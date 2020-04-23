//
//  RegisterVC.swift
//  news
//
//  Created by Eliot Gravett on 2019/5/23.
//  Copyright © 2019 Barq. All rights reserved.
//

import FBSDKLoginKit
import GoogleSignIn
import SwiftValidators
import SwiftyJSON
import TwitterKit
import UIKit

class RegisterVC: UIViewController {
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var emailText: UITextField!
    @IBOutlet weak var passwordText: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func onSignUpAction(_ sender: Any) {
        nameText.resignFirstResponder()
        emailText.resignFirstResponder()
        passwordText.resignFirstResponder()

        if Validator.isEmpty().apply(nameText.text) {
            fail("name empty", for: nameText)
        } else if !Validator.isEmail().apply(emailText.text) {
            fail("email invalid", for: emailText)
        } else if Validator.isEmpty().apply(passwordText.text) {
            fail("password empty", for: passwordText)
        } else {
            var params: [String: Any] = [
                "username": nameText.text!,
                "email": emailText.text!,
                "password": passwordText.text!,
            ]
            if !Defaults.sources.value.isEmpty {
                params["source_ids"] = Defaults.sources.value.map(String.init).joined(separator: "_")

                let notify = Defaults.notifications.value
                let block = Defaults.sources.value.filter { !notify.contains($0) }
                if !block.isEmpty {
                    params["block_ids"] = block.map(String.init).joined(separator: "_")
                }
            }
            if !Defaults.favorites.value.isEmpty {
                params["favorite_ids"] = Defaults.favorites.value.map(String.init).joined(separator: "_")
            }
            post(url: "/signup", params: params) { [unowned self] res in
                Defaults.apiToken.value = res["token"].string
                Defaults.userId.value = res["id"].intValue
                Defaults.userName.value = res["name"].string
                Defaults.email.value = res["email"].string
                Defaults.photo.value = res["photo_url"].string

                self.performSegue(withIdentifier: "unwind2Setting", sender: nil)
            }
        }
    }

    fileprivate func register(name: String, email: String, photo: String, type: String) {
        var params: [String: Any] = [
            "name": name,
            "email": email,
            "photo": photo,
            "type": type,
        ]
        if !Defaults.sources.value.isEmpty {
            params["source_ids"] = Defaults.sources.value.map(String.init).joined(separator: "_")

            let notify = Defaults.notifications.value
            let block = Defaults.sources.value.filter { !notify.contains($0) }
            if !block.isEmpty {
                params["block_ids"] = block.map(String.init).joined(separator: "_")
            }
        }
        if !Defaults.favorites.value.isEmpty {
            params["favorite_ids"] = Defaults.favorites.value.map(String.init).joined(separator: "_")
        }
        post(url: "/social_signup", params: params) { [unowned self] res in
            Defaults.apiToken.value = res["token"].string
            Defaults.userId.value = res["id"].intValue
            Defaults.userName.value = res["name"].string
            Defaults.email.value = res["email"].string
            Defaults.photo.value = res["photo_url"].string

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
        let request = GraphRequest(graphPath: "me", parameters: ["fields": "email,name,picture"], httpMethod: .get)
        let connection = GraphRequestConnection()
        connection.add(request) { [unowned self] _, result, error in
            if let error = error {
                print("Graph Request Failed: \(error)")
            } else {
                let json = JSON(result as! NSDictionary)
                let name = json["name"].stringValue
                let email = json["email"].stringValue
                let photo = json["picture", "data", "url"].stringValue
                self.register(name: name, email: email, photo: photo, type: "facebook")
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
                TWTRTwitter.sharedInstance().sessionStore.logOutUserID(userId)
            } else {
                self.requestTwitterUserPhoto(userId: userId, email: email!)
            }
        }
    }

    func requestTwitterUserPhoto(userId: String, email: String) {
        TWTRAPIClient.withCurrentUser().loadUser(withID: userId) { user, error in
            if let error = error {
                print("Twitter fetch user photo failed: \(error)")
            } else {
                self.register(name: user!.name, email: email, photo: user!.profileImageURL, type: "twitter")
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

extension RegisterVC: GIDSignInDelegate, GIDSignInUIDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let error = error {
            print("Google signin failed: \(error)")
        } else {
            let name = user!.profile!.name!
            let email = user!.profile!.email!
            let photo = user!.profile!.imageURL(withDimension: 75)!.absoluteString
            register(name: name, email: email, photo: photo, type: "google")
        }
        GIDSignIn.sharedInstance().signOut()
    }

    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        print("User disconnected google signin")
    }
}
