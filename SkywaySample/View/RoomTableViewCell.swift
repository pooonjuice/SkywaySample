//
//  RoomTableViewCell.swift
//  SkywaySample
//
//  Created by Ryo Tabuchi on 2023/06/24.
//

import UIKit

class RoomTableViewCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var optionLabel: UILabel!
    
    var room: SSRoom? {
        didSet {
            nameLabel.text = room?.name
            optionLabel.text = room?.password == nil ? "誰でも参加可能" : "パスワードあり"
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
