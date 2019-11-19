//
//  CarShareClientTests.swift
//  CarShare_Tests
//
//  Created by Marc Maguire on 2019-11-08.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import XCTest
@testable import CarShare

class CarShareClientTests: XCTestCase {
    
    private var sut: CarShareClient!
    private var delegate: FakeCarShareClientDelegate!
    private var tokenTransformer: FakeTokenTransformer!
    private var commandProtocol: FakeCommandProtocol!

    override func setUp() {
        let tokenTransformer = FakeTokenTransformer()
        let commandProtocol = FakeCommandProtocol()
        let delegate = FakeCarShareClientDelegate()
        let client = CarShareClient(commandProtocol: commandProtocol, tokenTransformer: tokenTransformer)
        client.delegate = delegate
        self.sut = client
        self.delegate = delegate
        self.tokenTransformer = tokenTransformer
        self.commandProtocol = commandProtocol
    }

    override func tearDown() {
        self.sut = nil
        self.delegate = nil
        self.tokenTransformer = nil
        self.commandProtocol = nil
    }
    
    func testConnectingWithValidTokenSendsMessageToCommandLayer() {
        let validToken = "VALID_TOKEN"
        do {
            try sut.connect(validToken)
        } catch {
            XCTFail()
        }
        XCTAssertTrue(tokenTransformer.transformCalled)
        XCTAssertTrue(commandProtocol.openCalled)
    }
    
    func testProperNotifyAndWriteCharacteristicsUsed() {
        let validToken = "VALID_TOKEN"
        do {
            try sut.connect(validToken)
        } catch {
            XCTFail()
        }
        
        let config = BLeSocketConfiguration(
            serviceID: "SERVICE_ID",
            notifyCharacteristicID: "430F2EA3-C765-4051-9134-A341254CFD00",
            writeCharacteristicID: "906EE7E0-D8DB-44F3-AF54-6B0DFCECDF1C")
        
        XCTAssertEqual(commandProtocol.configeUsed?.notifyCharacteristicID, config.notifyCharacteristicID)
        XCTAssertEqual(commandProtocol.configeUsed?.writeCharacteristicID, config.writeCharacteristicID)
    }
    
    func testSuccessfulCommandPropagates() {
        let validToken = "VALID_TOKEN"
        try? sut.execute(.checkIn, with: validToken)
        let bytes: [UInt8] = [0x01]
        sut.protocol(commandProtocol, command: .checkIn, didSucceed: Data(bytes: bytes, count: bytes.count))
        
        XCTAssertTrue(delegate.commandDidSucceedCalled)
        XCTAssertEqual(delegate.successfulCommand, Command.checkIn)
    }
    
    func testConnectFailsWithInvalidToken() {
        
        let invalidToken = "INVALID_TOKEN"
        try? sut.connect(invalidToken)
        XCTAssertFalse(commandProtocol.openCalled)
    }
    
    func testExecuteFailsWithInvalidToken() {
        
        let invalidToken = "INVALID_TOKEN"
        try? sut.execute(.checkIn, with: invalidToken)
        XCTAssertFalse(commandProtocol.sendCalled)
    }
    
    func testDidSucceedFailsIfDisconnected() {
        let validToken = "VALID_TOKEN"
        try? sut.connect(validToken)
        let bytes: [UInt8] = [0x01]
        sut.disconnect()
        sut.protocol(commandProtocol, command: .closeTrunk, didSucceed: Data(bytes: bytes, count: bytes.count))
        XCTAssertFalse(delegate.commandDidSucceedCalled)
    }
    
    func testDidFailsFailsIfDisconnected() {
        let validToken = "VALID_TOKEN"
        try? sut.connect(validToken)
        sut.disconnect()
        sut.protocol(commandProtocol, command: .checkIn, didFail: DefaultCommandProtocol.DefaultCommandProtocolError.malformedData)
        XCTAssertFalse(delegate.commandDidFail)
    }
    
    func testUnsuccessfulCommandPropagates() {
        let validToken = "VALID_TOKEN"
        try? sut.execute(.checkIn, with: validToken)
        sut.protocol(commandProtocol, command: .checkIn, didFail: DefaultCommandProtocol.DefaultCommandProtocolError.malformedData)
        
        XCTAssertTrue(delegate.commandDidFail)
        XCTAssertEqual(delegate.failedCommand, Command.checkIn)
    }
    
    func testUnexpectedDisconnectPropagatesError() {
        connect()
        sut.protocolDidCloseUnexpectedly(commandProtocol, error: DefaultCommandProtocol.DefaultCommandProtocolError.malformedData)
        XCTAssertTrue(delegate.didDisconnectUnexpectedlyCalled)
    }
    
    func testCloseConnection() {
        connect()
        sut.disconnect()
        XCTAssertTrue(commandProtocol.closeCalled)
    }

    private func connect() {
        let carShareToken = "VALID_TOKEN"
        do {
            try sut.connect(carShareToken)
        } catch {
            XCTFail()
        }
        sut.protocolDidOpen(commandProtocol)
    }
}

extension CarShareClientTests {
    
    class FakeTokenTransformer: TokenTransformer {
                
        var transformCalled: Bool = false
        func transform(_ token: String) throws -> CarShareTokenInfo {
            if token == "INVALID_TOKEN" {
                throw DefaultCarShareTokenTransformer.TokenTransformerError.tokenDecodingFailed
            }
            transformCalled = true
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
    
    class FakeCommandProtocol: CommandProtocol {
        
        var delegate: CommandProtocolDelegate?
        
        var openCalled: Bool = false
        var configeUsed: BLeSocketConfiguration? = nil
        func open(_ configuration: BLeSocketConfiguration) {
            openCalled = true
            configeUsed = configuration
        }
        
        var closeCalled: Bool = false
        func close() {
            closeCalled = true
        }
        
        var sendCalled: Bool = false
        func send(_ command: Message) {
            sendCalled = true
        }
        
        
    }
    
    class FakeCarShareClientDelegate: CarShareClientDelegate {
        
        var didConnectCalled: Bool = false
        func clientDidConnect(_ client: CarShareClient) {
            didConnectCalled = true
        }
        
        var didDisconnectUnexpectedlyCalled: Bool = false
        func clientDidDisconnectUnexpectedly(_ client: CarShareClient, error: Error) {
            didDisconnectUnexpectedlyCalled = true
        }
        
        var commandDidSucceedCalled: Bool = false
        var successfulCommand: Command = .openTrunk
        func clientCommandDidSucceed(_ client: CarShareClient, command: Command) {
            commandDidSucceedCalled = true
            successfulCommand = command
        }
        
        var commandDidFail: Bool = false
        var failedCommand: Command = .openTrunk
        func clientCommandDidFail(_ client: CarShareClient, command: Command, error: Error) {
            commandDidFail = true
            failedCommand = command
        }
        
        
    }
    
}
