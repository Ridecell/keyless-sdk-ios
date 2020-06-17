//
//  UnlockDriverError.swift
//  Keyless
//
//  Created by Marc Maguire on 2020-06-16.
//

import Foundation

/// Error returned when the Unlock Driver Operation fails.
public enum UnlockDriverError: Int, StatusDataError, CustomStringConvertible {
    /// Operation already in progress.
    case operationInProgress = 1
    /// Vehicle error
    case vehicleError = 2
    /// Execution Timeout.
    case timeout = 3
    /// Keyfob error.
    case keyfobErrors = 4

    public var code: Int { return 3_349 }
    public var value: Int { return self.rawValue }

    public var description: String {
        switch self {
        case .operationInProgress:
            return "Unlock-Driver failed due to: Operation Already In Progress"
        case .vehicleError:
            return "Unlock-Driver failed due to: Vehicle Error"
        case .timeout:
            return "Unlock-Driver failed due to: Feedback Timeout"
        case .keyfobErrors:
            return "Unlock-Driver failed due to: Keyfob Errors"
        }
    }
}
