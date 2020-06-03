//
//  SocketState.swift
//  Keyless
//
//  Created by Matt Snow on 2020-03-30.
//

import CoreBluetooth

protocol SocketState: CBPeripheralManagerDelegate {
    func transition()
}
