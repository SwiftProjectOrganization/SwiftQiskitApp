//
//  CircuitBuilderView.swift
//  SwiftQiskitApp
//
//  Regular-width layout: gate palette, circuit grid, and (on wide windows)
//  an always-visible results/measurement pane. Used on macOS and iPad (any
//  horizontalSizeClass other than .compact). Below widePaneThreshold — the
//  unfolded iPhone Duo, Split View, or a narrowed Mac window — the pane
//  hides and the layout matches CompactBuilderView's main view instead,
//  with Results/Measurement/Display reachable via the bottom bar's sheets
//  (which stay available at every width, e.g. for a roomier look at a
//  many-qubit state vector). State is owned by ContentView so
//  CompactBuilderView can share the same builder and armed gate.
//

import SwiftUI
import SwiftQiskitCore

struct CircuitBuilderView: View {
    var builder: CircuitBuilder
    @Binding var armedGate: GateKind?

    @State private var showingResults = false
    @State private var showingMeasurement = false
    @State private var showingDisplay = false
    @State private var availableWidth: CGFloat = .infinity

    /// Below this width, palette + grid + results pane no longer leaves the
    /// grid a comfortable minimum. Narrower configurations (Split View, a
    /// narrowed Mac window) use the palette+grid-only layout instead, with
    /// Results/Measure reachable via the bottom bar.
    private static let widePaneThreshold: CGFloat = 672

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

            if availableWidth >= Self.widePaneThreshold {
                VStack(alignment: .leading, spacing: 12) {
                    ResultsView(builder: builder)
                    Divider()
                    MeasurementView(builder: builder)
                }
                .frame(width: 320)
                .padding()
            }
        }
        .onGeometryChange(for: CGFloat.self, of: { $0.size.width }) { availableWidth = $0 }
        .safeAreaBar(edge: .bottom) { bottomBar }
        .sheet(isPresented: $showingResults) {
            NavigationStack {
                ResultsView(builder: builder)
                    .padding()
                    .navigationTitle("Results")
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { showingResults = false }
                        }
                    }
            }
        }
        .sheet(isPresented: $showingMeasurement) {
            NavigationStack {
                MeasurementView(builder: builder)
                    .padding()
                    .navigationTitle("Measurement")
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { showingMeasurement = false }
                        }
                    }
            }
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

    /// Floating Liquid Glass bar pinned to the bottom of the window. A single
    /// GlassEffectContainer keeps the qubit stepper and the four actions
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
                Button("Results") { showingResults = true }
                Button("Measure") {
                    builder.measure()
                    showingMeasurement = true
                }
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
