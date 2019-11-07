//
//  PocCommandProtocol.swift
//  CarShare
//
//  Created by Marc Maguire on 2019-08-26.
//

import Foundation

class DefaultCommandProtocol: CommandProtocol, TransportProtocolDelegate {

    enum DefaultCommandProtocolError: Swift.Error {
        case ackError
        case malformedData
    }

    private enum CommandState {
        case requestingToSendMessage
        case waitingForChallenge
        case issuingCommand
        case awaitingChallengeAck
    }

    private struct OutgoingCommand {
        let command: Command
        let deviceCommandMessage: Data
        let carShareTokenInfo: CarShareTokenInfo
        var state: CommandState
    }

    private enum ChallengeResponseValues {
        static let messageRequestType: UInt8 = 0x00
        static let messageRequestProtocolVersion: [UInt8] = [0x01, 0x00]
        static let challengeResponseType: UInt8 = 0x80
        static let deviceToAppAck: [UInt8] = [0x81, 0x00]
        static let encryptionSalt: [UInt8] = [232, 96, 98, 5, 159, 228, 202, 239]
        static let encryptionPassphrase: String = "SUPER_SECRET"
        static let encryptionIterations: Int = 14_271
    }

    private var outgoingCommand: OutgoingCommand?

    private let transportProtocol: TransportProtocol
    private let deviceCommandTransformer: DeviceCommandTransformer
    private let challengeSigner: ChallengeSigner
    private let encryptionHandler: EncryptionHandler
    private let byteGenerator: ByteGenerator

    weak var delegate: CommandProtocolDelegate?

    init(transportProtocol: TransportProtocol = DefaultTransportProtocol(),
         deviceCommandTransformer: DeviceCommandTransformer = ProtobufDeviceCommandTransformer(),
         challengeSigner: ChallengeSigner = DefaultChallengeSigner(),
         encryptionHandler: EncryptionHandler = AESEncryptionHandler(),
         byteGenerator: ByteGenerator = DefaultByteGenerator()) {
        self.transportProtocol = transportProtocol
        self.deviceCommandTransformer = deviceCommandTransformer
        self.challengeSigner = challengeSigner
        self.encryptionHandler = encryptionHandler
        self.byteGenerator = byteGenerator
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
        guard outgoingCommand == nil else {
            return
        }
        guard let commandProto = deviceCommandTransformer.transform(message.command) else {
            return
        }
        outgoingCommand = OutgoingCommand(command: message.command, deviceCommandMessage: commandProto, carShareTokenInfo: message.carShareTokenInfo, state: .requestingToSendMessage)
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

    func `protocol`(_ protocol: TransportProtocol, didReceive data: Data) {
        guard let outgoingCommand = outgoingCommand else {
            return
        }
        switch outgoingCommand.state {
        case .requestingToSendMessage:
            return
        case .waitingForChallenge:
            guard let randomBytes = IncomingChallenge(data: data)?.randomBytes else {
                delegate?.protocol(self,
                                   command: outgoingCommand.command,
                                   didFail: DefaultCommandProtocolError.malformedData)
                self.outgoingCommand = nil
                return
            }

            let securePayload = generateSecurePayload(randomBytes, outgoingCommand: outgoingCommand)
            guard let encryptionResult = encryptMessage([UInt8](securePayload)) else {
                self.delegate?.protocol(self, command: outgoingCommand.command, didFail: DefaultCommandProtocolError.malformedData)
                self.outgoingCommand = nil
                return
            }
            sendChallengeResponse(encryptionResult.initVector, encryptedMessage: encryptionResult.encryptedMessage)
            self.outgoingCommand?.state = .issuingCommand
        case .issuingCommand:
            return
        case .awaitingChallengeAck:
            self.outgoingCommand = nil
            switch handleAck(data) {
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
        case .requestingToSendMessage:
            self.outgoingCommand?.state = .waitingForChallenge
        case .awaitingChallengeAck:
            return
        case .waitingForChallenge:
            return
        case .issuingCommand:
            self.outgoingCommand?.state = .awaitingChallengeAck
        }
    }

    func protocolDidCloseUnexpectedly(_ protocol: TransportProtocol, error: Error) {
        self.outgoingCommand = nil
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

    private func generateSecurePayload(_ randomBytes: [UInt8], outgoingCommand: OutgoingCommand) -> Data {
        let signedCommandHash = self.signedCommandHash(with: outgoingCommand.carShareTokenInfo.reservationPrivateKey,
                                                       commandMessageProto: outgoingCommand.deviceCommandMessage,
                                                       randomBytes: Data(bytes: randomBytes,
                                                                         count: randomBytes.count))
        return DeviceCommandPayload.build(from: outgoingCommand.carShareTokenInfo,
                                          commandMessageProto: outgoingCommand.deviceCommandMessage,
                                          signedCommandHash: signedCommandHash).data
    }

    private func signedCommandHash(with privateKey: String, commandMessageProto: Data, randomBytes: Data) -> [UInt8] {
        var commandMessageProto = [UInt8](commandMessageProto)
        commandMessageProto.append(contentsOf: [UInt8](randomBytes))
        let commandMessageData = Data(bytes: commandMessageProto, count: commandMessageProto.count)
        guard let signedData = challengeSigner.sign(commandMessageData, signingKey: privateKey) else {
            //throw error?
            return []
        }
        return [UInt8](signedData)
    }

    private func encryptMessage(_ messageToEncrypt: [UInt8]) -> (initVector: [UInt8], encryptedMessage: [UInt8])? {
        let encryptionKey = encryptionHandler.encryptionKey(byteGenerator.generate(16))
        var bytesToEncrypt: [UInt8] = []
        bytesToEncrypt.append(ChallengeResponseValues.challengeResponseType)
        bytesToEncrypt.append(contentsOf: messageToEncrypt)
        guard let encryptedMessage = encryptionHandler.encrypt(bytesToEncrypt, with: encryptionKey) else {
            return nil
        }
        return (encryptionKey.initializationVector, encryptedMessage)
    }

    private func handleAck(_ data: Data) -> Result<Void, DefaultCommandProtocolError> {
        guard let incomingChallengeAck = IncomingChallengeAck(data: data) else {
            return .failure(DefaultCommandProtocolError.malformedData)
        }
        let encryptionKey = encryptionHandler.encryptionKey(incomingChallengeAck.initVector)
        guard let decryptedMessage = encryptionHandler.decrypt(incomingChallengeAck.encryptedMessage, with: encryptionKey) else {
            return .failure(DefaultCommandProtocolError.malformedData)
        }
        guard incomingChallengeAck.validatePayload(decryptedMessage) else {
            //future check for specific ack error codes
            return .failure(DefaultCommandProtocolError.ackError)
        }
        return .success(())
    }

    private func sendChallengeResponse(_ initializationVector: [UInt8], encryptedMessage: [UInt8]) {
        var response: [UInt8] = []
        response.append(contentsOf: initializationVector)
        response.append(contentsOf: encryptedMessage)
        transportProtocol.send(Data(bytes: response, count: response.count))
    }
}
