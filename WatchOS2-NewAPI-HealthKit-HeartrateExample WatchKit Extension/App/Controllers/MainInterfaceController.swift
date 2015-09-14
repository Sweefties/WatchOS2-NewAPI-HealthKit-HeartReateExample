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
    let workoutSession = HKWorkoutSession(activityType: HKWorkoutActivityType.CrossTraining, locationType: HKWorkoutSessionLocationType.Indoor)
    let heartRateUnit = HKUnit(fromString: "count/min")
    var anchor = HKQueryAnchor(fromValue: Int(HKAnchoredObjectQueryNoAnchor))
    var toggleAction = false
    
    // MARK: - Context Initializer
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)

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
        guard let quantityType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate) else {
            displayNotAllowed()
            return
        }
        /// Request permission to save and read the specified data types
        let dataTypes = Set(arrayLiteral: quantityType)
        healthStore.requestAuthorizationToShareTypes(nil, readTypes: dataTypes) { (success, error) -> Void in
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
    
    func workoutSession(workoutSession: HKWorkoutSession, didChangeToState toState: HKWorkoutSessionState, fromState: HKWorkoutSessionState, date: NSDate) {
        dispatch_async(dispatch_get_main_queue()) {
        switch toState {
        case .Running:
            self.workoutDidStart(date)
        case .Ended:
            self.workoutDidEnd(date)
        default:
            print("unexpected \(toState)")
        }
        }
    }
    
    func workoutSession(workoutSession: HKWorkoutSession, didFailWithError error: NSError) {
        print("workOutSession Error : \(error.localizedDescription)")
    }
}


//MARK: - HealthKitWorkoutUpdates -> MainInterfaceController
typealias HealthKitWorkoutUpdates = MainInterfaceController
extension HealthKitWorkoutUpdates {
    
    
    /// start workout
    func workoutDidStart(date : NSDate) {
        if let query = createHeartRateStreamingQuery(date) {
            healthStore.executeQuery(query)
        } else {
            infoLabel.setText("cannot start")
        }
    }
    /// stop workout
    func workoutDidEnd(date : NSDate) {
        if let query = createHeartRateStreamingQuery(date) {
            healthStore.stopQuery(query)
            infoLabel.setText("Stop")
        } else {
            infoLabel.setText("cannot stop")
        }
    }
    /// HealthKit - create Heart Rate Streaming query
    func createHeartRateStreamingQuery(workoutStartDate: NSDate) -> HKQuery? {
        // adding predicate will not work
        let predicate = HKQuery.predicateForSamplesWithStartDate(workoutStartDate, endDate: nil, options: HKQueryOptions.None)
        
        guard let quantityType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate) else { return nil }
        
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
    func updateHeartRate(samples: [HKSample]?) {
        guard let heartRateSamples = samples as? [HKQuantitySample] else {return}
        
        dispatch_async(dispatch_get_main_queue()) {
            guard let sample = heartRateSamples.first else{return}
            let value = sample.quantity.doubleValueForUnit(self.heartRateUnit)
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
            healthStore.startWorkoutSession(workoutSession)
            toggleAction = true
            startButton.setBackgroundImageNamed("stop")
        }else{
            healthStore.endWorkoutSession(workoutSession)
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
    
    func updateSourceName(deviceName: String) {
        infoLabel.setText("Source: \(deviceName)")
    }
    
    func animateHeart() {
        self.animateWithDuration(0.5) {
            self.heartImage.setWidth(50)
            self.heartImage.setHeight(50)
        }
        
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(0.5 * double_t(NSEC_PER_SEC)))
        let global_queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        dispatch_after(time, global_queue) {
            dispatch_async(dispatch_get_main_queue(), {
                self.animateWithDuration(0.5, animations: {
                    self.heartImage.setWidth(75)
                    self.heartImage.setHeight(75)
                })
            })
        }
    }
}