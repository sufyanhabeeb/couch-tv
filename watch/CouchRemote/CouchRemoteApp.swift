import SwiftUI

@main
struct CouchRemoteApp: App {
    @StateObject private var bridge = Bridge()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                if bridge.base.isEmpty {
                    SetupView()
                } else {
                    RemoteView()
                }
            }
            .environmentObject(bridge)
        }
    }
}

/// First run without an address built in: type or dictate the bridge's address once.
struct SetupView: View {
    @EnvironmentObject var bridge: Bridge

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Image(systemName: "tv")
                    .font(.title)
                Text("Enter the address your phone remote opens, like 192.168.1.20")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                TextFieldLink(prompt: Text("Bridge address")) {
                    Label("Address", systemImage: "network")
                } onSubmit: { text in
                    bridge.setBase(text)
                }
            }
        }
        .navigationTitle("Couch TV")
    }
}
