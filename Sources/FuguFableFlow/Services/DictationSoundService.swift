import AppKit
import Foundation

@MainActor
final class DictationSoundService {
    func playStart(soundName: String, volume: Double) {
        play(named: soundName, volume: volume)
    }

    func playStop(soundName: String, volume: Double) {
        play(named: soundName, volume: volume)
    }

    func preview(soundName: String, volume: Double) {
        play(named: soundName, volume: volume)
    }

    private func play(named name: String, volume: Double) {
        guard let sound = NSSound(named: NSSound.Name(name)) else { return }
        sound.volume = Float(max(0, min(1, volume)))
        sound.play()
    }
}
