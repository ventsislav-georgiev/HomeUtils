import Foundation
import Network

func request(requestURL: String, body: [String: Any]?, callback: @escaping ((Data) -> Void)) {
  let url = URL(string: requestURL)!
  var request = URLRequest(url: url)
  let session = URLSession.shared
  
  request.setValue(
    "application/json",
    forHTTPHeaderField: "Content-Type"
  )
  
  if (body != nil) {
    let bodyData = try? JSONSerialization.data(
      withJSONObject: body as Any,
      options: []
    )
    
    request.httpMethod = "POST"
    request.httpBody = bodyData
  }
  
  let task = session.dataTask(with: request) { (data, response, error) in
    guard error == nil else { return }
    guard let data = data else { return }
    callback(data)
  }
  
  task.resume()
}

func getTCPSocket(host: String, port: UInt16) -> (CFReadStream, CFWriteStream) {
  var readStream: Unmanaged<CFReadStream>?
  var writeStream: Unmanaged<CFWriteStream>?
  
  CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, host as CFString, UInt32(port), &readStream, &writeStream)
  
  let inputStream = readStream!.takeRetainedValue()
  let outputStream = writeStream!.takeRetainedValue()
  
  CFReadStreamScheduleWithRunLoop(inputStream, CFRunLoopGetCurrent(), CFRunLoopMode.commonModes)
  CFWriteStreamScheduleWithRunLoop(outputStream, CFRunLoopGetCurrent(), CFRunLoopMode.commonModes)
  CFReadStreamOpen(inputStream)
  CFWriteStreamOpen(outputStream)
  
  return (inputStream, outputStream)
}

func sendTCPMsg(_ outputStream: CFWriteStream, _ msg: String) {
  let data = msg.data(using: .utf8)!
  
  data.withUnsafeBytes {
    let bufferAddress = $0.baseAddress?.assumingMemoryBound(to: UInt8.self)
    
    if bufferAddress == nil {
      debugPrint("Error sending message")
      return
    }
    
    CFWriteStreamWrite(outputStream, bufferAddress, data.count)
  }
}

func getConnection(host: String, port: UInt16, using: NWParameters) -> NWConnection {
  let host = NWEndpoint.Host(host)
  let port = NWEndpoint.Port(rawValue: port)!
  let connection = NWConnection(host: host, port: port, using: using)
  let queue = DispatchQueue(label: "client connection Q")
  
  connection.stateUpdateHandler = { newState in
    switch (newState) {
    case .ready:
      debugPrint("State: Ready")
      return
    case .setup:
      debugPrint("State: Setup")
    case .cancelled:
      debugPrint("State: Cancelled")
    case .preparing:
      debugPrint("State: Preparing")
    default:
      debugPrint("State: Not defined")
    }
  }
  
  connection.start(queue: queue)
  
  return connection
}

func sendConnData(conn: NWConnection, data: Data?) {
  conn.send(content: data, completion: .contentProcessed( { error in
    if error != nil {
      debugPrint("Error sending message \(error!)")
      return
    }
    debugPrint("Connection did send, data: \(data!) string: \(data!.string ?? "-" )")
  }))
}
