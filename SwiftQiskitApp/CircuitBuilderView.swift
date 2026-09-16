//
//  CircuitBuilderView.swift
//  SwiftQiskitApp
//
//  Regular-width layout: gate palette, circuit grid, and live results side by
//  side. Used on macOS and iPad (any horizontalSizeClass other than .compact).
//  State is owned by ContentView so CompactBuilderView can share the same
//  builder and armed gate.
//

import SwiftUI
import SwiftQiskitCore

struct CircuitBuilderView: View {
    var builder: CircuitBuilder
    @Binding var armedGate: GateKind?

    @State private var showingDisplay = false

    var body: some View {
        HStack(spacing: 16) {
            GatePaletteView(armedGate: $armedGate)
                .frame(width: 220)
                .padding()
                .background(Color.gray.opacity(0.1))

            VStack(alignment: .leading, spacing: 12) {
                Text("Circuit")
                    .font(.headline)

                CircuitGridView(builder: builder, armedGate: $armedGate)
                    .frame(maxHeight: .infinity)
            }
            .padding()

            ResultsView(builder: builder)
                .frame(width: 320)
                .padding()
        }
        .safeAreaBar(edge: .bottom) { bottomBar }
        .sheet(isPresented: $showingDisplay) {
            NavigationStack {
                BlochDisplayView(builder: builder)
                    .padding()
                    .navigationTitle("Bloch Spheres")
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { showingDisplay = false }
                        }
                    }
            }
        }
    }

    /// Floating Liquid Glass bar pinned to the bottom of the window. A single
    /// GlassEffectContainer keeps the qubit stepper and the two actions
    /// rendering as one capsule.
    private var bottomBar: some View {
        GlassEffectContainer(spacing: 12) {
            HStack(spacing: 12) {
                Stepper(
                    "Qubits: \(builder.qubitCount)",
                    value: Binding(
                        get: { builder.qubitCount },
                        set: { builder.qubitCount = $0 }
                    ),
                    in: CircuitBuilder.minQubits...CircuitBuilder.maxQubits
                )
                .fixedSize()

                Divider()
                    .frame(height: 20)
                    .padding(.horizontal, 6)

                Button("Clear") { builder.clear() }
                Button("Display") { showingDisplay = true }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .glassEffect(.regular.interactive())
        }
    }
}

#Preview {
    CircuitBuilderView(builder: CircuitBuilder(qubitCount: 2), armedGate: .constant(nil))
        .frame(width: 900, height: 600)
}
