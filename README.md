# Keyless

[![Build Status](https://app.bitrise.io/app/d92098b0096b1157/status.svg?token=St__CQ-4FiFt1iJa5rQc9Q&branch=master)](https://app.bitrise.io/app/d92098b0096b1157)
[![iOS](https://img.shields.io/cocoapods/p/CarShare.svg?style=flat)](https://gitlab.voffice.bsmtechnologies.com/bsm/illuminate/mobile/car-share-podspec)

## Publishing

Maintainers should update the version in the Keyless.podspec file to the appropriate version, then tag the commit. For example, for a new version, 2.4.7, the maintainer should push a commit to `Keyless.podspec`, with the version string modified:
```ruby
  s.version = '2.4.7'
```
The maintainer must then push the `v2.4.7` tag, which will trigger [Bitrise](https://app.bitrise.io/app/d92098b0096b1157) to publish a new pod version of the [`Keyless` framework](https://github.com/Geotab/podspecs).

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Installation

Keyless is available through [CocoaPods](https://cocoapods.org). To install it, add the following lines to your Podfile:

```ruby

source 'git@github.com:Geotab/podspecs.git'
source 'https://github.com/CocoaPods/Specs.git'

# add the pod to your target
pod 'Keyless'
```

## Detailed diagram of mobile application and integration points

[SDK Diagrams](Keyless/Classes/README.md)

## Usage

Add a usage description to your Info.plist for the following keys as Bluetooth is required in order for the SDK to operate:
```swift
Privacy - Bluetooth Peripheral Usage Description
Privacy - Bluetooth Always Usage Description
```


The **KeylessClient** class is initialized with default parameters that are already provided by the SDK.
The **KeylessClient** class provides a set of functions that can be used to interact with a Keyless device via Bluetooth. The **KeylessClient** provides feedback to the integrator via the delegate. Therefore, in order to be notified on the status of the execution of a command or the connection attempt, the **KeylessClientDelegate** must be implemented.

**KeylessClient Class**

```swift
public func connect(_ keylessToken: String) throws
```

To communicate with a Keyless device, the connect function must first be invoked with a valid **KeylessToken**.The **keylessToken** parameter represents a valid reservation key which the Keyless device authenticates against. Once the connection has been established, the delegate method ```func clientDidConnect(_ client: KeylessClient)``` is called. Should the connection close suddenly, the delegate method ```func clientDidDisconnectUnexpectedly(_ client: KeylessClient, error: Error)``` is invoked.

```swift
public func execute(_ command: Command, with keylessToken: String) throws
```

With an established connection to the Keyless device, commands can be executed with the command passed in and valid a keylessToken. The execution of the command will result in either the ```func clientCommandDidSucceed(_ client: KeylessClient, command: Command)``` or ```func clientCommandDidFail(_ client: KeylessClient, command: Command, error: Error)``` KeylessClientDelegate method being called.

You can also have more granular control over the vehicle by passing in a set of CarOperations. The execution of the set of CarOperations will result in either the ```func clientOperationsDidSucceed(_ client: KeylessClient, operations: Set<CarOperation>)``` or ```func clientOperationsDidFail(_ client: KeylessClient, operations: Set<CarOperation>, error: Error)``` KeylessClientDelegate method being called.

**Command Enum**

* .checkIn
* .checkOut
* .lock
* .unlockAll
* .locate

### Swift

```swift
import UIKit
import Keyless

class ViewController: UIViewController, KeylessClientDelegate {

    private let client = KeylessClient()

    override func viewDidLoad() {
        super.viewDidLoad()
        client.delegate = self
    }
    
    @IBAction private func didTapConnect(_ sender: Any) {
    //Pass in a KeylessToken from the signing service
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
    
    func clientDidConnect(_ client: KeylessClient) {

    }
    
    func clientCommandDidSucceed(_ client: KeylessClient, command: Command) {

    }
}
```

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

Please make sure to update tests as appropriate.

## License
[MIT](https://choosealicense.com/licenses/mit/)

