//
//  IOSocketTests.swift
//  CarShare_Tests
//
//  Created by Marc Maguire on 2019-11-11.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import CoreBluetooth
import XCTest
@testable import CarShare

class IOSocketTests: XCTestCase {
    
    var sut: IOSSocket!
    var transportProtocol: FakeTransportProtocol!
    var peripheral: FakeCBPeripheralManager!

    override func setUp() {
        let peripheral = FakeCBPeripheralManager(delegate: nil, queue: nil)
        let socket = IOSSocket(peripheral: peripheral)
        self.peripheral = peripheral
        self.transportProtocol = FakeTransportProtocol()
        socket.delegate = transportProtocol
        self.sut = socket
    }

    override func tearDown() {
        sut = nil
        transportProtocol = nil
    }
    
    func testMTUSetsOnConnectionAndMTUChange() {
        XCTAssert(sut.mtu == nil)
        sut.open(bleConfig())
        let central = FakeCentral(maximumUpdateValueLength: 30)
        let characteristic = FakeCBCharacteristic(foo: "dontdie")
        
        
        
        peripheral.delegate?.peripheralManager?(peripheral, central: central, didSubscribeTo: characteristic)
        XCTAssert(sut.mtu == 30)
        XCTAssert(transportProtocol.socketDidOpenCalled)
    }
    
    func testClosesIfPeripherIsPoweredOff() {
        XCTAssert(sut.mtu == nil)
        peripheral.stubbedState = .poweredOff
        sut.open(bleConfig())
        peripheral.delegate?.peripheralManager?(peripheral, central: central(mtu: 30), didSubscribeTo: characteristic())
        XCTAssert(transportProtocol.socketDidCloseUnexpectedlyCalled)
    }
    
    func testReceiveWritingFailsIfDifferentCentral() {
        XCTAssert(sut.mtu == nil)
        peripheral.stubbedState = .poweredOn
        sut.open(bleConfig())
        peripheral.delegate?.peripheralManager?(peripheral, central: central(mtu: 30), didSubscribeTo: characteristic())
        peripheral.stubbedState = .poweredOn
        //can't seem to mock past this point
        peripheral.delegate?.peripheralManager?(peripheral, didReceiveWrite: attributeRequest())
        XCTAssertFalse(transportProtocol.sockDidReceiveCalled)

    }
    
    func testSendingData() {
        XCTAssert(sut.mtu == nil)
        sut.open(bleConfig())
        let central = FakeCentral(maximumUpdateValueLength: 30)
        let characteristic = FakeCBCharacteristic(foo: "dontdie")
        
        peripheral.delegate?.peripheralManager?(peripheral, central: central, didSubscribeTo: characteristic)
        sut.send("test".data(using: .utf8)!)
        XCTAssert(sut.mtu == 30)
        XCTAssert(transportProtocol.socketDidOpenCalled)
        XCTAssertTrue(transportProtocol.socketDidSendCalled)
    }
    
    func testSendingDataFailsIfNotConnected() {
        XCTAssert(sut.mtu == nil)
        sut.open(bleConfig())
        sut.send("test".data(using: .utf8)!)
        XCTAssert(transportProtocol.socketDidFailToSendCalled)
    }
    
    func testCloseOnUnsubscribe() {
        XCTAssert(sut.mtu == nil)
        sut.open(bleConfig())
        let central = FakeCentral(maximumUpdateValueLength: 30)
        let characteristic = FakeCBCharacteristic(foo: "dontdie")
        peripheral.delegate?.peripheralManager?(peripheral, central: central, didSubscribeTo: characteristic)
        peripheral.delegate?.peripheralManager?(peripheral, central: central, didUnsubscribeFrom: FakeCBCharacteristic(foo: "fake"))
        XCTAssertTrue(transportProtocol.socketDidCloseUnexpectedlyCalled)
    }
    
    func testNoCloseOnUnsubscribeIfDifferentCentral() {
        XCTAssert(sut.mtu == nil)
        sut.open(bleConfig())
        let central = FakeCentral(maximumUpdateValueLength: 30)
        let characteristic = FakeCBCharacteristic(foo: "dontdie")
        peripheral.delegate?.peripheralManager?(peripheral, central: central, didSubscribeTo: characteristic)
        peripheral.delegate?.peripheralManager?(peripheral, central: FakeCentral(maximumUpdateValueLength: 100), didUnsubscribeFrom: FakeCBCharacteristic(foo: "fake"))
        XCTAssertFalse(transportProtocol.socketDidCloseUnexpectedlyCalled)
    }
    
    func testNoCloseIfUnsubscribeIsCalledWhenWeAreDisconnected() {
        XCTAssert(sut.mtu == nil)
        sut.open(bleConfig())
        let central = FakeCentral(maximumUpdateValueLength: 30)
        let characteristic = FakeCBCharacteristic(foo: "dontdie")
        peripheral.delegate?.peripheralManager?(peripheral, central: central, didSubscribeTo: characteristic)
        sut.close()
        peripheral.delegate?.peripheralManager?(peripheral, central: central, didUnsubscribeFrom: FakeCBCharacteristic(foo: "fake"))
        XCTAssertFalse(transportProtocol.socketDidCloseUnexpectedlyCalled)
    }
    
    private func attributeRequest() -> [CBATTRequest] {
        let bytes: [UInt8] = [0x01, 0x00, 0x00, 0x00]
        let data: Data = Data(bytes: bytes, count: bytes.count)
        return [FakeCBATTRequest(value: data)]
    }
    
    private func central(mtu maximumUpdateValueLength: Int) -> CBCentral {
        return FakeCentral(maximumUpdateValueLength: maximumUpdateValueLength)
    }
    
    private func characteristic() -> CBCharacteristic {
        return FakeCBCharacteristic(foo: "HackHacky")
    }
    
    private func bleConfig() -> BLeSocketConfiguration {
        return BLeSocketConfiguration(
            serviceID: "430F2EA3-C765-4051-9134-A341254CFD00",
            notifyCharacteristicID: "430F2EA3-C765-4051-9134-A341254CFD00",
            writeCharacteristicID: "906EE7E0-D8DB-44F3-AF54-6B0DFCECDF1C")
    }

}

extension IOSocketTests {
    class FakeTransportProtocol: TransportProtocol, SocketDelegate {
        var delegate: TransportProtocolDelegate?
        
        var openCalled: Bool = false
        func open(_ configuration: BLeSocketConfiguration) {
            openCalled = true
        }
        
        var closeCalled: Bool = false
        func close() {
            closeCalled = true
        }
        
        var sendCalled: Bool = false
        var sentData: Data? = nil
        func send(_ data: Data) {
            sendCalled = true
            sentData = data
        }
        
        var socketDidOpenCalled: Bool = false
        func socketDidOpen(_ socket: Socket) {
            socketDidOpenCalled = true
        }
        
        var sockDidReceiveCalled: Bool = false
        var receivedData: Data?
        func socket(_ socket: Socket, didReceive data: Data) {
            sockDidReceiveCalled = true
            receivedData = data
        }
        
        var socketDidSendCalled: Bool = false
        func socketDidSend(_ socket: Socket) {
            socketDidSendCalled = true
        }
        
        var socketDidCloseUnexpectedlyCalled: Bool = false
        func socketDidCloseUnexpectedly(_ socket: Socket, error: Error) {
            socketDidCloseUnexpectedlyCalled = true
        }
        
        var socketDidFailToReceiveCalled: Bool = false
        func socketDidFailToReceive(_ socket: Socket, error: Error) {
            socketDidFailToReceiveCalled = true
        }
        var socketDidFailToSendCalled: Bool = false
        func socketDidFailToSend(_ socket: Socket, error: Error) {
            socketDidFailToSendCalled = true
        }
    }
    
    class FakeCBPeripheralManager: CBPeripheralManager {
        
        var stubbedState: CBManagerState = .poweredOn
        override var state: CBManagerState { return stubbedState }
        
        var services: [CBMutableService] = []
        override func add(_ service: CBMutableService) {
            
        }
        
        var isISAdvertising: Bool = false
        var advertisementData: [String : Any?] = [:]
        override func startAdvertising(_ advertisementData: [String : Any]?) {
            isISAdvertising = true
        }
    }

}

class FakeCentral: CBCentral {
    override var maximumUpdateValueLength: Int { return _maximumUpdateValueLength }
    private var _maximumUpdateValueLength: Int
    
    override var identifier: UUID { return _identifier }
    private var _identifier: UUID = UUID(uuidString: "906EE7E0-D8DB-44F3-AF54-6B0DFCECDF1C")!
    init(maximumUpdateValueLength: Int) {
        _maximumUpdateValueLength = maximumUpdateValueLength
    }
}
class FakeCBCharacteristic: CBCharacteristic {
    
    init(foo: String) {

    }
}

class FakeCBAttribute: CBAttribute {
    override var uuid: CBUUID { return _uuid }
    var _uuid: CBUUID
    
    init(stubUUID: String) {
        _uuid = CBUUID(string: stubUUID)
    }
}

class FakeCBATTRequest: CBATTRequest {
    override var value: Data? {
        get {
            return _value
            
        } set {
            _value = newValue
        }
    }
    
    override var central: FakeCentral {
        return _central
    }
    var _value: Data?
    var _central: FakeCentral
    
    init(value: Data, centrals: FakeCentral = FakeCentral(maximumUpdateValueLength: 30)) {
        _value = value
        _central = centrals
    }
}




