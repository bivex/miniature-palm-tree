// ModularityTest2.swift - Test for weakened modularity with dependencies
import Foundation

class ServiceA {
    var data: String
    var count: Int
    var serviceB: ServiceB

    func process() {
        serviceB.process()
    }
    func validate() {}
    func save() {}
}

class ServiceB {
    var data: String
    var count: Int
    var serviceC: ServiceC

    func process() {
        serviceC.process()
    }
    func validate() {}
    func load() {}
}

class ServiceC {
    var data: String
    var count: Int

    func process() {}
    func validate() {}
    func execute() {}
}