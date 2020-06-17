//
//  LockError.swift
//  Keyless
//
//  Created by Marc Maguire on 2020-06-16.
//

import Foundation

/// Error returned when the Lock Operation fails.
public enum LockError: Int, StatusDataError, CustomStringConvertible {
    /// Operation already in progress.
    case operationInProgress = 1
    /// Vehicle error
    case vehicleError = 2
    /// Execution Timeout.
    case timeout = 3
    /// Keyfob error.
    case keyfobErrors = 4

    public var code: Int { return 3_348 }
    public var value: Int { return self.rawValue }

    public var description: String {
        switch self {
        case .operationInProgress:
            return "Lock failed due to: Operation already in progress"
        case .vehicleError:
            return "Lock failed due to: Vehicle Error"
        case .timeout:
            return "Lock failed due to: Feedback Timeout"
        case .keyfobErrors:
            return "Lock failed due to: Keyfob Errors"
        }
    }
}
