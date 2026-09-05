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
                HStack {
                    Text("Circuit")
                        .font(.headline)

                    Spacer()

                    Stepper(
                        "Qubits: \(builder.qubitCount)",
                        value: Binding(
                            get: { builder.qubitCount },
                            set: { builder.qubitCount = $0 }
                        ),
                        in: CircuitBuilder.minQubits...CircuitBuilder.maxQubits
                    )
                    .frame(width: 160)

                    Button("Clear") { builder.clear() }

                    Button("Display") { showingDisplay = true }
                }

                CircuitGridView(builder: builder, armedGate: $armedGate)
                    .frame(maxHeight: .infinity)
            }
            .padding()

            ResultsView(builder: builder)
                .frame(width: 320)
                .padding()
        }
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
}

#Preview {
    CircuitBuilderView(builder: CircuitBuilder(qubitCount: 2), armedGate: .constant(nil))
        .frame(width: 900, height: 600)
}
