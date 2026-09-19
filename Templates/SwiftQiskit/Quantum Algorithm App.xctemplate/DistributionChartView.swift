//
//  DistributionChartView.swift
//  ___PACKAGENAME___
//
//  Quantum vs. classical position distribution, plotted with Swift Charts.
//  (SwiftQiskit's own playground page hand-rolls this on a bare `Canvas`
//  because a playground's `Sources/` folder can't import much — an app
//  target has no such restriction, so Swift Charts gets you axes and a
//  legend for a fraction of the code.)
//

import SwiftUI
import Charts

private struct DistributionPoint: Hashable {
    let offset: Int
    let probability: Double
}

struct DistributionChartView: View {
    let model: AlgorithmModel

    var body: some View {
        Chart {
            ForEach(points(for: model.classicalDistribution), id: \.offset) { point in
                LineMark(x: .value("Site", point.offset), y: .value("Probability", point.probability))
                    .foregroundStyle(by: .value("Walk", "Classical"))
            }
            ForEach(points(for: model.quantumDistribution), id: \.offset) { point in
                PointMark(x: .value("Site", point.offset), y: .value("Probability", point.probability))
                    .foregroundStyle(by: .value("Walk", "Quantum"))
            }
        }
        .chartForegroundStyleScale(["Classical": Color.blue, "Quantum": Color.orange])
        .chartXAxisLabel("Site (signed offset from start)")
        .chartYAxisLabel("Probability")
        .frame(height: 260)
    }

    private func points(for distribution: [Double]) -> [DistributionPoint] {
        distribution.enumerated()
            .map { DistributionPoint(offset: model.signedOffset($0.offset), probability: $0.element) }
            .sorted { $0.offset < $1.offset }
    }
}
