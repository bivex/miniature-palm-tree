// Debug test for message chains
class Container {
    var inner: Inner?
}

class Inner {
    var value: String = "test"
}

class TestClass {
    var container: Container?

    func test() {
        // This should be detected as a message chain: container.inner.value
        let val = container?.inner?.value
        print(val ?? "nil")
    }

    func test2() {
        // Even simpler case
        if let c = container {
            if let i = c.inner {
                print(i.value)
            }
        }
    }
}