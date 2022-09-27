//
//  DataManager.swift
//  Messenger
//
//  Created by Gabriel Castillo Serafim on 14/9/22.
//

import Foundation
import FirebaseStorage

///Allows you to get, fetch, and upload files to firebase storage.
final class StorageManager {
    
    //Create a accessible instance of this class to be able to access it globally
    static let shared = StorageManager()
    
    //Create a reference to our storage
    private let storage = Storage.storage().reference()
    
    ///Uploads profile picture to firebase storage and saves to memory the url string to download it
    public func uploadProfilePicture(with imageData: Data, fileName: String) {
        
        storage.child("images/\(fileName)").putData(imageData) { [weak self] metadata, error in
            if let err = error {
                print(err.localizedDescription)
                return
            } else {
                self?.storage.child("images/\(fileName)").downloadURL { url, error in
                    if let err = error {
                        print(err.localizedDescription)
                        return
                    } else {
                        let downloadUrl = url?.absoluteString
                        //Save the urlString to cache memory
                        UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")
                    }
                }
            }
        }
    }
    
    ///Downloads profile image url
    public func downloadURL(for path: String, completion: @escaping (Result<URL, Error>) -> Void) {
        //This is the reference for the image on the database
        let reference = storage.child(path)
        
        reference.downloadURL { url, error in
            guard let url = url, error == nil else {
                completion(.failure(error!))
                return
            }
                completion(.success(url))
        }
    }
}
