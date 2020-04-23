//
//  CommentVC.swift
//  news
//
//  Created by Eliot Gravett on 2019/5/24.
//  Copyright © 2019 Barq. All rights reserved.
//

import UIKit
import RSKGrowingTextView
import DZNEmptyDataSet
import SwiftyAttributes
import SwiftValidators

class CommentVC: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var textView: RSKGrowingTextView!

    var news: News!
    var comments: [Comment] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "ic_refresh"), style: .plain, target: self, action: #selector(loadData))

        textView.placeholder = NSString(string: "Comment...".localized)

        setup(tableView, cellClass: [CommentHeader.self, CommentCell.self], pullToRefresh: false, separator: true)
        tableView.separatorInset = UIEdgeInsets.zero
        tableView.backgroundColor = .white

        loadData()
    }

    @objc func loadData() {
        get(url: "/comments/newsId/\(news.id)") { [unowned self] res in
            self.comments = res.arrayValue.map(Comment.init)
            self.tableView.reloadData()
        }
    }

    @IBAction func onSendAction(_ sender: Any) {
        textView.resignFirstResponder()

        if Validator.isEmpty().apply(textView.text) {
            fail("comment empty", for: textView)
        } else {
            let params: [String: Any] = [
                "newsId": news.id,
                "newsTitle": news.title ?? "",
                "sourceId": news.source.id,
                "comment": textView.text!,
            ]

            post(url: "/comments", params: params) { [unowned self] res in
                self.textView.text = ""
                self.textView.resignFirstResponder()
                self.comments.append(Comment(json: res))
                self.tableView.reloadData()
                self.tableView.scrollToRow(at: IndexPath(row: 0, section: 2), at: .bottom, animated: true)

                NotificationCenter.default.post(
                    name: .commentChanged,
                    object: nil,
                    userInfo: ["newsId": self.news.id, "commentCount": self.comments.count]
                )
            }
        }
    }

}

// MARK: - Tableview
extension CommentVC: UITableViewDelegate, UITableViewDataSource, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return comments.count > 0 ? 3 : 0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 1 ? comments.count : 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: CommentHeader.identifier, for: indexPath) as? CommentHeader else {
                fatalError()
            }

            cell.iconImageView.sd_setImage(with: URL(string: news.source.imageUrl ?? ""), placeholderImage: #imageLiteral(resourceName: "tab_bg.png"))
            cell.sourceNameLabel.text = news.source.name
            cell.timestampLabel.text = news.time.diffString
            cell.newsTitleLabel.text = news.title

            return cell

        case 1:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: CommentCell.identifier, for: indexPath) as? CommentCell else {
                fatalError()
            }

            let i = indexPath.row
            let userId = Defaults.userId.value
            let comment = comments[i]

            cell.userImageView.sd_setImage(with: URL(string: comment.userPhoto ?? ""), placeholderImage: #imageLiteral(resourceName: "ic_profile"))
            cell.userNameLabel.text = comment.userName
            cell.timeLabel.text = comment.issuedAt.diffString
            cell.commentLabel.text = comment.comment
            cell.flagged = comment.flagged.contains(userId)
            cell.flagLabel.text = comment.flagged.count.description
            cell.liked = comment.liked.contains(userId)
            cell.likeLabel.text = comment.liked.count.description
            cell.disliked = comment.disliked.contains(userId)
            cell.dislikeLabel.text = comment.disliked.count.description

            let likeUrl = "/vote_comment/id/\(comment.id)/type/liked/checked/"
            let dislikeUrl = "/vote_comment/id/\(comment.id)/type/disliked/checked/"
            let flagUrl = "/vote_comment/id/\(comment.id)/type/flagged/checked/"

            cell.tappedLike = { [unowned self] in
                if comment.userId == userId {
                    self.fail("You cannot do this action at your comment")
                    return
                }

                let liked = self.comments[i].liked.contains(userId)
                let disliked = self.comments[i].disliked.contains(userId)

                var url = ""
                if liked { url = likeUrl + "0" }
                else if disliked { url = dislikeUrl + "0" }
                else { url = likeUrl + "1" }

                self.get(url: url, indicator: false) { res in
                    self.comments[i] = Comment(json: res)
                    cell.liked = self.comments[i].liked.contains(userId)
                    cell.likeLabel.text = self.comments[i].liked.count.description
                    cell.disliked = self.comments[i].disliked.contains(userId)
                    cell.dislikeLabel.text = self.comments[i].disliked.count.description
                }
            }

            cell.tappedDislike = { [unowned self] in
                if comment.userId == userId {
                    self.fail("You cannot do this action at your comment")
                    return
                }

                let liked = self.comments[i].liked.contains(userId)
                let disliked = self.comments[i].disliked.contains(userId)

                var url = ""
                if disliked { url = dislikeUrl + "0" }
                else if liked { url = likeUrl + "0" }
                else { url = dislikeUrl + "1" }

                self.get(url: url, indicator: false) { res in
                    self.comments[i] = Comment(json: res)
                    cell.liked = self.comments[i].liked.contains(userId)
                    cell.likeLabel.text = self.comments[i].liked.count.description
                    cell.disliked = self.comments[i].disliked.contains(userId)
                    cell.dislikeLabel.text = self.comments[i].disliked.count.description
                }
            }

            cell.tappedFlagged = { [unowned self] in
                if comment.userId == userId {
                    self.fail("You cannot do this action at your comment")
                    return
                }

                let flagged = self.comments[i].flagged.contains(userId)

                let url = flagUrl + (flagged ? "0" : "1")

                self.get(url: url, indicator: false) { res in
                    self.comments[i] = Comment(json: res)
                    cell.flagged = self.comments[i].flagged.contains(userId)
                    cell.flagLabel.text = self.comments[i].flagged.count.description
                }
            }

            return cell

        default:
            return tableView.dequeueReusableCell(withIdentifier: "CommentFooter", for: indexPath)
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func customView(forEmptyDataSet scrollView: UIScrollView!) -> UIView! {
        let view: EmptyView = .loadFromNib()
        view.imageView.image = #imageLiteral(resourceName: "empty_comment")
        view.titleLabel.text = "Be the first who comment on this news".localized
        view.messageLabel.isHidden = true
        view.button.isHidden = true
        return view
    }
}
