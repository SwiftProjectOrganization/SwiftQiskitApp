import Testing
@testable import SwiftQiskitApp
import SwiftQiskit

@MainActor
@Suite("CircuitBuilder")
struct CircuitBuilderTests {

    @Test("H + CX reproduces the Bell state")
    func bellState() {
        let builder = CircuitBuilder(qubitCount: 2)
        builder.place(.h, qubits: [0], column: 0)
        builder.place(.cx, qubits: [0, 1], column: 1)

        let state = builder.buildCircuit().run()

        let expectedAmplitude = 1.0 / 2.0.squareRoot()
        #expect(abs(state[0].magnitude - expectedAmplitude) < 1e-9)
        #expect(state[1].magnitude < 1e-9)
        #expect(state[2].magnitude < 1e-9)
        #expect(abs(state[3].magnitude - expectedAmplitude) < 1e-9)
    }

    @Test("placing a gate on an occupied cell is rejected")
    func occupiedCellRejected() {
        let builder = CircuitBuilder(qubitCount: 2)
        #expect(builder.place(.h, qubits: [0], column: 0))
        #expect(!builder.place(.x, qubits: [0], column: 0))
        #expect(builder.gates.count == 1)
    }

    @Test("placing a gate out of range is rejected")
    func outOfRangeRejected() {
        let builder = CircuitBuilder(qubitCount: 2)
        #expect(!builder.place(.h, qubits: [5], column: 0))
        #expect(builder.gates.isEmpty)
    }

    @Test("shrinking qubitCount drops gates that no longer fit")
    func shrinkingDropsOutOfRangeGates() {
        let builder = CircuitBuilder(qubitCount: 3)
        builder.place(.h, qubits: [0], column: 0)
        builder.place(.x, qubits: [2], column: 0)

        builder.qubitCount = 2

        #expect(builder.gates.count == 1)
        #expect(builder.gates.first?.kind == .h)
    }

    @Test("qubitCount is clamped to the supported range")
    func qubitCountClamped() {
        let builder = CircuitBuilder(qubitCount: 2)

        builder.qubitCount = 99
        #expect(builder.qubitCount == CircuitBuilder.maxQubits)

        builder.qubitCount = -5
        #expect(builder.qubitCount == CircuitBuilder.minQubits)
    }

    @Test("updateTheta changes only the targeted parameterized gate")
    func updateThetaChangesAngle() {
        let builder = CircuitBuilder(qubitCount: 1)
        builder.place(.rx(0.1), qubits: [0], column: 0)
        let id = builder.gates[0].id

        builder.updateTheta(id: id, theta: 1.23)

        #expect(builder.gates[0].kind.theta == 1.23)
    }

    @Test("clear removes all placed gates and any prior measurement")
    func clearRemovesGates() {
        let builder = CircuitBuilder(qubitCount: 2)
        builder.place(.h, qubits: [0], column: 0)
        builder.place(.x, qubits: [1], column: 0)
        builder.measure()

        builder.clear()

        #expect(builder.gates.isEmpty)
        #expect(builder.lastResult == nil)
    }

    @Test("measure populates lastResult with counts totaling shots")
    func measurePopulatesResult() throws {
        let builder = CircuitBuilder(qubitCount: 2)
        builder.place(.h, qubits: [0], column: 0)
        builder.shots = 250

        builder.measure()

        let result = try #require(builder.lastResult)
        #expect(result.counts.values.reduce(0, +) == 250)
    }

    @Test("shrinking qubitCount discards a prior measurement")
    func shrinkingQubitCountClearsResult() {
        let builder = CircuitBuilder(qubitCount: 3)
        builder.place(.h, qubits: [0], column: 0)
        builder.measure()

        builder.qubitCount = 2

        #expect(builder.lastResult == nil)
    }

    @Test("RZZ replay matches a directly built circuit on non-adjacent qubits")
    func rzzReplay() {
        let theta = 0.7
        let builder = CircuitBuilder(qubitCount: 3)
        builder.place(.h, qubits: [0], column: 0)
        builder.place(.h, qubits: [2], column: 0)
        builder.place(.rzz(theta), qubits: [0, 2], column: 1)

        let direct = QuantumCircuit(qubits: 3)
        direct.h(0)
        direct.h(2)
        direct.rzz(theta, 0, 2)

        expectStatesMatch(builder.buildCircuit().run(), direct.run())
    }

    @Test("RXX replay matches a directly built circuit on non-adjacent qubits")
    func rxxReplay() {
        let theta = 0.7
        let builder = CircuitBuilder(qubitCount: 3)
        builder.place(.h, qubits: [0], column: 0)
        builder.place(.h, qubits: [2], column: 0)
        builder.place(.rxx(theta), qubits: [0, 2], column: 1)

        let direct = QuantumCircuit(qubits: 3)
        direct.h(0)
        direct.h(2)
        direct.rxx(theta, 0, 2)

        expectStatesMatch(builder.buildCircuit().run(), direct.run())
    }

    @Test("RYY replay matches a directly built circuit on non-adjacent qubits")
    func ryyReplay() {
        let theta = 0.7
        let builder = CircuitBuilder(qubitCount: 3)
        builder.place(.h, qubits: [0], column: 0)
        builder.place(.h, qubits: [2], column: 0)
        builder.place(.ryy(theta), qubits: [0, 2], column: 1)

        let direct = QuantumCircuit(qubits: 3)
        direct.h(0)
        direct.h(2)
        direct.ryy(theta, 0, 2)

        expectStatesMatch(builder.buildCircuit().run(), direct.run())
    }

    @Test("RZZ replay matches the cx;rz;cx identity")
    func rzzMatchesIdentity() {
        let theta = 0.7
        let builder = CircuitBuilder(qubitCount: 3)
        builder.place(.h, qubits: [0], column: 0)
        builder.place(.h, qubits: [2], column: 0)
        builder.place(.rzz(theta), qubits: [0, 2], column: 1)

        let direct = QuantumCircuit(qubits: 3)
        direct.h(0)
        direct.h(2)
        direct.cx(0, 2)
        direct.rz(theta, 2)
        direct.cx(0, 2)

        expectStatesMatch(builder.buildCircuit().run(), direct.run())
    }

    @Test("updateTheta changes an RZZ gate's angle")
    func updateThetaChangesRZZAngle() {
        let builder = CircuitBuilder(qubitCount: 2)
        builder.place(.rzz(0.1), qubits: [0, 1], column: 0)
        let id = builder.gates[0].id

        builder.updateTheta(id: id, theta: 1.23)

        #expect(builder.gates[0].kind.theta == 1.23)
        #expect(builder.gates[0].kind.qubitSpan == 2)
        #expect(builder.gates[0].kind.isControlled == false)
    }

    @Test("placing an RZZ on an occupied qubit is rejected")
    func rzzOccupiedCellRejected() {
        let builder = CircuitBuilder(qubitCount: 2)
        #expect(builder.place(.h, qubits: [0], column: 0))
        #expect(!builder.place(.rzz(0.5), qubits: [0, 1], column: 0))
        #expect(builder.gates.count == 1)
    }

    @Test("a CX with a second control replays as CCX")
    func twoControlsMatchCCX() throws {
        let builder = CircuitBuilder(qubitCount: 3)
        builder.place(.x, qubits: [0], column: 0)
        builder.place(.x, qubits: [1], column: 0)
        builder.place(.cx, qubits: [0, 2], column: 1)
        let id = try #require(builder.gates.last?.id)
        #expect(builder.addControl(id: id, qubit: 1))
        #expect(builder.gates.last?.qubits == [0, 1, 2])

        let direct = QuantumCircuit(qubits: 3)
        direct.x(0)
        direct.x(1)
        direct.ccx(0, 1, 2)
        expectStatesMatch(builder.buildCircuit().run(), direct.run())
    }

    @Test("three controls on non-adjacent qubits replay as MCX")
    func threeControlsMatchMCX() throws {
        let builder = CircuitBuilder(qubitCount: 4)
        for qubit in [0, 2, 3] { builder.place(.x, qubits: [qubit], column: 0) }
        builder.place(.cx, qubits: [3, 1], column: 1)
        let id = try #require(builder.gates.last?.id)
        #expect(builder.addControl(id: id, qubit: 0))
        #expect(builder.addControl(id: id, qubit: 2))
        #expect(builder.gates.last?.controls == [3, 0, 2])
        #expect(builder.gates.last?.target == 1)

        let direct = QuantumCircuit(qubits: 4)
        for qubit in [0, 2, 3] { direct.x(qubit) }
        direct.mcx([3, 0, 2], 1)
        expectStatesMatch(builder.buildCircuit().run(), direct.run())
    }

    @Test("addControl rejects occupied, out-of-range, duplicate and non-CX cases")
    func addControlRejections() throws {
        let builder = CircuitBuilder(qubitCount: 4)
        builder.place(.h, qubits: [1], column: 0)
        builder.place(.cx, qubits: [0, 2], column: 0)
        builder.place(.h, qubits: [0], column: 1)
        let cxID = try #require(builder.gates.first { $0.kind == .cx }?.id)
        let hID = try #require(builder.gates.last?.id)

        #expect(!builder.addControl(id: cxID, qubit: 1))
        #expect(!builder.addControl(id: cxID, qubit: 9))
        #expect(!builder.addControl(id: cxID, qubit: 0))
        #expect(!builder.addControl(id: hID, qubit: 3))
        #expect(builder.canAddControl(id: cxID))
        #expect(!builder.canAddControl(id: hID))
        #expect(builder.gates.first { $0.id == cxID }?.qubits == [0, 2])
    }

    @Test("removeLastControl removes the newest control and stops at one")
    func removeLastControl() throws {
        let builder = CircuitBuilder(qubitCount: 3)
        builder.place(.cx, qubits: [0, 2], column: 0)
        let id = try #require(builder.gates.first?.id)
        builder.addControl(id: id, qubit: 1)

        builder.removeLastControl(id: id)
        #expect(builder.gates.first?.qubits == [0, 2])

        builder.removeLastControl(id: id)
        #expect(builder.gates.first?.qubits == [0, 2])
    }

    @Test("shrinking qubitCount drops a CX whose added control no longer fits")
    func shrinkDropsMultiControlGate() throws {
        let builder = CircuitBuilder(qubitCount: 4)
        builder.place(.cx, qubits: [0, 1], column: 0)
        let id = try #require(builder.gates.first?.id)
        builder.addControl(id: id, qubit: 3)

        builder.qubitCount = 3

        #expect(builder.gates.isEmpty)
    }

    @Test("CZ on non-adjacent qubits matches H-CX-H on the target")
    func czMatchesHCXH() {
        let builder = CircuitBuilder(qubitCount: 3)
        builder.place(.h, qubits: [0], column: 0)
        builder.place(.h, qubits: [2], column: 0)
        builder.place(.cz, qubits: [0, 2], column: 1)

        let direct = QuantumCircuit(qubits: 3)
        direct.h(0)
        direct.h(2)
        direct.h(2)
        direct.cx(0, 2)
        direct.h(2)
        expectStatesMatch(builder.buildCircuit().run(), direct.run())
    }

    @Test("a CZ with added controls replays as MCZ and reverts on removeLastControl")
    func czMultiControl() throws {
        let builder = CircuitBuilder(qubitCount: 3)
        for qubit in 0..<3 { builder.place(.h, qubits: [qubit], column: 0) }
        builder.place(.cz, qubits: [0, 2], column: 1)
        let id = try #require(builder.gates.last?.id)
        #expect(builder.addControl(id: id, qubit: 1))
        #expect(builder.gates.last?.qubits == [0, 1, 2])

        let ccz = QuantumCircuit(qubits: 3)
        for qubit in 0..<3 { ccz.h(qubit) }
        ccz.h(2)
        ccz.ccx(0, 1, 2)
        ccz.h(2)
        expectStatesMatch(builder.buildCircuit().run(), ccz.run())

        builder.removeLastControl(id: id)
        let cz = QuantumCircuit(qubits: 3)
        for qubit in 0..<3 { cz.h(qubit) }
        cz.cz(0, 2)
        expectStatesMatch(builder.buildCircuit().run(), cz.run())
    }

    @Test("SWAP moves an X excitation between non-adjacent qubits")
    func swapMovesExcitation() {
        let builder = CircuitBuilder(qubitCount: 3)
        builder.place(.x, qubits: [0], column: 0)
        builder.place(.swap, qubits: [0, 2], column: 1)

        let state = builder.buildCircuit().run()
        #expect(abs(state[1].magnitude - 1) < 1e-9)
    }

    @Test("CZ and SWAP reject occupied cells and drop on qubit-count shrink")
    func czSwapPlacementRules() {
        let builder = CircuitBuilder(qubitCount: 3)
        builder.place(.h, qubits: [1], column: 0)
        #expect(!builder.place(.cz, qubits: [0, 1], column: 0))
        #expect(!builder.place(.swap, qubits: [1, 2], column: 0))
        #expect(builder.place(.cz, qubits: [0, 2], column: 1))
        #expect(builder.place(.swap, qubits: [0, 1], column: 2))

        builder.qubitCount = 2
        #expect(builder.gates.map(\.kind) == [.h, .swap])
    }
}

/// Compares two state vectors entrywise within a fixed tolerance.
private func expectStatesMatch(_ lhs: StateVector, _ rhs: StateVector, tolerance: Double = 1e-9) {
    #expect(lhs.dimension == rhs.dimension)
    for i in 0..<lhs.dimension {
        #expect((lhs[i] - rhs[i]).magnitude < tolerance)
    }
}
