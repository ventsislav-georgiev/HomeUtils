import Foundation
import Network

private func setupConnReceive(_ conn: NWConnection, _ device: MiioDevice, _ callback: @escaping (_ device: MiioDevice, _ res: Data, _ decrypted: String?) -> Void) {
  var data: Data = Data()

  func onData(chunk: Data?, context: NWConnection.ContentContext?, completed: Bool, error: NWError?) {
    guard let chunk = chunk else {
      return
    }
    
    guard !chunk.isEmpty else {
      debugPrint("Empty chunk")
      return
    }

    receive()
    debugPrint("Connection did receive, chunk: \(chunk) string: \(chunk.string ?? "-" )")
    data += chunk

    if completed {
      debugPrint("Connection did end")
      
      let encrypted = data.subdata(in: 32..<data.count)
      let decrypted = device.crypto.decrypt(encrypted)
      if decrypted != nil {
        debugPrint("Connection did receive, string: \(decrypted!)")
      } else {
        debugPrint("Decryption failed")
      }
      
      callback(device, data, decrypted)
    } else if error != nil {
      debugPrint("Connection did fail, error: \(error!)")
    }
  }
  
  func receive() {
    data = Data()
    conn.receive(minimumIncompleteLength: 1, maximumLength: 65536, completion: onData)
  }

  receive()
}

private let handshakePacket = { () -> Data in
  var packet = [UInt8](repeating: 0, count: 32)
  packet[0] = 0x21
  packet[1] = 0x31
  packet[3] = 0x20
  for index in 4..<32 {
    packet[index] = 0xff
  }
  return Data(packet)
}()

private func miioAES(_ token: String) -> AES {
  let tokenData = token.data(using: .hexadecimal)
  let key = tokenData.md5hash.data
  let iv = (key + tokenData).md5hash.data
  return AES(key, iv)
}

private func getPacket(_ device: MiioDevice, _ msg: String) -> Data? {
  var packet = [UInt8](repeating: 0, count: 32)
  packet[0] = 0x21
  packet[1] = 0x31
  packet[3] = 0x20
  for index in 4..<8 {
    packet[index] = 0x00
  }
  
  let deviceId = device.id.data
  packet[8] = deviceId[3]
  packet[9] = deviceId[2]
  packet[10] = deviceId[1]
  packet[11] = deviceId[0]
  
  let timeNow = timestampNow()
  let deviceTimestamp = (timeNow - device.serverTimestamp + device.timestamp).data
  packet[12] = deviceTimestamp[3]
  packet[13] = deviceTimestamp[2]
  packet[14] = deviceTimestamp[1]
  packet[15] = deviceTimestamp[0]
  
  guard let encrypted = device.crypto.encrypt(msg) else {
    return nil
  }
  
  let msgLength = UInt16(encrypted.count + 32).data
  packet[2] = msgLength[1]
  packet[3] = msgLength[0]
  
  let msgData = Data(packet).subdata(in: 0..<16) + device.token.data(using: .hexadecimal) + encrypted
  let checksum = msgData.md5hash.data
  for index in 16..<32 {
    packet[index] = checksum[index - 16]
  }
  
  debugPrint("Encrypted \(encrypted.bytes)")
  return Data(packet) + encrypted
}

private var msgId = Int.random(in: 1..<10000)

class MiioDevice {
  var id: UInt32 = 0
  var token: String = ""
  var timestamp: UInt32 = 0
  var serverTimestamp: UInt32 = 0
  var crypto: AES! = nil
}

class Miio {
  private let port: UInt16 = 54321
  private let host: String
  private var conn: NWConnection! = nil
  private var device: MiioDevice
  
  init(_ token: String, _ host: String) {
    self.host = host
    self.device = MiioDevice()
    self.device.token = token
    self.device.crypto = miioAES(token)
    self.setupConnection()
  }

  func setupConnection(_ responseHandler: ((_ msg: String) -> Void)? = nil) {
    if self.conn != nil {
      self.conn.forceCancel()
      self.conn = nil
    }

    self.conn = getConnection(host: self.host, port: self.port, using: .udp)

    func callback(device: MiioDevice, res: Data, decrypted: String?) {
      device.id = res.readUInt32(offset: 8)
      device.timestamp = res.readUInt32(offset: 12)
      device.serverTimestamp = timestampNow()
      
      if decrypted != nil && responseHandler != nil {
        responseHandler!(decrypted!)
      }
    }

    setupConnReceive(conn, self.device, callback)
  }
  
  private func handshake() {
    sendConnData(conn: self.conn, data: handshakePacket)
  }

  func send(_ method: String, _ params: [Any] = [], _ responseHandler: @escaping (_ msg: String) -> Void) {
    self.setupConnection(responseHandler)
    
    func _send() {
      if msgId == 10000 { msgId = 0 }
      msgId += 1

      var msg = [String: Any].init()
      msg["id"] = msgId
      msg["method"] = method
      msg["params"] = params
  
      guard let json = stringifyJSON(msg) else {
        debugPrint("Failed to stringify message for \(method)")
        return
      }
      
      guard let packet = getPacket(self.device, json) else {
        debugPrint("Failed to create packet")
        return
      }
      
      debugPrint("Sending \(packet.bytes)")
      sendConnData(conn: self.conn, data: packet)
    }

    if timestampNow() - self.device.serverTimestamp > 120 {
      self.handshake()
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { _send() }
    } else {
      _send()
    }
  }
}
