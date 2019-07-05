//
//  ReservationList.swift
//  CarShare
//
//  Created by Matt Snow on 2019-06-03.
//  Copyright © 2019 BSM Technologies Inc. All rights reserved.
//

import RxSwift

struct Reservation: Equatable {
    let reservationId: String
    let userId: String
    let vehicle: Vehicle
    let sharedSecret: String
    let isActive: Bool
    let notBeforeTimestamp: Double
    let expiryTimestamp: Double
    let vehicleLocation: Location
    let isConnectable: Bool
}

struct Vehicle: Equatable {
    let vehicleId: String
    let vehicleName: String
}

struct Location: Equatable {
    let latitude: Double
    let longitude: Double
    let name: String
}

struct ReservationViewModel: Equatable {
    let reservationId: String
    let vehicleName: String
    let locationName: String
    let isNearby: Bool
    let isActive: Bool
}

protocol ReservationListView: AnyObject {
    func show(_ reservations: [ReservationViewModel])
    func show(_ vehicleLocation: Location, userLocation: Location)
    func showDialog(_ message: String)
    func showError(_ message: String)
}

protocol ReservationListPresenter: AnyObject {
    func viewDidLoad(view: ReservationListView)
    func view(_ view: ReservationListView, didTapLocateVehicleFor reservation: ReservationViewModel)
    func view(_ view: ReservationListView, didTapUnlock reservation: ReservationViewModel)
}

protocol ReservationListInteractor: AnyObject {
    var activeLocation: Observable<Location> { get }
    func findReservations() -> Observable<[Reservation]>
    func location(for reservationId: String) -> Observable<Location>
    func claim(_ reservationId: String) -> Completable
}

protocol ReservationListRouter: AnyObject {
    func goToReservationPage(for reservationId: String)
}
