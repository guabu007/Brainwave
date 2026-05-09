import UIKit

class ViewController: UIViewController {
    
    private let launchButton = UIButton(type: .system)
    private let notesTableView = UITableView()
    private var notes: [URL] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadNotes()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        title = "Brainwave"
        
        launchButton.setTitle("开始录音", for: .normal)
        launchButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        launchButton.addTarget(self, action: #selector(launchRecording), for: .touchUpInside)
        launchButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(launchButton)
        
        notesTableView.translatesAutoresizingMaskIntoConstraints = false
        notesTableView.dataSource = self
        notesTableView.delegate = self
        notesTableView.register(UITableViewCell.self, forCellReuseIdentifier: "NoteCell")
        notesTableView.rowHeight = UITableView.automaticDimension
        notesTableView.estimatedRowHeight = 60
        view.addSubview(notesTableView)
        
        NSLayoutConstraint.activate([
            launchButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            launchButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            launchButton.widthAnchor.constraint(equalToConstant: 200),
            launchButton.heightAnchor.constraint(equalToConstant: 50),
            
            notesTableView.topAnchor.constraint(equalTo: launchButton.bottomAnchor, constant: 20),
            notesTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            notesTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            notesTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    @objc private func launchRecording() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let recordingVC = storyboard.instantiateViewController(withIdentifier: "RecordingViewController") as? RecordingViewController {
            recordingVC.modalPresentationStyle = .fullScreen
            recordingVC.onSaveComplete = { [weak self] in
                self?.loadNotes()
            }
            present(recordingVC, animated: true)
        }
    }
    
    private func loadNotes() {
        let obsidianManager = ObsidianManager()
        obsidianManager.listNotes { [weak self] notes in
            self?.notes = notes
            self?.notesTableView.reloadData()
        }
    }
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        notes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NoteCell", for: indexPath)
        let noteURL = notes[indexPath.row]
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        let fileName = noteURL.lastPathComponent.replacingOccurrences(of: ".md", with: "")
        cell.textLabel?.text = fileName.replacingOccurrences(of: "Brainwave_", with: "")
        cell.textLabel?.font = .systemFont(ofSize: 14)
        cell.detailTextLabel?.text = "点击查看内容"
        cell.detailTextLabel?.font = .systemFont(ofSize: 12)
        cell.detailTextLabel?.textColor = .secondaryLabel
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let noteURL = notes[indexPath.row]
        let obsidianManager = ObsidianManager()
        
        obsidianManager.readNote(at: noteURL) { [weak self] content in
            guard let content = content else { return }
            
            let alert = UIAlertController(title: "笔记内容", message: content, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "关闭", style: .default))
            self?.present(alert, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let noteURL = notes[indexPath.row]
            
            do {
                try FileManager.default.removeItem(at: noteURL)
                notes.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .automatic)
            } catch {
                print("Failed to delete note: \(error.localizedDescription)")
            }
        }
    }
}
