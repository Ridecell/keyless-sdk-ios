# CarShare

[![Build Status](https://app.bitrise.io/app/d92098b0096b1157/status.svg?token=St__CQ-4FiFt1iJa5rQc9Q&branch=master)](https://app.bitrise.io/app/d92098b0096b1157)
[![iOS](https://img.shields.io/cocoapods/p/CarShare.svg?style=flat)](https://gitlab.voffice.bsmtechnologies.com/bsm/illuminate/mobile/car-share-podspec)

## Publishing

Maintainers should update the version in the CarShare.podspec file to the appropriate version, then tag the commit. For example, for a new version, 2.4.7, the maintainer should push a commit to `CarShare.podspec`, with the version string modified:
```ruby
  s.version = '2.4.7'
```
The maintainer must then push the `vx.x.x` tag, which will trigger [Bitrise](https://app.bitrise.io/app/d92098b0096b1157) to publish a new pod version of the [`CarShare` framework](https://gitlab.voffice.bsmtechnologies.com/bsm/illuminate/mobile/car-share-podspec).

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

CarShare is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'CarShare'
```

## Author

msnow-bsm, matt.snow@bsmtechnologies.com

## License

CarShare is available under the MIT license. See the LICENSE file for more info.
