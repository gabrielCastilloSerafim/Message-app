//
//  ChatViewController.swift
//  Messenger
//
//  Created by Gabriel Castillo Serafim on 14/9/22.
//

import UIKit
import MessageKit
import InputBarAccessoryView

///Class that lets user read and write new messages.
//Changed the class from UIViewController to MessagesViewController to conform to the MessageKit framework.
final class ChatViewController: MessagesViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Set the chat nav bar title name
        navigationItem.title = Self.otherUsersName
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
        
        listenForMessages()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //Presents keyboard automatically when view will appear
        messageInputBar.inputTextView.becomeFirstResponder()
        
        self.messagesCollectionView.scrollToLastItem(animated: true)
        
    }
    
    //Called on view did load to listen for messages
    private func listenForMessages() {
        DatabaseManager.shared.getAllMessagesForConversation(with: Self.conversationId) { [weak self] result in
            switch result {
            case .success(let messages):
                guard messages.isEmpty == false else {
                    return
                }
                self?.messages = messages
                
                DispatchQueue.main.async {
                    self?.messagesCollectionView.reloadDataAndKeepOffset()
                }
            case .failure(let error):
                print("failed to get messages:\(error)")
            }
        }
    }
    
    //MARK: - Variables and computed properties
    
    //Data that comes from conversation and new conversation VCs
    static var otherUsersName = ""
    static var otherUserEmail = ""
    static var isNewConversation = false
    static var conversationId = ""
    
    //Array of messages to display
    private var messages:[Message] = []
    
    //Computed property that has a type sender and returns a sender object
    private var selfSender: Sender {
        let email = UserDefaults.standard.string(forKey: "userEmail")
        let formattedEmail = DatabaseManager.formatedEmail(emailAddress: email!)
        return Sender(photoURL: "",
                      senderId: formattedEmail,
                      displayName: "Me")
    }
    
    //For the avatar photos
    private var senderPhotoURL: URL?
    private var otherPhotoURL: URL?
    
    //Created this date formatter to user across app to get formatted date
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()
    

}

//MARK: - InputBarAccessoryViewDelegate

extension ChatViewController: InputBarAccessoryViewDelegate {
    //Send message...
    
    //Executes when pressed send button, text typed can be accessed using "text" property
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        //Clears input text field
        inputBar.inputTextView.text = ""
        
        DispatchQueue.main.async {
            self.messagesCollectionView.scrollToLastItem(animated: true)
        }
        
        let formattedEmail = DatabaseManager.formatedEmail(emailAddress: Self.otherUserEmail)
        
        let message = Message(sender: selfSender, messageId: createMessageId(), sentDate: Date(), kind: .text(text))
        
        //Check if is a new conversation and if it is creates a new conversation
        if Self.isNewConversation == true {
            //Create new conversation on database
            DatabaseManager.shared.createNewConversation(with: formattedEmail, name: Self.otherUsersName, firstMessage: message) { success in
                if success == true {
                    print("message sent")
                    Self.isNewConversation = false
                } else {
                    print("Failed to send")
                }
            }
        } else {
            //Append to existing conversation on database
            DatabaseManager.shared.sendMessage(to: Self.conversationId, otherUserEmail: Self.otherUserEmail, name: Self.otherUsersName ,newMessage: message, completion: { success in
                
                if success == true {
                    print("MESSAGE SENT")
                    
                } else {
                    print("FAILED TO SEND MESSAGE")
                    
                }
                
            })
        }
        
    }
    //Function that generates a unique message Id
    private func createMessageId() -> String  {
        let formattedEmail = DatabaseManager.formatedEmail(emailAddress: Self.otherUserEmail)
        let dateString = Self.dateFormatter.string(from: Date())
        let formattedDate = dateString.replacingOccurrences(of: ".", with: "_")
        let currentUserEmail = UserDefaults.standard.string(forKey: "userEmail")
        let formattedCurrentUserEmail = DatabaseManager.formatedEmail(emailAddress: currentUserEmail!)
        
        let newIdentifier = "\(formattedEmail)_\(formattedCurrentUserEmail)_\(formattedDate)"
        
        print("CREATED MESSAGE \(newIdentifier)")
        
        return newIdentifier
    }
}

//MARK: - Messages Setup

//This extension uses protocols from the MessageKit framework
extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    
    //This current sender function is used to determine if a message was sent by the current or received by the current user to place the message bubble on the right or on the left side of the screen.
    func currentSender() -> MessageKit.SenderType {
        return selfSender
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessageKit.MessagesCollectionView) -> MessageKit.MessageType {
        //Framework uses sections to separate the messages and because of that we are not calling indexPath.row we are calling indexPath.section
        return messages[indexPath.section]
    }
    
    //Just like a number of rows in a table view
    func numberOfSections(in messagesCollectionView: MessageKit.MessagesCollectionView) -> Int {
        return messages.count
    }
    //Message bubble color
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        let sender = message.sender
        //if message comes from user use this color
        if sender.senderId == selfSender.senderId {
            return #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1)
        } else {
            return .secondarySystemBackground
        }
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        
        let sender = message.sender
        //if message comes from user use this image
        if sender.senderId == selfSender.senderId {
            //If we already have the url in the variable we just need to set it to the avatar view
            if let currentUserURL = self.senderPhotoURL {
                avatarView.sd_setImage(with: currentUserURL)
                //If the url variable is nil then we have to fetch it and then set it
            } else {
                
                let email = UserDefaults.standard.string(forKey: "userEmail")!
                let formattedEmail = DatabaseManager.formatedEmail(emailAddress: email)
                let path = "images/\(formattedEmail)_profile_picture.png"
                
                //Gets the download url for a image of given path
                StorageManager.shared.downloadURL(for: path) { [weak self] result in
                    switch result {
                        
                    case .success(let url):
                        self?.senderPhotoURL = url
                        DispatchQueue.main.async {
                            avatarView.sd_setImage(with: url)
                        }
                    case .failure(let error):
                        print(error)
                    }
                }
            }
        }
        //If message does not come from user
        else {
            //If we already have the url in the variable we just need to set it to the avatar view
            if let otherUserURL = self.senderPhotoURL {
                avatarView.sd_setImage(with: otherUserURL)
                //If the url variable is nil then we have to fetch it and then set it
            } else {
                
                let otherUserEmail = Self.otherUserEmail
                let path = "images/\(otherUserEmail)_profile_picture.png"
                
                //Gets the download url for a image of given path
                StorageManager.shared.downloadURL(for: path) { [weak self] result in
                    switch result {
                        
                    case .success(let url):
                        self?.otherPhotoURL = url
                        DispatchQueue.main.async {
                            avatarView.sd_setImage(with: url)
                        }
                    case .failure(let error):
                        print(error)
                    }
                }
            }
        }
    }
    
}
