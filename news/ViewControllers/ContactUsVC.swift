//
//  ContactUsVC.swift
//  news
//
//  Created by Eliot Gravett on 2019/5/23.
//  Copyright © 2019 Barq. All rights reserved.
//

import UIKit
import SwiftValidators

class ContactUsVC: UIViewController {
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var emailText: UITextField!
    @IBOutlet weak var messageText: UITextView!

    @IBAction func onSendAction(sender: Any) {
        nameText.resignFirstResponder()
        emailText.resignFirstResponder()
        messageText.resignFirstResponder()

        if Validator.isEmpty().apply(nameText.text) {
            fail("name empty", for: nameText)
        } else if !Validator.isEmail().apply(emailText.text) {
            fail("email invalid", for: emailText)
        } else if Validator.isEmpty().apply(messageText.text) {
            fail("message empty", for: messageText)
        } else {
            let params: [String: Any] = [
                "name": nameText.text!,
                "email": emailText.text!,
                "message": messageText.text!,
            ]
            post(url: "/contact_us", params: params) { [unowned self] res in
                self.nameText.text = ""
                self.emailText.text = ""
                self.messageText.text = ""
                self.success("Message sent successfully!")
            }
        }
    }
}
