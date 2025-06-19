import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            AudioListView()
                .tabItem {
                    Label("Library", systemImage: "music.note.list")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}