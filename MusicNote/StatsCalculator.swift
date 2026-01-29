//
//  StatsCalculator.swift
//  MusicNote
//
//  Created by Jeremy Bastidas on 5/31/25.
//

import CoreData

enum Metric { case speed, accuracy }
enum TimeSpan { case day, month, year }

struct BucketPoint: Hashable {
    let period: Date
    let value: Double
    let letter: String
}

func bucketedStats(for metric: Metric,
                   span: TimeSpan,
                   letters: [String]) -> [BucketPoint] {

    let ctx = PersistenceController.shared.container.viewContext
    let cal = Calendar.current
    var pts: [BucketPoint] = []

    for letter in letters {
        let req: NSFetchRequest<Attempt> = Attempt.fetchRequest()
        req.predicate = NSPredicate(format: "letter == %@", letter)
        let rows = (try? ctx.fetch(req)) ?? []

        let grouped = Dictionary(grouping: rows) { att in
            switch span {
            case .day:   return cal.startOfDay(for: att.date!)
            case .month: return cal.date(from: cal.dateComponents([.year,.month], from: att.date!))!
            case .year:  return cal.date(from: cal.dateComponents([.year], from: att.date!))!
            }
        }

        for (date, attempts) in grouped {
            switch metric {
            case .accuracy:
                let pct = Double(attempts.filter{$0.correct}.count) / Double(attempts.count) * 100
                pts.append(.init(period: date, value: pct, letter: letter))
            case .speed:
                let avgRT = attempts.map{$0.rt}.reduce(0,+) / Double(attempts.count)
                pts.append(.init(period: date, value: 1/avgRT, letter: letter))
            }
        }
    }
    return pts.sorted { $0.period < $1.period }
}
