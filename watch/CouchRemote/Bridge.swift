import Foundation
import WatchKit

/// Talks to the couch-tv bridge over the home Wi-Fi (bridge/API.md). Volume goes to /api/volume as a
/// level; everything else to /api/watch, which answers in a few words of plain text.
@MainActor
final class Bridge: ObservableObject {
    @Published var base: String
    @Published var volume: Double = 0          // 0 to 100, bound to the Digital Crown
    @Published var volumeKnown = false
    @Published var muted = false
    @Published var reachable = true
    @Published var tvOn = true
    @Published var note: String?               // a short line under the volume ("Paused", errors)
    @Published var asking = false
    @Published var reply: String?

    private var lastSent: Int?
    private var pending: Int?
    private var sending = false
    private var crownUntil = Date.distantPast   // ignore the TV's level while the crown is moving
    private var noteTask: Task<Void, Never>?

    init() {
        let saved = UserDefaults.standard.string(forKey: "bridgeURL") ?? ""
        let built = (Bundle.main.object(forInfoDictionaryKey: "CouchBridgeURL") as? String) ?? ""
        base = saved.isEmpty ? built : saved
    }

    /// "192.168.1.20" -> "http://192.168.1.20:5400"
    func setBase(_ text: String) {
        var t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty { return }
        if !t.contains("://") { t = "http://" + t }
        while t.hasSuffix("/") { t.removeLast() }
        if let u = URL(string: t), u.port == nil { t += ":5400" }
        base = t
        UserDefaults.standard.set(t, forKey: "bridgeURL")
        Task { await refresh() }
    }

    enum Failure: Error { case status(Int, String) }

    private func call(_ path: String, _ body: [String: Any]? = nil, timeout: TimeInterval = 8) async throws -> Data {
        guard let url = URL(string: base + path) else { throw URLError(.badURL) }
        var req = URLRequest(url: url, timeoutInterval: timeout)
        if let body {
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        let (data, resp) = try await URLSession.shared.data(for: req)
        if let h = resp as? HTTPURLResponse, h.statusCode >= 400 {
            throw Failure.status(h.statusCode, String(decoding: data, as: UTF8.self))
        }
        return data
    }

    /// The TV's state from /api/now: on or off, and the volume.
    func refresh() async {
        guard !base.isEmpty else { return }
        do {
            let data = try await call("/api/now", timeout: 5)
            guard let j = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
            reachable = true
            tvOn = (j["power"] as? String) != "off"
            if let v = j["volume"] as? [String: Any] {
                volumeKnown = (v["known"] as? Bool) ?? false
                muted = (v["muted"] as? Bool) ?? false
                if Date() > crownUntil, !sending, pending == nil,
                   let level = v["level"] as? Int, let max = v["max"] as? Int, max > 0 {
                    let pct = (Double(level) * 100 / Double(max)).rounded()
                    lastSent = Int(pct)
                    volume = pct
                }
            }
        } catch {
            reachable = false
        }
    }

    /// The crown moved: send the newest level, one request at a time, so turning feels live.
    func crownMoved(to value: Double) {
        let target = Int(value.rounded())
        guard target != lastSent else { return }
        crownUntil = Date().addingTimeInterval(1.5)
        pending = target
        if !sending { Task { await pump() } }
    }

    private func pump() async {
        sending = true
        while let target = pending {
            pending = nil
            if target == lastSent { continue }
            lastSent = target
            do {
                _ = try await call("/api/volume", ["level": target])
                muted = false
            } catch {
                show("Volume didn't send")
            }
        }
        sending = false
        crownUntil = Date().addingTimeInterval(0.8)
    }

    /// A key or command for /api/watch ("Play", "Pause", "Back", "Mute", "Power", ...).
    func send(_ what: String) async {
        WKInterfaceDevice.current().play(.click)
        do {
            let data = try await call("/api/watch", ["do": what], timeout: what == "Power" ? 40 : 8)
            show(String(decoding: data, as: UTF8.self))
            reachable = true
        } catch Failure.status(_, let text) {
            show(text.isEmpty ? "Didn't work" : text)
        } catch {
            reachable = false
            show("Can't reach the TV")
        }
        await refresh()
    }

    /// The Claude assistant: what you said goes to the bridge, the reply comes back as text.
    func ask(_ text: String) async {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        asking = true
        reply = nil
        do {
            let data = try await call("/api/watch", ["do": "ask", "text": t], timeout: 120)
            reply = String(decoding: data, as: UTF8.self)
            WKInterfaceDevice.current().play(.success)
        } catch Failure.status(_, let text) {
            reply = text.isEmpty ? "The assistant didn't answer." : text
            WKInterfaceDevice.current().play(.failure)
        } catch {
            reply = "Can't reach the TV. Are you on the home Wi-Fi?"
            WKInterfaceDevice.current().play(.failure)
        }
        asking = false
        await refresh()
    }

    private func show(_ text: String) {
        note = text
        noteTask?.cancel()
        noteTask = Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            if !Task.isCancelled { note = nil }
        }
    }
}
