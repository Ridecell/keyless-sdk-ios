//
//  ReservationListPresenter.swift
//  CarShare
//
//  Created by Matt Snow on 2019-06-03.
//  Copyright © 2019 BSM Technologies Inc. All rights reserved.
//

import RxSwift

class DefaultReservationListPresenter: ReservationListPresenter {

    private let interactor: ReservationListInteractor
    private let router: ReservationListRouter
    private let disposeBag = DisposeBag()

    init(interactor: ReservationListInteractor, router: ReservationListRouter) {
        self.interactor = interactor
        self.router = router
    }

    deinit {
        log.verbose("deinit")
    }

    func viewDidLoad(view: ReservationListView) {
        interactor
            .findReservations()
            .map { reservations in
                reservations.map { reservation in
                    ReservationViewModel(
                        reservationId: reservation.reservationId,
                        vehicleName: reservation.vehicle.vehicleName,
                        locationName: reservation.vehicleLocation.name,
                        isNearby: reservation.isConnectable,
                        isActive: reservation.isActive)
                }
            }
            .subscribe(onNext: { [weak view] reservations in
                view?.show(reservations)
            })
            .disposed(by: disposeBag)
    }

    func view(_ view: ReservationListView, didTapLocateVehicleFor reservation: ReservationViewModel) {
        Observable
            .combineLatest(
                interactor.location(for: reservation.reservationId),
                interactor.activeLocation)
            .subscribe(onNext: { [weak view] vehicleLocation, userLocation in
                view?.show(vehicleLocation, userLocation: userLocation)
            })
            .disposed(by: disposeBag)
    }

    func view(_ view: ReservationListView, didTapUnlock reservation: ReservationViewModel) {
        interactor
            .claim(reservation.reservationId)
            .subscribe(onCompleted: {
                self.router.goToReservationPage(for: reservation.reservationId)
            })
            .disposed(by: disposeBag)
    }

}
