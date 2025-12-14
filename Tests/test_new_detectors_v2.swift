// More explicit test cases for new detectors

class Address {
    var street: String
    var city: String
    var country: String

    init(street: String, city: String, country: String) {
        self.street = street
        self.city = city
        self.country = country
    }
}

class Person {
    var name: String
    var age: Int
    var address: Address

    init(name: String, age: Int, address: Address) {
        self.name = name
        self.age = age
        self.address = address
    }

    // Feature Envy - this method accesses address properties multiple times
    // but doesn't access Person's own properties
    func getFullAddress() -> String {
        return address.street + ", " + address.city + ", " + address.country
    }

    // Another feature envy case
    func isInCountry(country: String) -> Bool {
        return address.country == country
    }

    // Message chain - accessing nested properties
    func getStreetName() -> String {
        return address.street
    }

    func getCityName() -> String {
        return address.city
    }

    func getCountryName() -> String {
        return address.country
    }
}

class Company {
    var name: String
    var employees: [Person]

    init(name: String, employees: [Person]) {
        self.name = name
        self.employees = employees
    }

    // Method with message chains
    func getEmployeeCities() -> [String] {
        return employees.map { employee in
            employee.address.city  // message chain: employee.address.city
        }
    }

    // Method that might exhibit feature envy
    func getEmployeeAddress(employee: Person) -> String {
        return employee.address.street + " " + employee.address.city
    }
}

// Cyclic dependency test
class Manager {
    var name: String
    var team: Team?

    init(name: String) {
        self.name = name
    }

    func getTeamSize() -> Int {
        return team?.members.count ?? 0
    }
}

class Team {
    var name: String
    var manager: Manager?
    var members: [Employee]

    init(name: String, members: [Employee] = []) {
        self.name = name
        self.members = members
    }

    func assignManager(manager: Manager) {
        self.manager = manager
        manager.team = self  // Creates cycle: Manager -> Team -> Manager
    }
}

class Employee {
    var name: String
    var team: Team?

    init(name: String) {
        self.name = name
    }
}