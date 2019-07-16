// DO NOT EDIT.
//
// Generated by the Swift generator plugin for the protocol buffer compiler.
// Source: geotab.proto
//
// For information on using the generated types, please see the documenation:
//   https://github.com/apple/swift-protobuf/

import Foundation
import SwiftProtobuf

// If the compiler emits an error on this type, it is because this file
// was generated by a version of the `protoc` Swift plug-in that is
// incompatible with the version of SwiftProtobuf to which you are linking.
// Please ensure that your are building against the same version of the API
// that was used to generate this file.
fileprivate struct _GeneratedWithProtocGenSwiftVersion: SwiftProtobuf.ProtobufAPIVersionCheck {
  struct _2: SwiftProtobuf.ProtobufAPIVersion_2 {}
  typealias Version = _2
}

enum Permission_t: SwiftProtobuf.Enum {
  typealias RawValue = Int
  case unlock // = 0
  case lock // = 1
  case mobilize // = 2
  case locate // = 3
  case checkin // = 4
  case checkout // = 5

  init() {
    self = .unlock
  }

  init?(rawValue: Int) {
    switch rawValue {
    case 0: self = .unlock
    case 1: self = .lock
    case 2: self = .mobilize
    case 3: self = .locate
    case 4: self = .checkin
    case 5: self = .checkout
    default: return nil
    }
  }

  var rawValue: Int {
    switch self {
    case .unlock: return 0
    case .lock: return 1
    case .mobilize: return 2
    case .locate: return 3
    case .checkin: return 4
    case .checkout: return 5
    }
  }

}

#if swift(>=4.2)

extension Permission_t: CaseIterable {
  // Support synthesized by the compiler.
}

#endif  // swift(>=4.2)

struct ReservationMessage {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var reservationID: Data {
    get {return _storage._reservationID ?? SwiftProtobuf.Internal.emptyData}
    set {_uniqueStorage()._reservationID = newValue}
  }
  /// Returns true if `reservationID` has been explicitly set.
  var hasReservationID: Bool {return _storage._reservationID != nil}
  /// Clears the value of `reservationID`. Subsequent reads from it will return its default value.
  mutating func clearReservationID() {_uniqueStorage()._reservationID = nil}

  var appPrivateKey: Data {
    get {return _storage._appPrivateKey ?? SwiftProtobuf.Internal.emptyData}
    set {_uniqueStorage()._appPrivateKey = newValue}
  }
  /// Returns true if `appPrivateKey` has been explicitly set.
  var hasAppPrivateKey: Bool {return _storage._appPrivateKey != nil}
  /// Clears the value of `appPrivateKey`. Subsequent reads from it will return its default value.
  mutating func clearAppPrivateKey() {_uniqueStorage()._appPrivateKey = nil}

  var reservationTokenSignature: Data {
    get {return _storage._reservationTokenSignature ?? SwiftProtobuf.Internal.emptyData}
    set {_uniqueStorage()._reservationTokenSignature = newValue}
  }
  /// Returns true if `reservationTokenSignature` has been explicitly set.
  var hasReservationTokenSignature: Bool {return _storage._reservationTokenSignature != nil}
  /// Clears the value of `reservationTokenSignature`. Subsequent reads from it will return its default value.
  mutating func clearReservationTokenSignature() {_uniqueStorage()._reservationTokenSignature = nil}

  var reservationToken: ReservationToken_t {
    get {return _storage._reservationToken ?? ReservationToken_t()}
    set {_uniqueStorage()._reservationToken = newValue}
  }
  /// Returns true if `reservationToken` has been explicitly set.
  var hasReservationToken: Bool {return _storage._reservationToken != nil}
  /// Clears the value of `reservationToken`. Subsequent reads from it will return its default value.
  mutating func clearReservationToken() {_uniqueStorage()._reservationToken = nil}

  var directCommand: Account_t {
    get {return _storage._directCommand ?? Account_t()}
    set {_uniqueStorage()._directCommand = newValue}
  }
  /// Returns true if `directCommand` has been explicitly set.
  var hasDirectCommand: Bool {return _storage._directCommand != nil}
  /// Clears the value of `directCommand`. Subsequent reads from it will return its default value.
  mutating func clearDirectCommand() {_uniqueStorage()._directCommand = nil}

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}

  fileprivate var _storage = _StorageClass.defaultInstance
}

struct ReservationToken_t {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var appPublicKey: Data {
    get {return _storage._appPublicKey ?? SwiftProtobuf.Internal.emptyData}
    set {_uniqueStorage()._appPublicKey = newValue}
  }
  /// Returns true if `appPublicKey` has been explicitly set.
  var hasAppPublicKey: Bool {return _storage._appPublicKey != nil}
  /// Clears the value of `appPublicKey`. Subsequent reads from it will return its default value.
  mutating func clearAppPublicKey() {_uniqueStorage()._appPublicKey = nil}

  var keyExpiry: UInt64 {
    get {return _storage._keyExpiry ?? 0}
    set {_uniqueStorage()._keyExpiry = newValue}
  }
  /// Returns true if `keyExpiry` has been explicitly set.
  var hasKeyExpiry: Bool {return _storage._keyExpiry != nil}
  /// Clears the value of `keyExpiry`. Subsequent reads from it will return its default value.
  mutating func clearKeyExpiry() {_uniqueStorage()._keyExpiry = nil}

  var reservationID: Data {
    get {return _storage._reservationID ?? SwiftProtobuf.Internal.emptyData}
    set {_uniqueStorage()._reservationID = newValue}
  }
  /// Returns true if `reservationID` has been explicitly set.
  var hasReservationID: Bool {return _storage._reservationID != nil}
  /// Clears the value of `reservationID`. Subsequent reads from it will return its default value.
  mutating func clearReservationID() {_uniqueStorage()._reservationID = nil}

  var deviceHardwareID: UInt64 {
    get {return _storage._deviceHardwareID ?? 0}
    set {_uniqueStorage()._deviceHardwareID = newValue}
  }
  /// Returns true if `deviceHardwareID` has been explicitly set.
  var hasDeviceHardwareID: Bool {return _storage._deviceHardwareID != nil}
  /// Clears the value of `deviceHardwareID`. Subsequent reads from it will return its default value.
  mutating func clearDeviceHardwareID() {_uniqueStorage()._deviceHardwareID = nil}

  var account: Account_t {
    get {return _storage._account ?? Account_t()}
    set {_uniqueStorage()._account = newValue}
  }
  /// Returns true if `account` has been explicitly set.
  var hasAccount: Bool {return _storage._account != nil}
  /// Clears the value of `account`. Subsequent reads from it will return its default value.
  mutating func clearAccount() {_uniqueStorage()._account = nil}

  var reservationStartTime: UInt64 {
    get {return _storage._reservationStartTime ?? 0}
    set {_uniqueStorage()._reservationStartTime = newValue}
  }
  /// Returns true if `reservationStartTime` has been explicitly set.
  var hasReservationStartTime: Bool {return _storage._reservationStartTime != nil}
  /// Clears the value of `reservationStartTime`. Subsequent reads from it will return its default value.
  mutating func clearReservationStartTime() {_uniqueStorage()._reservationStartTime = nil}

  var reservationEndTime: UInt64 {
    get {return _storage._reservationEndTime ?? 0}
    set {_uniqueStorage()._reservationEndTime = newValue}
  }
  /// Returns true if `reservationEndTime` has been explicitly set.
  var hasReservationEndTime: Bool {return _storage._reservationEndTime != nil}
  /// Clears the value of `reservationEndTime`. Subsequent reads from it will return its default value.
  mutating func clearReservationEndTime() {_uniqueStorage()._reservationEndTime = nil}

  var gracePeriodSeconds: UInt32 {
    get {return _storage._gracePeriodSeconds ?? 0}
    set {_uniqueStorage()._gracePeriodSeconds = newValue}
  }
  /// Returns true if `gracePeriodSeconds` has been explicitly set.
  var hasGracePeriodSeconds: Bool {return _storage._gracePeriodSeconds != nil}
  /// Clears the value of `gracePeriodSeconds`. Subsequent reads from it will return its default value.
  mutating func clearGracePeriodSeconds() {_uniqueStorage()._gracePeriodSeconds = nil}

  var securePeriodSeconds: UInt32 {
    get {return _storage._securePeriodSeconds ?? 0}
    set {_uniqueStorage()._securePeriodSeconds = newValue}
  }
  /// Returns true if `securePeriodSeconds` has been explicitly set.
  var hasSecurePeriodSeconds: Bool {return _storage._securePeriodSeconds != nil}
  /// Clears the value of `securePeriodSeconds`. Subsequent reads from it will return its default value.
  mutating func clearSecurePeriodSeconds() {_uniqueStorage()._securePeriodSeconds = nil}

  var endBookConditions: EndBookConditions_t {
    get {return _storage._endBookConditions ?? EndBookConditions_t()}
    set {_uniqueStorage()._endBookConditions = newValue}
  }
  /// Returns true if `endBookConditions` has been explicitly set.
  var hasEndBookConditions: Bool {return _storage._endBookConditions != nil}
  /// Clears the value of `endBookConditions`. Subsequent reads from it will return its default value.
  mutating func clearEndBookConditions() {_uniqueStorage()._endBookConditions = nil}

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}

  fileprivate var _storage = _StorageClass.defaultInstance
}

struct Account_t {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var id: UInt32 {
    get {return _id ?? 0}
    set {_id = newValue}
  }
  /// Returns true if `id` has been explicitly set.
  var hasID: Bool {return self._id != nil}
  /// Clears the value of `id`. Subsequent reads from it will return its default value.
  mutating func clearID() {self._id = nil}

  var permissions: Permission_t {
    get {return _permissions ?? .unlock}
    set {_permissions = newValue}
  }
  /// Returns true if `permissions` has been explicitly set.
  var hasPermissions: Bool {return self._permissions != nil}
  /// Clears the value of `permissions`. Subsequent reads from it will return its default value.
  mutating func clearPermissions() {self._permissions = nil}

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}

  fileprivate var _id: UInt32? = nil
  fileprivate var _permissions: Permission_t? = nil
}

struct EndBookConditions_t {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var requireWindowsUp: Bool {
    get {return _storage._requireWindowsUp ?? false}
    set {_uniqueStorage()._requireWindowsUp = newValue}
  }
  /// Returns true if `requireWindowsUp` has been explicitly set.
  var hasRequireWindowsUp: Bool {return _storage._requireWindowsUp != nil}
  /// Clears the value of `requireWindowsUp`. Subsequent reads from it will return its default value.
  mutating func clearRequireWindowsUp() {_uniqueStorage()._requireWindowsUp = nil}

  var requireSunroofClosed: Bool {
    get {return _storage._requireSunroofClosed ?? false}
    set {_uniqueStorage()._requireSunroofClosed = newValue}
  }
  /// Returns true if `requireSunroofClosed` has been explicitly set.
  var hasRequireSunroofClosed: Bool {return _storage._requireSunroofClosed != nil}
  /// Clears the value of `requireSunroofClosed`. Subsequent reads from it will return its default value.
  mutating func clearRequireSunroofClosed() {_uniqueStorage()._requireSunroofClosed = nil}

  var requireConvertibleClosed: Bool {
    get {return _storage._requireConvertibleClosed ?? false}
    set {_uniqueStorage()._requireConvertibleClosed = newValue}
  }
  /// Returns true if `requireConvertibleClosed` has been explicitly set.
  var hasRequireConvertibleClosed: Bool {return _storage._requireConvertibleClosed != nil}
  /// Clears the value of `requireConvertibleClosed`. Subsequent reads from it will return its default value.
  mutating func clearRequireConvertibleClosed() {_uniqueStorage()._requireConvertibleClosed = nil}

  var requireDoorsClosed: Bool {
    get {return _storage._requireDoorsClosed ?? false}
    set {_uniqueStorage()._requireDoorsClosed = newValue}
  }
  /// Returns true if `requireDoorsClosed` has been explicitly set.
  var hasRequireDoorsClosed: Bool {return _storage._requireDoorsClosed != nil}
  /// Clears the value of `requireDoorsClosed`. Subsequent reads from it will return its default value.
  mutating func clearRequireDoorsClosed() {_uniqueStorage()._requireDoorsClosed = nil}

  var requireIgnitionOff: Bool {
    get {return _storage._requireIgnitionOff ?? false}
    set {_uniqueStorage()._requireIgnitionOff = newValue}
  }
  /// Returns true if `requireIgnitionOff` has been explicitly set.
  var hasRequireIgnitionOff: Bool {return _storage._requireIgnitionOff != nil}
  /// Clears the value of `requireIgnitionOff`. Subsequent reads from it will return its default value.
  mutating func clearRequireIgnitionOff() {_uniqueStorage()._requireIgnitionOff = nil}

  var requireLightsOff: Bool {
    get {return _storage._requireLightsOff ?? false}
    set {_uniqueStorage()._requireLightsOff = newValue}
  }
  /// Returns true if `requireLightsOff` has been explicitly set.
  var hasRequireLightsOff: Bool {return _storage._requireLightsOff != nil}
  /// Clears the value of `requireLightsOff`. Subsequent reads from it will return its default value.
  mutating func clearRequireLightsOff() {_uniqueStorage()._requireLightsOff = nil}

  var homePoint: Gps_t {
    get {return _storage._homePoint ?? Gps_t()}
    set {_uniqueStorage()._homePoint = newValue}
  }
  /// Returns true if `homePoint` has been explicitly set.
  var hasHomePoint: Bool {return _storage._homePoint != nil}
  /// Clears the value of `homePoint`. Subsequent reads from it will return its default value.
  mutating func clearHomePoint() {_uniqueStorage()._homePoint = nil}

  var homeRadius: UInt32 {
    get {return _storage._homeRadius ?? 0}
    set {_uniqueStorage()._homeRadius = newValue}
  }
  /// Returns true if `homeRadius` has been explicitly set.
  var hasHomeRadius: Bool {return _storage._homeRadius != nil}
  /// Clears the value of `homeRadius`. Subsequent reads from it will return its default value.
  mutating func clearHomeRadius() {_uniqueStorage()._homeRadius = nil}

  var fuelTankGreaterThan: Float {
    get {return _storage._fuelTankGreaterThan ?? 0}
    set {_uniqueStorage()._fuelTankGreaterThan = newValue}
  }
  /// Returns true if `fuelTankGreaterThan` has been explicitly set.
  var hasFuelTankGreaterThan: Bool {return _storage._fuelTankGreaterThan != nil}
  /// Clears the value of `fuelTankGreaterThan`. Subsequent reads from it will return its default value.
  mutating func clearFuelTankGreaterThan() {_uniqueStorage()._fuelTankGreaterThan = nil}

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}

  fileprivate var _storage = _StorageClass.defaultInstance
}

struct Gps_t {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var latitude: Float {
    get {return _latitude ?? 0}
    set {_latitude = newValue}
  }
  /// Returns true if `latitude` has been explicitly set.
  var hasLatitude: Bool {return self._latitude != nil}
  /// Clears the value of `latitude`. Subsequent reads from it will return its default value.
  mutating func clearLatitude() {self._latitude = nil}

  var longitude: Float {
    get {return _longitude ?? 0}
    set {_longitude = newValue}
  }
  /// Returns true if `longitude` has been explicitly set.
  var hasLongitude: Bool {return self._longitude != nil}
  /// Clears the value of `longitude`. Subsequent reads from it will return its default value.
  mutating func clearLongitude() {self._longitude = nil}

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}

  fileprivate var _latitude: Float? = nil
  fileprivate var _longitude: Float? = nil
}

// MARK: - Code below here is support for the SwiftProtobuf runtime.

extension Permission_t: SwiftProtobuf._ProtoNameProviding {
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    0: .same(proto: "UNLOCK"),
    1: .same(proto: "LOCK"),
    2: .same(proto: "MOBILIZE"),
    3: .same(proto: "LOCATE"),
    4: .same(proto: "CHECKIN"),
    5: .same(proto: "CHECKOUT"),
  ]
}

extension ReservationMessage: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = "ReservationMessage"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "reservationId"),
    2: .same(proto: "appPrivateKey"),
    3: .same(proto: "reservationTokenSignature"),
    4: .same(proto: "reservationToken"),
    5: .same(proto: "directCommand"),
  ]

  fileprivate class _StorageClass {
    var _reservationID: Data? = nil
    var _appPrivateKey: Data? = nil
    var _reservationTokenSignature: Data? = nil
    var _reservationToken: ReservationToken_t? = nil
    var _directCommand: Account_t? = nil

    static let defaultInstance = _StorageClass()

    private init() {}

    init(copying source: _StorageClass) {
      _reservationID = source._reservationID
      _appPrivateKey = source._appPrivateKey
      _reservationTokenSignature = source._reservationTokenSignature
      _reservationToken = source._reservationToken
      _directCommand = source._directCommand
    }
  }

  fileprivate mutating func _uniqueStorage() -> _StorageClass {
    if !isKnownUniquelyReferenced(&_storage) {
      _storage = _StorageClass(copying: _storage)
    }
    return _storage
  }

  public var isInitialized: Bool {
    return withExtendedLifetime(_storage) { (_storage: _StorageClass) in
      if _storage._reservationID == nil {return false}
      if _storage._appPrivateKey == nil {return false}
      if _storage._reservationTokenSignature == nil {return false}
      if _storage._reservationToken == nil {return false}
      if _storage._directCommand == nil {return false}
      if let v = _storage._reservationToken, !v.isInitialized {return false}
      if let v = _storage._directCommand, !v.isInitialized {return false}
      return true
    }
  }

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    _ = _uniqueStorage()
    try withExtendedLifetime(_storage) { (_storage: _StorageClass) in
      while let fieldNumber = try decoder.nextFieldNumber() {
        switch fieldNumber {
        case 1: try decoder.decodeSingularBytesField(value: &_storage._reservationID)
        case 2: try decoder.decodeSingularBytesField(value: &_storage._appPrivateKey)
        case 3: try decoder.decodeSingularBytesField(value: &_storage._reservationTokenSignature)
        case 4: try decoder.decodeSingularMessageField(value: &_storage._reservationToken)
        case 5: try decoder.decodeSingularMessageField(value: &_storage._directCommand)
        default: break
        }
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    try withExtendedLifetime(_storage) { (_storage: _StorageClass) in
      if let v = _storage._reservationID {
        try visitor.visitSingularBytesField(value: v, fieldNumber: 1)
      }
      if let v = _storage._appPrivateKey {
        try visitor.visitSingularBytesField(value: v, fieldNumber: 2)
      }
      if let v = _storage._reservationTokenSignature {
        try visitor.visitSingularBytesField(value: v, fieldNumber: 3)
      }
      if let v = _storage._reservationToken {
        try visitor.visitSingularMessageField(value: v, fieldNumber: 4)
      }
      if let v = _storage._directCommand {
        try visitor.visitSingularMessageField(value: v, fieldNumber: 5)
      }
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: ReservationMessage, rhs: ReservationMessage) -> Bool {
    if lhs._storage !== rhs._storage {
      let storagesAreEqual: Bool = withExtendedLifetime((lhs._storage, rhs._storage)) { (_args: (_StorageClass, _StorageClass)) in
        let _storage = _args.0
        let rhs_storage = _args.1
        if _storage._reservationID != rhs_storage._reservationID {return false}
        if _storage._appPrivateKey != rhs_storage._appPrivateKey {return false}
        if _storage._reservationTokenSignature != rhs_storage._reservationTokenSignature {return false}
        if _storage._reservationToken != rhs_storage._reservationToken {return false}
        if _storage._directCommand != rhs_storage._directCommand {return false}
        return true
      }
      if !storagesAreEqual {return false}
    }
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension ReservationToken_t: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = "ReservationToken_t"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "appPublicKey"),
    2: .same(proto: "keyExpiry"),
    3: .same(proto: "reservationId"),
    4: .same(proto: "deviceHardwareId"),
    5: .same(proto: "account"),
    6: .same(proto: "reservationStartTime"),
    7: .same(proto: "reservationEndTime"),
    8: .same(proto: "gracePeriodSeconds"),
    9: .same(proto: "securePeriodSeconds"),
    10: .same(proto: "endBookConditions"),
  ]

  fileprivate class _StorageClass {
    var _appPublicKey: Data? = nil
    var _keyExpiry: UInt64? = nil
    var _reservationID: Data? = nil
    var _deviceHardwareID: UInt64? = nil
    var _account: Account_t? = nil
    var _reservationStartTime: UInt64? = nil
    var _reservationEndTime: UInt64? = nil
    var _gracePeriodSeconds: UInt32? = nil
    var _securePeriodSeconds: UInt32? = nil
    var _endBookConditions: EndBookConditions_t? = nil

    static let defaultInstance = _StorageClass()

    private init() {}

    init(copying source: _StorageClass) {
      _appPublicKey = source._appPublicKey
      _keyExpiry = source._keyExpiry
      _reservationID = source._reservationID
      _deviceHardwareID = source._deviceHardwareID
      _account = source._account
      _reservationStartTime = source._reservationStartTime
      _reservationEndTime = source._reservationEndTime
      _gracePeriodSeconds = source._gracePeriodSeconds
      _securePeriodSeconds = source._securePeriodSeconds
      _endBookConditions = source._endBookConditions
    }
  }

  fileprivate mutating func _uniqueStorage() -> _StorageClass {
    if !isKnownUniquelyReferenced(&_storage) {
      _storage = _StorageClass(copying: _storage)
    }
    return _storage
  }

  public var isInitialized: Bool {
    return withExtendedLifetime(_storage) { (_storage: _StorageClass) in
      if _storage._appPublicKey == nil {return false}
      if _storage._keyExpiry == nil {return false}
      if _storage._reservationID == nil {return false}
      if _storage._deviceHardwareID == nil {return false}
      if _storage._account == nil {return false}
      if _storage._reservationStartTime == nil {return false}
      if _storage._reservationEndTime == nil {return false}
      if _storage._gracePeriodSeconds == nil {return false}
      if _storage._securePeriodSeconds == nil {return false}
      if _storage._endBookConditions == nil {return false}
      if let v = _storage._account, !v.isInitialized {return false}
      if let v = _storage._endBookConditions, !v.isInitialized {return false}
      return true
    }
  }

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    _ = _uniqueStorage()
    try withExtendedLifetime(_storage) { (_storage: _StorageClass) in
      while let fieldNumber = try decoder.nextFieldNumber() {
        switch fieldNumber {
        case 1: try decoder.decodeSingularBytesField(value: &_storage._appPublicKey)
        case 2: try decoder.decodeSingularUInt64Field(value: &_storage._keyExpiry)
        case 3: try decoder.decodeSingularBytesField(value: &_storage._reservationID)
        case 4: try decoder.decodeSingularUInt64Field(value: &_storage._deviceHardwareID)
        case 5: try decoder.decodeSingularMessageField(value: &_storage._account)
        case 6: try decoder.decodeSingularUInt64Field(value: &_storage._reservationStartTime)
        case 7: try decoder.decodeSingularUInt64Field(value: &_storage._reservationEndTime)
        case 8: try decoder.decodeSingularUInt32Field(value: &_storage._gracePeriodSeconds)
        case 9: try decoder.decodeSingularUInt32Field(value: &_storage._securePeriodSeconds)
        case 10: try decoder.decodeSingularMessageField(value: &_storage._endBookConditions)
        default: break
        }
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    try withExtendedLifetime(_storage) { (_storage: _StorageClass) in
      if let v = _storage._appPublicKey {
        try visitor.visitSingularBytesField(value: v, fieldNumber: 1)
      }
      if let v = _storage._keyExpiry {
        try visitor.visitSingularUInt64Field(value: v, fieldNumber: 2)
      }
      if let v = _storage._reservationID {
        try visitor.visitSingularBytesField(value: v, fieldNumber: 3)
      }
      if let v = _storage._deviceHardwareID {
        try visitor.visitSingularUInt64Field(value: v, fieldNumber: 4)
      }
      if let v = _storage._account {
        try visitor.visitSingularMessageField(value: v, fieldNumber: 5)
      }
      if let v = _storage._reservationStartTime {
        try visitor.visitSingularUInt64Field(value: v, fieldNumber: 6)
      }
      if let v = _storage._reservationEndTime {
        try visitor.visitSingularUInt64Field(value: v, fieldNumber: 7)
      }
      if let v = _storage._gracePeriodSeconds {
        try visitor.visitSingularUInt32Field(value: v, fieldNumber: 8)
      }
      if let v = _storage._securePeriodSeconds {
        try visitor.visitSingularUInt32Field(value: v, fieldNumber: 9)
      }
      if let v = _storage._endBookConditions {
        try visitor.visitSingularMessageField(value: v, fieldNumber: 10)
      }
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: ReservationToken_t, rhs: ReservationToken_t) -> Bool {
    if lhs._storage !== rhs._storage {
      let storagesAreEqual: Bool = withExtendedLifetime((lhs._storage, rhs._storage)) { (_args: (_StorageClass, _StorageClass)) in
        let _storage = _args.0
        let rhs_storage = _args.1
        if _storage._appPublicKey != rhs_storage._appPublicKey {return false}
        if _storage._keyExpiry != rhs_storage._keyExpiry {return false}
        if _storage._reservationID != rhs_storage._reservationID {return false}
        if _storage._deviceHardwareID != rhs_storage._deviceHardwareID {return false}
        if _storage._account != rhs_storage._account {return false}
        if _storage._reservationStartTime != rhs_storage._reservationStartTime {return false}
        if _storage._reservationEndTime != rhs_storage._reservationEndTime {return false}
        if _storage._gracePeriodSeconds != rhs_storage._gracePeriodSeconds {return false}
        if _storage._securePeriodSeconds != rhs_storage._securePeriodSeconds {return false}
        if _storage._endBookConditions != rhs_storage._endBookConditions {return false}
        return true
      }
      if !storagesAreEqual {return false}
    }
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Account_t: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = "Account_t"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "id"),
    2: .same(proto: "permissions"),
  ]

  public var isInitialized: Bool {
    if self._id == nil {return false}
    return true
  }

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      switch fieldNumber {
      case 1: try decoder.decodeSingularUInt32Field(value: &self._id)
      case 2: try decoder.decodeSingularEnumField(value: &self._permissions)
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if let v = self._id {
      try visitor.visitSingularUInt32Field(value: v, fieldNumber: 1)
    }
    if let v = self._permissions {
      try visitor.visitSingularEnumField(value: v, fieldNumber: 2)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: Account_t, rhs: Account_t) -> Bool {
    if lhs._id != rhs._id {return false}
    if lhs._permissions != rhs._permissions {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension EndBookConditions_t: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = "EndBookConditions_t"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "requireWindowsUp"),
    2: .same(proto: "requireSunroofClosed"),
    3: .same(proto: "requireConvertibleClosed"),
    4: .same(proto: "requireDoorsClosed"),
    5: .same(proto: "requireIgnitionOff"),
    6: .same(proto: "requireLightsOff"),
    7: .same(proto: "homePoint"),
    8: .same(proto: "homeRadius"),
    10: .same(proto: "fuelTankGreaterThan"),
  ]

  fileprivate class _StorageClass {
    var _requireWindowsUp: Bool? = nil
    var _requireSunroofClosed: Bool? = nil
    var _requireConvertibleClosed: Bool? = nil
    var _requireDoorsClosed: Bool? = nil
    var _requireIgnitionOff: Bool? = nil
    var _requireLightsOff: Bool? = nil
    var _homePoint: Gps_t? = nil
    var _homeRadius: UInt32? = nil
    var _fuelTankGreaterThan: Float? = nil

    static let defaultInstance = _StorageClass()

    private init() {}

    init(copying source: _StorageClass) {
      _requireWindowsUp = source._requireWindowsUp
      _requireSunroofClosed = source._requireSunroofClosed
      _requireConvertibleClosed = source._requireConvertibleClosed
      _requireDoorsClosed = source._requireDoorsClosed
      _requireIgnitionOff = source._requireIgnitionOff
      _requireLightsOff = source._requireLightsOff
      _homePoint = source._homePoint
      _homeRadius = source._homeRadius
      _fuelTankGreaterThan = source._fuelTankGreaterThan
    }
  }

  fileprivate mutating func _uniqueStorage() -> _StorageClass {
    if !isKnownUniquelyReferenced(&_storage) {
      _storage = _StorageClass(copying: _storage)
    }
    return _storage
  }

  public var isInitialized: Bool {
    return withExtendedLifetime(_storage) { (_storage: _StorageClass) in
      if let v = _storage._homePoint, !v.isInitialized {return false}
      return true
    }
  }

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    _ = _uniqueStorage()
    try withExtendedLifetime(_storage) { (_storage: _StorageClass) in
      while let fieldNumber = try decoder.nextFieldNumber() {
        switch fieldNumber {
        case 1: try decoder.decodeSingularBoolField(value: &_storage._requireWindowsUp)
        case 2: try decoder.decodeSingularBoolField(value: &_storage._requireSunroofClosed)
        case 3: try decoder.decodeSingularBoolField(value: &_storage._requireConvertibleClosed)
        case 4: try decoder.decodeSingularBoolField(value: &_storage._requireDoorsClosed)
        case 5: try decoder.decodeSingularBoolField(value: &_storage._requireIgnitionOff)
        case 6: try decoder.decodeSingularBoolField(value: &_storage._requireLightsOff)
        case 7: try decoder.decodeSingularMessageField(value: &_storage._homePoint)
        case 8: try decoder.decodeSingularUInt32Field(value: &_storage._homeRadius)
        case 10: try decoder.decodeSingularFloatField(value: &_storage._fuelTankGreaterThan)
        default: break
        }
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    try withExtendedLifetime(_storage) { (_storage: _StorageClass) in
      if let v = _storage._requireWindowsUp {
        try visitor.visitSingularBoolField(value: v, fieldNumber: 1)
      }
      if let v = _storage._requireSunroofClosed {
        try visitor.visitSingularBoolField(value: v, fieldNumber: 2)
      }
      if let v = _storage._requireConvertibleClosed {
        try visitor.visitSingularBoolField(value: v, fieldNumber: 3)
      }
      if let v = _storage._requireDoorsClosed {
        try visitor.visitSingularBoolField(value: v, fieldNumber: 4)
      }
      if let v = _storage._requireIgnitionOff {
        try visitor.visitSingularBoolField(value: v, fieldNumber: 5)
      }
      if let v = _storage._requireLightsOff {
        try visitor.visitSingularBoolField(value: v, fieldNumber: 6)
      }
      if let v = _storage._homePoint {
        try visitor.visitSingularMessageField(value: v, fieldNumber: 7)
      }
      if let v = _storage._homeRadius {
        try visitor.visitSingularUInt32Field(value: v, fieldNumber: 8)
      }
      if let v = _storage._fuelTankGreaterThan {
        try visitor.visitSingularFloatField(value: v, fieldNumber: 10)
      }
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: EndBookConditions_t, rhs: EndBookConditions_t) -> Bool {
    if lhs._storage !== rhs._storage {
      let storagesAreEqual: Bool = withExtendedLifetime((lhs._storage, rhs._storage)) { (_args: (_StorageClass, _StorageClass)) in
        let _storage = _args.0
        let rhs_storage = _args.1
        if _storage._requireWindowsUp != rhs_storage._requireWindowsUp {return false}
        if _storage._requireSunroofClosed != rhs_storage._requireSunroofClosed {return false}
        if _storage._requireConvertibleClosed != rhs_storage._requireConvertibleClosed {return false}
        if _storage._requireDoorsClosed != rhs_storage._requireDoorsClosed {return false}
        if _storage._requireIgnitionOff != rhs_storage._requireIgnitionOff {return false}
        if _storage._requireLightsOff != rhs_storage._requireLightsOff {return false}
        if _storage._homePoint != rhs_storage._homePoint {return false}
        if _storage._homeRadius != rhs_storage._homeRadius {return false}
        if _storage._fuelTankGreaterThan != rhs_storage._fuelTankGreaterThan {return false}
        return true
      }
      if !storagesAreEqual {return false}
    }
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Gps_t: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = "Gps_t"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "latitude"),
    2: .same(proto: "longitude"),
  ]

  public var isInitialized: Bool {
    if self._latitude == nil {return false}
    if self._longitude == nil {return false}
    return true
  }

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      switch fieldNumber {
      case 1: try decoder.decodeSingularFloatField(value: &self._latitude)
      case 2: try decoder.decodeSingularFloatField(value: &self._longitude)
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if let v = self._latitude {
      try visitor.visitSingularFloatField(value: v, fieldNumber: 1)
    }
    if let v = self._longitude {
      try visitor.visitSingularFloatField(value: v, fieldNumber: 2)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: Gps_t, rhs: Gps_t) -> Bool {
    if lhs._latitude != rhs._latitude {return false}
    if lhs._longitude != rhs._longitude {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}
