//
//  PeripheralManagerSocket.swift
//  Keyless
//
//  Created by Matt Snow on 2019-07-05.
//

import CoreBluetooth
import Foundation

class PeripheralManagerSocket: NSObject, Socket {

    enum SocketError: Swift.Error, CustomStringConvertible {
        case bluetoothOff
        case notConnected
        case lostConnection
        case noData
        case badResponse

        var description: String {
            switch self {
            case .bluetoothOff:
                return "Bluetooth is turned off"
            case .notConnected:
                return "Not connected"
            case .lostConnection:
                return "Lost the connection to the central"
            case .noData:
                return "No data"
            case .badResponse:
                return "Bad response"
            }
        }
    }

    let peripheral: CBPeripheralManager
    let log: Logger
    let executer: AsyncExecuter

    var state: SocketState = Noop() {
        didSet {
            log.v("State: \(state)")
            peripheral.delegate = state
            state.transition()
        }
    }

    weak var delegate: SocketDelegate?

    init(
        logger: Logger = NoopLogger(),
        peripheral: CBPeripheralManager = CBPeripheralManager(delegate: nil, queue: DispatchQueue(label: "PeripheralManagerSocket-\(UUID().uuidString)")),
        executer: AsyncExecuter = MainExecuter()) {
        self.peripheral = peripheral
        self.log = logger
        self.executer = executer
    }

    var mtu: Int? {
        guard let connected = state as? Connected else {
            return nil
        }
        return connected.central.maximumUpdateValueLength
    }

    private var dataToSend: Data?

    func open(_ configuration: BLeSocketConfiguration) {
        log.d("Service UUID: \(configuration.serviceID)")
        let serviceId = CBUUID(string: configuration.serviceID)
        let advertisingData = [
            CBAdvertisementDataServiceUUIDsKey: [serviceId]
        ]
        let notifyCharacteristicId = CBUUID(string: configuration.notifyCharacteristicID)
        let writeCharacteristicId = CBUUID(string: configuration.writeCharacteristicID)
        state = Opening(
            socket: self,
            advertisingData: advertisingData,
            serviceId: serviceId,
            notifyCharacteristicId: notifyCharacteristicId,
            writeCharacteristicId: writeCharacteristicId)
    }

    func close() {
        state = Idle(socket: self)
    }

    func send(_ data: Data) {
        guard let connected = state as? Connected else {
            log.w("Can't send data, not connected")
            executer.after(0) {
                self.delegate?.socketDidFailToSend(self, error: SocketError.notConnected)
            }
            return
        }
        state = Sending(socket: self, notifyCharacteristic: connected.notifyCharacteristic, writeCharacteristic: connected.writeCharacteristic, central: connected.central, data: data)
    }
}
