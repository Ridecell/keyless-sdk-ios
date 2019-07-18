//
//  DefaultCommandProtocol.swift
//  CarShare
//
//  Created by Matt Snow on 2019-07-08.
//

import Foundation
import SwiftProtobuf

class DefaultCommandProtocol: CommandProtocol, TransportProtocolDelegate {

    enum DefaultCommandProtocolError: Swift.Error {
        case malformedChallenge
    }

    private enum CommandState {
        case issuingCommand
        case waitingForChallenge
        case respondingToChallenge
        case waitingForResponse
    }

    private var outgoingCommand: (command: Message, challengeKey: String, state: CommandState)?

    private let transportProtocol: TransportProtocol

    weak var delegate: CommandProtocolDelegate?

    init(transportProtocol: TransportProtocol) {
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

    func send(_ command: Message, challengeKey: String) {
        outgoingCommand = (command, challengeKey, .issuingCommand)
        guard let outgoingMessage = transformIntoProtobufMessage(command) else {
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
        switch (outgoingCommand.state) {
        case .issuingCommand:
            return
        case .waitingForChallenge:
            guard let challenge = transformIntoChallenge(data) else {
                self.outgoingCommand = nil
                delegate?.protocol(self, command: outgoingCommand.command.data, didFail: DefaultCommandProtocolError.malformedChallenge)
                return
            }
            guard let responseToChallenge = sign(challenge, with: outgoingCommand.challengeKey) else {
                self.outgoingCommand = nil
                delegate?.protocol(self, command: outgoingCommand.command.data, didFail: DefaultCommandProtocolError.malformedChallenge)
                return
            }
            
            guard let response = transformIntoProtobufResponse(responseToChallenge) else {
                self.outgoingCommand = nil
                delegate?.protocol(self, command: outgoingCommand.command.data, didFail: DefaultCommandProtocolError.malformedChallenge)
                return
            }
            
            self.outgoingCommand?.state = .respondingToChallenge
            transportProtocol.send(response)
        case .respondingToChallenge:
            return
        case .waitingForResponse:
            self.outgoingCommand = nil
            switch transformIntoProtobufResult(data) {
            case .success(_):
                //assume we will never succeed to connect with a failure?
                delegate?.protocol(self, command: outgoingCommand.command.data, didSucceed: data)
            case .failure(let error):
                delegate?.protocol(self, command: outgoingCommand.command.data, didFail: error)
            }
            //transform data into result message and succeed or fail
            delegate?.protocol(self, command: outgoingCommand.command.data, didSucceed: data)
        }
    }

    func protocolDidSend(_ protocol: TransportProtocol) {
        guard let outgoingCommand = outgoingCommand else {
            return
        }
        switch (outgoingCommand.state) {
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

    func protocolDidCloseUnexpectedly(_ protocol: TransportProtocol, error: Error) {
        delegate?.protocolDidCloseUnexpectedly(self, error: error)
    }

    func protocolDidFailToSend(_ protocol: TransportProtocol, error: Error) {
        guard let outgoingCommand = outgoingCommand else {
            return
        }
        self.outgoingCommand = nil
        delegate?.protocol(self, command: outgoingCommand.command.data, didFail: error)
    }

    func protocolDidFailToReceive(_ protocol: TransportProtocol, error: Error) {
        guard let outgoingCommand = outgoingCommand else {
            return
        }
        self.outgoingCommand = nil
        delegate?.protocol(self, command: outgoingCommand.command.data, didFail: error)
    }

    private func transformIntoProtobufMessage(_ message: Message) -> Data? {
        var protoMessage = CommandMessage()
        protoMessage.reservationToken = message.reservation.certificate
        switch message.command {
        case .checkIn:
            protoMessage.command = .checkin
        case .checkOut:
            protoMessage.command = .checkout
        case .locate:
            protoMessage.command = .locate
        case .lock:
            protoMessage.command = .lock
        case .unlock:
            protoMessage.command = .unlock
        }
        do {
            return try protoMessage.serializedData()
        } catch {
            print("Failed to serialize data to protobuf due to error: \(error.localizedDescription)")
        }
        return nil
    }
    
    private func transformIntoProtobufResponse(_ response: Data) -> Data? {
        var responseMessage = ResponseMessage()
        responseMessage.response = response
        do {
            return try responseMessage.serializedData()
        } catch {
            print("Unable to serialize challenge response due to error: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func transformIntoProtobufResult(_ result: Data) -> Result<Bool, Error> {
        var resultMessage: ResultMessage?
        do {
            try resultMessage = ResultMessage(serializedData: result)
            guard let result = resultMessage else {
                //impossible?
                return .success(false)
            }
            return .success(result.success ? true : false)
        } catch {
            print("Failed to transform protobuf result data into Result Message due to error \(error.localizedDescription)")
            return .failure(error)
        }
    }
    
    private func transformIntoChallenge(_ data: Data) -> String? {
        var challengeMessage: ChallengeMessage?
        do {
            try challengeMessage = ChallengeMessage(serializedData: data)
            guard let challengeData = challengeMessage?.challenge else { return nil }
            return String(data: challengeData, encoding: .utf8)
        } catch {
            print("Unable to transform data into Challenge Message with error: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func sign(_ challenge: String, with signingKey: String) -> Data? {
        let signer = ChallengeSigner(privateKey: signingKey)
        return signer.sign(challenge)?.data(using: .utf8)
    }

}
