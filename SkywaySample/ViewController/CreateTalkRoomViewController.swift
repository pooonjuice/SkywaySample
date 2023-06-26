//
//  CreateTalkRoomViewController.swift
//  SkywaySample
//
//  Created by Ryo Tabuchi on 2023/06/24.
//

import UIKit

protocol CreateTalkRoomViewControllerDelegate: AnyObject {
    func didSelectCreateRoom(name: String, password: String?)
}
class CreateTalkRoomViewController: UIViewController {
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    weak var delegate: CreateTalkRoomViewControllerDelegate?
    
    private var usePassword = true {
        didSet {
            passwordTextField.isEnabled = usePassword
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        nameTextField.delegate = self
        passwordTextField.delegate = self
    }
    
    @IBAction func didChangeUsePassword(_ sender: UISwitch) {
        usePassword = sender.isOn
    }
    
    @IBAction func didSelectOK(_ sender: Any) {
        guard let name = nameTextField.text,
              !name.isEmpty else {
            showAlert(message: "ルーム名を入力してください")
            return
        }
        if !usePassword {
            dismiss(animated: true) { [weak self] in
                self?.delegate?.didSelectCreateRoom(name: name,
                                                    password: nil)
            }
        } else if let password = passwordTextField.text,
                  !password.isEmpty {
            dismiss(animated: true) { [weak self] in
                self?.delegate?.didSelectCreateRoom(name: name,
                                                    password: password)
            }
        } else {
            showAlert(message: "パスワードを入力してください")
        }
    }
    
    @IBAction func didSelectCancel(_ sender: Any) {
        dismiss(animated: true)
    }
}

extension CreateTalkRoomViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
