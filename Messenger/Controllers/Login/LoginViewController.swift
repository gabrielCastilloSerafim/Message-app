//
//  LoginViewController.swift
//  Messenger
//
//  Created by Gabriel Castillo Serafim on 12/9/22.
//

import UIKit
import FirebaseAuth
import JGProgressHUD

///Controller that handles users login.
final class LoginViewController: UIViewController {
    
    //Instance of spinner imported from the JGProgressHUD pod
    private let spinner = JGProgressHUD(style: .dark)

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var registerButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //round button corners
        loginButton.layer.cornerRadius = loginButton.frame.height/4
        registerButton.layer.cornerRadius = registerButton.frame.height/4
        
        emailField.delegate = self
        passwordField.delegate = self
        
        //Changes the back button text that will appear in the next view controller
        let backBarBtnItem = UIBarButtonItem()
            backBarBtnItem.title = "Login"
            navigationItem.backBarButtonItem = backBarBtnItem
        
        //Hides tab bar controller
        self.tabBarController?.tabBar.isHidden = true
        
        //Hides back button on view
        self.navigationItem.setHidesBackButton(true, animated: true)
    }
    
    @IBAction func loginTapped(_ sender: UIButton) {
        
        if let email = emailField.text, let password = passwordField.text {
            //Show spinner while networking is being done
            spinner.show(in: view)
            //Logs user in
            Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
                //Dismiss spinner
                DispatchQueue.main.async {
                    self?.spinner.dismiss(animated: true)
                }
                if let err = error {
                    print(err.localizedDescription)
                    return
                } else {
                    
                    let formattedEmail = DatabaseManager.formatedEmail(emailAddress: email)
                    DatabaseManager.shared.getDataFor(path: formattedEmail) { result in
                        switch result {
                        case .success(let data):
                            guard let userData = data as? [String: Any], let firstName = userData["first_name"] as? String, let lastName = userData["last_name"] as? String else {
                                return
                            }
                            //Saves user full name to cache memory
                            UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "userName")
                            //Saves user first name to cache memory
                            UserDefaults.standard.set("\(firstName)", forKey: "firstName")
                            //Saves user last name to cache memory
                            UserDefaults.standard.set("\(lastName)", forKey: "lastName")
                            
                        case .failure(let error):
                            print("FAILED TO FETCH USER NAME \(error)")
                        }
                    }
                    
                    //Saves user email to cache memory
                    UserDefaults.standard.set(email, forKey: "userEmail")
                    
                    //Dismiss view
                    self?.navigationController?.popToRootViewController(animated: false)
                }
              
            }
        }
    }
    
    
}

//MARK: - Text input validation

extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.endEditing(true)
        return true
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        if textField.text != "" {
            return true
        } else {
            return false
        }
    }
}
