//
//  CheckOutError.swift
//  Keyless
//
//  Created by Marc Maguire on 2020-06-16.
//

import Foundation

/// Error returned when the Check-Out Operation fails.
public enum CheckOutError: Int, StatusDataError, CustomStringConvertible {
    /// Failed due to endbook conditions. See EnbookConditionsError.
    case endbookConditions = 1
    /// Unknown error.
    case unknown = 2

    public var code: Int { return 3_347 }
    public var value: Int { return self.rawValue }

    public var description: String {
        switch self {
        case .endbookConditions:
            return "Check-Out failed due to: End Book Conditions"
        case .unknown:
            return "Check-Out failed due to: Unknown error"
        }
    }
}
