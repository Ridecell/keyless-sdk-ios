//
//  DeviceCommandPayloadTests.swift
//  Keyless_Tests
//
//  Created by Marc Maguire on 2019-10-29.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import XCTest
@testable import Keyless

class DeviceCommandPayloadTests: XCTestCase {

    override func setUp() {
    }

    override func tearDown() {
    }

    func testReservationSignaturePayloadFormat() {
        let keylessTokenInfo = getKeylessTokenInfo()
        let expectedVersion: [UInt8] = [0x01, 0x00]
        let randomBytes: [UInt8] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        let expectedCommandMessage: [UInt8] = [0x01, 0x02, 0x03]
        var signedCommandHashBytes = [UInt8](repeating: 0, count: 256)
        signedCommandHashBytes.append(contentsOf: randomBytes)
        let deviceCommandPayload = DeviceCommandPayload.build(from: keylessTokenInfo,
                                                                  commandMessageProto: Data(bytes: expectedCommandMessage, count: expectedCommandMessage.count),
                                                                  signedCommandHash: signedCommandHashBytes)
        XCTAssertEqual(expectedVersion, deviceCommandPayload.reservationSignaturePayload.reservationVersion)
        XCTAssertEqual([UInt8](keylessTokenInfo.tenantModulusHash).dropLast(), deviceCommandPayload.reservationSignaturePayload.tenantModulusHash)
        XCTAssertEqual([UInt8](keylessTokenInfo.reservationTokenSignature), deviceCommandPayload.reservationSignaturePayload.signedReservationHash)
        
        let reservationLength1 = ((deviceCommandPayload.reservationSignaturePayload.reservationLength[1] & 0xFF) << 8)
        let reservationLength2 = (deviceCommandPayload.reservationSignaturePayload.reservationLength[0] & 0xFF)
        let actualReservationTokenSize = Int(reservationLength1+reservationLength2)
        XCTAssertEqual(keylessTokenInfo.reservationToken.count, actualReservationTokenSize)
        XCTAssertEqual(4, deviceCommandPayload.reservationSignaturePayload.crc32Reservation.count)
    }
    
    func testCommandSignaturePayloadFormat() {
        let keylessTokenInfo = getKeylessTokenInfo()
        let expectedVersion: [UInt8] = [0x01, 0x00]
        let randomBytes: [UInt8] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        let expectedCommandMessage: [UInt8] = [0x01, 0x02, 0x03]
        var signedCommandHashBytes = [UInt8](repeating: 0, count: 256)
        signedCommandHashBytes.append(contentsOf: randomBytes)
        let deviceMessage = DeviceCommandPayload.build(from: keylessTokenInfo,
                                                          commandMessageProto: Data(bytes: expectedCommandMessage, count: expectedCommandMessage.count),
                                                          signedCommandHash: signedCommandHashBytes)
        XCTAssertEqual(expectedVersion, deviceMessage.commandSignaturePayload.commandVersion)
        XCTAssertEqual([UInt8](keylessTokenInfo.reservationModulusHash).dropLast(), deviceMessage.commandSignaturePayload.reservationPublicKeyHash)
        XCTAssertEqual(signedCommandHashBytes, deviceMessage.commandSignaturePayload.signedCommandHash)
        
        let commandLength1 = ((deviceMessage.commandSignaturePayload.commandLength[1] & 0xFF) << 8)
        let commandLength2 = (deviceMessage.commandSignaturePayload.commandLength[0] & 0xFF)
        let actualCommandMessageSize = Int(commandLength1 + commandLength2)
        XCTAssertEqual(expectedCommandMessage.count, actualCommandMessageSize)
        XCTAssertEqual(4, deviceMessage.commandSignaturePayload.crc32Command.count)
    }
    
    private func getKeylessTokenInfo() -> KeylessTokenInfo {
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
