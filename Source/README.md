# Keyless Library

## Component Breakdown

### KeylessClient

[More on KeylessClient](KeylessClient.md)

### Command Protocol Layer

[More on CommandProtocol](CommandProtocol.md)

### Transport Protocol Layer

[More on TransportProtocol](TransportProtocol.md)

### Bluetooth Socket Layer

[More on BluetoothSocket](Socket.md)

### Internal Details ###
[Implementation Details](https://docs.google.com/document/d/1URT1blNemftnz8m69trHAaQcPElUxWqyTggJcoEt5Qc/edit?ts=5d5dac59#) <br>
[Messaging Protocols](https://docs.google.com/document/d/1RAUzXC29UFdBI6u7wDGa1JNkIxm0M8NM0KYPSTcalos/#)

## Sequence Diagrams

### Connect to a Go Device

```mermaid
sequenceDiagram
participant A as Mobile App
participant B as Lib Keyless Layer
participant C as Lib Command Layer
participant D as Lib Transport Layer
participant E as Lib Socket Layer
participant F as GO 9 Device

A->>B: connect w/ vehicle
B->>C: connect
C->>D: connect
D->>E: connect
E-->>F: advertise
E-->>F: advertise
E-->>F: advertise
F->>E: set notify flag
E->>F: [0x55] sync request
F-->>E: [02 01 00 03 08 03] handshake request (0x01)
E-->>F: [02 81 04 5D 10 00 00 F4 CC 03] handshake confirmation (0x81)
F-->>E: Ack
E-->>D: connected
D-->>C: connected
C-->>B: connected
B-->>A: connected
```

### Send command to a Go Device

```mermaid
sequenceDiagram
participant A as Mobile App
participant B as Lib Keyless Layer
participant C as Lib Command Layer
participant D as Lib Transport Layer
participant E as Lib Socket Layer
participant F as GO 9 Device

A->>B: check-in to connected vehicle
B->>C: issue command
C->>D: data (request to send message)
D->>E: data (request to send message)
E->>F: data (request to send message)
F-->>E: data (32 random bytes challenge)
E-->>D: data (32 random bytes challenge)
D-->>C: data (32 random bytes challenge)
C->>D: data (secure command message)
D->>E: data (secure command message)
E->>F: data (secure command message)
F-->>E: data (challenge ack)
E-->>D: data (challenge ack)
D-->>C: data (challenge ack)
C-->>B: command succeed
B-->>A: command succeed
```
