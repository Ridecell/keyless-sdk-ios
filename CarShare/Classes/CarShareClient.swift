//
//  CarShareClient.swift
//  CarShare
//
//  Created by Matt Snow on 2019-07-08.
//

import Foundation

public class CarShareClient: CommandProtocolDelegate {

    enum DefaultCarShareClientError: Error {
        case challengeFailed
        case tokenDecodingFailed
    }
    private struct CarShareToken {
        let bleServiceUuid: String
        let reservationPrivateKey: String
        let reservationModulusHash: Data
        let deploymentModulusHash: Data
        let reservationToken: Data
        let reservationTokenSignature: Data
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

    public func connect(_ carShareToken: String) throws {
        do {
            let carShareToken = try transformIntoCarshareToken(carShareToken)
            commandProtocol.delegate = self
            commandProtocol.open(generateConfig(bleServiceUUID: carShareToken.bleServiceUuid))
        } catch {
            print("Failed to decode reservation token")
            throw error
        }
    }

    public func disconnect() {
        commandProtocol.close()
    }

    public func execute(_ command: Command, with carShareToken: String) throws {
        do {
            let token = try transformIntoCarshareToken(carShareToken)
            let reservation = Reservation(token: token.reservationToken, privateKey: token.reservationPrivateKey)
            let message = Message(command: command, reservation: reservation)
            outgoingMessage = message
            commandProtocol.send(message, challengeKey: reservation.privateKey)
        } catch {
            print("Failed to decode reservation token")
            throw error
        }
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

    private func generateConfig(bleServiceUUID: String) -> BLeSocketConfiguration {
        return BLeSocketConfiguration(
            serviceID: bleServiceUUID,
            notifyCharacteristicID: "430F2EA3-C765-4051-9134-A341254CFD00",
            writeCharacteristicID: "906EE7E0-D8DB-44F3-AF54-6B0DFCECDF1C")
    }

    private func transformIntoCarshareToken(_ carShareToken: String) throws -> CarshareToken {
        guard let decodedData = Data(base64Encoded: carShareToken) else {
            throw DefaultCarShareClientError.tokenDecodingFailed
        }
        do {
            let token = try CarshareToken(serializedData: decodedData)
            return token
        } catch {
            throw DefaultCarShareClientError.tokenDecodingFailed
        }
    }

}
