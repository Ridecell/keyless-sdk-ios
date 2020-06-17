//
//  UnknownStatusData.swift
//  Keyless
//
//  Created by Marc Maguire on 2020-06-16.
//

import Foundation

/// Status Data from the GO9 which may not directly relate to the failure of a command
public struct UnknownStatusData: StatusDataError {
    public let code: Int
    public let value: Int
}
