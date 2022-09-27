//
//  ConversationTableViewCell.swift
//  Messenger
//
//  Created by Gabriel Castillo Serafim on 20/9/22.
//

import UIKit

class ConversationTableViewCell: UITableViewCell {

    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Makes profile picture a circle
        profilePicture.layer.cornerRadius = profilePicture.frame.width/2
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
