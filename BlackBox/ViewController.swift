//
//  ViewController.swift
//  BlackBox
//
//  Created by William Rory Kronmiller on 2/9/19.
//  Copyright © 2019 William Rory Kronmiller. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    private let refreshQueue = DispatchQueue(label: "refreshQueue")
    
    @IBOutlet weak var voicePromptsLabel: UILabel!
    
    @IBOutlet weak var peakAccelLabel: UILabel!
    
    @IBOutlet weak var topSpeedLabel: UILabel!
    
    @IBOutlet weak var numLocationsLabel: UILabel!
    
    @IBOutlet weak var latestLatLonLabel: UILabel!
    
    @IBOutlet weak var voicePromptsToggle: UISwitch!
    
    @IBOutlet weak var trackingLocationToggle: UISwitch!
    
    @IBAction func toggledLocationTracking(_ sender: Any) {
        if(self.trackingLocationToggle.isOn) {
            MetricsCollector.shared.startTracking()
        } else {
            MetricsCollector.shared.stopTracking()
        }
    }
    
    @IBAction func toggledVoicePrompts(_ sender: Any) {
        if(self.voicePromptsToggle.isOn) {
            AudioPrompts.shared.start()
        } else {
            AudioPrompts.shared.stop()
        }
    }
    
    @IBAction func voicePromptRateChanged(_ sender: UIStepper) {
        MetricsCollector.shared.metricsReportingIntervalSeconds = sender.value
        DispatchQueue.main.async {
            self.voicePromptsLabel.text = "Voice Prompts \(MetricsCollector.shared.metricsReportingIntervalSeconds)/sec"
        }
    }
    
    @objc private func updateView(notification: Notification) {
        if let stats = notification.object as? LocationStats {
            self.peakAccelLabel.text = String(format: "%.2f g", MetricsCollector.shared.acceleration)
            self.topSpeedLabel.text = String(format: "%.2f mph", stats.topSpeed * 2.23694)
            
            self.latestLatLonLabel.text = String(format: "%.2f lat, %.2f lon", stats.latestLat, stats.latestLon)
            self.numLocationsLabel.text = "\(stats.numLocations)"
        }
    }
    
    @IBAction func exportButtonPressed(_ sender: Any) {
        let path = Database.shared.dbPath
        let activityVc = UIActivityViewController(activityItems: [path], applicationActivities: nil)
        self.present(activityVc, animated: true, completion: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.async {
            self.trackingLocationToggle.isOn = MetricsCollector.shared.tracking
            self.voicePromptsToggle.isOn = AudioPrompts.shared.running
            self.voicePromptsLabel.text = "Voice Prompts \(MetricsCollector.shared.metricsReportingIntervalSeconds) sec/prompt"
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateView), name: .locationStatsUpdated, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
        super.viewDidDisappear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        MetricsCollector.shared.startTracking()
        // Do any additional setup after loading the view, typically from a nib.
    }


}

