//
//  CentralSocket.swift
//  CarShare
//
//  Created by Matt Snow on 2019-06-13.
//  Copyright © 2019 BSM Technologies Inc. All rights reserved.
//

import CoreBluetooth
import CoreLocation

protocol CentralSocketDelegate: SocketDelegate {
    func centralSocket(_ centralSocket: CentralSocket, didDiscover peripheral: CBPeripheral)
    func centralSocketDidOpen(_ centralSocket: CentralSocket)
}

class CentralSocket: NSObject, Socket {

    private enum State {
        case idle
        case scanning(serviceId: CBUUID)
        case connecting(peripheral: CBPeripheral, serviceId: CBUUID, characteristicId: CBUUID)
        case discoveringService(peripheral: CBPeripheral, serviceId: CBUUID, characteristicId: CBUUID)
        case discoveringCharacteristic(peripheral: CBPeripheral, service: CBService, characteristicId: CBUUID)
        case discoveringPSM(peripheral: CBPeripheral, characteristic: CBCharacteristic)
        case openingSocket(peripheral: CBPeripheral, psm: CBL2CAPPSM)
        case open(peripheral: CBPeripheral, channel: CBL2CAPChannel)
    }

    private var state: State = .idle {
        didSet {
            log.info(state)
        }
    }
    private lazy var central: CBCentralManager = CBCentralManager(delegate: self, queue: nil)

    weak var delegate: CentralSocketDelegate?
    weak var socketDelegate: SocketDelegate? {
        return delegate
    }

    func scan(for serviceId: String) {
        state = .scanning(serviceId: CBUUID(string: serviceId))
        centralManagerDidUpdateState(central)
    }

    func stopScanning() {
        state = .idle
        central.stopScan()
    }

    func open(_ peripheral: CBPeripheral, serviceId: String, characteristicId: String) {
        state = .connecting(peripheral: peripheral, serviceId: CBUUID(string: serviceId), characteristicId: CBUUID(string: characteristicId))
        centralManagerDidUpdateState(central)
    }

    func close() {
        switch state {
        case .idle:
            return
        case .scanning(serviceId: _):
            central.stopScan()
        case let .connecting(peripheral: peripheral, serviceId: _, characteristicId: _):
            central.cancelPeripheralConnection(peripheral)
        case let .openingSocket(peripheral: peripheral, psm: _):
            central.cancelPeripheralConnection(peripheral)
        case let .discoveringCharacteristic(peripheral: peripheral, service: _, characteristicId: _):
            central.cancelPeripheralConnection(peripheral)
        case let .discoveringService(peripheral: peripheral, serviceId: _, characteristicId: _):
            central.cancelPeripheralConnection(peripheral)
        case let .discoveringPSM(peripheral: peripheral, characteristic: _):
            central.cancelPeripheralConnection(peripheral)
        case let .open(peripheral: peripheral, channel: channel):
            central.cancelPeripheralConnection(peripheral)
            channel.inputStream.close()
            channel.inputStream.remove(from: .main, forMode: .default)
            channel.outputStream.close()
            channel.outputStream.remove(from: .main, forMode: .default)
        }
        state = .idle
    }

    func write(_ data: Data) {
        guard case let .open(peripheral: _, channel: channel) = state else {
            return
        }
        write(data, into: channel.outputStream)
    }
}

extension CentralSocket: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard central.state == .poweredOn else {
            return
        }
        switch state {
        case let .scanning(serviceId: serviceId):
            central.scanForPeripherals(withServices: [serviceId], options: nil)
        case let .connecting(peripheral: peripheral, serviceId: _, characteristicId: _):
            central.stopScan()
            central.connect(peripheral, options: nil)
        default:
            break
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        delegate?.centralSocket(self, didDiscover: peripheral)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        guard case let .connecting(peripheral: peripheral, serviceId: serviceId, characteristicId: characteristicId) = state else {
            return
        }
        state = .discoveringService(peripheral: peripheral, serviceId: serviceId, characteristicId: characteristicId)
        peripheral.delegate = self
        peripheral.discoverServices([serviceId])
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        guard case .open = state else {
            close()
            return
        }
        close()
        socketDelegate?.socketDidClose(self)

    }
}

extension CentralSocket: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard case let .discoveringService(peripheral: peripheral, serviceId: serviceId, characteristicId: characteristicId) = state else {
            return
        }
        guard let service = peripheral.services?.first(where: {$0.uuid == serviceId}) else {
            return
        }
        state = .discoveringCharacteristic(peripheral: peripheral, service: service, characteristicId: characteristicId)
        peripheral.discoverCharacteristics([characteristicId], for: service)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard case let .discoveringCharacteristic(peripheral: peripheral, service: service, characteristicId: characteristicId) = state else {
            return
        }
        guard let characteristic = service.characteristics?.first(where: { $0.uuid == characteristicId }) else {
            return
        }
        state = .discoveringPSM(peripheral: peripheral, characteristic: characteristic)
        peripheral.setNotifyValue(true, for: characteristic)
        peripheral.readValue(for: characteristic)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard case let .discoveringPSM(peripheral: peripheral, characteristic: characteristic) = state else {
            return
        }
        guard let data = characteristic.value, let psmString = String(data: data, encoding: .utf8), let psm = UInt16(psmString) else {
            return
        }
        state = .openingSocket(peripheral: peripheral, psm: psm)
        peripheral.openL2CAPChannel(psm)
    }

    func peripheral(_ peripheral: CBPeripheral, didOpen channel: CBL2CAPChannel?, error: Error?) {
        guard case let .openingSocket(peripheral: peripheral, psm: _) = state else {
            return
        }
        guard let channel = channel else {
            return
        }
        channel.inputStream.delegate = self
        channel.inputStream.schedule(in: .main, forMode: .default)
        channel.inputStream.open()
        channel.outputStream.delegate = self
        channel.outputStream.schedule(in: .main, forMode: .default)
        channel.outputStream.open()
        state = .open(peripheral: peripheral, channel: channel)
        delegate?.centralSocketDidOpen(self)
    }

}

extension CentralSocket: StreamDelegate {
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        guard case .open = state else {
            return
        }
        handleStream(aStream, handle: eventCode)
    }
}
