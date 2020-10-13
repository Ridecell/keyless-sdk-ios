# KeylessClient

The **KeylessClient** is the first layer in the Keyless library which exposes public facing APIs. In this layer, the bluetooth connection configuration is constructed using the BLE service UUID extracted from the **KeylessToken**, the **Notify Characteristic UUID**, and the **Write Characteristic UUID**. 

```swift
public func connect(_ keylessToken: String) throws {
    do {
        let keylessToken = try tokenTransformer.transform(keylessToken)
        commandProtocol.delegate = self
        commandProtocol.open(generateConfig(bleServiceUUID: keylessToken.bleServiceUuid))
    } catch {
        print("Failed to decode reservation token")
        throw error
        }
}

private func generateConfig(bleServiceUUID: String) -> BLeSocketConfiguration {
    return BLeSocketConfiguration(
            serviceID: bleServiceUUID,
            notifyCharacteristicID: "430F2EA3-C765-4051-9134-A341254CFD00",
            writeCharacteristicID: "906EE7E0-D8DB-44F3-AF54-6B0DFCECDF1C")
}
```

The **BLeSockectConfiguration** object is passed down to the socket layer which provides a Bluetooth connection context based on the configuration. The KeylessClient implements the **CommandProtocolDelegate** which provides callbacks on initiating a Bluetooth connection, and executing a command.

```swift
func protocolDidOpen(_ protocol: CommandProtocol) {
    delegate?.clientDidConnect(self)
}
```


## Class Diagrams

```mermaid
classDiagram
	class KeylessClientDelegate {
    <<interface>>
    clientDidConnect(client)
    clientOperationsDidSucceed(client, operations)
    clientOperationsDidFail(client, command, error)
    clientDidDisconnectUnexpectedly(client, error)
}
class CommandProtocolDelegate {
    <<interface>>
    protocolDidOpen(protocol)
    protocol(protocol, didReceive)
    protocol(protocol, didFail)
    protocolDidCloseUnexpectedly(protocol, error)
}
class KeylessClient {

    -commandProtocol: CommandProtocol
    -tokenTransformer: KeylessTokenTransformer
    -deviceCommandTransformer: DeviceCommandTransformer
    -deviceToAppMessageTransformer: DeviceToAppMessageTransformer
    -outgoingMessage: MessageStrategy?

    +delegate: KeylessClientDelegate
    +isConnected: Bool
    
    +connect(keylessToken)
    +execute(operations, keylessToken)
    +disconnect()
}

CommandProtocolDelegate <|-- KeylessClient : implements
```
