//
//  VehicleStatusDataTransformer.swift
//  Keyless_Example
//
//  Created by Marc Maguire on 2020-06-15.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import XCTest
@testable import Keyless

class VehicleStatusDataTransformerTests: XCTestCase {

    var sut: StatusDataTransformer!

    override func setUp() {
        self.sut = VehicleStatusDataTransformer()
    }

    override func tearDown() {
        self.sut = nil
    }

    func testTransformingCheckInError() {
        let _ = [
            testTransform(StatusDataRecord(code: 3346, value: 1), to: CheckInError(rawValue: 1)),
            testTransform(StatusDataRecord(code: 3346, value: 2), to: CheckInError(rawValue: 2)),
            testTransform(StatusDataRecord(code: 3346, value: 3), to: CheckInError(rawValue: 3)),
            testTransform(StatusDataRecord(code: 3346, value: 4), to: CheckInError(rawValue: 4)),
            testTransform(StatusDataRecord(code: 3346, value: 5), to: CheckInError(rawValue: 5)),
            testTransform(StatusDataRecord(code: 3346, value: 6), to: CheckInError(rawValue: 6)),
            testTransform(StatusDataRecord(code: 3346, value: 7), to: CheckInError(rawValue: 7))
            ].map { XCTAssertNotNil($0.errors.first as? CheckInError) }
    }

    func testTransformingCheckOutError() {
        let _ = [
            testTransform(StatusDataRecord(code: 3347, value: 1), to: CheckOutError(rawValue: 1)),
            testTransform(StatusDataRecord(code: 3347, value: 2), to: CheckOutError(rawValue: 2))
            ].map { XCTAssertNotNil($0.errors.first as? CheckOutError) }
    }

    func testTransformingEndbookConditionsError() {
        let _ = [
            testTransform(StatusDataRecord(code: 3355, value: 1), to: EndbookConditionsError(rawValue: 1)),
            testTransform(StatusDataRecord(code: 3355, value: 2), to: EndbookConditionsError(rawValue: 2)),
            testTransform(StatusDataRecord(code: 3355, value: 3), to: EndbookConditionsError(rawValue: 3)),
            testTransform(StatusDataRecord(code: 3355, value: 4), to: EndbookConditionsError(rawValue: 4)),
            testTransform(StatusDataRecord(code: 3355, value: 5), to: EndbookConditionsError(rawValue: 5))
            ].map { XCTAssertNotNil($0.errors.first as? EndbookConditionsError) }
    }

    func testTransformingLockError() {
        let _ = [
            testTransform(StatusDataRecord(code: 3348, value: 1), to: LockError(rawValue: 1)),
            testTransform(StatusDataRecord(code: 3348, value: 2), to: LockError(rawValue: 2)),
            testTransform(StatusDataRecord(code: 3348, value: 3), to: LockError(rawValue: 3)),
            testTransform(StatusDataRecord(code: 3348, value: 4), to: LockError(rawValue: 4))
            ].map { XCTAssertNotNil($0.errors.first as? LockError) }
    }

    func testTransformingUnlockDriverError() {
        let _ = [
            testTransform(StatusDataRecord(code: 3349, value: 1), to: UnlockDriverError(rawValue: 1)),
            testTransform(StatusDataRecord(code: 3349, value: 2), to: UnlockDriverError(rawValue: 2)),
            testTransform(StatusDataRecord(code: 3349, value: 3), to: UnlockDriverError(rawValue: 3)),
            testTransform(StatusDataRecord(code: 3349, value: 4), to: UnlockDriverError(rawValue: 4))
            ].map { XCTAssertNotNil($0.errors.first as? UnlockDriverError) }
    }

    func testTransformingUnlockAllError() {
        let _ = [
            testTransform(StatusDataRecord(code: 3350, value: 1), to: UnlockAllError(rawValue: 1)),
            testTransform(StatusDataRecord(code: 3350, value: 2), to: UnlockAllError(rawValue: 2)),
            testTransform(StatusDataRecord(code: 3350, value: 3), to: UnlockAllError(rawValue: 3)),
            testTransform(StatusDataRecord(code: 3350, value: 4), to: UnlockAllError(rawValue: 4))
            ].map { XCTAssertNotNil($0.errors.first as? UnlockAllError) }
    }

    func testTransformingLocateFeedback() {
        let _ = [
            testTransform(StatusDataRecord(code: 3351, value: 1), to: LocateError(rawValue: 1)),
            testTransform(StatusDataRecord(code: 3351, value: 2), to: LocateError(rawValue: 2)),
            testTransform(StatusDataRecord(code: 3351, value: 3), to: LocateError(rawValue: 3))
            ].map { XCTAssertNotNil($0.errors.first as? LocateError) }
    }

    func testTransformingIgnitionInhibitFeedback() {
        let _ = [
            testTransform(StatusDataRecord(code: 3352, value: 1), to: IgnitionInhibitFeedback(rawValue: 1)),
            testTransform(StatusDataRecord(code: 3352, value: 2), to: IgnitionInhibitFeedback(rawValue: 2))
            ].map { XCTAssertNotNil($0.errors.first as? IgnitionInhibitFeedback) }
    }

    func testTransformingIgnitionInhibitError() {
        let _ = [
            testTransform(StatusDataRecord(code: 3334, value: 0), to: IgnitionInhibitError(rawValue: 0)),
            testTransform(StatusDataRecord(code: 3334, value: 1), to: IgnitionInhibitError(rawValue: 1))
            ].map { XCTAssertNotNil($0.errors.first as? IgnitionInhibitError) }
    }

    func testTransformingIgnitionEnableError() {
        let _ = [
            testTransform(StatusDataRecord(code: 3353, value: 1), to: IgnitionEnableError(value: 1))
            ].map { XCTAssertNotNil($0.errors.first as? IgnitionEnableError) }
    }

    func testTransformUnknownStatusData() {
        let _ = [
            testTransform(StatusDataRecord(code: 9990, value: 444444), to: UnknownStatusData(code: 9990, value: 444444)),
            testTransform(StatusDataRecord(code: 190290390, value: 43431231), to: UnknownStatusData(code: 190290390, value: 43431231))
            ].map { XCTAssertNotNil($0.errors.first as? UnknownStatusData) }
    }

    private func testTransform(_ from: StatusDataRecord, to: StatusDataError?) -> KeylessError {
        let actual = sut.transform([from])
        XCTAssertEqual(to?.code, (actual.errors.first as? StatusDataError)?.code)
        XCTAssertEqual(to?.value, (actual.errors.first as? StatusDataError)?.value)
        return actual
    }


}

