// Test Swift file for JSON export functionality
import Foundation

class TestGodClass {
    var property1: String
    var property2: Int
    var property3: Double
    var property4: Bool
    var property5: [String]
    var property6: Date
    var property7: URL?

    init() {
        self.property1 = ""
        self.property2 = 0
        self.property3 = 0.0
        self.property4 = false
        self.property5 = []
        self.property6 = Date()
    }

    func method1() { print("method1") }
    func method2() { print("method2") }
    func method3() { print("method3") }
    func method4() { print("method4") }
    func method5() { print("method5") }
    func method6() { print("method6") }
    func method7() { print("method7") }
    func method8() { print("method8") }
    func method9() { print("method9") }
    func method10() { print("method10") }
    func method11() { print("method11") }
    func method12() { print("method12") }
    func method13() { print("method13") }
    func method14() { print("method14") }
    func method15() { print("method15") }
}

class TestLazyClass {
    // Only has one method - should be detected as Lazy Class
    func doSomething() {
        print("Doing something")
    }
}

class TestDataClass {
    var name: String
    var age: Int

    init(name: String, age: Int) {
        self.name = name
        self.age = age
    }
}

func longMethod() {
    let a = 1
    let b = 2
    let c = 3
    let d = 4
    let e = 5
    let f = 6
    let g = 7
    let h = 8
    let i = 9
    let j = 10
    let k = 11
    let l = 12
    let m = 13
    let n = 14
    let o = 15
    let p = 16
    let q = 17
    let r = 18
    let s = 19
    let t = 20
    let u = 21
    let v = 22
    let w = 23
    let x = 24
    let y = 25
    let z = 26
    let aa = 27
    let bb = 28
    let cc = 29
    let dd = 30
    let ee = 31
    let ff = 32
    let gg = 33
    let hh = 34
    let ii = 35
    let jj = 36
    let kk = 37
    let ll = 38
    let mm = 39
    let nn = 40
    let oo = 41
    let pp = 42
    let qq = 43
    let rr = 44
    let ss = 45
    let tt = 46
    let uu = 47
    let vv = 48
    let ww = 49
    let xx = 50
    let yy = 51
    print("This is a very long method with \(a + b + c + d + e + f + g + h + i + j + k + l + m + n + o + p + q + r + s + t + u + v + w + x + y + z + aa + bb + cc + dd + ee + ff + gg + hh + ii + jj + kk + ll + mm + nn + oo + pp + qq + rr + ss + tt + uu + vv + ww + xx + yy) lines")
}