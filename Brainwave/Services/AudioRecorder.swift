import Foundation
import AVFoundation

protocol AudioRecorderDelegate: AnyObject {
    func audioRecorderDidStart()
    func audioRecorderDidStop()
    func audioRecorder(_ recorder: AudioRecorder, didUpdateDecibels decibels: Float)
    func audioRecorder(_ recorder: AudioRecorder, didFinishRecordingWith url: URL)
    func audioRecorder(_ recorder: AudioRecorder, didFailWith error: Error)
}

class AudioRecorder: NSObject {
    
    weak var delegate: AudioRecorderDelegate?
    
    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    private let audioSession = AVAudioSession.sharedInstance()
    
    var isRecording: Bool { audioRecorder?.isRecording ?? false }
    
    private var recordingURL: URL {
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let timestamp = Date().timeIntervalSince1970
        return documentsDir.appendingPathComponent("recording_\(timestamp).m4a")
    }
    
    override init() {
        super.init()
        setupSession()
    }
    
    private func setupSession() {
        do {
            try audioSession.setCategory(.record, mode: .default, options: .duckOthers)
            try audioSession.setActive(true)
        } catch {
            delegate?.audioRecorder(self, didFailWith: error)
        }
    }
    
    func startRecording() {
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()
            
            delegate?.audioRecorderDidStart()
            
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                self?.updateMeters()
            }
        } catch {
            delegate?.audioRecorder(self, didFailWith: error)
        }
    }
    
    func stopRecording() {
        timer?.invalidate()
        timer = nil
        
        audioRecorder?.stop()
    }
    
    private func updateMeters() {
        audioRecorder?.updateMeters()
        let averagePower = audioRecorder?.averagePower(forChannel: 0) ?? 0
        delegate?.audioRecorder(self, didUpdateDecibels: averagePower)
    }
    
    deinit {
        timer?.invalidate()
        audioRecorder?.stop()
    }
}

extension AudioRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        delegate?.audioRecorderDidStop()
        
        if flag {
            delegate?.audioRecorder(self, didFinishRecordingWith: recorder.url)
        } else {
            delegate?.audioRecorder(self, didFailWith: NSError(domain: "AudioRecorder", code: -1, userInfo: [NSLocalizedDescriptionKey: "Recording failed"]))
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            delegate?.audioRecorder(self, didFailWith: error)
        }
    }
}
