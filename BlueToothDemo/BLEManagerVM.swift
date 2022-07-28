//
//  BLEManagerVM.swift
//  BlueToothDemo
//
//  Created by Ling on 2021/12/7.
//

/**
 * 說明
 * CBCentralManager: 藍牙的控制中心，此類別主要用於對外部設備進行搜尋、發現以及連接 CBPeripheral 設備。
 * CBPeripheral: 此類別代表每一個外部藍牙設備，在 ios中一個外部藍芽設備代表一個CBPeripheral對象，
 *               通過對應的外部藍牙設備獲取RSSI(距離)、發送數據以及讀取數據，
 *               且外圍設備由通用唯一標識符(UUID)表示為NSUUID對象，可能包含一項或多項服務特徵(CBCharacteristic)。
 * CBCharacteristic: 每個對應serviceUUID(服務UUID)的特徵，含包寫入、讀取、設定通知
 **/

import Foundation
import CoreBluetooth


/*
 * ViewModel
 */
class BLEManagerVM: NSObject, ObservableObject {

    /* Battery 藍芽設備 */
    public static let serviceUUID: CBUUID           = CBUUID.init(string: "00001523-1212-EFDE-1523-785FEABCD123")
    public static let notifyBtnUUID: CBUUID         = CBUUID.init(string: "00001524-1212-EFDE-1523-785FEABCD123")
    public static let notifyLedUUID: CBUUID         = CBUUID.init(string: "00001525-1212-EFDE-1523-785FEABCD123")
    public static let notifyResistorUUID: CBUUID    = CBUUID.init(string: "00001526-1212-EFDE-1523-785FEABCD123")
    
    public static let batteryServiceUUID: CBUUID    = CBUUID.init(string: "0000180F-0000-1000-8000-00805F9B34FB")
    public static let batteryUUID: CBUUID           = CBUUID.init(string: "00002A19-0000-1000-8000-00805F9B34FB")
    
    public static let descNotifyUUID:CBUUID         = CBUUID.init(string: "00002902-0000-1000-8000-00805F9B34FB")
    
    private var centralManager: CBCentralManager!
    private var basePeripheral: CBPeripheral!
    
    private var batteryCharacteristic: CBCharacteristic?
    private var btnCharacteristic: CBCharacteristic?
    private var ledCharacteristic: CBCharacteristic?
    private var resistorCharacteristic: CBCharacteristic?
    
    @Published var isSwitchedOn = false
    @Published var devises: [Devise] = []
    @Published var selectedDevise: Devise?
    @Published var battery: Int = 0
    @Published var led: String = "0x01"
    @Published var btnWords: String?
    @Published var resistorQueue = ResistorQueue<Double>()

    override init() {
        super.init()
        // queue: 可以是 background run ，又或者 nil
        centralManager = CBCentralManager(delegate: self, queue: nil)
//        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.global(qos: .background))
        centralManager.delegate = self
    }

    // 開始掃描設備
    func startScanning() {
        // print("startScanning...")
        devises.removeAll()
        centralManager.scanForPeripherals(withServices: nil, options: nil)
        // 指定
//        centralManager.scanForPeripherals(withServices: [BLEManagerVM.serviceUUID, BLEManagerVM.batteryServiceUUID], options: nil)
        
        // 3秒後停止掃描
        DispatchQueue.global().asyncAfter(deadline: .now()+3) {
            print("auto stopScanning...")
            self.stopScanning()
        }
        
    }
    // 停止掃描設備
    func stopScanning() {
        // print("stopScanning...")
        centralManager.stopScan()
    }

    // 連線
    func connect(peripheral: CBPeripheral) {
        // print("Connecting to  device...")
        self.stopScanning()
        self.basePeripheral = peripheral
        peripheral.delegate = self // 放在 init 會有問題
        centralManager.connect(self.basePeripheral, options: nil)
    }

    // 斷開設備
    func disconnect() {
        // print("disconnect...")
        centralManager.cancelPeripheralConnection(self.basePeripheral)
    }
    
    // 寫入資料
    func witeValueForCharacteristic(ledData: String) {
        print("witeValueForCharacteristic...")
        
        // 這邊做轉換，都會有問題，所以直接寫入data值就好
        // let hex = data.data(using: .utf8)!
        // let binary = String(data: Data(bytes: data.hexaToBytes), encoding: .utf8)
        // let trData = Data(bytes: data.hexaToBytes)
        // let sendData = trData.hexEncodedString().hexaToBinary.data(using: .utf8)!

        var sendData: Data = Data()

        if ledData == "0x01" {
            sendData.append(0x01) // 開
            self.led = "0x00"
        }else {
            sendData.append(0x00) // 關
            self.led = "0x01"
        }

        if self.basePeripheral == nil { return }
        if self.ledCharacteristic == nil { return }
        
        if ledCharacteristic!.uuid == BLEManagerVM.notifyLedUUID {
            self.basePeripheral.writeValue(sendData, for: ledCharacteristic!, type: .withResponse)
        }
    }
    
    // 寫入資料手動區(尚未寫完)12/27
    func witeValueForCharacteristic(data: String, delay: Double, loop: Int) {
        
        // 整理資料
        // data 會是 一連串16進位的數字 或是字串(會將轉譯為 16進位數字傳過去)，兩個則都轉為 uint8 傳進去
        
        if self.basePeripheral == nil { return }
        if self.ledCharacteristic == nil { return }
        
        // let hexString = String(hexadecimal: data) // 將字串轉為 16進位字串 轉為 16進位
        let sendData = data.data(using: .utf8)
        
        if self.basePeripheral == nil { return }
        if self.ledCharacteristic == nil { return }
        
        let when = DispatchTime.now() + delay // 延遲時間
        DispatchQueue.main.asyncAfter(deadline: when) { [self] in
            for i in 0..<loop {
                if ledCharacteristic!.uuid == BLEManagerVM.notifyLedUUID {
                    self.basePeripheral.writeValue(sendData!, for: ledCharacteristic!, type: .withResponse)
                }
            }
        }
        
//        if ledCharacteristic!.uuid == BLEManagerVM.notifyLedUUID {
//            self.basePeripheral.writeValue(sendData, for: ledCharacteristic!, type: .withResponse)
//        }
    }

    // 加入要發現的服務
    private func discoverServices() {
        // print("discoverServices...")
        basePeripheral.discoverServices([BLEManagerVM.serviceUUID, BLEManagerVM.batteryServiceUUID])
    }
    
    // 加入要尋找的相關特徵
    private func discoverCharacteristicsForService(_ service: CBService) {
        // print("discoverCharacteristicsForBlinkyService...")
        
        if service.uuid == BLEManagerVM.serviceUUID {
            basePeripheral.discoverCharacteristics([
                BLEManagerVM.notifyBtnUUID,
                BLEManagerVM.notifyLedUUID,
                BLEManagerVM.notifyResistorUUID
            ], for: service)
        }else if service.uuid == BLEManagerVM.batteryServiceUUID {
            basePeripheral.discoverCharacteristics([BLEManagerVM.batteryUUID], for: service)
        }
    }

}


extension BLEManagerVM: CBCentralManagerDelegate {
    
    /** 偵測是否藍芽有開啟 */
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            self.isSwitchedOn = true
        }else {
            self.isSwitchedOn = false
        }
    }

    /** 發現符合要求的外設 */
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // print("centralManager didDiscover ...")
        
        if peripheral.name != nil {
            devises.append(Devise(rssi: RSSI.intValue, peripheral: peripheral))
        }
        
        // 直接連線
//        self.basePeripheral = peripheral
//        self.connect(peripheral: peripheral)
        
        // 根據名稱過濾
//        if peripheral.name?.hasPrefix("BB")! {
//            self.connect(peripheral: peripheral)
//        }
    }

    /** 連接成功 */
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("centralManager didConnect ...")
        if peripheral == basePeripheral {
            // 連線成功，加入要尋找的服務
            discoverServices()
        }
    }
    
    /** 連接失敗的回調 */
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("連接失敗")
    }

    /** 斷開連接 (還沒實作介面)*/
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("斷開連接")
        // 重新連線(這個可以製作成 自動連線)
//        central.connect(peripheral, options: nil)
    }
    
    
    
}

extension BLEManagerVM: CBPeripheralDelegate {
    
    /** 發現有哪些服務 */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services, services.count > 0 else { return }
        print("didDiscoverServices...")
        for service in services {
            if service.uuid == BLEManagerVM.batteryServiceUUID {
                // 發現服務後，就要去設定要尋找的特稱
                discoverCharacteristicsForService(service)
            }else if  service.uuid == BLEManagerVM.serviceUUID {
                // 發現服務後，就要去設定要尋找的特稱
                discoverCharacteristicsForService(service)
            }
        }
    } // end func

    /** 發現特徵(不管今天這個特徵是寫入還是獲取通知，都要在這裡被指定才能有後續的功能) */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("didDiscoverCharacteristicsFor...")
        
        // Check if characteristics found for service.
//        guard let characteristics = service.characteristics, error == nil else {
//            print("error: \(String(describing: error))")
//            return
//        }
        
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                print("特徵: \(characteristic.uuid)")
                
                /* 電池 */
                if characteristic.uuid == BLEManagerVM.batteryUUID {
                    self.batteryCharacteristic = characteristic
                    // 讀取特徵裏的數據
                    peripheral.readValue(for: self.batteryCharacteristic!)
                    // 訂閱
                    peripheral.setNotifyValue(true, for: self.batteryCharacteristic!)
                }
                
                // 待解決 Error Domain=CBATTErrorDomain Code=10 "The attribute could not be found."
                /* 按鈕 */
                if characteristic.uuid == BLEManagerVM.notifyBtnUUID { // 按鈕
                    self.btnCharacteristic = characteristic
                    peripheral.readValue(for: self.btnCharacteristic!)
                    peripheral.setNotifyValue(true, for: self.btnCharacteristic!)
                }

                /* 可變電阻 */
                if characteristic.uuid == BLEManagerVM.notifyResistorUUID {
                    self.resistorCharacteristic = characteristic
                    peripheral.readValue(for: self.resistorCharacteristic!)
                    peripheral.setNotifyValue(true, for: self.resistorCharacteristic!)
                    
                }
                
                /* LED */
                if characteristic.uuid == BLEManagerVM.notifyLedUUID {
                    self.ledCharacteristic = characteristic
                    peripheral.readValue(for: self.ledCharacteristic!)
                }
            } // end for loop characteristics
        } // end if characteristics
    } // end func

    /** 寫入資料狀態(當執行某個 characteristic 寫入動作時，會進來這裡) */
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        print("didWriteValueFor...")
        if error != nil {
            print("寫入資料錯誤: \(error!)")
        }else {
            print("寫入資料成功")
        }
    } // end func

    /** 訂閱狀態 */
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        // 當訂閱的狀態發生改變的時候
        guard error == nil else {
            print("讀取資料錯誤: \(self), \(#function)")
            print(error!)
            return
        }
        
        if characteristic.isNotifying {
            print("訂閱成功")
        } else {
            print("取消訂閱")
        }
        
//        guard let data = characteristic.value as NSData?,
//        let str = String(data: data as Data, encoding: .utf8) else {
//            print("沒有收到更新資料")
//            return
//        }
//        print(str)
        
        // print(characteristic)
        

//        if characteristic.uuid == ParticlePeripheral.HM11CharacteristicUUID {
//            guard let data = characteristic.value as NSData?,
//                  let str = String(data: data as Data, encoding: .utf8) else {
//                print("沒有資料")
//                return
//            }
//            print("> \(str)")
//        }
    } // end func
    
    /** 接收到數據 */
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        // 收到的資料 有可能會是 nil 哦!
        if let data = characteristic.value {
            if characteristic.uuid == BLEManagerVM.batteryUUID {
                // let battery = Int(data!.hexEncodedString(), radix: 16)
                // data!.hexEncodedString() : data 轉成 16進位
                // Int(value, radix: 16) : 16進位轉成 10進位
                if let value = Int(data.hexEncodedString(), radix: 16) {
                    self.battery = value
                }
            }else if characteristic.uuid == BLEManagerVM.notifyResistorUUID {
                // let battery = Int(data!.hexEncodedString(), radix: 16)
                // data!.hexEncodedString() : data 轉成 16進位
                // Int(value, radix: 16) : 16進位轉成 10進位
                if let value = Int(data.hexEncodedString(), radix: 16) {
                    print("Resistor data: \(value)")
                    // 來源借於 0~255之間，顯示 0~1之間，因為做轉換
                    self.resistorQueue.enqueue(Double(value) / 255)
                    self.resistorQueue.dequeue()
                }
            }else if characteristic.uuid == BLEManagerVM.notifyLedUUID {
//                let str = String(decoding: data, as: UTF8.self)
//                print("LED data: \(str)")
                
                if let value = Int(data.hexEncodedString(), radix: 16) {
                    print("LED data \(value)")
                }
            }else if characteristic.uuid == BLEManagerVM.notifyBtnUUID {
//                let str = String(decoding: data, as: UTF8.self)
//                self.btnWords = str
                
                if let value = Int(data.hexEncodedString(), radix: 16) {
                    self.btnWords = String(value)
                    print("Btn data \(value)")
                }
            }
        }
        
//        print(String.init(data: data!, encoding: String.Encoding.utf8))
    }

}
