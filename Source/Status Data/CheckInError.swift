//
//  CheckInError.swift
//  Keyless
//
//  Created by Marc Maguire on 2020-06-16.
//

import Foundation

/// Error returned when the Check-In Operation fails.
public enum CheckInError: Int, StatusDataError, CustomStringConvertible {
    /// Could not authenticate.
    case couldNotAuthenticate = 1
    /// GO device has no time.
    case noDeviceTime = 2
    /// Start or end time is invalid.
    case startOrEndTimeInvalid = 3
    /// GO device has an invalid device ID.
    case invalidDeviceID = 4
    /// GO device has an invalid device serial number.
    case invalidDeviceSerialNumber = 5
    /// GO device has no public key.
    case noPublicKeysOnDevice = 6
    /// Reservation already in progress.
    case reservationAlreadyInProgress = 7

    public var code: Int { return 3_346 }
    public var value: Int { return self.rawValue }

    public var description: String {
        switch self {
        case .couldNotAuthenticate:
            return "Check-In failed - could not authenticate"
        case .noDeviceTime:
            return "Check-In failed due to no device time"
        case .startOrEndTimeInvalid:
            return "Check-In failed due to invalid start or end time"
        case .invalidDeviceID:
            return "Check-In failed due to invalid Device ID"
        case .invalidDeviceSerialNumber:
            return "Check-In failed due to invalid device serial number"
        case .noPublicKeysOnDevice:
            return "Check-In failed due to no public keys on device"
        case .reservationAlreadyInProgress:
            return "Check-In failed due to reservation already in progress"
        }
    }
}
