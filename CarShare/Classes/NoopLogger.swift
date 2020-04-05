//
//  NoopLogger.swift
//  CarShare
//
//  Created by Matt Snow on 2020-03-30.
//

public struct NoopLogger: Logger {

    public init() {

    }

    public func log(_ level: LogLevel, message: () -> Any, context: LogContext) {
    }

}
