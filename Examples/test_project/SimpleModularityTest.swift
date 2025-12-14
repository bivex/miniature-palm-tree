// SimpleModularityTest.swift - Simple test for weakened modularity
import Foundation

class ServiceA {
    var data: String = ""
    var count: Int = 0

    func process() {}
    func validate() {}
    func save() {}
}

class ServiceB {
    var name: String = ""
    var active: Bool = false

    func execute() {}
    func validate() {}
    func load() {}
}

class ServiceC {
    var items: [String] = []
    var ready: Bool = true

    func run() {}
    func validate() {}
    func process() {}
}