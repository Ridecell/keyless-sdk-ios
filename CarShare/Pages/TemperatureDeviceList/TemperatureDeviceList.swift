//
//  TemperatureDeviceList.swift
//  CarShare
//
//  Created by Matt Snow on 2019-06-03.
//  Copyright © 2019 BSM Technologies Inc. All rights reserved.
//

import RxSwift

struct TemperatureDevice: Equatable {
    let identifier: String
    let name: String
    let temperature: Float?
}

protocol TemperatureDeviceListView: AnyObject {
    func show(_ devices: [TemperatureDevice])
    func showTemperature(value: Float)
    func showError(message: String)
}

protocol TemperatureDeviceListPresenter: AnyObject {
    func viewDidLoad(view: TemperatureDeviceListView)
    func view(_ view: TemperatureDeviceListView, didTapDevice device: TemperatureDevice)
}

protocol TemperatureDeviceListInteractor: AnyObject {
    func scanForDevices() -> Observable<[TemperatureDevice]>
    func updateTemperature(for device: TemperatureDevice) -> Single<TemperatureDevice>
}

protocol TemperatureDeviceListRouter: AnyObject {

}
