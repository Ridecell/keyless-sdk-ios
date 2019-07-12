//
//  ProtobufMessageBuilder.swift
//  CarShare
//
//  Created by Marc Maguire on 2019-07-11.
//

import Foundation
import SwiftProtobuf

class ProtobufMessageHandler {
    static func create(permission: Permission_t) -> ReservationMessage {
        var message = ReservationMessage()
        var command = Account_t()
        command.clearPermissions()
        command.permissions = permission
        message.directCommand = command
        return message
    }
}
