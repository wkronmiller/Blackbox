//
//  AudioAlerts.swift
//  BlackBox
//
//  Created by William Rory Kronmiller on 2/9/19.
//  Copyright © 2019 William Rory Kronmiller. All rights reserved.
//

import Foundation
import AVKit
import MediaPlayer

class AudioPrompts {
    
    private var _running = false
    
    var running: Bool {
        get {
            return _running
        }
    }
    
    private let speechQueue = DispatchQueue(label: "speech-queue")
    
    private let synth = AVSpeechSynthesizer()
    
    private var lastLocationUtterance = Date()
    
    private func say(words: String) {
        let utterance = AVSpeechUtterance(string: words)
        utterance.rate = 0.55
        utterance.pitchMultiplier = 0.65
        // utterance.voice = AVSpeechSynthesisVoice(language: "de-DE")
        
        speechQueue.async {
            self.synth.speak(utterance)
            NSLog("Said utterance \(utterance)")
        }
    }
    
    @objc func gotMetricsUpdate(notification: Notification) {
        if let stats = notification.object as? MetricsUpdate {
            let maxSpeedMph = stats.locationStats.topSpeed * 2.23694
            let recentMaxSpeedMph = stats.locationStats.topSpeedBatch * 2.23694
            let batteryPercent = stats.deviceStats.batteryLevel * 100.0
            let words = String(format: "max speed %.2f. recent speed %.2f. battery %.0f percent", maxSpeedMph, recentMaxSpeedMph, batteryPercent)
            self.say(words: words)
        }
    }
    
    func start() {
        self._running = true
        NotificationCenter.default.addObserver(self, selector: #selector(gotMetricsUpdate), name: .metricsUpdate, object: nil)
    }
    
    func stop() {
        self._running = false
        NotificationCenter.default.removeObserver(self)
    }
    
    static let shared = AudioPrompts()
}
