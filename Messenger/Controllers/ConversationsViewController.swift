//
//  ViewController.swift
//  Messenger
//
//  Created by Gabriel Castillo Serafim on 12/9/22.
//

import UIKit
import FirebaseAuth
import JGProgressHUD
import SDWebImage

///Controller that shows list of conversations.
final class ConversationsViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noConversationsLabel: UILabel!
    
    public var conversations: [Conversation] = []
    static var newConversationId = ""
    
    //Instance of spinner imported from the JGProgressHUD pod
    private let spinner = JGProgressHUD(style: .dark)
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //Unhides tab bar
        self.tabBarController?.tabBar.isHidden = false
        //Unhides "No conversations" label
        if conversations.isEmpty == true {
            noConversationsLabel.isHidden = false
        }
        
        tableView.reloadData()
        
        validateAuth()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "ConversationTableViewCell" , bundle: nil), forCellReuseIdentifier: "ConversationsCell")
        
        validateAuth()
        //startListeningForConversations()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //Unhides tab bar
        self.tabBarController?.tabBar.isHidden = false
        
        //validateAuth()
        startListeningForConversations()
    }
    
    //Validates if user is already logged in and if it's false performs segue to login page
    private func validateAuth() {
        if FirebaseAuth.Auth.auth().currentUser == nil {
            performSegue(withIdentifier: "conversationToLogin", sender: self)
        }
    }
    
    //Gets called on view did appear and updates the view whenever a new conversation is added
    private func startListeningForConversations() {
        let userEmail = UserDefaults.standard.string(forKey: "userEmail")
        let formattedEmail = DatabaseManager.formatedEmail(emailAddress: userEmail!)
        //Gets all conversations for the user's email
        DatabaseManager.shared.getAllConversations(for: formattedEmail) { [weak self] results in
            switch results {
            case .success(let conversations):
                guard conversations.isEmpty == false else {
                    return
                }
                //Sets the conversations array to be equal to the conversations array that we get back from the function if its not empty
                self?.conversations = conversations
                //Reloads the table view to display updated array
                DispatchQueue.main.async {
                    //Hides "No conversations label"
                    self?.noConversationsLabel.isHidden = true
                    
                    self?.tableView.reloadData()
                }
            case .failure(let error):
                print("FAILED TO GET CONVERSATIONS\(error)")
            }
        }
    }
    
    @IBAction func composeButtonTapped(_ sender: UIBarButtonItem) {
        //Presents new screen modally
        performSegue(withIdentifier: "conversationToNewConversation", sender: self)
        
        //Call the completion property and when a row is selected in the new conversation view controller the completion gets a value assigned to it and then calls the createNewConversation function with the result value
        NewConversationViewController.completion = { [weak self] result in
            self?.createNewConversation(result: result)
        }
    }
    
    func createNewConversation(result: [String:String]) {
        guard let name = result["name"], let email = result["email"] else {
            return
        }

        ChatViewController.otherUsersName = name
        ChatViewController.isNewConversation = true
        ChatViewController.otherUserEmail = email
        ChatViewController.conversationId = ""
 
        performSegue(withIdentifier: "conversationsToChat", sender: self)
    }
}

//MARK: -   Table view delegate and data source setup

extension ConversationsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ConversationsCell", for: indexPath) as! ConversationTableViewCell
        
        let model = conversations[indexPath.row]
        //Populate cell
        DispatchQueue.main.async {
            cell.nameLabel.text = model.name
            cell.messageLabel.text = model.latestMessage.text
            //Download and set profile picture
            let path = "images/\(model.otherUserEmail)_profile_picture.png"
            StorageManager.shared.downloadURL(for: path) { result in
                switch result {
                    
                case .success(let url):
                    cell.profilePicture.sd_setImage(with: url)
                    
                case .failure(let error):
                    print("FAILED TO GET IMAGE URL\(error)")
                }
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let model = conversations[indexPath.row]
        
        ChatViewController.otherUsersName = model.name
        ChatViewController.otherUserEmail = model.otherUserEmail
        ChatViewController.isNewConversation = false
        ChatViewController.conversationId = model.id
        
        performSegue(withIdentifier: "conversationsToChat", sender: self)
    }
    //Specify what options we want to present when swipe on cell
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    //Set an action to the delete option we created above
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            //Begin delete
            tableView.beginUpdates()
            //Get the conversation id to use it to delete conversation on database
            let conversationId = conversations[indexPath.row].id
            //Delete conversation from users database
            DatabaseManager.shared.deleteConversation(conversationId: conversationId) { [weak self] success in
                //If succeeds to delete from database procede to delete localy
                if success == true {
                    //Remove conversation from conversations array
                    self?.conversations.remove(at: indexPath.row)
                    //Remove row from table view
                    tableView.deleteRows(at: [indexPath], with: .left)
                }
            }
            //If conversations array is empty unhide noConversations label
            if conversations.isEmpty == true {
                noConversationsLabel.isHidden = false
            }
            //End delete
            tableView.endUpdates()
        }
    }
    
}
