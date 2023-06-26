//
//  UIViewController+Ext.swift
//  SkywaySample
//
//  Created by Ryo Tabuchi on 2023/06/24.
//

import UIKit

extension UIViewController {
    func showAlert(message: String) {
        let alert = UIAlertController(title: nil,
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
