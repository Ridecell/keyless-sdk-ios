//
//  BinaryResponseDataTests.swift
//  CarShare_Tests
//
//  Created by Marc Maguire on 2019-12-02.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import XCTest
@testable import CarShare

class BinaryDataResponseTests: XCTestCase {

    override func setUp() {
    }

    override func tearDown() {
    }
    
    func testValidBinaryDataResponse() {
        let validBytes: [UInt8] = [0x02, 0x22, 0x04, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03]
        if let binaryDataResponse = BinaryDataResponse(data: Data(bytes: validBytes, count: validBytes.count)) {
            XCTAssert(binaryDataResponse.transmissionSuccess)
        } else {
            XCTFail()
        }
    }

    func testValidationFailWithWrongSize() {
        let validBytes: [UInt8] = [0x02, 0x22, 0x04, 0x01, 0x00, 0x00, 0x00, 0x00, 0x03]
        if let _ = BinaryDataResponse(data: Data(bytes: validBytes, count: validBytes.count)) {
            XCTFail()
        } else {
            XCTAssert(true)
        }
    }

    func testValidationFailWithWrongSTX() {
        let validBytes: [UInt8] = [0x09, 0x22, 0x04, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03]
        if let _ = BinaryDataResponse(data: Data(bytes: validBytes, count: validBytes.count)) {
            XCTFail()
        } else {
            XCTAssert(true)
        }
    }

    func testValidationFailWithWrongMessageType() {
        let validBytes: [UInt8] = [0x02, 0x21, 0x04, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03]
        if let _ = BinaryDataResponse(data: Data(bytes: validBytes, count: validBytes.count)) {
            XCTFail()
        } else {
            XCTAssert(true)
        }
    }

    func testValidationFailWithWrongBodyLength() {
        let validBytes: [UInt8] = [0x02, 0x22, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03]
        if let _ = BinaryDataResponse(data: Data(bytes: validBytes, count: validBytes.count)) {
            XCTFail()
        } else {
            XCTAssert(true)
        }
    }

    func testValidationFailWithWrongETX() {
        let validBytes: [UInt8] = [0x02, 0x22, 0x04, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01]
        if let _ = BinaryDataResponse(data: Data(bytes: validBytes, count: validBytes.count)) {
            XCTFail()
        } else {
            XCTAssert(true)
        }
    }

    func testValidResponseWithTransmissionFailure() {
        let validBytes: [UInt8] = [0x02, 0x22, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03]
        if let binaryDataResponse = BinaryDataResponse(data: Data(bytes: validBytes, count: validBytes.count)) {
            XCTAssert(!binaryDataResponse.transmissionSuccess)
        } else {
            XCTFail()
        }
    }

}
