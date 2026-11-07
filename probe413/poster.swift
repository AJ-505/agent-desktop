import CoreGraphics
import Foundation

let mode = CommandLine.arguments[1]
let pid = CommandLine.arguments.count > 2 ? pid_t(CommandLine.arguments[2])! : 0
let src = CGEventSource(stateID: .hidSystemState)

func post(_ e: CGEvent) {
    if pid != 0 { e.postToPid(pid) } else { e.post(tap: .cghidEventTap) }
    usleep(4000)
}

func key(_ code: CGKeyCode, _ down: Bool, _ flags: UInt64, flagsChanged: Bool) -> CGEvent {
    let e = CGEvent(keyboardEventSource: src, virtualKey: code, keyDown: down)!
    print("created keyCode=\(code) down=\(down) defaultType=\(e.type.rawValue)")
    e.flags = CGEventFlags(rawValue: flags)
    if flagsChanged { e.type = .flagsChanged }
    return e
}

let cmd: UInt64 = 0x100000
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
default:
    print("unknown mode")
}
