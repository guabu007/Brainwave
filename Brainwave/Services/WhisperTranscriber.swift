import Foundation

protocol WhisperTranscriberDelegate: AnyObject {
    func whisperTranscriber(_ transcriber: WhisperTranscriber, didStartTranscription audioURL: URL)
    func whisperTranscriber(_ transcriber: WhisperTranscriber, didUpdateProgress progress: Double)
    func whisperTranscriber(_ transcriber: WhisperTranscriber, didFinishTranscription text: String)
    func whisperTranscriber(_ transcriber: WhisperTranscriber, didFailWith error: Error)
}

class WhisperTranscriber {
    
    weak var delegate: WhisperTranscriberDelegate?
    
    private let baseURL = URL(string: "http://localhost:8000")!
    
    func transcribe(audioURL: URL) {
        delegate?.whisperTranscriber(self, didStartTranscription: audioURL)
        
        let endpoint = baseURL.appendingPathComponent("transcribe")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let formData = createMultipartFormData(audioURL: audioURL, boundary: boundary)
        request.httpBody = formData
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                self.delegate?.whisperTranscriber(self, didFailWith: error)
                return
            }
            
            guard let data = data else {
                self.delegate?.whisperTranscriber(self, didFailWith: NSError(domain: "WhisperTranscriber", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let text = json["text"] as? String {
                    self.delegate?.whisperTranscriber(self, didFinishTranscription: text)
                } else {
                    throw NSError(domain: "WhisperTranscriber", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
                }
            } catch {
                self.delegate?.whisperTranscriber(self, didFailWith: error)
            }
        }
        
        task.resume()
    }
    
    private func createMultipartFormData(audioURL: URL, boundary: String) -> Data {
        let data = NSMutableData()
        
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(audioURL.lastPathComponent)\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        
        if let audioData = try? Data(contentsOf: audioURL) {
            data.append(audioData)
        }
        
        data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        return data as Data
    }
    
    func downloadModelIfNeeded() {
        let modelPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("ggml-base.bin")
        
        if !FileManager.default.fileExists(atPath: modelPath.path) {
            downloadModel(to: modelPath)
        }
    }
    
    private func downloadModel(to path: URL) {
        let url = URL(string: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/models/ggml-base.bin")!
        
        let task = URLSession.shared.downloadTask(with: url) { [weak self] tempURL, response, error in
            guard let tempURL = tempURL, error == nil else { return }
            
            do {
                if FileManager.default.fileExists(atPath: path.path) {
                    try FileManager.default.removeItem(at: path)
                }
                try FileManager.default.moveItem(at: tempURL, to: path)
            } catch {
                self?.delegate?.whisperTranscriber(self!, didFailWith: error)
            }
        }
        
        task.resume()
    }
}
