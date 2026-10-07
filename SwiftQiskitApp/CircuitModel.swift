//
//  CircuitModel.swift
//  SwiftQiskitApp
//
//  Front-end model for interactively constructing a QuantumCircuit.
//  QuantumCircuit itself only records the resulting full-dimension matrices
//  (no gate identity/qubit metadata), so the builder keeps its own record of
//  placed gates and replays them onto a fresh QuantumCircuit to run.
//

import Foundation
import SwiftQiskit

// MARK: - GateKind

public enum GateKind: Equatable, Hashable {
    case h, x, y, z, s, sdg, t, tdg
    case p(Double)
    case rx(Double)
    case ry(Double)
    case rz(Double)
    case cx
    case rzz(Double)
    case rxx(Double)
    case ryy(Double)

    public var symbol: String {
        switch self {
        case .h: return "H"
        case .x: return "X"
        case .y: return "Y"
        case .z: return "Z"
        case .s: return "S"
        case .sdg: return "S†"
        case .t: return "T"
        case .tdg: return "T†"
        case .p: return "P"
        case .rx: return "RX"
        case .ry: return "RY"
        case .rz: return "RZ"
        case .cx: return "CX"
        case .rzz: return "RZZ"
        case .rxx: return "RXX"
        case .ryy: return "RYY"
        }
    }

    /// Number of qubits this gate occupies (1 for single-qubit gates, 2 for the
    /// two-qubit gates: CX and the RZZ/RXX/RYY rotations).
    public var qubitSpan: Int {
        switch self {
        case .cx, .rzz, .rxx, .ryy: return 2
        default: return 1
        }
    }

    /// True only for CX: its two qubits play distinct roles (control vs. target),
    /// unlike RZZ/RXX/RYY, whose two qubits are symmetric.
    public var isControlled: Bool {
        if case .cx = self { return true }
        return false
    }

    public var isParameterized: Bool {
        theta != nil
    }

    public var theta: Double? {
        switch self {
        case .p(let t), .rx(let t), .ry(let t), .rz(let t),
             .rzz(let t), .rxx(let t), .ryy(let t):
            return t
        default: return nil
        }
    }

    /// Returns the same gate with a new angle; a no-op for non-parameterized gates.
    public func withTheta(_ newTheta: Double) -> GateKind {
        switch self {
        case .p: return .p(newTheta)
        case .rx: return .rx(newTheta)
        case .ry: return .ry(newTheta)
        case .rz: return .rz(newTheta)
        case .rzz: return .rzz(newTheta)
        case .rxx: return .rxx(newTheta)
        case .ryy: return .ryy(newTheta)
        default: return self
        }
    }
}

// MARK: - PlacedGate

public struct PlacedGate: Identifiable, Equatable {
    public let id: UUID
    public var kind: GateKind
    public var qubits: [Int]
    public var column: Int

    public init(id: UUID = UUID(), kind: GateKind, qubits: [Int], column: Int) {
        self.id = id
        self.kind = kind
        self.qubits = qubits
        self.column = column
    }

    /// For a CX: every qubit but the last. A plain CX has one control.
    public var controls: [Int] { Array(qubits.dropLast()) }

    /// For a CX: the target, which is always stored last.
    public var target: Int? { qubits.last }
}

// MARK: - CircuitBuilder

@MainActor
@Observable
public final class CircuitBuilder {

    public static let minQubits = 1
    public static let maxQubits = 8

    public var qubitCount: Int {
        didSet {
            let clamped = min(max(qubitCount, Self.minQubits), Self.maxQubits)
            if clamped != qubitCount {
                qubitCount = clamped
                return
            }
            gates.removeAll { gate in gate.qubits.contains { $0 >= qubitCount } }
            lastResult = nil
        }
    }

    public var gates: [PlacedGate] = []

    public var shots: Int = 1000
    public var lastResult: SimulationResult?

    public init(qubitCount: Int = 2) {
        self.qubitCount = min(max(qubitCount, Self.minQubits), Self.maxQubits)
    }

    /// One past the highest occupied column (0 if empty).
    public func columnCount() -> Int {
        (gates.map(\.column).max() ?? -1) + 1
    }

    public func gate(atColumn column: Int, qubit: Int) -> PlacedGate? {
        gates.first { $0.column == column && $0.qubits.contains(qubit) }
    }

    public func isOccupied(column: Int, qubit: Int) -> Bool {
        gate(atColumn: column, qubit: qubit) != nil
    }

    /// Places a gate if every target qubit is in range and free at that column.
    @discardableResult
    public func place(_ kind: GateKind, qubits: [Int], column: Int) -> Bool {
        guard qubits.allSatisfy({ $0 >= 0 && $0 < qubitCount }) else { return false }
        guard qubits.allSatisfy({ !isOccupied(column: column, qubit: $0) }) else { return false }
        gates.append(PlacedGate(kind: kind, qubits: qubits, column: column))
        return true
    }

    public func remove(id: UUID) {
        gates.removeAll { $0.id == id }
    }

    /// True if some qubit is still free in the gate's column, so a control could be added.
    public func canAddControl(id: UUID) -> Bool {
        guard let gate = gates.first(where: { $0.id == id }), gate.kind.isControlled else { return false }
        return (0..<qubitCount).contains { !isOccupied(column: gate.column, qubit: $0) }
    }

    /// Adds `qubit` as a further control of a CX. The target stays last, so the
    /// new control is inserted just before it.
    @discardableResult
    public func addControl(id: UUID, qubit: Int) -> Bool {
        guard let index = gates.firstIndex(where: { $0.id == id }),
              gates[index].kind.isControlled,
              qubit >= 0, qubit < qubitCount,
              !isOccupied(column: gates[index].column, qubit: qubit) else { return false }
        gates[index].qubits.insert(qubit, at: gates[index].qubits.count - 1)
        return true
    }

    /// Removes the most recently added control; a no-op when only one control is left.
    public func removeLastControl(id: UUID) {
        guard let index = gates.firstIndex(where: { $0.id == id }),
              gates[index].kind.isControlled,
              gates[index].qubits.count > 2 else { return }
        gates[index].qubits.remove(at: gates[index].qubits.count - 2)
    }

    public func updateTheta(id: UUID, theta: Double) {
        guard let index = gates.firstIndex(where: { $0.id == id }) else { return }
        gates[index].kind = gates[index].kind.withTheta(theta)
    }

    public func clear() {
        gates.removeAll()
        lastResult = nil
    }

    /// Runs `shots` measurements on the current circuit and stores the result.
    public func measure() {
        lastResult = buildCircuit().measure(shots: shots)
    }

    /// Replays the placed gates, in column order, onto a fresh QuantumCircuit.
    public func buildCircuit() -> QuantumCircuit {
        buildCircuit(throughColumn: columnCount())
    }

    /// Replays only the gates in columns `0...throughColumn`. Pass -1 for the
    /// initial (empty) circuit.
    public func buildCircuit(throughColumn: Int) -> QuantumCircuit {
        let circuit = QuantumCircuit(qubits: qubitCount)
        for gate in gates.filter({ $0.column <= throughColumn }).sorted(by: { $0.column < $1.column }) {
            apply(gate, to: circuit)
        }
        return circuit
    }

    private func apply(_ gate: PlacedGate, to circuit: QuantumCircuit) {
        switch gate.kind {
        case .h: circuit.h(gate.qubits[0])
        case .x: circuit.x(gate.qubits[0])
        case .y: circuit.y(gate.qubits[0])
        case .z: circuit.z(gate.qubits[0])
        case .s: circuit.s(gate.qubits[0])
        case .sdg: circuit.sdg(gate.qubits[0])
        case .t: circuit.t(gate.qubits[0])
        case .tdg: circuit.tdg(gate.qubits[0])
        case .p(let theta): circuit.p(theta, gate.qubits[0])
        case .rx(let theta): circuit.rx(theta, gate.qubits[0])
        case .ry(let theta): circuit.ry(theta, gate.qubits[0])
        case .rz(let theta): circuit.rz(theta, gate.qubits[0])
        case .cx:
            guard let target = gate.target else { return }
            if gate.controls.count == 1 {
                circuit.cx(gate.controls[0], target)
            } else {
                circuit.mcx(gate.controls, target)
            }
        case .rzz(let theta): circuit.rzz(theta, gate.qubits[0], gate.qubits[1])
        case .rxx(let theta): circuit.rxx(theta, gate.qubits[0], gate.qubits[1])
        case .ryy(let theta): circuit.ryy(theta, gate.qubits[0], gate.qubits[1])
        }
    }
}
