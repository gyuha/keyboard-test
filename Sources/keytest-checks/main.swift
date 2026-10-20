import Foundation

let allSuites = [layoutSuite, keyStateSuite, eventTapSuite, soundSuite]

var selected = allSuites
if let flag = CommandLine.arguments.firstIndex(of: "--suite") {
    let name = flag + 1 < CommandLine.arguments.count ? CommandLine.arguments[flag + 1] : ""
    selected = allSuites.filter { $0.name == name }
    if selected.isEmpty {
        FileHandle.standardError.write(Data("unknown suite: \(name)\n".utf8))
        exit(1)
    }
}

var failed = false
for suite in selected {
    var passed = 0
    for test in suite.tests {
        do {
            try test.body()
            passed += 1
        } catch {
            failed = true
            FileHandle.standardError.write(Data("FAIL \(suite.name)/\(test.name): \(error)\n".utf8))
        }
    }
    print("SUITE \(suite.name): \(passed)/\(suite.tests.count)")
}
exit(failed ? 1 : 0)
