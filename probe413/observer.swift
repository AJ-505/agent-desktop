import AppKit

let logPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "/tmp/observer.log"
FileManager.default.createFile(atPath: logPath, contents: nil)
let logHandle = FileHandle(forWritingAtPath: logPath)!

func typeName(_ t: NSEvent.EventType) -> String {
    switch t {
    case .flagsChanged: return "flagsChanged"
    case .keyDown: return "keyDown"
    case .keyUp: return "keyUp"
    default: return "type\(t.rawValue)"
    }
}

final class Observer: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var status: NSTextField!
    var history: NSTextField!
    var lines: [String] = []
    var chordsSeen: [String] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        window = NSWindow(contentRect: NSRect(x: 80, y: 120, width: 1100, height: 640),
                          styleMask: [.titled], backing: .buffered, defer: false)
        window.title = "Chord observer (NSEvent local + global monitors)"
        status = NSTextField(labelWithString: "Waiting for modifier events")
        status.font = .boldSystemFont(ofSize: 30)
        status.frame = NSRect(x: 20, y: 560, width: 1060, height: 50)
        history = NSTextField(wrappingLabelWithString: "")
        history.font = .monospacedSystemFont(ofSize: 15, weight: .regular)
        history.frame = NSRect(x: 20, y: 20, width: 1060, height: 530)
        window.contentView!.addSubview(status)
        window.contentView!.addSubview(history)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        let mask: NSEvent.EventTypeMask = [.flagsChanged, .keyDown, .keyUp]
        NSEvent.addLocalMonitorForEvents(matching: mask) { event in
            self.record(event, via: "local"); return event
        }
        NSEvent.addGlobalMonitorForEvents(matching: mask) { event in
            self.record(event, via: "global")
        }
        log("READY pid=\(ProcessInfo.processInfo.processIdentifier) trusted=\(AXIsProcessTrusted())")
    }

    func record(_ event: NSEvent, via: String) {
        let raw = event.modifierFlags.rawValue
        let device = raw & 0xff
        var sides: [String] = []
        if device & 0x08 != 0 { sides.append("L⌘") }
        if device & 0x10 != 0 { sides.append("R⌘") }
        if device & 0x20 != 0 { sides.append("L⌥") }
        if device & 0x40 != 0 { sides.append("R⌥") }
        let line = String(format: "%@ %@ keyCode=%d flags=0x%llx device=0x%02llx held=[%@]",
                          via, typeName(event.type), event.keyCode, raw, device,
                          sides.joined(separator: " "))
        log(line)
        lines.append(line)
        if lines.count > 22 { lines.removeFirst() }
        history.stringValue = lines.joined(separator: "\n")
        if device & 0x18 == 0x18 { chordsSeen.append("BOTH ⌘ (L⌘+R⌘)") }
        if device & 0x60 == 0x60 { chordsSeen.append("BOTH ⌥ (L⌥+R⌥)") }
        let unique = Array(Set(chordsSeen)).sorted()
        status.stringValue = unique.isEmpty ? "Held now: [\(sides.joined(separator: " "))]"
            : "Chords seen: \(unique.joined(separator: ", "))  |  held now: [\(sides.joined(separator: " "))]"
    }

    func log(_ line: String) {
        logHandle.write((line + "\n").data(using: .utf8)!)
        try? logHandle.synchronize()
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.regular)
let delegate = Observer()
app.delegate = delegate
app.run()
