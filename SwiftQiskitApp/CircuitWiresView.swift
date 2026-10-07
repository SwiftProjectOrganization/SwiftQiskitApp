//
//  CircuitWiresView.swift
//  SwiftQiskitApp
//
//  Background layer of the circuit diagram: one horizontal wire per qubit,
//  plus a vertical connector between any two-qubit gate's two qubits (CX's
//  control/target, or an RZZ/RXX/RYY rotation's symmetric pair). Drawn behind
//  the interactive gate layer in CircuitGridView, so a connector that passes
//  through an intervening qubit's wire also passes behind any gate placed
//  there in the same column — matching standard circuit-diagram style.
//

import SwiftUI

struct CircuitWiresView: View {
    let gates: [PlacedGate]
    let qubitCount: Int
    let columns: Int
    let layout: CircuitLayout

    var body: some View {
        Canvas { context, _ in
            for qubit in 0..<qubitCount {
                var path = Path()
                let y = layout.wireY(qubit)
                let range = layout.wireXRange(columns: columns)
                path.move(to: CGPoint(x: range.lowerBound, y: y))
                path.addLine(to: CGPoint(x: range.upperBound, y: y))
                context.stroke(path, with: .color(.secondary.opacity(0.5)), lineWidth: 1)
            }

            for gate in gates where gate.qubits.count >= 2 {
                guard let top = gate.qubits.min(), let bottom = gate.qubits.max() else { continue }
                let start = layout.center(column: gate.column, qubit: top)
                let end = layout.center(column: gate.column, qubit: bottom)
                var path = Path()
                path.move(to: start)
                path.addLine(to: end)
                context.stroke(path, with: .color(.accentColor), lineWidth: 2)
            }
        }
    }
}
