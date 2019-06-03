//
//  TemperatureDeviceListViewController.swift
//  CarShare
//
//  Created by Matt Snow on 2019-06-03.
//  Copyright © 2019 BSM Technologies Inc. All rights reserved.
//

import UIKit

class TemperatureDeviceListViewController: UITableViewController {

    private static let cellIdentifier = "TemperatureDeviceCell"

    static func initialize(presenter: TemperatureDeviceListPresenter) -> TemperatureDeviceListViewController {
        let viewController = TemperatureDeviceListViewController()
        viewController.presenter = presenter
        return viewController
    }

    private var presenter: TemperatureDeviceListPresenter!

    private var devices: [TemperatureDevice] = [] {
        didSet {
            tableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: TemperatureDeviceListViewController.cellIdentifier)
        DispatchQueue.main.async {
            self.presenter.viewDidLoad(view: self)
        }
    }

}

extension TemperatureDeviceListViewController: TemperatureDeviceListView {
    func show(_ devices: [TemperatureDevice]) {
        self.devices = devices
    }

    func showTemperature(value: Float) {
        let alert = UIAlertController(title: "Temperature", message: "\(value)°C", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true, completion: nil)
    }

    func showError(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true, completion: nil)
    }
}

extension TemperatureDeviceListViewController {

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return devices.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TemperatureDeviceListViewController.cellIdentifier, for: indexPath)
        cell.textLabel?.text = devices[indexPath.row].name
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        presenter.view(self, didTapDevice: devices[indexPath.row])
    }
}
