//
//  Extension+T.swift
//  BlueToothDemo
//
//  Created by Ling on 2021/12/27.
//

/**
 * 說明: 一些進位轉換的延伸套件
 **/

import Foundation

extension Data {
    // Data 轉 16 進位
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }

    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return self.map { String(format: format, $0) }.joined()
    }
    
    func hexadecimal() -> String {
        return map { String(format: "%02x", $0) }
        .joined(separator: "")
    }
}

// 進位轉換
// 0x02 為 00000010
extension String {
    var hexaToBinary: String {
        return hexaToBytes.map {
            let binary = String($0, radix: 2)
            return repeatElement("0", count: 8-binary.count) + binary
        }.joined()
    }

    var hexaToBytes: [UInt8] {
        var start = startIndex
        return stride(from: 0, to: count, by: 2).compactMap { _ in
            let end = index(after: start)
            defer { start = index(after: end) }
            return UInt8(self[start...end], radix: 16)
        }
    }
    
    
}

// 16進位 字串 互轉
extension String {
    init?(hexadecimal string: String) {
        guard let data = string.hexadecimal() else {
            return nil
        }
        self.init(data: data, encoding: .utf8)
    }
    
    // 只能接收 0-9a-f
    func hexadecimal() -> Data? {
        var data = Data(capacity: self.count / 2)
        
        let regex = try! NSRegularExpression(pattern: "[0-9a-f]{1,2}", options: .caseInsensitive)
        regex.enumerateMatches(in: self, options: [], range: NSMakeRange(0, self.count)) { match, flags, stop in
            let byteString = (self as NSString).substring(with: match!.range)
            var num = UInt8(byteString, radix: 16)!
            data.append(&num, count: 1)
        }
        
        guard data.count > 0 else {
            return nil
        }
        
        return data
    }
    
    func hexadecimalString() -> String? {
        return data(using: .utf8)? .hexadecimal()
    }
}

// 16進位字串 互轉 字串 演示
//let hexString = "68656c6c6f2c20776f726c64"
//print(String(hexadecimal: hexString))
//let originalString = "hello, world"
//print(originalString.hexadecimalString())
