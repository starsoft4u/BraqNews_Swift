//
//  ReportBugVC.swift
//  news
//
//  Created by Eliot Gravett on 7/13/19.
//  Copyright © 2019 Barq. All rights reserved.
//

import SwiftValidators
import UIKit

class ReportBugVC: UIViewController {
    @IBOutlet var deviceText: UITextField!
    @IBOutlet var messageText: UITextField!
    @IBOutlet var detailsText: UITextView!

    @IBAction func onSendAction(_ sender: Any) {
        deviceText.resignFirstResponder()
        messageText.resignFirstResponder()
        detailsText.resignFirstResponder()

        if Validator.isEmpty().apply(deviceText.text) {
            fail("device empty", for: deviceText)
        } else if Validator.isEmpty().apply(messageText.text) {
            fail("message empty", for: messageText)
        } else if Validator.isEmpty().apply(detailsText.text) {
            fail("details empty", for: detailsText)
        } else {
            let params: [String: Any] = [
                "device": deviceText.text!,
                "message": messageText.text!,
                "details": detailsText.text!,
            ]
            post(url: "/report", params: params) { [unowned self] _ in
                self.deviceText.text = ""
                self.messageText.text = ""
                self.detailsText.text = ""
                self.success("Message sent successfully!")
            }
        }
    }
}
