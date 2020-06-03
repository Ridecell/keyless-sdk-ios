//
//  IncomingChallengeTests.swift
//  Keyless_Tests
//
//  Created by Marc Maguire on 2019-11-10.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import XCTest
@testable import Keyless

class IncomingChallengeTests: XCTestCase {

    override func setUp() {
    }

    override func tearDown() {
    }
    
    func testValidatingInitDataFailsOnWrongDataSize() {
        if let _ = generateIncomingChallenge(messageType: [0x01],
                                             protocolVersion: [0x01, 0x00],
                                             countOfRandomBytes: 31) {
            XCTFail()
        } else {
            XCTAssert(true)
        }
    }
    
    func testValidatingInitDataSucceedsOnCorrectDataSize() {
        if let _ = generateIncomingChallenge(messageType: [0x01],
                                             protocolVersion: [0x01, 0x00],
                                             countOfRandomBytes: 32) {
            XCTAssert(true)
        } else {
            XCTFail()
        }
    }
    
    func testValidatingInitDataFailsOnWrongMessageType() {
        if let _ = generateIncomingChallenge(messageType: [0x02],
                                             protocolVersion: [0x01, 0x00],
                                             countOfRandomBytes: 32) {
            XCTFail()
        } else {
            XCTAssert(true)
        }
    }
    
    func testValidatingInitDataFailsOnWrongProtocolVersion() {
        if let _ = generateIncomingChallenge(messageType: [0x01],
                                             protocolVersion: [0x02, 0x00],
                                             countOfRandomBytes: 32) {
            XCTFail()
        } else {
            XCTAssert(true)
        }
    }
    
    func testValidatingInitDataFailsOnWrongProtocolVersion2() {
        if let _ = generateIncomingChallenge(messageType: [0x01],
                                             protocolVersion: [0x01, 0x01],
                                             countOfRandomBytes: 32) {
            XCTFail()
        } else {
            XCTAssert(true)
        }
    }

    
    func testValidatingInitData() {
        var initBytes: [UInt8] = []
        initBytes.append(contentsOf: [0x01])
        initBytes.append(contentsOf: [0x01, 0x00])
        let randomBytes = generateRandom(32)
        initBytes.append(contentsOf: randomBytes)
        if let incomingChallenge = IncomingChallenge(data: Data(bytes: initBytes, count: initBytes.count)) {
            XCTAssertEqual(incomingChallenge.randomBytes, randomBytes)
        } else {
            XCTFail()
        }
    }
    
    private func generateIncomingChallenge(messageType: [UInt8], protocolVersion: [UInt8], countOfRandomBytes: Int) -> IncomingChallenge? {
        var bytes: [UInt8] = []
        bytes.append(contentsOf: messageType)
        bytes.append(contentsOf: protocolVersion)
        bytes.append(contentsOf: generateRandom(countOfRandomBytes))
        if let incomingChallenge = IncomingChallenge(data: Data(bytes: bytes, count: bytes.count)) {
            return incomingChallenge
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
