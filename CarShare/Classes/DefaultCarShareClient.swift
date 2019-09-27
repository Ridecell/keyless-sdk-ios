//
//  DefaultCarShareClient.swift
//  CarShare
//
//  Created by Matt Snow on 2019-07-08.
//

import Foundation

public class DefaultCarShareClient: CarShareClient, CommandProtocolDelegate {

    enum DefaultCarShareClientError: Error {
        case challengeFailed
    }

    private let commandProtocol: CommandProtocol

    private var outgoingMessage: Message?

    public weak var delegate: CarShareClientDelegate?

    public convenience init() {
        self.init(commandProtocol: PocCommandProtocol())
    }

    init(commandProtocol: PocCommandProtocol) {
        self.commandProtocol = commandProtocol
    }

    public func connect(_ configuration: BLeSocketConfiguration) {
        commandProtocol.delegate = self
        commandProtocol.open(configuration)
    }

    public func disconnect() {
        commandProtocol.close()
    }

    public func execute(_ command: Command, with reservation: Reservation) {
        let message = Message(command: command, reservation: reservation)
        outgoingMessage = message
        commandProtocol.send(message, challengeKey: reservation.privateKey)
    }

    func protocolDidOpen(_ protocol: CommandProtocol) {
        delegate?.clientDidConnect(self)
    }

    func protocolDidCloseUnexpectedly(_ protocol: CommandProtocol, error: Error) {
        delegate?.clientDidDisconnectUnexpectedly(self, error: error)
        disconnect()
    }

    func `protocol`(_ protocol: CommandProtocol, command: Command, didSucceed response: Data) {
        guard let message = outgoingMessage else {
            return
        }
        outgoingMessage = nil
        delegate?.clientCommandDidSucceed(self, command: message.command)
    }

    func `protocol`(_ protocol: CommandProtocol, command: Command, didFail error: Error) {
        guard let message = outgoingMessage else {
            return
        }
        outgoingMessage = nil
        delegate?.clientCommandDidFail(self, command: message.command, error: error)
    }
}
