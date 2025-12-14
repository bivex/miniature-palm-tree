// Test file for new detectors
import Foundation

class User {
    var name: String
    var email: String

    init(name: String, email: String) {
        self.name = name
        self.email = email
    }
}

class Order {
    var id: Int
    var user: User
    var items: [String]

    init(id: Int, user: User, items: [String]) {
        self.id = id
        self.user = user
        self.items = items
    }

    // Feature Envy - method accesses more from User than from Order
    func getUserDetails() -> String {
        return user.name + " " + user.email + " " + user.name // accessing user multiple times
    }

    // Message Chain - long chain of method calls
    func getNestedUserInfo() -> String {
        // This would be a message chain if we had nested objects
        return user.name.uppercased()
    }

    // Another potential message chain
    func processOrder() {
        let details = user.name + user.email
        print(details)
    }
}

class OrderProcessor {
    var orders: [Order] = []

    init() {}

    func addOrder(_ order: Order) {
        orders.append(order)
    }

    func processOrders() {
        for order in orders {
            // Potential message chain
            let userName = order.user.name
            print("Processing order for \(userName)")
        }
    }
}

// Cyclic dependency classes
class ClassA {
    var b: ClassB?

    func methodA() {
        b?.methodB()
    }
}

class ClassB {
    var c: ClassC?

    func methodB() {
        c?.methodC()
    }
}

class ClassC {
    var a: ClassA?

    func methodC() {
        a?.methodA() // This creates a cycle: A -> B -> C -> A
    }
}