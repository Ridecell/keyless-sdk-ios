//  Keyless
//
//  Created by Marc Maguire on 2020-01-10.
//

import Foundation
import SwiftProtobuf

protocol DeviceToAppMessageTransformer {
    func transform(_ data: Data) -> Result<Void, OperationFailureError>
}

enum OperationFailureError: Swift.Error, CustomStringConvertible {
    case protobufSerialization
    case ackFailed([StatusDataRecord])

    var description: String {
        switch self {
        case .protobufSerialization:
            return "Failed to transform GO9 protobuf result data into a Result Message."
        case .ackFailed:
            return "GO9 failed to execute the operations."
        }
    }
}

class ProtobufDeviceToAppMessageTransformer: DeviceToAppMessageTransformer {

    func transform(_ data: Data) -> Result<Void, OperationFailureError> {
        do {
            let deviceToAppMessage = try DeviceToAppMessage(serializedData: data)
            if deviceToAppMessage.result.success {
                return .success(())
            } else {
                let statusData: [StatusDataRecord] = deviceToAppMessage.result.statusData.map { result in
                    StatusDataRecord(code: Int(result.id),
                                     value: Int(result.value))
                }
                return .failure(.ackFailed(statusData))
            }
        } catch {
            print("Failed to transform protobuf result data into Result Message due to error: \(error)")
            return .failure(.protobufSerialization)
        }
    }

}
