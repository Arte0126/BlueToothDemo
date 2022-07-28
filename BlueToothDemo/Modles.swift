//
//  Modles.swift
//  BlueToothDemo
//
//  Created by Ling on 2021/12/7.
//

import Foundation
import CoreBluetooth

/*
 * Model
 */

struct Devise: Identifiable {
    let id = UUID()
    let rssi: Int
    let peripheral: CBPeripheral
}

//class ParticlePeripheral: NSObject {
//    public static let HM11ServiceUUID        = CBUUID(data: Data([0xFF, 0xE0]))
//    public static let HM11CharacteristicUUID = CBUUID(data: Data([0xFF, 0xE1]))
//}

// 這個做法是用堆疊，加入一個新值，刪掉最一開始加入的值這樣
struct ResistorQueue<T> {
    var list = [T]()
    
    mutating func enqueue(_ element: T) {
        list.append(element)
    }
    
    mutating func dequeue() -> T? {
        if !list.isEmpty {
            return list.removeFirst()
        } else {
            return nil
        }
    }
    
    func peek() -> T? {
        if !list.isEmpty {
            return list[0]
        } else {
            return nil
        }
    }
}
