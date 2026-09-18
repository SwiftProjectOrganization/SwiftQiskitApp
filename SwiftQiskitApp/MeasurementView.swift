//
//  MeasurementView.swift
//  SwiftQiskitApp
//
//  On-demand shots measurement with a histogram. Split out of ResultsView so
//  the state vector and the measurement UI can be shown separately (a
//  dedicated sheet on iPhone; stacked in one pane on iPad/macOS).
//

import SwiftUI
import SwiftQiskitCore

struct MeasurementView: View {
    var builder: CircuitBuilder
    var showsMeasureButton: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Measurement")
                .font(.headline)

            Stepper(
                "Shots: \(builder.shots)",
                value: Binding(
                    get: { builder.shots },
                    set: { builder.shots = $0 }
                ),
                in: 1...10000,
                step: 100
            )

            if showsMeasureButton {
                Button("Measure") { builder.measure() }
            }

            if let result = builder.lastResult {
                HistogramView(result: result)
                    .frame(height: 160)
            } else {
                Text("No measurement yet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}

#Preview {
    MeasurementView(builder: CircuitBuilder(qubitCount: 2))
        .padding()
}
