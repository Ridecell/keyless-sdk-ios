//
//  BluetoothClient.swift
//  CarShare
//
//  Created by Matt Snow on 2019-05-31.
//  Copyright © 2019 BSM Technologies Inc. All rights reserved.
//

import CoreBluetooth
import RxSwift

protocol BluetoothClient {
    func scan(serviceId: String) -> Observable<CBPeripheral>
    func stopScan() -> Completable
    func connect(to peripheral: CBPeripheral) -> Single<CBPeripheral>
    func disconnect(from peripheral: CBPeripheral) -> Completable
    func find(serviceId: String, for peripheral: CBPeripheral) -> Single<CBService>
    func find(characteristicId: String, for service: CBService) -> Single<CBCharacteristic>
    func read(_ characteristic: CBCharacteristic) -> Single<Data?>
    func write(data: Data, to characteristic: CBCharacteristic) -> Completable
}

class CoreBluetoothClient: NSObject {
    private lazy var bluetoothManager = CBCentralManager(
        delegate: self,
        queue: self.bluetoothQueue,
        options: [:
//            CBCentralManagerOptionRestoreIdentifierKey: reuseIdentifier
        ])
    private let reuseIdentifier = "BluetoothClient_CBCentralManagerOptionRestoreIdentifierKey"
    private let mainScheduler = MainScheduler.instance
    private let bluetoothQueue = DispatchQueue(label: "BluetoothClient")
    private lazy var bluetoothScheduler = ConcurrentDispatchQueueScheduler(queue: self.bluetoothQueue)

    private var state: DeviceState = .idle

    enum DeviceState {
        case idle
        case scanning(serviceId: String, subject: PublishSubject<CBPeripheral>)
        case connecting(peripheral: CBPeripheral, observer: (SingleEvent<CBPeripheral>) -> Void)
        case findingService(serviceId: String, peripheral: CBPeripheral, observer: (SingleEvent<CBService>) -> Void)
        case findingCharacteristic(characteristicId: String, service: CBService, peripheral: CBPeripheral, observer: (SingleEvent<CBCharacteristic>) -> Void)
        case readingCharacteristic(characteristic: CBCharacteristic, service: CBService, peripheral: CBPeripheral, observer: (SingleEvent<Data?>) -> Void)
        case writingCharacteristic(value: Data, characteristic: CBCharacteristic, service: CBService, peripheral: CBPeripheral, observer: (CompletableEvent) -> Void)
        case connected(peripheral: CBPeripheral)
    }
}

extension CoreBluetoothClient: BluetoothClient {

    func scan(serviceId: String) -> Observable<CBPeripheral> {
        let subject = PublishSubject<CBPeripheral>()
        return subject
            .do(onSubscribe: {
                print("scan now!")
                self.state = .scanning(serviceId: serviceId, subject: subject)
                self.centralManagerDidUpdateState(self.bluetoothManager)
            })
            .subscribeOn(bluetoothScheduler)
            .observeOn(mainScheduler)
    }

    func stopScan() -> Completable {
        return Completable.create {
            if case let .scanning(_, subject) = self.state {
                subject.dispose()
            }
            print("stop scan!")
            self.state = .idle
            self.bluetoothManager.stopScan()
            $0(.completed)
            return Disposables.create()
        }
            .subscribeOn(bluetoothScheduler)
            .observeOn(mainScheduler)
    }

    func connect(to peripheral: CBPeripheral) -> Single<CBPeripheral> {
        return Single.create {
            self.state = .connecting(peripheral: peripheral, observer: $0)
            self.bluetoothManager.connect(peripheral)
            return Disposables.create()
        }
            .subscribeOn(bluetoothScheduler)
            .observeOn(mainScheduler)
    }

    func disconnect(from peripheral: CBPeripheral) -> Completable {
        return Completable.create {
            self.state = .idle
            self.bluetoothManager.cancelPeripheralConnection(peripheral)
            $0(.completed)
            return Disposables.create()
        }
            .subscribeOn(bluetoothScheduler)
            .observeOn(mainScheduler)
    }

    func find(serviceId: String, for peripheral: CBPeripheral) -> Single<CBService> {
        return Single.create {
            self.state = .findingService(serviceId: serviceId, peripheral: peripheral, observer: $0)
            peripheral.delegate = self
            peripheral.discoverServices([CBUUID(string: serviceId)])
            return Disposables.create()
        }
            .subscribeOn(bluetoothScheduler)
            .observeOn(mainScheduler)
    }

    func find(characteristicId: String, for service: CBService) -> Single<CBCharacteristic> {
        return Single.create {
            let peripheral = service.peripheral
            self.state = .findingCharacteristic(characteristicId: characteristicId, service: service, peripheral: peripheral, observer: $0)
            peripheral.delegate = self
            peripheral.discoverCharacteristics(nil, for: service)
            return Disposables.create()
        }
            .subscribeOn(bluetoothScheduler)
            .observeOn(mainScheduler)
    }

    func read(_ characteristic: CBCharacteristic) -> Single<Data?> {
        return Single.create {
            let peripheral = characteristic.service.peripheral
            let service = characteristic.service
            self.state = DeviceState.readingCharacteristic(characteristic: characteristic, service: service, peripheral: peripheral, observer: $0)
            peripheral.delegate = self
            peripheral.readValue(for: characteristic)
            return Disposables.create()
        }
            .subscribeOn(bluetoothScheduler)
            .observeOn(mainScheduler)
    }

    func write(data: Data, to characteristic: CBCharacteristic) -> Completable {
        return Completable.create {
            let peripheral = characteristic.service.peripheral
            let service = characteristic.service
            self.state = DeviceState.writingCharacteristic(value: data, characteristic: characteristic, service: service, peripheral: peripheral, observer: $0)
            peripheral.delegate = self
            peripheral.writeValue(data, for: characteristic, type: CBCharacteristicWriteType.withResponse)
            return Disposables.create()
        }
            .subscribeOn(bluetoothScheduler)
            .observeOn(mainScheduler)
    }

}

extension CoreBluetoothClient: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("centralManagerDidUpdateState: \(central.state.rawValue)")
        if case let .scanning(serviceId, _) = state, case .poweredOn = central.state {
            print("scannnnn")
            bluetoothManager.scanForPeripherals(withServices: [CBUUID(string: serviceId)])
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        print(peripheral.name ?? "No name for peripheral")
        guard case let .scanning(_, subject) = state else {
            return
        }
        subject.onNext(peripheral)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("didConnect")
        guard case let .connecting(_, observer) = state else {
            return
        }
        state = .connected(peripheral: peripheral)
        observer(.success(peripheral))
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("didFailToConnect")
        guard case let DeviceState.connecting(_, observer) = state, let error = error else {
            return
        }
        state = .idle
        observer(.error(error))
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("didDisconnectPeripheral")
        state = .idle
    }
}

extension CoreBluetoothClient: CBPeripheralDelegate {

    func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
        print("peripheralDidUpdateName")
    }

    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        print("didModifyServices")
    }

    func peripheralDidUpdateRSSI(_ peripheral: CBPeripheral, error: Error?) {
        print("peripheralDidUpdateRSSI")
    }

    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        print("didReadRSSI")
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("didDiscoverServices")
        guard case let .findingService(serviceId, _, observer) = state, let service = peripheral.services?.first(where: { service in service.uuid.uuidString == serviceId }) else {
            return
        }
        state = .connected(peripheral: peripheral)
        observer(.success(service))
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?) {
        print("didDiscoverIncludedServicesFor")
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("didDiscoverCharacteristicsFor")
        guard case let .findingCharacteristic(characteristicId, _, _, observer) = state, let characteristic = service.characteristics?.first(where: { $0.uuid.uuidString == characteristicId }) else {
            return
        }
        state = .connected(peripheral: peripheral)
        observer(.success(characteristic))
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard case let .readingCharacteristic(_, _, _, observer) = state else {
            return
        }
        state = .connected(peripheral: peripheral)
        observer(.success(characteristic.value))
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        guard case let DeviceState.writingCharacteristic(_, _, _, _, observer) = state else {
            return
        }
        state = .connected(peripheral: peripheral)
        observer(.completed)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print("didUpdateNotificationStateFor")
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        print("didDiscoverDescriptorsFor")
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        print("didUpdateValueFor")
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        print("didWriteValueFor")
    }

    func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        print("peripheralIsReady")
    }

    func peripheral(_ peripheral: CBPeripheral, didOpen channel: CBL2CAPChannel?, error: Error?) {
        print("didOpen")
    }
}