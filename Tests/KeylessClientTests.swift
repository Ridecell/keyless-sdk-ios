//
//  KeylessClientTests.swift
//  Keyless_Tests
//
//  Created by Marc Maguire on 2019-11-08.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import XCTest
@testable import Keyless

class KeylessClientTests: XCTestCase {
    
    private var sut: KeylessClient!
    private var delegate: FakeKeylessClientDelegate!
    private var tokenTransformer: FakeTokenTransformer!
    private var deviceCommandTransformer: FakeDeviceCommandTransformer!
    private var deviceToAppMessageTransformer: FakeDeviceToAppMessageTransformer!
    private var vehicleStatusDataTransformer: FakeVehicleStatusDataTransformer!
    private var commandProtocol: FakeCommandProtocol!

    override func setUp() {
        
        let commandProtocol = FakeCommandProtocol()
        let tokenTransformer = FakeTokenTransformer()
        let deviceCommandTransformer = FakeDeviceCommandTransformer()
        let deviceToAppMessageTransformer = FakeDeviceToAppMessageTransformer()
        let vehicleStatusDataTransformer = FakeVehicleStatusDataTransformer()
        let delegate = FakeKeylessClientDelegate()
        let client = KeylessClient(commandProtocol: commandProtocol,
                                    tokenTransformer: tokenTransformer,
                                    deviceCommandTransformer: deviceCommandTransformer,
                                    deviceToAppMessageTransformer: deviceToAppMessageTransformer,
                                    vehicleStatusDataTransformer: vehicleStatusDataTransformer)
        client.delegate = delegate
        self.sut = client
        self.delegate = delegate
        self.tokenTransformer = tokenTransformer
        self.deviceCommandTransformer = deviceCommandTransformer
        self.deviceToAppMessageTransformer = deviceToAppMessageTransformer
        self.vehicleStatusDataTransformer = vehicleStatusDataTransformer
        self.commandProtocol = commandProtocol
    }

    override func tearDown() {
        self.sut = nil
        self.delegate = nil
        self.tokenTransformer = nil
        self.deviceCommandTransformer = nil
        self.deviceToAppMessageTransformer = nil
        self.commandProtocol = nil
    }
    
    func testConnectingWithValidTokenSendsMessageToCommandLayer() {
        let validToken = "VALID_TOKEN"
        connect(validToken)
        XCTAssertTrue(tokenTransformer.transformCalled)
        XCTAssertTrue(commandProtocol.openCalled)
    }
    
    func testProperNotifyAndWriteCharacteristicsUsed() {
        let validToken = "VALID_TOKEN"
        connect(validToken)
        let config = BLeSocketConfiguration(
            serviceID: "SERVICE_ID",
            notifyCharacteristicID: "430F2EA3-C765-4051-9134-A341254CFD00",
            writeCharacteristicID: "906EE7E0-D8DB-44F3-AF54-6B0DFCECDF1C")
        
        XCTAssertEqual(commandProtocol.configeUsed?.notifyCharacteristicID, config.notifyCharacteristicID)
        XCTAssertEqual(commandProtocol.configeUsed?.writeCharacteristicID, config.writeCharacteristicID)
    }
    
    func testSuccessfulOperationsPropagates() {
        let validToken = "VALID_TOKEN"
        connect(validToken)
        try? sut.execute([.checkIn], with: validToken)
        let bytes: [UInt8] = [0x01]
        deviceToAppMessageTransformer.stubResponse = true
        sut.protocol(commandProtocol, didReceive: Data(bytes: bytes, count: bytes.count))
        
        XCTAssertTrue(delegate.operationsDidSucceedCalled)
        XCTAssertEqual(delegate.successfulOperations, [CarOperation.checkIn])
        XCTAssertTrue(sut.isConnected)
    }
    
    func testConnectFailsWithInvalidToken() {
        
        let invalidToken = "INVALID_TOKEN"
        try? sut.connect(invalidToken)
        XCTAssertFalse(commandProtocol.openCalled)
        XCTAssertFalse(sut.isConnected)
    }

    func testExecuteOperationFailsWithInvalidToken() {
        
        let invalidToken = "INVALID_TOKEN"
        try? sut.execute([.checkIn], with: invalidToken)
        XCTAssertFalse(commandProtocol.sendCalled)
    }
    
    func testExecuteOperationsFailsIfCommandTransformFails() {
        let validToken = "VALID_TOKEN"
        deviceCommandTransformer.stubbedTransformSuccess = false
        try? sut.execute([.checkIn], with: validToken)
        XCTAssertFalse(commandProtocol.sendCalled)
    }

    func testDidSucceedFailsIfDisconnected() {
        let validToken = "VALID_TOKEN"
        try? sut.connect(validToken)
        sut.protocolDidOpen(commandProtocol)
        let bytes: [UInt8] = [0x01]
        sut.disconnect()
        sut.protocol(commandProtocol, didReceive: Data(bytes: bytes, count: bytes.count))
        XCTAssertFalse(delegate.commandDidSucceedCalled)
        XCTAssertFalse(sut.isConnected)
    }
    
    func testDidSucceedFailsIfNack() {
        let validToken = "VALID_TOKEN"
        try? sut.connect(validToken)
        sut.protocolDidOpen(commandProtocol)
        try? sut.execute([.checkIn], with: validToken)
        deviceCommandTransformer.stubbedTransformSuccess = true
        deviceToAppMessageTransformer.stubResponse = false
        guard let deviceAck = deviceToAppMessage(success: false) else {
            XCTFail()
            return
        }
        sut.protocol(commandProtocol, didReceive: deviceAck)
        XCTAssertFalse(delegate.commandDidSucceedCalled)
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
    
    func testDidFailFailsIfDisconnected() {
        let validToken = "VALID_TOKEN"
        try? sut.connect(validToken)
        sut.protocolDidOpen(commandProtocol)
        sut.disconnect()
        sut.protocol(commandProtocol, didFail: DefaultCommandProtocol.DefaultCommandProtocolError.malformedData)
        XCTAssertFalse(delegate.commandDidFail)
        XCTAssertFalse(sut.isConnected)
    }
    
    func testUnsuccessfulOperationsPropagates() {
        let validToken = "VALID_TOKEN"
        connect(validToken)
        try? sut.execute([.checkIn], with: validToken)
        sut.protocol(commandProtocol, didFail: DefaultCommandProtocol.DefaultCommandProtocolError.malformedData)
        
        XCTAssertTrue(delegate.operationsDidFail)
        XCTAssertEqual(delegate.failedOperations, [CarOperation.checkIn])
    }
    
    func testUnexpectedDisconnectPropagatesError() {
        let validToken = "VALID_TOKEN"
        connect(validToken)
        sut.protocolDidCloseUnexpectedly(commandProtocol, error: DefaultCommandProtocol.DefaultCommandProtocolError.malformedData)
        XCTAssertTrue(delegate.didDisconnectUnexpectedlyCalled)
    }
    
    func testCloseConnection() {
        let validToken = "VALID_TOKEN"
        connect(validToken)
        sut.disconnect()
        XCTAssertTrue(commandProtocol.closeCalled)
        XCTAssertFalse(sut.isConnected)
    }

    private func connect(_ token: String) {
        do {
            try sut.connect(token)
        } catch {
            XCTFail()
        }
        sut.protocolDidOpen(commandProtocol)
    }
}

extension KeylessClientTests {
    
    class FakeTokenTransformer: TokenTransformer {
                
        var transformCalled: Bool = false
        func transform(_ token: String) throws -> KeylessTokenInfo {
            if token == "INVALID_TOKEN" {
                throw DefaultKeylessTokenTransformer.TokenTransformerError.tokenDecodingFailed
            }
            transformCalled = true
            let reservationTokenSignature: [UInt8] = [0x01, 0x02, 0x03, 0x04, 0x05]
            let reservationToken: [UInt8] = [0x06, 0x07, 0x08, 0x09, 0x10]
            let reservationModulusHash: [UInt8] = [0x11, 0x12, 0x13, 0x14, 0x15]
            let tenantModulusHash: [UInt8] = [0x16, 017, 0x18, 0x19, 0x20]
            return KeylessTokenInfo(bleServiceUuid: "SERVICE_ID",
                                     reservationPrivateKey: "iaxGDZGroFXYvzbYRnS5TEPJkHwPIrUSaqKIPLt6eq5lpgL2fBGgbhM3gXF78cvsS30C5bGWMvdXOJP1fZNQmJtPUlqMRnciHgLQDzFLdbEDeUsctYMOlWOCSsGDkD4GAEbTS4ptKNiuH2AugbjTrQi61Z7Slp514KWgFfJxLMckchmyW2IYtUbCgcoXx22K6xZILU2CJfn4jelcf0k4ZKnsy9NcuMysIecMkLKP23TRGqiQVWFN0Rqw4SGUEUrW",
                                     reservationModulusHash: Data(bytes: reservationModulusHash, count: reservationModulusHash.count),
                                     tenantModulusHash: Data(bytes: tenantModulusHash, count: tenantModulusHash.count),
                                     reservationToken: Data(bytes: reservationToken, count: reservationToken.count),
                                     reservationTokenSignature: Data(bytes: reservationTokenSignature, count: reservationTokenSignature.count))
        }
        
        
    }
    
    private struct TestError: Swift.Error{}
    
    class FakeDeviceCommandTransformer: DeviceCommandTransformer {
        
        
        
        var transformCalled: Bool = false
        var stubbedTransformSuccess: Bool = true
        func transform(_ command: Command) throws -> Data {
            transformCalled = true
            if stubbedTransformSuccess {
                return Data(repeating: 0x01, count: 1)
            } else {
               throw TestError()
            }
        }
        
        func transform(_ operations: Set<CarOperation>) throws -> Data {
            transformCalled = true
            if stubbedTransformSuccess {
                return Data(repeating: 0x01, count: 1)
            } else {
               throw TestError()
            }
        }
        
        
    }
    
    class FakeDeviceToAppMessageTransformer: DeviceToAppMessageTransformer {
        
        var stubResponse: Bool = false
        func transform(_ data: Data) -> Result<Void, OperationFailureError> {
            if stubResponse {
                return .success(())
            } else {
                return .failure(OperationFailureError.protobufSerialization)
            }
        }
    }
    
    class FakeVehicleStatusDataTransformer: StatusDataTransformer {
        
        var stubResponse: KeylessError = KeylessError(errors: [])
        func transform(_ statusData: [StatusDataRecord]) -> KeylessError {
            return stubResponse
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
        func send(_ command: OutgoingCommand) {
            sendCalled = true
        }
        
        
    }
    
    class FakeKeylessClientDelegate: KeylessClientDelegate {

        var didConnectCalled: Bool = false
        func clientDidConnect(_ client: KeylessClient) {
            didConnectCalled = true
        }
        
        var didDisconnectUnexpectedlyCalled: Bool = false
        func clientDidDisconnectUnexpectedly(_ client: KeylessClient, error: Error) {
            didDisconnectUnexpectedlyCalled = true
        }
        
        var commandDidSucceedCalled: Bool = false
        var successfulCommand: Command = .locate
        func clientCommandDidSucceed(_ client: KeylessClient, command: Command) {
            commandDidSucceedCalled = true
            successfulCommand = command
        }
        
        var commandDidFail: Bool = false
        var failedCommand: Command = .locate
        func clientCommandDidFail(_ client: KeylessClient, command: Command, error: Error) {
            commandDidFail = true
            failedCommand = command
        }

        var operationsDidSucceedCalled: Bool = false
        var successfulOperations: Set<CarOperation> = [.locate, .lock]
        func clientOperationsDidSucceed(_ client: KeylessClient, operations: Set<CarOperation>) {
            operationsDidSucceedCalled = true
            successfulOperations = operations
        }
        
        var operationsDidFail: Bool = false
        var failedOperations: Set<CarOperation> = [.locate, .lock]
        func clientOperationsDidFail(_ client: KeylessClient, operations: Set<CarOperation>, error: Error) {
            operationsDidFail = true
            failedOperations = operations
        }
    }
    
}
