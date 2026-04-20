import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    private var source: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1

    private let triggerPath = NSHomeDirectory() + "/.wifi-loc-control/vpn-trigger"

    func applicationDidFinishLaunching(_ notification: Notification) {
        if !FileManager.default.fileExists(atPath: triggerPath) {
            try? "".write(toFile: triggerPath, atomically: true, encoding: .utf8)
        }
        startWatching()
    }

    private func startWatching() {
        fileDescriptor = open(triggerPath, O_EVTONLY)
        guard fileDescriptor != -1 else { return }

        source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: .write,
            queue: .global()
        )
        source?.setEventHandler { [weak self] in self?.handleTrigger() }
        source?.setCancelHandler { [weak self] in
            if let fd = self?.fileDescriptor, fd != -1 { close(fd) }
        }
        source?.resume()
    }

    private func handleTrigger() {
        guard let raw = try? String(contentsOfFile: triggerPath, encoding: .utf8) else { return }
        let line = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = line.split(separator: ":", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { return }
        let action = parts[0]
        let tunnel = parts[1]
        guard !tunnel.isEmpty, action == "on" || action == "off" else { return }

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/scutil")
        task.arguments = ["--nc", action == "on" ? "start" : "stop", tunnel]
        try? task.run()
        task.waitUntilExit()
    }

    func applicationWillTerminate(_ notification: Notification) {
        source?.cancel()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
