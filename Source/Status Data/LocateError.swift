//
//  LocateError.swift
//  Keyless
//
//  Created by Marc Maguire on 2020-06-16.
//

import Foundation

/// Error returned when the Locate Operation fails.
public enum LocateError: Int, StatusDataError, CustomStringConvertible {
    /// Operation in progress.
    case operationInProgress = 1
    /// Vehicle error.
    case vehicleError = 2
    /// Keyfob error.
    case keyfobError = 3

    public var code: Int { return 3_351 }
    public var value: Int { return self.rawValue }

    public var description: String {
        switch self {
        case .operationInProgress:
            return "Locate failed due to: Operation In Progress"
        case .vehicleError:
            return "Locate failed due to: Vehicle Error"
        case .keyfobError:
            return "Locate failed due to: Keyfob Error"
        }
    }
}
