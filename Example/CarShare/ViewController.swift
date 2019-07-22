//
//  ViewController.swift
//  CarShare
//
//  Created by msnow-bsm on 07/05/2019.
//  Copyright (c) 2019 msnow-bsm. All rights reserved.
//

import UIKit
import CarShare

class ViewController: UIViewController, CarShareClientConnectionDelegate {
    private let simulator = Go9CarShareSimulator()

    private let client = DefaultCarShareClient()

    private let config = BLeSocketConfiguration(
        serviceID: "42B20191-092E-4B85-B0CA-1012F6AC783F",
        notifyCharacteristicID: "430F2EA3-C765-4051-9134-A341254CFD00",
        writeCharacteristicID: "906EE7E0-D8DB-44F3-AF54-6B0DFCECDF1C")

    private let reservation = Reservation(
        certificate: """
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAzC6IX6BUROsB4wI/Z/Vu
eg7VwV4TbPIJiTPbD8bHA+FpT/5D2uGkmvhIXQIcIb5k9RmPL8s0Qs6m6E8unv8d
pGGT/inPnK3wTSgbodBArTJ/H42dKcNaGspogyPtlndVxvfSC/hrLrRr0qEZTgws
V+uJqFGCBC+HWkV3dk/RrZ0qbw7KGYKqQjv/zDyzs2IL/7g5E5ySjnsgDnm7LhKc
X8E9GyLqF2Qr/7/pSiWGtCggJljgzq6eI0V4Em5iHFBY50n0UbGIcz2fZqasfHRM
NEiMR/yEWxOuudAQbcStWyOj+5vBfu/+cvoVysDBZEsqqsrSm+gRVYW8+mt2U2Na
hQIDAQAB
-----END PUBLIC KEY-----
""",
        privateKey: """
-----BEGIN RSA PRIVATE KEY-----
MIIEpgIBAAKCAQEAzC6IX6BUROsB4wI/Z/Vueg7VwV4TbPIJiTPbD8bHA+FpT/5D
2uGkmvhIXQIcIb5k9RmPL8s0Qs6m6E8unv8dpGGT/inPnK3wTSgbodBArTJ/H42d
KcNaGspogyPtlndVxvfSC/hrLrRr0qEZTgwsV+uJqFGCBC+HWkV3dk/RrZ0qbw7K
GYKqQjv/zDyzs2IL/7g5E5ySjnsgDnm7LhKcX8E9GyLqF2Qr/7/pSiWGtCggJljg
zq6eI0V4Em5iHFBY50n0UbGIcz2fZqasfHRMNEiMR/yEWxOuudAQbcStWyOj+5vB
fu/+cvoVysDBZEsqqsrSm+gRVYW8+mt2U2NahQIDAQABAoIBAQC0d2h3xNjWtTRM
td7e/tGvtk7+Ay1+PItrJlc3oYSjjGctmdnVq1x20H39HvFIbeUDsZyaLKu7ZLWn
XN0jEO/dK5XHrqLeo+ph99I8ejnAG4K6m8tOb2jDhyVKy8WiGUXKf526kM4DUNqA
J32bOy0yZG+eQrR9CJlEk2OcQb5dCJlDJzUqHh+sWZdDA6Cs0nlkSISPQYnLOlKh
sDwGC5AmJdLrnwf4VcjfhrFkhKTS8l6a4gsD9z0OdG09/VhG1dSP13OSUOMA0hRz
Z9BiqlbZ+pYIqMU6jHxqKnIYHRq3weA9xDa+y8BnwRZ/HYGecB+98S8sj5wuuqJF
cff/mOlhAoGBAO6u24z0hFK+TRRurRwy60PxnZPoM5MjHxmWE4MzZs0FjlS/TQkv
aU8F9yx7q0PxLcMtQS7hRvcmBI5XniEA/BmQZfSgViRZoD55jxW0uEc+GJpyPkyC
FMCJtDF7lwykIsTIJFPRohicxn12w42TTtUBZbGI32p8oqxHwN8KNkRdAoGBANr+
3wGLxtjWP/dPCNMfl5YmrUxlWpgmVumbQIsrt1t3HISjsCNDcnjJ3GQ1Lq+JT7b2
QJtbXZSEX5uasJ5Jb/XctFUj/hpGAiNFmJYlZxij7M/x75or464NtmOU8YOvCEvx
0lFZDrPOP6jABP7Dy2oOtCiH+9hbgsFbyoG2M4xJAoGBALZCF6ye2pxEbJ95k/7A
cx5C1c0ntppYa1siWmwJSCquX20fVzf4WDXbnE7/cFxFQmiTmf6uT35SLZB0H2+c
TOVIelI+TQkc11xdfoFYqo7cP/VP33qUqjwL6ukOMt2YSGRzYCoRHfIlZPxRQCpP
nhbRJlJW7iNmYOGlOQYXyjCRAoGBANcXuA87q220WZVdEizS/b8jc9jyP53rIjhG
HYnTwT7b6a25XDn2eAt9MLNXrOgKNLpeeaxde7dwoLsjn0+Ij6frQ0/QjzZdBqKA
K9NlHzKLZwAC/7PsYa7FlxuN4fzVwI9fD5SIpTEjZVEocH+N7U/Y60hX75tcnjuu
HWNzgoPJAoGBAKmBtodogaJFdySMs0uwryDGJroBxo+07s3AGwxCo+Tj5r+26vvs
SUdMRwaaBihHvLkDLgLYyR3YyY+aZL7BPetf3iA0iWhhkwHppWvJ5tGRE5z+Q2r3
QnHMrFAtXCNK5uqWlGnDzOEPvhGVj5yPiyXzvGwzn6m/7Co3vyqX6LXR
-----END RSA PRIVATE KEY-----
""")

    override func viewDidLoad() {
        super.viewDidLoad()
        client.delegate = self
    }

    @IBAction func didTapSimulator() {
        client.disconnect()
        simulator.stop()
        simulator.start(
            serviceID: config.serviceID,
            notifyCharacteristicID: config.notifyCharacteristicID,
            writeCharacteristicID: config.writeCharacteristicID)
    }

    @IBAction func didTapCheckIn() {
//        simulator.stop()
//        client.disconnect()
        client.connect(config)
    }

    func clientDidConnect(_ client: CarShareClient) {
        client.checkIn(with: reservation) {
            switch $0 {
            case let .failure(error):
                let alert = UIAlertController(title: "Failed", message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                print("CHECK IN FAILED: \(error)")
            case .success:
                let alert = UIAlertController(title: "Checked in", message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                print("CHECKED IN")
            }
        }
    }

    func clientDidDisconnectUnexpectedly(_ client: CarShareClient, error: Error) {
        print("SOMETHING WENT WRONG: \(error)")
    }
}

