//
//  RegisterViewController.swift
//  Messenger
//
//  Created by Gabriel Castillo Serafim on 12/9/22.
//

import UIKit
import FirebaseAuth
import JGProgressHUD

///Controller that handles registering new user.
final class RegisterViewController: UIViewController {
    
    //Instance of spinner imported from the JGProgressHUD pod
    private let spinner = JGProgressHUD(style: .dark)
    
    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var firstNameLabel: UITextField!
    @IBOutlet weak var lastNameLabel: UITextField!
    @IBOutlet weak var emailLabel: UITextField!
    @IBOutlet weak var passwordLabel: UITextField!
    @IBOutlet weak var registerButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Round register/profile picture button corner
        registerButton.layer.cornerRadius = registerButton.frame.height/4
        
        //Delegates
        firstNameLabel.delegate = self
        lastNameLabel.delegate = self
        emailLabel.delegate = self
        passwordLabel.delegate = self
        
        //Setup profile picture frame to be rounded and have a border
        profilePicture.layer.masksToBounds = true
        profilePicture.layer.cornerRadius = profilePicture.frame.height/2
        profilePicture.layer.borderWidth = 2
        profilePicture.layer.borderColor = UIColor.lightGray.cgColor
        
        //Setup text field border and add right icon using extension from "UITextfieldExtensions" under "extensions" folder
        firstNameLabel.layer.borderWidth = 1
        firstNameLabel.layer.borderColor = UIColor.lightGray.cgColor
        firstNameLabel.setupRightSideImage(sistemImageNamed: "person.text.rectangle")
        
        lastNameLabel.layer.borderWidth = 1
        lastNameLabel.layer.borderColor = UIColor.lightGray.cgColor
        lastNameLabel.setupRightSideImage(sistemImageNamed: "person.text.rectangle")
        
        emailLabel.layer.borderWidth = 1
        emailLabel.layer.borderColor = UIColor.lightGray.cgColor
        emailLabel.setupRightSideImage(sistemImageNamed: "envelope")
        
        passwordLabel.layer.borderWidth = 1
        passwordLabel.layer.borderColor = UIColor.lightGray.cgColor
        passwordLabel.setupRightSideImage(sistemImageNamed: "lock.rectangle")
        
        //Declared in "SlideViewWhithKeyboard" under "extensions" to manage keyboard obstructing textField and adding touch outside to dismiss.
        setupKeyboardHiding()
        hideKeyboardWhenTappedAround()
    }
    
    //MARK: - Keyboard obstructing textFields management
    
    private func setupKeyboardHiding() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc func keyboardWillShow(sender: NSNotification) {

        guard let userInfo = sender.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
              let currentTextField = UIResponder.currentFirst() as? UITextField
        else { return }

        // check if the top of the keyboard is above the bottom of the currently focused textBox ...
        let keyboardTopY = keyboardFrame.cgRectValue.origin.y
        let convertedTextFieldFrame = view.convert(currentTextField.frame, from: currentTextField.superview)
        let textFieldBottomY = convertedTextFieldFrame.origin.y + convertedTextFieldFrame.size.height

        // if textField bottom is below keyboard bottom - bump the frame up
        if textFieldBottomY > keyboardTopY {
            let textFieldHeight:Double = 70
            let textBoxY = convertedTextFieldFrame.origin.y
            let newFrameY = (textBoxY - keyboardTopY + textFieldHeight) * -1
            view.frame.origin.y = newFrameY
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        view.frame.origin.y = 0
    }
    
    
    //MARK: - UIButtons functionality
    
    
    @IBAction func changeProfilePictureTapped(_ sender: UIButton) {
        //Invokes the function to present our action sheet
        presentPhotoActionSheet()
    }
    
    
    @IBAction func registerButtonPressed(_ sender: UIButton) {
        
        if let email = self.emailLabel.text, let password = self.passwordLabel.text, let firstName = firstNameLabel.text, let lastName = lastNameLabel.text {
            //Show spinner while networking is being done
            self.spinner.show(in: self.view)
            
            //Creates user and logs in with the created user
            Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                
                if let err = error {
                    //Cals function from extension "HandleFirebaseErrors" under "extensions" folder to properly present error for user.
                    self.handleFireAuthError(error: err)
                    
                    print(err.localizedDescription)
                    return
                } else {
                    //Saves user email to cache memory
                    UserDefaults.standard.set(email, forKey: "userEmail")
                    //Saves user full name to cache memory
                    UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "userName")
                    //Saves user first name to cache memory
                    UserDefaults.standard.set("\(firstName)", forKey: "firstName")
                    //Saves user last name to cache memory
                    UserDefaults.standard.set("\(lastName)", forKey: "lastName")
                    //Create chatUser object
                    let chatUser = ChatAppUser(firstName: self.firstNameLabel.text!, lastName: self.lastNameLabel.text!, emailAddress: self.emailLabel.text!)
                    //Adds the chatUser to database using function from databaseManager class
                    DatabaseManager.shared.insertUser(with: chatUser)
                    
                    //Create variables needed to use as parameters on the function that is going to upload the profile picture
                    let image = self.profilePicture.image
                    let imageData = image?.pngData()
                    let filename = chatUser.profilePictureFileName
                    //Function from storageManager that is going to upload the image and safe the download url to cache memory
                    StorageManager.shared.uploadProfilePicture(with: imageData!, fileName: filename)
                    
                    //Dismiss spinner and go back to chats view controller
                    DispatchQueue.main.async {
                        self.spinner.dismiss(animated: true)
                        self.navigationController?.popToRootViewController(animated: false)
                    }
                }
            }
        }
    }
}

//MARK: - Image Picker for profile picture

extension RegisterViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    //Creates an action sheet with actions to see if user whats to use camera or choose photo from the library
    func presentPhotoActionSheet() {
        let actionSheet = UIAlertController(title: "Profile picture",
                                            message: "How would you like to select a picture?",
                                            preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Cancel",
                                            style: .default,
                                            handler: nil))
        
        actionSheet.addAction(UIAlertAction(title: "Take Photo",
                                            style: .default,
                                            handler: { [weak self] _ in
            self?.presentCamera()
            
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Choose Photo",
                                            style: .default,
                                            handler: { [weak self] _ in
            self?.presentPhotoPicker()
        }))
        
        present(actionSheet, animated: true)
    }
    
    //Function called in action sheet to present camera
    func presentCamera () {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true)
    }
    //Function called in the action sheet to present photo picker
    func presentPhotoPicker () {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        //allowEditing lets us have that crop delimitation to the pictures
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true)
    }
    //Conforms to image picker controller protocol and tells what to do when finish picking media (dismiss and set the image view content to be equal to the edited chosen image)
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        let selectedImage = info[UIImagePickerController.InfoKey.editedImage]
        self.profilePicture.image = (selectedImage as! UIImage)
    }
    //Conforms to image picker controller protocol and dismisses when cancel is tapped
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
}

//MARK: - UITextFieldDelegate

extension RegisterViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        //Use switch function below to send user to next textField when return button is tapped.
        self.switchBasedNextTextField(textField)
        
        return true
    }
    
    private func switchBasedNextTextField(_ textField: UITextField) {
        switch textField {
        case self.firstNameLabel:
            self.lastNameLabel.becomeFirstResponder()
        case self.lastNameLabel:
            self.emailLabel.becomeFirstResponder()
        case self.emailLabel:
            self.passwordLabel.becomeFirstResponder()
        default:
            self.passwordLabel.resignFirstResponder()
        }
    }
}
