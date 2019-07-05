//
//  TLSSocket.swift
//  CarShare
//
//  Created by Matt Snow on 2019-06-11.
//  Copyright © 2019 BSM Technologies Inc. All rights reserved.
//

import Foundation
import Security

func getCNforSSL(at url: URL, port: UInt16) -> String? {
    var socketfd = Darwin.socket(AF_INET, SOCK_STREAM, IPPROTO_TCP)

    guard let ip = urlToIP(url) else {
        NSLog("Could not get IP from URL \(url)")
        return nil
    }

    let inAddr = in_addr(s_addr: inet_addr(ip))

    var addr = sockaddr_in(sin_len: __uint8_t(MemoryLayout<sockaddr_in>.size),
                           sin_family: sa_family_t(AF_INET),
                           sin_port: CFSwapInt16(port),
                           sin_addr: inAddr,
                           sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
    var sock_addr = sockaddr(sa_len: 0,
                             sa_family: 0,
                             sa_data: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
    _ = memcpy(&sock_addr, &addr, MemoryLayout<sockaddr_in>.size)

    guard connect(socketfd, &sock_addr, socklen_t(MemoryLayout<sockaddr_in>.size)) == 0 else {
        NSLog("Failed connection for \(url) port \(port) with error \(Darwin.errno)")
        return nil
    }

    defer {
        if close(socketfd) != 0 {
            NSLog("Error closing socket for \(url) port \(port) with error \(Darwin.errno)")
        }
    }

    guard let sslContext = SSLCreateContext(kCFAllocatorDefault, .clientSide, .streamType) else {
        NSLog("Could not create SSL Context for \(url) port \(port)")
        return nil
    }

    defer {
        SSLClose(sslContext)
    }

    SSLSetIOFuncs(sslContext, sslReadCallback, sslWriteCallback)
    SSLSetConnection(sslContext, &socketfd)
    SSLSetSessionOption(sslContext, .breakOnServerAuth, true)

    var secTrust: SecTrust?
    var status: OSStatus = 0
    var subject: String?
    repeat {
        status = SSLHandshake(sslContext)
        if status == errSSLPeerAuthCompleted {
            SSLCopyPeerTrust(sslContext, &secTrust)
            if let trust = secTrust {
                // 0 always garunteed to exist
                let cert = SecTrustGetCertificateAtIndex(trust, 0)!
                subject = SecCertificateCopySubjectSummary(cert) as String?
            }
        }
    } while status == errSSLWouldBlock

    guard status == errSSLPeerAuthCompleted else {
        NSLog("SSL Handshake Error for \(url) port \(port) OSStatus \(status)")
        return nil
    }

    let data = "abcde".data(using: .utf8)!
    data.withUnsafeBytes { (pointer: UnsafeRawBufferPointer) in
        print("write abcde")
        let processedPointer = UnsafeMutablePointer<Int>.allocate(capacity: 1)
        SSLWrite(sslContext, pointer.baseAddress!, data.count, processedPointer)
        print("written")
    }

    return subject
}

func sslReadCallback(connection: SSLConnectionRef,
                     data: UnsafeMutableRawPointer,
                     dataLength: UnsafeMutablePointer<Int>) -> OSStatus {

    let socketfd = connection.load(as: Int32.self)

    let bytesRequested = dataLength.pointee
    let bytesRead = read(socketfd, data, UnsafePointer<Int>(dataLength).pointee)

    if (bytesRead > 0) {
        dataLength.initialize(to: bytesRead)
        if bytesRequested > bytesRead {
            return Int32(errSSLWouldBlock)
        } else {
            return noErr
        }
    } else if (bytesRead == 0) {
        dataLength.initialize(to: 0)
        return Int32(errSSLClosedGraceful)
    } else {
        dataLength.initialize(to: 0)
        switch (errno) {
        case ENOENT: return Int32(errSSLClosedGraceful)
        case EAGAIN: return Int32(errSSLWouldBlock)
        case ECONNRESET: return Int32(errSSLClosedAbort)
        default: return Int32(errSecIO)
        }
    }
}

func sslWriteCallback(connection: SSLConnectionRef,
                      data: UnsafeRawPointer,
                      dataLength: UnsafeMutablePointer<Int>) -> OSStatus {
    defer {
        print(dataLength.pointee)
    }
    let socketfd = connection.load(as: Int32.self)

    let bytesToWrite = dataLength.pointee
    print(bytesToWrite)
    let bytesWritten = write(socketfd, data, UnsafePointer<Int>(dataLength).pointee)

    if (bytesWritten > 0) {
        dataLength.initialize(to: bytesWritten)
        if (bytesToWrite > bytesWritten) {
            return Int32(errSSLWouldBlock)
        } else {
            return noErr
        }
    } else if (bytesWritten == 0) {
        dataLength.initialize(to: 0)
        return Int32(errSSLClosedGraceful)
    } else {
        dataLength.initialize(to: 0)
        if (EAGAIN == errno) {
            return Int32(errSSLWouldBlock)
        } else {
            return Int32(errSecIO)
        }
    }
}

private func urlToIP(_ url: URL) -> String? {
    guard let hostname = url.host else {
        return nil
    }

    guard let host = hostname.withCString({ gethostbyname($0) }) else {
        return nil
    }

    guard host.pointee.h_length > 0 else {
        return nil
    }

    var addr = in_addr()
    memcpy(&addr.s_addr, host.pointee.h_addr_list[0], Int(host.pointee.h_length))

    guard let remoteIPAsC = inet_ntoa(addr) else {
        return nil
    }

    return String(cString: remoteIPAsC)
}
