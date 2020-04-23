//
//  ForgotPasswordVC.swift
//  news
//
//  Created by Eliot Gravett on 2019/5/23.
//  Copyright © 2019 Barq. All rights reserved.
//

import UIKit
import SwiftValidators

class ForgotPasswordVC: UIViewController {
    @IBOutlet weak var emailText: UITextField!

    @IBAction func onSubmitAction(_ sender: Any) {
        emailText.resignFirstResponder()

        if !Validator.isEmail().apply(emailText.text!) {
            fail("email invalid", for: emailText)
        } else {
            post(url: "/forgot_password", params: ["email": emailText.text!]) { [unowned self] res in
                self.emailText.text = ""
                self.success("Reset password email sent successfully!")
            }
        }
    }

}
