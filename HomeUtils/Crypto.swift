import Foundation
import CommonCrypto

private func aesCrypt(key: Data, iv: Data, data: Data?, option: CCOperation) -> Data? {
  guard let data = data else { return nil }
  
  let cryptLength = data.count + kCCBlockSizeAES128
  var cryptData   = Data(count: cryptLength)
  
  let keyLength = key.count
  let options   = CCOptions(kCCOptionPKCS7Padding)
  
  var bytesLength = Int(0)
  
  let status = cryptData.withUnsafeMutableBytes { cryptBytes in
    data.withUnsafeBytes { dataBytes in
      iv.withUnsafeBytes { ivBytes in
        key.withUnsafeBytes { keyBytes in
          CCCrypt(option, CCAlgorithm(kCCAlgorithmAES), options, keyBytes.baseAddress, keyLength, ivBytes.baseAddress, dataBytes.baseAddress, data.count, cryptBytes.baseAddress, cryptLength, &bytesLength)
        }
      }
    }
  }
  
  guard UInt32(status) == UInt32(kCCSuccess) else {
    debugPrint("Failed to crypt data. Status \(status)")
    return nil
  }
  
  cryptData.removeSubrange(bytesLength..<cryptData.count)
  return cryptData
}

func aesEncrypt(key: Data, iv: Data, string: String) -> Data? {
  return aesCrypt(key: key, iv: iv, data: string.data, option: CCOperation(kCCEncrypt))
}

func aesDecrypt(key: Data, iv: Data, data: Data?) -> String? {
  let result = aesCrypt(key: key, iv: iv, data: data, option: CCOperation(kCCDecrypt))
  guard let decryptedData = result else { return nil }
  return decryptedData.string
}

struct AES {
  private let key: Data
  private let iv: Data
  
  init(_ key: Data, _ iv: Data) {
    self.key = key
    self.iv = iv
  }

  func encrypt(_ string: String) -> Data? { aesEncrypt(key: self.key, iv: self.iv, string: string) }
  func decrypt(_ data: Data?) -> String? { return aesDecrypt(key: self.key, iv: self.iv, data: data) }
}
