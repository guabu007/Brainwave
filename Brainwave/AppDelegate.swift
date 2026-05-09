import UIKit
import AVFoundation

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        setupAudioSession()
        handleQuickAction(launchOptions)
        return true
    }
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .default)
            try session.setActive(true)
        } catch {
            print("Audio session setup failed: \(error.localizedDescription)")
        }
    }
    
    private func handleQuickAction(_ launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        guard let shortcutItem = launchOptions?[.shortcutItem] as? UIApplicationShortcutItem else { return }
        handleShortcutItem(shortcutItem)
    }
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        handleShortcutItem(shortcutItem)
        completionHandler(true)
    }
    
    private func handleShortcutItem(_ shortcutItem: UIApplicationShortcutItem) {
        if shortcutItem.type == "com.brainwave.app.shortcut.record" {
            launchRecordingViewController()
        }
    }
    
    private func launchRecordingViewController() {
        guard let window = window, let rootViewController = window.rootViewController else { return }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let recordingVC = storyboard.instantiateViewController(withIdentifier: "RecordingViewController") as? RecordingViewController {
            recordingVC.modalPresentationStyle = .fullScreen
            rootViewController.present(recordingVC, animated: true)
        }
    }
}
