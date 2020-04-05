//
//  PocCommandProtocol.swift
//  CarShare
//
//  Created by Marc Maguire on 2019-08-26.
//

import Foundation

class DefaultCommandProtocol: CommandProtocol, TransportProtocolDelegate {

    enum DefaultCommandProtocolError: Swift.Error, CustomStringConvertible {
        case ackError
        case malformedData

        var description: String {
            switch self {
            case .ackError:
                return "Challenge Failed"
            case .malformedData:
                return "Malformed Data"
            }
        }
    }

    private enum ChallengeResponseValues {
        static let messageRequestType: UInt8 = 0x00
        static let messageRequestProtocolVersion: [UInt8] = [0x01, 0x00]
        static let challengeResponseType: UInt8 = 0x80
        static let deviceToAppAck: [UInt8] = [0x81, 0x00]
        static let encryptionSalt: [UInt8] = [232, 96, 98, 5, 159, 228, 202, 239]
        static let encryptionPassphrase: String = "SUPER_SECRET"
        static let encryptionIterations: Int = 14_271
        static let deviceToAppAckValue: UInt8 = 0x00
    }

    private var outgoingCommand: OutgoingCommand?

    private let transportProtocol: TransportProtocol
    private let deviceToAppMessageTransformer: DeviceToAppMessageTransformer
    private let challengeSigner: ChallengeSigner

    weak var delegate: CommandProtocolDelegate?

    init(transportProtocol: TransportProtocol, deviceToAppMessageTransformer: DeviceToAppMessageTransformer, challengeSigner: ChallengeSigner) {
        self.transportProtocol = transportProtocol
        self.deviceToAppMessageTransformer = deviceToAppMessageTransformer
        self.challengeSigner = challengeSigner
    }

    convenience init(logger: Logger) {
        self.init(
            transportProtocol: DefaultTransportProtocol(logger: logger),
            deviceToAppMessageTransformer: ProtobufDeviceToAppMessageTransformer(),
            challengeSigner: DefaultChallengeSigner())
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

    func send(_ command: OutgoingCommand) {
        guard outgoingCommand == nil else {
            return
        }
        outgoingCommand = command
        transportProtocol.send(appToDeviceMessageRequest)
    }

    private var appToDeviceMessageRequest: Data {
        var request: [UInt8] = []
        request.append(ChallengeResponseValues.messageRequestType)
        request.append(contentsOf: ChallengeResponseValues.messageRequestProtocolVersion)
        return Data(bytes: request, count: request.count)
    }

    func protocolDidOpen(_ protocol: TransportProtocol) {
        delegate?.protocolDidOpen(self)
    }
    //swiftlint:disable:next cyclomatic_complexity
    func `protocol`(_ protocol: TransportProtocol, didReceive data: Data) {
        guard let outgoingCommand = outgoingCommand else {
            return
        }
        switch outgoingCommand.state {
        case .requestingToSendMessage:
            return
        case .waitingForChallenge:
            guard let randomBytes = IncomingChallenge(data: data)?.randomBytes else {
                delegate?.protocol(self, didFail: DefaultCommandProtocolError.malformedData)
                self.outgoingCommand = nil
                return
            }

            guard let securePayload = generateSecurePayload(randomBytes, outgoingCommand: outgoingCommand) else {
                self.delegate?.protocol(self, didFail: DefaultCommandProtocolError.malformedData)
                self.outgoingCommand = nil
                return
            }
            self.outgoingCommand?.state = .issuingCommand
            sendChallengeResponse(ChallengeResponseValues.challengeResponseType, message: [UInt8](securePayload))

        case .issuingCommand:
            return
        case .awaitingChallengeAck:
            switch handleChallengeAck(data) {
            case .success:
                self.outgoingCommand?.state = .awaitingDeviceAck
            case .failure(let error):
                self.outgoingCommand = nil
                delegate?.protocol(self, didFail: error)
            }
        case .awaitingDeviceAck:
            self.outgoingCommand = nil
            switch handleDeviceAck(data) {
            case .success:
                delegate?.protocol(self, didSucceed: data)
            case .failure(let error):
                delegate?.protocol(self, didFail: error)
            }
        }
    }

    func protocolDidSend(_ protocol: TransportProtocol) {
        guard let outgoingCommand = outgoingCommand else {
            return
        }
        switch outgoingCommand.state {
        case .requestingToSendMessage:
            self.outgoingCommand?.state = .waitingForChallenge
        case .waitingForChallenge:
            return
        case .issuingCommand:
            self.outgoingCommand?.state = .awaitingChallengeAck
        case .awaitingChallengeAck:
            return
        case .awaitingDeviceAck:
            return
        }
    }

    func protocolDidCloseUnexpectedly(_ protocol: TransportProtocol, error: Error) {
        self.outgoingCommand = nil
        delegate?.protocolDidCloseUnexpectedly(self, error: error)
    }

    func protocolDidFailToSend(_ protocol: TransportProtocol, error: Error) {
        guard outgoingCommand != nil else {
            return
        }
        self.outgoingCommand = nil
        delegate?.protocol(self, didFail: error)
    }

    func protocolDidFailToReceive(_ protocol: TransportProtocol, error: Error) {
        guard outgoingCommand != nil else {
            return
        }
        self.outgoingCommand = nil
        delegate?.protocol(self, didFail: error)
    }

    private func generateSecurePayload(_ randomBytes: [UInt8], outgoingCommand: OutgoingCommand) -> Data? {
        guard let signedCommandHash = self.signedCommandHash(with: outgoingCommand.carShareTokenInfo.reservationPrivateKey,
                                                             commandMessageProto: outgoingCommand.deviceCommandMessage,
                                                             randomBytes: Data(bytes: randomBytes,
                                                                               count: randomBytes.count)) else {
                                                                                return nil
        }
        return DeviceCommandPayload.build(from: outgoingCommand.carShareTokenInfo,
                                          commandMessageProto: outgoingCommand.deviceCommandMessage,
                                          signedCommandHash: signedCommandHash).data
    }

    //swiftlint:disable:next discouraged_optional_collection
    private func signedCommandHash(with privateKey: String, commandMessageProto: Data, randomBytes: Data) -> [UInt8]? {
        var commandMessageProto = [UInt8](commandMessageProto)
        commandMessageProto.append(contentsOf: [UInt8](randomBytes))
        let commandMessageData = Data(bytes: commandMessageProto, count: commandMessageProto.count)
        guard let signedData = challengeSigner.sign(commandMessageData, signingKey: privateKey) else {
            return nil
        }
        return [UInt8](signedData)
    }

    private func handleChallengeAck(_ data: Data) -> Result<Void, DefaultCommandProtocolError> {
        guard let incomingChallengeAck = IncomingChallengeAck(data: data) else {
            return .failure(DefaultCommandProtocolError.malformedData)
        }
        guard incomingChallengeAck.result == ChallengeResponseValues.deviceToAppAckValue else {
            return .failure(DefaultCommandProtocolError.ackError)
        }
        return .success(())
    }

    private func sendChallengeResponse(_ type: UInt8, message: [UInt8]) {
        var response: [UInt8] = []
        response.append(type)
        response.append(contentsOf: message)
        transportProtocol.send(Data(bytes: response, count: response.count))
    }

    private func handleDeviceAck(_ result: Data) -> Result<Bool, Error> {
        return deviceToAppMessageTransformer.transform(result)
    }
}
