//
//  ProgressChart.swift
//  MusicNote
//
//  Created by Jeremy Bastidas on 5/31/25.
//

/*
import SwiftUI
import Charts

struct ProgressChart: View {
    @State private var metric: Metric = .speed
    @State private var span: TimeSpan = .day
    private let letters = ["C","D","E","F","G","A","B"]

    var body: some View {
        let pts = bucketedStats(for: metric, span: span, letters: letters)

        VStack {
            Picker("Metric", selection: $metric) {
                Text("Speed").tag(Metric.speed)
                Text("Accuracy").tag(Metric.accuracy)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            Picker("Span", selection: $span) {
                Text("Day").tag(TimeSpan.day)
                Text("Month").tag(TimeSpan.month)
                Text("Year").tag(TimeSpan.year)
            }
            .pickerStyle(.segmented)
            .padding([.horizontal, .bottom])

            Chart {
                ForEach(pts, id:\.self) { p in
                    LineMark(
                        x: .value("Date", p.period),
                        y: .value("Val", p.value)
                    )
                    .foregroundStyle(by: .value("Note", p.letter))
                    .symbol(by: .value("Note", p.letter))
                }
            }
            .chartYScale(domain: metric == .speed ? 0...4 : 0...100)
            .padding()
        }
    }
}
*/
