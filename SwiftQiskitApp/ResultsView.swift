//
//  ResultsView.swift
//  SwiftQiskitApp
//
//  Live state vector for the current circuit. Shots/measurement/histogram
//  live in MeasurementView instead.
//

import SwiftUI
import SwiftQiskitCore

struct ResultsView: View {
    var builder: CircuitBuilder

    var body: some View {
        let state = builder.buildCircuit().run()

        VStack(alignment: .leading, spacing: 12) {
            Text("State Vector")
                .font(.headline)

            ScrollView {
                stateVectorList(state)
            }
            .frame(maxHeight: 220)
        }
    }

    private func stateVectorList(_ state: StateVector) -> some View {
        let probabilities = state.probabilities

        return VStack(alignment: .leading, spacing: 4) {
            ForEach(0..<state.dimension, id: \.self) { index in
                if probabilities[index] > 1e-9 {
                    Text("|\(binaryLabel(index))⟩: \(state[index].description)  (p=\(String(format: "%.3f", probabilities[index])))")
                        .font(.system(.caption, design: .monospaced))
                }
            }
        }
    }

    private func binaryLabel(_ index: Int) -> String {
        String(index, radix: 2).leftPadding(toLength: builder.qubitCount, withPad: "0")
    }
}
