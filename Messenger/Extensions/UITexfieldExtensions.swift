//
//  UITexfieldExtensions.swift
//  Messenger
//
//  Created by Gabriel Castillo Serafim on 28/9/22.
//

import UIKit

extension UITextField {
    
    func setupRightSideImage(sistemImageNamed: String) {
        let imageView = UIImageView(frame: CGRect(x: -2, y:10, width: 30, height: 20))
        imageView.image = UIImage(systemName: sistemImageNamed)
        let imageViewContainerView = UIView(frame: CGRect(x:0 ,y:0, width: 40, height: 40))
        imageViewContainerView.addSubview(imageView)
        rightView = imageViewContainerView
        rightViewMode = .always
        self.tintColor = .lightGray
    }
    
    
}
