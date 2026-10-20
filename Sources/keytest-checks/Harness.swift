import Foundation

struct CheckFailure: Error, CustomStringConvertible {
    let description: String
}

func expect(_ condition: @autoclosure () -> Bool, _ message: @autoclosure () -> String, line: Int = #line) throws {
    if !condition() { throw CheckFailure(description: "line \(line): \(message())") }
}

func expectEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String = "", line: Int = #line) throws {
    if actual != expected {
        throw CheckFailure(description: "line \(line): \(message) expected \(expected), got \(actual)")
    }
}

struct Suite {
    let name: String
    let tests: [(name: String, body: () throws -> Void)]
}
