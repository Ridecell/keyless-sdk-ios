//
//  ProtobufDeviceCommandTransformerTests.swift
//  Keyless_Tests
//
//  Created by Matt Snow on 2019-12-02.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import XCTest
@testable import Keyless

class ProtobufDeviceCommandTransformerTests: XCTestCase {

    private var sut: ProtobufDeviceCommandTransformer!

    override func setUp() {
        sut = ProtobufDeviceCommandTransformer()
    }

    override func tearDown() {
        sut = nil
    }

    func testTransformCheckinCommand() {
        let expectedSubcommandFlags = UInt32(DeviceCommandMessage.Command.checkin.rawValue) |
                UInt32(DeviceCommandMessage.Command.mobilize.rawValue) |
                UInt32(DeviceCommandMessage.Command.locate.rawValue)

        guard let actualData = try? sut.transform(Command.checkIn) else {
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

    func testTransformCheckoutCommand() {
        let expectedSubcommandFlags = UInt32(DeviceCommandMessage.Command.checkout.rawValue) |
                UInt32(DeviceCommandMessage.Command.immobilize.rawValue) |
                UInt32(DeviceCommandMessage.Command.lock.rawValue)

        guard let actualData = try? sut.transform(Command.checkOut) else {
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

    func testTransformLockCommand() {
        let expectedSubcommandFlags = UInt32(DeviceCommandMessage.Command.lock.rawValue) |
                UInt32(DeviceCommandMessage.Command.immobilize.rawValue)

        guard let actualData = try? sut.transform(Command.lock) else {
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

    func testTransformUnlockCommand() {
        let expectedSubcommandFlags = UInt32(DeviceCommandMessage.Command.unlockAll.rawValue) |
                UInt32(DeviceCommandMessage.Command.mobilize.rawValue)

        guard let actualData = try? sut.transform(Command.unlockAll) else {
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
    
    func testTransformLocateCommand() {
        let expectedSubcommandFlags = UInt32(DeviceCommandMessage.Command.locate.rawValue)

        guard let actualData = try? sut.transform(Command.locate) else {
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
    
    func testTransformAllOperation() {
        transform(operation: .checkIn, into: .checkin)
        transform(operation: .checkOut, into: .checkout)
        transform(operation: .lock, into: .lock)
        transform(operation: .unlockAll, into: .unlockAll)
        transform(operation: .unlockDriver, into: .unlockDriver)
        transform(operation: .locate, into: .locate)
        transform(operation: .mobilize, into: .mobilize)
        transform(operation: .immobilize, into: .immobilize)
        transform(operation: .openTrunk, into: .openTrunk)
        transform(operation: .closeTrunk, into: .closeTrunk)
        
    }
    
    private func transform(operation: CarOperation, into command: DeviceCommandMessage.Command) {
        let expectedSubcommandFlags = UInt32(command.rawValue)

        guard let actualData = try? sut.transform([operation]) else {
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
    
    func testTransformUnlockAllLocateMobilize() {
       let expectedSubcommandFlags = UInt32(DeviceCommandMessage.Command.unlockAll.rawValue) | UInt32(DeviceCommandMessage.Command.locate.rawValue) | UInt32(DeviceCommandMessage.Command.mobilize.rawValue)

        guard let actualData = try? sut.transform([.unlockAll, .locate, .mobilize]) else {
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
