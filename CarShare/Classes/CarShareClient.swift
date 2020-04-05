//
//  CarShareClient.swift
//  CarShare
//
//  Created by Matt Snow on 2019-07-08.
//

import Foundation

/** This class is for handling interactions between the mobile application and the GO9 device. In order to respond
 to feedback from the SDK, you must set the delegate of the CarShareClient.
 
 ### Usage Example: ###
 ````
 private let client = CarShareClient()
 
 override func viewDidLoad() {
    super.viewDidLoad()
    client.delegate = self
 }
 ````
*/

public class CarShareClient: CommandProtocolDelegate {

    private struct CarShareToken {
        let bleServiceUuid: String
        let reservationPrivateKey: String
        let reservationModulusHash: Data
        let deploymentModulusHash: Data
        let reservationToken: Data
        let reservationTokenSignature: Data
    }

    private let commandProtocol: CommandProtocol
    private let tokenTransformer: TokenTransformer
    private let deviceCommandTransformer: DeviceCommandTransformer

    private var outgoingMessage: MessageStrategy?

    public weak var delegate: CarShareClientDelegate?

    /**
     Call this function to initialize the CarShareClient.
     The init function has been given default paramaters
     so there is no need to pass anything in.
     */

    public convenience init(logger: Logger = NoopLogger()) {
        self.init(commandProtocol: DefaultCommandProtocol(logger: logger), tokenTransformer: DefaultCarShareTokenTransformer(), deviceCommandTransformer: ProtobufDeviceCommandTransformer())
    }

    init(commandProtocol: CommandProtocol, tokenTransformer: TokenTransformer, deviceCommandTransformer: DeviceCommandTransformer) {
        self.commandProtocol = commandProtocol
        self.tokenTransformer = tokenTransformer
        self.deviceCommandTransformer = deviceCommandTransformer
    }

    /**
     To communicate with a carshare device, the connect function must first be invoked with valid
     carShareToken. The carShareToken parameter represents a valid reservation key which
     the carshare device authenticates against. Once the connection has been established,
     the delegate method clientDidConnect(_ client: CarShareClient) is called. Should the
     connection close suddenly, the delegate method
     clientDidDisconnectUnexpectedly(_ client: CarShareClient, error: Error) is called.

     - Parameter carShareToken: A valid, signed, reservation.
     
     - Throws: `TokenTransformerError.tokenDecodingFailed` if decoding carShareToken fails
     
     ### Usage Example: ###
     ````
     do {
        try client.connect("CiQwNTc0NTgzQi0wRDh...")
     } catch {
        print(error)
     }
     ````
     */

    public func connect(_ carShareToken: String) throws {
        do {
            let carShareToken = try tokenTransformer.transform(carShareToken)
            commandProtocol.delegate = self
            commandProtocol.open(generateConfig(bleServiceUUID: carShareToken.bleServiceUuid))
        } catch {
            print("Failed to decode reservation token")
            throw error
        }
    }

    /**
     Must be called to disconnect / cancel the Bluetooth connection between the SDK and the GO9 device.
     
     ### Usage Example: ###
     ````
     client.disconnect()
     ````
     */

    public func disconnect() {
        outgoingMessage = nil
        commandProtocol.close()
    }

    /**
     With a connection established to the carshare device, commands can be executed with the
     command passed in and a valid carShareToken. The execution of the command will result in
     either the CarShareClientDelegate method
     `protocol`(_ protocol: CommandProtocol, command: Command, didSucceed response: Data) or
     `protocol`(_ protocol: CommandProtocol, command: Command, didFail error: Error) being called.

     - Parameter command: An executable command.
     - Parameter carShareToken: A valid, signed, reservation.
     
     - Throws: `TokenTransformerError.tokenDecodingFailed` if decoding carShareToken fails
     
     ### Usage Example: ###
     ````
     do {
        try client.execute(.checkIn, with: "CiQwNTc0NTgzQi0wRDh...")
     } catch {
        print(error)
     }
     ````
     */

    @available(*, deprecated, message: "This function will be removed in the next release. Use execute(_ operations: Set<CarOperation>, with carShareToken: String) instead.")
    public func execute(_ command: Command, with carShareToken: String) throws {
        do {
            let tokenData = try tokenTransformer.transform(carShareToken)
            let commandProto = try deviceCommandTransformer.transform(command)
            outgoingMessage = CommandMessageStrategy(command: command)
            commandProtocol.send(OutgoingCommand(deviceCommandMessage: commandProto,
                                                 carShareTokenInfo: tokenData,
                                                 state: .requestingToSendMessage))
        } catch {
            print("Failed to decode reservation token")
            throw error
        }
    }

    /**
     With a connection established to the carshare device, commands can be executed with the
     command set passed in and a valid carShareToken. The execution of the command will result in
     either the CarShareClientDelegate method
     `protocol`(_ protocol: CommandProtocol, command: Command, didSucceed response: Data) or
     `protocol`(_ protocol: CommandProtocol, command: Command, didFail error: Error) being called.

     - Parameter [commands]: Executable commands.
     - Parameter carShareToken: A valid, signed, reservation.
     
     - Throws: `TokenTransformerError.tokenDecodingFailed` if decoding carShareToken fails
     
     ### Usage Example: ###
     ````
     do {
        try client.execute([.unlock, .mobilize, .locate], with: "CiQwNTc0NTgzQi0wRDh...")
     } catch {
        print(error)
     }
     ````
     */

    public func execute(_ operations: Set<CarOperation>, with carShareToken: String) throws {
        do {
            let tokenData = try tokenTransformer.transform(carShareToken)
            let commandProto = try deviceCommandTransformer.transform(operations)
            let message = OperationMessageStrategy(operations: operations)
            outgoingMessage = message
            commandProtocol.send(OutgoingCommand(deviceCommandMessage: commandProto,
                                                 carShareTokenInfo: tokenData,
                                                 state: .requestingToSendMessage))
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

    func `protocol`(_ protocol: CommandProtocol, didSucceed response: Data) {
        guard let outgoingMessage = outgoingMessage else {
            return
        }
        self.outgoingMessage = nil
        outgoingMessage.didSucceed(self)
    }

    func `protocol`(_ protocol: CommandProtocol, didFail error: Error) {
        guard let outgoingMessage = outgoingMessage else {
            return
        }
        self.outgoingMessage = nil
        outgoingMessage.didFail(self, error: error)
    }

    private func generateConfig(bleServiceUUID: String) -> BLeSocketConfiguration {
        return BLeSocketConfiguration(
            serviceID: bleServiceUUID,
            notifyCharacteristicID: "430F2EA3-C765-4051-9134-A341254CFD00",
            writeCharacteristicID: "906EE7E0-D8DB-44F3-AF54-6B0DFCECDF1C")
    }
}

extension CarShareClient {
    struct CommandMessageStrategy: MessageStrategy {

        let command: Command

        func didFail(_ carShareClient: CarShareClient, error: Swift.Error) {
            carShareClient.delegate?.clientCommandDidFail(carShareClient, command: command, error: error)
        }

        func didSucceed(_ carShareClient: CarShareClient) {
            carShareClient.delegate?.clientCommandDidSucceed(carShareClient, command: command)
        }
    }

    struct OperationMessageStrategy: MessageStrategy {

        let operations: Set<CarOperation>

        func didFail(_ carShareClient: CarShareClient, error: Swift.Error) {
            carShareClient.delegate?.clientOperationsDidFail(carShareClient, operations: operations, error: error)
        }
        func didSucceed(_ carShareClient: CarShareClient) {
            carShareClient.delegate?.clientOperationsDidSucceed(carShareClient, operations: operations)
        }
    }
}
