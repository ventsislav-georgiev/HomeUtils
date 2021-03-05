import SwiftUI

@main
struct HomeUtilsApp: App {
  var body: some Scene {
    WindowGroup {
      HomeView()
    }
  }
}

struct HomeView: View {
  @StateObject var context = Connectivity()
  
  var body: some View {
    NavigationView {
      ScrollView(content: {
        NavigationLink(destination:
                        ScrollView() {
                          HStack() {
                            Button(action: { self.context.sendVacuum("app_start") }) { Image(systemName: "play") }
                            Button(action: { self.context.sendVacuum("app_stop") }) { Image(systemName: "stop") }
                          }
                          HStack() {
                            Button(action: { self.context.sendVacuum("app_pause") }) { Image(systemName: "pause") }
                            Button(action: { self.context.sendVacuum("app_charge") }) { Image(systemName: "backward.end") }
                          }
                          HStack() {
                            Button(action: { self.context.sendVacuum("set_custom_mode", [105]) }) { Image(systemName: "cloud.rain") }
                            Button(action: { self.context.sendVacuum("set_custom_mode", [104]) }) { Image(systemName: "tornado") }
                          }
                          HStack() {
                            Button(action: { self.context.sendVacuum("miIO.info") }) { Image(systemName: "gear") }
                            Button(action: { self.context.sendVacuum("get_status") }) { Image(systemName: "info.circle") }
                          }
                        }, label: { HStack() { Image(systemName: "lifepreserver.fill"); Text("Vacuum") } })
        NavigationLink(destination:
                        ScrollView() {
                          HStack() {
                            Button(action: { self.context.sendCamera("set_power", ["on"]) }) { Image(systemName: "play") }
                            Button(action: { self.context.sendCamera("set_power", ["off"]) }) { Image(systemName: "stop") }
                          }
                          HStack() {
                            Button(action: { self.context.sendCamera("miIO.info") }) { Image(systemName: "gear") }
                            Button(action: { self.context.sendCamera("get_prop", camera_props) }) { Image(systemName: "info.circle") }
                          }
                        }, label: { HStack() { Image(systemName: "video"); Text("Camera") } })
      })
    }
  }
}
