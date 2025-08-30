import Foundation
import CoreMotion
import AVFoundation
import Vision
import Speech
import CoreImage

protocol SensorManagerDelegate: AnyObject {
    func sensorManager(_ manager: SensorManager, didDetectPosture isCorrect: Bool, progress: Double)
    func sensorManager(_ manager: SensorManager, didDetectLight level: Double, progress: Double)
    func sensorManager(_ manager: SensorManager, didDetectExpression isSmiling: Bool, progress: Double)
    func sensorManager(_ manager: SensorManager, didDetectVoice text: String, progress: Double)
}

class SensorManager: NSObject {
    
    weak var delegate: SensorManagerDelegate?
    
    // MARK: - Motion Detection
    private let motionManager = CMMotionManager()
    private var postureTimer: Timer?
    private var currentPostureProgress: Double = 0.0
    
    // MARK: - Light Detection
    private let captureSession = AVCaptureSession()
    private var lightTimer: Timer?
    private var currentLightProgress: Double = 0.0
    
    // MARK: - Expression Detection
    private var faceDetectionTimer: Timer?
    private var currentExpressionProgress: Double = 0.0
    private let faceDetectionRequest = VNDetectFaceRectanglesRequest()
    
    // MARK: - Voice Recognition
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja_JP"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var currentVoiceProgress: Double = 0.0
    private var isVoiceRecognitionEnabled: Bool = true
    private var isAudioTapInstalled: Bool = false
    private let inputBus: AVAudioNodeBus = 0
    
    // MARK: - Lifecycle
    override init() {
        super.init()
        setupFaceDetection()
    }
    
    // MARK: - Public Methods
    func startMonitoring() {
        startPostureDetection()
        startLightDetection()
        startExpressionDetection()
        if isVoiceRecognitionEnabled {
            startVoiceRecognition()
        }
    }
    
    func stopMonitoring() {
        stopPostureDetection()
        stopLightDetection()
        stopExpressionDetection()
        stopVoiceRecognition()
    }
    
    // MARK: - Posture Detection
    private func startPostureDetection() {
        guard motionManager.isDeviceMotionAvailable else { return }
        
        motionManager.deviceMotionUpdateInterval = 0.1
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self = self, let motion = motion else { return }
            self.processMotionData(motion)
        }
    }
    
    private func stopPostureDetection() {
        motionManager.stopDeviceMotionUpdates()
        postureTimer?.invalidate()
    }
    
    private func processMotionData(_ motion: CMDeviceMotion) {
        let gravity = motion.gravity
        
        // Z軸方向（縦向き）の重力を検出
        let zGravity = gravity.z
        let isUpright = abs(zGravity) > 0.8  // 縦向きの閾値
        
        if isUpright {
            currentPostureProgress = min(1.0, currentPostureProgress + 0.1)
        } else {
            currentPostureProgress = max(0.0, currentPostureProgress - 0.05)
        }
        
        delegate?.sensorManager(self, didDetectPosture: isUpright, progress: currentPostureProgress)
    }
    
    // MARK: - Light Detection
    private func startLightDetection() {
        // カメラセッションをセットアップ
        setupCameraForLightDetection()
        
        lightTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.simulateLightDetection()
        }
    }
    
    private func stopLightDetection() {
        captureSession.stopRunning()
        lightTimer?.invalidate()
    }
    
    private func setupCameraForLightDetection() {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device) else { return }
        
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }
        
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: .userInitiated))
        
        if captureSession.canAddOutput(output) {
            captureSession.addOutput(output)
        }
        
        captureSession.startRunning()
    }
    
    private func simulateLightDetection() {
        // 実際の実装では、カメラからの画像の明度を分析
        // ここではシミュレーション
        let currentHour = Calendar.current.component(.hour, from: Date())
        let isDaytime = currentHour >= 6 && currentHour <= 18
        
        if isDaytime {
            currentLightProgress = min(1.0, currentLightProgress + 0.2)
        } else {
            currentLightProgress = max(0.0, currentLightProgress - 0.1)
        }
        
        let lightLevel = isDaytime ? 0.8 : 0.2
        delegate?.sensorManager(self, didDetectLight: lightLevel, progress: currentLightProgress)
    }
    
    // MARK: - Expression Detection
    private func setupFaceDetection() {
        faceDetectionRequest.revision = VNDetectFaceRectanglesRequestRevision3
    }
    
    private func startExpressionDetection() {
        // カメラセッションは既にLight Detectionで開始済み
        faceDetectionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.simulateExpressionDetection()
        }
    }
    
    private func stopExpressionDetection() {
        faceDetectionTimer?.invalidate()
    }
    
    private func simulateExpressionDetection() {
        // 実際の実装では、Vision frameworkを使用して表情分析
        // ここではランダムシミュレーション（実際のアプリでは表情認識APIを使用）
        let isSmiling = Bool.random()
        
        if isSmiling {
            currentExpressionProgress = min(1.0, currentExpressionProgress + 0.3)
        } else {
            currentExpressionProgress = max(0.0, currentExpressionProgress - 0.1)
        }
        
        delegate?.sensorManager(self, didDetectExpression: isSmiling, progress: currentExpressionProgress)
    }
    
    // MARK: - Voice Recognition
    private func startVoiceRecognition() {
        // 権限確認
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            DispatchQueue.main.async {
                if authStatus == .authorized {
                    self?.startRecording()
                }
            }
        }
    }
    
    private func stopVoiceRecognition() {
        if isAudioTapInstalled {
            audioEngine.inputNode.removeTap(onBus: inputBus)
            isAudioTapInstalled = false
        }
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
    }

    // 公開: 音声認識のON/OFF切り替え
    func setVoiceRecognitionEnabled(_ enabled: Bool) {
        isVoiceRecognitionEnabled = enabled
        if enabled {
            startVoiceRecognition()
        } else {
            stopVoiceRecognition()
        }
    }
    
    private func startRecording() {
        // 既存のタスクをキャンセル
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        // オーディオセッションを設定
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session setup failed: \(error)")
            return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        guard let recognitionRequest = recognitionRequest else { return }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                let recognizedText = result.bestTranscription.formattedString
                self.processVoiceInput(recognizedText)
            }
            
            if error != nil || result?.isFinal == true {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                // 再開
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.startRecording()
                }
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: inputBus)
        // 既存のタップがある場合は一旦外す
        if isAudioTapInstalled {
            inputNode.removeTap(onBus: inputBus)
            isAudioTapInstalled = false
        }
        inputNode.installTap(onBus: inputBus, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        isAudioTapInstalled = true
        
        audioEngine.prepare()
        
        do {
            if !audioEngine.isRunning {
                try audioEngine.start()
            }
        } catch {
            print("Audio engine start failed: \(error)")
        }
    }
    
    private func processVoiceInput(_ text: String) {
        let targetWords = ["おはよう", "起きる", "アラーム", "ストップ"]
        let lowercaseText = text.lowercased()
        
        var foundMatch = false
        for word in targetWords {
            if lowercaseText.contains(word) {
                foundMatch = true
                break
            }
        }
        
        if foundMatch {
            currentVoiceProgress = min(1.0, currentVoiceProgress + 0.5)
        }
        
        delegate?.sensorManager(self, didDetectVoice: text, progress: currentVoiceProgress)
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension SensorManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // 実際のカメラデータから明度を計算
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let context = CIContext()
        
        // 画像の平均明度を計算（簡略化）
        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
            let brightness = calculateBrightness(from: cgImage)
            
            DispatchQueue.main.async {
                if brightness > 0.5 {
                    self.currentLightProgress = min(1.0, self.currentLightProgress + 0.1)
                } else {
                    self.currentLightProgress = max(0.0, self.currentLightProgress - 0.05)
                }
                
                self.delegate?.sensorManager(self, didDetectLight: brightness, progress: self.currentLightProgress)
            }
        }
    }
    
    private func calculateBrightness(from cgImage: CGImage) -> Double {
        // 簡単な明度計算（実際にはより複雑な計算が必要）
        // ここでは0.0-1.0の範囲で返す
        return 0.6 // シミュレーション値
    }
}

// MARK: - Challenge Helper Extensions
extension SensorManager {
    
    func resetProgress(for challengeType: ChallengeType) {
        switch challengeType {
        case .posture:
            currentPostureProgress = 0.0
        case .light:
            currentLightProgress = 0.0
        case .expression:
            currentExpressionProgress = 0.0
        case .voice:
            currentVoiceProgress = 0.0
        }
    }
    
    func getCurrentProgress(for challengeType: ChallengeType) -> Double {
        switch challengeType {
        case .posture:
            return currentPostureProgress
        case .light:
            return currentLightProgress
        case .expression:
            return currentExpressionProgress
        case .voice:
            return currentVoiceProgress
        }
    }
    
    // テスト用のシミュレーションメソッド
    func simulateSuccess(for challengeType: ChallengeType) {
        switch challengeType {
        case .posture:
            currentPostureProgress = 1.0
            delegate?.sensorManager(self, didDetectPosture: true, progress: 1.0)
        case .light:
            currentLightProgress = 1.0
            delegate?.sensorManager(self, didDetectLight: 1.0, progress: 1.0)
        case .expression:
            currentExpressionProgress = 1.0
            delegate?.sensorManager(self, didDetectExpression: true, progress: 1.0)
        case .voice:
            currentVoiceProgress = 1.0
            delegate?.sensorManager(self, didDetectVoice: "おはよう", progress: 1.0)
        }
    }
}
