![](https://img.shields.io/badge/build-pass-brightgreen.svg?style=flat-square)
![](https://img.shields.io/badge/platform-WatchOS2-ff69b4.svg?style=flat-square)
![](https://img.shields.io/badge/Require-XCode7-lightgrey.svg?style=flat-square)


# WatchOS2 - New API - HealthKit - Heartrate Example
WatchOS 2 Experiments - New API Components - Heartrate with HealthKit Framework.

## Example

![](https://raw.githubusercontent.com/Sweefties/WatchOS2-NewAPI-HealthKit-HeartrateExample/master/source/Apple_Watch_template-HealthKit-HeartRate.jpg)


## Requirements

- >= XCode 7.
- >= Swift 2.
- >= WatchOS2.

Tested on WatchOS2, iOS 9.1 Simulators.


## Usage

To run the example project, download or clone the repo.


## Caution

- HealthKit required in linked Framework and libraries.
- You must allow app to access your streaming heartrate from iPhone
- Change the 'Team' setting on [General] for each target.

### Example Code!


Configure :

- Customize your Interface Controller (Storyboard)
- import HealthKit to your Interface Controller class

```swift
// create store object
let healthStore = HKHealthStore()

// create HKWorkoutSession with ActivityType (Cycling, Walking ...)
let workoutSession = HKWorkoutSession(activityType: HKWorkoutActivityType.CrossTraining, locationType: HKWorkoutSessionLocationType.Indoor)
let heartRateUnit = HKUnit(fromString: "count/min")
var anchor = HKQueryAnchor(fromValue: Int(HKAnchoredObjectQueryNoAnchor))

```

- in interface context object method

```swift
workoutSession.delegate = self
```

- in willActivate() method

```swift
/// Indicates whether HealthKit is available on this device
guard HKHealthStore.isHealthDataAvailable() == true else {
    infoLabel.setText("not available")
    return
}
/// To create samples that store a numerical value
guard let quantityType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate) else {
    //..
    return
}
/// Request permission to save and read the specified data types
let dataTypes = Set(arrayLiteral: quantityType)
healthStore.requestAuthorizationToShareTypes(nil, readTypes: dataTypes) { (success, error) -> Void in
    if success == false {
        //..
    }
}
```

- HKWorkoutSessionDelegate required
```swift
extension WKInterfaceController : HKWorkoutSessionDelegate {

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
```

Build and Run on simulator or physical watch!
Get datas in Health App!
