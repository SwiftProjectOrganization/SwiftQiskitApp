//
//  CompactBuilderView.swift
//  SwiftQiskitApp
//
//  iPhone (horizontally-compact) layout: the circuit grid fills the screen
//  with a horizontally-scrolling gate strip pinned below it. Results (state
//  vector) and Measurement (shots + histogram) are separate sheets rather
//  than a side panel. Clear/Results/Measure/Display all live together in the
//  bottom bar.
//

#if os(iOS)
import SwiftUI
import SwiftQiskit

struct CompactBuilderView: View {
    var builder: CircuitBuilder
    @Binding var armedGate: GateKind?

    @State private var showingResults = false
    @State private var showingMeasurement = false
    @State private var showingDisplay = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                CircuitGridView(builder: builder, armedGate: $armedGate)
                    .frame(maxHeight: .infinity)

                Divider()

                GatePaletteView(armedGate: $armedGate, layout: .strip)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
            }
            .navigationTitle("Circuit")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Stepper(
                        "Qubits: \(builder.qubitCount)",
                        value: Binding(
                            get: { builder.qubitCount },
                            set: { builder.qubitCount = $0 }
                        ),
                        in: CircuitBuilder.minQubits...CircuitBuilder.maxQubits
                    )
                    .fixedSize()
                }

                if #available(iOS 27.1, *) {
                    actionItems.axisBehavior(.verticalPreferred)
                } else {
                    actionItems
                }
            }
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
    }

    @ToolbarContentBuilder
    private var actionItems: some ToolbarContent {
        // No explicit placement (defaults to `.automatic`): a `.bottomBar`
        // placement makes the system anchor a `.verticalPreferred` capsule
        // near the bottom, overlapping the gate strip. Left `.automatic`,
        // it anchors top-right instead, clear of everything else on screen.
        ToolbarItemGroup {
            Button("Clear", systemImage: "eraser") { builder.clear() }
            Button("Results", systemImage: "list.bullet") { showingResults = true }
            Button("Measure", systemImage: "chart.bar") {
                builder.measure()
                showingMeasurement = true
            }
            Button("Display", systemImage: "globe") { showingDisplay = true }
        }
    }
}

#Preview {
    CompactBuilderView(builder: CircuitBuilder(qubitCount: 2), armedGate: .constant(nil))
}
#endif
