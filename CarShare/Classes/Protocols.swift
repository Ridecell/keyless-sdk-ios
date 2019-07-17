import Foundation

public struct BLeSocketConfiguration {
    public let serviceID: String
    public let characteristicID: String

    public init(serviceID: String, characteristicID: String) {
        self.serviceID = serviceID
        self.characteristicID = characteristicID
    }
}

public struct Reservation: Codable {
    public let certificate: String
    public let privateKey: String

    public init(certificate: String, privateKey: String) {
        self.certificate = certificate
        self.privateKey = privateKey
    }
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
    func socket(_ socket: Socket, didReceive: Data)
    func socketDidCloseUnexpectedly(_ socket: Socket, error: Error)
    func socketDidSend(_ socket: Socket, error: Error?)
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
    func protocolDidCloseUnexpectedly(_ protocol: TransportProtocol, error: Error)
    func protocolDidSend(_ protocol: TransportProtocol, error: Error?)
}

protocol CommandProtocol: AnyObject {
    var delegate: CommandProtocolDelegate? { get set }

    func open(_ configuration: BLeSocketConfiguration)
    func close()
    func send(_ command: Data, challengeKey: String)
}

protocol CommandProtocolDelegate: AnyObject {
    func protocolDidOpen(_ protocol: CommandProtocol)
    func protocolDidCloseUnexpectedly(_ protocol: CommandProtocol, error: Error)
    func `protocol`(_ protocol: CommandProtocol, command: Data, didSucceed response: Data)
    func `protocol`(_ protocol: CommandProtocol, command: Data, didFail error: Error)
}

public protocol CarShareClient: AnyObject {
    var delegate: CarShareClientConnectionDelegate? { get set }

    func connect(_ configuration: BLeSocketConfiguration)
    func disconnect()
    func checkIn(with reservation: Reservation, callback: @escaping (Result<Void, Error>) -> Void)
    func checkOut(with reservation: Reservation, callback: @escaping (Result<Void, Error>) -> Void)
    func lock(with reservation: Reservation, callback: @escaping (Result<Void, Error>) -> Void)
    func unlock(with reservation: Reservation, callback: @escaping (Result<Void, Error>) -> Void)
    func locate(with reservation: Reservation, callback: @escaping (Result<Void, Error>) -> Void)
}

public protocol CarShareClientConnectionDelegate: AnyObject {
    func clientDidConnect(_ client: CarShareClient)
    func clientDidDisconnectUnexpectedly(_ client: CarShareClient, error: Error)
}

public protocol Signer: AnyObject {
    func sign(_ challengeData: Data) -> Data?
    func sign(_ base64ChallengeString: String) -> String?
}

public protocol Verifier: AnyObject {
    func verify(_ challengeData: Data, withSigned response: Data) -> Bool
    func verify(_ base64ChallengeString: String, withSigned response: String) -> Bool
}

public protocol Securable: AnyObject {
    func encrypt(_ message: [UInt8], with encryptionKey: EncryptionKey) -> [UInt8]
    func decrypt(_ encrypted: [UInt8], with encryptionKey: EncryptionKey) -> [UInt8]
}
