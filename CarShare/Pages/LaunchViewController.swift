//
//  LaunchViewController.swift
//  CarShare
//
//  Created by Matt Snow on 2019-06-03.
//  Copyright © 2019 BSM Technologies Inc. All rights reserved.
//

import UIKit

class LaunchViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let button = UIButton(type: .roundedRect)
        button.setTitle("Reservations", for: .normal)
        button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
        view.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        button.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }

    @objc func didTapButton() {
        let vc = (UIApplication.shared.delegate as! AppDelegate).container.resolve(ReservationListView.self) as! UIViewController
        navigationController?.pushViewController(vc, animated: true)
    }
}
