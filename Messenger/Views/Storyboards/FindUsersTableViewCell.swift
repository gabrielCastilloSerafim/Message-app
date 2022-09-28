//
//  FindUsersTableViewCell.swift
//  Messenger
//
//  Created by Gabriel Castillo Serafim on 27/9/22.
//

import UIKit

class FindUsersTableViewCell: UITableViewCell {

    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var profilePicture: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        profilePicture.layer.cornerRadius = profilePicture.frame.height/2
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
