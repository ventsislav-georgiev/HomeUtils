import Foundation
import WatchConnectivity

let camera_props = ["power", "motion_record", "light", "full_color", "flip", "improve_program", "wdr", "track", "sdcard_status", "watermark", "max_client", "night_mode", "mini_level"]

class Connectivity: NSObject, WCSessionDelegate, ObservableObject {
  var session: WCSession
  @Published var msg = [String : Any]()
  
  init(session: WCSession = .default){
    self.session = session
    super.init()
    self.session.delegate = self
    self.session.activate()
  }
  
  func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    if let error = error { debugPrint(error.localizedDescription) }
  }
  
  func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
    DispatchQueue.main.async { self.msg = message }
  }
  
  func sendVacuum(_ method: String, _ params: [Any] = []) {
    self.session.sendMessage(["target": "vacuum", "method": method, "params": params]) { error in debugPrint(error) }
  }
  
  func sendCamera(_ method: String, _ params: [Any] = []) {
    self.session.sendMessage(["target": "camera", "method": method, "params": params]) { error in debugPrint(error) }
  }
}
