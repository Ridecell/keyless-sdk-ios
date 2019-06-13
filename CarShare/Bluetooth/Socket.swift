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

    func write(_ data: Data)

    func close()
}

extension Socket {
    func write(_ data: Data, into outputStream: OutputStream) {
        let _ = data.withUnsafeBytes { (rawBufferPointer: UnsafeRawBufferPointer) -> Bool in
            guard let pointer = rawBufferPointer.bindMemory(to: UInt8.self).baseAddress else {
                return false
            }
            outputStream.write(pointer, maxLength: data.count)
            return true
        }
    }
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
                let bufLength = 1024
                let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufLength)
                let bytesRead = iStream.read(buffer, maxLength: bufLength)
                print("bytesRead = \(bytesRead)")
                let data = Data(bytes: buffer, count: bytesRead)
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

    func socketDidClose(_ socket: Socket)
}

