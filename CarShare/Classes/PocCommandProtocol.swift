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
            populator.reservation = message.reservation.token
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
