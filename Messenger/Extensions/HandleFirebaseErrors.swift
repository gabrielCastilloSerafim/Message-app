//
//  HandleFirebaseErrors.swift
//  Messenger
//
//  Created by Gabriel Castillo Serafim on 28/9/22.
//

import UIKit
import FirebaseAuth

//Can be called from every VC to handle firebase errors
extension UIViewController {

    //Get the error code from error in login/register VC and calls the errorMessage computed property on it if the switch case matches one of the messages that we customised we show that on alert otherwise we show the localised description on alert.
    func handleFireAuthError(error: Error) {

        if let errorCode = AuthErrorCode.Code(rawValue: error._code) {
            
            if let errorMessage = errorCode.errorMessage {
                //Show custom alert "errorMessage did not return nil"
                let alert = UIAlertController(title: "Error", message: errorMessage, preferredStyle: .alert)
                let okAction = UIAlertAction(title: "Ok", style: .default)
                alert.addAction(okAction)
                present(alert, animated: true)
                        
            } else {
                //Show localised description "errorMessage returned nil"
                let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "Ok", style: .default)
                    alert.addAction(okAction)
                    present(alert, animated: true)
            }
        }
    }
}

extension AuthErrorCode.Code {
    //Computed property
    var errorMessage: String? {
        //We are switching on the original enum that contains all the errors from firebase and changing the return for the ones that we want.
        switch self {
        case .emailAlreadyInUse:
            return "The email is already in use with another account."
        case .invalidEmail:
            return "Please enter a valid Email."
        case .networkError:
            return "Network error. Please try again."
        case .wrongPassword:
            return "Password is not correct, please try again."
        case .weakPassword:
            return "Your password is too weak. The password must be 6 characters long or more."
            
        default:
            return nil
        }
    }
}
