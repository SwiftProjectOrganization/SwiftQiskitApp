//
//  GateTileView.swift
//  SwiftQiskitApp
//
//  A single placed gate. Takes only the gate value + closures, not the whole
//  CircuitBuilder, so it only redraws when its own data changes.
//

import SwiftUI

struct GateTileView: View {
    let gate: PlacedGate
    let isSelected: Bool
    var onSelect: () -> Void
    var onDelete: () -> Void
    var onThetaChange: (Double) -> Void
    /// True for a CX's ⊕ target, drawn by this same tile so it shares the popover and menu.
    var isTarget = false
    var canAddControl = false
    var onAddControl: () -> Void = {}
    var onRemoveControl: () -> Void = {}

    @State private var showingParameters = false
    @State private var showingControls = false

    private var thetaBinding: Binding<Double> {
        Binding(
            get: { gate.kind.theta ?? 0 },
            set: { onThetaChange($0) }
        )
    }

    // Every single-qubit gate is boxed, as is each qubit of a symmetric
    // two-qubit rotation (RZZ/RXX/RYY); only CX's control dot is unboxed.
    private var isBoxed: Bool { !gate.kind.isControlled }

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(boxedBackground)
            .clipShape(isBoxed ? RoundedRectangle(cornerRadius: 6) : RoundedRectangle(cornerRadius: 0))
            .overlay(isBoxed ? boxedSelectionOverlay : nil)
            .contentShape(Rectangle())
            .onTapGesture {
                onSelect()
                if gate.kind.isParameterized {
                    showingParameters = true
                }
                if gate.kind.isControlled {
                    showingControls = true
                }
            }
            .popover(isPresented: $showingParameters) {
                ParameterPopover(theta: thetaBinding)
            }
            .popover(isPresented: $showingControls) {
                ControlsPopover(
                    count: gate.controls.count,
                    canAdd: canAddControl,
                    onAdd: {
                        showingControls = false
                        onAddControl()
                    },
                    onRemove: onRemoveControl
                )
            }
            .contextMenu {
                Button("Delete", role: .destructive, action: onDelete)
            }
    }

    @ViewBuilder
    private var boxedBackground: some View {
        if isBoxed {
            ZStack {
                RoundedRectangle(cornerRadius: 6).fill(.background)
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.accentColor.opacity(0.25) : Color.accentColor.opacity(0.12))
            }
        }
    }

    private var boxedSelectionOverlay: some View {
        RoundedRectangle(cornerRadius: 6)
            .stroke(isSelected ? Color.accentColor : .clear, lineWidth: 1.5)
    }

    @ViewBuilder
    private var content: some View {
        if gate.kind.isControlled && isTarget {
            CXTargetView()
        } else if gate.kind.isControlled {
            Circle()
                .fill(Color.accentColor)
                .frame(width: 14, height: 14)
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.accentColor : .clear, lineWidth: 2)
                        .frame(width: 22, height: 22)
                )
        } else {
            Text(gate.kind.symbol)
                .font(.system(.body, design: .monospaced, weight: .semibold))
        }
    }
}

/// The target-qubit half of a placed CX gate (the control's row shows the dot via GateTileView).
struct CXTargetView: View {
    var body: some View {
        Circle()
            .stroke(Color.accentColor, lineWidth: 2)
            .overlay(
                ZStack {
                    Rectangle().fill(Color.accentColor).frame(width: 12, height: 2)
                    Rectangle().fill(Color.accentColor).frame(width: 2, height: 12)
                }
            )
            .frame(width: 20, height: 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EmptyCellView: View {
    let isPendingControl: Bool
    var isControlCandidate = false

    var body: some View {
        Circle()
            .stroke(
                isControlCandidate ? Color.accentColor : Color.orange,
                style: StrokeStyle(lineWidth: 2, dash: isControlCandidate ? [3, 3] : [])
            )
            .opacity(isPendingControl || isControlCandidate ? 1 : 0)
            .frame(width: 20, height: 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
    }
}
