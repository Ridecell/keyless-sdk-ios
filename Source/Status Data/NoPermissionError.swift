//
//  NoPermissionsError.swift
//  Keyless
//
//  Created by Marc Maguire on 2020-10-13.
//

import Foundation

/// Error returned when the set of Operations fail due to no permission.
public struct NoPermissionError: StatusDataError, CustomStringConvertible {
    public let code: Int
    public let value: Int

    public var description: String {
        return "The Keyless Token does not include the required permissions to execute requested operations"
    }
}
