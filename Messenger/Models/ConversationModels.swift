//
//  ConversationModels.swift
//  Messenger
//
//  Created by Gabriel Castillo Serafim on 27/9/22.
//

import Foundation

//Used to create conversation objects on this VC and on the database manager VC
struct Conversation {
    let id: String
    let name: String
    let otherUserEmail: String
    let latestMessage: LatestMessage
}
//Is a part of the Conversation struct to match the structure of our data from the database
struct LatestMessage {
    let date: String
    let text: String
    let isRead: Bool
}
