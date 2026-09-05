//
//  BlochDisplayView.swift
//  SwiftQiskitApp
//
//  2D Bloch-sphere view of the circuit: either the final state of every
//  qubit, or one qubit's state after each column ("Steps"). Presented as a
//  sheet from both CircuitBuilderView and CompactBuilderView, mirroring how
//  ResultsView is presented.
//

import SwiftUI
import SwiftQiskitCore

struct BlochDisplayView: View {
    var builder: CircuitBuilder

    private enum Mode: String, CaseIterable, Identifiable {
        case final = "Final"
        case steps = "Steps"
        var id: String { rawValue }
    }

    @State private var mode: Mode = .final
    @State private var selectedQubit = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Mode", selection: $mode) {
                ForEach(Mode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            ScrollView(mode == .final ? .vertical : .horizontal) {
                switch mode {
                case .final:
                    finalGrid
                case .steps:
                    stepsRow
                }
            }
        }
        .onChange(of: builder.qubitCount) {
            selectedQubit = min(selectedQubit, builder.qubitCount - 1)
        }
    }

    private var finalGrid: some View {
        let state = builder.buildCircuit().run()
        let columns = [GridItem(.adaptive(minimum: 160), spacing: 20)]
        return glassContainer(spacing: 20) {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(0..<builder.qubitCount, id: \.self) { qubit in
                    sphereCard(label: "q\(qubit)", bloch: BlochVector(state, qubit: qubit))
                }
            }
        }
    }

    private var stepsRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            if builder.qubitCount > 1 {
                Picker("Qubit", selection: $selectedQubit) {
                    ForEach(0..<builder.qubitCount, id: \.self) { qubit in
                        Text("q\(qubit)").tag(qubit)
                    }
                }
                .pickerStyle(.segmented)
            }

            glassContainer(spacing: 20) {
                LazyHStack(spacing: 20) {
                    sphereCard(
                        label: "Start",
                        bloch: BlochVector(builder.buildCircuit(throughColumn: -1).run(), qubit: selectedQubit)
                    )
                    ForEach(0..<builder.columnCount(), id: \.self) { column in
                        sphereCard(
                            label: "Col \(column + 1)",
                            bloch: BlochVector(builder.buildCircuit(throughColumn: column).run(), qubit: selectedQubit)
                        )
                    }
                }
            }
        }
    }

    /// `GlassEffectContainer` is unavailable on visionOS, which this app
    /// supports as a build-only target — fall back to no container there.
    @ViewBuilder
    private func glassContainer<Content: View>(
        spacing: CGFloat, @ViewBuilder content: () -> Content
    ) -> some View {
        #if os(visionOS)
        content()
        #else
        GlassEffectContainer(spacing: spacing) { content() }
        #endif
    }

    private func sphereCard(label: String, bloch: BlochVector) -> some View {
        let card = BlochSphereView(label: label, bloch: bloch)
            .padding()
        #if os(visionOS)
        return card
        #else
        return card.glassEffect(in: .rect(cornerRadius: 16))
        #endif
    }
}

#Preview {
    let builder = CircuitBuilder(qubitCount: 2)
    builder.place(.h, qubits: [0], column: 0)
    builder.place(.cx, qubits: [0, 1], column: 1)
    return BlochDisplayView(builder: builder)
        .padding()
        .frame(width: 500, height: 500)
}
