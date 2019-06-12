//
//  TLSClient.swift
//  CarShare
//
//  Created by Matt Snow on 2019-06-10.
//  Copyright © 2019 BSM Technologies Inc. All rights reserved.
//

import CoreBluetooth
import RxSwift
import Security

@available(iOS 12.0, *)
class TLSBluetoothClient {
    private let client: BluetoothClient
    private let certificateValidator: CertificateValidator
    private let readQueue = DispatchQueue(label: "ReadQueue")
    private let mainQueue = DispatchQueue.main

    private var state: State = .idle

    private enum State {
        case idle
        case connected(context: SSLContext, characteristic: CBCharacteristic)
    }

    init(client: BluetoothClient, certificateValidator: CertificateValidator) {
        self.client = client
        self.certificateValidator = certificateValidator
    }

    func scan(serviceId: String) -> Observable<(peripheral: CBPeripheral, advertisementData: [String: Any])> {
        return client.scan(serviceId: serviceId)
    }

    func stopScan() -> Completable {
        return client.stopScan()
    }

    func connect(to peripheral: CBPeripheral, serviceId: String, characteristicId: String) -> Single<CBCharacteristic> {
        return self.client.connect(to: peripheral)
            .flatMap { peripheral in
                self.client.find(serviceId: serviceId, for: peripheral)
            }
            .flatMap { service in
                self.client.find(characteristicId: characteristicId, for: service)
            }
            .flatMap { characteristic in
                self.handshake(on: characteristic)
                    .andThen(Single.just(characteristic))
            }
    }

    private func handshake(on characteristic: CBCharacteristic) -> Completable {
        return Completable.create { observer in
            guard let context = SSLCreateContext(nil, .clientSide, .streamType) else {
                log.error("no context")
                observer(.completed)
                return Disposables.create()
            }
            self.state = .connected(context: context, characteristic: characteristic)

            SSLSetIOFuncs(context, TLSBluetoothClient.read, TLSBluetoothClient.write)
            let connection = Unmanaged<TLSBluetoothClient>.passUnretained(self).toOpaque()

            SSLSetConnection(context, connection)
            SSLSetSessionOption(context, .breakOnServerAuth, true)

            var secTrust: SecTrust?
            var handshakeStatus: OSStatus = 0

            repeat {
                handshakeStatus = SSLHandshake(context)
                if handshakeStatus == errSSLPeerAuthCompleted {
                    SSLCopyPeerTrust(context, &secTrust)
                    if let trust = secTrust {
                        // 0 always garunteed to exist
                        let cert = SecTrustGetCertificateAtIndex(trust, 0)!
                        if !self.certificateValidator.validate(cert) {
                            log.error("I don't trust this certificate")
                            handshakeStatus = errSSLBadCert
                        } else {
                            handshakeStatus = 0
                        }
                    }
                }
            } while handshakeStatus == errSSLWouldBlock

            if handshakeStatus == 0 {
                log.info("ok")
            } else {
                log.error("woops \(handshakeStatus)")
            }
            observer(.completed)
            return Disposables.create()
        }
    }

    func read(from characteristic: CBCharacteristic) -> Single<Data> {
        return Single.create { observer in
            guard case let .connected(context, _) = self.state else {
                log.error("Not connected. This should be an error")
                observer(.success(Data()))
                return Disposables.create()
            }
            let bytesPointer = UnsafeMutableRawPointer.allocate(byteCount: 1_000_000, alignment: 0)
            let processedPointer = UnsafeMutablePointer<Int>.allocate(capacity: 1)
            let readStatus = SSLRead(context, bytesPointer, 1_000_000, processedPointer)
            if readStatus == 0 {
                log.info("read ok")
            } else {
                log.error("woops on read \(readStatus)")
            }
            observer(.success(Data(bytes: bytesPointer, count: processedPointer.pointee)))
            return Disposables.create()
        }
    }

    func write(_ data: Data, to characteristic: CBCharacteristic) -> Completable {
        return Completable.create { observer in
            guard case let .connected(context, _) = self.state else {
                log.error("Not connected. This should be an error")
                observer(.completed)
                return Disposables.create()
            }
            let writeStatus = data.withUnsafeBytes { (buffer: UnsafeRawBufferPointer) -> Bool in
                guard let pointer = buffer.baseAddress else {
                    return false
                }
                let processedPointer = UnsafeMutablePointer<Int>.allocate(capacity: 1)

                let writeStatus = SSLWrite(context, pointer, data.count, processedPointer)
                return writeStatus == 0
            }
            if writeStatus {
                log.info("write ok")
            } else {
                log.error("woops on write")
            }
            observer(.completed)
            return Disposables.create()
        }
    }

    private static var read: SSLReadFunc = { connection, bytesPointer, length in
        let semaphore = DispatchSemaphore(value: 0)
        let tlsClient = Unmanaged<TLSBluetoothClient>.fromOpaque(connection).takeUnretainedValue()
        guard case let .connected(_, characteristic) = tlsClient.state else {
            return 0
        }
        _ = tlsClient.client.read(characteristic)
            .subscribe(onSuccess: { data in
                defer {
                    semaphore.signal()
                }
                guard let data = data else {
                    return
                }
                data.withUnsafeBytes {
                    guard let pointer = $0.baseAddress else {
                        return
                    }
                    bytesPointer.copyMemory(from: pointer, byteCount: data.count)
                    length.initialize(to: data.count)
                }
            })
        semaphore.wait()
        return 0
    }

    private static var write: SSLWriteFunc = { connection, bytesPointer, length in
        let semaphore = DispatchSemaphore(value: 0)
        let tlsClient = Unmanaged<TLSBluetoothClient>.fromOpaque(connection).takeUnretainedValue()
        guard case let .connected(_, characteristic) = tlsClient.state else {
            return 0
        }
        let data = Data(bytes: bytesPointer, count: length.pointee)

        _ = tlsClient.client.write(data: data, to: characteristic)
            .subscribe(onCompleted: {
                semaphore.signal()
            })
        semaphore.wait()
        return 0
    }

}
