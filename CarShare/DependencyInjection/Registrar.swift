//
//  AppModule.swift
//  CarShare
//
//  Created by Matt Snow on 2019-05-31.
//  Copyright © 2019 BSM Technologies Inc. All rights reserved.
//

import Swinject

protocol Module {
    static func register(in container: Container)
}

enum Registrar {

    private static let modules: [Module.Type] = [
        TemperatureDeviceListModule.self,
        ReservationListModule.self
    ]

    static func appContainer() -> Container {
        let container = Container()
        Registrar.modules.forEach {
            $0.register(in: container)
        }
        registerAllTheThings(in: container)
        return container
    }

    private static func registerAllTheThings(in container: Container) {
        container
            .register(TemperatureWorker.self) { r in
                TemperatureWorker(bluetoothClient: r.resolve(BluetoothClient.self)!)
            }
            .inObjectScope(.container)
        container
            .register(LocationWorker.self) { _ in
                LocationWorker()
            }
            .inObjectScope(.container)
        container
            .register(VehicleWorker.self) { r in
                VehicleWorker(bluetoothClient: r.resolve(BluetoothClient.self)!)
            }
            .inObjectScope(.container)
        container
            .register(BluetoothClient.self) { _ in
                CoreBluetoothClient()
            }
            .inObjectScope(.container)
        container.register(LaunchViewController.self) { r in
            LaunchViewController.initialize(grootWorker: r.resolve(GrootWorker.self)!)
        }
        container.register(GrootWorker.self) { r in
            GrootWorker(bluetoothClient: r.resolve(BluetoothClient.self)!)
        }
        .inObjectScope(.container)
    }
}

//extension Container {
//    @discardableResult
//    public func register<Service>(serviceType: Service.Type, service: @escaping @autoclosure () -> Service) -> ServiceEntry<Service> {
//        return register(serviceType, factory: { _ in service() })
//    }
//}
