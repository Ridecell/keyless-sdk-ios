//  CarShare
//
//  Created by Marc Maguire on 2020-01-10.
//

import Foundation
import SwiftProtobuf

protocol DeviceToAppMessageTransformer {
    func transform(_ data: Data) -> Result<Bool, Error>
}

class ProtobufDeviceToAppMessageTransformer: DeviceToAppMessageTransformer {

    enum DeviceToAppMessageTransformerError: Swift.Error {
        case ackError
    }

    func transform(_ data: Data) -> Result<Bool, Error> {
        do {
            let deviceToAppMessage = try DeviceToAppMessage(serializedData: data)
            if deviceToAppMessage.result.success {
                return .success(true)
            } else {
                return .failure(DeviceToAppMessageTransformerError.ackError)
            }
        } catch {
            print("Failed to transform protobuf result data into Result Message due to error \(error.localizedDescription)")
            return .failure(error)
        }
    }

}
