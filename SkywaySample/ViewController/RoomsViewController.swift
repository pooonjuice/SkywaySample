//
//  RoomsViewController.swift
//  SkywaySample
//
//  Created by Ryo Tabuchi on 2023/06/24.
//

import UIKit

class RoomsViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noRoomsLabel: UILabel!
    
    private let firestoreManager = FirestoreManager()
    private let refreshControl = UIRefreshControl()
    
    private var rooms: [SSRoom] = [] {
        didSet {
            noRoomsLabel.isHidden = !rooms.isEmpty
            tableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        noRoomsLabel.isHidden = true
        tableView.register(UINib(nibName: String(describing: RoomTableViewCell.self),
                                 bundle: .main),
                           forCellReuseIdentifier: String(describing: RoomTableViewCell.self))
        tableView.addSubview(refreshControl)
        refreshControl.addTarget(self,
                                 action: #selector(reloadData),
                                 for: .valueChanged)
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if UserDefaults.userName == nil {
            let vc = storyboard?.instantiateViewController(withIdentifier: String(describing: UserNameRegisterViewController.self)) as! UserNameRegisterViewController
            vc.modalTransitionStyle = .crossDissolve
            vc.modalPresentationStyle = .overFullScreen
            present(vc, animated: true)
        }
    }
    
    @objc
    private func reloadData() {
        Task {
            rooms = try await firestoreManager.rooms()
            refreshControl.endRefreshing()
        }
    }
    
    @IBAction func didSelectCreateRoom(_ sender: Any) {
        let vc = storyboard?.instantiateViewController(withIdentifier: String(describing: CreateTalkRoomViewController.self)) as! CreateTalkRoomViewController
        vc.delegate = self
        vc.modalTransitionStyle = .crossDissolve
        vc.modalPresentationStyle = .overFullScreen
        present(vc, animated: true)
    }
}

extension RoomsViewController: CreateTalkRoomViewControllerDelegate {
    func didSelectCreateRoom(name: String, password: String?) {
        let vc = storyboard?.instantiateViewController(withIdentifier: String(describing: TalkRoomViewController.self)) as! TalkRoomViewController
        vc.joinMethod = .createRoom(name: name,
                                    password: password)
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }
}

extension RoomsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rooms.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: RoomTableViewCell.self),
                                                 for: indexPath) as! RoomTableViewCell
        cell.room = rooms[indexPath.row]
        return cell
    }
}

extension RoomsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath,
                              animated: true)
        let vc = storyboard?.instantiateViewController(withIdentifier: String(describing: TalkRoomViewController.self)) as! TalkRoomViewController
        vc.joinMethod = .join(room: rooms[indexPath.row])
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }
}
