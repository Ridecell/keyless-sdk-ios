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
    var challengeSigner: FakeChallengeSigner!
    var transportProtocol: FakeTransportProtocol!
    var delegate: CommandDelegate!
    var byteGenerator: ByteGenerator!

    override func setUp() {
        let transportProtocol = FakeTransportProtocol()
        let challengeSigner = FakeChallengeSigner()
        byteGenerator = DefaultByteGenerator()
        let defaultCommandProtocol = DefaultCommandProtocol(
            transportProtocol: transportProtocol,
            deviceToAppMessageTransformer: ProtobufDeviceToAppMessageTransformer(),
            challengeSigner: challengeSigner)
        let delegate = CommandDelegate()
        defaultCommandProtocol.delegate = delegate
        self.sut = defaultCommandProtocol
        self.challengeSigner = challengeSigner
        self.transportProtocol = transportProtocol
        self.delegate = delegate
    }

    override func tearDown() {
        self.sut = nil
        self.challengeSigner = nil
        self.transportProtocol = nil
        self.byteGenerator = nil
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
        openAndSend()
        XCTAssertTrue(transportProtocol.sendCalled)
        XCTAssertTrue(transportProtocol.sentData != nil)
        XCTAssertTrue([UInt8](transportProtocol.sentData!) == [0x00, 0x01, 0x00])
        sut.protocolDidSend(transportProtocol)
        let randomBytes = byteGenerator.generate(32)
        var challenge: [UInt8] = [0x01, 0x01, 0x00]
        challenge.append(contentsOf: randomBytes)
        sut.protocol(transportProtocol, didReceive: Data(bytes: challenge, count: challenge.count))
        
        sut.protocolDidSend(transportProtocol)
        let ack: [UInt8] = [0x81, 0x00]
        sut.protocol(transportProtocol, didReceive: Data(bytes: ack, count: ack.count))
        
        guard let deviceAck = deviceToAppMessage(success: true) else {
            XCTFail()
            return
        }
        sut.protocol(transportProtocol, didReceive: deviceAck)
        
        XCTAssertTrue(delegate.didSucceedCalled)
        XCTAssertTrue(delegate.didSucceedData != nil)
        XCTAssertTrue(delegate.didSucceedData == deviceAck)
    }
    
    func testSendingCommandDeviceAckFailure() {
        openAndSend()
        XCTAssertTrue(transportProtocol.sendCalled)
        XCTAssertTrue(transportProtocol.sentData != nil)
        XCTAssertTrue([UInt8](transportProtocol.sentData!) == [0x00, 0x01, 0x00])
        sut.protocolDidSend(transportProtocol)
        let randomBytes = byteGenerator.generate(32)
        var challenge: [UInt8] = [0x01, 0x01, 0x00]
        challenge.append(contentsOf: randomBytes)
        sut.protocol(transportProtocol, didReceive: Data(bytes: challenge, count: challenge.count))
        
        sut.protocolDidSend(transportProtocol)
        let ack: [UInt8] = [0x81, 0x00]
        sut.protocol(transportProtocol, didReceive: Data(bytes: ack, count: ack.count))
        
        guard let deviceAck = deviceToAppMessage(success: false) else {
            XCTFail()
            return
        }
        sut.protocol(transportProtocol, didReceive: deviceAck)
        
        XCTAssertFalse(delegate.didSucceedCalled)
        XCTAssertTrue(delegate.didSucceedData == nil)
    }
    
    private func deviceToAppMessage(success: Bool) -> Data? {
        let deviceToAppMessage = DeviceToAppMessage.with { populator in
            let resultMessage = ResultMessage.with { populator in
                populator.success = success
            }
            populator.message = DeviceToAppMessage.OneOf_Message.result(resultMessage)
        }
        do {
            return try deviceToAppMessage.serializedData()
        } catch {
            return nil
        }
    }
    
    func testCommandFailsIfSigningFails() {
        challengeSigner.stubbedSigningSuccess = false
        openAndSend()
        
        sut.protocolDidSend(transportProtocol)
        let randomBytes = byteGenerator.generate(32)
        var challenge: [UInt8] = [0x01, 0x01, 0x00]
        challenge.append(contentsOf: randomBytes)
        sut.protocol(transportProtocol, didReceive: Data(bytes: challenge, count: challenge.count))
        
        sut.protocolDidSend(transportProtocol)
        let ack: [UInt8] = [0x81, 0x00]
        
        sut.protocol(transportProtocol, didReceive: Data(bytes: ack, count: ack.count))
        XCTAssertFalse(delegate.didSucceedCalled)
        XCTAssertTrue(delegate.didSucceedData == nil)
        XCTAssertTrue(delegate.didFailCalled)
    }

    func testCannotReceiveIfNoOutgoingMessage() {
        
        let randomBytes = byteGenerator.generate(32)
        sut.protocol(transportProtocol, didReceive: Data(bytes: randomBytes, count: randomBytes.count))
        XCTAssertFalse(delegate.didSucceedCalled)
        XCTAssertTrue(delegate.didSucceedData == nil)
        XCTAssertFalse(delegate.didFailCalled)
        XCTAssertFalse(transportProtocol.sendCalled)
    }
    
    func testSendingCommandFailsOnTwoSends() {
        let carShareTokenInfo = getCarShareTokenInfo()
        let outgoingCommand = OutgoingCommand(deviceCommandMessage: Data(bytes: [0x00], count: 1), carShareTokenInfo: carShareTokenInfo, state: .requestingToSendMessage)
        sut.send(outgoingCommand)
        transportProtocol.sendCalled = false
        sut.send(outgoingCommand)
        XCTAssert(transportProtocol.sendCalled == false)
    }
    
    func testProtocolDidCloseUnexpectedlyPropagatesAfterSend() {
        openAndSend()
        transportProtocol.delegate?.protocolDidCloseUnexpectedly(transportProtocol, error: TestError())
        XCTAssert(delegate.didCloseUnexpectedlyCalled)
    }
    
    func testProtocolDidCloseUnexpectedlyPropagatesBeforeSend() {
        open()
        transportProtocol.delegate?.protocolDidCloseUnexpectedly(transportProtocol, error: TestError())
        XCTAssert(delegate.didCloseUnexpectedlyCalled)
    }
    
    func testProtocolDidFailToSendPropagatesAfterSend() {
        openAndSend()
        transportProtocol.delegate?.protocolDidFailToSend(transportProtocol, error: TestError())
        XCTAssert(delegate.didFailCalled)
    }
    func testProtocolDidFailToSendDoesNotPropagateBeforeSend() {
        open()
        transportProtocol.delegate?.protocolDidFailToSend(transportProtocol, error: TestError())
        XCTAssert(delegate.didFailCalled == false)
    }
    
    func testProtocolDidFailToReceivePropagatesAfterSend() {
        openAndSend()
        transportProtocol.delegate?.protocolDidFailToReceive(transportProtocol, error: TestError())
        XCTAssert(delegate.didFailCalled)
    }
    
    func testProtocolDidFailToReceiveDoesNotPropagateBeforeSend() {
        open()
        transportProtocol.delegate?.protocolDidFailToReceive(transportProtocol, error: TestError())
        XCTAssert(delegate.didFailCalled == false)
    }
    
    func testSendingCommandFailedOnMalformedChallenge() {
        openAndSend()
        
        XCTAssertTrue(transportProtocol.sendCalled)
        
        sut.protocolDidSend(transportProtocol)
        sut.protocol(transportProtocol, didReceive: Data(bytes: [0x00,0x00], count: 2))
        XCTAssertTrue(delegate.didFailCalled)
    }
    
    func testSendingCommandFailedOnChallengeNack() {
        openAndSend()
        
        sut.protocolDidSend(transportProtocol)
        let randomBytes = byteGenerator.generate(32)
        var challenge: [UInt8] = [0x01, 0x01, 0x00]
        challenge.append(contentsOf: randomBytes)
        sut.protocol(transportProtocol, didReceive: Data(bytes: challenge, count: challenge.count))
        
        sut.protocolDidSend(transportProtocol)
        let nack: [UInt8] = [0x81, 0x01]
        
        sut.protocol(transportProtocol, didReceive: Data(bytes: nack, count: nack.count))
        XCTAssertTrue(delegate.didFailCalled)
    }
    
    func testSendingCommandFailedOnInvalidChallengeAck() {
        openAndSend()
        
        sut.protocolDidSend(transportProtocol)
        let randomBytes = byteGenerator.generate(32)
        var challenge: [UInt8] = [0x01, 0x01, 0x00]
        challenge.append(contentsOf: randomBytes)
        sut.protocol(transportProtocol, didReceive: Data(bytes: challenge, count: challenge.count))
        
        sut.protocolDidSend(transportProtocol)
        let ack: [UInt8] = [0x81, 0x00, 0x00]
        
        sut.protocol(transportProtocol, didReceive: Data(bytes: ack, count: ack.count))
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
    
    private func open() {
        let config = BLeSocketConfiguration(serviceID: "SERVICE_ID",
                                            notifyCharacteristicID: "NOTIFY_ID",
                                            writeCharacteristicID: "WRITE_ID")
        sut.open(config)
    }
    
    private func openAndSend() {
        let config = BLeSocketConfiguration(serviceID: "SERVICE_ID",
                                            notifyCharacteristicID: "NOTIFY_ID",
                                            writeCharacteristicID: "WRITE_ID")
        sut.open(config)
        let carShareTokenInfo = getCarShareTokenInfo()
        let outgoingCommand = OutgoingCommand(deviceCommandMessage: Data(bytes: [0x00], count: 1), carShareTokenInfo: carShareTokenInfo, state: .requestingToSendMessage)
        sut.send(outgoingCommand)
    }
    
    private struct TestError: Swift.Error{}

}

extension DefaultCommandProtocolTests {
    class FakeChallengeSigner: ChallengeSigner {
        
        var stubbedSigningSuccess: Bool = true
        func sign(_ challengeData: Data, signingKey: String) -> Data? {
            return stubbedSigningSuccess ? challengeData : nil
        }
    }
    
    class FakeEncryptionHandler: EncryptionHandler {
        
        var stubbedEncryptSuccess: Bool = true
        func encrypt(_ message: [UInt8], with encryptionKey: EncryptionKey) -> [UInt8]? {
            return stubbedEncryptSuccess ? message : nil
        }
        
        var stubbedDecryptSuccess: Bool = true
        func decrypt(_ encrypted: [UInt8], with encryptionKey: EncryptionKey) -> [UInt8]? {
            return stubbedDecryptSuccess ? encrypted.suffix(16) : nil
        }

        func encryptionKey(_ initVector: [UInt8]) -> EncryptionKey {
            return EncryptionKey(
                salt: [232, 96, 98, 5, 159, 228, 202, 239],
                initializationVector: initVector,
                passphrase: "SUPER_SECRET",
                iterations: 14_271)
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
        func `protocol`(_ protocol: CommandProtocol, didSucceed response: Data) {
            didSucceedCalled = true
            didSucceedData = response
        }

        var didFailCalled: Bool = false
        func `protocol`(_ protocol: CommandProtocol, didFail error: Error) {
            didFailCalled = true
        }
    }
}
