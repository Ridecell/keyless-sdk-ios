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

    private var outgoingMessage: Message?

    public weak var delegate: CarShareClientDelegate?

    /**
     Call this function to initialize the CarShareClient.
     The init function has been given default paramaters
     so there is no need to pass anything in.
     */

    public convenience init() {
        self.init(commandProtocol: DefaultCommandProtocol(), tokenTransformer: DefaultCarShareTokenTransformer())
    }

    init(commandProtocol: CommandProtocol, tokenTransformer: TokenTransformer) {
        self.commandProtocol = commandProtocol
        self.tokenTransformer = tokenTransformer
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

    public func execute(_ command: Command, with carShareToken: String) throws {
        do {
            let tokenData = try tokenTransformer.transform(carShareToken)
            //remove message and pass down two params
            let message = Message(command: command, carShareTokenInfo: tokenData)
            outgoingMessage = message
            commandProtocol.send(message)
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
        guard outgoingMessage != nil else {
            return
        }
        outgoingMessage = nil
        delegate?.clientCommandDidSucceed(self, command: command)
    }

    func `protocol`(_ protocol: CommandProtocol, command: Command, didFail error: Error) {
         guard outgoingMessage != nil else {
            return
        }
        outgoingMessage = nil
        delegate?.clientCommandDidFail(self, command: command, error: error)
    }

    private func generateConfig(bleServiceUUID: String) -> BLeSocketConfiguration {
        return BLeSocketConfiguration(
            serviceID: bleServiceUUID,
            notifyCharacteristicID: "430F2EA3-C765-4051-9134-A341254CFD00",
            writeCharacteristicID: "906EE7E0-D8DB-44F3-AF54-6B0DFCECDF1C")
    }
}
