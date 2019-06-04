//
//  TemperatureDeviceListInteractor.swift
//  CarShare
//
//  Created by Matt Snow on 2019-06-03.
//  Copyright © 2019 BSM Technologies Inc. All rights reserved.
//

import RxSwift

class DefaultTemperatureDeviceListInteractor: TemperatureDeviceListInteractor {

    private let temperatureWorker: TemperatureWorker

    init(temperatureWorker: TemperatureWorker) {
        self.temperatureWorker = temperatureWorker
    }

    deinit {
        log.verbose("deinit")
    }

    func scanForDevices() -> Observable<[TemperatureDevice]> {
        return temperatureWorker.findDevices()
            .scan(into: []) { list, device in
                list.append(device)
            }
    }

    func updateTemperature(for device: TemperatureDevice) -> Single<TemperatureDevice> {
        return temperatureWorker.findTemperature(for: device)
            .map {
                TemperatureDevice(
                    identifier: device.identifier,
                    name: device.name,
                    temperature: $0)
            }
    }

}
