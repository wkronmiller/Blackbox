//
//  MetricsCollector.swift
//  BlackBox
//
//  Created by William Rory Kronmiller on 2/9/19.
//  Copyright © 2019 William Rory Kronmiller. All rights reserved.
//

import Foundation
import CoreLocation
import CoreMotion
import UIKit

struct LocationStats {
    var peakAcceleration: Double
    var topSpeed: Double
    var topSpeedBatch: Double // top speed of batch
    var numLocations: Int
    var latestLat: Double
    var latestLon: Double
    var latestAltitude: Double
}

struct DeviceStats {
    var batteryLevel: Double
    var unplugged: Bool
}

struct MetricsUpdate {
    let locationStats: LocationStats
    let deviceStats: DeviceStats
    let acceleration: Double
}

extension Notification.Name {
    static let locationStatsUpdated = Notification.Name("lcf-location-stats-updated")
    static let deviceStatsUpdated = Notification.Name("lcf-device-stats-updated")
    static let metricsUpdate = Notification.Name("lfc-metrics-update")
}

class MetricsCollector: NSObject, CLLocationManagerDelegate {
    private var _tracking = false
    
    var tracking: Bool {
        get {
            return self._tracking
        }
    }
    
    var metricsReportingIntervalSeconds = 10.0
    
    private let metricsReportingQueue = DispatchQueue(label: "metrics-reporting")
    
    private var _locationStats = LocationStats(peakAcceleration: 0.0,
                                       topSpeed: 0.0,
                                       topSpeedBatch: 0.0,
                                       numLocations: 0,
                                       latestLat: 0.0,
                                       latestLon: 0.0,
                                       latestAltitude: 0.0)
    
    private var _deviceStats = DeviceStats(batteryLevel: -1.0, unplugged: true)
    var acceleration: Double = -1.0 //TODO private and getter
    
    private let locationManager = CLLocationManager()
    private let motionManager = CMMotionManager()
    
    private func trackLocation() {
        locationManager.delegate = self
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.activityType = .fitness
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        NSLog("Got locations \(locations)")
        self._locationStats.topSpeedBatch = 0.0
        locations.forEach{ location in
            self._locationStats.topSpeed = max(self._locationStats.topSpeed, location.speed)
            self._locationStats.topSpeedBatch = max(self._locationStats.topSpeedBatch, location.speed)
            self._locationStats.numLocations += 1
            self._locationStats.latestLon = location.coordinate.longitude
            self._locationStats.latestLat = location.coordinate.latitude
            self._locationStats.latestAltitude = location.altitude
            
            Database.shared.addLocation(lat: location.coordinate.latitude,
                                        lon: location.coordinate.longitude,
                                        heading: location.course,
                                        speed: location.speed,
                                        altitude: location.altitude,
                                        epochSeconds: location.timestamp.timeIntervalSince1970)
        }
        
        NotificationCenter.default.post(name: .locationStatsUpdated, object: self._locationStats)
    }
    
    @objc func batteryLevelChanged() {
        DispatchQueue.main.async {
            self._deviceStats.batteryLevel = Double(UIDevice.current.batteryLevel)
            if UIDevice.current.batteryState == .unplugged {
                self._deviceStats.unplugged = true
            } else {
                self._deviceStats.unplugged = false
            }
            Database.shared.addBattery(charge: self._deviceStats.batteryLevel,
                                       unplugged: self._deviceStats.unplugged,
                                       epochSeconds: abs(Date().timeIntervalSince1970))
        }
    }
    
    private let motionQueue = OperationQueue()
    
    private func trackMotion() {
        DispatchQueue.main.async {
            if self.motionManager.isDeviceMotionAvailable {
                self.motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
                self.motionManager.startDeviceMotionUpdates(to: self.motionQueue){ data, error in
                    if let err = error {
                        NSLog("Got error recording motion \(err)")
                        return
                    }
                    
                    // Magnitude of net vector
                    let accelerationMagnitude = sqrt(pow(data!.userAcceleration.x, 2) + pow(data!.userAcceleration.y, 2) + pow(data!.userAcceleration.z, 2))
                    self.acceleration = max(self.acceleration, accelerationMagnitude)

                    Database.shared.addMotion(accelX: data!.userAcceleration.x,
                                              accelY: data!.userAcceleration.y,
                                              accelZ: data!.userAcceleration.z,
                                              epochSeconds: data!.timestamp)
                }
            }
        }
    }
    
    private func publishMetrics() {
        if(!self._tracking) {
            return
        }
        
        let metrics = MetricsUpdate(locationStats: self._locationStats,
                                    deviceStats: self._deviceStats,
                                    acceleration: self.acceleration)
        
        NSLog("Publishing metrics \(metrics)")
        
        NotificationCenter.default.post(name: .metricsUpdate, object: metrics)
        
        self.metricsReportingQueue.asyncAfter(deadline: .now() + self.metricsReportingIntervalSeconds){
            self.publishMetrics()
        }
    }
    
    func startTracking() {
        NSLog("Tracking started")
        self._tracking = true
        self.trackLocation()
        self.trackMotion()
        self.publishMetrics()
        self.batteryLevelChanged()
        NotificationCenter.default.addObserver(self, selector: #selector(batteryLevelChanged), name: UIDevice.batteryLevelDidChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(batteryLevelChanged), name: UIDevice.batteryStateDidChangeNotification, object: nil)
    }
    
    func stopTracking() {
        self._tracking = false
        locationManager.stopUpdatingLocation()
        NSLog("Tracking stopped")
    }
    
    static let shared = MetricsCollector()
}
