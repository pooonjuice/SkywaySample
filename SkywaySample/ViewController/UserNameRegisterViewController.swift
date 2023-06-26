//
//  UserNameRegisterViewController.swift
//  SkywaySample
//
//  Created by Ryo Tabuchi on 2023/06/24.
//

import UIKit

class UserNameRegisterViewController: UIViewController {
    @IBOutlet weak var okButton: UIButton!
    @IBOutlet weak var textField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        textField.delegate = self
        okButton.isEnabled = false
    }
    
    @IBAction func didSelectOk(_ sender: Any) {
        UserDefaults.userName = textField.text
        dismiss(animated: true)
    }
}

extension UserNameRegisterViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        guard let text = textField.text,
              let range = Range(range, in: text) else {
            return true
        }
        okButton.isEnabled = !text.replacingCharacters(in: range,
                                                      with: string).isEmpty
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
