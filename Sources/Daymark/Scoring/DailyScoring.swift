import Foundation

struct DailyScore: Equatable {
    var total: Int
    var planning: Int
    var reflection: Int
    var progress: Int
    var adaptability: Int
    var confidence: Double
    var summary: String
}

enum DailyScoring {
    static func score(_ day: DayRecord?) -> DailyScore {
        guard let day else {
            return DailyScore(
                total: 0,
                planning: 0,
                reflection: 0,
                progress: 0,
                adaptability: 0,
                confidence: 0,
                summary: "No record"
            )
        }

        let hasPlan = !day.plannedTasks.isEmpty
        let reflectionText = combinedReflection(day)
        let hasReflection = !reflectionText.isEmpty
        let completed = day.plannedTasks.filter(\.completed).count
        let attempted = day.plannedTasks.filter {
            ProgressMatcher.matches(reflectionText, label: $0.text)
        }.count
        let mentionedProgress = containsProgressLanguage(reflectionText)
        let mentionedBlocker = containsBlockerLanguage(reflectionText)
        let lateLogCount = day.lateLogs?.count ?? 0

        let planning = hasPlan ? 20 : 0
        let reflection = hasReflection ? 20 : 0

        var progress = 0
        if hasPlan {
            let evidenceCount = max(completed, attempted)
            progress = Int(
                (Double(evidenceCount) / Double(day.plannedTasks.count) * 45).rounded()
            )
            if mentionedProgress && progress == 0 { progress = 12 }
        } else if hasReflection && mentionedProgress {
            progress = 15
        }

        var adaptability = 0
        if mentionedBlocker { adaptability += 8 }
        if lateLogCount > 0 { adaptability += 5 }
        if hasReflection && attempted > completed { adaptability += 5 }
        adaptability = min(15, adaptability)

        let total = min(100, planning + reflection + progress + adaptability)
        let knownSignals = [hasPlan, hasReflection, completed > 0 || attempted > 0]
            .filter { $0 }.count
        let confidence = Double(knownSignals) / 3.0

        return DailyScore(
            total: total,
            planning: planning,
            reflection: reflection,
            progress: progress,
            adaptability: adaptability,
            confidence: confidence,
            summary: summary(
                total: total,
                hasPlan: hasPlan,
                hasReflection: hasReflection,
                mentionedBlocker: mentionedBlocker
            )
        )
    }

    static func combinedReflection(_ day: DayRecord) -> String {
        ([day.reflection] + (day.lateLogs ?? []).map(\.text))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }

    private static func containsProgressLanguage(_ text: String) -> Bool {
        let words = [
            "started", "attempted", "worked", "built", "progress", "finished",
            "completed", "drafted", "researched", "fixed", "%"
        ]
        let lowercased = text.lowercased()
        return words.contains { lowercased.contains($0) }
    }

    private static func containsBlockerLanguage(_ text: String) -> Bool {
        let words = [
            "blocked", "blocker", "stuck", "issue", "problem", "waiting",
            "couldn't", "could not", "ran out"
        ]
        let lowercased = text.lowercased()
        return words.contains { lowercased.contains($0) }
    }

    private static func summary(
        total: Int,
        hasPlan: Bool,
        hasReflection: Bool,
        mentionedBlocker: Bool
    ) -> String {
        if !hasPlan && !hasReflection { return "No evidence yet" }
        if mentionedBlocker { return "Progress with a blocker" }
        switch total {
        case 0..<30: return "Limited evidence"
        case 30..<50: return "Some engagement"
        case 50..<70: return "Meaningful progress"
        case 70..<90: return "Strong day"
        default: return "Exceptional alignment"
        }
    }
}
