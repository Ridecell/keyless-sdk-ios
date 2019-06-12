//
//  TLSBeaconClient.swift
//  CarShare
//
//  Created by Matt Snow on 2019-06-12.
//  Copyright © 2019 BSM Technologies Inc. All rights reserved.
//

import CoreBluetooth
import CoreLocation
import RxSwift
import Security

class TLSBeaconClient: NSObject {

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
        case advertising(context: SSLContext, peripheral: CBPeripheralManager)
        case requestedWrite(context: SSLContext, peripheral: CBPeripheralManager, requests: [CBATTRequest])
        case requestedRead(context: SSLContext, peripheral: CBPeripheralManager, request: CBATTRequest)
    }

    private let peripheralQueue = DispatchQueue(label: "BeaconClient_PeripheralQueue")
    private let mainQueue = DispatchQueue.main
    private var state = State.idle

    func startAdvertising(in region: CLBeaconRegion, localName: String, serviceId: String, characteristicId: String) -> Single<CBPeripheralManager> {
        return Single.create { observer in

            let peripheral = CBPeripheralManager(delegate: self, queue: self.peripheralQueue)

            self.state = .initializing(
                context: PeripheralContext(
                    region: region,
                    peripheral: peripheral,
                    advertisingData: [
                        CBAdvertisementDataServiceUUIDsKey: [CBUUID(string: serviceId)]
                    ],
                    serviceId: serviceId,
                    characteristicId: characteristicId),
                observer: observer)
            self.peripheralManagerDidUpdateState(peripheral)
            return Disposables.create()
        }
    }

    func stopAdvertising() {
        guard case let .advertising(_, peripheral) = state else {
            return
        }
        state = .idle
        peripheral.stopAdvertising()
    }

    private func generateContext() -> SSLContext {
        guard let context = SSLCreateContext(nil, .serverSide, .streamType) else {
            log.error("no context")
            fatalError()
        }

        SSLSetIOFuncs(context, TLSBeaconClient.handleWriteRequest, TLSBeaconClient.handleReadRequest)
        let connection = Unmanaged<TLSBeaconClient>.passUnretained(self).toOpaque()

        SSLSetConnection(context, connection)

        SecIdentityRef
        SSLSetCertificate(context, [])

        return context
    }

    private static var handleWriteRequest: SSLReadFunc = { connection, bytesPointer, length in
        let tlsClient: TLSBeaconClient = Unmanaged<TLSBeaconClient>.fromOpaque(connection).takeUnretainedValue()
        guard case let .requestedWrite(context, peripheral, requests) = tlsClient.state, let data = requests.first?.value else {
            return 0
        }
        data.withUnsafeBytes {
            guard let pointer = $0.baseAddress else {
                return
            }
            bytesPointer.copyMemory(from: pointer, byteCount: data.count)
            length.initialize(to: data.count)
        }
        tlsClient.state = .advertising(context: context, peripheral: peripheral)
        return 0
    }

    private static var handleReadRequest: SSLWriteFunc = { connection, bytesPointer, length in
        let tlsClient: TLSBeaconClient = Unmanaged<TLSBeaconClient>.fromOpaque(connection).takeUnretainedValue()
        guard case let .requestedRead(context, peripheral, request) = tlsClient.state else {
            return 0
        }
        let data = Data(bytes: bytesPointer, count: length.pointee)
        request.value = data
        tlsClient.state = .advertising(context: context, peripheral: peripheral)
        peripheral.respond(to: request, withResult: .success)
        return 0
    }
}

extension TLSBeaconClient: CBPeripheralManagerDelegate {
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

//        state = .advertising(context: context, peripheral: peripheral)
        observer(.success(peripheral))
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didOpen channel: CBL2CAPChannel?, error: Error?) {
        log.info("didOpen")
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {

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
