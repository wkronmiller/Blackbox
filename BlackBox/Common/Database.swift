//
//  Database.swift
//  BlackBox
//
//  Created by William Rory Kronmiller on 2/9/19.
//  Copyright © 2019 William Rory Kronmiller. All rights reserved.
//

import Foundation
import SQLite

class Database {
    //private let dbLocation = "\(FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!.absoluteString)/blackbox.v4.sqlite3"
    private let dbLocation = "\(FileManager().containerURL(forSecurityApplicationGroupIdentifier: "group.lcf")!.absoluteString)/blackbox.v5.sqlite3"
    private var myDeviceId: String!
    private var db: Connection!
    
    private let epochSeconds = Expression<Double>("epoch_seconds")
    private let deviceId = Expression<String>("device_uid")
    
    private let battery = Table("battery")
    private let charge = Expression<Double>("charge")
    private let unplugged = Expression<Bool>("unplugged")
    
    private let motion = Table("motion")
    private let accelX = Expression<Double>("accel_x")
    private let accelY = Expression<Double>("accel_y")
    private let accelZ = Expression<Double>("accel_z")
    
    private let locations = Table("locations")
    
    private let lat = Expression<Double>("latitude")
    private let lon = Expression<Double>("longitude")
    private let heading = Expression<Double>("heading")
    private let speed = Expression<Double>("speed")
    private let altitude = Expression<Double>("altitude")
    
    var dbPath: URL {
        get {
            return URL(fileURLWithPath: self.dbLocation)
        }
    }
    
    func initTables(deviceId: String) {
        self.myDeviceId = deviceId
        
        self.db = try! Connection(dbLocation)
        NSLog("Opened database \(dbLocation)")
        try! db.run(locations.create(temporary: false, ifNotExists: true, withoutRowid: false){ t in
            t.column(self.deviceId)
            t.column(epochSeconds)
            t.column(lat)
            t.column(lon)
            t.column(heading)
            t.column(speed)
            t.column(altitude)
        })
        
        try! db.run(motion.create(temporary: false, ifNotExists: true, withoutRowid: false){ t in
            t.column(self.deviceId)
            t.column(epochSeconds)
            t.column(accelX)
            t.column(accelY)
            t.column(accelZ)
        })
        
        try! db.run(battery.create(temporary: false, ifNotExists: true, withoutRowid: false){ t in
            t.column(self.deviceId)
            t.column(epochSeconds)
            t.column(charge)
            t.column(unplugged)
        })
    }
    
    func addBattery(charge: Double, unplugged: Bool, epochSeconds: Double) {
        try! db.run(battery.insert(
            self.deviceId <- self.myDeviceId,
            self.epochSeconds <- epochSeconds,
            self.charge <- charge,
            self.unplugged <- unplugged
        ))
    }
    
    func addMotion(accelX: Double, accelY: Double, accelZ: Double, epochSeconds: Double) {
        try! db.run(motion.insert(
            self.accelX <- accelX,
            self.accelY <- accelY,
            self.accelZ <- accelZ,
            self.epochSeconds <- epochSeconds,
            self.deviceId <- self.myDeviceId
        ))
    }
    
    func addLocation(lat: Double,
                     lon: Double,
                     heading: Double,
                     speed: Double,
                     altitude: Double,
                     epochSeconds: Double) {
        
        let location = locations.insert(
            self.deviceId <- self.myDeviceId,
            self.lat <- lat,
            self.lon <- lon,
            self.heading <- heading,
            self.speed <- speed,
            self.altitude <- altitude,
            self.epochSeconds <- epochSeconds
        )
        try! db.run(location)
    }
    
    static let shared = Database()
}
