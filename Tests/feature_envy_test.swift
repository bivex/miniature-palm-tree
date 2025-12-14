class OtherClass {
    var property1: String = ""
    var property2: Int = 0
    var property3: Double = 0.0
}

class MyClass {
    var localProp: String = ""

    func methodWithFeatureEnvy(other: OtherClass) {
        // Local access: 1 (self.localProp)
        self.localProp = "test"

        // Foreign access: 3 (other.property1, other.property2, other.property3)
        // With default threshold=3, this should NOT trigger feature envy
        // With strict threshold=2, this SHOULD trigger feature envy
        let value1 = other.property1
        let value2 = other.property2
        let value3 = other.property3

        print("Values: \(value1), \(value2), \(value3)")
    }
}