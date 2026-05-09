import Foundation

protocol ObsidianManagerDelegate: AnyObject {
    func obsidianManager(_ manager: ObsidianManager, didSaveNoteSuccessfully noteID: String)
    func obsidianManager(_ manager: ObsidianManager, didFailWith error: Error)
}

class ObsidianManager {
    
    weak var delegate: ObsidianManagerDelegate?
    
    private let vaultPath: String
    private let noteFolder = "Brainwave"
    
    init(vaultPath: String = "Brainwave") {
        self.vaultPath = vaultPath
    }
    
    func saveNote(content: String) {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            
            do {
                let vaultURL = self.getVaultURL()
                try self.ensureFolderExists(at: vaultURL)
                
                let noteName = self.generateNoteName()
                let noteURL = vaultURL.appendingPathComponent("\(noteName).md")
                
                let markdownContent = self.formatMarkdown(content: content)
                try markdownContent.write(to: noteURL, atomically: true, encoding: .utf8)
                
                DispatchQueue.main.async {
                    self.delegate?.obsidianManager(self, didSaveNoteSuccessfully: noteName)
                }
            } catch {
                DispatchQueue.main.async {
                    self.delegate?.obsidianManager(self, didFailWith: error)
                }
            }
        }
    }
    
    private func getVaultURL() -> URL {
        let fileManager = FileManager.default
        let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDir.appendingPathComponent(vaultPath)
    }
    
    private func ensureFolderExists(at url: URL) throws {
        let fileManager = FileManager.default
        
        if !fileManager.fileExists(atPath: url.path) {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    private func generateNoteName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return "Brainwave_\(formatter.string(from: Date()))"
    }
    
    private func formatMarkdown(content: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let timestamp = formatter.string(from: Date())
        
        return """
        ---
        created: \(timestamp)
        tags: [brainwave, voice-note]
        ---
        
        \(content)
        """
    }
    
    func listNotes(completion: @escaping ([URL]) -> Void) {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            
            do {
                let vaultURL = self.getVaultURL()
                let contents = try FileManager.default.contentsOfDirectory(at: vaultURL, includingPropertiesForKeys: nil)
                let mdFiles = contents.filter { $0.pathExtension == "md" }.sorted { $0.lastPathComponent > $1.lastPathComponent }
                
                DispatchQueue.main.async {
                    completion(mdFiles)
                }
            } catch {
                DispatchQueue.main.async {
                    completion([])
                }
            }
        }
    }
    
    func readNote(at url: URL, completion: @escaping (String?) -> Void) {
        DispatchQueue.global().async {
            do {
                let content = try String(contentsOf: url, encoding: .utf8)
                DispatchQueue.main.async {
                    completion(content)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
}
