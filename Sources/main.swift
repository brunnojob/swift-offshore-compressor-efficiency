import Foundation

enum Failure: Error, CustomStringConvertible {
    case invalid(String)
    var description: String { switch self { case .invalid(let message): return message } }
}
func require(_ condition: Bool, _ message: String) throws {
    if !condition { throw Failure.invalid(message) }
}
func numeric(_ value: String) throws -> Double {
    guard let parsed = Double(value), parsed.isFinite else { throw Failure.invalid("Finite number required") }
    return parsed
}
func input(_ columns: Int) throws -> [[String]] {
    var rows: [[String]] = []
    while let line = readLine() {
        try require(rows.count < 100000, "Input capacity exceeded")
        let fields = line.split(separator: ",", omittingEmptySubsequences: false).map(String.init)
        try require(fields.count == columns && fields.allSatisfy { !$0.isEmpty }, "Invalid CSV row")
        rows.append(fields)
    }
    try require(!rows.isEmpty, "Missing input")
    return rows
}
func output<T: Encodable>(_ value: T) throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    let data = try encoder.encode(value)
    guard let text = String(data: data, encoding: .utf8) else { throw Failure.invalid("Encoding failed") }
    print(text)
}

struct Reading { let tag: String; let inletBar: Double; let outletBar: Double; let inletK: Double; let outletK: Double; let flow: Double }
struct Performance: Codable { let tag: String; let pressureRatio: Double; let isentropicEfficiency: Double; let shaftPowerKw: Double; let degraded: Bool }
func performance(_ r: Reading) throws -> Performance {
    try require(r.inletBar > 0 && r.outletBar > r.inletBar && r.inletK > 0 && r.outletK > r.inletK && r.flow >= 0, "Invalid thermodynamic reading")
    let gamma = 1.4, cp = 1.005
    let ratio = r.outletBar / r.inletBar
    let idealOutlet = r.inletK * pow(ratio, (gamma - 1) / gamma)
    let efficiency = (idealOutlet - r.inletK) / (r.outletK - r.inletK)
    try require(efficiency > 0 && efficiency <= 1.02, "Inconsistent compression temperature")
    return Performance(tag: r.tag, pressureRatio: ratio, isentropicEfficiency: efficiency, shaftPowerKw: r.flow * cp * (r.outletK - r.inletK), degraded: efficiency < 0.65)
}
func test() throws {
    let ideal = 300 * pow(2.0, 0.4 / 1.4)
    let p = try performance(Reading(tag: "A", inletBar: 1, outletBar: 2, inletK: 300, outletK: 300 + (ideal - 300) / 0.8, flow: 1))
    try require(abs(p.isentropicEfficiency - 0.8) < 1e-12 && !p.degraded, "Efficiency mismatch")
    var rejected = false
    do { _ = try performance(Reading(tag: "A", inletBar: 1, outletBar: 2, inletK: 300, outletK: 310, flow: 1)) } catch { rejected = true }
    try require(rejected, "Inconsistent thermodynamics accepted")
}
func run() throws {
    for row in try input(6) {
        let r = Reading(tag: row[0], inletBar: try numeric(row[1]), outletBar: try numeric(row[2]), inletK: try numeric(row[3]), outletK: try numeric(row[4]), flow: try numeric(row[5]))
        try output(performance(r))
    }
}

do {
    if Array(CommandLine.arguments.dropFirst()) == ["--self-test"] { try test(); print("Tests passed") }
    else { try run() }
} catch {
    FileHandle.standardError.write(Data("\(error)\n".utf8))
    exit(2)
}
