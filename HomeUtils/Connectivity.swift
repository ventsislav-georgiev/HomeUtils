import Foundation
import WatchConnectivity

class Connectivity: NSObject, WCSessionDelegate, ObservableObject {
  let vacuum = Miio("<Vacuum Token Here>", "<Vacuum IP Here>")
  let camera = Miio("<Camera Token Here>", "<Camera IP Here>")

  @Published var sendMsg = [String : Any]()
  @Published var receivedMsg = "-"

  func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    if let error = error { debugPrint(error.localizedDescription) }
  }
  
  func sessionDidBecomeInactive(_ session: WCSession) {
  }
  
  func sessionDidDeactivate(_ session: WCSession) {
  }
  
  func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
    DispatchQueue.main.async { self.sendMsg = message }
      
    let responseHandler = { msg in
      DispatchQueue.main.async { self.receivedMsg = msg }
    }

    let target = message["target"] as! String
    let method = message["method"] as! String
    let params = message["params"] as! [Any]

    switch target {
    case "vacuum":
      self.vacuum.send(method, params, responseHandler)
    case "camera":
      self.camera.send(method, params, responseHandler)
    default:
      break
    }
  }
}
