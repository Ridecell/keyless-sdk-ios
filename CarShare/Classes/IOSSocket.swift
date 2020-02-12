//
//  iOSSocket.swift
//  CarShare
//
//  Created by Matt Snow on 2019-07-05.
//

import CoreBluetooth
import Foundation

class IOSSocket: NSObject, Socket {

    enum IOSSocketError: Swift.Error, CustomStringConvertible {
        case bluetoothOff
        case notConnected
        case noData
        case badResponse

        var description: String {
            switch self {
            case .bluetoothOff:
                return "Bluetooth is turned off."
            case .notConnected:
                return "Not Connected."
            case .noData:
                return "No Data"
            case .badResponse:
                return "Bad Response"
            }
        }
    }

    private enum State {
        case idle
        case initializing(advertisingData: [String: Any], serviceId: CBUUID, notifyCharacteristicId: CBUUID, writeCharacteristicId: CBUUID)
        case advertising(notifyCharacteristic: CBMutableCharacteristic, writeCharacteristic: CBMutableCharacteristic)
        case connected(notifyCharacteristic: CBMutableCharacteristic, writeCharacteristic: CBMutableCharacteristic, central: CBCentral)
    }

    private let peripheral: CBPeripheralManager

    init(peripheral: CBPeripheralManager) {
        self.peripheral = peripheral
    }

    private var state: State = .idle

    weak var delegate: SocketDelegate?

    var mtu: Int? {
        if case let .connected(_, _, central) = state {
            return central.maximumUpdateValueLength
        } else {
            return nil
        }
    }

    private var dataToSend: Data?

    func open(_ configuration: BLeSocketConfiguration) {

        guard case .idle = state else {
            return
        }

        peripheral.delegate = self
        let serviceId = CBUUID(string: configuration.serviceID)
        let advertisingData = [
            CBAdvertisementDataServiceUUIDsKey: [serviceId]
        ]

        state = .initializing(
            advertisingData: advertisingData,
            serviceId: serviceId,
            notifyCharacteristicId: CBUUID(string: configuration.notifyCharacteristicID),
            writeCharacteristicId: CBUUID(string: configuration.writeCharacteristicID)
        )

        peripheralManagerDidUpdateState(peripheral)
    }

    func close() {
        state = .idle
        if peripheral.isAdvertising {
            peripheral.stopAdvertising()
        }
        peripheral.removeAllServices()
    }

    func send(_ data: Data) {
        guard case .connected = state else {
            delegate?.socketDidFailToSend(self, error: IOSSocketError.notConnected)
            return
        }

        dataToSend = data

        peripheralManagerIsReady(toUpdateSubscribers: peripheral)
    }
}

extension IOSSocket: CBPeripheralManagerDelegate {

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {

        if peripheral.state == .poweredOff {
            delegate?.socketDidCloseUnexpectedly(self, error: IOSSocketError.bluetoothOff)
        }
        guard peripheral.state == .poweredOn else {
            return
        }

        guard case let .initializing(advertisingData, serviceId, notifyCharacteristicId, writeCharacteristicId) = state else {
            return
        }
        let service = CBMutableService(type: serviceId, primary: true)
        let notifyCharacteristic = CBMutableCharacteristic(
            type: notifyCharacteristicId,
            properties: [.notify],
            value: nil,
            permissions: [])
        let writeCharacteristic = CBMutableCharacteristic(
            type: writeCharacteristicId,
            properties: [.writeWithoutResponse],
            value: nil,
            permissions: [.writeable])
        service.characteristics = [notifyCharacteristic, writeCharacteristic]

        state = .advertising(notifyCharacteristic: notifyCharacteristic, writeCharacteristic: writeCharacteristic)
        peripheral.add(service)
        peripheral.startAdvertising(advertisingData)

    }

    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        guard case let .advertising(notifyCharacteristic, writeCharacteristic) = state else {
            return
        }
        state = .connected(notifyCharacteristic: notifyCharacteristic, writeCharacteristic: writeCharacteristic, central: central)
        peripheral.stopAdvertising()
        delegate?.socketDidOpen(self)
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        guard case let .connected(_, _, connectedCentral) = state else {
            return
        }
        guard central == connectedCentral else {
            return
        }
        peripheral.removeAllServices()
        state = .idle
        delegate?.socketDidCloseUnexpectedly(self, error: IOSSocketError.notConnected)
    }

    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        guard let data = dataToSend else {
            return
        }
        guard case let .connected(notifyCharacteristic, _, central) = state else {
            dataToSend = nil
            delegate?.socketDidFailToSend(self, error: IOSSocketError.notConnected)
            return
        }

        guard peripheral.updateValue(data, for: notifyCharacteristic, onSubscribedCentrals: [central]) else {
            return
        }
        dataToSend = nil
        delegate?.socketDidSend(self)
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        print(#function)
        guard case let .connected(_, _, central) = state else {
            return
        }
        guard let request = requests.first, request.central == central, let data = request.value else {
            return
        }
        delegate?.socket(self, didReceive: data)
    }

}
