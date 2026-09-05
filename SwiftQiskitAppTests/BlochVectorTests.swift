import Testing
@testable import SwiftQiskitApp
import SwiftQiskitCore

@MainActor
@Suite("BlochVector")
struct BlochVectorTests {

    private func expectClose(_ a: Double, _ b: Double) {
        #expect(abs(a - b) < 1e-9)
    }

    @Test("empty circuit stays at |0⟩")
    func zeroState() {
        let builder = CircuitBuilder(qubitCount: 1)
        let bloch = BlochVector(builder.buildCircuit().run(), qubit: 0)
        expectClose(bloch.x, 0)
        expectClose(bloch.y, 0)
        expectClose(bloch.z, 1)
    }

    @Test("H rotates |0⟩ to |+⟩")
    func hadamard() {
        let builder = CircuitBuilder(qubitCount: 1)
        builder.place(.h, qubits: [0], column: 0)
        let bloch = BlochVector(builder.buildCircuit().run(), qubit: 0)
        expectClose(bloch.x, 1)
        expectClose(bloch.y, 0)
        expectClose(bloch.z, 0)
    }

    @Test("H then S rotates |+⟩ to |+i⟩")
    func hadamardThenS() {
        let builder = CircuitBuilder(qubitCount: 1)
        builder.place(.h, qubits: [0], column: 0)
        builder.place(.s, qubits: [0], column: 1)
        let bloch = BlochVector(builder.buildCircuit().run(), qubit: 0)
        expectClose(bloch.x, 0)
        expectClose(bloch.y, 1)
        expectClose(bloch.z, 0)
    }

    @Test("X flips |0⟩ to |1⟩")
    func pauliX() {
        let builder = CircuitBuilder(qubitCount: 1)
        builder.place(.x, qubits: [0], column: 0)
        let bloch = BlochVector(builder.buildCircuit().run(), qubit: 0)
        expectClose(bloch.x, 0)
        expectClose(bloch.y, 0)
        expectClose(bloch.z, -1)
        expectClose(bloch.theta, Double.pi)
    }

    @Test("Bell state collapses both qubits' reduced vectors to the origin")
    func bellStateIsMaximallyEntangled() {
        let builder = CircuitBuilder(qubitCount: 2)
        builder.place(.h, qubits: [0], column: 0)
        builder.place(.cx, qubits: [0, 1], column: 1)
        let state = builder.buildCircuit().run()

        for qubit in 0..<2 {
            let bloch = BlochVector(state, qubit: qubit)
            expectClose(bloch.x, 0)
            expectClose(bloch.y, 0)
            expectClose(bloch.z, 0)
            expectClose(bloch.magnitude, 0)
        }
    }

    @Test("H on q0 only leaves q1 untouched")
    func reducedVectorIsolatesQubits() {
        let builder = CircuitBuilder(qubitCount: 2)
        builder.place(.h, qubits: [0], column: 0)
        let state = builder.buildCircuit().run()

        let q0 = BlochVector(state, qubit: 0)
        expectClose(q0.x, 1)
        expectClose(q0.y, 0)
        expectClose(q0.z, 0)

        let q1 = BlochVector(state, qubit: 1)
        expectClose(q1.x, 0)
        expectClose(q1.y, 0)
        expectClose(q1.z, 1)
    }

    @Test("buildCircuit(throughColumn:) replays only a prefix of the gates")
    func throughColumnReplaysPrefix() {
        let builder = CircuitBuilder(qubitCount: 2)
        builder.place(.h, qubits: [0], column: 0)
        builder.place(.cx, qubits: [0, 1], column: 1)

        let beforeAnyGates = BlochVector(builder.buildCircuit(throughColumn: -1).run(), qubit: 0)
        expectClose(beforeAnyGates.z, 1)

        let afterH = builder.buildCircuit(throughColumn: 0).run()
        let q0AfterH = BlochVector(afterH, qubit: 0)
        let q1AfterH = BlochVector(afterH, qubit: 1)
        expectClose(q0AfterH.x, 1)
        expectClose(q1AfterH.z, 1)
    }
}
