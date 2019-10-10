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

    private let reservation = "CiQ0MEEyOUZFOC02ODY3LUY1RTAtMDVFNi1FOTM2QkQ0RUQ0QUIStAxNSUlFb3dJQkFBS0NBUUVBdzRKZTZDS2dXdUlKWWNDTzY4bjI5RitJdHg1RWZDK1VISHpVd0doZ2tkeWJxTWNaOWsrN0ZNV2VqTXJUWk8xZ3FZWFNWRWR2WElwR3R1N1ZLNFMwZDltWXpjbHVwL25mVFdHd0MwOUNCR0VYR05Vc2RXRXltZlkxemE3S09YRjVPRUQ3elpBaytKRDlzcjBUZGgvaE5oWWIrS3Y1OEsvZlduS1NYZHFSclN1SWllVG05NUZJY1hUUHVoRGpnUyswWVlUWGk5SFNnQ0ZKUEV5ckZOOEc5UExZSGlJZmZRZjV3WE9XNVZjRzFNa1NGZktyMm9saVkzWnNhS1hWRDBxV2Y4dlVHeEZ0YzZBTGlPM0JFRHlGc0ZYVTM0TzVOL1N3NG9NNDNhdkFmZTYrQi8zOE93bTNhRXNyeUxXOEh0SmlLdTl5a0dleEVFd2cvMUlyV0FNS1pRSURBUUFCQW9JQkFCaVhoLytVQjI2WEd3NEFMaG9May9RbUppaStkbWZXaGo5VkZsL0RZVTVIblE3TVNJQTZoREkzTDF2UFVXclREd01UMGFLSFA4TTRvMjkwT0QwYW1xYXVxTEZONG96ZmVjNmVlSW5icE5hdkxid1NhRjYxWkt1SUZEbDBnSHhjUVI2cDBlS0gvSmFGaWx2V3U2RnluaDN6QnY2dkJ5Zld2M1g5amxxZTJROGFmKy9PUCtXSDVmaW9WWHVJVXIvWEdLLzZ3UGgwNjZjaXpabXM0QnBKaUxnMXM0S2tGaDJTcGM5WHo2U0dMY3ZBc0Nod1pla3pyZ2lUQndOZ1BUdmxUSzkvdkpydERoUTF3bnhUOG1jemVHa2RiU1V2Nm5YVTBMakE1TjdHMUkydDFCcmRrcFhRblo4dDdOejduUERZT2NaTFoybVFGbjR5VldXZUpXN2VWbkVDZ1lFQTRpZnBQRkVxZENhUmZpa0tZS3Q5dGRPcytDREUrNFhTRzVSVHMza2c0UVZ6Zk82aTdvU2tmR1ZzbmJsQUFTY0dLb2NkbVJsZjFpUzkxQVI5V0Vub25jNGgwVmx2UExZOTd0cjJKSnVndmJiZW9PVmh3bzZtRDVteXVkaExMc3EyTjVJQllmR2lyUDArbFhoWkh3M0QzTmJHQW9zNXlabnFrZ1BmK3hmNVh4a0NnWUVBM1U4a2YxSGtlZytvTTVaWGdqbGUwRFBWTkIwUE9rSVVCdlpxNmdCWEo2TFBhSmN2aXhvUE1mVnpGMGp5QXE4ZzFSdUNPVXBZQzRmV2I2cDVUZFBhYWpTWDZ3cC9wRTFIMFc1ZWdRT1dyMGlGUno0MzVpM2JHc2k1dHJKb2ZrNWJ5MjF3NzNVNjVmZGFhTHAyREwyclkrbkhPRzdudit1K0VWb0Zvb3Y1U3kwQ2dZQnF1dTB1d3h0bS80Q3dhb3YwUFZxeGdmbGlqSXlLSzRpUjdYbG0vT1pRYS9NcDViRk5JWnBDL3RhNHhPRjQ2Y0xXTlRmNXRlanR0aDlFUE80dXlZcVhWdDNNNEFsSVBMV1QwUkJURElOYXBVQUI3TjhySTRrcFdaN29hRFJyRzgzTkFnSFhDR04rZ25HVHR0MVFjMzJZN2w4NmVoeEdrWFlMZlBxcWxKRGltUUtCZ1FESEwvWmZpZXVrV1BkQkJ5M1lEWjdpc2VSUk5WNkJSdndUa0RLR1Rxd2pCb3k3VEdnRVFQNHdMd1RaamxRVVNsKzRyenUwS00rNkFSYm1CbitMcHdSTTF1MXRKVlBoSTVWaVVINUtqRnBSaFdvL3h5WTB6RTBLZkdONnBuVWFTWmloTGUyWitOOThIL2VGajEyMDlmbU93ZGtIVi9yS2FIbjMwQmlHUm9tb09RS0JnQTc5Ky9iN1RjZDBTZmZXMklHSUwrM2gyUy9veTd3U21xR1BYWlNuaEN3NXJsb0tFMEJSRElPQ1pvTHljb0dBeldUZ3FSbEhMQ0NlRnhpakpNUkZZa1dMWjc5YmtaTEJJTjdOWWJRQzJDMURXY0w1U0tTQnBpQ21pcHdnY3c1djRDMkJNS0I2L0UyR0VVbkNZZjQ5b21DRDJvRENBSndPMmFXMUFKMk9nQWRvGoACw4Je6CKgWuIJYcCO68n29F+Itx5EfC+UHHzUwGhgkdybqMcZ9k+7FMWejMrTZO1gqYXSVEdvXIpGtu7VK4S0d9mYzclup/nfTWGwC09CBGEXGNUsdWEymfY1za7KOXF5OED7zZAk+JD9sr0Tdh/hNhYb+Kv58K/fWnKSXdqRrSuIieTm95FIcXTPuhDjgS+0YYTXi9HSgCFJPEyrFN8G9PLYHiIffQf5wXOW5VcG1MkSFfKr2oliY3ZsaKXVD0qWf8vUGxFtc6ALiO3BEDyFsFXU34O5N/Sw4oM43avAfe6+B/38Owm3aEsryLW8HtJiKu9ykGexEEwg/1IrWAMKZSKAApWoyqmq4I18lz9mTjxN8sB+484YwY9kwWqFzI1ccK2Qx6gw15CVeXNbhU+D4WT4dd5wW9BjIToTTWv9xYWEtmWJDloit68tidXzMV1oP7abjrHRxIBn6eOaMgNZ/3jiAFBUx4HVKcUa4Dcst0qO9stFSwPcOmEE8jQ53vgmgxawfC7qu1OXuZCh23RH9HsbTTE2BV8lLNZVGbdYuID+3bJCitm1HzWJdCmHWvcLtdT0OEjXqXBKDkIJo495zzMlIXElSfr7yCghuj7UPQFdlB/kE2o0WYGZHcskcpvNm51Aa02P6gkgONy4T2X5k9pFaw8QAgUAK/GsYETx5f6o3YUq4gIKgALDgl7oIqBa4glhwI7ryfb0X4i3HkR8L5QcfNTAaGCR3Juoxxn2T7sUxZ6MytNk7WCphdJUR29cika27tUrhLR32ZjNyW6n+d9NYbALT0IEYRcY1Sx1YTKZ9jXNrso5cXk4QPvNkCT4kP2yvRN2H+E2Fhv4q/nwr99acpJd2pGtK4iJ5Ob3kUhxdM+6EOOBL7RhhNeL0dKAIUk8TKsU3wb08tgeIh99B/nBc5blVwbUyRIV8qvaiWJjdmxopdUPSpZ/y9QbEW1zoAuI7cEQPIWwVdTfg7k39LDigzjdq8B97r4H/fw7CbdoSyvItbwe0mIq73KQZ7EQTCD/UitYAwplEKC0iaXXLRoQJ/RDR+FF1U+fsyNJBjDXjyDth4yIAioNCNOL64IOEgUN/w8AADDAr5uj1y04gL3SpNctQIQHSIQHUhsKBQ0/AAAAEgoNAACAQBUAAOBAGPQDJQAAgD4ygAJY6TImM4e48/GTS+TDA5wqQdUSWWwAsYdQeZ/YU2alVdcLdgKPJVDeXNIw+GTLjUh+vILzyM6cc49tFQXyjfG5Yv3IgNqTe/drJkmQIhigfZqQrQWCW/N9XZcI/5IY3t4P7oQ22bo5tDfsxe0DH0hssocOLllh5ej3PmtP8cFev2LcU2I1P4toW2WeW0nxdJOBUg3K/moDAbx1LXwwFkaisy5sqM0WZK+AqQkefwBTm/uTqiYazJW56l99EO5am0iOG0Z6zSEkPtrXZc5jUm3sTSnuaqbH5Gg1w8qmDaLlDZp+mgY/GM9yLi5zfURhzsF2e7s3pDZhOs+qO+fa61aH"

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

