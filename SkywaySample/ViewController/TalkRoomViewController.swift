//
//  ViewController.swift
//  SkywaySample
//
//  Created by Ryo Tabuchi on 2023/06/23.
//

import UIKit
import SkyWayRoom

class TalkRoomViewController: UIViewController {
    @IBOutlet weak var remoteView: VideoView!
    @IBOutlet weak var localView: VideoView!
    @IBOutlet weak var muteButton: UIButton!
    @IBOutlet weak var speakerButton: UIButton!
    @IBOutlet weak var backgroundButton: UIButton!
    
    private let skywayManager = SkywayManager()
    private var partnerVideoStream: RemoteVideoStream? {
        didSet {
            oldValue?.detach(remoteView)
            partnerVideoStream?.attach(remoteView)
        }
    }
    
    private var isMute: Bool {
        get {
            skywayManager.isMute
        }
        set {
            skywayManager.isMute = newValue
            if newValue {
                muteButton.setImage(UIImage(named: "mic_off"),
                                    for: .normal)
            } else {
                muteButton.setImage(UIImage(named: "mic_on"),
                                    for: .normal)
            }
        }
    }
    
    private var useSpeaker: Bool {
        get {
            skywayManager.useSpeaker
        }
        set {
            skywayManager.useSpeaker = newValue
            if newValue {
                speakerButton.setImage(UIImage(named: "speaker_on"),
                                       for: .normal)
            } else {
                speakerButton.setImage(UIImage(named: "speaker_off"),
                                       for: .normal)
            }
        }
    }
    
    private var useBackground: Bool {
        get {
            skywayManager.useBackground
        }
        set {
            skywayManager.useBackground = newValue
            if newValue {
                backgroundButton.setImage(UIImage(named: "background_on"),
                                          for: .normal)
            } else {
                backgroundButton.setImage(UIImage(named: "background_off"),
                                          for: .normal)
            }
        }
    }
    
    enum JoinMethod {
        case createRoom(name: String, password: String?)
        case join(room: SSRoom)
    }
    
    var joinMethod: JoinMethod?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        remoteView.videoContentMode = .scaleAspectFill
        localView.videoContentMode = .scaleAspectFill
        skywayManager.delegate = self
        guard let joinMethod else {
            fatalError("Missing join method.")
        }
        switch joinMethod {
        case .createRoom(name: let name, password: let password):
            createRoom(name: name, password: password)
        case .join(room: let room):
            joinRoom(room: room)
        }
    }

    private func createRoom(name: String, password: String?) {
        Task {
            let result = await skywayManager.createRoom(name: name, password: password)
            switch result {
            case .success:
                skywayManager.localVideoStream?.attach(localView)
            case .failure(let error):
                showAlert(message: error.message)
            }
        }
    }
    
    private func joinRoom(room: SSRoom) {
        Task {
            let result = await skywayManager.joinRoom(room: room)
            switch result {
            case .success:
                skywayManager.localVideoStream?.attach(localView)
            case .failure(let error):
                showAlert(message: error.message)
            }
        }
    }
    
    private func leave() {
        Task {
            await skywayManager.leave()
        }
        dismiss(animated: true)
    }
    
    @IBAction func didSelectClose(_ sender: Any) {
        let alert = UIAlertController(title: "確認",
                                      message: "退室しますか？",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK",
                                      style: .default) { [weak self] _ in
            self?.leave()
        })
        alert.addAction(UIAlertAction(title: "キャンセル",
                                      style: .cancel))
        present(alert,
                animated: true)
    }
    
    @IBAction func didSelectMic(_ sender: Any) {
        isMute.toggle()
    }
    
    @IBAction func didSelectSpeaker(_ sender: Any) {
        useSpeaker.toggle()
    }
    
    @IBAction func didSelectBackground(_ sender: Any) {
        useBackground.toggle()
    }
}

extension TalkRoomViewController: SkywayManagerDelegate {
    func didPartnerJoined(videoStream: RemoteVideoStream?) {
        partnerVideoStream = videoStream
    }
}
