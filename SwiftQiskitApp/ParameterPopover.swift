//
//  ParameterPopover.swift
//  SwiftQiskitApp
//
//  Angle editor for a placed P/RX/RY/RZ/RZZ/RXX/RYY gate.
//

import SwiftUI

struct ParameterPopover: View {
    @Binding var theta: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("θ = \(theta, format: .number.precision(.fractionLength(3)))")
                .font(.caption.monospaced())

            Slider(value: $theta, in: 0...(2 * .pi))
                .frame(width: 200)
        }
        .padding()
        .presentationCompactAdaptation(.popover)
    }
}

/// Control-count editor for a placed CX. `+` asks the grid to enter add-control
/// mode; `−` removes the most recently added control.
struct ControlsPopover: View {
    let count: Int
    let canAdd: Bool
    var onAdd: () -> Void
    var onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Stepper("Controls: \(count)") {
                if canAdd { onAdd() }
            } onDecrement: {
                if count > 1 { onRemove() }
            }
            .frame(width: 200)

            Text("After +, tap a free qubit in this column.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .presentationCompactAdaptation(.popover)
    }
}
