//
//  UnlockAllError.swift
//  Keyless
//
//  Created by Marc Maguire on 2020-06-16.
//

import Foundation

/// Error returned when the UnlockAll Operation fails.
public enum UnlockAllError: Int, StatusDataError, CustomStringConvertible {
    /// Operation already in progress.
    case operationInProgress = 1
    /// Vehicle error
    case vehicleError = 2
    /// Execution Timeout.
    case timeout = 3
    /// Keyfob error.
    case keyfobErrors = 4

    public var code: Int { return 3_350 }
    public var value: Int { return self.rawValue }

    public var description: String {
        switch self {
        case .operationInProgress:
            return "Unlock-All failed due to: Operation Already In Progress"
        case .vehicleError:
            return "Unlock-All failed due to: Vehicle Error"
        case .timeout:
            return "Unlock-All failed due to: Feedback Timeout"
        case .keyfobErrors:
            return "Unlock-All failed due to: Keyfob Errors"
        }
    }
}
