// ComplexDependencies.swift - Test file for graph interface detectors
import Foundation

class ServiceA {
    var data: DataManager?
    var helper: HelperService?

    func process() {
        data?.save()
        helper?.assist()
    }
}

class ServiceB {
    var data: DataManager?
    var helper: HelperService?
    var serviceA: ServiceA?

    func execute() {
        data?.load()
        helper?.assist()
        serviceA?.process()
    }
}

class ServiceC {
    var data: DataManager?
    var helper: HelperService?
    var serviceB: ServiceB?
    var serviceA: ServiceA?

    func run() {
        data?.update()
        helper?.assist()
        serviceB?.execute()
        serviceA?.process()
    }
}

class DataManager {
    var serviceA: ServiceA?
    var serviceB: ServiceB?
    var serviceC: ServiceC?

    func save() {}
    func load() {}
    func update() {}
}

class HelperService {
    var serviceA: ServiceA?
    var serviceB: ServiceB?
    var serviceC: ServiceC?
    var data: DataManager?

    func assist() {}
}

class Controller {
    var serviceA: ServiceA?
    var serviceB: ServiceB?
    var serviceC: ServiceC?
    var data: DataManager?
    var helper: HelperService?

    func handleRequest() {
        serviceA?.process()
        serviceB?.execute()
        serviceC?.run()
        data?.save()
        helper?.assist()
    }
}

class ViewModel {
    var controller: Controller?
    var serviceA: ServiceA?
    var serviceB: ServiceB?
    var serviceC: ServiceC?

    func updateView() {
        controller?.handleRequest()
        serviceA?.process()
        serviceB?.execute()
        serviceC?.run()
    }
}