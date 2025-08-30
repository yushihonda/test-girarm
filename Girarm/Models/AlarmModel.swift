import Foundation

struct AlarmModel {
    let id: UUID
    var time: Date
    var isEnabled: Bool
    var challenges: [ChallengeType]
    var label: String
    var repeatDays: Set<Weekday>
    
    init(time: Date, label: String = "アラーム", challenges: [ChallengeType] = [.posture, .light, .expression, .voice]) {
        self.id = UUID()
        self.time = time
        self.isEnabled = true
        self.challenges = challenges
        self.label = label
        self.repeatDays = []
    }
}

enum ChallengeType: CaseIterable {
    case posture    // 姿勢
    case light      // 光
    case expression // 表情
    case voice      // 音声
    
    var displayName: String {
        switch self {
        case .posture:
            return "姿勢チャレンジ"
        case .light:
            return "光チャレンジ"
        case .expression:
            return "表情チャレンジ"
        case .voice:
            return "音声チャレンジ"
        }
    }
    
    var instruction: String {
        switch self {
        case .posture:
            return "スマートフォンを縦に立ててください"
        case .light:
            return "明るい場所に移動してください"
        case .expression:
            return "笑顔を見せてください"
        case .voice:
            return "「おはよう」と言ってください"
        }
    }
}

// RawRepresentableを実装して文字列表現を提供（通知や永続化で使用）
extension ChallengeType: RawRepresentable {
    typealias RawValue = String

    init?(rawValue: String) {
        switch rawValue {
        case "posture": self = .posture
        case "light": self = .light
        case "expression": self = .expression
        case "voice": self = .voice
        default: return nil
        }
    }

    var rawValue: String {
        switch self {
        case .posture: return "posture"
        case .light: return "light"
        case .expression: return "expression"
        case .voice: return "voice"
        }
    }
}

enum Weekday: Int, CaseIterable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7
    
    var displayName: String {
        switch self {
        case .sunday:
            return "日"
        case .monday:
            return "月"
        case .tuesday:
            return "火"
        case .wednesday:
            return "水"
        case .thursday:
            return "木"
        case .friday:
            return "金"
        case .saturday:
            return "土"
        }
    }
}

struct ChallengeProgress {
    let type: ChallengeType
    var isCompleted: Bool = false
    var progress: Double = 0.0
}

class AlarmManager: ObservableObject {
    @Published var alarms: [AlarmModel] = []
    @Published var activeAlarm: AlarmModel?
    @Published var challengeProgresses: [ChallengeProgress] = []
    
    func addAlarm(_ alarm: AlarmModel) {
        alarms.append(alarm)
        scheduleNotification(for: alarm)
    }
    
    func removeAlarm(at index: Int) {
        let alarm = alarms[index]
        cancelNotification(for: alarm)
        alarms.remove(at: index)
    }
    
    func updateAlarm(_ alarm: AlarmModel) {
        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            alarms[index] = alarm
            cancelNotification(for: alarm)
            scheduleNotification(for: alarm)
        }
    }
    
    func startAlarm(_ alarm: AlarmModel) {
        activeAlarm = alarm
        challengeProgresses = alarm.challenges.map { ChallengeProgress(type: $0) }
    }
    
    func completeChallenge(_ challengeType: ChallengeType) {
        if let index = challengeProgresses.firstIndex(where: { $0.type == challengeType }) {
            challengeProgresses[index].isCompleted = true
            challengeProgresses[index].progress = 1.0
        }
        
        // 全てのチャレンジが完了したかチェック
        if challengeProgresses.allSatisfy({ $0.isCompleted }) {
            stopAlarm()
        }
    }
    
    func updateChallengeProgress(_ challengeType: ChallengeType, progress: Double) {
        if let index = challengeProgresses.firstIndex(where: { $0.type == challengeType }) {
            challengeProgresses[index].progress = min(1.0, max(0.0, progress))
        }
    }
    
    func stopAlarm() {
        activeAlarm = nil
        challengeProgresses = []
    }
    
    private func scheduleNotification(for alarm: AlarmModel) {
        // 通知スケジュール実装
    }
    
    private func cancelNotification(for alarm: AlarmModel) {
        // 通知キャンセル実装
    }
}