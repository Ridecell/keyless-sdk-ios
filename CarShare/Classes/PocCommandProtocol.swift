//
//  PocCommandProtocol.swift
//  CarShare
//
//  Created by Marc Maguire on 2019-08-26.
//

import Foundation
import SwiftProtobuf

class PocCommandProtocol: CommandProtocol, TransportProtocolDelegate {

    enum DefaultCommandProtocolError: Swift.Error {
        case malformedChallenge
        case invalidChallengeResponse
    }

    private enum CommandState {
        case issuingCommand
        case waitingForResponse
    }

    private struct OutgoingCommand {
        let command: Command
        let challengeKey: String
        var state: CommandState
    }

    private var outgoingCommand: OutgoingCommand?

    private let transportProtocol: TransportProtocol

    weak var delegate: CommandProtocolDelegate?

    init(transportProtocol: TransportProtocol = DefaultTransportProtocol()) {
        self.transportProtocol = transportProtocol
    }

    func open(_ configuration: BLeSocketConfiguration) {
        outgoingCommand = nil
        transportProtocol.delegate = self
        transportProtocol.open(configuration)
    }

    func close() {
        outgoingCommand = nil
        transportProtocol.close()
    }

    func send(_ message: Message, challengeKey: String) {
        outgoingCommand = OutgoingCommand(command: message.command, challengeKey: challengeKey, state: .issuingCommand)
        guard let outgoingMessage = transformIntoProtobufMessage(message) else {
            return
        }
        transportProtocol.send(outgoingMessage)
    }

    func protocolDidOpen(_ protocol: TransportProtocol) {
        delegate?.protocolDidOpen(self)
    }

    func `protocol`(_ protocol: TransportProtocol, didReceive data: Data) {
        guard let outgoingCommand = outgoingCommand else {
            return
        }
        switch outgoingCommand.state {
        case .issuingCommand:
            return
        case .waitingForResponse:
            self.outgoingCommand = nil
            switch transformIntoProtobufResult(data) {
            case .success:
                delegate?.protocol(self, command: outgoingCommand.command, didSucceed: data)
            case .failure(let error):
                delegate?.protocol(self, command: outgoingCommand.command, didFail: error)
            }
        }
    }

    func protocolDidSend(_ protocol: TransportProtocol) {
        guard let outgoingCommand = outgoingCommand else {
            return
        }
        switch outgoingCommand.state {
        case .issuingCommand:
            self.outgoingCommand?.state = .waitingForResponse
        case .waitingForResponse:
            return
        }
    }

    func protocolDidCloseUnexpectedly(_ protocol: TransportProtocol, error: Error) {
        delegate?.protocolDidCloseUnexpectedly(self, error: error)
    }

    func protocolDidFailToSend(_ protocol: TransportProtocol, error: Error) {
        guard let outgoingCommand = outgoingCommand else {
            return
        }
        self.outgoingCommand = nil
        delegate?.protocol(self, command: outgoingCommand.command, didFail: error)
    }

    func protocolDidFailToReceive(_ protocol: TransportProtocol, error: Error) {
        guard let outgoingCommand = outgoingCommand else {
            return
        }
        self.outgoingCommand = nil
        delegate?.protocol(self, command: outgoingCommand.command, didFail: error)
    }

    private func transformIntoProtobufMessage(_ message: Message) -> Data? {
        let reservationTransformer = ReservationTransformer()
        guard let tokenString = String(data: message.reservation.token, encoding: .utf8), let tokenObject = try? reservationTransformer.transform(tokenString) else {
            print("Failed to decode message", #function)
            return nil
        }
        guard let deviceReservationMessage = generateDeviceReservationMessage(from: tokenObject) else {
            print("Unable to generate DeviceReservationMessage from ReservationDetails")
            return nil
        }

        let deviceCommandMessage = DeviceCommandMessage.with { populator in
            populator.command = {
                switch message.command {
                case .checkIn:
                    return DeviceCommandMessage.Command.checkin
                case .checkOut:
                    return DeviceCommandMessage.Command.checkout
                case .locate:
                    return DeviceCommandMessage.Command.locate
                case .lock:
                    return DeviceCommandMessage.Command.lock
                case .unlockAll:
                    return DeviceCommandMessage.Command.unlockAll
                case .unlockDriver:
                    return DeviceCommandMessage.Command.unlockDriver
                case .openTrunk:
                    return DeviceCommandMessage.Command.openTrunk
                case .closeTrunk:
                    return DeviceCommandMessage.Command.closeTrunk
                }
            }()
            populator.reservation = deviceReservationMessage

        }
        let appToDeviceMessage = AppToDeviceMessage.with { populator in
            populator.message = .command(deviceCommandMessage)

        }
        do {
            return try appToDeviceMessage.serializedData()
        } catch {
            print("Failed to serialize data to protobuf due to error: \(error)")
            return nil
        }
    }

    private func generateDeviceReservationMessage(from reservationDetails: ReservationTransformer.ReservationDetails) -> DeviceReservationMessage? {

        guard let publicModulus = Data(base64Encoded: reservationDetails.reservationToken.appPublicModulus) else {
            print("Unable to turn public modulus into Data")
            return nil
        }
        guard let reservationBytes = Data(base64Encoded: reservationDetails.reservationId) else {
            print("Unable to turn reservationID into Data")
            return nil
        }

        let deviceReservationMessage = DeviceReservationMessage.with { populator in
            populator.appPublicModulus = publicModulus
            populator.keyExpiry = reservationDetails.reservationToken.keyExpiry
            populator.reservationID = reservationBytes
            populator.deviceHardwareID = reservationDetails.reservationToken.deviceHardwareId
            populator.account = Account.with { accountPopulator in
                accountPopulator.id = reservationDetails.reservationToken.account.id
                accountPopulator.permissions = PermissionList.with { permissionsPopulator in
                    permissionsPopulator.permissions = reservationDetails.reservationToken.account.permissions
                }
            }
            populator.reservationStartTime = reservationDetails.reservationToken.reservationStartTime
            populator.reservationEndTime = reservationDetails.reservationToken.reservationEndTime
            populator.gracePeriodSeconds = reservationDetails.reservationToken.gracePeriodSeconds
            populator.securePeriodSeconds = reservationDetails.reservationToken.securePeriodSeconds
            populator.endBookConditions = EndBookConditions.with { endBookPopulator in
                endBookPopulator.vehicleSecureConditions = VehicleSecureConditions.with { vehicleSecurePopulator in
                    vehicleSecurePopulator.vehicleSecureConditions = reservationDetails.reservationToken.endBookConditions.endBookVehicleFlags
                }
                endBookPopulator.homePoint = GpsCoordinate.with { gpsCoordinatePopulator in
                    gpsCoordinatePopulator.latitude = reservationDetails.reservationToken.endBookConditions.homePoint.latitude
                    gpsCoordinatePopulator.longitude = reservationDetails.reservationToken.endBookConditions.homePoint.longitude
                }
                endBookPopulator.homeRadius = reservationDetails.reservationToken.endBookConditions.homeRadius
            }
        }
        return deviceReservationMessage
    }

    private func transformIntoProtobufResult(_ result: Data) -> Result<Bool, Error> {
        do {
            let deviceToAppMessage = try DeviceToAppMessage(serializedData: result)
            if deviceToAppMessage.result.success {
                return .success(true)
            } else {
                return .failure(DefaultCommandProtocolError.invalidChallengeResponse)
            }
        } catch {
            print("Failed to transform protobuf result data into Result Message due to error \(error.localizedDescription)")
            return .failure(error)
        }
    }
}
