//
//  ReservationListViewController.swift
//  CarShare
//
//  Created by Matt Snow on 2019-06-04.
//  Copyright © 2019 BSM Technologies Inc. All rights reserved.
//

import UIKit

class ReservationListViewController: UITableViewController {

    private static let cellIdentifier = "ReservationCell"

    static func initialize(presenter: ReservationListPresenter) -> ReservationListViewController {
        let viewController = ReservationListViewController()
        viewController.presenter = presenter
        return viewController
    }

    private var presenter: ReservationListPresenter!

    private var reservations: [ReservationViewModel] = [] {
        didSet {
            tableView.reloadData()
        }
    }

    deinit {
        log.verbose("deinit")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        DispatchQueue.main.async {
            self.presenter.viewDidLoad(view: self)
        }
    }

}

extension ReservationListViewController: ReservationListView {
    func show(_ reservations: [ReservationViewModel]) {
        self.reservations = reservations
    }

    func show(_ vehicleLocation: Location, userLocation: Location) {
        log.info("vehicle: \(vehicleLocation.latitude), \(vehicleLocation.longitude)")
        log.info("user: \(userLocation.latitude), \(userLocation.longitude)")
    }

    func showDialog(_ message: String) {
        let alert = UIAlertController(title: "Important", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true, completion: nil)
    }

    func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true, completion: nil)
    }

}

extension ReservationListViewController {

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reservations.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ReservationListViewController.cellIdentifier) ?? UITableViewCell(style: .value1, reuseIdentifier: ReservationListViewController.cellIdentifier)
        let reservation = reservations[indexPath.row]
        cell.textLabel?.text = reservation.vehicleName
        cell.detailTextLabel?.text = reservation.isNearby ? "Nearby" : "Not nearby"
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let reservation = reservations[indexPath.row]
        let actionSheet = UIAlertController(title: reservation.vehicleName, message: nil, preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Show on map", style: .default) { [weak self] _ in
            guard let view = self else {
                return
            }
            view.presenter.view(view, didTapLocateVehicleFor: reservation)
        })
        actionSheet.addAction(UIAlertAction(title: "Claim Reservation", style: .default) { [weak self] _ in
            guard let view = self else {
                return
            }
            view.presenter.view(view, didTapUnlock: reservation)
        })
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(actionSheet, animated: true, completion: nil)
    }
}
