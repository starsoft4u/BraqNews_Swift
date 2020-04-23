//
//  LoginVC.swift
//  news
//
//  Created by Eliot Gravett on 2019/5/23.
//  Copyright © 2019 Barq. All rights reserved.
//

import FBSDKCoreKit
import FBSDKLoginKit
import GoogleSignIn
import SwiftValidators
import SwiftyAttributes
import SwiftyJSON
import TwitterKit
import UIKit

class LoginVC: UIViewController {
    @IBOutlet var emailText: UITextField!
    @IBOutlet var passwordText: UITextField!
    @IBOutlet var forgotButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        forgotButton.titleLabel?.attributedText = "Forgot your password?"
            .localized
            .withUnderlineStyle(.single)
            .withTextColor(UIColor(rgb: 0xB61F2A))
    }

    @IBAction func onLoginAction(_ sender: Any) {
        emailText.resignFirstResponder()
        passwordText.resignFirstResponder()

        if !Validator.isEmail().apply(emailText.text) {
            fail("name empty", for: emailText)
        } else if Validator.isEmpty().apply(passwordText.text) {
            fail("password empty", for: passwordText)
        } else {
            let params: [String: Any] = [
                "email": emailText.text!,
                "password": passwordText.text!,
            ]
            post(url: "/login", params: params) { [unowned self] res in
                Defaults.apiToken.value = res["token"].string
                Defaults.userId.value = res["id"].intValue
                Defaults.userName.value = res["name"].string
                Defaults.email.value = res["email"].string
                Defaults.photo.value = res["photo_url"].string
                Defaults.sources.value = res["source"].arrayValue.map { $0.intValue }
                let block = res["blockNotification"].arrayValue.map { $0.intValue }
                Defaults.notifications.value = Defaults.sources.value.filter { !block.contains($0) }
                Defaults.favorites.value = Defaults.favorites.defaultValue

                if Defaults.notifyGlobal.value {
                    Defaults.notifications.value.forEach {
                        subscribeNotification(topic: $0.description, subscribe: true)
                    }
                }

                self.performSegue(withIdentifier: "unwind2Setting", sender: nil)
            }
        }
    }

    fileprivate func login(email: String, type: String) {
        let params: [String: Any] = [
            "email": email,
            "type": type,
        ]
        post(url: "/social_login", params: params) { [unowned self] res in
            Defaults.apiToken.value = res["token"].string
            Defaults.userId.value = res["id"].intValue
            Defaults.userName.value = res["name"].string
            Defaults.email.value = res["email"].string
            Defaults.photo.value = res["photo_url"].string
            Defaults.sources.value = res["source"].arrayValue.map { $0.intValue }
            let block = res["blockNotification"].arrayValue.map { $0.intValue }
            Defaults.notifications.value = Defaults.sources.value.filter { !block.contains($0) }
            Defaults.favorites.value = Defaults.favorites.defaultValue

            if Defaults.notifyGlobal.value {
                Defaults.notifications.value.forEach {
                    subscribeNotification(topic: $0.description, subscribe: true)
                }
            }

            self.performSegue(withIdentifier: "unwind2Setting", sender: nil)
        }
    }

    @IBAction func onFacebookAction(_ sender: Any) {
        if let accessToken = AccessToken.current {
            requestFacebookProfile(accessToken)
        } else {
            LoginManager().logIn(permissions: ["public_profile", "email"], from: self) { [unowned self] result, error in
                if let error = error {
                    print("Facebook login failed: \(error)")
                } else {
                    self.requestFacebookProfile(result!.token!)
                }
            }
        }
    }

    fileprivate func requestFacebookProfile(_ token: AccessToken) {
        let request = GraphRequest(graphPath: "me", parameters: ["fields": "email"], httpMethod: .get)
        let connection = GraphRequestConnection()
        connection.add(request) { [unowned self] _, result, error in
            if let error = error {
                print("Graph Request Failed: \(error)")
            } else {
                let json = JSON(result as! NSDictionary)
                self.login(email: json["email"].stringValue, type: "facebook")
            }
            LoginManager().logOut()
        }
        connection.start()
    }

    @IBAction func onTwitterAction(_ sender: Any) {
        if let session = TWTRTwitter.sharedInstance().sessionStore.session() {
            requestTwitterEmail(userId: session.userID)
        } else {
            TWTRTwitter.sharedInstance().logIn { [unowned self] session, error in
                if let error = error {
                    print("Twitter login failed: \(error)")
                } else {
                    self.requestTwitterEmail(userId: session!.userID)
                }
            }
        }
    }

    fileprivate func requestTwitterEmail(userId: String) {
        TWTRAPIClient(userID: userId).requestEmail { [unowned self] email, error in
            if let error = error {
                print("Twitter request email failed: \(error)")
                let nsError = error as NSError
                if nsError.code == 3 {
                    self.fail(error.localizedDescription)
                }
            } else {
                self.login(email: email!, type: "twitter")
            }

            TWTRTwitter.sharedInstance().sessionStore.logOutUserID(userId)
        }
    }

    @IBAction func onGoogleAction(_ sender: Any) {
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().signIn()
    }
}

extension LoginVC: GIDSignInDelegate, GIDSignInUIDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let error = error {
            print("Google signin failed: \(error)")
        } else {
            login(email: user!.profile!.email!, type: "google")
        }
        GIDSignIn.sharedInstance().signOut()
    }

    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        print("User disconnected google signin")
    }
}
