//
//  ConsoleLogger.swift
//  Keyless
//
//  Created by Matt Snow on 2020-03-30.
//

public struct ConsoleLogger: Logger {

    public init() {
    }

    public func log(_ level: LogLevel, message: () -> Any, context: LogContext) {
        print("\(level): \(message())")
    }

}
