//
//  EndbookConditionsError.swift
//  Keyless
//
//  Created by Marc Maguire on 2020-06-16.
//

import Foundation

/// Error returned when the Check-In Operation fails due to Endbook Conditions.
public enum EndbookConditionsError: Int, StatusDataError, CustomStringConvertible {
    /// Enbook condition: Warning, no GPS.
    case warnNoGPS = 1
    /// Enbook condition: Incorrect location.
    case incorrectLocation = 2
    /// Enbook condition: Warning, no fuel found.
    case warnNoFuelFound = 3
    /// Enbook condition: Warning, low fuel.
    case lowFuel = 4
    /// Enbook condition: Warning, ignition on.
    case ignitionOn = 5

    public var code: Int { return 3_355 }
    public var value: Int { return self.rawValue }

    public var description: String {
        switch self {
        case .warnNoGPS:
            return "Check-Out failed due to Endbook Condition: Warning - No GPS"
        case .incorrectLocation:
            return "Check-Out failed due to Endbook Condition: Incorrect Location "
        case .warnNoFuelFound:
            return "Check-Out failed due to Endbook Condition: No Fuel Found"
        case .lowFuel:
            return "Check-Out failed due to Endbook Condition: Low Fuel"
        case .ignitionOn:
            return "Check-Out failed due to Endbook Condition: Ignition On"
        }
    }
}
