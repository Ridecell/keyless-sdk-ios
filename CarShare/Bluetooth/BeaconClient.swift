//
//  BeaconClient.swift
//  CarShare
//
//  Created by Matt Snow on 2019-06-06.
//  Copyright © 2019 BSM Technologies Inc. All rights reserved.
//

import CoreBluetooth
import CoreLocation

class BeaconClient: NSObject {

    private enum State {
        case idle
        case initializing(region: CLBeaconRegion, data: [String: Any])
        case advertising(region: CLBeaconRegion)
    }

    private let peripheralQueue = DispatchQueue(label: "BeaconClient_PeripheralQueue")
    private let mainQueue = DispatchQueue.main
    private lazy var peripheralManager = CBPeripheralManager(delegate: self, queue: self.peripheralQueue)
    private var state = State.idle

    func startAdvertising(_ identifier: String) {
        let uuid = UUID(uuidString: "0CEA4D3C-8193-4A26-887E-0FB5CA95F14E")!
        log.info(uuid.uuidString)
        let region = CLBeaconRegion(proximityUUID: uuid, major: 100, minor: 1, identifier: identifier)

        var data = region.peripheralData(withMeasuredPower: nil) as! [String: Any]
        log.info(region)
//        let data = [
//         data[CBAdvertisementDataManufacturerDataKey] = NSData(bytes: [UInt8(0xaf)], length: 1)
        data[CBAdvertisementDataLocalNameKey] = "vishads-folly-returns"
        data[CBAdvertisementDataServiceUUIDsKey] = CBUUID(string: "1809")
//        ]

        state = .initializing(region: region, data: data)
        peripheralManagerDidUpdateState(peripheralManager)
    }

    func stopAdvertising() {
        state = .idle
        peripheralManager.stopAdvertising()
    }
}

extension BeaconClient: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        guard case let .initializing(region, data) = state, case .poweredOn = peripheralManager.state else {
            return
        }
        state = .advertising(region: region)
        let service = CBMutableService(type: CBUUID(string: "1809"), primary: true)

        service.characteristics = [
            CBMutableCharacteristic(
                type: CBUUID(string: "2A1C"),
                properties: [.read],
                value: nil,
                permissions: [.readable])
        ]
        peripheralManager.add(service)
        log.info(data)

        log.verbose("start advertising")
//        let uuid = UUID(uuidString: "103a878d-3852-4a82-b087-2cd3756c1e06")

    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if let error = error {
            log.error(error)
        } else {
            log.info("added service")
            peripheralManager.startAdvertising([
                CBAdvertisementDataLocalNameKey: "Thermo-Supreme",
                CBAdvertisementDataServiceUUIDsKey: [service.uuid]
            ])
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didOpen channel: CBL2CAPChannel?, error: Error?) {
        log.info("didOpen")
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        log.info("didReceiveRead")
        let temperature: [UInt8] = [
            0, 194, 0, 0, 255
        ]
        request.value = Data(bytes: temperature, count: 5)
        peripheral.respond(to: request, withResult: .success)
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        log.info("didSubscribe \(characteristic.uuid.uuidString)")
    }

}
