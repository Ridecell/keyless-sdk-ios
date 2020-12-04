//
//  ViewController.swift
//  Keyless
//
//  Created by msnow-bsm on 07/05/2019.
//  Copyright (c) 2019 msnow-bsm. All rights reserved.
//

import UIKit
import Keyless

class ViewController: UIViewController {

    @IBOutlet var tableView: UITableView!
    private lazy var client = KeylessClient(logger: self)
    private lazy var helper = LoginHelper(logger: self)
    private var output: [String] = []

    private var reservation = ""
    private var executeDate = Date()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        client.delegate = self
        showLoginAlert()
    }
    
    func showLoginAlert() {
        let alert = UIAlertController(title: "Login", message: nil, preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "Email"
        }
        alert.addTextField { (textField) in
            textField.placeholder = "Password"
            textField.isSecureTextEntry = true
        }
        let action = UIAlertAction(title: "Login", style: .default) { (action) in
            guard let email = alert.textFields?.first?.text, let password = alert.textFields?.last?.text else {
                self.showAlert("Error", message: "Please enter email and password")
                return
            }
            self.helper.getEventId(email: email, password: password) { (token) in
                guard !token.isEmpty else {
                    self.showAlert("Error", message: "Not in active rental, or API error.")
                    return
                }
                self.showAlert("Success", message: "Fetched token from backend")
                self.reservation = token
            }
        }

        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }

    @IBAction private func didTapConnect(_ sender: Any) {
        //Pass in a KeylessToken from the signing service
        guard !reservation.isEmpty else {
            showLoginAlert()
            return
        }
        executeDate = Date()
        do {
            try client.connect(reservation)
        } catch {
            self.d("didTapConnect: \(error)")
            showAlert("Error", message: error.localizedDescription)
        }
    }
    
    @IBAction private func didTapDisconnect(_ sender: Any) {
        client.disconnect()
        let alert = UIAlertController(title: "Disconnected", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction private func didTapCheckIn() {
        executeDate = Date()
        do {
            try client.execute([.checkIn, .ignitionEnable, .locate], with: reservation)
        } catch {
            self.d("didTapCheckIn: \(error)")
            showAlert("Error", message: error.localizedDescription)
        }
    }
    
    @IBAction private func didTapCheckOut(_ sender: Any) {
        executeDate = Date()
        do {
            try client.execute([.checkOut, .ignitionInhibit, .lock], with: reservation)
        } catch {
            self.d("didTapCheckOut: \(error)")
            showAlert("Error", message: error.localizedDescription)
        }
    }

    @IBAction private func didTapLocate(_ sender: Any) {
        executeDate = Date()
        do {
            try client.execute([.locate], with: reservation)
        } catch {
            self.d("didTapLocate: \(error)")
            showAlert("Error", message: error.localizedDescription)
        }
    }

    @IBAction private func didTapLock(_ sender: Any) {
        executeDate = Date()
        do {
            try client.execute([.lock], with: reservation)
        } catch {
            self.d("didTapLock: \(error)")
            showAlert("Error", message: error.localizedDescription)
        }
    }

    @IBAction private func didTapUnlockAll(_ sender: Any) {
        executeDate = Date()
        do {
            try client.execute([.unlockAll], with: reservation)
        } catch {
            self.d("didTapUnlockAll: \(error)")
            showAlert("Error", message: error.localizedDescription)
        }
    }

    func showAlert(_ title: String, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
}
    
extension ViewController: KeylessClientDelegate {

    func clientDidConnect(_ client: KeylessClient) {
        let alert = UIAlertController(title: "Connected", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
        self.d("clientDidConnect, took \(-executeDate.timeIntervalSinceNow)s")
    }

    func clientDidDisconnectUnexpectedly(_ client: KeylessClient, error: Error) {
        let alert = UIAlertController(title: "Disconnected with error: \(String(describing: error))", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: "Retry", style: .default) { _ in
            self.didTapConnect(self)
        })
        self.present(alert, animated: true, completion: nil)
        print("SOMETHING WENT WRONG: \(error)")
        self.d("clientDidDisconnectUnexpectedly")
    }
    
    func clientCommandDidSucceed(_ client: KeylessClient, command: Command) {
        let alert = UIAlertController(title: String(describing: command), message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
        print("Command Succeded: \(String(describing: command))")
        self.d("clientCommandDidSucceed, took \(-executeDate.timeIntervalSinceNow)s")
    }
    
    func clientCommandDidFail(_ client: KeylessClient, command: Command, error: Error) {
        let alert = UIAlertController(title: "\(String(describing: command.self)) failed", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
        print("Command: \(String(describing: command.self))  Failed with error: \(error)")
        self.d("clientCommandDidFail, took \(-executeDate.timeIntervalSinceNow)s")
    }

    func clientOperationsDidSucceed(_ client: KeylessClient, operations: Set<CarOperation>) {
        let alert = UIAlertController(title: String(describing: operations), message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
        print("Operation Succeded: \(String(describing: operations))")
        self.d("clientOperationsDidSucceed, took \(-executeDate.timeIntervalSinceNow)s")
    }

    func clientOperationsDidFail(_ client: KeylessClient, operations: Set<CarOperation>, error: Error) {
        let alert = UIAlertController(title: "\(String(describing: operations)) failed", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
        print("Operations: \(String(describing: operations))  Failed with error: \(error)")
        self.d("clientOperationsDidFail, took \(-executeDate.timeIntervalSinceNow)s")
    }

}

extension ViewController: Logger {
    func log(_ level: LogLevel, message: () -> Any, context: LogContext) {
        let message = "\(message())"
        output.append(message)
        print(message)
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return output.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DefaultCell", for: indexPath)
        cell.textLabel?.font = UIFont(name: "Helvetica", size: 9)
        let message = output[indexPath.row]
        cell.textLabel?.text = message
        return cell
    }
}
