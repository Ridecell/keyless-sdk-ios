//
//  AsyncExecuter.swift
//  CarShare
//
//  Created by Matt Snow on 2019-07-22.
//

import Foundation

protocol AsyncExecuter {
    func after(_ seconds: TimeInterval, execute: @escaping () -> Void)
}

class MainExecuter: AsyncExecuter {
    func after(_ seconds: TimeInterval, execute: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: execute)
    }
}
