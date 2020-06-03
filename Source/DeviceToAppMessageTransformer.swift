//  Keyless
//
//  Created by Marc Maguire on 2020-01-10.
//

import Foundation
import SwiftProtobuf

protocol DeviceToAppMessageTransformer {
    func transform(_ data: Data) -> Result<Bool, Error>
}

class ProtobufDeviceToAppMessageTransformer: DeviceToAppMessageTransformer {

    enum DeviceToAppMessageTransformerError: Swift.Error, CustomStringConvertible {
        case protobufSerialization
        case ackFailed

        var description: String {
            switch self {
            case .protobufSerialization:
                return "Failed to transform GO9 protobuf result data into a Result Message."
            case .ackFailed:
                return "GO9 failed to execute the command."
            }
        }
    }

    func transform(_ data: Data) -> Result<Bool, Error> {
        do {
            let deviceToAppMessage = try DeviceToAppMessage(serializedData: data)
            if deviceToAppMessage.result.success {
                return .success(true)
            } else {
                return .failure(DeviceToAppMessageTransformerError.ackFailed)
            }
        } catch {
            print("Failed to transform protobuf result data into Result Message due to error: \(error)")
            return .failure(DeviceToAppMessageTransformerError.protobufSerialization)
        }
    }

}
