import Foundation
import CryptoKit

extension String {
  enum ExtendedEncoding {
    case hexadecimal
  }
  
  var data: Data { .init(utf8) }
  var bytes: [UInt8] { .init(utf8) }

  func data(using encoding:ExtendedEncoding) -> Data {
    let hexStr = self.dropFirst(self.hasPrefix("0x") ? 2 : 0)
    var newData = Data(capacity: hexStr.count/2)
    
    var indexIsEven = true
    for i in hexStr.indices {
      if indexIsEven {
        let byteRange = i...hexStr.index(after: i)
        let byte = UInt8(hexStr[byteRange], radix: 16)!
        newData.append(byte)
      }
      indexIsEven.toggle()
    }
    return newData
  }

  var md5: Insecure.MD5 {
    var md5 = Insecure.MD5()
    md5.update(data: self.data)
    return md5
  }
  var md5hash: Insecure.MD5Digest { Insecure.MD5.hash(data: self.data) }
  var md5hex: String { self.md5hash.hex }
}

extension Data {
  var string: String? { String(bytes: Array(self), encoding: .utf8) }
  var bytes: [UInt8] { .init(self) }
  var md5: Insecure.MD5 {
    var md5 = Insecure.MD5()
    md5.update(data: self)
    return md5
  }
  var md5hash: Insecure.MD5Digest { Insecure.MD5.hash(data: self) }
  var hex: String { self.map { String(format: "%02hhx", $0) }.joined() }
  
  func readUInt32(offset: Int) -> UInt32 {
    let length = offset + MemoryLayout<UInt32>.size
    let subdata = self.subdata(in: offset..<length)
    return UInt32(bigEndian: subdata.withUnsafeBytes { $0.load(as: UInt32.self) })
  }
}

extension Insecure.MD5Digest {
  var data: Data { Data(self) }
  var hex: String { self.map { String(format: "%02hhx", $0) }.joined() }
}

extension UInt16 {
  var data: Data {
    var int = self
    return Data(bytes: &int, count: MemoryLayout<UInt16>.size)
  }
}

extension UInt32 {
  var data: Data {
    var int = self
    return Data(bytes: &int, count: MemoryLayout<UInt32>.size)
  }
}
