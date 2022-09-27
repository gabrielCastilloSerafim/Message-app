//
//  ProfileViewController.swift
//  Messenger
//
//  Created by Gabriel Castillo Serafim on 12/9/22.
//

import UIKit
import FirebaseAuth
import SDWebImage

///Displays logged in user's information and allows log out.
final class ProfileViewController: UIViewController {
    
    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var logOutButton: UIButton!
    @IBOutlet weak var firstNameLabel: UILabel!
    @IBOutlet weak var lastNameLabel: UILabel!
    
 
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Set logOut button to have rounded corners
        logOutButton.layer.cornerRadius = logOutButton.frame.height/4

        //Set the profile image view to have be a circle
        profilePicture.layer.cornerRadius = profilePicture.frame.width/2
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //Variables needed to create path for the downloadURL function to use
        let email = UserDefaults.standard.string(forKey: "userEmail")
        let safeEmail = DatabaseManager.formatedEmail(emailAddress : email!)
        let fileName = safeEmail + "_profile_picture.png"
        let path = "images/" + fileName
        
        
        //Function from the storageManager that gets the download url for the profile picture and if succeeds calls other function that downloads the image and sets it to the UIImageView
        StorageManager.shared.downloadURL(for: path) { [weak self] result in
            switch result {
                
            case .success(let url):
                //sd_setImage is a function that comes with the SDWebImage package that can replace a URLSession call to get a image from the web using the image download url
                self?.profilePicture.sd_setImage(with: url)
                
            case .failure(let error):
                print("Failed to download URL: \(error)")
                
            }
        }
        
        firstNameLabel.text = UserDefaults.standard.string(forKey: "firstName")
        lastNameLabel.text = UserDefaults.standard.string(forKey: "lastName")
    }
    
    @IBAction func logOutButtonPressed(_ sender: UIButton) {
        do {
            try Auth.auth().signOut()
            tabBarController?.selectedIndex = 0
            //Set cached data to nil
            UserDefaults.standard.set(nil, forKey: "userName")
            UserDefaults.standard.set(nil, forKey: "userEmail")
            UserDefaults.standard.set(nil, forKey: "firstName")
            UserDefaults.standard.set(nil, forKey: "lastName")
            ConversationsViewController().conversations = []
        } catch let signOutError as NSError {
          print("Error signing out: %@", signOutError)
        }
    }
    
}
