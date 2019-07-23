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
        self.init(commandProtocol: DefaultCommandProtocol())
    }

    init(commandProtocol: CommandProtocol) {
        self.commandProtocol = commandProtocol
    }

    public func connect(_ configuration: BLeSocketConfiguration) {
        commandProtocol.delegate = self
        commandProtocol.open(configuration)
    }

    public func disconnect() {
        commandProtocol.close()
    }

    public func checkIn(with reservation: Reservation) {
        let message = Message(command: .checkIn, reservation: reservation)
        outgoingMessage = message
        commandProtocol.send(message, challengeKey: reservation.privateKey)
    }

    public func checkOut(with reservation: Reservation) {
        let message = Message(command: .checkOut, reservation: reservation)

        outgoingMessage = message
        commandProtocol.send(message, challengeKey: reservation.privateKey)
    }

    public func lock(with reservation: Reservation) {
        let message = Message(command: .lock, reservation: reservation)
        outgoingMessage = message
        commandProtocol.send(message, challengeKey: reservation.privateKey)
    }

    public func unlock(with reservation: Reservation) {
        let message = Message(command: .unlock, reservation: reservation)
        outgoingMessage = message
        commandProtocol.send(message, challengeKey: reservation.privateKey)
    }

    public func locate(with reservation: Reservation) {
        let message = Message(command: .locate, reservation: reservation)
        outgoingMessage = message
        commandProtocol.send(message, challengeKey: reservation.privateKey)
    }

    func protocolDidOpen(_ protocol: CommandProtocol) {
        delegate?.clientDidConnect(self)
    }

    func protocolDidCloseUnexpectedly(_ protocol: CommandProtocol, error: Error) {
        delegate?.clientDidDisconnectUnexpectedly(self, error: error)
    }

    func `protocol`(_ protocol: CommandProtocol, command: Message.Command, didSucceed response: Data) {
        guard let message = outgoingMessage else {
            return
        }
        outgoingMessage = nil
        delegate?.clientCommandDidSucceed(self, command: message.command)
    }

    func `protocol`(_ protocol: CommandProtocol, command: Message.Command, didFail error: Error) {
        guard let message = outgoingMessage else {
            return
        }
        outgoingMessage = nil
        delegate?.clientCommandDidFail(self, command: message.command, error: error)
    }
}
