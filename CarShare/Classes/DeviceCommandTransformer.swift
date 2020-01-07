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
            populator.command = subCommands(in: command)
                .map { UInt32($0.rawValue) }
                .reduce(0, |)

        }
        do {
            return try deviceCommandMessage.serializedData()
        } catch {
            print("Failed to serialize data to protobuf due to error: \(error)")
            return nil
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

}
