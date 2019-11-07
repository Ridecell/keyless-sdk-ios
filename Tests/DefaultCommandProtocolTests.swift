//
//  DefaultCommandProtocolTests.swift
//  CarShare_Tests
//
//  Created by Marc Maguire on 2019-11-06.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import XCTest
@testable import CarShare

class DefaultCommandProtocolTests: XCTestCase {
    
    var sut: DefaultCommandProtocol!
    var deviceCommandTransformer: FakeDeviceCommandTransformer!
    var challengeSigner: FakeChallengeSigner!
    var encryptionHandler: FakeEncryptionHandler!
    var transportProtocol: FakeTransportProtocol!
    var delegate: CommandDelegate!

    override func setUp() {
        let transportProtocol = FakeTransportProtocol()
        let deviceCommandTransformer = FakeDeviceCommandTransformer()
        let challengeSigner = FakeChallengeSigner()
        let encryptionHandler = FakeEncryptionHandler()
        let defaultCommandProtocol = DefaultCommandProtocol(transportProtocol: transportProtocol,
                                                            deviceCommandTransformer: deviceCommandTransformer,
                                                            challengeSigner: challengeSigner,
                                                            encryptionHandler: encryptionHandler)
        let delegate = CommandDelegate()
        defaultCommandProtocol.delegate = delegate
        self.sut = defaultCommandProtocol
        self.deviceCommandTransformer = deviceCommandTransformer
        self.challengeSigner = challengeSigner
        self.encryptionHandler = encryptionHandler
        self.transportProtocol = transportProtocol
        self.delegate = delegate
    }

    override func tearDown() {
        self.sut = nil
        self.deviceCommandTransformer = nil
        self.challengeSigner = nil
        self.encryptionHandler = nil
        self.transportProtocol = nil
        self.delegate = nil
    }
    
    func testOpeningTransportProtocol() {
        let config = BLeSocketConfiguration(serviceID: "SERVICE_ID",
                                            notifyCharacteristicID: "NOTIFY_ID",
                                            writeCharacteristicID: "WRITE_ID")
        sut.open(config)
        XCTAssertTrue(transportProtocol.openCalled)
        
        sut.protocolDidOpen(transportProtocol)
        XCTAssertTrue(delegate.didOpenCalled)
    }
    
    func testClosingTransportProtocol() {
        sut.close()
        XCTAssertTrue(transportProtocol.closeCalled)
    }
    
    func testSendingCommandSuccess() {
        let carShareTokenInfo = getCarShareTokenInfo()
        let message = Message(command: .checkIn, carShareTokenInfo: carShareTokenInfo)
        
        sut.send(message)
        XCTAssertTrue(transportProtocol.sendCalled)
        XCTAssertTrue(transportProtocol.sentData != nil)
        XCTAssertTrue([UInt8](transportProtocol.sentData!) == [0x00, 0x01, 0x00])
        
        sut.protocolDidSend(transportProtocol)
        let randomBytes = [UInt8](Data(repeating: UInt8.random(in: UInt8.min...UInt8.max), count: 32))
        var challenge: [UInt8] = [0x01, 0x01, 0x00]
        challenge.append(contentsOf: randomBytes)
        sut.protocol(transportProtocol, didReceive: Data(bytes: challenge, count: challenge.count))
        
        sut.protocolDidSend(transportProtocol)
        var iv = [UInt8](Data(repeating: UInt8.random(in: UInt8.min...UInt8.max), count: 16))
        iv.append(contentsOf: [0x81,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00])
        
        sut.protocol(transportProtocol, didReceive: Data(bytes: iv, count: iv.count))
        XCTAssertTrue(delegate.didSucceedCalled)
        XCTAssertTrue(delegate.didSucceedData != nil)
        XCTAssertTrue([UInt8](delegate.didSucceedData!)[16] == 129)
    }
    
    func testSendingCommandFailedOnMalformedChallenge() {
        let carShareTokenInfo = getCarShareTokenInfo()
        let message = Message(command: .checkIn, carShareTokenInfo: carShareTokenInfo)
        sut.send(message)
        
        XCTAssertTrue(transportProtocol.sendCalled)
        
        sut.protocolDidSend(transportProtocol)
        sut.protocol(transportProtocol, didReceive: Data(bytes: [0x00,0x00], count: 2))
        XCTAssertTrue(delegate.didFailCalled)
    }
    
    func testSendingCommandFailedOnChallengeAck() {
        let carShareTokenInfo = getCarShareTokenInfo()
        let message = Message(command: .checkIn, carShareTokenInfo: carShareTokenInfo)
        
        sut.send(message)
        XCTAssertTrue(transportProtocol.sendCalled)
        XCTAssertTrue(transportProtocol.sentData != nil)
        XCTAssertTrue([UInt8](transportProtocol.sentData!) == [0x00, 0x01, 0x00])
        
        sut.protocolDidSend(transportProtocol)
        let randomBytes = [UInt8](Data(repeating: UInt8.random(in: UInt8.min...UInt8.max), count: 32))
        var challenge: [UInt8] = [0x01, 0x01, 0x00]
        challenge.append(contentsOf: randomBytes)
        sut.protocol(transportProtocol, didReceive: Data(bytes: challenge, count: challenge.count))
        
        sut.protocolDidSend(transportProtocol)
        var iv = [UInt8](Data(repeating: UInt8.random(in: UInt8.min...UInt8.max), count: 16))
        iv.append(contentsOf: [0x81,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00])
        
        sut.protocol(transportProtocol, didReceive: Data(bytes: iv, count: iv.count))
        XCTAssertTrue(delegate.didFailCalled)
    }
    
    private func getCarShareTokenInfo() -> CarShareTokenInfo {
        let reservationTokenSignature: [UInt8] = [0x01, 0x02, 0x03, 0x04, 0x05]
        let reservationToken: [UInt8] = [0x06, 0x07, 0x08, 0x09, 0x10]
        let reservationModulusHash: [UInt8] = [0x11, 0x12, 0x13, 0x14, 0x15]
        let tenantModulusHash: [UInt8] = [0x16, 017, 0x18, 0x19, 0x20]
        return CarShareTokenInfo(bleServiceUuid: "SERVICE_ID",
                                 reservationPrivateKey: "iaxGDZGroFXYvzbYRnS5TEPJkHwPIrUSaqKIPLt6eq5lpgL2fBGgbhM3gXF78cvsS30C5bGWMvdXOJP1fZNQmJtPUlqMRnciHgLQDzFLdbEDeUsctYMOlWOCSsGDkD4GAEbTS4ptKNiuH2AugbjTrQi61Z7Slp514KWgFfJxLMckchmyW2IYtUbCgcoXx22K6xZILU2CJfn4jelcf0k4ZKnsy9NcuMysIecMkLKP23TRGqiQVWFN0Rqw4SGUEUrW",
                                 reservationModulusHash: Data(bytes: reservationModulusHash, count: reservationModulusHash.count),
                                 tenantModulusHash: Data(bytes: tenantModulusHash, count: tenantModulusHash.count),
                                 reservationToken: Data(bytes: reservationToken, count: reservationToken.count),
                                 reservationTokenSignature: Data(bytes: reservationTokenSignature, count: reservationTokenSignature.count))
    }

}

extension DefaultCommandProtocolTests {
    class FakeChallengeSigner: ChallengeSigner {
        func sign(_ challengeData: Data, signingKey: String) -> Data? {
            return nil
        }
    }
    
    class FakeEncryptionHandler: EncryptionHandler {
        func encrypt(_ message: [UInt8], with encryptionKey: EncryptionKey) -> [UInt8]? {
            return message
        }
        
        func decrypt(_ encrypted: [UInt8], with encryptionKey: EncryptionKey) -> [UInt8]? {
            return encrypted.suffix(16)
        }
        
        func encryptionKey(_ salt: [UInt8], initVector: [UInt8], passphrase: String, iterations: Int) -> EncryptionKey {
            return EncryptionKey(salt: salt, initializationVector: initVector, passphrase: passphrase, iterations: UInt32(iterations))
        }
        
        func encryptionKey() -> EncryptionKey {
             return EncryptionKey(salt: [0,0,0,0,0,0,0,0], initializationVector: [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0], passphrase: "SUPER SECRET", iterations: 14271)
        }
    }
    
    class FakeTransportProtocol: TransportProtocol {
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
    }
    
    class CommandDelegate: CommandProtocolDelegate {
        
        var didOpenCalled: Bool = false
        func protocolDidOpen(_ protocol: CommandProtocol) {
            didOpenCalled = true
        }
        
        var didCloseUnexpectedlyCalled: Bool = false
        func protocolDidCloseUnexpectedly(_ protocol: CommandProtocol, error: Error) {
            didCloseUnexpectedlyCalled = true
        }
        
        var didSucceedCalled: Bool = false
        var didSucceedData: Data? = nil
        func `protocol`(_ protocol: CommandProtocol, command: Command, didSucceed response: Data) {
            didSucceedCalled = true
            didSucceedData = response
        }
        
        var didFailCalled: Bool = false
        func `protocol`(_ protocol: CommandProtocol, command: Command, didFail error: Error) {
            didFailCalled = true
        }
    }
    
    class FakeDeviceCommandTransformer: DeviceCommandTransformer {
        
        var transformCalled: Bool = false
        func transform(_ command: Command) -> Data? {
            transformCalled = true
            return Data(repeating: 0x00, count: 1)
        }
    }
}
