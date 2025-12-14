// SimpleGraphTest.swift - Simple test for graph detectors
import Foundation

class TypeA {
    var b: TypeB
    var c: TypeC

    init(b: TypeB, c: TypeC) {
        self.b = b
        self.c = c
    }

    func method1() -> TypeD {
        return TypeD()
    }
}

class TypeB {
    var a: TypeA
    var c: TypeC
    var d: TypeD

    init(a: TypeA, c: TypeC, d: TypeD) {
        self.a = a
        self.c = c
        self.d = d
    }

    func method2(param: TypeC) -> TypeA {
        return TypeA(b: self, c: param)
    }
}

class TypeC {
    var a: TypeA
    var b: TypeB

    init(a: TypeA, b: TypeB) {
        self.a = a
        self.b = b
    }
}

class TypeD {
    var a: TypeA

    init() {
        self.a = TypeA(b: TypeB(a: self as! TypeA, c: TypeC(a: self as! TypeA, b: TypeB(a: self as! TypeA, c: TypeC(a: self as! TypeA, b: self as! TypeB), d: self)), c: TypeC(a: self as! TypeA, b: TypeB(a: self as! TypeA, c: TypeC(a: self as! TypeA, b: self as! TypeB), d: self))))
    }
}