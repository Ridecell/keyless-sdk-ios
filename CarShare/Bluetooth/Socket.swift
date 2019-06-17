//
//  SocketDelegate.swift
//  CarShare
//
//  Created by Matt Snow on 2019-06-13.
//  Copyright © 2019 BSM Technologies Inc. All rights reserved.
//

import Foundation

protocol Socket: AnyObject {

    var socketDelegate: SocketDelegate? { get }

    func write(_ data: Data) -> Bool

    func close()
}

extension Socket {
    func write(_ data: Data, into outputStream: OutputStream) -> Bool {
        print(data.count)
        let lengthBytes = [UInt8((data.count >> 8)&0xFF), UInt8(0xFF&data.count)]
        let toSend: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer.allocate(capacity: data.count+2)
        dump(Data(bytes: lengthBytes, count: 2))


//        outputStream.write(lengthBytes, maxLength: 2)

        toSend.initialize(from: lengthBytes, count: 2)
        data.copyBytes(to: toSend.advanced(by: 2), count: data.count)

        return outputStream.write(toSend, maxLength: data.count+2) > 0

//        return toSend.withUnsafeBytes { (rawBufferPointer: UnsafeRawBufferPointer) -> Bool in
//            guard let pointer = rawBufferPointer.bindMemory(to: UInt8.self).baseAddress else {
//                return false
//            }

//            let data = [UInt8((data.count >> 8)&0xFF), UInt8(0xFF&data.count)
//            let status = outputStream.write(pointer, maxLength: data.count)
//            log.verbose(status)
//            return status > 0
//        }
    }
}

struct Blob {
    let totalBlobBytes: UInt8

}

extension Socket {
    func handleStream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case Stream.Event.openCompleted:
            print("Stream is open")
        case Stream.Event.endEncountered:
            print("End Encountered")
            close()
            socketDelegate?.socketDidClose(self)
        case Stream.Event.hasBytesAvailable:
            print("Bytes are available")
            if let iStream = aStream as? InputStream {
                let bufferLength = UnsafeMutablePointer<UInt8>.allocate(capacity: 2)
                iStream.read(bufferLength, maxLength: 2)
                let count = Int(bufferLength[0]) << 8 + Int(bufferLength[1])
                print("Need to read \(count) bytes")
                let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: count)

                var bytesRead = 0
                repeat {
                    bytesRead += iStream.read(buffer.advanced(by: bytesRead), maxLength: count - bytesRead)
                    print("bytesRead = \(bytesRead)")
                } while count > bytesRead
                let data = Data(bytes: buffer, count: count)
                socketDelegate?.socket(self, didRead: data)
                print("Received data: \(data)")
            }
        case Stream.Event.hasSpaceAvailable:
            print("Space is available")
        case Stream.Event.errorOccurred:
            print("Stream error")
        default:
            print("Unknown stream event")
        }
    }
}

protocol SocketDelegate: AnyObject {
    func socket(_ socket: Socket, didRead data: Data)

    func socketDidOpen(_ socket: Socket)

    func socketDidClose(_ socket: Socket)
}

