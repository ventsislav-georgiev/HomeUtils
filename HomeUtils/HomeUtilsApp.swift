import SwiftUI
import WatchConnectivity

let connectivity = Connectivity()

@main
struct HomeUtilsApp: App {
  var body: some Scene {
    WindowGroup {
      NavigationView {
        HomeView()
      }
    }
  }
  
  init() {
    WCSession.default.delegate = connectivity
    WCSession.default.activate()
  }
}

struct HomeView: View {
  @StateObject var conn = connectivity
  
  var body: some View {
    ScrollView(content: {
      Text("Use the Watch app").bold()
      Text("")
      Text("Last send message:").bold()
      Text(stringifyJSON(self.conn.sendMsg) ?? "-").italic()
      Text("")
      Text("Last received message:").bold()
      Text(self.conn.receivedMsg).italic()
    })
  }
}
