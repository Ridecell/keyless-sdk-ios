//
//  KeylessClient.swift
//  Keyless
//
//  Created by Matt Snow on 2019-07-08.
//

import Foundation

/** This class is for handling interactions between the mobile application and the GO9 device. In order to respond
 to feedback from the SDK, you must set the delegate of the KeylessClient.
 
 ### Usage Example: ###
 ````
 private let client = KeylessClient()
 
 override func viewDidLoad() {
    super.viewDidLoad()
    client.delegate = self
 }
 ````
*/

public class KeylessClient: CommandProtocolDelegate {

    enum KeylessClientError: Swift.Error, CustomStringConvertible {
        case notConnected
        case alreadyConnected

        var description: String {
            switch self {
            case .notConnected:
                return "Please establish a connection with the GO9 prior to executing a command. This can be done by calling the connect() function"
            case .alreadyConnected:
                return "You are already connected"
            }
        }
    }

    private struct KeylessToken {
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
    private let deviceToAppMessageTransformer: DeviceToAppMessageTransformer
    private let vehicleStatusDataTransformer: StatusDataTransformer

    private var outgoingMessage: MessageStrategy?

    public weak var delegate: KeylessClientDelegate?

    /**
     Call this function to initialize the KeylessClient.
     The init function has been given default paramaters
     so there is no need to pass anything in.
     */

    public convenience init(logger: Logger = NoopLogger()) {
        self.init(commandProtocol: DefaultCommandProtocol(logger: logger),
                  tokenTransformer: DefaultKeylessTokenTransformer(),
                  deviceCommandTransformer: ProtobufDeviceCommandTransformer(),
                  deviceToAppMessageTransformer: ProtobufDeviceToAppMessageTransformer(),
                  vehicleStatusDataTransformer: VehicleStatusDataTransformer()
        )
    }

    init(commandProtocol: CommandProtocol,
         tokenTransformer: TokenTransformer,
         deviceCommandTransformer: DeviceCommandTransformer,
         deviceToAppMessageTransformer: DeviceToAppMessageTransformer,
         vehicleStatusDataTransformer: StatusDataTransformer
    ) {
        self.commandProtocol = commandProtocol
        self.tokenTransformer = tokenTransformer
        self.deviceCommandTransformer = deviceCommandTransformer
        self.deviceToAppMessageTransformer = deviceToAppMessageTransformer
        self.vehicleStatusDataTransformer = vehicleStatusDataTransformer
    }

    /**
     To communicate with a Keyless device, the connect function must first be invoked with valid
     keylessToken. The keylessToken parameter represents a valid reservation key which
     the Keyless device authenticates against. Once the connection has been established,
     the delegate method clientDidConnect(_ client: KeylessClient) is called. Should the
     connection close suddenly, the delegate method
     clientDidDisconnectUnexpectedly(_ client: KeylessClient, error: Error) is called.

     - Parameter keylessToken: A valid, signed, reservation.
     
     - Throws: `TokenTransformerError.tokenDecodingFailed` if decoding keylessToken fails
     - Throws: `KeylessClientError.alreadyConnected` if the connection has already been established
     
     ### Usage Example: ###
     ````
     do {
        try client.connect("CiQwNTc0NTgzQi0wRDh...")
     } catch {
        print(error)
     }
     ````
     */

    public func connect(_ keylessToken: String) throws {
        guard !isConnected else {
            throw KeylessClientError.alreadyConnected
        }
        let keylessToken = try tokenTransformer.transform(keylessToken)
        commandProtocol.delegate = self
        commandProtocol.open(generateConfig(bleServiceUUID: keylessToken.bleServiceUuid))
    }

    /// can be queried to determine if the SDK considers itself connected to a GO9.
    public private(set) var isConnected: Bool = false

    /**
     Must be called to disconnect / cancel the Bluetooth connection between the SDK and the GO9 device.
     
     ### Usage Example: ###
     ````
     client.disconnect()
     ````
     */

    public func disconnect() {
        outgoingMessage = nil
        isConnected = false
        commandProtocol.close()
    }

    /**
     With a connection established to the Keyless device, operations can be executed with the
     operation set passed in and a valid keylessToken. The execution of the operations will result in
     either the KeylessClientDelegate method
     func clientOperationsDidSucceed(_ client: KeylessClient, operations: Set<CarOperation>) or
     func clientOperationsDidFail(_ client: KeylessClient, operations: Set<CarOperation>, error: Error) being called.

     - Parameter [commands]: Executable commands.
     - Parameter keylessToken: A valid, signed, reservation.
     
     - Throws: `KeylessClientError.notConnected` if the connection has yet to be established
     - Throws: `TokenTransformerError.tokenDecodingFailed` if decoding keylessToken fails
     - Throws: 'ProtobufDeviceCommandTransformerError.transformFailed(error: error)' if encoding fails
     
     ### Usage Example: ###
     ````
     do {
        try client.execute([.unlock, .ignitionEnable, .locate], with: "CiQwNTc0NTgzQi0wRDh...")
     } catch {
        print(error)
     }
     ````
     */

    public func execute(_ operations: Set<CarOperation>, with keylessToken: String) throws {
        guard isConnected else {
            throw KeylessClientError.notConnected
        }
        let tokenData = try tokenTransformer.transform(keylessToken)
        let commandProto = try deviceCommandTransformer.transform(operations)
        let message = OperationMessageStrategy(operations: operations)
        outgoingMessage = message
        commandProtocol.send(OutgoingCommand(deviceCommandMessage: commandProto,
                                             keylessTokenInfo: tokenData,
                                             state: .requestingToSendMessage))
    }

    func protocolDidOpen(_ protocol: CommandProtocol) {
        isConnected = true
        delegate?.clientDidConnect(self)
    }

    func protocolDidCloseUnexpectedly(_ protocol: CommandProtocol, error: Error) {
        disconnect()
        delegate?.clientDidDisconnectUnexpectedly(self, error: KeylessError(errors: [error]))
    }

    func `protocol`(_ protocol: CommandProtocol, didReceive response: Data) {
        guard let outgoingMessage = outgoingMessage else {
            return
        }
        self.outgoingMessage = nil
        switch deviceToAppMessageTransformer.transform(response) {
        case .success:
            outgoingMessage.didSucceed(self)
        case .failure(let error):
            switch error {
            case .ackFailed(let statusData):
                outgoingMessage.didFail(self, error: vehicleStatusDataTransformer.transform(statusData))
            case .protobufSerialization:
                outgoingMessage.didFail(self, error: KeylessError(errors: [error]))
            }
        }
    }

    func `protocol`(_ protocol: CommandProtocol, didFail error: Error) {
        guard let outgoingMessage = outgoingMessage else {
            return
        }
        self.outgoingMessage = nil
        outgoingMessage.didFail(self, error: KeylessError(errors: [error]))
    }

    private func generateConfig(bleServiceUUID: String) -> BLeSocketConfiguration {
        return BLeSocketConfiguration(
            serviceID: bleServiceUUID,
            notifyCharacteristicID: "430F2EA3-C765-4051-9134-A341254CFD00",
            writeCharacteristicID: "906EE7E0-D8DB-44F3-AF54-6B0DFCECDF1C")
    }
}

extension KeylessClient {

    struct OperationMessageStrategy: MessageStrategy {

        let operations: Set<CarOperation>

        func didFail(_ keylessClient: KeylessClient, error: Swift.Error) {
            keylessClient.delegate?.clientOperationsDidFail(keylessClient, operations: operations, error: error)
        }
        func didSucceed(_ keylessClient: KeylessClient) {
            keylessClient.delegate?.clientOperationsDidSucceed(keylessClient, operations: operations)
        }
    }
}
