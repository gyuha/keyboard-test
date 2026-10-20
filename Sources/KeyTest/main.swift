import AppKit
import KeyTestCore

let arguments = CommandLine.arguments

if arguments.contains("--version") {
    print("KeyTest \(Layout.all.count) keys")
    exit(0)
}

if arguments.contains("--describe-ui") {
    print(UIDescription.text())
    exit(0)
}

if let flag = arguments.firstIndex(of: "--snapshot") {
    guard flag + 1 < arguments.count else {
        FileHandle.standardError.write(Data("usage: KeyTest --snapshot <path.png>\n".utf8))
        exit(64)
    }
    _ = NSApplication.shared
    exit(Snapshot.write(to: arguments[flag + 1]) ? 0 : 1)
}

let application = NSApplication.shared
application.setActivationPolicy(.regular)
let delegate = AppDelegate()
application.delegate = delegate
application.run()
