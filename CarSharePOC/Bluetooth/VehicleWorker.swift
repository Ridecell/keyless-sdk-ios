//
//  VehicleWorker.swift
//  CarShare
//
//  Created by Matt Snow on 2019-06-04.
//  Copyright © 2019 BSM Technologies Inc. All rights reserved.
//

import CoreBluetooth
import RxSwift

class VehicleWorker {

    private enum Identifier {
        static let service = "1809"
        static let characteristic = "2A1C"
    }

    private let bluetoothClient: BluetoothClient

    init(bluetoothClient: BluetoothClient) {
        self.bluetoothClient = bluetoothClient
    }

    var nearbyVehicles: Observable<[Vehicle]> {
        return Observable.combineLatest(
            Observable<Int>.timer(.seconds(0), period: .seconds(20), scheduler: MainScheduler.instance),
            bluetoothClient
            .scan(serviceId: Identifier.service)
            .map { _ -> Vehicle in
                Vehicle(vehicleId: "v1", vehicleName: "2001 Honda Civic")
            }
            .scan(into: Array<TimedVehicle>()) { list, vehicle in
                if let index = list.firstIndex(where: { $0.vehicle.vehicleId == vehicle.vehicleId }) {
                    list[index] = TimedVehicle(vehicle: vehicle, timestamp: Date().timeIntervalSince1970)
                } else {
                    list.append(TimedVehicle(vehicle: vehicle, timestamp: Date().timeIntervalSince1970))
                }
            })
            .map { _, timedVehicles in
                timedVehicles.reduce(into: Array<Vehicle>()) { list, timedVehicle in
                    if timedVehicle.timestamp > Date().timeIntervalSince1970 - 20 {
                        list.append(timedVehicle.vehicle)
                    }
                }
            }
            .startWith([])

    }

    private struct TimedVehicle {
        let vehicle: Vehicle
        let timestamp: Double
    }
}
