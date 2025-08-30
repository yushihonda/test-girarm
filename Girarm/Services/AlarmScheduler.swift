import Foundation
import UserNotifications
import UIKit

class AlarmScheduler: NSObject {
    
    static let shared = AlarmScheduler()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    override init() {
        super.init()
        notificationCenter.delegate = self
        requestNotificationPermissions()
    }
    
    // MARK: - Permission
    private func requestNotificationPermissions() {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    // MARK: - Schedule Alarm
    func scheduleAlarm(_ alarm: AlarmModel) {
        guard alarm.isEnabled else { return }
        
        // 既存の通知をキャンセル
        cancelAlarm(alarm)
        
        let calendar = Calendar.current
        let now = Date()
        
        if alarm.repeatDays.isEmpty {
            // 単発アラーム
            scheduleOneTimeAlarm(alarm)
        } else {
            // 繰り返しアラーム
            scheduleRepeatingAlarm(alarm)
        }
    }
    
    private func scheduleOneTimeAlarm(_ alarm: AlarmModel) {
        let content = createNotificationContent(for: alarm)
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: alarm.time)
        
        var triggerDate = calendar.dateComponents([.year, .month, .day], from: Date())
        triggerDate.hour = components.hour
        triggerDate.minute = components.minute
        
        // 今日の時刻が過ぎていたら明日に設定
        if let alarmDate = calendar.date(from: triggerDate), alarmDate <= Date() {
            triggerDate.day! += 1
        }
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let request = UNNotificationRequest(identifier: alarm.id.uuidString, content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to schedule alarm: \(error)")
            }
        }
    }
    
    private func scheduleRepeatingAlarm(_ alarm: AlarmModel) {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: alarm.time)
        
        for weekday in alarm.repeatDays {
            let content = createNotificationContent(for: alarm)
            
            var dateComponents = DateComponents()
            dateComponents.hour = components.hour
            dateComponents.minute = components.minute
            dateComponents.weekday = weekday.rawValue
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let identifier = "\(alarm.id.uuidString)_\(weekday.rawValue)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            notificationCenter.add(request) { error in
                if let error = error {
                    print("Failed to schedule repeating alarm: \(error)")
                }
            }
        }
    }
    
    private func createNotificationContent(for alarm: AlarmModel) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "ギラーム"
        content.body = alarm.label
        content.sound = UNNotificationSound.default
        content.badge = 1
        content.categoryIdentifier = "ALARM_CATEGORY"
        content.userInfo = [
            "alarmId": alarm.id.uuidString,
            "challenges": alarm.challenges.map { $0.rawValue }
        ]
        
        return content
    }
    
    // MARK: - Cancel Alarm
    func cancelAlarm(_ alarm: AlarmModel) {
        if alarm.repeatDays.isEmpty {
            // 単発アラーム
            notificationCenter.removePendingNotificationRequests(withIdentifiers: [alarm.id.uuidString])
        } else {
            // 繰り返しアラーム
            let identifiers = alarm.repeatDays.map { "\(alarm.id.uuidString)_\($0.rawValue)" }
            notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
        }
    }
    
    func cancelAllAlarms() {
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    // MARK: - Get Scheduled Alarms
    func getScheduledAlarms(completion: @escaping ([UNNotificationRequest]) -> Void) {
        notificationCenter.getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                completion(requests)
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AlarmScheduler: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        // フォアグラウンドでも通知を表示
        completionHandler([.alert, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        
        if let alarmIdString = userInfo["alarmId"] as? String,
           let alarmId = UUID(uuidString: alarmIdString) {
            
            // アラーム画面を表示
            DispatchQueue.main.async {
                self.presentAlarmViewController(for: alarmId, userInfo: userInfo)
            }
        }
        
        completionHandler()
    }
    
    private func presentAlarmViewController(for alarmId: UUID, userInfo: [AnyHashable: Any]) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return
        }
        
        // アラームマネージャーから該当のアラームを検索
        // 実際の実装では、永続化されたデータからアラームを取得
        let alarmViewController = AlarmViewController()
        alarmViewController.modalPresentationStyle = .fullScreen
        
        // 現在表示されているViewControllerを取得
        var topViewController = window.rootViewController
        while let presentedViewController = topViewController?.presentedViewController {
            topViewController = presentedViewController
        }
        
        topViewController?.present(alarmViewController, animated: true)
    }
}

// MARK: - Notification Actions
extension AlarmScheduler {
    
    func setupNotificationActions() {
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_ACTION",
            title: "スヌーズ (5分)",
            options: []
        )
        
        let stopAction = UNNotificationAction(
            identifier: "STOP_ACTION",
            title: "停止",
            options: [.destructive]
        )
        
        let category = UNNotificationCategory(
            identifier: "ALARM_CATEGORY",
            actions: [snoozeAction, stopAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        notificationCenter.setNotificationCategories([category])
    }
}

// MARK: - Snooze Functionality
extension AlarmScheduler {
    
    func snoozeAlarm(_ alarmId: UUID, snoozeMinutes: Int = 5) {
        let content = UNMutableNotificationContent()
        content.title = "ギラーム - スヌーズ"
        content.body = "スヌーズ時間が終了しました"
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "ALARM_CATEGORY"
        content.userInfo = ["alarmId": alarmId.uuidString, "isSnooze": true]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(snoozeMinutes * 60), repeats: false)
        let request = UNNotificationRequest(
            identifier: "snooze_\(alarmId.uuidString)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to schedule snooze: \(error)")
            }
        }
    }
    
    func cancelSnooze(for alarmId: UUID) {
        getScheduledAlarms { requests in
            let snoozeIdentifiers = requests
                .filter { $0.identifier.hasPrefix("snooze_\(alarmId.uuidString)") }
                .map { $0.identifier }
            
            self.notificationCenter.removePendingNotificationRequests(withIdentifiers: snoozeIdentifiers)
        }
    }
}

// MARK: - Background App Refresh
extension AlarmScheduler {
    
    func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.example.Girarm.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15分後
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }
}

import BackgroundTasks

// MARK: - Data Persistence Helper
extension AlarmScheduler {
    
    func saveAlarmsToUserDefaults(_ alarms: [AlarmModel]) {
        if let data = try? JSONEncoder().encode(alarms) {
            UserDefaults.standard.set(data, forKey: "saved_alarms")
        }
    }
    
    func loadAlarmsFromUserDefaults() -> [AlarmModel] {
        guard let data = UserDefaults.standard.data(forKey: "saved_alarms"),
              let alarms = try? JSONDecoder().decode([AlarmModel].self, from: data) else {
            return []
        }
        return alarms
    }
}

// AlarmModelをCodableに準拠させるための拡張
extension AlarmModel: Codable {
    enum CodingKeys: String, CodingKey {
        case id, time, isEnabled, challenges, label, repeatDays
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        time = try container.decode(Date.self, forKey: .time)
        isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        challenges = try container.decode([ChallengeType].self, forKey: .challenges)
        label = try container.decode(String.self, forKey: .label)
        let repeatDaysArray = try container.decode([Int].self, forKey: .repeatDays)
        repeatDays = Set(repeatDaysArray.compactMap { Weekday(rawValue: $0) })
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(time, forKey: .time)
        try container.encode(isEnabled, forKey: .isEnabled)
        try container.encode(challenges, forKey: .challenges)
        try container.encode(label, forKey: .label)
        try container.encode(repeatDays.map { $0.rawValue }, forKey: .repeatDays)
    }
}

extension ChallengeType: Codable {
    enum CodingKeys: String, CodingKey {
        case posture, light, expression, voice
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        
        switch value {
        case "posture":
            self = .posture
        case "light":
            self = .light
        case "expression":
            self = .expression
        case "voice":
            self = .voice
        default:
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unknown challenge type")
            )
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .posture:
            try container.encode("posture")
        case .light:
            try container.encode("light")
        case .expression:
            try container.encode("expression")
        case .voice:
            try container.encode("voice")
        }
    }
}