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
    
    func testValidatingInitSucceeds() {
        let invalidData: [UInt8] = [0x81, 0x00]
        if let incomingAck = IncomingChallengeAck(data: Data(bytes: invalidData, count: invalidData.count)) {
            XCTAssert(true)
            XCTAssert(incomingAck.result == 0x00)
        } else {
            XCTFail()
        }
    }

    func testValidatingInitDataFailsOnWrongDataSize() {
        let invalidData: [UInt8] = [0x01, 0x01, 0x01, 0x01]
        if let _ = IncomingChallengeAck(data: Data(bytes: invalidData, count: invalidData.count)) {
            XCTFail()
        } else {
            XCTAssert(true)
        }
    }
    
    func testValidatingInitDataFailsOnRightSizeWrongType() {
        let invalidData: [UInt8] = [0x01, 0x01]
        if let _ = IncomingChallengeAck(data: Data(bytes: invalidData, count: invalidData.count)) {
            XCTFail()
        } else {
            XCTAssert(true)
        }
    }
    
    private func generateChallengeAck() -> IncomingChallengeAck? {
        let random2Bytes = generateRandom(2)
        if let incomingChallengeAck = IncomingChallengeAck(data: Data(bytes: random2Bytes, count: random2Bytes.count)) {
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
