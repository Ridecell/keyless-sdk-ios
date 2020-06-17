//
//  StatusDataTransformer.swift
//  Keyless
//
//  Created by Marc Maguire on 2020-06-11.
//

import Foundation

protocol StatusDataTransformer {
    func transform(_ statusData: [StatusDataRecord]) -> KeylessError
}

class VehicleStatusDataTransformer: StatusDataTransformer {

    func transform(_ statusData: [StatusDataRecord]) -> KeylessError {
        let statusDataErrors: [StatusDataError] = statusData.map { error in
            let unknownError = UnknownStatusData(code: error.code, value: error.value)
            return transform(error) ?? unknownError
        }
        return KeylessError(errors: statusDataErrors)
    }
    //swiftlint:disable:next cyclomatic_complexity
    private func transform(_ statusData: StatusDataRecord) -> StatusDataError? {
        switch statusData.code {
        case 3_334:
            return IgnitionInhibitError(rawValue: statusData.value)
        case 3_346:
            return CheckInError(rawValue: statusData.value)
        case 3_355:
            return EndbookConditionsError(rawValue: statusData.value)
        case 3_347:
            return CheckOutError(rawValue: statusData.value)
        case 3_348:
            return LockError(rawValue: statusData.value)
        case 3_349:
            return UnlockDriverError(rawValue: statusData.value)
        case 3_350:
            return UnlockAllError(rawValue: statusData.value)
        case 3_351:
            return LocateError(rawValue: statusData.value)
        case 3_352:
            return IgnitionInhibitFeedback(rawValue: statusData.value)
        case 3_353:
            return IgnitionEnableError(value: statusData.value)
        default:
            return nil
        }
    }
}
