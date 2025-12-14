// TestAllDetectors.swift - Test file to trigger various detectors
import Foundation

// Empty class - should trigger UnnecessaryAbstractionDetector
class EmptyClass {
}

// Global function - should trigger MissingAbstractionDetector
func globalFunction() {
    print("Hello")
}

// Global variable - should trigger MissingAbstractionDetector
var globalVar = "test"

// Another global variable - should trigger MissingAbstractionDetector
var anotherGlobal = 42

// Duplicate code blocks - should trigger DuplicateBlockDetector
class TestDuplicate {
    func method1() {
        if true {
            print("line1")
            print("line2")
            print("line3")
            print("line4")
            print("line5")
        }
    }

    func method2() {
        if false {
            print("line1")
            print("line2")
            print("line3")
            print("line4")
            print("line5")
        }
    }
}

// Imperative abstraction - should trigger ImperativeAbstractionDetector
class ImperativeClass {
    func doSomething() {
        print("Doing something")
        fatalError("Error occurred")
        UserDefaults.standard.set("value", forKey: "key")
        FileManager.default.createFile(atPath: "test", contents: nil)
    }
}

// Unstructured module - mixed architectural layers
class ModelClass {
    var data: String = ""
}

class ViewClass {
    func display() {}
}

class ControllerClass {
    func handle() {}
}

class UtilityClass {
    static func helper() {}
}