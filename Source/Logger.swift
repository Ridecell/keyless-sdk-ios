//
//  Logger.swift
//  Keyless
//
//  Created by Matt Snow on 2020-03-30.
//

public enum LogLevel {
    case verbose, debug, info, warning, error
}

public struct LogContext {
    public let timestamp: Double
    public let file: String
    public let function: String
    public let line: Int

    public init(timestamp: Double, file: String, function: String, line: Int) {
        self.timestamp = timestamp
        self.file = file
        self.function = function
        self.line = line
    }
}
/// The `Logger` is used throughout the components of the framework.
public protocol Logger {

    /// Log with the log level provided.
    /// - Parameters:
    ///   - level: The log level
    ///   - message: The log message
    ///   - timeInterval: The timestamp, in seconds, since epoch that the log occurred
    ///   - file: The file the log occurred on
    ///   - function: The function the log occurred in
    ///   - line: The line the log occurred on
    func log(_ level: LogLevel, message: () -> Any, context: LogContext)

}

import Foundation
public extension Logger {
    /// Verbose log (lowest priority)
    /// - Parameter message: The log message
    func v(_ message: @autoclosure () -> Any, file: String = #file, function: String = #function, line: Int = #line) {

        log(.verbose, message: message, context: LogContext(timestamp: Date().timeIntervalSince1970, file: file, function: function, line: line))
    }

    /// Debug log (low priority)
    /// - Parameter message: The log message
    func d(_ message: @autoclosure () -> Any, file: String = #file, function: String = #function, line: Int = #line) {
        log(.debug, message: message, context: LogContext(timestamp: Date().timeIntervalSince1970, file: file, function: function, line: line))
    }

    /// Information log (medium priority)
    /// - Parameter message: The log message
    func i(_ message: @autoclosure () -> Any, file: String = #file, function: String = #function, line: Int = #line) {
        log(.info, message: message, context: LogContext(timestamp: Date().timeIntervalSince1970, file: file, function: function, line: line))
    }

    /// Warning log (high priority)
    /// - Parameter message: The log message
    func w(_ message: @autoclosure () -> Any, file: String = #file, function: String = #function, line: Int = #line) {
        log(.warning, message: message, context: LogContext(timestamp: Date().timeIntervalSince1970, file: file, function: function, line: line))
    }

    /// Error log (highest priority)
    /// - Parameter message: The log message
    func e(_ message: @autoclosure () -> Any, file: String = #file, function: String = #function, line: Int = #line) {
        log(.verbose, message: message, context: LogContext(timestamp: Date().timeIntervalSince1970, file: file, function: function, line: line))
    }
}
