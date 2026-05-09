import UIKit

class RecordingViewController: UIViewController {
    
    var onSaveComplete: (() -> Void)?
    
    private let audioRecorder = AudioRecorder()
    private let whisperTranscriber = WhisperTranscriber()
    private let obsidianManager = ObsidianManager()
    
    private let statusLabel = UILabel()
    private let waveformView = WaveformView()
    private let stopButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    private let transcriptionTextView = UITextView()
    private let saveButton = UIButton(type: .system)
    
    private var recordingState: RecordingState = .idle
    private var recordedText: String = ""
    
    enum RecordingState {
        case idle
        case recording
        case transcribing
        case completed
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupDelegates()
        startRecording()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        statusLabel.text = "正在录音..."
        statusLabel.font = .systemFont(ofSize: 24, weight: .bold)
        statusLabel.textAlignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)
        
        waveformView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(waveformView)
        
        stopButton.setTitle("停止录音", for: .normal)
        stopButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        stopButton.addTarget(self, action: #selector(stopRecording), for: .touchUpInside)
        stopButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stopButton)
        
        cancelButton.setTitle("取消", for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 16)
        cancelButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cancelButton)
        
        transcriptionTextView.isEditable = true
        transcriptionTextView.font = .systemFont(ofSize: 16)
        transcriptionTextView.textColor = .label
        transcriptionTextView.backgroundColor = .secondarySystemBackground
        transcriptionTextView.layer.cornerRadius = 12
        transcriptionTextView.isHidden = true
        transcriptionTextView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(transcriptionTextView)
        
        saveButton.setTitle("保存到 Obsidian", for: .normal)
        saveButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        saveButton.addTarget(self, action: #selector(saveToObsidian), for: .touchUpInside)
        saveButton.isHidden = true
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(saveButton)
        
        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            waveformView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 40),
            waveformView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            waveformView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            waveformView.heightAnchor.constraint(equalToConstant: 100),
            
            stopButton.topAnchor.constraint(equalTo: waveformView.bottomAnchor, constant: 40),
            stopButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stopButton.widthAnchor.constraint(equalToConstant: 180),
            stopButton.heightAnchor.constraint(equalToConstant: 50),
            
            cancelButton.topAnchor.constraint(equalTo: stopButton.bottomAnchor, constant: 20),
            cancelButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            transcriptionTextView.topAnchor.constraint(equalTo: waveformView.bottomAnchor, constant: 20),
            transcriptionTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            transcriptionTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            transcriptionTextView.heightAnchor.constraint(equalToConstant: 200),
            
            saveButton.topAnchor.constraint(equalTo: transcriptionTextView.bottomAnchor, constant: 20),
            saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            saveButton.widthAnchor.constraint(equalToConstant: 200),
            saveButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupDelegates() {
        audioRecorder.delegate = self
        whisperTranscriber.delegate = self
        obsidianManager.delegate = self
    }
    
    private func startRecording() {
        recordingState = .recording
        audioRecorder.startRecording()
    }
    
    @objc private func stopRecording() {
        audioRecorder.stopRecording()
    }
    
    @objc private func cancel() {
        dismiss(animated: true)
    }
    
    @objc private func saveToObsidian() {
        let text = transcriptionTextView.text ?? ""
        if !text.isEmpty {
            obsidianManager.saveNote(content: text)
        }
    }
    
    private func updateUI(for state: RecordingState) {
        switch state {
        case .idle:
            statusLabel.text = "准备就绪"
            waveformView.isHidden = false
            stopButton.isHidden = false
            cancelButton.isHidden = false
            transcriptionTextView.isHidden = true
            saveButton.isHidden = true
            
        case .recording:
            statusLabel.text = "正在录音..."
            waveformView.isHidden = false
            stopButton.isHidden = false
            cancelButton.isHidden = false
            transcriptionTextView.isHidden = true
            saveButton.isHidden = true
            
        case .transcribing:
            statusLabel.text = "正在识别..."
            waveformView.isHidden = true
            stopButton.isHidden = true
            cancelButton.isHidden = false
            transcriptionTextView.isHidden = true
            saveButton.isHidden = true
            
        case .completed:
            statusLabel.text = "识别完成"
            waveformView.isHidden = true
            stopButton.isHidden = true
            cancelButton.isHidden = false
            transcriptionTextView.isHidden = false
            transcriptionTextView.text = recordedText
            saveButton.isHidden = false
        }
    }
}

extension RecordingViewController: AudioRecorderDelegate {
    func audioRecorderDidStart() {
        updateUI(for: .recording)
    }
    
    func audioRecorderDidStop() {
        recordingState = .transcribing
        updateUI(for: .transcribing)
    }
    
    func audioRecorder(_ recorder: AudioRecorder, didUpdateDecibels decibels: Float) {
        waveformView.update(with: decibels)
    }
    
    func audioRecorder(_ recorder: AudioRecorder, didFinishRecordingWith url: URL) {
        whisperTranscriber.transcribe(audioURL: url)
    }
    
    func audioRecorder(_ recorder: AudioRecorder, didFailWith error: Error) {
        showError(message: error.localizedDescription)
    }
}

extension RecordingViewController: WhisperTranscriberDelegate {
    func whisperTranscriber(_ transcriber: WhisperTranscriber, didStartTranscription audioURL: URL) {
    }
    
    func whisperTranscriber(_ transcriber: WhisperTranscriber, didUpdateProgress progress: Double) {
    }
    
    func whisperTranscriber(_ transcriber: WhisperTranscriber, didFinishTranscription text: String) {
        recordedText = text
        recordingState = .completed
        updateUI(for: .completed)
    }
    
    func whisperTranscriber(_ transcriber: WhisperTranscriber, didFailWith error: Error) {
        showError(message: "语音识别失败: \(error.localizedDescription)")
    }
}

extension RecordingViewController: ObsidianManagerDelegate {
    func obsidianManager(_ manager: ObsidianManager, didSaveNoteSuccessfully noteID: String) {
        let alert = UIAlertController(title: "保存成功", message: "笔记已保存到 Obsidian", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default) { [weak self] _ in
            self?.onSaveComplete?()
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }
    
    func obsidianManager(_ manager: ObsidianManager, didFailWith error: Error) {
        showError(message: "保存失败: \(error.localizedDescription)")
    }
}

extension RecordingViewController {
    private func showError(message: String) {
        let alert = UIAlertController(title: "错误", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}

class WaveformView: UIView {
    
    private let bars: [UIView] = (0..<30).map { _ in
        let view = UIView()
        view.backgroundColor = .systemBlue
        view.layer.cornerRadius = 2
        return view
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupBars()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupBars()
    }
    
    private func setupBars() {
        let stackView = UIStackView(arrangedSubviews: bars)
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 4
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        
        bars.forEach { $0.heightAnchor.constraint(equalToConstant: 8).isActive = true }
    }
    
    func update(with decibels: Float) {
        let normalizedValue = max(0, min(1, (decibels + 60) / 60))
        
        bars.enumerated().forEach { index, bar in
            let barIndex = Double(index) / Double(bars.count)
            let threshold = barIndex * normalizedValue * 2
            
            UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseOut) {
                if Double.random(in: 0...1) < threshold {
                    bar.transform = CGAffineTransform(scaleY: CGFloat(0.3 + normalizedValue * 0.7))
                } else {
                    bar.transform = CGAffineTransform(scaleY: 0.3)
                }
            }
        }
    }
}
