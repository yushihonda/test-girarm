import UIKit

class MainViewController: UIViewController {
    
    // MARK: - UI Components
    private let titleLabel = UILabel()
    private let tableView = UITableView()
    private let addButton = UIButton(type: .system)
    private let timeLabel = UILabel()
    
    // MARK: - Properties
    private let alarmManager = AlarmManager()
    private var timer: Timer?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupTimer()
        loadSampleAlarms()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.black
        
        // タイトルラベル
        titleLabel.text = "ギラーム"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 32)
        titleLabel.textColor = UIColor.white
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 現在時刻表示
        timeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 48, weight: .thin)
        timeLabel.textColor = UIColor.white
        timeLabel.textAlignment = .center
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        updateTimeLabel()
        
        // テーブルビュー
        tableView.backgroundColor = UIColor.black
        tableView.separatorColor = UIColor.darkGray
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(AlarmTableViewCell.self, forCellReuseIdentifier: "AlarmCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        // 追加ボタン
        addButton.setTitle("＋", for: .normal)
        addButton.titleLabel?.font = UIFont.systemFont(ofSize: 32, weight: .light)
        addButton.setTitleColor(UIColor.orange, for: .normal)
        addButton.backgroundColor = UIColor.darkGray
        addButton.layer.cornerRadius = 30
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        
        view.addSubview(titleLabel)
        view.addSubview(timeLabel)
        view.addSubview(tableView)
        view.addSubview(addButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // タイトル
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // 時刻表示
            timeLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            timeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // テーブルビュー
            tableView.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 30),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -80),
            
            // 追加ボタン
            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            addButton.widthAnchor.constraint(equalToConstant: 60),
            addButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    private func setupTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateTimeLabel()
        }
    }
    
    private func updateTimeLabel() {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        timeLabel.text = formatter.string(from: Date())
    }
    
    private func loadSampleAlarms() {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 7
        components.minute = 0
        
        if let alarmTime = calendar.date(from: components) {
            let alarm = AlarmModel(time: alarmTime, label: "朝のアラーム")
            alarmManager.addAlarm(alarm)
        }
        
        tableView.reloadData()
    }
    
    @objc private func addButtonTapped() {
        let alertController = UIAlertController(title: "新しいアラーム", message: "時刻を設定してください", preferredStyle: .alert)
        
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .time
        datePicker.preferredDatePickerStyle = .wheels
        
        // UIAlertController の contentViewController には UIView ではなく UIViewController を渡す必要がある
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(datePicker)
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            datePicker.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            datePicker.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            datePicker.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            datePicker.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            datePicker.topAnchor.constraint(equalTo: containerView.topAnchor),
            datePicker.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        let hostVC = UIViewController()
        hostVC.view = containerView
        hostVC.preferredContentSize = CGSize(width: 300, height: 200)
        alertController.setValue(hostVC, forKey: "contentViewController")
        
        let addAction = UIAlertAction(title: "追加", style: .default) { _ in
            let alarm = AlarmModel(time: datePicker.date)
            self.alarmManager.addAlarm(alarm)
            self.tableView.reloadData()
        }
        
        let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel)
        
        alertController.addAction(addAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true)
    }
    
    deinit {
        timer?.invalidate()
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension MainViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return alarmManager.alarms.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AlarmCell", for: indexPath) as! AlarmTableViewCell
        let alarm = alarmManager.alarms[indexPath.row]
        cell.configure(with: alarm)
        cell.delegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let alarm = alarmManager.alarms[indexPath.row]
        let alarmViewController = AlarmViewController()
        alarmViewController.alarmManager = alarmManager
        alarmViewController.currentAlarm = alarm
        
        present(alarmViewController, animated: true)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            alarmManager.removeAlarm(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}

// MARK: - AlarmTableViewCellDelegate
extension MainViewController: AlarmTableViewCellDelegate {
    func alarmCell(_ cell: AlarmTableViewCell, didToggleSwitch isOn: Bool) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        var alarm = alarmManager.alarms[indexPath.row]
        alarm.isEnabled = isOn
        alarmManager.updateAlarm(alarm)
    }
}

// MARK: - AlarmTableViewCell
protocol AlarmTableViewCellDelegate: AnyObject {
    func alarmCell(_ cell: AlarmTableViewCell, didToggleSwitch isOn: Bool)
}

class AlarmTableViewCell: UITableViewCell {
    
    weak var delegate: AlarmTableViewCellDelegate?
    
    private let timeLabel = UILabel()
    private let labelLabel = UILabel()
    private let enabledSwitch = UISwitch()
    private let challengesLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = UIColor.black
        
        timeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 32, weight: .light)
        timeLabel.textColor = UIColor.white
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        labelLabel.font = UIFont.systemFont(ofSize: 16)
        labelLabel.textColor = UIColor.lightGray
        labelLabel.translatesAutoresizingMaskIntoConstraints = false
        
        challengesLabel.font = UIFont.systemFont(ofSize: 12)
        challengesLabel.textColor = UIColor.orange
        challengesLabel.translatesAutoresizingMaskIntoConstraints = false
        
        enabledSwitch.onTintColor = UIColor.orange
        enabledSwitch.translatesAutoresizingMaskIntoConstraints = false
        enabledSwitch.addTarget(self, action: #selector(switchToggled), for: .valueChanged)
        
        contentView.addSubview(timeLabel)
        contentView.addSubview(labelLabel)
        contentView.addSubview(challengesLabel)
        contentView.addSubview(enabledSwitch)
        
        NSLayoutConstraint.activate([
            timeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            timeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            
            labelLabel.leadingAnchor.constraint(equalTo: timeLabel.leadingAnchor),
            labelLabel.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 4),
            
            challengesLabel.leadingAnchor.constraint(equalTo: timeLabel.leadingAnchor),
            challengesLabel.topAnchor.constraint(equalTo: labelLabel.bottomAnchor, constant: 2),
            
            enabledSwitch.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            enabledSwitch.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    func configure(with alarm: AlarmModel) {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        
        timeLabel.text = formatter.string(from: alarm.time)
        labelLabel.text = alarm.label
        enabledSwitch.isOn = alarm.isEnabled
        
        let challengeNames = alarm.challenges.map { challenge in
            switch challenge {
            case .posture: return "姿勢"
            case .light: return "光"
            case .expression: return "表情"
            case .voice: return "音声"
            }
        }
        challengesLabel.text = challengeNames.joined(separator: " • ")
    }
    
    @objc private func switchToggled() {
        delegate?.alarmCell(self, didToggleSwitch: enabledSwitch.isOn)
    }
}