import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    private var timer: Timer?
    private var lastContent = ""
    private var lastTunnel = ""
    private var retryCount = 0
    private let maxRetries = 3

    private let triggerPath = NSHomeDirectory() + "/.wifi-loc-control/vpn-trigger"

    func applicationDidFinishLaunching(_ notification: Notification) {
        if !FileManager.default.fileExists(atPath: triggerPath) {
            try? "".write(toFile: triggerPath, atomically: true, encoding: .utf8)
        }
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkTrigger()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    private func checkTrigger() {
        guard let raw = try? String(contentsOfFile: triggerPath, encoding: .utf8) else { return }
        let line = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !line.isEmpty, line != lastContent else { return }

        let parts = line.split(separator: ":", maxSplits: 2, omittingEmptySubsequences: false).map(String.init)
        guard parts.count >= 2 else { lastContent = line; return }
        let action = parts[0]
        let tunnel = parts[1].isEmpty ? lastTunnel : parts[1]
        guard !tunnel.isEmpty, action == "on" || action == "off" else { lastContent = line; return }

        if action == "on" { lastTunnel = tunnel }

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/scutil")
        task.arguments = ["--nc", action == "on" ? "start" : "stop", tunnel]
        guard (try? task.run()) != nil else { return }
        task.waitUntilExit()

        if task.terminationStatus == 0 {
            lastContent = line
            retryCount = 0
        } else {
            retryCount += 1
            if retryCount >= maxRetries { lastContent = line; retryCount = 0 }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        timer?.invalidate()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
