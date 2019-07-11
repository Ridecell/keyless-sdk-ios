import XCTest
@testable import CarShare

class DefaultTransportProtocolTests: XCTestCase {

    private var sut: DefaultTransportProtocol!

    private var socket: FakeSocket!

    private var recorder: TransportRecorder!

    override func setUp() {
        super.setUp()
        recorder = TransportRecorder()
        socket = FakeSocket()
        sut = DefaultTransportProtocol(socket: socket)
        sut.delegate = recorder
    }

    override func tearDown() {
        recorder = nil
        socket = nil
        sut = nil
        super.tearDown()
    }

    func testOpenningSocketPerformsHandshake() {
        let configuration = BLeSocketConfiguration(
            serviceID: "SERVICE",
            notifyCharacteristicID: "NOTIFY",
            writeCharacteristicID: "WRITE")
        sut.open(configuration)

        XCTAssertTrue(socket.delegate as! DefaultTransportProtocol === sut)
        XCTAssertTrue(socket.didOpen)
        XCTAssertFalse(recorder.didOpen)

        socket.delegate?.socketDidOpen(socket)

        let sync: [UInt8] = [0x55]
        XCTAssertEqual(socket.dataToSend, Data(bytes: sync, count: 1))

        socket.delegate?.socketDidSend(socket, error: nil)

        let handshake: [UInt8] = [0x02, 0x01, 0x00, 0x03, 0x08, 0x03]
        socket.delegate?.socket(socket, didReceive: Data(bytes: handshake, count: 6))

        let confirmation: [UInt8] = [0x02, 0x81, 0x04, 0x5D, 0x10, 0x00, 0x00, 0xF4, 0xCC, 0x03]
        XCTAssertEqual(socket.dataToSend, Data(bytes: confirmation, count: 10))

        socket.delegate?.socketDidSend(socket, error: nil)
        XCTAssertTrue(recorder.didOpen)
    }

}

extension DefaultTransportProtocolTests {
    class FakeSocket: Socket {
        weak var delegate: SocketDelegate?

        var mtu: Int? = 20

        var didOpen = false
        func open(_ configuration: BLeSocketConfiguration) {
            didOpen = true
        }

        var didClose = false
        func close() {
            didClose = true
        }

        var dataToSend: Data?
        func send(_ data: Data) {
            dataToSend = data
        }

    }

    class TransportRecorder: TransportProtocolDelegate {
        var didOpen = false
        func protocolDidOpen(_ protocol: TransportProtocol) {
            didOpen = true
        }

        var receivedData: Data?
        func `protocol`(_ protocol: TransportProtocol, didReceive: Data) {
            receivedData = didReceive
        }

        var closeError: Error?
        func protocolDidCloseUnexpectedly(_ protocol: TransportProtocol, error: Error) {
            closeError = error
        }

        var didSend = false
        func protocolDidSend(_ protocol: TransportProtocol, error: Error?) {
            didSend = true
        }
    }
}
