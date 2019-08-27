//
//  ViewController.swift
//  CarShare
//
//  Created by msnow-bsm on 07/05/2019.
//  Copyright (c) 2019 msnow-bsm. All rights reserved.
//

import UIKit
import CarShare
import CommonCrypto

class ViewController: UIViewController, CarShareClientDelegate {
    
    private let simulator = Go9CarShareSimulator()

    private let client = DefaultCarShareClient()
    
    private func generateConfig(deviceHardwareId: String) -> BLeSocketConfiguration {
        return BLeSocketConfiguration(
            serviceID: serviceUUID(deviceHardwareId: deviceHardwareId),
            notifyCharacteristicID: "430F2EA3-C765-4051-9134-A341254CFD00",
            writeCharacteristicID: "906EE7E0-D8DB-44F3-AF54-6B0DFCECDF1C")
    }
    
    private func serviceUUID(deviceHardwareId: String) -> String {
        //SHA-256 hash of device ID and take the first 32 bytes of this.
        
        let deviceId = Int(deviceHardwareId)!.reverseBytes().bytes
        var hashBytes = [UInt8](repeating: 0, count:Int(CC_SHA256_DIGEST_LENGTH))
        CC_SHA256(deviceId, CC_LONG(deviceId.count), &hashBytes)
        var firstSixteen: [UInt8] = []
        for byte in hashBytes {
            firstSixteen.append(byte)
            if firstSixteen.count == 16 {
                break
            }
        }
        return NSUUID(uuidBytes: firstSixteen).uuidString
    }
    
    private var reservation: Reservation? {
        if let token = generateReservationJson(with: deviceHardwareIDTextField.text ?? "No ID Provided") {
            return Reservation(token: token, privateKey: """
-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAxQKJmRupP7zoxiNM65NpwGj1Sxp13pDPPC5dezh0GYmBAlL6hHlt1NfUFRDTAcRxIoM58FF4PQUI2oEXGlVjn8lKYBqXwydvXQZI1gyizwAx1oDzzIIisixQmZv/+CnUGU/+uyPSdUvDEVBf4ug58Ffzafqdb3c5Mwf3fCM1F+9rzU3K8AQbSvPleMGUx3HH/DUGHmAVNy7EbAoVZmIYYaBlMJF+12eAUl9CVwWtR6JrqmAJeLjtx6op7I7KQf65nfq1/m/kjy4KqQ9DeUTqimf5w7cAN2YTUfYtFo5RXvgSDrdG36DwUFW1BApippruytHFDh+JhK7xX/F/vdrgVwIDAQABAoIBAFE3J5RHs/EDpo4v9UDUR287lYt9gAPdfKEZmA35CtuQNO/JV18PU/i/dL2ubt42plEM+fCZFVFKZwj02JpRgz1W1ONjcxbPhfg6ZAJhuShOszzzcg3nw/fhjuSUS+R5EefRc3igXt1d+y+DC9RV2bS7/Su+VfKimqDv8tVpCjUwEwGp2o/GGKbANxOtiRlwOKzDqGU6mZxwBUGlnD944laeLPJjoBEniS7UCZdJT8P8XsRG9mKbno1trjGtD459EUQnflJYgoGpodjoftrd5JokuWd4OF5ENq9MrYhN2IAf8KryC+8ogoV9QG1pM/wY/FAdkroOm4jC0AeYNKhaetECgYEA+P8nKCCmeXxn5fLOItR5BDX+VqV1/6rn8yUHof11F5Dtr0r2X+EZr7+acR+D1Lt9aN4cbM1+R0SZjpYsy4Pzv6rQPASY4+MSxTitWwtLfowCPFUdxNu4GJ5vrbs6zljtbLM79YHp000S9WbmfRcjMKq9ly7eTmNJ6kzjWBLCgxkCgYEAyo0Qn0nlmgdkSbLXE9kXUA81t6kFiUgTSuOo+XpoKINMFdmfm6cLh8KPrLHzY/eknE36HRXKa8D8MzoAT061ibhCSK+ShkQVP9y9vzK8W3COKrOrTZ9PcUq9373qVd+AIBXW4YFz5aW2DB9Rf6X9x4iV2mV0D79/8xYy7VKB3O8CgYBTYFUDSdOU0ISV6jT+UrlnIJFXADa/8sGSmG6y3oUr6/q6/NX9Cwon4Hfds1jYjiOTTvSjtje3s4/bwAul5jxjjNYHkt6DSJELe0wJNYIFEOrauwGp3o0JqVvqB8zMNdji0i2cqvDaMW/MvrUlY+8Dp9iuXCJSi0q/6xkhb760WQKBgCtXCdJ7lmRh5oSafsjhb8qSppTY1rVsNayVkAdpuLXKelJGkY9Vq/Ltn559KS4fxBop2TW1/u0ViyFO7NgLaG7CfXReFQUjtkRG8Fbj/Ue3isP6U9I1H2OHcZ9ZXLXpL9otsh/oeisOTSjE3sRoeSfjwuTLRo1EFZWnD1iWifEDAoGBAIhpuaFCrlYAi+G2Oda+yWlg6GwsaOaXaGF1evwVb3aOMFBV8d2FDus+OyiFXL9iRkziJBf2yVUj5wl1FHZyFfsCeSNwfoK06E5JydiEARR6sevUBBjzh1LjjjQENFh8btkrBUKOOMagXi09VRFRoSk7EaSyIb256UZkWkF3Xile
-----END RSA PRIVATE KEY-----
""")
        }
        print("Failed to generate reservation")
        return nil
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        client.delegate = self
    }

    @IBAction func didTapSimulator() {
        client.disconnect()
        simulator.stop()
        let config = generateConfig(deviceHardwareId: deviceHardwareIDTextField.text ?? "No Device Hardware ID")
        simulator.start(
            serviceID: config.serviceID,
            notifyCharacteristicID: config.notifyCharacteristicID,
            writeCharacteristicID: config.writeCharacteristicID)
    }

    @IBOutlet weak var deviceHardwareIDTextField: UITextField!
    
    
    @IBAction func didTapConnect(_ sender: Any) {
        guard let deviceHardwareID = deviceHardwareIDTextField.text, deviceHardwareID.count > 0, let _ = Int(deviceHardwareID) else {
            let alert = UIAlertController(title: "Please enter a valid, non nil, numeric (Int) deviceHardwareID", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        client.connect(generateConfig(deviceHardwareId: deviceHardwareID))
    }
    
    @IBAction func didTapDisconnect(_ sender: Any) {
        deviceHardwareIDTextField.isEnabled = true
        client.disconnect()
    }
    
    @IBAction func didTapCheckIn() {
        guard let reservation = reservation else {
            presentInvalidReservationAlert()
            return
        }
        client.execute(.checkIn, with: reservation)
    }
    
    @IBAction func didTapLocate(_ sender: Any) {
        guard let reservation = reservation else {
            presentInvalidReservationAlert()
            return
        }
        client.execute(.locate, with: reservation)
    }
    
    @IBAction func didTapUnlock(_ sender: Any) {
        guard let reservation = reservation else {
            presentInvalidReservationAlert()
            return
        }
        client.execute(.unlock, with: reservation)
    }
    
    @IBAction func didTapLock(_ sender: Any) {
        guard let reservation = reservation else {
            presentInvalidReservationAlert()
            return
        }
        client.execute(.lock, with: reservation)
    }
    
    @IBAction func didTapCheckOut(_ sender: Any) {
        guard let reservation = reservation else {
            presentInvalidReservationAlert()
            return
        }
        client.execute(.checkOut, with: reservation)
    }
    

    func clientDidConnect(_ client: CarShareClient) {
        deviceHardwareIDTextField.isEnabled = false
        guard let reservation = reservation else {
            presentInvalidReservationAlert()
            return
        }
        let alert = UIAlertController(title: "Connected", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    func clientDidDisconnectUnexpectedly(_ client: CarShareClient, error: Error) {
        deviceHardwareIDTextField.isEnabled = true
        print("SOMETHING WENT WRONG: \(error)")
    }
    
    func clientCommandDidSucceed(_ client: CarShareClient, command: Command) {
        let alert = UIAlertController(title: String(describing: command), message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
        print("Command Succeded: \(String(describing: command))")
    }
    
    func clientCommandDidFail(_ client: CarShareClient, command: Command, error: Error) {
        let alert = UIAlertController(title: "\(String(describing: command.self)) failed", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
        print("Command: \(String(describing: command.self))  Failed with error: \(error)")
    }
    
    private func generateReservationJson(with deviceHardwareId: String) -> Data? {
        return """
        {
        "reservationId": "6CLhfHKvOUWhT9hZknHLGA==",
        "appPrivateKeyPkcs1Encoded": "MIIEowIBAAKCAQEAxQKJmRupP7zoxiNM65NpwGj1Sxp13pDPPC5dezh0GYmBAlL6hHlt1NfUFRDTAcRxIoM58FF4PQUI2oEXGlVjn8lKYBqXwydvXQZI1gyizwAx1oDzzIIisixQmZv/+CnUGU/+uyPSdUvDEVBf4ug58Ffzafqdb3c5Mwf3fCM1F+9rzU3K8AQbSvPleMGUx3HH/DUGHmAVNy7EbAoVZmIYYaBlMJF+12eAUl9CVwWtR6JrqmAJeLjtx6op7I7KQf65nfq1/m/kjy4KqQ9DeUTqimf5w7cAN2YTUfYtFo5RXvgSDrdG36DwUFW1BApippruytHFDh+JhK7xX/F/vdrgVwIDAQABAoIBAFE3J5RHs/EDpo4v9UDUR287lYt9gAPdfKEZmA35CtuQNO/JV18PU/i/dL2ubt42plEM+fCZFVFKZwj02JpRgz1W1ONjcxbPhfg6ZAJhuShOszzzcg3nw/fhjuSUS+R5EefRc3igXt1d+y+DC9RV2bS7/Su+VfKimqDv8tVpCjUwEwGp2o/GGKbANxOtiRlwOKzDqGU6mZxwBUGlnD944laeLPJjoBEniS7UCZdJT8P8XsRG9mKbno1trjGtD459EUQnflJYgoGpodjoftrd5JokuWd4OF5ENq9MrYhN2IAf8KryC+8ogoV9QG1pM/wY/FAdkroOm4jC0AeYNKhaetECgYEA+P8nKCCmeXxn5fLOItR5BDX+VqV1/6rn8yUHof11F5Dtr0r2X+EZr7+acR+D1Lt9aN4cbM1+R0SZjpYsy4Pzv6rQPASY4+MSxTitWwtLfowCPFUdxNu4GJ5vrbs6zljtbLM79YHp000S9WbmfRcjMKq9ly7eTmNJ6kzjWBLCgxkCgYEAyo0Qn0nlmgdkSbLXE9kXUA81t6kFiUgTSuOo+XpoKINMFdmfm6cLh8KPrLHzY/eknE36HRXKa8D8MzoAT061ibhCSK+ShkQVP9y9vzK8W3COKrOrTZ9PcUq9373qVd+AIBXW4YFz5aW2DB9Rf6X9x4iV2mV0D79/8xYy7VKB3O8CgYBTYFUDSdOU0ISV6jT+UrlnIJFXADa/8sGSmG6y3oUr6/q6/NX9Cwon4Hfds1jYjiOTTvSjtje3s4/bwAul5jxjjNYHkt6DSJELe0wJNYIFEOrauwGp3o0JqVvqB8zMNdji0i2cqvDaMW/MvrUlY+8Dp9iuXCJSi0q/6xkhb760WQKBgCtXCdJ7lmRh5oSafsjhb8qSppTY1rVsNayVkAdpuLXKelJGkY9Vq/Ltn559KS4fxBop2TW1/u0ViyFO7NgLaG7CfXReFQUjtkRG8Fbj/Ue3isP6U9I1H2OHcZ9ZXLXpL9otsh/oeisOTSjE3sRoeSfjwuTLRo1EFZWnD1iWifEDAoGBAIhpuaFCrlYAi+G2Oda+yWlg6GwsaOaXaGF1evwVb3aOMFBV8d2FDus+OyiFXL9iRkziJBf2yVUj5wl1FHZyFfsCeSNwfoK06E5JydiEARR6sevUBBjzh1LjjjQENFh8btkrBUKOOMagXi09VRFRoSk7EaSyIb256UZkWkF3Xile",
        "reservationTokenSignature": "qY3rg2rrvmcjGEsIMMEb5zuVy1X8m18uqO5fEsp2sgFsYd6l7j/TolOMLrBGj60opND9iD/GdVrq8R3mDQMGh1jdb8zc2ORQ0FQZkeFrB4W6YwT+hcHmMcEMScI1Bs1HfzUADsWFsv+IDxUEjmKRtFzZy5ImEZ+zgEiTltzHZO9SxRSVACBce/ant+Mx8rGRx/wqDdqwxmjFzyS9uXogFW4Im+X8+rz8FokZJxSVKBzhBEVaqcVSLqFqcnJ5vzq6S21ujV6BVKnao/SYUZRZRTDncoGT80Qdi9FrHWm5HrH6ohGHu6u+fjFOqLjITz9U3e1ApEH6Qrxvq2R4ZiGgoQ==",
        "reservationToken": {
        "appPublicModulus": "xQKJmRupP7zoxiNM65NpwGj1Sxp13pDPPC5dezh0GYmBAlL6hHlt1NfUFRDTAcRxIoM58FF4PQUI2oEXGlVjn8lKYBqXwydvXQZI1gyizwAx1oDzzIIisixQmZv/+CnUGU/+uyPSdUvDEVBf4ug58Ffzafqdb3c5Mwf3fCM1F+9rzU3K8AQbSvPleMGUx3HH/DUGHmAVNy7EbAoVZmIYYaBlMJF+12eAUl9CVwWtR6JrqmAJeLjtx6op7I7KQf65nfq1/m/kjy4KqQ9DeUTqimf5w7cAN2YTUfYtFo5RXvgSDrdG36DwUFW1BApippruytHFDh+JhK7xX/F/vdrgVw==",
        "keyExpiry": 1567142040,
        "reservationId": "6CLhfHKvOUWhT9hZknHLGA==",
        "deviceHardwareId": \(deviceHardwareId),
        "account": {
        "id": 23,
        "permissions": 15
        },
        "reservationStartTime": 1564625640,
        "reservationEndTime": 1567142040,
        "gracePeriodSeconds": 900,
        "securePeriodSeconds": 900,
        "endBookConditions": {
        "endBookVehicleFlags": 63,
        "homePoint": {
        "latitude": 43.4509125,
        "longitude": -80.51358
        },
        "homeRadius": 500
        }
        }
        }
        """.data(using: .utf8)

    }
    
    private func presentInvalidReservationAlert() {
        let alert = UIAlertController(title: "Invalid Reservation", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

extension Int {
    var bytes: [UInt8] {
        let v0: UInt8 = UInt8(((self >> 24) & 0xFF))
        let v1: UInt8 = UInt8(((self >> 16) & 0xFF))
        let v2: UInt8 = UInt8(((self >> 8) & 0xFF))
        let v3: UInt8 = UInt8(((self >> 0) & 0xFF))
        return [v0, v1, v2, v3]
    }
    
    func reverseBytes() -> Int {
        let v0  = ((self >> 0) & 0xFF)
        let v1  = ((self >> 8) & 0xFF)
        let v2  = ((self >> 16) & 0xFF)
        let v3  = ((self >> 24) & 0xFF)
        return (v0 << 24) | (v1 << 16) | (v2 << 8) | (v3 << 0)
    }
}

