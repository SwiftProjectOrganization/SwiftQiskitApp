//
//  CircuitGridView.swift
//  SwiftQiskitApp
//
//  Renders the circuit as a grid of qubit wires x columns, and handles
//  tap-to-place: arm a gate in the palette, then tap an empty cell. Two-qubit
//  gates need two taps in the same column — CX distinguishes control from
//  target, while RZZ/RXX/RYY treat both taps the same way.
//

import SwiftUI

struct CircuitGridView: View {
    var builder: CircuitBuilder
    @Binding var armedGate: GateKind?

    @State private var pendingControl: (column: Int, qubit: Int)?
    @State private var selectedGateID: UUID?
    /// Set while the next tap should add a control to this CX.
    @State private var addingControlTo: UUID?

    private let layout = CircuitLayout()

    var body: some View {
        let columns = max(builder.columnCount() + 1, 4)
        let size = layout.canvasSize(columns: columns, qubits: builder.qubitCount)

        ScrollView([.horizontal, .vertical]) {
            ZStack(alignment: .topLeading) {
                CircuitWiresView(
                    gates: builder.gates,
                    qubitCount: builder.qubitCount,
                    columns: columns,
                    layout: layout
                )

                ForEach(0..<builder.qubitCount, id: \.self) { qubit in
                    Text("q\(qubit)")
                        .font(.caption.monospaced())
                        .position(x: layout.padding + layout.labelWidth / 2, y: layout.wireY(qubit))
                }

                ForEach(0..<columns, id: \.self) { column in
                    ForEach(0..<builder.qubitCount, id: \.self) { qubit in
                        cell(column: column, qubit: qubit)
                    }
                }
            }
            .frame(width: size.width, height: size.height)
        }
        .onChange(of: armedGate) {
            pendingControl = nil
            addingControlTo = nil
        }
    }

    @ViewBuilder
    private func cell(column: Int, qubit: Int) -> some View {
        let point = layout.center(column: column, qubit: qubit)

        if let gate = builder.gate(atColumn: column, qubit: qubit) {
            occupiedCell(gate: gate, qubit: qubit)
                .frame(width: layout.cellSize, height: layout.cellSize)
                .position(point)
        } else {
            EmptyCellView(
                isPendingControl: pendingControl?.column == column && pendingControl?.qubit == qubit,
                isControlCandidate: isControlCandidate(column: column)
            )
                .frame(width: layout.cellSize, height: layout.cellSize)
                .position(point)
                .onTapGesture { handleTap(column: column, qubit: qubit) }
        }
    }

    @ViewBuilder
    private func occupiedCell(gate: PlacedGate, qubit: Int) -> some View {
        // Every qubit of a placed gate shows a GateTileView. A CX's target
        // (always its last qubit) draws the ⊕ glyph; both it and the control
        // dots open the controls popover, and Delete lives in the context menu.
        GateTileView(
            gate: gate,
            isSelected: selectedGateID == gate.id,
            onSelect: { selectedGateID = gate.id },
            onDelete: { deleteGate(gate) },
            onThetaChange: { builder.updateTheta(id: gate.id, theta: $0) },
            isTarget: gate.kind.isControlled && qubit == gate.target,
            canAddControl: builder.canAddControl(id: gate.id),
            onAddControl: { addingControlTo = gate.id },
            onRemoveControl: { builder.removeLastControl(id: gate.id) }
        )
    }

    private func deleteGate(_ gate: PlacedGate) {
        builder.remove(id: gate.id)
        if selectedGateID == gate.id { selectedGateID = nil }
        if addingControlTo == gate.id { addingControlTo = nil }
    }

    /// True for free cells in the column of the CX that is waiting for a new control.
    private func isControlCandidate(column: Int) -> Bool {
        guard let id = addingControlTo,
              let gate = builder.gates.first(where: { $0.id == id }) else { return false }
        return gate.column == column
    }

    private func handleTap(column: Int, qubit: Int) {
        // Add-control mode: one tap either adds the control or cancels the mode.
        if let id = addingControlTo {
            builder.addControl(id: id, qubit: qubit)
            addingControlTo = nil
            return
        }

        guard let armed = armedGate else { return }

        guard armed.qubitSpan == 2 else {
            builder.place(armed, qubits: [qubit], column: column)
            return
        }

        guard let pending = pendingControl else {
            pendingControl = (column, qubit)
            return
        }

        guard pending.column == column, pending.qubit != qubit else {
            pendingControl = (column, qubit)
            return
        }

        if builder.place(armed, qubits: [pending.qubit, qubit], column: column) {
            pendingControl = nil
        }
    }
}

#Preview {
    let builder = CircuitBuilder(qubitCount: 3)
    builder.place(.h, qubits: [0], column: 0)
    builder.place(.rx(.pi / 2), qubits: [1], column: 0)
    builder.place(.cx, qubits: [0, 2], column: 1)
    builder.place(.rzz(.pi / 2), qubits: [0, 2], column: 2)

    return CircuitGridView(builder: builder, armedGate: .constant(nil))
        .frame(width: 500, height: 300)
}
