//
//  DatabaseManager.swift
//  Messenger
//
//  Created by Gabriel Castillo Serafim on 13/9/22.
//

import Foundation
import FirebaseDatabase
import UIKit

/// Manager object to read and write data to real time firebase database
final class DatabaseManager {
    
    //Create static var so we can access all DatabaseManager properties and methods by typing "shared"
    static let shared = DatabaseManager()
    
    //Creates a reference to the database called "database"
    private let database = Database.database().reference()
    
    //Function to transform the email to formatted version
    static func formatedEmail(emailAddress: String) -> String {
        //Replaces "." with "-"  and "@" with "-" on the users email because a child in the database can't contain "."
        var formattedEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        formattedEmail = formattedEmail.replacingOccurrences(of: "@", with: "-")
        return formattedEmail
    }
}

//MARK: - Account Management

extension DatabaseManager {
    
    ///Adds user to the database
    public func insertUser(with user: ChatAppUser){
        //Adds to the database a child named with user's email and with the value of first name and last name
        database.child(user.formattedEmail).setValue(["first_name": user.firstName, "last_name": user.lastName], withCompletionBlock: { [weak self] error, _ in
            guard error == nil else {
                print("failed to write to database")
                return
            }
            //First we accesses the database child called "users"
            self?.database.child("users").observeSingleEvent(of: .value, with: { [weak self] snapshot in
                //Checks to see if a [[String:String]] dictionary was already created and if was assigns the dictionary to the variable usersCollection, else creates a brand new on the "else" statement.
                if var usersCollection = snapshot.value as? [[String:String]] {
                    //Create a new element to append to the usersCollection dictionary
                    let newElement = ["name": user.firstName + " " + user.lastName, "email": user.emailAddress]
                    //Append the newElement to usersCollection dictionary variable
                    usersCollection.append(newElement)
                    //Accesses the database and replaces the old dictionary with all the users with the new one "usersCollection" with the new user appended
                    self?.database.child("users").setValue(usersCollection, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            return
                        }
                    })
                } else {
                    //Create the array that we want to insert to the child called "users" that is going to be created
                    let newCollection: [[String:String]] = [["name": user.firstName + " " + user.lastName, "email": user.emailAddress]]
                    //Inserts the array created above to the database and created the user child
                    self?.database.child("users").setValue(newCollection, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            return
                        }
                    })
                }
            })
        })
    }
    
    ///Gets all the users from the database
    public func getAllUsers(completion: @escaping (Result<[[String:String]],Error>) -> Void) {
        database.child("users").observeSingleEvent(of: .value, with: { snapshot in
            guard let value = snapshot.value as? [[String:String]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        })
    }
    
    //Enum with the errors for the database manager
    private enum DatabaseError: Error {
        case failedToFetch
    }
}

//MARK: - Sending messages / Conversations

extension DatabaseManager {
    
    ///Creates a new conversation with target user email and first message sent with completion to check if succeeded
    public func createNewConversation(with otherUserEmail: String, name: String, firstMessage: Message, completion: @escaping(Bool) -> Void) {
        
        let currentName = UserDefaults.standard.string(forKey: "userName")!
        let currentEmail = UserDefaults.standard.string(forKey: "userEmail")!
        let formattedEmail = DatabaseManager.formatedEmail(emailAddress: currentEmail)
        //Reference to the current user's child on database
        let ref = database.child(formattedEmail)
        
        //See if can find current user with email on database to prevent errors, if can't find return and call completion false
        ref.observeSingleEvent(of: .value) { [weak self] snapshot in
            guard var userNode = snapshot.value as? [String: Any] else {
                completion(false)
                print("User not found")
                return
            }
            //Variables used to fill the new conversation data
            let messageDate = firstMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            var message = ""
            
            //Check the message type
            switch firstMessage.kind {
                //If it is message text assign it's text content to the message variable
            case .text(let messageText):
                message = messageText
            default:
                break
            }
            
            let conversationId = "conversation_\(firstMessage.messageId)"
            
            //All the data that is going to be passed to a new or existing conversation in current user
            let newConversationData: [String: Any] = [
                "id": conversationId,
                "other_user_email": otherUserEmail,
                "name": name, //Receiver user name
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]
            
            //All the data that is going to be passed to a new or existing conversation in target user
            let recipient_newConversationData: [String: Any] = [
                "id": conversationId,
                "other_user_email": formattedEmail,
                "name": currentName,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]
            
            //Update recipient user conversation entry...
            
            //Accesses the user that is going to receive the message on the database and sets observer
            self?.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value, with: { [weak self] snapshot in
                //If the conversation already exists "in not nil" appends updated conversations array
                if var conversations = snapshot.value as? [[String: Any]] {
                    //Append
                    conversations.append(recipient_newConversationData)
                    self?.database.child("\(otherUserEmail)/conversations").setValue([conversations])
                    
                } else {
                    //Create conversation under recipient user
                    self?.database.child("\(otherUserEmail)/conversations").setValue([recipient_newConversationData])
                }
            })
            
            //Update current user conversation entry and create conversation child on top level...
            
            //Check if the conversation already exists, and if it does assigns the current value for it to the conversations variable
            if var conversations = userNode["conversations"] as? [[String: Any]] {
                //Conversation array exists for current user, therefore append new conversation data to conversations
                conversations.append(newConversationData)
                //Sets new conversations array with appended new data to userNode
                userNode["conversations"] = conversations
                //Set value on database
                ref.setValue(userNode) { [weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    //Add or update conversation as a child of database on the top level, by creating this child on the top level allows us to query and observe a unique conversation without having to search inside users emails
                    self?.finishCreatingConversation(name: name,conversationID: conversationId, firstMessage: firstMessage, completion: completion)
                }
            } else {
                //conversation array do not exist
                //Create conversations
                userNode["conversations"] = [
                    newConversationData
                ]
                //Set value on database
                ref.setValue(userNode) { [weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    //Add or update conversation as a child of database on the top level, by creating this child on the top level allows us to query and observe a unique conversation without having to search inside users emails
                    self?.finishCreatingConversation(name: name,conversationID: conversationId, firstMessage: firstMessage, completion: completion)
                }
            }
        }
    }
    
    //Called in the create conversation function to create or append to a conversation child on top level with a single identifier for the conversation.
    private func finishCreatingConversation(name: String, conversationID: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
        
        let currentUserEmail = UserDefaults.standard.string(forKey: "userEmail")
        let formattedEmail = DatabaseManager.formatedEmail(emailAddress: currentUserEmail!)
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        
        var message = ""
        
        //Check the message type
        switch firstMessage.kind {
            //If it is message text assign it's text content to the message variable
        case .text(let messageText):
            message = messageText
        default:
            break
        }
        
        let collectionMessage:[String: Any] = [
            "id": firstMessage.messageId,
            "type": firstMessage.kind.messageKingString,
            "content": message,
            "date": dateString,
            "sender_email": formattedEmail,
            "is_read": false,
            "name": name
        ]
        
        let value: [String: Any] = [
            "messages": [
                collectionMessage
            ]
        ]
        
        database.child("\(conversationID)").setValue(value) { error, _ in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    ///Fetches and returns all conversations for the user with passed in email
    public func getAllConversations(for email: String, completion: @escaping (Result<[Conversation], Error>) -> Void) {
        //Accesses conversations inside the email child
        database.child("\(email)/conversations").observe(.value, with: { snapshot in
            //Assigns to the "value" variable the conversations snapshot which has a datatype of [[String: Any]]
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            //Used the compactMap to iterate on "value" dictionary and bring all elements casted as we want to populate our model and if one of them is missing the guard returns nil "compactMap returns an array with no nil values"
            let conversations: [Conversation] = value.compactMap({ dictionary in
                guard let conversationId = dictionary["id"] as? String,
                      let name = dictionary["name"] as? String,
                      let otherUserEmail = dictionary["other_user_email"] as? String,
                      let latestMessage = dictionary["latest_message"] as? [String: Any],
                      let date = latestMessage["date"] as? String,
                      let message = latestMessage["message"] as? String,
                      let isRead = latestMessage["is_read"] as? Bool else {
                    return nil
                }
                //LatestMessage is a array inside the conversation array below we are going to incorporate it to the final object "used struct from conversations VC"
                let latestMessageObject = LatestMessage(date: date, text: message, isRead: isRead)
                //Final object with all conversation data properly unwrapped and organised "used struct from conversations VC"
                return Conversation(id: conversationId, name: name, otherUserEmail: otherUserEmail, latestMessage: latestMessageObject)
                
            })
            //Call completion and assign the result of the compactMap which is the conversations object
            completion(.success(conversations))
        })
    }
    
    ///Gets all messages for a given conversation
    public func getAllMessagesForConversation(with id: String, completion: @escaping (Result<[Message], Error>) -> Void) {
        //Accesses messages inside the conversation id child that we have on top level
        database.child("\(id)/messages").observe(.value, with: { snapshot in
            //Assigns to the "value" variable the conversation id snapshot which has a datatype of [[String: Any]]
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            //Used the compactMap to iterate on "value" dictionary and bring all elements casted as we want to populate our model and if one of them is missing the guard returns nil "compactMap returns an array with no nil values"
            let messages: [Message] = value.compactMap({ dictionary in
                guard let name = dictionary["name"] as? String,
                      //let isRead = dictionary["is_read"] as? Bool,
                      let messageID = dictionary["id"] as? String,
                      let content = dictionary["content"] as? String,
                      let senderEmail = dictionary["sender_email"] as? String,
                      let dateString = dictionary["date"] as? String,
                      let date = ChatViewController.dateFormatter.date(from: dateString) else {
                    return nil
                }
                
                let sender = Sender(photoURL: "", senderId: senderEmail, displayName: name)
                
                return Message(sender: sender, messageId: messageID, sentDate: date, kind: .text(content))
            })
            //Call completion and assign the result of the compactMap which is the messages object
            completion(.success(messages))
        })
    }
    
    
    ///Sends a message (Takes target conversation and message parameters), (Appends message to specific conversation and updates both users latest messages child).
    public func sendMessage(to conversation: String, otherUserEmail: String, name: String, newMessage: Message, completion: @escaping (Bool) -> Void) {
        
        //Send message part...
        
        //Access messages inside conversation child located on top level and identified by a unique conversation ID
        database.child("\(conversation)/messages").observeSingleEvent(of: .value, with: { [weak self] snapshot in
            //Assigns the snapshot value to "currentMessages" variable (if it's not nil). The snapshot represents the array of dictionaries which contains all the messages as dictionaries.
            guard var currentMessages = snapshot.value as? [[String: Any]] else {
                completion(false)
                return
            }
            //Variables that will be used along the function
            let currentName = UserDefaults.standard.value(forKey: "userName")!
            let currentEmail = UserDefaults.standard.string(forKey: "userEmail")!
            let currentUserEmail = DatabaseManager.formatedEmail(emailAddress: currentEmail)
            let messageDate = newMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)

            var message = ""
            
            //Check the message type "for now only have text messages"
            switch newMessage.kind {
                //If it is message text assign it's text content to the message variable
            case .text(let messageText):
                message = messageText
            default:
                break
            }
            
            //Creates new message dictionary which contains all the data that a new message needs
            let newMessageEntry: [String: Any] = [
                "id": newMessage.messageId,
                "type": newMessage.kind.messageKingString,
                "content": message,
                "date": dateString,
                "sender_email": currentUserEmail,
                "is_read": false,
                "name": name
            ]
            //Append the new message dictionary to currentMessages (variable that the database snapshot got assigned to)
            currentMessages.append(newMessageEntry)
            
            //Sets the value of our specific conversation array of message dictionaries to be the updated one that contains the "newMessageEntry" appended to it.
            self?.database.child("\(conversation)/messages").setValue(currentMessages) { error, _ in
                guard error == nil else {
                    completion(false)
                    return
                }
               
                //Updating latest message child on both users (so it can show properly on conversations VC)...
                
                //Update on sender user...
                
                //Access conversations in current user's child and get database snapshot.
                self?.database.child("\(currentUserEmail)/conversations").observeSingleEvent (of: .value, with: { snapshot in
                    
                    //The updated conversation array that is going to be inserted back to the database.
                    var databaseEntryConversations = [[String: Any]]()
                    
                    //Value of the latest message that we are going to pass to our users conversation "latest_message" dictionary
                    let updatedValue: [String: Any] = [
                        "date": dateString,
                        "is_read": false,
                        "message": message
                    ]
                    
                    //First if statement checks if the snapshot value is not nil and then assigns it to "currentUserConversations" if this condition is true it means that the user has conversations created on the database and therefore we must find the conversation that has to get the "latest-message" dictionary value modified, for that we use a for loop that iterates on the values of the snapshot to find a match for the conversation id called "conversation" passed on the function parameters, for each iteration that the conversation is not found the loop adds one to a position variable that later on is going to be used to identify the position of the target conversation on our snapshot. Inside the first if statement there is a second if statement that checks if the "targetConversation" is not nil, if the condition is true it means that our for loop found a match for the conversation id and therefore can proceed to assign the updated value to the latest_message dictionary match and set the "databaseEntryConversations" variable to be equal to the updated array of conversations, otherwise if the condition ends up being false we append a new conversation to the "currentUserConversations" array of conversations and then set the value of the "databaseEntryConversations" to be equal to the updated array of conversations ("databaseEntryConversations" is the updated array that is going to be passed back to the database). If the first if statement is not true we are facing the case in which the current user does not have any conversations in the snapshot therefore we must only add the newConversation to the database, without appending or modifying an existing conversation.
                    
                    if var currentUserConversations = snapshot.value as? [[String: Any]] {
                        var targetConversation: [String: Any]?
                        var position = 0

                        for conversationDictionary in currentUserConversations {
                            if let currentId = conversationDictionary["id"] as? String, currentId == conversation {
                                targetConversation = conversationDictionary
                                break
                            }
                            position += 1
                        }

                        if var targetConversation = targetConversation {
                            targetConversation["latest_message"] = updatedValue
                            currentUserConversations[position] = targetConversation
                            databaseEntryConversations = currentUserConversations
                        }
                        else {
                            let newConversationData: [String: Any] = [
                                "id": conversation,
                                "other_user_email": DatabaseManager.formatedEmail(emailAddress: otherUserEmail),
                                "name": name, //Other users name
                                "latest_message": updatedValue
                            ]
                            currentUserConversations.append(newConversationData)
                            databaseEntryConversations = currentUserConversations
                        }
                    }
                    else {
                        let newConversationData: [String: Any] = [
                            "id": conversation,
                            "other_user_email": DatabaseManager.formatedEmail(emailAddress: otherUserEmail),
                            "name": name,
                            "latest_message": updatedValue
                        ]
                        databaseEntryConversations = [newConversationData]
                    }

                    self?.database.child("\(currentUserEmail)/conversations").setValue(databaseEntryConversations, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        
                        
                        //Performing update on latest message just like before but for the recipient user...
                        
                        
                        self?.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
                            
                            let updatedValue: [String: Any] = [
                                "date": dateString,
                                "is_read": false,
                                "message": message
                            ]
                            var databaseEntryConversations = [[String: Any]]()
                            
                            
                            if var otherUserConversations = snapshot.value as? [[String: Any]] {
                                var targetConversation: [String: Any]?
                                var position = 0

                                for conversationDictionary in otherUserConversations {
                                    if let currentId = conversationDictionary["id"] as? String, currentId == conversation {
                                        targetConversation = conversationDictionary
                                        break
                                    }
                                    position += 1
                                }

                                if var targetConversation = targetConversation {
                                    targetConversation["latest_message"] = updatedValue
                                    otherUserConversations[position] = targetConversation
                                    databaseEntryConversations = otherUserConversations
                                }
                                else {
                                    // failed to find in current collection
                                    let newConversationData: [String: Any] = [
                                        "id": conversation,
                                        "other_user_email": currentUserEmail,
                                        "name": currentName,
                                        "latest_message": updatedValue
                                    ]
                                    otherUserConversations.append(newConversationData)
                                    databaseEntryConversations = otherUserConversations
                                }
                            }
                            else {
                                // current collection does not exist
                                let newConversationData: [String: Any] = [
                                    "id": conversation,
                                    "other_user_email": DatabaseManager.formatedEmail(emailAddress: currentUserEmail),
                                    "name": currentName,
                                    "latest_message": updatedValue
                                ]
                                databaseEntryConversations = [newConversationData]
                            }

                            self?.database.child("\(otherUserEmail)/conversations").setValue(databaseEntryConversations, withCompletionBlock: { error, _ in
                                guard error == nil else {
                                    completion(false)
                                    return
                                }
                                completion(true)
                            })
                        })
                    })
                })
            }
        })
    }
    
    //MARK: - Deleting conversations

    ///Deletes conversation from user's database
    public func deleteConversation(conversationId: String, completion: @escaping (Bool) -> Void) {
        let userEmail = UserDefaults.standard.string(forKey: "userEmail")!
        let formattedEmail = DatabaseManager.formatedEmail(emailAddress: userEmail)
        //Reference to database path for conversations in user child
        let ref = database.child("\(formattedEmail)/conversations")
        
        print("DELETTING CONVERSATION WITH ID \(conversationId)")
        
        //Function iterates thru array of dictionaries that we called conversations and check if the id item for each dictionary matches the conversation id provided on the functions's parameter, for each iteration ads one to the position to remove, after finding a match breaks out of the function and removes the conversation from the array using the position to remove variable "counter" that we created, after removing replaces updated array to database.
        ref.observeSingleEvent(of: .value) { snapshot in
            if var conversations = snapshot.value as? [[String: Any]] {
                
                var positionToRemove = 0
                
                for conversation in conversations {
                    if let id = conversation["id"] as? String, id == conversationId {
                        print("FOUND CONVERSATION TO DELETE")
                        break
                    }
                    positionToRemove += 1
                }
                conversations.remove(at: positionToRemove)
                ref.setValue(conversations) { error, _ in
                    guard error == nil else {
                        completion(false)
                        print("FAILED TO WRITE NEW CONVERSATION ARRAY")
                        return
                    }
                    print("DELETED CONVERSATION")
                    completion(true)
                }
            }
        }
    }
    
    //MARK: - Generic databaseManegement functions
    
    //Pass in generic child path to get result back from db
    public func getDataFor(path: String, completion: @escaping (Result<Any, Error>) -> Void) {
        self.database.child("\(path)").observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        }
    }

}



