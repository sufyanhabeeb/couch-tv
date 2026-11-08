import SwiftUI

/// The main screen: turn the crown for volume, tap the dial to mute, playback below, Ask at the bottom.
struct RemoteView: View {
    @EnvironmentObject var bridge: Bridge
    @FocusState private var dialFocused: Bool

    var body: some View {
        VStack(spacing: 6) {
            dial
            HStack(spacing: 6) {
                key("chevron.backward", "Back")
                key("play.fill", "Play")
                key("pause.fill", "Pause")
            }
            TextFieldLink(prompt: Text("Ask the TV")) {
                Label("Ask", systemImage: "mic.fill")
                    .frame(maxWidth: .infinity)
            } onSubmit: { text in
                Task { await bridge.ask(text) }
            }
            .tint(.pink)
        }
        .padding(.horizontal, 4)
        .navigationTitle("Couch TV")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    MoreView()
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
        .onChange(of: bridge.volume) { _, value in
            bridge.crownMoved(to: value)
        }
        .task {
            dialFocused = true
            while !Task.isCancelled {
                await bridge.refresh()
                try? await Task.sleep(nanoseconds: 3_000_000_000)
            }
        }
        .sheet(isPresented: Binding(
            get: { bridge.asking || bridge.reply != nil },
            set: { if !$0 { bridge.reply = nil } }
        )) {
            ReplyView()
        }
    }

    private var dial: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.15), lineWidth: 7)
            Circle()
                .trim(from: 0, to: bridge.volume / 100)
                .stroke(bridge.muted ? Color.gray : Color.pink,
                        style: StrokeStyle(lineWidth: 7, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.15), value: bridge.volume)
            VStack(spacing: 0) {
                Text("\(Int(bridge.volume))")
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                Text(status)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(width: 92, height: 92)
        .focusable(true)
        .focused($dialFocused)
        .digitalCrownRotation($bridge.volume, from: 0, through: 100, by: 1,
                              sensitivity: .low, isContinuous: false, isHapticFeedbackEnabled: true)
        .onTapGesture {
            Task { await bridge.send("Mute") }
        }
        .accessibilityLabel("Volume \(Int(bridge.volume))")
        .accessibilityHint("Turn the Digital Crown to change it, tap to mute")
    }

    private var status: String {
        if let note = bridge.note { return note }
        if !bridge.reachable { return "Not reachable" }
        if !bridge.tvOn { return "TV is off" }
        return bridge.muted ? "Muted" : "Volume"
    }

    private func key(_ symbol: String, _ what: String) -> some View {
        Button {
            Task { await bridge.send(what) }
        } label: {
            Image(systemName: symbol)
                .frame(maxWidth: .infinity)
        }
        .accessibilityLabel(what)
    }
}

/// The assistant's answer, or a spinner while it thinks.
struct ReplyView: View {
    @EnvironmentObject var bridge: Bridge

    var body: some View {
        ScrollView {
            if bridge.asking {
                ProgressView("Asking…")
                    .padding(.top, 20)
            } else {
                Text(bridge.reply ?? "")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

/// Arrows, OK, Home, Power, and the bridge address.
struct MoreView: View {
    @EnvironmentObject var bridge: Bridge

    var body: some View {
        ScrollView {
            VStack(spacing: 6) {
                pad("chevron.up", "Up")
                HStack(spacing: 6) {
                    pad("chevron.left", "Left")
                    Button("OK") { Task { await bridge.send("OK") } }
                    pad("chevron.right", "Right")
                }
                pad("chevron.down", "Down")
                HStack(spacing: 6) {
                    pad("house.fill", "Home")
                    pad("power", "Power")
                        .tint(.red)
                }
                .padding(.top, 4)
                TextFieldLink(prompt: Text("Bridge address")) {
                    Label(bridge.base.replacingOccurrences(of: "http://", with: ""), systemImage: "network")
                        .font(.footnote)
                } onSubmit: { text in
                    bridge.setBase(text)
                }
                .padding(.top, 8)
            }
        }
        .navigationTitle("More")
    }

    private func pad(_ symbol: String, _ what: String) -> some View {
        Button {
            Task { await bridge.send(what) }
        } label: {
            Image(systemName: symbol)
                .frame(maxWidth: .infinity)
        }
        .accessibilityLabel(what)
    }
}
