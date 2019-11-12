//
//  IncomingChallengeAckTests.swift
//  CarShare_Tests
//
//  Created by Marc Maguire on 2019-11-10.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import XCTest
@testable import CarShare

class IncomingChallengeAckTests: XCTestCase {

    override func setUp() {
    }

    override func tearDown() {
    }

    func testValidatingInitDataFailsOnWrongDataSize() {
        let invalidData: [UInt8] = [0x01, 0x01, 0x01, 0x01]
        if let _ = IncomingChallengeAck(data: Data(bytes: invalidData, count: invalidData.count)) {
            XCTFail()
        } else {
            XCTAssert(true)
        }
    }
    
    func testValidatingInitData() {
        let expectedIV = generateRandom(16)
        let expectedEncryptedMessage = generateRandom(16)
        var message: [UInt8] = expectedIV
        message.append(contentsOf: expectedEncryptedMessage)
        let incomingChallengeAck = IncomingChallengeAck(data: Data(bytes: message, count: message.count))
        XCTAssertEqual(expectedIV, incomingChallengeAck?.initVector)
        XCTAssertEqual(expectedEncryptedMessage, incomingChallengeAck?.encryptedMessage)
    }
    
    func testValidatingPayloadDataFailsOnWrongPayloadDataSize() {
        if let incomingChallengeAck = generateChallengeAck() {
            XCTAssertFalse(incomingChallengeAck.validatePayload(generateRandom(2)))
        } else {
            XCTFail()
        }
    }
    
    func testValidatingPayloadDataFailsOnWrongMessageType() {
        let badType: [UInt8] = [0x80, 0x00]
        if let incomingChallengeAck = generateChallengeAck() {
            XCTAssertFalse(incomingChallengeAck.validatePayload(badType))
        } else {
            XCTFail()
        }
    }
    
    func testFailsIfPayloadDoesntContainSuccessValue() {
        let nack: [UInt8] = [0x81, 0x01]
        if let incomingChallengeAck = generateChallengeAck() {
            XCTAssertFalse(incomingChallengeAck.validatePayload(nack))
        } else {
            XCTFail()
        }
    }
    
    func testValidateSuccessfulPayloadDataType() {
        let goodType: [UInt8] = [0x81, 0x00]
        if let incomingChallengeAck = generateChallengeAck() {
            XCTAssertTrue(incomingChallengeAck.validatePayload(goodType))
        } else {
            XCTFail()
        }
    }
    
    private func generateChallengeAck() -> IncomingChallengeAck? {
        let random32Bytes = generateRandom(32)
        if let incomingChallengeAck = IncomingChallengeAck(data: Data(bytes: random32Bytes, count: random32Bytes.count)) {
            return incomingChallengeAck
        } else {
            return nil
        }
    }
    
    private func generateRandom(_ size: Int) -> [UInt8] {
        let bytes = UnsafeMutableRawPointer.allocate(byteCount: size, alignment: 0)
        
        
        guard SecRandomCopyBytes(kSecRandomDefault, size, bytes) == errSecSuccess else {
            fatalError()
        }
        
        let data = Data(bytes: bytes, count: size)
        return [UInt8](data)
    }

}
