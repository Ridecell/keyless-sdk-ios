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
        return bluetoothClient
            .scan(serviceId: Identifier.service)
            .map { _ in
                Vehicle(vehicleId: "v1", vehicleName: "2001 Honda Civic")
            }
            .scan(into: []) { list, vehicle in
                if let index = list.firstIndex(where: { $0.vehicleId == vehicle.vehicleId }) {
                    list[index] = vehicle
                } else {
                    list.append(vehicle)
                }
            }
            .startWith([])
            .debug()

    }
}
