//
//  DeviceCommandTransformer.swift
//  CarShare
//
//  Created by Marc Maguire on 2019-11-06.
//

import Foundation
import SwiftProtobuf

protocol DeviceCommandTransformer {
    func transform(_ command: Command) -> Data?
}

class ProtobufDeviceCommandTransformer: DeviceCommandTransformer {
    func transform(_ command: Command) -> Data? {
        let deviceCommandMessage = DeviceCommandMessage.with { populator in
            populator.command = {
                switch command {
                case .checkIn:
                    return DeviceCommandMessage.Command.checkin
                case .checkOut:
                    return DeviceCommandMessage.Command.checkout
                case .locate:
                    return DeviceCommandMessage.Command.locate
                case .lock:
                    return DeviceCommandMessage.Command.lock
                case .unlockAll:
                    return DeviceCommandMessage.Command.unlockAll
                case .unlockDriver:
                    return DeviceCommandMessage.Command.unlockDriver
                case .openTrunk:
                    return DeviceCommandMessage.Command.openTrunk
                case .closeTrunk:
                    return DeviceCommandMessage.Command.closeTrunk
                }
            }()
        }
        do {
            return try deviceCommandMessage.serializedData()
        } catch {
            print("Failed to serialize data to protobuf due to error: \(error)")
            return nil
        }
    }
}
