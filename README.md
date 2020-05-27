# CarShare

[![Build Status](https://app.bitrise.io/app/d92098b0096b1157/status.svg?token=St__CQ-4FiFt1iJa5rQc9Q&branch=master)](https://app.bitrise.io/app/d92098b0096b1157)
[![iOS](https://img.shields.io/cocoapods/p/CarShare.svg?style=flat)](https://gitlab.voffice.bsmtechnologies.com/bsm/illuminate/mobile/car-share-podspec)

## Publishing

Maintainers should update the version in the CarShare.podspec file to the appropriate version, then tag the commit. For example, for a new version, 2.4.7, the maintainer should push a commit to `CarShare.podspec`, with the version string modified:
```ruby
  s.version = '2.4.7'
```
The maintainer must then push the `v2.4.7` tag, which will trigger [Bitrise](https://app.bitrise.io/app/d92098b0096b1157) to publish a new pod version of the [`CarShare` framework](https://gitlab.voffice.bsmtechnologies.com/bsm/illuminate/mobile/car-share-podspec).

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Installation

CarShare is available through [CocoaPods](https://cocoapods.org). To install it, add the following lines to your Podfile:

```ruby

source 'git@github.com:Geotab/carshare-sdk-podspec.git'
source 'https://github.com/CocoaPods/Specs.git'

# add the pod to your target
pod 'CarShare'
```

## Detailed diagram of mobile application and integration points

[SDK Diagrams](CarShare/Classes/README.md)

## Usage

Add a usage description to your Info.plist for the following keys as Bluetooth is required in order for the SDK to operate:
```swift
Privacy - Bluetooth Peripheral Usage Description
Privacy - Bluetooth Always Usage Description
```


The **CarShareClient** class is initialized with default parameters that are already provided by the SDK.
The **CarShareClient** class provides a set of functions that can be used to interact with a CarShare device via Bluetooth. The **CarShareClient** provides feedback to the integrator via the delegate. Therefore, in order to be notified on the status of the execution of a command or the connection attempt, the **CarShareClientDelegate** must be implemented.

**CarShareClient Class**

```swift
public func connect(_ carShareToken: String) throws
```

To communicate with a carshare device, the connect function must first be invoked with a valid **CarShareToken**.The **carShareToken** parameter represents a valid reservation key which the carshare device authenticates against. Once the connection has been established, the delegate method ```func clientDidConnect(_ client: CarShareClient)``` is called. Should the connection close suddenly, the delegate method ```func clientDidDisconnectUnexpectedly(_ client: CarShareClient, error: Error)``` is invoked.

```swift
public func execute(_ command: Command, with carShareToken: String) throws
```

With an established connection to the carshare device, commands can be executed with the command passed in and valid a carshareToken. The execution of the command will result in either the ```func clientCommandDidSucceed(_ client: CarShareClient, command: Command)``` or ```func clientCommandDidFail(_ client: CarShareClient, command: Command, error: Error)``` CarShareClientDelegate method being called.

You can also have more granular control over the vehicle by passing in a set of CarOperations. The execution of the set of CarOperations will result in either the ```func clientOperationsDidSucceed(_ client: CarShareClient, operations: Set<CarOperation>)``` or ```func clientOperationsDidFail(_ client: CarShareClient, operations: Set<CarOperation>, error: Error)``` CarShareClientDelegate method being called.

**Command Enum**

* .checkIn
* .checkOut
* .lock
* .unlockAll
* .locate

### Swift

```swift
import UIKit
import CarShare

class ViewController: UIViewController, CarShareClientDelegate {

    private let client = CarShareClient()

    override func viewDidLoad() {
        super.viewDidLoad()
        client.delegate = self
    }
    
    @IBAction private func didTapConnect(_ sender: Any) {
    //Pass in a CarShareToken from the signing service
        do {
            try client.connect(reservation)
        } catch {
            print(error)
        }
    }
    
    @IBAction private func didTapCheckIn() {
        do {
            try client.execute(.checkIn, with: reservation)
        } catch {
            print(error)
        }
    }
    
    func clientDidConnect(_ client: CarShareClient) {

    }
    
    func clientCommandDidSucceed(_ client: CarShareClient, command: Command) {

    }
}
```

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

Please make sure to update tests as appropriate.

## License
[MIT](https://choosealicense.com/licenses/mit/)

