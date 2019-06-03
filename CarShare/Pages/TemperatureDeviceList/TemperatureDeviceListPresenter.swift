//
//  TemperatureDeviceListPresenter.swift
//  CarShare
//
//  Created by Matt Snow on 2019-06-03.
//  Copyright © 2019 BSM Technologies Inc. All rights reserved.
//

import RxSwift

class DefaultTemperatureDeviceListPresenter: TemperatureDeviceListPresenter {

    private let interactor: TemperatureDeviceListInteractor
    private let disposeBag = DisposeBag()

    init(interactor: TemperatureDeviceListInteractor) {
        self.interactor = interactor
    }

    func viewDidLoad(view: TemperatureDeviceListView) {
        interactor.scanForDevices()
            .subscribe(onNext: view.show)
            .disposed(by: disposeBag)
    }

    func view(_ view: TemperatureDeviceListView, didTapDevice device: TemperatureDevice) {
        interactor.updateTemperature(for: device)
            .subscribe(onSuccess: { device in
                if let temperature = device.temperature {
                    view.showTemperature(value: temperature)
                } else {
                    view.showError(message: "ah!!!")
                }
            })
            .disposed(by: disposeBag)
    }

    deinit {
        log.verbose("deinit")
    }

}
