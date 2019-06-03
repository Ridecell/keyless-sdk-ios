//
//  LaunchViewController.swift
//  CarShare
//
//  Created by Matt Snow on 2019-05-31.
//  Copyright © 2019 BSM Technologies Inc. All rights reserved.
//

import RxSwift
import UIKit

class LaunchViewController: UIViewController {

    static func initialize(temperatureWorker: TemperatureWorker) -> LaunchViewController {
        let viewController = LaunchViewController()
        viewController.temperatureWorker = temperatureWorker
        return viewController
    }

    private var temperatureWorker: TemperatureWorker!

    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        label.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        label.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true

        label.text = "Launch..."
        DispatchQueue.main.async {
            self.temperatureWorker.printTemperature()
            .subscribe(
                onSuccess: { temperature in
                    print("Temperature: \(temperature!)°C")
                    label.text = "\(temperature!)°C"
                },
                onError: { error in
                    print(error)
                })
                .disposed(by: self.disposeBag)
        }
    }

}
