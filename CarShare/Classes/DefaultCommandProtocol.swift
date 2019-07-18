//
//  DefaultCommandProtocol.swift
//  CarShare
//
//  Created by Matt Snow on 2019-07-08.
//

import Foundation

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

    private var outgoingCommand: (command: Data, challengeKey: String, state: CommandState)?

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

    func send(_ command: Data, challengeKey: String) {
        outgoingCommand = (command, challengeKey, .issuingCommand)
        transportProtocol.send(command)
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
                delegate?.protocol(self, command: outgoingCommand.command, didFail: DefaultCommandProtocolError.malformedChallenge)
                return
            }
            guard let responseToChallenge = sign(challenge, with: outgoingCommand.challengeKey) else {
                self.outgoingCommand = nil
                delegate?.protocol(self, command: outgoingCommand.command, didFail: DefaultCommandProtocolError.malformedChallenge)
                return
            }
            self.outgoingCommand?.state = .respondingToChallenge
            transportProtocol.send(responseToChallenge)
        case .respondingToChallenge:
            return
        case .waitingForResponse:
            self.outgoingCommand = nil
            delegate?.protocol(self, command: outgoingCommand.command, didSucceed: data)
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
        delegate?.protocol(self, command: outgoingCommand.command, didFail: error)
    }

    func protocolDidFailToReceive(_ protocol: TransportProtocol, error: Error) {
        guard let outgoingCommand = outgoingCommand else {
            return
        }
        self.outgoingCommand = nil
        delegate?.protocol(self, command: outgoingCommand.command, didFail: error)
    }


    private func transformIntoChallenge(_ data: Data) -> String? {
        return String(data: data, encoding: .utf8)
    }

    private func sign(_ challenge: String, with signingKey: String) -> Data? {
        return "\(challenge)---\(signingKey)".data(using: .utf8)
    }

}
