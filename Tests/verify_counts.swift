#!/usr/bin/env swift

import Foundation

// Simple verification script to check the analysis counts
print("Verifying AST Analyzer counts...")

// Run the analyzer and capture output
let process = Process()
process.executableURL = URL(fileURLWithPath: "./.build/debug/ASTAnalyzer")
process.arguments = ["Sources/ASTAnalyzer"]

let pipe = Pipe()
process.standardOutput = pipe

do {
    try process.run()
    process.waitUntilExit()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8) ?? ""

    // Parse the output
    let criticalPattern = #"🚨 Critical Issues: (\d+)"#
    let highPattern = #"⚠️  High Priority: (\d+)"#
    let totalPattern = #"📊 Total Defects: (\d+)"#
    let scorePattern = #"🎯 Average Maintainability Score: ([0-9.]+)/100"#

    if let criticalMatch = output.range(of: criticalPattern, options: .regularExpression),
       let highMatch = output.range(of: highPattern, options: .regularExpression),
       let totalMatch = output.range(of: totalPattern, options: .regularExpression),
       let scoreMatch = output.range(of: scorePattern, options: .regularExpression) {

        let criticalStr = String(output[criticalMatch])
        let highStr = String(output[highMatch])
        let totalStr = String(output[totalMatch])
        let scoreStr = String(output[scoreMatch])

        print("Parsed values:")
        print("Critical: \(criticalStr)")
        print("High Priority: \(highStr)")
        print("Total Defects: \(totalStr)")
        print("Score: \(scoreStr)")

        // Extract numbers
        let critical = Int(criticalStr.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) ?? 0
        let high = Int(highStr.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) ?? 0
        let total = Int(totalStr.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) ?? 0

        print("\nVerification:")
        print("Critical + High should be ≤ Total: \(critical) + \(high) = \(critical + high) ≤ \(total) -> \(critical + high <= total)")

        if critical + high <= total {
            print("✅ Counts are consistent")
        } else {
            print("❌ Counts are inconsistent!")
        }
    } else {
        print("Failed to parse output")
    }
} catch {
    print("Error running analyzer: \(error)")
}