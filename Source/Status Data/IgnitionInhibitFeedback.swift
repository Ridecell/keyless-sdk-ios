//
//  IgnitionInhibitFeedback.swift
//  Keyless
//
//  Created by Marc Maguire on 2020-06-16.
//

import Foundation

/// Error returned when the Ignition Inhibit Operation fails.
public enum IgnitionInhibitFeedback: Int, StatusDataError, CustomStringConvertible {
    /// Failed due to Ignition Inhibit error. See Ignition Inhibit Error.
    case error = 1
    /// Ignition is on.
    case ignitionOn = 2

    public var code: Int { return 3_352 }
    public var value: Int { return self.rawValue }

    public var description: String {
        switch self {
        case .error:
            return "Ignition Inhibit failed due to: Error"
        case .ignitionOn:
            return "Ignition Inhibit failed due to: Ignition On"
        }
    }
}
