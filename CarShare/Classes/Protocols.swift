// swiftlint:disable:this file_name

import Foundation

public struct BLeSocketConfiguration {
    public let serviceID: String
    public let notifyCharacteristicID: String
    public let writeCharacteristicID: String

    public init(serviceID: String, notifyCharacteristicID: String, writeCharacteristicID: String) {
        self.serviceID = serviceID
        self.notifyCharacteristicID = notifyCharacteristicID
        self.writeCharacteristicID = writeCharacteristicID
    }
}

public enum Command {
    case checkIn
    case checkOut
    case lock
    case unlockAll
    case locate
}

public enum CarOperation {
    case checkIn
    case checkOut
    case lock
    case unlockAll
    case unlockDriver
    case locate
    case mobilize
    case immobilize
    case openTrunk
    case closeTrunk
}

protocol MessageStrategy {
    func didFail(_ carShareClient: CarShareClient, error: Swift.Error)
    func didSucceed(_ carShareClient: CarShareClient)
}

protocol Socket: AnyObject {
    var delegate: SocketDelegate? { get set }

    var mtu: Int? { get }

    func open(_ configuration: BLeSocketConfiguration)
    func close()
    func send(_ data: Data)
}

protocol SocketDelegate: AnyObject {
    func socketDidOpen(_ socket: Socket)
    func socket(_ socket: Socket, didReceive data: Data)
    func socketDidSend(_ socket: Socket)
    func socketDidCloseUnexpectedly(_ socket: Socket, error: Error)
    func socketDidFailToReceive(_ socket: Socket, error: Error)
    func socketDidFailToSend(_ socket: Socket, error: Error)
}

protocol TransportProtocol: AnyObject {
    var delegate: TransportProtocolDelegate? { get set }

    func open(_ configuration: BLeSocketConfiguration)
    func close()
    func send(_ data: Data)
}

protocol TransportProtocolDelegate: AnyObject {
    func protocolDidOpen(_ protocol: TransportProtocol)
    func `protocol`(_ protocol: TransportProtocol, didReceive: Data)
    func protocolDidSend(_ protocol: TransportProtocol)
    func protocolDidCloseUnexpectedly(_ protocol: TransportProtocol, error: Error)
    func protocolDidFailToSend(_ protocol: TransportProtocol, error: Error)
    func protocolDidFailToReceive(_ protocol: TransportProtocol, error: Error)
}

protocol CommandProtocol: AnyObject {
    var delegate: CommandProtocolDelegate? { get set }

    func open(_ configuration: BLeSocketConfiguration)
    func close()
    func send(_ command: OutgoingCommand)
}

struct OutgoingCommand {
    let deviceCommandMessage: Data
    let carShareTokenInfo: CarShareTokenInfo
    var state: CommandState
}

enum CommandState {
    case requestingToSendMessage
    case waitingForChallenge
    case issuingCommand
    case awaitingChallengeAck
    case awaitingDeviceAck
}

protocol CommandProtocolDelegate: AnyObject {
    func protocolDidOpen(_ protocol: CommandProtocol)
    func protocolDidCloseUnexpectedly(_ protocol: CommandProtocol, error: Error)
    func `protocol`(_ protocol: CommandProtocol, didReceive response: Data)
    func `protocol`(_ protocol: CommandProtocol, didFail error: Error)
}

public protocol CarShareClientDelegate: AnyObject {

    /**
     This is the delegate callback that is called once a `client.connect()' call has succeeded.
     
     - Parameter client: The CarShareClient instance that called the method.
     */

    func clientDidConnect(_ client: CarShareClient)

    /**
     This is the delegate callback that is called due to the Bluetooth connection between
     the SDK and the GO9 being terminated.
     
     - Parameter client: The CarShareClient instance that called the method.
     - Parameter error: The error that caused the disconnect.
     */

    func clientDidDisconnectUnexpectedly(_ client: CarShareClient, error: Error)

    /**
     This is the delegate callback that is called once a `execute(_ command: Command, with carShareToken: String)' call has succeeded.
     
     - Parameter client: The CarShareClient instance that called the method.
     - Parameter command: The command that succeeded.
     */

    func clientCommandDidSucceed(_ client: CarShareClient, command: Command)

    /**
     This is the delegate callback that is called if a `execute(_ command: Command, with carShareToken: String)' call has failed.
     
     - Parameter client: The CarShareClient instance that called the method.
     - Parameter command: The command that failed.
     - Parameter error: The error that caused the failure.
     */

    func clientCommandDidFail(_ client: CarShareClient, command: Command, error: Error)

    /**
     This is the delegate callback that is called once a `execute(_ operations: Set<CarOperation>, with carShareToken: String)' call has succeeded.
     
     - Parameter client: The CarShareClient instance that called the method.
     - Parameter operations: The set of operations that succeeded.
     */

    func clientOperationsDidSucceed(_ client: CarShareClient, operations: Set<CarOperation>)

    /**
     This is the delegate callback that is called if a `execute(_ operations: Set<CarOperation>, with carShareToken: String)' call has failed.
     
     - Parameter client: The CarShareClient instance that called the method.
     - Parameter operations: The set of operations that failed.
     - Parameter error: The error that caused the failure.
     */

    func clientOperationsDidFail(_ client: CarShareClient, operations: Set<CarOperation>, error: Error)
}

public protocol Verifier: AnyObject {
    func verify(_ challengeData: Data, withSigned response: Data) -> Bool
    func verify(_ base64ChallengeString: String, withSigned response: String) -> Bool
}
