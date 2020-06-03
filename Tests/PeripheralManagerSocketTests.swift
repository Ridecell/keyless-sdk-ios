//
//  PeripheralManagerSocketTests.swift
//  Keyless_Tests
//
//  Created by Marc Maguire on 2019-11-11.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import CoreBluetooth
import XCTest
@testable import Keyless

class PeripheralManagerSocketTests: XCTestCase {
    
    var sut: PeripheralManagerSocket!
    var delegate: Delegate!
    var peripheral: FakeCBPeripheralManager!
    var executer: ManualExecuter!

    private static let config = BLeSocketConfiguration(
        serviceID: "430F2EA3-C765-4051-9134-A341254CFD00",
        notifyCharacteristicID: "430F2EA3-C765-4051-9134-A341254CFD00",
        writeCharacteristicID: "906EE7E0-D8DB-44F3-AF54-6B0DFCECDF1C")

    private func notifyCharacteristic() -> CBCharacteristic {
        return CBMutableCharacteristic(
            type: CBUUID(nsuuid: UUID(uuidString: PeripheralManagerSocketTests.config.notifyCharacteristicID)!),
            properties: CBCharacteristicProperties(),
            value: nil,
            permissions: [])
    }

    override func setUp() {
        let peripheral = FakeCBPeripheralManager(delegate: nil, queue: nil)
        self.executer = ManualExecuter()
        let socket = PeripheralManagerSocket(peripheral: peripheral, executer: executer)
        self.peripheral = peripheral
        self.delegate = Delegate()
        socket.delegate = delegate
        self.sut = socket
    }

    override func tearDown() {
        sut = nil
        delegate = nil
        executer = nil
    }

    class ManualExecuter: AsyncExecuter {
        var task: (seconds: TimeInterval, execute: () -> Void)?
        func after(_ seconds: TimeInterval, execute: @escaping () -> Void) {
            task = (seconds, execute)
        }
    }

    func testDelegateReceivesFailureIfPoweredOffOnOpen() {
        // arrange
        peripheral.stubbedState = .poweredOff

        // act
        sut.open(PeripheralManagerSocketTests.config)
        executer.task!.execute()

        // assert
        XCTAssertTrue(delegate.socketDidCloseUnexpectedlyCalled)
        XCTAssertEqual(0, executer.task!.seconds)
    }

    func testPeripheralAddsServiceIfPoweredOnOnOpen() {
        // act
        sut.open(PeripheralManagerSocketTests.config)

        // assert
        XCTAssertEqual(1, peripheral.services.count)
    }

    func testDelegateReceivesFailureIfAddingServiceFails() {
        // arrange
        sut.open(PeripheralManagerSocketTests.config)

        // act
        peripheral.delegate?.peripheralManager?(peripheral, didAdd: peripheral.services.first!, error: PeripheralManagerSocket.SocketError.notConnected)
        executer.task!.execute()

        // assert
        XCTAssertTrue(delegate.socketDidCloseUnexpectedlyCalled)
        XCTAssertEqual(0, executer.task!.seconds)
    }

    func testPeripheralStartsAdvertisingIfServiceAdded() {
        // arrange
        sut.open(PeripheralManagerSocketTests.config)

        // act
        peripheral.delegate?.peripheralManager?(peripheral, didAdd: peripheral.services.first!, error: nil)

        // assert
        XCTAssertTrue(peripheral.isAdvertising)
    }

    func testDelegateReceivesFailureIfAdvertisingFails() {
        // arrange
        sut.open(PeripheralManagerSocketTests.config)
        peripheral.delegate?.peripheralManager?(peripheral, didAdd: peripheral.services.first!, error: nil)

        // act
        peripheral.delegate?.peripheralManagerDidStartAdvertising?(peripheral, error: PeripheralManagerSocket.SocketError.notConnected)
        executer.task!.execute()

        // assert
        XCTAssertTrue(delegate.socketDidCloseUnexpectedlyCalled)
        XCTAssertEqual(0, executer.task!.seconds)
    }

    func testDelegateDidOpen() {
        // arrange
        sut.open(PeripheralManagerSocketTests.config)
        let central = FakeCentral(maximumUpdateValueLength: 120)

        // act
        peripheral.delegate?.peripheralManager?(peripheral, central: central, didSubscribeTo: notifyCharacteristic())
        executer.task!.execute()

        // assert
        XCTAssertTrue(delegate.socketDidOpenCalled)
        XCTAssertEqual(0, executer.task!.seconds)
    }

    func testMTUIsSetOnDidSubscribeToCharacteristic() {
        // arrange
        let central = FakeCentral(maximumUpdateValueLength: 120)
        sut.open(PeripheralManagerSocketTests.config)

        // act
        peripheral.delegate?.peripheralManager?(peripheral, central: central, didSubscribeTo: notifyCharacteristic())

        // assert
        XCTAssertEqual(120, sut.mtu)
    }

    func testReceiveDoesNothingIfNotSubscribed() {
        // arrange
        let data: Data = Data(bytes: [0x01, 0x00, 0x00, 0x00], count: 4)
        let request = [FakeCBATTRequest(value: data, central: FakeCentral(maximumUpdateValueLength: 30))]
        sut.open(PeripheralManagerSocketTests.config)

        // act
        peripheral.delegate?.peripheralManager?(peripheral, didReceiveWrite: request)

        // assert
        XCTAssertFalse(delegate.sockDidReceiveCalled)
        XCTAssertFalse(delegate.socketDidFailToReceiveCalled)
        XCTAssertNil(executer.task)
    }

    func testReceiveFailsIfDifferentCentral() {
        // arrange
        let central = FakeCentral(maximumUpdateValueLength: 30)
        let data: Data = Data(bytes: [0x01, 0x00, 0x00, 0x00], count: 4)
        let request = [FakeCBATTRequest(value: data, central: FakeCentral(maximumUpdateValueLength: 30))]
        sut.open(PeripheralManagerSocketTests.config)
        peripheral.delegate?.peripheralManager?(peripheral, central: central, didSubscribeTo: notifyCharacteristic())
        executer.task = nil // open is called so we need to remove the executer's task.

        // act
        peripheral.delegate?.peripheralManager?(peripheral, didReceiveWrite: request)

        // assert
        XCTAssertFalse(delegate.sockDidReceiveCalled)
        XCTAssertFalse(delegate.socketDidFailToReceiveCalled)
        XCTAssertNil(executer.task)
    }

    func testSendingData() {
        // arrange
        sut.open(PeripheralManagerSocketTests.config)
        let central = FakeCentral(maximumUpdateValueLength: 30)
        peripheral.delegate?.peripheralManager?(peripheral, central: central, didSubscribeTo: notifyCharacteristic())

        // act
        sut.send("test".data(using: .utf8)!)
        executer.task!.execute()


        XCTAssertTrue(delegate.socketDidSendCalled)
        XCTAssertEqual(0, executer.task!.seconds)
    }

    func testSendingDataFailsIfNotConnected() {
        // arrange
        sut.open(PeripheralManagerSocketTests.config)

        // act
        sut.send("test".data(using: .utf8)!)
        executer.task!.execute()

        // assert
        XCTAssertTrue(delegate.socketDidFailToSendCalled)
        XCTAssertEqual(0, executer.task!.seconds)
    }

    func testCloseOnUnsubscribe() {
        // arrange
        sut.open(PeripheralManagerSocketTests.config)
        let central = FakeCentral(maximumUpdateValueLength: 30)
        peripheral.delegate?.peripheralManager?(peripheral, central: central, didSubscribeTo: notifyCharacteristic())

        // act
        peripheral.delegate?.peripheralManager?(peripheral, central: central, didUnsubscribeFrom: notifyCharacteristic())
        executer.task!.execute()

        // assert
        XCTAssertTrue(delegate.socketDidCloseUnexpectedlyCalled)
        XCTAssertEqual(0, executer.task!.seconds)
    }

    func testNoCloseOnUnsubscribeIfDifferentCentral() {
        // arrange
        sut.open(PeripheralManagerSocketTests.config)
        let central = FakeCentral(maximumUpdateValueLength: 30)
        peripheral.delegate?.peripheralManager?(peripheral, central: central, didSubscribeTo: notifyCharacteristic())

        // act
        peripheral.delegate?.peripheralManager?(peripheral, central: FakeCentral(maximumUpdateValueLength: 100), didUnsubscribeFrom: notifyCharacteristic())
        executer.task!.execute()

        // assert
        XCTAssertFalse(delegate.socketDidCloseUnexpectedlyCalled)
        XCTAssertEqual(0, executer.task!.seconds)
    }

    func testNoCloseIfUnsubscribeIsCalledWhenWeAreDisconnected() {
        // arrange
        sut.open(PeripheralManagerSocketTests.config)
        let central = FakeCentral(maximumUpdateValueLength: 30)
        peripheral.delegate?.peripheralManager?(peripheral, central: central, didSubscribeTo: notifyCharacteristic())

        // act
        sut.close()
        peripheral.delegate?.peripheralManager?(peripheral, central: central, didUnsubscribeFrom: notifyCharacteristic())
        executer.task!.execute()

        // assert
        XCTAssertFalse(delegate.socketDidCloseUnexpectedlyCalled)
        XCTAssertEqual(0, executer.task!.seconds)
    }

    func testRetryAfter3Seconds() {
        // arrange
        sut.open(PeripheralManagerSocketTests.config)

        // act 1
        peripheral.delegate?.peripheralManager?(peripheral, didAdd: peripheral.services.first!, error: nil)
        peripheral.delegate?.peripheralManagerDidStartAdvertising?(peripheral, error: nil)

        // assert 1
        XCTAssertEqual(1, peripheral.services.count)
        let task = executer.task!
        XCTAssertEqual(3, task.seconds)

        // arrange 2
        executer.task = nil
        peripheral.addServiceCalled = false
        peripheral.removeAllServicesCalled = false

        // act 2 to reset the peripheral
        task.execute()
        peripheral.delegate?.peripheralManager?(peripheral, didAdd: peripheral.services.first!, error: nil)

        // assert restart and new task in 3 seconds
        XCTAssertTrue(peripheral.removeAllServicesCalled)
        XCTAssertTrue(peripheral.addServiceCalled)
        XCTAssertEqual(1, peripheral.services.count)
    }

}

extension PeripheralManagerSocketTests {
    class Delegate: TransportProtocol, SocketDelegate {
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
        var addServiceCalled = false
        override func add(_ service: CBMutableService) {
            services.append(service)
            addServiceCalled = true
        }

        var removeAllServicesCalled = false
        override func removeAllServices() {
            services = []
            removeAllServicesCalled = true
        }

        override var isAdvertising: Bool { return advertisementData != nil }

        var advertisementData: [String : Any]? = nil
        override func startAdvertising(_ advertisementData: [String : Any]?) {
            self.advertisementData = advertisementData
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
    
    init(value: Data, central: FakeCentral) {
        _value = value
        _central = central
    }
}
