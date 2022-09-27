//
//  NewConversationViewController.swift
//  Messenger
//
//  Created by Gabriel Castillo Serafim on 12/9/22.
//

import UIKit
import JGProgressHUD

///Controller that allows users to search for other users and start a new conversation with them.
final class NewConversationViewController: UIViewController {
    
    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noResultsLabel: UILabel!
    
    //Array that will contain all the users registered
    private var users: [[String: String]] = []
    
    //Results that will appear on table view
    private var results: [[String: String]] = []
    
    //Keeps track if a fetch has already been performed
    private var hasFetched = false
    
    //Closure to pass new conversation data to conversation view controller
    static var completion: (([String:String]) -> (Void))?
    
    private let spinner = JGProgressHUD(style: .dark)
    
    //Closure that returns the search bar object with its configurations.
    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search for User"
        searchBar.backgroundColor = .white
        
        return searchBar
    }()
    
    override func viewDidLoad() {
        
        //By making the search bar first responder we make the keyboard pop automatically when the view appears
        searchBar.becomeFirstResponder()
        
        searchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        //Set the search bar to be the top item inside of the navBar
        navBar.topItem?.titleView = searchBar
        
    }
    
    @IBAction func cancelPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
}

//MARK: - SearchBar Setup

extension NewConversationViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        //Dismiss keyboard when search is clicked
        searchBar.resignFirstResponder()
        
        if let text = searchBar.text {
            
            if text != "" {
                //Empties the results array
                results = []
                
                spinner.show(in: view)
                //Call function to perform query with text inputed
                self.searchUsers(query: text)
            }
        } else {
            //Warning to ask user to type a user name
        }
    }
    
    //Search for users and updates array of users if needed
    func searchUsers(query: String) {
        //Check if array has firebase results
        if hasFetched == true {
            //call filter function
            filterUsers(with: query)
            
        } else {
            //Calls function from the database manager to fetch all users from firebase and add them to users array
            DatabaseManager.shared.getAllUsers { [weak self] result in
                switch result {
                case .success(let usersCollection):
                    //Updates the users array
                    self?.users = usersCollection
                    //Call filter users function
                    self?.filterUsers(with: query)
                    //Set has fetched value to true
                    self?.hasFetched = true
                    
                case.failure(let error):
                    print("Failed to get users \(error)")
                }
            }
        }
    }
    
    //Filter users from users array using the term provided on search field
    func filterUsers (with term: String) {
        
        let userEmail = UserDefaults.standard.string(forKey: "userEmail")!
        
        self.spinner.dismiss(animated: true)
        //results internal variable created to be assigned to filtered results
        var results: [[String:String]] = []
        //Filters results from users array
        results = self.users.filter {
            //Check if email is different from users email to prevent user from finding himself as user
            guard let email = $0["email"], email != userEmail else {
                return false
            }
            //Inside the filter closure we check starting from the first item on the users array of dictionaries if the prefix of the string for the key "name" matches the term passed on the function's parameter the item will be added to the results array
            if let name = $0["name"]?.lowercased() {
                return name.hasPrefix(term.lowercased())
            } else {
                return false
            }
            
            //return name.hasPrefix(term.lowercased())
        }
        //Assigns the results from the local array "results" to the global array "results"
        self.results = results
        //Call function to update UI
        updateUI()
    }
    
    private func updateUI() {
        if results.isEmpty {
            self.tableView.isHidden = true
            self.noResultsLabel.isHidden = false
        } else {
            self.tableView.isHidden = false
            self.noResultsLabel.isHidden = true
            self.tableView.reloadData()
        }
    }
    
}



//MARK: - TableView Delegate And Datasource Setup

extension NewConversationViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = results[indexPath.row]["name"]
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        //Assign the data for the selected user in table view to the variable "targetUserData"
        let targetUserData = results[indexPath.row]
        //Set chat VC isNewConversation property to true
        ChatViewController.isNewConversation = true
        //Dismiss view and assign the target user to the closure property that we created wich will trigger the closure property called on the conversation view controller
        dismiss(animated: true) {
            Self.completion?(targetUserData)
        }
    }
    
    
}


