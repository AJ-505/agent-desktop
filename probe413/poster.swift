import CoreGraphics
import Foundation

let mode = CommandLine.arguments[1]
let pid = CommandLine.arguments.count > 2 ? pid_t(CommandLine.arguments[2])! : 0
let src = CGEventSource(stateID: .hidSystemState)

var gap: useconds_t = 4000
func post(_ e: CGEvent) {
    if pid != 0 { e.postToPid(pid) } else { e.post(tap: .cghidEventTap) }
    if gap > 0 { usleep(gap) }
}
func chord() {
    let a = key(55, true, cmd | 0x08, flagsChanged: false)
    let b = key(54, true, cmd | 0x18, flagsChanged: false)
    let c = key(54, false, cmd | 0x08, flagsChanged: false)
    let d = key(55, false, 0, flagsChanged: false)
    post(a); post(b); usleep(4000); post(c); post(d)
}

func key(_ code: CGKeyCode, _ down: Bool, _ flags: UInt64, flagsChanged: Bool) -> CGEvent {
    let e = CGEvent(keyboardEventSource: src, virtualKey: code, keyDown: down)!
    if !quiet { print("created keyCode=\(code) down=\(down) defaultType=\(e.type.rawValue)") }
    e.flags = CGEventFlags(rawValue: flags)
    if flagsChanged { e.type = .flagsChanged }
    return e
}

let cmd: UInt64 = 0x100000
let quiet = true
switch mode {
case "explicit":
    post(key(55, true, cmd | 0x08, flagsChanged: true))
    post(key(54, true, cmd | 0x18, flagsChanged: true))
    post(key(54, false, cmd | 0x08, flagsChanged: true))
    post(key(55, false, 0, flagsChanged: true))
case "implicit":
    post(key(55, true, cmd | 0x08, flagsChanged: false))
    post(key(54, true, cmd | 0x18, flagsChanged: false))
    post(key(54, false, cmd | 0x08, flagsChanged: false))
    post(key(55, false, 0, flagsChanged: false))
case "rapid-exit":
    gap = 0; chord()
case "rapid-linger":
    gap = 0; chord(); usleep(200000)
case "spaced-exit":
    gap = 4000; chord()
case "spaced-nolast":
    gap = 4000
    let a = key(55, true, cmd | 0x08, flagsChanged: false)
    let b = key(54, true, cmd | 0x18, flagsChanged: false)
    let c = key(54, false, cmd | 0x08, flagsChanged: false)
    let d = key(55, false, 0, flagsChanged: false)
    post(a); post(b); post(c); gap = 0; post(d)
case "state":
    print(String(format: "hidSystemState flags=0x%llx", CGEventSource.flagsState(.hidSystemState).rawValue))
    print(String(format: "combinedSessionState flags=0x%llx", CGEventSource.flagsState(.combinedSessionState).rawValue))
default:
    print("unknown mode")
}
