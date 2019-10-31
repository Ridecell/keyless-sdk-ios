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

    private let client = CarShareClient()

    private let reservation = "CiQ0MEEyOUZFOC02ODY3LUY1RTAtMDVFNi1FOTM2QkQ0RUQ0QUIStAxNSUlFb2dJQkFBS0NBUUVBME16dlkxM1dqeEgyV2ZCUzN5T29Ha1FLU05QYlNaaFhHRzJ6NzIyeVR5akdKbk1zUnYzeXUvVHliRjJRQWF5Y3U0R1BRU2d5aERZdjlwc0lWTkhkeFlscmt2MkJZSUdJRm95SXFGbmRnU3hUME9FZ0IxbXlIc0Z5djc3YThSSXBJNW92aGhtbDF5V2g0d3EwY1E4cm5hcEZ2T3l2RVg1eXQ2QmxzdUVVZkJNWWd0bmlIUWZCcGhHL1dLK0p2NWRkWG55cWhPaktrajUzWGhDWXQvR0N5MzQ2QUl5UWZEK014QUZpMHBNOUxIamJmNDdlVlRrVThnUnZEb29wNjYzY3ByTW5yN0k3VWlTdGhPQis0WEpHd0Irdko5ZVQxbmZtTGVnejNGRjFzZllVUnA3NU5OVDNheURCRHMvSUlROTdEZlQrWW9JdllocHo1YVorQ0wvZjh3SURBUUFCQW9JQkFDQXEybHg4R2ZCN3EzREtzZkczakEvVDJLUEVvNzF3VDBhdnErOWdmbjVzZ1M1dVF1MkM5UkRZMlRveHBkeGtLOWRGUy8wVlJNY1NsQXdSY1ZTajZsOGkzeVJMa3RGNzB5dnFKYW1PQXE2Q1ZqMVJXWDVZWnJVUFIyN2I1OTRJMXJhcDY5VmtnU1Ntb3d5WDJ4bXA1U1hLbENqWmE5VXRubDNFdzdZdHI5cTNUUlZicVVvb0toUEtSYVpYekpIakczaFJ2dEw5YSs2TFF2V0ZBWGVVdStXUmlSTSt1QXRWVFU2U2VmaUFTZVJKRjdvVnNqRy9EU0tTc21BYmloSnhVL3ltMGdHaG5yNmtSMzBpem1FM2dvbDlkVkNsQTlIdEQ4VjRCK1RlV1lrczZ4aFQxbHA3SmhxQkx4S2lGMlRYN21NSVladENnMnlRci8vNTJZWUlNcDBDZ1lFQTh3OTZwTzhqQTJOcDhtVU1pT1Q4ZDJmdEdPam5yd0tXTUpDc3RBM2cwRUFsSmpGSXQzK21zVDBoTWt2U0JGTklaY3Z2dnBQQm5QUGNFMzNENk5HQ1RMSmI2cDJRL1BKYng1dmJsa1ZxVGVKamZDRFFhOUR4a3NJS3pnbHhhUXExUUw1NTludzludlRaMEVsMjFoeUloc2JLR3NoTi9HVE81MUxHU0EzRWVRY0NnWUVBMitxTWF4MXpwd3g1bDVBclNsZHpQd2FLdU9kMzNIMmNzNmlEQkdndjMxT3JYVXQvcDBuNUJ0WkJqWXIreGxyRW40OE1hVHltTnRvUmtJWnJQOTk1b2hXQ3F4QTgySmRjN291OS9VbEM4VEk0SFovOC9XQWNEb1I2S1JadG9zNlJYRkZLUU1Vbm1qNFZHa2c5ZU9KZ3cyVFRreEg5K045LzhibUNLd0Vwd3JVQ2dZQVFCS0loZ256OU9Tei9RM2VMQWdROVhrVDYwa2FLZXhJb3l6QUdnYStpS2NnSTkxQ0NmMUFkK0JoYTl6STFCTVFOcVYzNFlrWnRNSWo5WTlsb1czNUp6YXRQRCtsQk1qdW9NUFpNdGZCbWg1ZmswMGpKQWpFWmFkNUthOGJrbEVjVHFEbmphNWFvQmh6Z3BDYkh2NE9qMWkvMWllUFIwVmJ0V2NBbGVYck1Pd0tCZ0NQcVB6cHpHZU1yTDJSb1FCbXBCSUpEZ0Q1SVZ4UGtVOFluZkJZcEtjQlFPc2xHdmpkRTVtMk9hakJDaGU5QS9hR05UQnFYdEJGN05ha2p1cm80dGZXWmk3aUNNMTJ3QXBaV3JoV0NkSE5ObjBwL1NXTGI0bGtnbTQ3QVFmRjN5TmVKMHhXVzNTdmNmYmZJR25uMmhwVUNqMmNTWmliUjRXUkp4bzlkWmtPTkFvR0FZVEoxeW1SYVBFOFhRc3FoQlBIYmZxT3hUUkFJcmt2Q2ZnRWdoNFYvaGVIOVFSL0dZZ2tTU05mQklaekI5QzF3dHc0ZmxRQmxZbWozcHBiSmY2dlhWNjhsbmhZWGt3UktsUmZaK2dsT3lHY0k4cnUvZUMwc3NJRkMvRFRIc0ZBUFY2bzdKZlN4akNpYURGOXNZSU1NSE42RS9LUVVwMHNVMnJoTHo5NGM5NGs9GiDSM8EAQUWYx/7GbzGwoO32efGkHbNjH7Jda/0jb2p3GSIgnNsqEestF2zPrF/zm3WbETTnNWZdvHtP9WhViHHpiHkq4gIKgALQzO9jXdaPEfZZ8FLfI6gaRApI09tJmFcYbbPvbbJPKMYmcyxG/fK79PJsXZABrJy7gY9BKDKENi/2mwhU0d3FiWuS/YFggYgWjIioWd2BLFPQ4SAHWbIewXK/vtrxEikjmi+GGaXXJaHjCrRxDyudqkW87K8RfnK3oGWy4RR8ExiC2eIdB8GmEb9Yr4m/l11efKqE6MqSPndeEJi38YLLfjoAjJB8P4zEAWLSkz0seNt/jt5VORTyBG8OiinrrdymsyevsjtSJK2E4H7hckbAH68n15PWd+Yt6DPcUXWx9hRGnvk01PdrIMEOz8ghD3sN9P5igi9iGnPlpn4Iv9/zEOib3anOLhoQHS5lx8qWPUa6kEzH8sdO3CDth4yIAioNCOPptN0OEgUN/w8AADDIlMjC2C04yKSmqc4uQIQHSIQHUhsKBQ0/AAAAEgoNAACAQBUAAOBAGPQDJQAAgD4ygAIUiptnFWFSdRdsT04HB/1k2lrWoxb4bvr672Er/n2eR4kyOXFwNW0OHL0YPYxn7IoTvW6ZeGufI+4HyVOO4vNOBeyee4KO+/4CGoiEMs9eFEhmq2YrCUBZ2cJpcU/wt4ubCwxqNZFl0rJs/dpScknkK/Vmz2HYunHc+3z0LLaVw3r1DJi/wJuoVmy3JF5EUeeqf0p+T3laVKFw8jIl8XAs2rMzCkYve6UU+VEy/1NjipBvmG3abO3reW6jPx5NcKeNA8Ci4jIPtQ0ByqLoCWQLvFG5XnUpV11FufBBBq0xnKhhon/wXj0J0UREDP1IbjgqUEHmZw3VS51cjJqqHJKB"

    override func viewDidLoad() {
        super.viewDidLoad()
        client.delegate = self
    }
    
    @IBAction func didTapConnect(_ sender: Any) {
        //Pass in a CarShareToken from the signing service
        try? client.connect(reservation)
    }
    
    @IBAction func didTapDisconnect(_ sender: Any) {
        client.disconnect()
        let alert = UIAlertController(title: "Disconnected", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func didTapCheckIn() {
        try? client.execute(.checkIn, with: reservation)
    }
    
    @IBAction func didTapCheckOut(_ sender: Any) {
        try? client.execute(.checkOut, with: reservation)
    }

    @IBAction func didTapLocate(_ sender: Any) {
        try? client.execute(.locate, with: reservation)
    }

    @IBAction func didTapLock(_ sender: Any) {
        try? client.execute(.lock, with: reservation)
    }

    @IBAction func didTapUnlockAll(_ sender: Any) {
        try? client.execute(.unlockAll, with: reservation)
    }

    @IBAction func didTapUnlockDriver(_ sender: Any) {
        try? client.execute(.unlockDriver, with: reservation)
    }
    
    @IBAction func didTapOpenTrunk(_ sender: Any) {
        try? client.execute(.openTrunk, with: reservation)
    }
    
    @IBAction func didTapCloseTrunk(_ sender: Any) {
        try? client.execute(.closeTrunk, with: reservation)
    }

    func clientDidConnect(_ client: CarShareClient) {
        let alert = UIAlertController(title: "Connected", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    func clientDidDisconnectUnexpectedly(_ client: CarShareClient, error: Error) {
        let alert = UIAlertController(title: "Disconnected with error: \(String(describing: error))", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: "Retry", style: .default) { _ in
            self.didTapConnect(self)
        })
        self.present(alert, animated: true, completion: nil)
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

}

