//
//  TemperatureDeviceListInteractor.swift
//  CarShare
//
//  Created by Matt Snow on 2019-06-03.
//  Copyright © 2019 BSM Technologies Inc. All rights reserved.
//

import RxSwift

extension Array {
    func appending(_ element: Element) -> Array<Element> {
        var array = self
        array.append(element)
        return array
    }
}

class DefaultTemperatureDeviceListInteractor: TemperatureDeviceListInteractor {

    private let temperatureWorker: TemperatureWorker

    init(temperatureWorker: TemperatureWorker) {
        self.temperatureWorker = temperatureWorker
    }

    func scanForDevices() -> Observable<[TemperatureDevice]> {
        return temperatureWorker.findDevices()
            .scan([]) { list, device in
                list.appending(device)
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
