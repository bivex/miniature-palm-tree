// ModularityTest.swift - Test for weakened modularity detector
import Foundation

class UserService {
    var repository: UserRepository
    var validator: UserValidator
    var logger: Logger
    var userCount: Int

    init(repository: UserRepository, validator: UserValidator, logger: Logger) {
        self.repository = repository
        self.validator = validator
        self.logger = logger
        self.userCount = 0
    }

    func createUser(name: String, email: String) -> User {
        logger.log("Creating user")
        if validator.validateEmail(email) {
            return repository.save(User(name: name, email: email))
        }
        return User(name: "", email: "")
    }

    func getUser(id: Int) -> User? {
        logger.log("Getting user")
        return repository.findById(id)
    }

    func updateUser(user: User) -> User {
        logger.log("Updating user")
        if validator.validateUser(user) {
            return repository.update(user)
        }
        return user
    }
}

class UserRepository {
    var database: Database
    var cache: Cache
    var lastAccess: Date

    init(database: Database, cache: Cache) {
        self.database = database
        self.cache = cache
        self.lastAccess = Date()
    }

    func save(user: User) -> User {
        cache.store(user)
        return database.insert(user)
    }

    func findById(id: Int) -> User? {
        if let cached = cache.get(id) {
            return cached
        }
        return database.query(id)
    }

    func update(user: User) -> User {
        cache.update(user)
        return database.update(user)
    }
}

class UserValidator {
    var rules: ValidationRules
    var sanitizer: DataSanitizer

    init(rules: ValidationRules, sanitizer: DataSanitizer) {
        self.rules = rules
        self.sanitizer = sanitizer
    }

    func validateEmail(email: String) -> Bool {
        let cleanEmail = sanitizer.sanitize(email)
        return rules.checkEmail(cleanEmail)
    }

    func validateUser(user: User) -> Bool {
        let cleanName = sanitizer.sanitize(user.name)
        let cleanEmail = sanitizer.sanitize(user.email)
        return rules.checkName(cleanName) && rules.checkEmail(cleanEmail)
    }
}

class Logger {
    func log(message: String) {
        print("LOG: \(message)")
    }
}

class Database {
    func insert(user: User) -> User { return user }
    func query(id: Int) -> User? { return nil }
    func update(user: User) -> User { return user }
}

class Cache {
    func store(user: User) {}
    func get(id: Int) -> User? { return nil }
    func update(user: User) {}
}

class ValidationRules {
    func checkEmail(email: String) -> Bool { return true }
    func checkName(name: String) -> Bool { return true }
}

class DataSanitizer {
    func sanitize(input: String) -> String { return input }
}

struct User {
    var id: Int = 0
    var name: String
    var email: String
}