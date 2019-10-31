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

    func send(_ message: Message) {
        outgoingCommand = OutgoingCommand(command: message.command, challengeKey: message.carShareTokenInfo.reservationPrivateKey, state: .issuingCommand)
        guard let commandProto = transformIntoProtobufMessage(message) else {
            return
        }
        //temporary random bytes
        let randomBytes: [UInt8] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        let signedCommandHash = self.signedCommandHash(with: message.carShareTokenInfo.reservationPrivateKey,
                                                       commandMessageProto: commandProto,
                                                       randomBytes: Data(bytes: randomBytes,
                                                                         count: randomBytes.count))
        let payload = CarShareMessage.deviceMessage(from: message.carShareTokenInfo, commandMessageProto: commandProto, signedCommandHash: signedCommandHash).data
        transportProtocol.send(payload)
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

    private func signedCommandHash(with privateKey: String, commandMessageProto: Data, randomBytes: Data) -> [UInt8] {
        let challengeSigner = ChallengeSigner()
        var commandMessageProto = [UInt8](commandMessageProto)
        //hardcoded with 32 0's until challenge response is fully implemented
        commandMessageProto.append(contentsOf: [UInt8](randomBytes))
        let commandMessageData = Data(bytes: commandMessageProto, count: commandMessageProto.count)
        guard let signedData = challengeSigner.sign(commandMessageData, signingKey: privateKey) else {
            return []
        }
        return [UInt8](signedData)
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
        }
        do {
             return try deviceCommandMessage.serializedData()
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
