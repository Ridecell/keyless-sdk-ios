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

    private struct Message {

        enum Command: UInt8 {
            case checkIn = 0x01
            case checkOut = 0x02
            case lock = 0x03
            case unlock = 0x04
            case locate = 0x05
        }

        let command: Command
        let reservation: Reservation
        let callback: (Result<Void, Error>) -> Void

        var data: Data {
            guard let tokenData = reservation.certificate.data(using: .utf8) else {
                fatalError("Could not encode confirmation token.")
            }
            var data = Data(bytes: [command.rawValue], count: 1)
            data.append(tokenData)
            return data
        }

        var expectedResponseData: Data {
            return Data(bytes: [0x01], count: 1)
        }
    }

    private let commandProtocol: CommandProtocol

    private var outgoingMessage: Message?

    public weak var delegate: CarShareClientConnectionDelegate?

    public convenience init() {
        self.init(commandProtocol: DefaultCommandProtocol(transportProtocol: DefaultTransportProtocol(socket: IOSSocket())))
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

    public func checkIn(with reservation: Reservation, callback: @escaping (Result<Void, Error>) -> Void) {
        let message = Message(command: .checkIn, reservation: reservation, callback: callback)
        outgoingMessage = message
        commandProtocol.send(message.data, challengeKey: reservation.privateKey)
    }

    public func checkOut(with reservation: Reservation, callback: @escaping (Result<Void, Error>) -> Void) {
        let message = Message(command: .checkOut, reservation: reservation, callback: callback)
        outgoingMessage = message
        commandProtocol.send(message.data, challengeKey: reservation.privateKey)
    }

    public func lock(with reservation: Reservation, callback: @escaping (Result<Void, Error>) -> Void) {
        let message = Message(command: .lock, reservation: reservation, callback: callback)
        outgoingMessage = message
        commandProtocol.send(message.data, challengeKey: reservation.privateKey)
    }

    public func unlock(with reservation: Reservation, callback: @escaping (Result<Void, Error>) -> Void) {
        let message = Message(command: .unlock, reservation: reservation, callback: callback)
        outgoingMessage = message
        commandProtocol.send(message.data, challengeKey: reservation.privateKey)
    }

    public func locate(with reservation: Reservation, callback: @escaping (Result<Void, Error>) -> Void) {
        let message = Message(command: .locate, reservation: reservation, callback: callback)
        outgoingMessage = message
        commandProtocol.send(message.data, challengeKey: reservation.privateKey)
    }

    func protocolDidOpen(_ protocol: CommandProtocol) {
        delegate?.clientDidConnect(self)
    }

    func protocolDidCloseUnexpectedly(_ protocol: CommandProtocol, error: Error) {
        delegate?.clientDidDisconnectUnexpectedly(self, error: error)
    }

    func `protocol`(_ protocol: CommandProtocol, command: Data, didSucceed response: Data) {
        guard let message = outgoingMessage else {
            return
        }
        outgoingMessage = nil
        if response == message.expectedResponseData {
            message.callback(.success(()))
        } else {
            message.callback(.failure(DefaultCarShareClientError.challengeFailed))
        }
    }

    func `protocol`(_ protocol: CommandProtocol, command: Data, didFail error: Error) {
        guard let message = outgoingMessage else {
            return
        }
        outgoingMessage = nil
        message.callback(.failure(error))
    }
}
