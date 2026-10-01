//
//  BlochDisplayView.swift
//  SwiftQiskitApp
//
//  2D Bloch-sphere view of the circuit: either the final state of every
//  qubit, one qubit's state after each column ("Steps"), a tensor-network
//  diagram of the circuit ("Tensor"), or an orbitable 3D sphere. Presented
//  as a sheet from both CircuitBuilderView and CompactBuilderView,
//  mirroring how ResultsView is presented.
//

import SwiftUI
import SwiftQiskit
import SwiftQiskitViews

struct BlochDisplayView: View {
    var builder: CircuitBuilder

    private enum Mode: String, CaseIterable, Identifiable {
        case final = "Final"
        case steps = "Steps"
        case tensor = "Tensor"
        case threeD = "3D"
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

            ScrollView(scrollAxes) {
                switch mode {
                case .final:
                    finalGrid
                case .steps:
                    stepsRow
                case .tensor:
                    tensorCard
                case .threeD:
                    threeDCard
                }
            }
        }
        .onChange(of: builder.qubitCount) {
            selectedQubit = min(selectedQubit, builder.qubitCount - 1)
        }
    }

    private var scrollAxes: Axis.Set {
        switch mode {
        case .steps: .horizontal
        case .tensor: [.horizontal, .vertical]
        case .final, .threeD: .vertical
        }
    }

    private var finalGrid: some View {
        let state = builder.buildCircuit().run()
        let columns = [GridItem(.adaptive(minimum: 160), spacing: 20)]
        return GlassEffectContainer(spacing: 20) {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(0..<builder.qubitCount, id: \.self) { qubit in
                    sphereCard(label: "q\(qubit)", bloch: BlochVector(state, qubit: qubit))
                }
            }
        }
    }

    @ViewBuilder
    private var qubitPicker: some View {
        if builder.qubitCount > 1 {
            Picker("Qubit", selection: $selectedQubit) {
                ForEach(0..<builder.qubitCount, id: \.self) { qubit in
                    Text("q\(qubit)").tag(qubit)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var stepsRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            qubitPicker

            GlassEffectContainer(spacing: 20) {
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

    private var tensorCard: some View {
        TensorNetworkView(TensorNetwork(builder.buildCircuit()))
            .padding()
            .glassEffect(in: .rect(cornerRadius: 16))
    }

    private var threeDCard: some View {
        let state = builder.buildCircuit().run()
        return VStack(alignment: .leading, spacing: 12) {
            qubitPicker

            Bloch3DSphereView(label: "q\(selectedQubit)", bloch: BlochVector(state, qubit: selectedQubit))
                .padding()
                .glassEffect(in: .rect(cornerRadius: 16))
        }
    }

    private func sphereCard(label: String, bloch: BlochVector) -> some View {
        BlochSphereView(label: label, bloch: bloch)
            .padding()
            .glassEffect(in: .rect(cornerRadius: 16))
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
