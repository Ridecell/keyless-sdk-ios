import XCTest
@testable import CarShare

class DefaultTransportProtocolTests: XCTestCase {

    private var sut: DefaultTransportProtocol!

    private var socket: FakeSocket!

    private var recorder: TransportRecorder!

    private var executer: AsyncExecuter!

    override func setUp() {
        super.setUp()
        executer = FakeExecuter()
        recorder = TransportRecorder()
        socket = FakeSocket()
        sut = DefaultTransportProtocol(executer: executer, socket: socket)
        sut.delegate = recorder
    }

    override func tearDown() {
        sut = nil
        socket = nil
        recorder = nil
        executer = nil
        super.tearDown()
    }

    func testOpeningSocketPerformsHandshake() {
        sutOpen()
        syncAndShake()
        confirmAndSend()
        socket.delegate?.socket(socket, didReceive: validHandshakeAck())
        XCTAssertTrue(recorder.didOpen)
    }
    
    func testCloseIfUnexpectedAckValues() {
        sutOpen()
        syncAndShake()
        confirmAndSend()
        
        let ack: [UInt8] = [0x02, 0x02, 0x07, 0x04, 0x0A, 0x03]
        socket.delegate?.socket(socket, didReceive: Data(bytes: ack, count: ack.count))
        XCTAssertTrue(recorder.closeError != nil)
    }

    func testOpenningSocketFailsIfHandshakeButNoAck() {
        sutOpen()
        syncAndShake()
        confirmAndSend()
        XCTAssertFalse(recorder.didOpen)
    }

    func testHandshakeFail1() {
        sutOpen()
        let error = NSError(domain: "", code: 0, userInfo: nil)
        socket.delegate?.socketDidCloseUnexpectedly(socket, error: error)
        XCTAssertTrue(recorder.closeError! as NSError === error)
        XCTAssertTrue(socket.didClose)
    }

    func testHandshakeFail2() {
        sutOpen()

        socket.delegate?.socketDidOpen(socket)
        XCTAssertEqual(socket.dataToSend, validSyncByte())

        let error = NSError(domain: "", code: 0, userInfo: nil)
        socket.delegate?.socketDidFailToSend(socket, error: error)

        XCTAssertNotNil(recorder.closeError)
        XCTAssertTrue(socket.didClose)
    }
    
    func testSockDidFailToSendIfConnected() {
        sutOpen()
        syncAndShake()
        confirmAndSend()
        
        socket.delegate?.socket(socket, didReceive: validHandshakeAck())
        XCTAssertTrue(recorder.didOpen)
        let error = NSError(domain: "", code: 0, userInfo: nil)
        socket.delegate?.socketDidFailToSend(socket, error: error)
        XCTAssertNotNil(recorder.didFailToSend)
    }
    
    func testSockDidFailToReceiveIfConnected() {
        sutOpen()
        syncAndShake()
        confirmAndSend()
        socket.delegate?.socket(socket, didReceive: validHandshakeAck())
        XCTAssertTrue(recorder.didOpen)
        let error = NSError(domain: "", code: 0, userInfo: nil)
        socket.delegate?.socketDidFailToReceive(socket, error: error)
        XCTAssertNotNil(recorder.didFailToReceive)
    }
    
    func testSockDidFailToReceiveIfNotConnected() {
        sutOpen()
        let error = NSError(domain: "", code: 0, userInfo: nil)
        socket.delegate?.socketDidFailToReceive(socket, error: error)
        XCTAssertNotNil(recorder.closeError)
    }
    
    func testSockDidSendFailsIfNoMtu() {
        sutOpen()
        socket.mtu = nil
        sut.send(Data(bytes: [0x01], count: 1))
        XCTAssertNotNil(recorder.didFailToSend)
    }

    func testHandshakeFail3() {
        sutOpen()
        socket.delegate?.socketDidOpen(socket)
        XCTAssertEqual(socket.dataToSend, validSyncByte())

        socket.delegate?.socketDidSend(socket)


        let badHandshake: [UInt8] = [0x02, 0x01, 0x00, 0x03, 0x08, 0x04]
        socket.delegate?.socket(socket, didReceive: Data(bytes: badHandshake, count: 6))
        XCTAssertNotNil(recorder.closeError)
        XCTAssertTrue(socket.didClose)
    }

    func testHandshakeFail4() {
        sutOpen()
        XCTAssertTrue(socket.delegate as! DefaultTransportProtocol === sut)
        XCTAssertTrue(socket.didOpen)
        XCTAssertFalse(recorder.didOpen)

        socket.delegate?.socketDidOpen(socket)
        XCTAssertEqual(socket.dataToSend, validSyncByte())

        socket.delegate?.socketDidSend(socket)

        let error = NSError(domain: "", code: 0, userInfo: nil)

        socket.delegate?.socketDidFailToReceive(socket, error: error)
        XCTAssertNotNil(recorder.closeError)
        XCTAssertTrue(socket.didClose)
    }

    func testHandshakeFail5() {
        sutOpen()

        socket.delegate?.socketDidOpen(socket)
        XCTAssertEqual(socket.dataToSend, validSyncByte())

        socket.delegate?.socketDidSend(socket)


        let badHandshake: [UInt8] = [0x02, 0x01, 0x00, 0x03, 0x08, 0x03]
        socket.delegate?.socket(socket, didReceive: Data(bytes: badHandshake, count: 6))

        XCTAssertEqual(socket.dataToSend, validHandshakeConfirmation())

        let error = NSError(domain: "", code: 0, userInfo: nil)
        socket.delegate?.socketDidFailToSend(socket, error: error)
        XCTAssertNotNil(recorder.closeError)
        XCTAssertTrue(socket.didClose)
    }

    func testSendingData() {
        openSocket()
        let bytes: [UInt8] = [0x01]
        sut.send(Data(bytes: bytes, count: bytes.count))
        let expectedBytes: [UInt8] = [0x02, 0x88, 0x01, 0x00, 0x01, 0x8C, 0x2E, 0x03]
        XCTAssertEqual(expectedBytes, [UInt8](socket.dataToSend!))
    }

    func testReceivingData() {
        openSocket()
        let bytes: [UInt8] = [0x02, 0x24, 0x01, 0x00, 0x01, 0x28, 0x9E, 0x03]
        socket.delegate?.socket(socket, didReceive: Data(bytes: bytes, count: bytes.count))
        let expectedBytes: [UInt8] = [0x01]
        XCTAssertEqual(expectedBytes, [UInt8](recorder.receivedData!))
    }

    func testReceivingMalformedData() {
        openSocket()
        let bytes: [UInt8] = [0x01, 0x24, 0x01, 0x00, 0x01, 0x28, 0x9D, 0x03]
        socket.delegate?.socket(socket, didReceive: Data(bytes: bytes, count: bytes.count))
        XCTAssertNotNil(recorder.didFailToReceive)
    }

    func testSendingMultiChunkData() {
        openSocket()
        let bytes: [UInt8] = [0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x20]
        sut.send(Data(bytes: bytes, count: bytes.count))
        let expectedChunk1: [UInt8] = [0x02, 0x88, 0x14, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16]
        let expectedChunk2: [UInt8] = [0x17, 0x18, 0x19, 0x20, 0xB8, 0xB6, 0x03]
        XCTAssertEqual(expectedChunk1, [UInt8](socket.dataToSend!))
        socket.delegate?.socketDidSend(socket)
        XCTAssertEqual(expectedChunk2, [UInt8](socket.dataToSend!))
        socket.delegate?.socketDidSend(socket)

        socket.delegate?.socket(socket, didReceive: validBinaryDataResponse())
        XCTAssertTrue(recorder.didSend)
    }

    func testSendingMultiChunkDataButNoAck() {
        openSocket()
        let bytes: [UInt8] = [0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x20]
        sut.send(Data(bytes: bytes, count: bytes.count))
        let expectedChunk1: [UInt8] = [0x02, 0x88, 0x14, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16]
        let expectedChunk2: [UInt8] = [0x17, 0x18, 0x19, 0x20, 0xB8, 0xB6, 0x03]
        XCTAssertEqual(expectedChunk1, [UInt8](socket.dataToSend!))
        socket.delegate?.socketDidSend(socket)
        XCTAssertEqual(expectedChunk2, [UInt8](socket.dataToSend!))
        socket.delegate?.socketDidSend(socket)

        XCTAssertFalse(recorder.didSend)
    }

    func testReceivingMultiChunkData() {
        openSocket()
        let chunk1: [UInt8] = [0x02, 0x24, 0x14, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16]
        let chunk2: [UInt8] = [0x17, 0x18, 0x19, 0x20, 0x54, 0xBA, 0x03]
        socket.delegate?.socket(socket, didReceive: Data(bytes: chunk1, count: 20))
        socket.delegate?.socket(socket, didReceive: Data(bytes: chunk2, count: 7))
        let expectedBytes: [UInt8] = [0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x20]
        XCTAssertEqual(expectedBytes, [UInt8](recorder.receivedData!))

    }
    
    func testSocketCloses() {
        sut.close()
        XCTAssert(socket.didClose)
    }
    
    func testReceivingSubsequentHandshake() {
        sutOpen()
        syncAndShake()
        confirmAndSend()
        socket.delegate?.socket(socket, didReceive: validHandshakeAck())
        socket.delegate?.socket(socket, didReceive: validHandshakeRequest())
        XCTAssertEqual(socket.dataToSend, validHandshakeConfirmation())
    }
    
    private func openSocket() {
        sutOpen()
        syncAndShake()
        socket.delegate?.socketDidSend(socket)
        socket.delegate?.socket(socket, didReceive: validHandshakeAck())
    }
    
    private func sutOpen() {
        let configuration = BLeSocketConfiguration(
            serviceID: "SERVICE",
            notifyCharacteristicID: "NOTIFY",
            writeCharacteristicID: "WRITE")
        sut.open(configuration)
        XCTAssertTrue(socket.delegate as! DefaultTransportProtocol === sut)
        XCTAssertTrue(socket.didOpen)
        XCTAssertFalse(recorder.didOpen)
    }
    
    private func syncAndShake() {
        socket.delegate?.socketDidOpen(socket)
        XCTAssertEqual(socket.dataToSend, validSyncByte())
        socket.delegate?.socketDidSend(socket)
        socket.delegate?.socket(socket, didReceive: validHandshakeRequest())
    }
    
    private func confirmAndSend() {
        XCTAssertEqual(socket.dataToSend, validHandshakeConfirmation())
        socket.delegate?.socketDidSend(socket)
    }
    
    private func validHandshakeRequest() -> Data {
        let handshake: [UInt8] = [0x02, 0x01, 0x00, 0x03, 0x08, 0x03]
        return Data(bytes: handshake, count: 6)
    }
    
    private func validSyncByte() -> Data {
        let sync: [UInt8] = [0x55]
        return Data(bytes: sync, count: 1)
    }
    
    private func validHandshakeAck() -> Data {
        let ack: [UInt8] = [0x02, 0x02, 0x00, 0x04, 0x0A, 0x03]
        return Data(bytes: ack, count: ack.count)
    }
    
    private func validBinaryDataResponse() -> Data {
        let binaryDataResponse: [UInt8] = [0x02, 0x22, 0x04, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03]
        return Data(bytes: binaryDataResponse, count: binaryDataResponse.count)
    }
    
    private func validHandshakeConfirmation() -> Data {
        let confirmation: [UInt8] = [0x02, 0x81, 0x04, 0x5F, 0x10, 0x01, 0x00, 247, 214, 0x03]
        return Data(bytes: confirmation, count: 10)
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

    class FakeExecuter: AsyncExecuter {
        func after(_ seconds: TimeInterval, execute: @escaping () -> Void) {
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
        func protocolDidSend(_ protocol: TransportProtocol) {
            didSend = true
        }

        var didFailToSend: Error?
        func protocolDidFailToSend(_ protocol: TransportProtocol, error: Error) {
            didFailToSend = error
        }

        var didFailToReceive: Error?
        func protocolDidFailToReceive(_ protocol: TransportProtocol, error: Error) {
            didFailToReceive = error
        }
    }
}
