//
//  BluetoothClient.swift
//  CarShare
//
//  Created by Matt Snow on 2019-05-31.
//  Copyright © 2019 BSM Technologies Inc. All rights reserved.
//

import CoreBluetooth
import RxSwift

class ChunkingBluetoothClient: NSObject {
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
        case scanning(serviceId: String, subject: PublishSubject<(peripheral: CBPeripheral, advertisementData: [String: Any])>)
        case connecting(peripheral: CBPeripheral, observer: (SingleEvent<CBPeripheral>) -> Void)
        case findingPeripheral(peripheralId: String, observer: (SingleEvent<CBPeripheral?>) -> Void)
        case findingService(serviceId: String, peripheral: CBPeripheral, observer: (SingleEvent<CBService>) -> Void)
        case findingCharacteristic(characteristicId: String, service: CBService, peripheral: CBPeripheral, observer: (SingleEvent<CBCharacteristic>) -> Void)
        case readingCharacteristic(characteristic: CBCharacteristic, service: CBService, peripheral: CBPeripheral, chunks: [Data?]?, observer: (SingleEvent<Data?>) -> Void)
        case writingCharacteristic(remainingChunks: [Data], characteristic: CBCharacteristic, service: CBService, peripheral: CBPeripheral, observer: (CompletableEvent) -> Void)
        case connected(peripheral: CBPeripheral)
    }
}

extension ChunkingBluetoothClient: BluetoothClient {

    func scan(serviceId: String) -> Observable<(peripheral: CBPeripheral, advertisementData: [String: Any])> {
        let subject = PublishSubject<(peripheral: CBPeripheral, advertisementData: [String: Any])>()
        return subject
            .do(onSubscribe: {
                log.debug("scan now!")
                self.state = .scanning(serviceId: serviceId, subject: subject)
                self.centralManagerDidUpdateState(self.bluetoothManager)
            }, onDispose: {
                if case .scanning = self.state {
                    self.state = .idle
                    self.bluetoothManager.stopScan()
                }
            })
            .subscribeOn(bluetoothScheduler)
            .observeOn(mainScheduler)
    }

    func stopScan() -> Completable {
        return Completable.create {
            if case let .scanning(_, subject) = self.state {
                subject.dispose()
            }
            log.debug("stop scan!")
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

    func find(peripheralId: String) -> Single<CBPeripheral?> {
        return Single.create {
            self.state = .findingPeripheral(peripheralId: peripheralId, observer: $0)
            self.centralManagerDidUpdateState(self.bluetoothManager)
            return Disposables.create()
        }
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
            self.state = DeviceState.readingCharacteristic(characteristic: characteristic, service: service, peripheral: peripheral, chunks: nil, observer: $0)
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
            var chunks: [Data] = []

            let chunkSize = 25
            let totalChunks = Int(ceil(Double(data.count) / Double(chunkSize)))
            for i in 0..<totalChunks {
                var chunk = Data(bytes: [UInt8(totalChunks), UInt8(i)], count: 2)
                chunk.append(data.subdata(in: i * chunkSize..<min((i * chunkSize + chunkSize), data.count)))
                chunks.append(chunk)
            }

            self.state = DeviceState.writingCharacteristic(remainingChunks: chunks, characteristic: characteristic, service: service, peripheral: peripheral, observer: $0)
            peripheral.delegate = self
            self.peripheral(peripheral, didWriteValueFor: characteristic, error: nil)
            return Disposables.create()
        }
            .subscribeOn(bluetoothScheduler)
            .observeOn(mainScheduler)
    }

}

extension ChunkingBluetoothClient: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        log.debug("centralManagerDidUpdateState: \(central.state.rawValue)")
        if case let .scanning(serviceId, _) = state, case .poweredOn = central.state {
            bluetoothManager.scanForPeripherals(withServices: [CBUUID(string: serviceId)], options: [
                CBCentralManagerScanOptionAllowDuplicatesKey: NSNumber(booleanLiteral: true)
            ])
        } else if case let .findingPeripheral(peripheralId, observer) = state, case .poweredOn = central.state {
            log.verbose("Looking for \(peripheralId)")
            let peripherals = bluetoothManager.retrievePeripherals(withIdentifiers: [UUID(uuidString: peripheralId)!])
            state = .idle
            observer(.success(peripherals.first))
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        log.debug(peripheral.name ?? "No name for peripheral")
        guard case let .scanning(_, subject) = state else {
            return
        }
        subject.onNext((peripheral, advertisementData))
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        log.debug("didConnect")
        guard case let .connecting(_, observer) = state else {
            return
        }
        log.info("connected to \(peripheral)")
        state = .connected(peripheral: peripheral)
        observer(.success(peripheral))
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        log.debug("didFailToConnect")
        guard case let DeviceState.connecting(_, observer) = state, let error = error else {
            return
        }
        state = .idle
        observer(.error(error))
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        log.debug("didDisconnectPeripheral")
        state = .idle
    }
}

extension ChunkingBluetoothClient: CBPeripheralDelegate {

    func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
        log.debug("peripheralDidUpdateName")
    }

    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        log.debug("didModifyServices")
    }

    func peripheralDidUpdateRSSI(_ peripheral: CBPeripheral, error: Error?) {
        log.debug("peripheralDidUpdateRSSI")
    }

    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        log.debug("didReadRSSI")
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        log.debug("didDiscoverServices")
        guard case let .findingService(serviceId, _, observer) = state, let service = peripheral.services?.first(where: { service in service.uuid.uuidString.lowercased() == serviceId.lowercased() }) else {
            return
        }
        log.info("connected with services")
        state = .connected(peripheral: peripheral)
        observer(.success(service))
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?) {
        log.debug("didDiscoverIncludedServicesFor")
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        log.debug("didDiscoverCharacteristicsFor")
        guard case let .findingCharacteristic(characteristicId, _, _, observer) = state, let characteristic = service.characteristics?.first(where: { $0.uuid.uuidString.lowercased() == characteristicId.lowercased() }) else {
            return
        }
        state = .connected(peripheral: peripheral)
        observer(.success(characteristic))
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard case let .readingCharacteristic(_, service, peripheral, chunksOrNil, observer) = state else {
            return
        }
        guard let chunk = characteristic.value, chunk.count >= 2 else {
            observer(.success(nil))
            return
        }
        var chunks: [Data?] = chunksOrNil ?? Array(repeating: nil, count: Int(chunk[0]))

        let index = Int(chunk[1])
        chunks[index] = chunk.dropFirst(2)

        if let nonEmptyChunks = chunks as? [Data] {
            let data = nonEmptyChunks.reduce(into: Data()) { data, chunk in
                data.append(chunk)
            }
            state = .connected(peripheral: peripheral)
            observer(.success(data))
        } else {
            state = .readingCharacteristic(characteristic: characteristic, service: service, peripheral: peripheral, chunks: chunks, observer: observer)
            //            peripheral.readValue(for: characteristic)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        guard case let DeviceState.writingCharacteristic(chunks, _, service, _, observer) = state else {
            return
        }
        guard !chunks.isEmpty else {
            state = .connected(peripheral: peripheral)
            observer(.completed)
            return
        }
        var remainingChunks = chunks
        let chunk = remainingChunks.removeFirst()
        state = .writingCharacteristic(remainingChunks: remainingChunks, characteristic: characteristic, service: service, peripheral: peripheral, observer: observer)
        peripheral.writeValue(chunk, for: characteristic, type: CBCharacteristicWriteType.withResponse)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        log.debug("didUpdateNotificationStateFor")
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        log.debug("didDiscoverDescriptorsFor")
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        log.debug("didUpdateValueFor")
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        log.debug("didWriteValueFor")
    }

    func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        log.debug("peripheralIsReady")
    }

    func peripheral(_ peripheral: CBPeripheral, didOpen channel: CBL2CAPChannel?, error: Error?) {
        log.debug("didOpen")
    }
}
