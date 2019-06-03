//
//  AppModule.swift
//  CarShare
//
//  Created by Matt Snow on 2019-05-31.
//  Copyright © 2019 BSM Technologies Inc. All rights reserved.
//

import Swinject

enum Registrar {
    static func appContainer() -> Container {
        let container = Container()
        registerAllTheThings(in: container)
        return container
    }

    private static func registerAllTheThings(in container: Container) {
        container.register(TemperatureWorker.self) { r in
            TemperatureWorker(bluetoothClient: r.resolve(BluetoothClient.self)!)
        }
        container.register(BluetoothClient.self) { _ in
            CoreBluetoothClient()
        }
        container.register(LaunchViewController.self) { r in
            LaunchViewController.initialize(temperatureWorker: r.resolve(TemperatureWorker.self)!)
        }

    }
}

//extension Container {
//    @discardableResult
//    public func register<Service>(serviceType: Service.Type, service: @escaping @autoclosure () -> Service) -> ServiceEntry<Service> {
//        return register(serviceType, factory: { _ in service() })
//    }
//}
