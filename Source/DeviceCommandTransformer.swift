//
//  DeviceCommandTransformer.swift
//  Keyless
//
//  Created by Marc Maguire on 2019-11-06.
//

import Foundation
import SwiftProtobuf

protocol DeviceCommandTransformer {
    func transform(_ command: Command) throws -> Data
    func transform(_ operations: Set<CarOperation>) throws -> Data
}

class ProtobufDeviceCommandTransformer: DeviceCommandTransformer {

    enum ProtobufDeviceCommandTransformerError: Swift.Error, CustomStringConvertible {
        case transformFailed(error: Swift.Error)

        var description: String {
            switch self {
            case .transformFailed(let error):
                return "Failed to decode Car Share token protobuf data due to error: \(error)"
            }
        }
    }

    func transform(_ command: Command) throws -> Data {
        let deviceCommandMessage = DeviceCommandMessage.with { populator in
            populator.command = subCommands(in: command)
                .map { UInt32($0.rawValue) }
                .reduce(0, |)

        }
        do {
            return try deviceCommandMessage.serializedData()
        } catch {
            print("Failed to serialize data to protobuf due to error: \(error)")
            throw ProtobufDeviceCommandTransformerError.transformFailed(error: error)
        }
    }

    func transform(_ operations: Set<CarOperation>) throws -> Data {
        let deviceCommandMessage = DeviceCommandMessage.with { populator in
            populator.command = transform(operations)
                .map { UInt32($0.rawValue) }
                .reduce(0, |)
        }
        do {
            return try deviceCommandMessage.serializedData()
        } catch {
            print("Failed to serialize data to protobuf due to error: \(error)")
            throw ProtobufDeviceCommandTransformerError.transformFailed(error: error)
        }
    }

    private func subCommands(in command: Command) -> Set<DeviceCommandMessage.Command> {
        switch command {
        case .checkIn:
            return [.checkin, .mobilize, .locate]
        case .checkOut:
            return [.checkout, .immobilize, .lock]
        case .locate:
            return [.locate]
        case .lock:
            return [.lock, .immobilize]
        case .unlockAll:
            return [.unlockAll, .mobilize]
        }
    }
    //swiftlint:disable:next cyclomatic_complexity
    private func transform(_ operations: Set<CarOperation>) -> Set<DeviceCommandMessage.Command> {

        var deviceCommands: Set<DeviceCommandMessage.Command> = []

        operations.forEach { operation in
            switch operation {
            case .checkIn:
                deviceCommands.insert(.checkin)
            case .checkOut:
                deviceCommands.insert(.checkout)
            case .lock:
                deviceCommands.insert(.lock)
            case .unlockAll:
                deviceCommands.insert(.unlockAll)
            case .unlockDriver:
                deviceCommands.insert(.unlockDriver)
            case .locate:
                deviceCommands.insert(.locate)
            case .mobilize:
                deviceCommands.insert(.mobilize)
                print("Mobilize is a deprecated operation. Use IgnitionEnable instead.")
            case .immobilize:
                deviceCommands.insert(.immobilize)
                print("Immobilize is a deprecated operation. Use IgnitionInhibit instead.")
            case .ignitionEnable:
                deviceCommands.insert(.mobilize)
            case .ignitionInhibit:
                deviceCommands.insert(.immobilize)
            case .openTrunk:
                deviceCommands.insert(.openTrunk)
            case .closeTrunk:
                deviceCommands.insert(.closeTrunk)
            }
        }
        return deviceCommands
    }

}
