//
//  DefaultCommandProtocol.swift
//  CarShare
//
//  Created by Matt Snow on 2019-07-08.
//

import Foundation
import SwiftProtobuf

class DefaultCommandProtocol: CommandProtocol, SecurityProtocolDelegate {

    enum DefaultCommandProtocolError: Swift.Error {
        case malformedChallenge
        case invalidChallengeResponse
    }

    private enum CommandState {
        case issuingCommand
        case waitingForChallenge
        case respondingToChallenge
        case waitingForResponse
    }

    private struct OutgoingCommand {
        let command: Command
        let challengeKey: String
        var state: CommandState
    }

    private var outgoingCommand: OutgoingCommand?

    private let securityProtocol: SecurityProtocol

    weak var delegate: CommandProtocolDelegate?

    init(securityProtocol: SecurityProtocol = DefaultSecurityProtocol()) {
        self.securityProtocol = securityProtocol
    }

    func open(_ configuration: BLeSocketConfiguration) {
        outgoingCommand = nil
        securityProtocol.delegate = self
        securityProtocol.open(configuration)
    }

    func close() {
        outgoingCommand = nil
        securityProtocol.close()
    }

    func send(_ message: Message, challengeKey: String) {
        outgoingCommand = OutgoingCommand(command: message.command, challengeKey: challengeKey, state: .issuingCommand)
        guard let outgoingMessage = transformIntoProtobufMessage(message) else {
            return
        }
        securityProtocol.send(outgoingMessage)
    }

    func protocolDidOpen(_ protocol: SecurityProtocol) {
        delegate?.protocolDidOpen(self)
    }

    func `protocol`(_ protocol: SecurityProtocol, didReceive data: Data) {
        guard let outgoingCommand = outgoingCommand else {
            return
        }
        switch outgoingCommand.state {
        case .issuingCommand:
            return
        case .waitingForChallenge:
            guard let challenge = transformIntoChallenge(data) else {
                self.outgoingCommand = nil
                delegate?.protocol(self, command: outgoingCommand.command, didFail: DefaultCommandProtocolError.malformedChallenge)
                return
            }
            guard let responseToChallenge = sign(challenge, with: outgoingCommand.challengeKey) else {
                self.outgoingCommand = nil
                delegate?.protocol(self, command: outgoingCommand.command, didFail: DefaultCommandProtocolError.malformedChallenge)
                return
            }

            guard let response = transformIntoProtobufResponse(responseToChallenge) else {
                self.outgoingCommand = nil
                delegate?.protocol(self, command: outgoingCommand.command, didFail: DefaultCommandProtocolError.malformedChallenge)
                return
            }

            self.outgoingCommand?.state = .respondingToChallenge
            securityProtocol.send(response)
        case .respondingToChallenge:
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

    func protocolDidSend(_ protocol: SecurityProtocol) {
        guard let outgoingCommand = outgoingCommand else {
            return
        }
        switch outgoingCommand.state {
        case .issuingCommand:
            self.outgoingCommand?.state = .waitingForChallenge
        case .waitingForChallenge:
            return
        case .respondingToChallenge:
            self.outgoingCommand?.state = .waitingForResponse
        case .waitingForResponse:
            return
        }
    }

    func protocolDidCloseUnexpectedly(_ protocol: SecurityProtocol, error: Error) {
        delegate?.protocolDidCloseUnexpectedly(self, error: error)
    }

    func protocolDidFailToSend(_ protocol: SecurityProtocol, error: Error) {
        guard let outgoingCommand = outgoingCommand else {
            return
        }
        self.outgoingCommand = nil
        delegate?.protocol(self, command: outgoingCommand.command, didFail: error)
    }

    func protocolDidFailToReceive(_ protocol: SecurityProtocol, error: Error) {
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

        var appToDeviceMessage = AppToDeviceMessage()
        var deviceCommandMessage = DeviceCommandMessage()
        switch message.command {
        case .checkIn:
            deviceCommandMessage.command = .checkin
        case .checkOut:
            deviceCommandMessage.command = .checkout
        case .locate:
            deviceCommandMessage.command = .locate
        case .lock:
            deviceCommandMessage.command = .lock
        case .unlockAll:
            deviceCommandMessage.command = .unlockAll
        case .unlockDriver:
            deviceCommandMessage.command = .unlockDriver
        case .openTrunk:
            deviceCommandMessage.command = .openTrunk
        case .closeTrunk:
            deviceCommandMessage.command = .closeTrunk
        }

        guard let deviceReservationMessage = generateDeviceReservationMessage(from: tokenObject) else {
            print("Unable to generate DeviceReservationMessage from ReservationDetails")
            return nil
        }
        deviceCommandMessage.reservation = deviceReservationMessage
        appToDeviceMessage.command = deviceCommandMessage
        do {
            return try appToDeviceMessage.serializedData()
        } catch {
            print("Failed to serialize data to protobuf due to error: \(error.localizedDescription)")
        }
        return nil
    }

    private func generateDeviceReservationMessage(from reservationDetails: ReservationTransformer.ReservationDetails) -> DeviceReservationMessage? {
        var deviceReservationMessage = DeviceReservationMessage()
        guard let publicModulus = Data(base64Encoded: reservationDetails.reservationToken.appPublicModulus) else {
            print("Unable to turn public modulus into Data")
            return nil
        }
        deviceReservationMessage.appPublicModulus = publicModulus
        deviceReservationMessage.keyExpiry = reservationDetails.reservationToken.keyExpiry

        guard let reservationBytes = Data(base64Encoded: reservationDetails.reservationId) else {
            print("Unable to turn reservationID into Data")
            return nil
        }
        deviceReservationMessage.reservationID = reservationBytes
        deviceReservationMessage.deviceHardwareID = reservationDetails.reservationToken.deviceHardwareId
        var account = Account()
        account.id = reservationDetails.reservationToken.account.id
        var permissionsList = PermissionList()
        permissionsList.permissions = reservationDetails.reservationToken.account.permissions
        account.permissions = permissionsList
        deviceReservationMessage.account = account
        deviceReservationMessage.reservationStartTime = reservationDetails.reservationToken.reservationStartTime
        deviceReservationMessage.reservationEndTime = reservationDetails.reservationToken.reservationEndTime
        deviceReservationMessage.gracePeriodSeconds = reservationDetails.reservationToken.gracePeriodSeconds
        deviceReservationMessage.gracePeriodSeconds = reservationDetails.reservationToken.securePeriodSeconds
        var endBookConditions = EndBookConditions()
        var vehicleSecureConditions = VehicleSecureConditions()
        vehicleSecureConditions.vehicleSecureConditions = reservationDetails.reservationToken.endBookConditions.endBookVehicleFlags
        endBookConditions.vehicleSecureConditions = vehicleSecureConditions
        var homePoint = GpsCoordinate()
        homePoint.latitude = reservationDetails.reservationToken.endBookConditions.homePoint.latitude
        homePoint.longitude = reservationDetails.reservationToken.endBookConditions.homePoint.longitude
        endBookConditions.homePoint = homePoint
        endBookConditions.homeRadius = reservationDetails.reservationToken.endBookConditions.homeRadius
        deviceReservationMessage.endBookConditions = endBookConditions
        return deviceReservationMessage
    }

    private func transformIntoProtobufResponse(_ response: Data) -> Data? {
        //to-do: Reimplement when proto file is updated to include challenge response
//        var responseMessage = ResponseMessage()
//        responseMessage.response = response
//        do {
//            return try responseMessage.serializedData()
//        } catch {
//            print("Unable to serialize challenge response due to error: \(error.localizedDescription)")
//            return nil
//        }
        return nil
    }

    private func transformIntoProtobufResult(_ result: Data) -> Result<Bool, Error> {
        do {
            let resultMessage = try ResultMessage(serializedData: result)
            if resultMessage.success {
                return .success(true)

            } else {
                return .failure(DefaultCommandProtocolError.invalidChallengeResponse)
            }
        } catch {
            print("Failed to transform protobuf result data into Result Message due to error \(error.localizedDescription)")
            return .failure(error)
        }
    }

    private func transformIntoChallenge(_ data: Data) -> Data? {
        //to-do: Reimplement when proto file is updated to include challenge response
//        var challengeMessage: ChallengeMessage?
//        do {
//            try challengeMessage = ChallengeMessage(serializedData: data)
//            guard let challengeData = challengeMessage?.challenge else {
//                return nil
//            }
//            return challengeData
//        } catch {
//            print("Unable to transform data into Challenge Message with error: \(error.localizedDescription)")
//            return nil
//        }
        return nil
    }

    private func sign(_ challenge: Data, with signingKey: String) -> Data? {
        let signer = ChallengeSigner()
        return signer.sign(challenge, signingKey: signingKey)
    }

}
