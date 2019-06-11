//
//  BeaconClient.swift
//  CarShare
//
//  Created by Matt Snow on 2019-06-06.
//  Copyright © 2019 BSM Technologies Inc. All rights reserved.
//

import CoreBluetooth
import CoreLocation
import RxSwift

class BeaconClient: NSObject {

    struct PeripheralContext {
        let region: CLBeaconRegion
        let peripheral: CBPeripheralManager
        let advertisingData: [String: Any]
        let serviceId: String
        let characteristicId: String
    }

    private enum State {
        case idle
        case initializing(context: PeripheralContext, observer: (SingleEvent<CBPeripheralManager>) -> Void)
        case advertising(peripheral: CBPeripheralManager)
    }

    private let peripheralQueue = DispatchQueue(label: "BeaconClient_PeripheralQueue")
    private let mainQueue = DispatchQueue.main
    private var state = State.idle

    func startAdvertising(in region: CLBeaconRegion, localName: String, serviceId: String, characteristicId: String) -> Single<CBPeripheralManager> {
        return Single.create { observer in

            let peripheral = CBPeripheralManager(delegate: self, queue: self.peripheralQueue)

            var data = region.peripheralData(withMeasuredPower: nil) as! [String: Any]
            data[CBAdvertisementDataLocalNameKey] = localName
            data[CBAdvertisementDataServiceUUIDsKey] = [CBUUID(string: serviceId)] as CFArray

            self.state = .initializing(
                context: PeripheralContext(
                    region: region,
                    peripheral: peripheral,
                    advertisingData: data,
                    serviceId: serviceId,
                    characteristicId: characteristicId),
                observer: observer)
            self.peripheralManagerDidUpdateState(peripheral)
            return Disposables.create()
        }
    }

    func stopAdvertising() {
        guard case let .advertising(peripheral) = state else {
            return
        }
        state = .idle
        peripheral.stopAdvertising()
    }
}

extension BeaconClient: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        guard case let .initializing(context, _) = state, case .poweredOn = peripheral.state else {
            return
        }
        let service = CBMutableService(type: CBUUID(string: context.serviceId), primary: true)

        service.characteristics = [
            CBMutableCharacteristic(
                type: CBUUID(string: context.characteristicId),
                properties: [.read, .write],
                value: nil,
                permissions: [.readable, .writeable])
        ]
        log.verbose("adding service")
        peripheral.add(service)
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        log.verbose("service added")
        guard case let .initializing(context, _) = state else {
            return
        }
        peripheral.startAdvertising(context.advertisingData)
    }

    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        log.verbose("advertising started")
        guard case let .initializing(advertisingData, observer) = state else {
            return
        }
        dump(advertisingData)
        state = .advertising(peripheral: peripheral)
        observer(.success(peripheral))
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didOpen channel: CBL2CAPChannel?, error: Error?) {
        log.info("didOpen")
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        log.info("didReceiveRead")

        request.value = "Hello, this is Matt's phone".data(using: .utf8)
        peripheral.respond(to: request, withResult: .success)
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        log.info("didSubscribe \(characteristic.uuid.uuidString)")
    }

}
