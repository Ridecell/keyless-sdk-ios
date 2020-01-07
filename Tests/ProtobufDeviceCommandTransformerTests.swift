//
//  ProtobufDeviceCommandTransformerTests.swift
//  CarShare_Tests
//
//  Created by Matt Snow on 2019-12-02.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import XCTest
@testable import CarShare

class ProtobufDeviceCommandTransformerTests: XCTestCase {

    private var sut: ProtobufDeviceCommandTransformer!

    override func setUp() {
        sut = ProtobufDeviceCommandTransformer()
    }

    override func tearDown() {
        sut = nil
    }

    func testTransformCheckin() {
        let expectedSubcommandFlags = UInt32(DeviceCommandMessage.Command.checkin.rawValue) |
                UInt32(DeviceCommandMessage.Command.mobilize.rawValue) |
                UInt32(DeviceCommandMessage.Command.locate.rawValue)

        guard let actualData = sut.transform(Command.checkIn) else {
            XCTFail()
            return
        }

        do {
            let actualMessage = try DeviceCommandMessage(serializedData: actualData)
            XCTAssertEqual(expectedSubcommandFlags, actualMessage.command)
        } catch {
            XCTFail()
        }

    }

    func testTransformCheckout() {
        let expectedSubcommandFlags = UInt32(DeviceCommandMessage.Command.checkout.rawValue) |
                UInt32(DeviceCommandMessage.Command.immobilize.rawValue) |
                UInt32(DeviceCommandMessage.Command.lock.rawValue)

        guard let actualData = sut.transform(Command.checkOut) else {
            XCTFail()
            return
        }

        do {
            let actualMessage = try DeviceCommandMessage(serializedData: actualData)
            XCTAssertEqual(expectedSubcommandFlags, actualMessage.command)
        } catch {
            XCTFail()
        }

    }

    func testTransformLock() {
        let expectedSubcommandFlags = UInt32(DeviceCommandMessage.Command.lock.rawValue) |
                UInt32(DeviceCommandMessage.Command.immobilize.rawValue)

        guard let actualData = sut.transform(Command.lock) else {
            XCTFail()
            return
        }

        do {
            let actualMessage = try DeviceCommandMessage(serializedData: actualData)
            XCTAssertEqual(expectedSubcommandFlags, actualMessage.command)
        } catch {
            XCTFail()
        }

    }

    func testTransformUnlock() {
        let expectedSubcommandFlags = UInt32(DeviceCommandMessage.Command.unlockAll.rawValue) |
                UInt32(DeviceCommandMessage.Command.mobilize.rawValue)

        guard let actualData = sut.transform(Command.unlockAll) else {
            XCTFail()
            return
        }

        do {
            let actualMessage = try DeviceCommandMessage(serializedData: actualData)
            XCTAssertEqual(expectedSubcommandFlags, actualMessage.command)
        } catch {
            XCTFail()
        }

    }

    func testTransformLocate() {
        let expectedSubcommandFlags = UInt32(DeviceCommandMessage.Command.locate.rawValue)

        guard let actualData = sut.transform(Command.locate) else {
            XCTFail()
            return
        }

        do {
            let actualMessage = try DeviceCommandMessage(serializedData: actualData)
            XCTAssertEqual(expectedSubcommandFlags, actualMessage.command)
        } catch {
            XCTFail()
        }

    }

}
