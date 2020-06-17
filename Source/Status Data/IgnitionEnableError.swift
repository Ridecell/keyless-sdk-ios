//
//  IgnitionEnableFeedback.swift
//  Keyless
//
//  Created by Marc Maguire on 2020-06-16.
//

import Foundation

/// Error returned when the Ignition Inhibit Operation fails.
public struct IgnitionEnableError: StatusDataError, CustomStringConvertible {

    public var code: Int { return 3_353 }
    public var value: Int

    public var description: String {
        return "Ignition Enable failed."
    }
}
