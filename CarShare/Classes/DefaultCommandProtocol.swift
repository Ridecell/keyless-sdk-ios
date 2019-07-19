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
    }

    private enum CommandState {
        case issuingCommand
        case waitingForChallenge
        case respondingToChallenge
        case waitingForResponse
    }

    private var outgoingCommand: (command: Message, challengeKey: String, state: CommandState)?

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

    func send(_ command: Message, challengeKey: String) {
        outgoingCommand = (command, challengeKey, .issuingCommand)
        guard let outgoingMessage = transformIntoProtobufMessage(command) else {
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
            securityProtocol.send(response)
        case .respondingToChallenge:
            return
        case .waitingForResponse:
            self.outgoingCommand = nil
            switch transformIntoProtobufResult(data) {
            case .success:
                delegate?.protocol(self, command: outgoingCommand.command.data, didSucceed: data)
            case .failure(let error):
                delegate?.protocol(self, command: outgoingCommand.command.data, didFail: error)
            }
        }
    }

    func protocolDidSend(_ protocol: SecurityProtocol) {
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

    func protocolDidCloseUnexpectedly(_ protocol: SecurityProtocol, error: Error) {
        delegate?.protocolDidCloseUnexpectedly(self, error: error)
    }

    func protocolDidFailToSend(_ protocol: SecurityProtocol, error: Error) {
        guard let outgoingCommand = outgoingCommand else {
            return
        }
        self.outgoingCommand = nil
        delegate?.protocol(self, command: outgoingCommand.command.data, didFail: error)
    }

    func protocolDidFailToReceive(_ protocol: SecurityProtocol, error: Error) {
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
        do {
            let resultMessage = try ResultMessage(serializedData: result)
            return .success(resultMessage.success ? true : false)
        } catch {
            print("Failed to transform protobuf result data into Result Message due to error \(error.localizedDescription)")
            return .failure(error)
        }
    }
    
    private func transformIntoChallenge(_ data: Data) -> Data? {
        var challengeMessage: ChallengeMessage?
        do {
            try challengeMessage = ChallengeMessage(serializedData: data)
            guard let challengeData = challengeMessage?.challenge else { return nil }
            return challengeData
        } catch {
            print("Unable to transform data into Challenge Message with error: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func sign(_ challenge: Data, with signingKey: String) -> Data? {
        let signer = ChallengeSigner()
        return signer.sign(challenge, signingKey: signingKey)
    }

}
