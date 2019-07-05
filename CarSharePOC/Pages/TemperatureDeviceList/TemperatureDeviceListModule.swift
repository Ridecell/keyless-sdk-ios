//
//  TemperatureDeviceListModule.swift
//  CarShare
//
//  Created by Matt Snow on 2019-06-03.
//  Copyright © 2019 BSM Technologies Inc. All rights reserved.
//

import Swinject

enum TemperatureDeviceListModule: Module {
    static func register(in container: Container) {
        container.register(TemperatureDeviceListView.self) { r in
            TemperatureDeviceListViewController.initialize(presenter: r.resolve(TemperatureDeviceListPresenter.self)!)
        }
        container.register(TemperatureDeviceListPresenter.self) { r in
            DefaultTemperatureDeviceListPresenter(interactor: r.resolve(TemperatureDeviceListInteractor.self)!)
        }
        container.register(TemperatureDeviceListInteractor.self) { r in
            DefaultTemperatureDeviceListInteractor(temperatureWorker: r.resolve(TemperatureWorker.self)!)
        }
    }
}
