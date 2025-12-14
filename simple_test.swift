// Simple test for message chains
class Test {
    func testMethod() {
        // This should create a message chain if we had nested objects
        let x = self
        let y = x
        let z = y
        print(z)
    }
}

// Let's try a more complex example
class A {
    var b: B?
}

class B {
    var c: C?
}

class C {
    var value: Int = 42
}

class Test2 {
    var a: A?

    func testMessageChain() {
        // This should be a message chain: a.b.c.value
        if let value = a?.b?.c?.value {
            print(value)
        }
    }
}