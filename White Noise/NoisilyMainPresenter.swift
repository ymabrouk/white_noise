//
//  MainPresenter.swift
//  White Noise
//
//  Created by Yasser Mabrouk on 4/17/17.
//  Copyright © 2019 Yasser Mabrouk. All rights reserved.
//

import Foundation
class NoisilyMainPresenter {
    //MARK: vars
    public enum NoiseColors: String {
        case White = "white"
        case Pink = "pink"
        case Brown = "brown"
    }

    
    var isPlaying: Bool = false
    var currentColor: NoiseColors = .Brown
    var viewController: NoisilyViewController
    var volume: Float = 0.2
    let minVolume: Float = 0.2
    var maxVolume: Float = 1.0
    static let tickInterval: Double = 0.03
    var increasing: Bool = false
    let volumeIncrement: Float
    var wavesEnabled: Bool = false
    var fadeEnabled: Bool = false
    var resettingVolume: Bool = false
    var fadeTime: Int = 10
    let resetVolumeIncrement: Float
    var timerDisplayed: Bool = false
    var timeLeftSecs: Double = 0
    var prevTime: Int = 0
    var timerActive: Bool = false
//    private let colorKey : String = "colorKey"
//    private let wavesKey : String = "wavesKey"
//    private let fadeKey : String = "fadeKey"
    private let timerKey : String = "timerKey"


    
    init(viewController: NoisilyViewController) {
        self.viewController = viewController
        volumeIncrement = Float(NoisilyMainPresenter.tickInterval / 5)
        resetVolumeIncrement = Float(NoisilyMainPresenter.tickInterval)
    }
    
    
    public func getColor() -> NoiseColors {
        return currentColor
    }
    
    public func playPause() {
        if (isPlaying) {
            pause()
        } else {
            play()
        }
    }
    
    public func pause() {
        viewController.pause()
        isPlaying = false
    }
    
    public func play() {
        resetVolume()
        saveState()
        donateIntent()
        viewController.play()
//        viewController.setMediaTitle(title: getSoundTitle())
        isPlaying = true
    }
    
//    private func getSoundTitle() -> String {
//        var playingTitle = ""
//        switch (currentColor) {
//        case .Brown:
//            playingTitle = "Brown"
//            break;
//        case .Pink:
//            playingTitle = "Pink"
//            break;
//        default:
//            playingTitle = "White"
//            break;
//        }
//        return playingTitle + " Noise"
//    }
    
    public func donateIntent() {
        guard #available(iOS 12.0, *) else {
            return
        }
        
        let intent = PlayIntent()
        intent.noiseModification = createNoiseModificationForIntent()
        intent.minutes = createTimerMinutesForIntent()
        intent.color = currentColor.rawValue
        NoisilyShortcutCreator().resetShortcutsWithNewIntent(intent: intent)
    }
    
    private func createNoiseModificationForIntent() -> [String] {
        var noiseModification = [String]()
        if fadeEnabled {
            noiseModification.append("fading")
        }
        if wavesEnabled {
            noiseModification.append("wavy")
        }
        return noiseModification
    }
    
    private func createTimerMinutesForIntent() -> NSNumber? {
        if timerActive {
            return (viewController.getTimerPickerTime() / 60) as NSNumber
        }
        return nil
    }
    
    private func saveState() {
        UserDefaults.standard.setValuesForKeys(createState())
    }

    private func createState() -> Dictionary<String, Any> {
        var state = Dictionary<String, Any>()
//        state.updateValue(currentColor.rawValue, forKey: colorKey)
//        state.updateValue(wavesEnabled, forKey: wavesKey)
//        state.updateValue(fadeEnabled, forKey: fadeKey)
        var timerSeconds: Double? = nil
        if timerActive {
            timerSeconds = viewController.getTimerPickerTime()
        }
        state.updateValue(timerSeconds as Any, forKey: timerKey)
        return state
    }
    
    @available(iOS 12.0, *)
    public func setIntent(intent: PlayIntent) {
        let intentParser = IntentParser(intent: intent)
        var state = [String: Any]()
//        state[colorKey] = intent.color
        state[timerKey] = intentParser.getMinutesFromIntent()
//        state[wavesKey] = intentParser.getWavesEnabledFromIntent()
//        state[fadeKey] = intentParser.getFadingEnabledFromIntent()
        loadSavedState(state: state)
        if intentParser.playForIntentIfNeeded() {
            play()
        }
    }

    public func loadStateFromDefaults() {
        loadSavedState(state: UserDefaults.standard.dictionaryRepresentation())
    }

    private func loadSavedState(state: Dictionary<String, Any>) {
//        if let savedColor = (state[colorKey] as? String) {
//            changeColor(color: NoisilyMainPresenter.NoiseColors(rawValue: savedColor) ?? .White)
//        }
//        wavesEnabled = state[wavesKey] as? Bool ?? false
//        fadeEnabled = state[fadeKey] as? Bool ?? false
////        viewController.setWavesEnabled(enabled: wavesEnabled)
//        viewController.setFadeEnabled(enabled: fadeEnabled)
//
        timerDisplayed = false
        timerActive = false
        if let savedTimerSeconds = state[timerKey] as? Double {
            viewController.setTimerPickerTime(seconds: savedTimerSeconds)
            addDeleteTimer()
        } else {
            timeLeftSecs = 0
            viewController.setTimerPickerTime(seconds: timeLeftSecs)
        }
    }
    
    public func enableWavyVolume(enabled: Bool) {
        wavesEnabled = enabled
        if (wavesEnabled) {
            resettingVolume = false;
        } else {
            resetVolume()
        }
    }
    
    public func enableFadeVolume(enabled: Bool) {
        fadeEnabled = enabled
        if (fadeEnabled) {
            resettingVolume = false;
            fadeTime = Int(timeLeftSecs)
            if (fadeTime == 0) {
                fadeTime = 10
            }
        } else {
            resetVolume()
        }
    }

    
    public func tick() {
        decrementTimerTime()
    
        if (fadeEnabled) {
            applyFadeVolume()
        }
        if (wavesEnabled) {
            applyWavyVolume()
        }
        if (resettingVolume) {
            applyResetVolume()
        }
        viewController.setVolume(volume: volume)
    }
    
    private func decrementTimerTime() {
        if (!timerActive) {
            return
        }
        
        if (Int(timeLeftSecs) != 0) {
            timeLeftSecs -= Double(NoisilyMainPresenter.tickInterval)
            
            if (Int(timeLeftSecs) != prevTime) {
                prevTime = Int(timeLeftSecs)
                viewController.setTimerText(text: getTimerText())
            }
        } else {
            viewController.pause()
            timerDisplayed = false
            viewController.cancelTimer(timerText: getTimerText())
            timerActive = false
            isPlaying = false
            fadeTime = 10
        }
    }
    
    public func resetVolume() {
        maxVolume = 1.0
        volume = 0.2
        viewController.setVolume(volume: volume)
        resettingVolume = true
        increasing = false
    }
    
    public func applyWavyVolume() {
        if (increasing) {
            volume += volumeIncrement
        } else {
            volume -= volumeIncrement
        }
        if (volume <= minVolume) {
            volume = minVolume
            increasing = true
        } else if (volume >= maxVolume) {
            increasing = false
            volume = maxVolume
        }
    }
    
    public func applyFadeVolume() {
        let volumeDelta = (1.0 - minVolume) /
            (Float(fadeTime) * 1.0 / Float(NoisilyMainPresenter.tickInterval))
        if (maxVolume > minVolume) {
            maxVolume -= volumeDelta
            if (volume > maxVolume) {
                volume -= volumeDelta
            }
        }
    }
    
    public func applyResetVolume() {
        if (volume < maxVolume) {
            volume += resetVolumeIncrement
        }
        if (volume >= maxVolume) {
            volume = maxVolume
            resettingVolume = false
        }
    }
    
    public func addDeleteTimer() {
        timerDisplayed = !timerDisplayed
        if (timerDisplayed) {
            timerActive = true
            timeLeftSecs = viewController.getTimerPickerTime()
            if (fadeEnabled) {
                fadeTime = Int(timeLeftSecs)
            }
            viewController.addTimer(timerText: getTimerText())
        } else {
            timerActive = false
            timeLeftSecs = 0
            viewController.cancelTimer(timerText: getTimerText())
        }
    }
    
    private func getTimerText() -> String {
        if (timerDisplayed) {
            return secondsToFormattedTime(time: timeLeftSecs)
        } else {
            return ""
        }
    }
    
    private func secondsToFormattedTime(time: Double) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        if (hours != 0) {
            return String(format:"%02i:%02i:%02i", hours, minutes, seconds)
        } else {
            return String(format:"%02i:%02i", minutes, seconds)
        }
    }
    
}
