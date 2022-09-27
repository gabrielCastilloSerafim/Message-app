//
//  DatabaseManagerModels.swift
//  Messenger
//
//  Created by Gabriel Castillo Serafim on 27/9/22.
//

import Foundation

//Chat user model
struct ChatAppUser {
    
    let firstName: String
    let lastName: String
    let emailAddress: String
    
    var formattedEmail: String {
        //Replaces "." with "-"  and "@" with "-" on the users email because a child in the database can't contain "."
        var formattedEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        formattedEmail = formattedEmail.replacingOccurrences(of: "@", with: "-")
        return formattedEmail
    }
    
    //Standardises the picture file names to be easily accessed on database afterwards
    var profilePictureFileName: String {
        return "\(formattedEmail)_profile_picture.png"
    }
    
}
