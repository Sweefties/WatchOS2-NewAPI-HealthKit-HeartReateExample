//
//  MainInterfaceController.swift
//  WatchOS2-NewAPI-HealthKit-HeartrateExample
//
//  Created by Wlad Dicario on 14/09/2015.
//  Copyright © 2015 Sweefties. All rights reserved.
//

import WatchKit
import Foundation
import HealthKit

class MainInterfaceController: WKInterfaceController {

    
    // MARK: - Interface
    @IBOutlet var heartImage: WKInterfaceImage!
    @IBOutlet var bpmLabel: WKInterfaceLabel!
    @IBOutlet var bpmCounterLabel: WKInterfaceLabel!
    @IBOutlet var startButton: WKInterfaceButton!
    @IBOutlet var infoLabel: WKInterfaceLabel!
    
    
    // MARK: - Properties
    let healthStore = HKHealthStore()
    
    // define the activity type and location
    let workoutSession = HKWorkoutSession(activityType: HKWorkoutActivityType.crossTraining, locationType: HKWorkoutSessionLocationType.indoor)
    let heartRateUnit = HKUnit(from: "count/min")
    var anchor = HKQueryAnchor(fromValue: Int(HKAnchoredObjectQueryNoAnchor))
    var toggleAction = false
    
    // MARK: - Context Initializer
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)

        setTitle("Heartrate")
        workoutSession.delegate = self
    }

    
    // MARK: - Lifecycle Calls
    override func willActivate() {
        super.willActivate()
        /// Indicates whether HealthKit is available on this device
        guard HKHealthStore.isHealthDataAvailable() == true else {
            infoLabel.setText("not available")
            return
        }
        /// To create samples that store a numerical value
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate) else {
            displayNotAllowed()
            return
        }
        /// Request permission to save and read the specified data types
        let dataTypes = Set(arrayLiteral: quantityType)
        healthStore.requestAuthorization(toShare: nil, read: dataTypes) { (success, error) -> Void in
            if success == false {
                self.displayNotAllowed()
            }
        }
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func displayNotAllowed() {
        setTitle("not allowed")
    }
    
}


//MARK: - HealthKitWorkoutSessionDelegate -> MainInterfaceController
typealias HealthKitWorkoutSessionDelegate = MainInterfaceController
extension HealthKitWorkoutSessionDelegate : HKWorkoutSessionDelegate {
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        DispatchQueue.main.async {
        switch toState {
        case .running:
            self.workoutDidStart(date)
        case .ended:
            self.workoutDidEnd(date)
        default:
            print("unexpected \(toState)")
        }
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("workOutSession Error : \(error.localizedDescription)")
    }
}


//MARK: - HealthKitWorkoutUpdates -> MainInterfaceController
typealias HealthKitWorkoutUpdates = MainInterfaceController
extension HealthKitWorkoutUpdates {
    
    
    /// start workout
    func workoutDidStart(_ date : Date) {
        if let query = createHeartRateStreamingQuery(date) {
            healthStore.execute(query)
        } else {
            infoLabel.setText("cannot start")
        }
    }
    /// stop workout
    func workoutDidEnd(_ date : Date) {
        if let query = createHeartRateStreamingQuery(date) {
            healthStore.stop(query)
            infoLabel.setText("Stop")
        } else {
            infoLabel.setText("cannot stop")
        }
    }
    /// HealthKit - create Heart Rate Streaming query
    func createHeartRateStreamingQuery(_ workoutStartDate: Date) -> HKQuery? {
        // adding predicate will not work
        let predicate = HKQuery.predicateForSamples(withStart: workoutStartDate, end: nil, options: HKQueryOptions())
        
        guard let quantityType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate) else { return nil }
        
        let heartRateQuery = HKAnchoredObjectQuery(type: quantityType, predicate: predicate, anchor: anchor, limit: Int(HKObjectQueryNoLimit)) { (query, sampleObjects, deletedObjects, newAnchor, error) -> Void in
            guard let newAnchor = newAnchor else {return}
            self.anchor = newAnchor
            self.updateHeartRate(sampleObjects)
        }
        
        heartRateQuery.updateHandler = {(query, samples, deleteObjects, newAnchor, error) -> Void in
            self.anchor = newAnchor!
            self.updateHeartRate(samples)
        }
        return heartRateQuery
    }
    /// HealthKit - update Heart Rate with Samples
    func updateHeartRate(_ samples: [HKSample]?) {
        guard let heartRateSamples = samples as? [HKQuantitySample] else {return}
        
        DispatchQueue.main.async {
            guard let sample = heartRateSamples.first else{return}
            let value = sample.quantity.doubleValue(for: self.heartRateUnit)
            self.bpmCounterLabel.setText(String(UInt16(value)))
            
            // retrieve source from sample
            let name = sample.sourceRevision.source.name
            self.updateSourceName(name)
            self.animateHeart()
        }
    }
}


//MARK: - IBActions -> MainInterfaceController
typealias IBActions = MainInterfaceController
extension IBActions {
    
    @IBAction func startButtonAction() {
        if !toggleAction {
            healthStore.start(workoutSession)
            toggleAction = true
            startButton.setBackgroundImageNamed("stop")
        }else{
            healthStore.end(workoutSession)
            toggleAction = false
            startButton.setBackgroundImageNamed("start")
            //TODO: - Stop and save methods (create SessionManager Helper by example..)
            //      - WatchConnectivity to send simultaneous datas in iOS-App parent
        }
    }
}


//MARK: - UIAnimationStyle -> MainInterfaceController
typealias UIAnimationStyle = MainInterfaceController
extension UIAnimationStyle {
    
    func updateSourceName(_ deviceName: String) {
        infoLabel.setText("Source: \(deviceName)")
    }
    
    func animateHeart() {
        self.animate(withDuration: 0.5) {
            self.heartImage.setWidth(50)
            self.heartImage.setHeight(50)
        }
        
        let time = DispatchTime.now() + Double(Int64(0.5 * double_t(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        let global_queue = DispatchQueue.global(qos: .userInteractive)
        global_queue.asyncAfter(deadline: time) {
            DispatchQueue.main.async(execute: {
                self.animate(withDuration: 0.5, animations: {
                    self.heartImage.setWidth(75)
                    self.heartImage.setHeight(75)
                })
            })
        }
    }
}
