import UIKit
import AVFoundation

class AlarmViewController: UIViewController {
    
    // MARK: - Properties
    var alarmManager: AlarmManager?
    var currentAlarm: AlarmModel?
    var sensorManager: SensorManager!
    
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    
    // MARK: - UI Components
    private let dismissButton = UIButton(type: .system)
    private let timeLabel = UILabel()
    private let alarmLabel = UILabel()
    private let challengesStackView = UIStackView()
    private let progressLabel = UILabel()
    private let headerSunView = UIView()
    private let bigGreetingLabel = UILabel()
    private let micButton = UIButton(type: .system)
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupSensorManager()
        startAlarm()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAlarm()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.systemBackground
        
        // 閉じるボタン
        dismissButton.setTitle("×", for: .normal)
        dismissButton.titleLabel?.font = UIFont.systemFont(ofSize: 32, weight: .light)
        dismissButton.setTitleColor(UIColor.white, for: .normal)
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        dismissButton.addTarget(self, action: #selector(dismissButtonTapped), for: .touchUpInside)
        
        // 時刻ラベル
        timeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 40, weight: .regular)
        timeLabel.textColor = UIColor.label
        timeLabel.textAlignment = .center
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        updateTimeLabel()
        
        // アラームラベル
        alarmLabel.text = currentAlarm?.label ?? "アラーム"
        alarmLabel.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        alarmLabel.textColor = UIColor.secondaryLabel
        alarmLabel.textAlignment = .center
        alarmLabel.translatesAutoresizingMaskIntoConstraints = false

        // サンバースト風の簡易ヘッダー
        headerSunView.translatesAutoresizingMaskIntoConstraints = false
        headerSunView.backgroundColor = UIColor.systemYellow.withAlphaComponent(0.25)
        headerSunView.layer.cornerRadius = 120

        bigGreetingLabel.text = "おはよう\nございます"
        bigGreetingLabel.numberOfLines = 2
        bigGreetingLabel.textAlignment = .center
        bigGreetingLabel.font = UIFont.boldSystemFont(ofSize: 44)
        bigGreetingLabel.textColor = UIColor.label
        bigGreetingLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // チャレンジスタックビュー
        challengesStackView.axis = .vertical
        challengesStackView.distribution = .fillEqually
        challengesStackView.spacing = 20
        challengesStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // プログレスラベル
        progressLabel.text = "すべてのチャレンジを達成してください"
        progressLabel.font = UIFont.systemFont(ofSize: 16)
        progressLabel.textColor = UIColor.systemOrange
        progressLabel.textAlignment = .center
        progressLabel.numberOfLines = 0
        progressLabel.translatesAutoresizingMaskIntoConstraints = false

        // マイクボタン（下部中央）
        micButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
        micButton.tintColor = .white
        micButton.backgroundColor = .systemOrange
        micButton.layer.cornerRadius = 28
        micButton.translatesAutoresizingMaskIntoConstraints = false
        micButton.addTarget(self, action: #selector(toggleMic), for: .touchUpInside)
        
        view.addSubview(dismissButton)
        view.addSubview(headerSunView)
        view.addSubview(bigGreetingLabel)
        view.addSubview(timeLabel)
        view.addSubview(alarmLabel)
        view.addSubview(challengesStackView)
        view.addSubview(progressLabel)
        view.addSubview(micButton)
        
        setupConstraints()
        setupChallengeViews()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // 閉じるボタン
            dismissButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            dismissButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            dismissButton.widthAnchor.constraint(equalToConstant: 44),
            dismissButton.heightAnchor.constraint(equalToConstant: 44),
            
            // サンバースト風ヘッダ
            headerSunView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),
            headerSunView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            headerSunView.widthAnchor.constraint(equalToConstant: 240),
            headerSunView.heightAnchor.constraint(equalToConstant: 240),
            bigGreetingLabel.centerXAnchor.constraint(equalTo: headerSunView.centerXAnchor),
            bigGreetingLabel.centerYAnchor.constraint(equalTo: headerSunView.centerYAnchor),
            
            // 時刻
            timeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            timeLabel.topAnchor.constraint(equalTo: headerSunView.bottomAnchor, constant: 8),
            
            // アラームラベル
            alarmLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            alarmLabel.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 20),
            
            // チャレンジビュー
            challengesStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            challengesStackView.topAnchor.constraint(equalTo: alarmLabel.bottomAnchor, constant: 32),
            challengesStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            challengesStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // プログレス
            progressLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            progressLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -96),
            progressLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            progressLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            // マイクボタン
            micButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            micButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            micButton.heightAnchor.constraint(equalToConstant: 56),
            micButton.widthAnchor.constraint(equalToConstant: 280)
        ])
    }
    
    private func setupChallengeViews() {
        guard let challenges = currentAlarm?.challenges else { return }
        
        for challenge in challenges {
            let challengeView = ChallengeView(challengeType: challenge)
            challengeView.layer.cornerRadius = 14
            challengeView.layer.borderWidth = 1
            challengeView.layer.borderColor = UIColor.systemOrange.withAlphaComponent(0.5).cgColor
            challengesStackView.addArrangedSubview(challengeView)
        }
    }
    
    private func setupSensorManager() {
        sensorManager = SensorManager()
        sensorManager.delegate = self
        sensorManager.startMonitoring()
    }
    
    private func startAlarm() {
        // アラーム音を再生
        playAlarmSound()
        
        // 時刻更新タイマー
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateTimeLabel()
        }
        
        // アラームマネージャーにアラーム開始を通知
        if let alarm = currentAlarm {
            alarmManager?.startAlarm(alarm)
        }
    }
    
    private func stopAlarm() {
        audioPlayer?.stop()
        timer?.invalidate()
        sensorManager?.stopMonitoring()
        alarmManager?.stopAlarm()
    }
    
    private func playAlarmSound() {
        guard let soundURL = Bundle.main.url(forResource: "alarm", withExtension: "mp3") else {
            // システム音を使用
            AudioServicesPlaySystemSound(1005)
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.numberOfLoops = -1 // 無限ループ
            audioPlayer?.play()
        } catch {
            AudioServicesPlaySystemSound(1005)
        }
    }
    
    private func updateTimeLabel() {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        timeLabel.text = formatter.string(from: Date())
    }
    
    private func checkAllChallengesCompleted() {
        guard let alarmManager = alarmManager else { return }
        
        let completedCount = alarmManager.challengeProgresses.filter { $0.isCompleted }.count
        let totalCount = alarmManager.challengeProgresses.count
        
        if completedCount == totalCount && totalCount > 0 {
            // 全チャレンジ完了
            progressLabel.text = "🎉 おめでとうございます！\nアラームを停止します"
            progressLabel.textColor = UIColor.green
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.dismiss(animated: true)
            }
        } else {
            progressLabel.text = "チャレンジ進行中... (\(completedCount)/\(totalCount))"
        }
        
        // チャレンジビューを更新
        updateChallengeViews()
    }
    
    private func updateChallengeViews() {
        guard let alarmManager = alarmManager else { return }
        
        for (index, arrangedSubview) in challengesStackView.arrangedSubviews.enumerated() {
            if let challengeView = arrangedSubview as? ChallengeView,
               index < alarmManager.challengeProgresses.count {
                let progress = alarmManager.challengeProgresses[index]
                challengeView.updateProgress(progress.progress, isCompleted: progress.isCompleted)
            }
        }
    }
    
    @objc private func dismissButtonTapped() {
        let alert = UIAlertController(title: "警告", message: "すべてのチャレンジを完了してください", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    @objc private func toggleMic() {
        if micButton.backgroundColor == .systemOrange {
            micButton.backgroundColor = .systemGray
            sensorManager.setVoiceRecognitionEnabled(false)
        } else {
            micButton.backgroundColor = .systemOrange
            sensorManager.setVoiceRecognitionEnabled(true)
        }
    }
}

// MARK: - SensorManagerDelegate
extension AlarmViewController: SensorManagerDelegate {
    func sensorManager(_ manager: SensorManager, didDetectPosture isCorrect: Bool, progress: Double) {
        DispatchQueue.main.async {
            self.alarmManager?.updateChallengeProgress(.posture, progress: progress)
            if progress >= 1.0 {
                self.alarmManager?.completeChallenge(.posture)
            }
            self.checkAllChallengesCompleted()
        }
    }
    
    func sensorManager(_ manager: SensorManager, didDetectLight level: Double, progress: Double) {
        DispatchQueue.main.async {
            self.alarmManager?.updateChallengeProgress(.light, progress: progress)
            if progress >= 1.0 {
                self.alarmManager?.completeChallenge(.light)
            }
            self.checkAllChallengesCompleted()
        }
    }
    
    func sensorManager(_ manager: SensorManager, didDetectExpression isSmiling: Bool, progress: Double) {
        DispatchQueue.main.async {
            self.alarmManager?.updateChallengeProgress(.expression, progress: progress)
            if progress >= 1.0 {
                self.alarmManager?.completeChallenge(.expression)
            }
            self.checkAllChallengesCompleted()
        }
    }
    
    func sensorManager(_ manager: SensorManager, didDetectVoice text: String, progress: Double) {
        DispatchQueue.main.async {
            self.alarmManager?.updateChallengeProgress(.voice, progress: progress)
            if progress >= 1.0 {
                self.alarmManager?.completeChallenge(.voice)
            }
            self.checkAllChallengesCompleted()
        }
    }
}

// MARK: - ChallengeView
class ChallengeView: UIView {
    
    private let challengeType: ChallengeType
    private let iconLabel = UILabel()
    private let titleLabel = UILabel()
    private let instructionLabel = UILabel()
    private let progressView = UIProgressView()
    private let statusLabel = UILabel()
    
    init(challengeType: ChallengeType) {
        self.challengeType = challengeType
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = UIColor.darkGray
        layer.cornerRadius = 12
        
        // アイコン
        iconLabel.text = getIcon(for: challengeType)
        iconLabel.font = UIFont.systemFont(ofSize: 32)
        iconLabel.textAlignment = .center
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // タイトル
        titleLabel.text = challengeType.displayName
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        titleLabel.textColor = UIColor.white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 説明
        instructionLabel.text = challengeType.instruction
        instructionLabel.font = UIFont.systemFont(ofSize: 14)
        instructionLabel.textColor = UIColor.lightGray
        instructionLabel.numberOfLines = 2
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // プログレスバー
        progressView.progressTintColor = UIColor.orange
        progressView.trackTintColor = UIColor.gray
        progressView.translatesAutoresizingMaskIntoConstraints = false
        
        // ステータス
        statusLabel.text = "待機中..."
        statusLabel.font = UIFont.systemFont(ofSize: 12)
        statusLabel.textColor = UIColor.orange
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(iconLabel)
        addSubview(titleLabel)
        addSubview(instructionLabel)
        addSubview(progressView)
        addSubview(statusLabel)
        
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 120),
            
            iconLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            iconLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconLabel.widthAnchor.constraint(equalToConstant: 40),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconLabel.trailingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            instructionLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            instructionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            instructionLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            
            progressView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            progressView.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 8),
            progressView.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 4),
            
            statusLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            statusLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 4),
            statusLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor)
        ])
    }
    
    private func getIcon(for challengeType: ChallengeType) -> String {
        switch challengeType {
        case .posture:
            return "📱"
        case .light:
            return "💡"
        case .expression:
            return "😊"
        case .voice:
            return "🎤"
        }
    }
    
    func updateProgress(_ progress: Double, isCompleted: Bool) {
        progressView.progress = Float(progress)
        
        if isCompleted {
            statusLabel.text = "✅ 完了!"
            statusLabel.textColor = UIColor.green
            backgroundColor = UIColor.systemGreen.withAlphaComponent(0.2)
        } else if progress > 0 {
            statusLabel.text = "進行中... \(Int(progress * 100))%"
            statusLabel.textColor = UIColor.orange
        } else {
            statusLabel.text = "待機中..."
            statusLabel.textColor = UIColor.lightGray
        }
    }
}