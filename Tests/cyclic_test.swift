class ClassA {
    var b: ClassB

    init(b: ClassB) {
        self.b = b
    }

    func methodA() {
        b.methodB() // Создаёт зависимость A -> B
    }
}

class ClassB {
    var c: ClassC

    init(c: ClassC) {
        self.c = c
    }

    func methodB() {
        c.methodC() // Создаёт зависимость B -> C
    }
}

class ClassC {
    var a: ClassA

    init(a: ClassA) {
        self.a = a
    }

    func methodC() {
        a.methodA() // Создаёт зависимость C -> A (замыкает цикл)
    }
}