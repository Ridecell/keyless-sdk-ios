//
//  ReservationTransformer.swift
//  CarShare_Example
//
//  Created by Marc Maguire on 2019-08-22.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation

class ReservationTransformer {

    struct ReservationDetails: Codable {
        var reservationId: String
        var appPrivateKeyPkcs1Encoded: String
        var reservationTokenSignature: String
        var reservationToken: ReservationToken
    }
    struct ReservationToken: Codable {
        var appPublicModulus: String
        var keyExpiry: UInt64
        var reservationId: String
        var deviceHardwareId: UInt64
        var account: Account
        var reservationStartTime: UInt64
        var reservationEndTime: UInt64
        var gracePeriodSeconds: UInt32
        var securePeriodSeconds: UInt32
        var endBookConditions: EndBookConditions
    }
    struct Account: Codable {
        //swiftlint:disable:next identifier_name
        var id: UInt32
        var permissions: UInt32
    }
    struct EndBookConditions: Codable {
        var endBookVehicleFlags: UInt32
        var homePoint: HomePoint
        var homeRadius: UInt32
    }
    struct HomePoint: Codable {
        var latitude: Float
        var longitude: Float
    }
    struct DataConversionError: Swift.Error {}

    func transform(_ json: String) throws -> ReservationDetails {
        let decoder = JSONDecoder()
        guard let data = json.data(using: .utf8) else {
            throw DataConversionError()
        }
        return try decoder.decode(ReservationDetails.self, from: data)
    }

}
