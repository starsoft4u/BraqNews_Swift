//
//  SuggestionVC.swift
//  news
//
//  Created by Eliot Gravett on 2019/5/23.
//  Copyright © 2019 Barq. All rights reserved.
//

import UIKit
import SwiftValidators

class SuggestionVC: UIViewController {
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var urlText: UITextField!

    @IBAction func onSendAction(_ sender: Any) {
        nameText.resignFirstResponder()
        urlText.resignFirstResponder()

        if Validator.isEmpty().apply(nameText.text) {
            fail("name empty", for: nameText)
        } else if !Validator.isURL().apply(urlText.text) {
            fail("url invalid", for: urlText)
        } else {
            let params: [String: Any] = [
                "name": nameText.text!,
                "url": urlText.text!,
            ]
            post(url: "/suggest", params: params) { [unowned self] res in
                self.nameText.text = ""
                self.urlText.text = ""
                self.success("Suggested successfully!")
            }
        }
    }
}
