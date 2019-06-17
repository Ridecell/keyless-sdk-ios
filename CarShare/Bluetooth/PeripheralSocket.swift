//
//  PeripheralSocket.swift
//  CarShare
//
//  Created by Matt Snow on 2019-06-13.
//  Copyright © 2019 BSM Technologies Inc. All rights reserved.
//

import CoreBluetooth
import CoreLocation

protocol PeripheralSocketDelegate: SocketDelegate {}

protocol PeripheralSocket: Socket {

    var delegate: PeripheralSocketDelegate? { get set }

    func advertiseL2CAPChannel(in region: CLBeaconRegion, serviceId: String, characteristicId: String)

}

class BasePeripheralSocket: NSObject, PeripheralSocket {

    private enum State {
        case idle
        case initializing(advertisingData: [String: Any], serviceId: CBUUID, characteristicId: CBUUID)
        case advertising(characteristic: CBMutableCharacteristic, psms: [CBL2CAPPSM], centrals: [CBCentral])
        case open(characteristic: CBMutableCharacteristic, psms: [CBL2CAPPSM], centrals: [CBCentral], channel: CBL2CAPChannel)
    }

    private var state: State = .idle {
        didSet {
            log.info(state)
        }
    }

    private lazy var peripheral: CBPeripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    weak var delegate: PeripheralSocketDelegate?

    weak var socketDelegate: SocketDelegate? {
        return delegate
    }

    func advertiseL2CAPChannel(in region: CLBeaconRegion, serviceId: String, characteristicId: String) {

        let serviceUUID = CBUUID(string: serviceId)
        let advertisingData = [
            CBAdvertisementDataServiceUUIDsKey: [serviceUUID]
        ]

        state = .initializing(
            advertisingData: advertisingData,
            serviceId: serviceUUID,
            characteristicId: CBUUID(string: characteristicId))

        self.peripheralManagerDidUpdateState(peripheral)

    }

    func close() {
        switch state {
        case .initializing(advertisingData: _, serviceId: _, characteristicId: _):
            peripheral.removeAllServices()
            peripheral.stopAdvertising()
        case let .advertising(characteristic: _, psms: psms, centrals: _):
            psms.forEach(peripheral.unpublishL2CAPChannel)
            peripheral.removeAllServices()
            peripheral.stopAdvertising()
        case let .open(characteristic: _, psms: psms, centrals: _, channel: channel):
            psms.forEach(peripheral.unpublishL2CAPChannel)
            peripheral.removeAllServices()
            peripheral.stopAdvertising()
            channel.inputStream.close()
            channel.inputStream.remove(from: .main, forMode: .default)
            channel.outputStream.close()
            channel.outputStream.remove(from: .main, forMode: .default)
        case .idle:
            return
        }
        state = .idle

    }

    func write(_ data: Data) -> Bool {
        guard case let .open(characteristic: _, psms: _, centrals: _, channel: channel) = state else {
            return false
        }

        return write(data, into: channel.outputStream)
    }

}

extension BasePeripheralSocket: CBPeripheralManagerDelegate {

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        guard peripheral.state == .poweredOn else {
            return
        }
        guard case let .initializing(advertisingData, serviceId, characteristicId) = state else {
            return
        }
        let service = CBMutableService(type: serviceId, primary: true)
        let characteristic = CBMutableCharacteristic(
            type: characteristicId,
            properties: [.read, .indicate],
            value: nil,
            permissions: .readable)
        service.characteristics = [characteristic]

        state = .advertising(characteristic: characteristic, psms: [], centrals: [])
        peripheral.add(service)
        peripheral.publishL2CAPChannel(withEncryption: true)
        peripheral.startAdvertising(advertisingData)
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didPublishL2CAPChannel PSM: CBL2CAPPSM, error: Error?) {
        guard case let .advertising(characteristic, _, centrals) = state else {
            return
        }
        guard let value = "\(PSM)".data(using: .utf8) else {
            return
        }
        state = .advertising(characteristic: characteristic, psms: [PSM], centrals: centrals)
        characteristic.value = value
        peripheral.updateValue(value, for: characteristic, onSubscribedCentrals: centrals)
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didUnpublishL2CAPChannel PSM: CBL2CAPPSM, error: Error?) {
        guard peripheral.state == .poweredOn else {
            return
        }
        guard case let .advertising(characteristic, _, centrals) = state else {
            return
        }
        let value = Data()
        state = .advertising(characteristic: characteristic, psms: [], centrals: centrals)
        characteristic.value = value
        peripheral.updateValue(value, for: characteristic, onSubscribedCentrals: centrals)
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        guard case .advertising(let characteristic, let psms, var centrals) = state else {
            return
        }
        centrals.append(central)
        state = .advertising(characteristic: characteristic, psms: psms, centrals: centrals)
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        guard peripheral.state == .poweredOn else {
            return
        }
        guard case .advertising(let characteristic, let psms, var centrals) = state else {
            return
        }
        centrals.removeAll(where: { $0 == central})
        state = .advertising(characteristic: characteristic, psms: psms, centrals: centrals)
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        guard case let .advertising(characteristic, _, _) = state else {
            return
        }
        request.value = characteristic.value
        peripheral.respond(to: request, withResult: .success)
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didOpen channel: CBL2CAPChannel?, error: Error?) {
        guard case let .advertising(characteristic, psms, centrals) = state, let channel = channel else {
            return
        }
        peripheral.stopAdvertising()
        channel.inputStream.delegate = self
        channel.inputStream.schedule(in: .main, forMode: .default)
        channel.inputStream.open()
        channel.outputStream.delegate = self
        channel.outputStream.schedule(in: .main, forMode: .default)
        channel.outputStream.open()
        state = .open(characteristic: characteristic, psms: psms, centrals: centrals, channel: channel)
        delegate?.socketDidOpen(self)
    }

}

extension BasePeripheralSocket: StreamDelegate {
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        guard case .open = state else {
            return
        }
        handleStream(aStream, handle: eventCode)
    }
}
