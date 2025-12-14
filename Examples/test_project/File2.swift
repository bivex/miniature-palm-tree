// File2.swift - Contains Long Method and Data Class
import Foundation

class UserData {
    var firstName: String
    var lastName: String

    init(firstName: String, lastName: String) {
        self.firstName = firstName
        self.lastName = lastName
    }
}

class Processor {
    func processUsers(users: [UserData]) {
        // This is a very long method
        for user in users {
            let name = user.firstName + " " + user.lastName
            print("Processing user: \(name)")

            if name.count > 5 {
                print("Name is long")
            } else {
                print("Name is short")
            }

            if user.firstName.hasPrefix("A") {
                print("Starts with A")
            } else if user.firstName.hasPrefix("B") {
                print("Starts with B")
            } else if user.firstName.hasPrefix("C") {
                print("Starts with C")
            } else {
                print("Starts with something else")
            }

            // More processing logic...
            let upperName = name.uppercased()
            let lowerName = name.lowercased()
            let reversedName = String(name.reversed())

            print("Upper: \(upperName)")
            print("Lower: \(lowerName)")
            print("Reversed: \(reversedName)")

            // Even more logic to make it long
            let components = name.split(separator: " ")
            let firstInitial = components.first?.first ?? Character(" ")
            let lastInitial = components.last?.first ?? Character(" ")

            print("Initials: \(firstInitial)\(lastInitial)")

            // Continue with more operations...
            let hash = name.hashValue
            let length = name.count
            let isEvenLength = length % 2 == 0

            print("Hash: \(hash), Length: \(length), Even: \(isEvenLength)")

            // And more...
            let containsSpace = name.contains(" ")
            let wordCount = components.count
            let averageWordLength = Double(length) / Double(wordCount)

            print("Contains space: \(containsSpace), Words: \(wordCount), Avg length: \(averageWordLength)")
        }
    }
}