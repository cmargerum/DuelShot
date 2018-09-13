//
//  PlayerState.swift
//  DuelShot
//
//  Created by Cole Margerum on 8/29/18.
//  Copyright © 2018 Cole Margerum. All rights reserved.
//

import Foundation

struct PlayerState: DataConvertible {
    let x: Double
    let y: Double
    let isFiring: Bool
    let isHit: Bool
    
    init(x: Double, y: Double, isFiring: Bool, isHit: Bool) {
        self.x = x
        self.y = y
        self.isFiring = isFiring
        self.isHit = isHit
    }
}

protocol DataConvertible {
    init?(data: Data)
    var data: Data { get }
}

extension DataConvertible {
    init?(data: Data) {
        guard data.count == MemoryLayout<Self>.stride else { return nil }
        self = data.withUnsafeBytes { $0.pointee }
    }
    var data: Data {
        var value = self
        return Data(buffer: UnsafeBufferPointer(start: &value, count: 1))
    }
}
