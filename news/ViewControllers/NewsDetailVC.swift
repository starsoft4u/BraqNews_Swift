//
//  NewsDetailVC.swift
//  news
//
//  Created by Eliot Gravett on 2019/5/24.
//  Copyright © 2019 Barq. All rights reserved.
//

import Cartography
import GoogleMobileAds
import NVActivityIndicatorView
import Popover
import UIKit
import WebKit

enum NewsDetailCellType: Int {
    case source = 0
    case ads
    case webview
}

class NewsDetailVC: UITableViewController {
    var newsId: String?
    var news: News?

    var webView: WKWebView!
    var webViewHeight = CGFloat(0)
    var loading: NVActivityIndicatorView!

    var adView: GADBannerView!
    let adViewHeight = CGFloat(250)

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(image: #imageLiteral(resourceName: "ic_share"), style: .plain, target: self, action: #selector(onShareAction)),
            UIBarButtonItem(image: #imageLiteral(resourceName: "ic_comment"), style: .plain, target: self, action: #selector(onCommentAction)),
            UIBarButtonItem(image: news?.favorited == true ? #imageLiteral(resourceName: "ic_star_d") : #imageLiteral(resourceName: "ic_star"), style: .plain, target: self, action: #selector(onStarAction)),
        ]

        setup(tableView, cellClass: [NewsCell.self, NewsAdsCell.self, WebViewCell.self])
        tableView.allowsSelection = false

        webViewHeight = tableView.bounds.height

        if let id = newsId {
            loadNews(id)
        } else {
            adView = makeAdView()
            webView = makeWebview()
        }
    }

    fileprivate func loadNews(_ id: String) {
        let params: [String: Any] = [
            "type": "favorite_ids",
            "id": id,
        ]
        post(url: "/fetch_news", params: params) { [unowned self] res in
            self.news = News(json: res.arrayValue.first!)
            self.adView = self.makeAdView()
            self.webView = self.makeWebview()
            self.tableView.reloadData()
        }
    }

    fileprivate func makeAdView() -> GADBannerView {
        let adSize = GADAdSizeFromCGSize(CGSize(width: tableView.contentSize.width, height: adViewHeight))
        let adView = GADBannerView(adSize: adSize)
        adView.adUnitID = Constants.adsUnitId
        adView.rootViewController = self

        let adRequest = GADRequest()
//        adRequest.testDevices = [kGADSimulatorID]
        adView.load(adRequest)

        return adView
    }

    fileprivate func makeWebview() -> WKWebView {
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.websiteDataStore = .nonPersistent()

        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: tableView.contentSize.width, height: webViewHeight), configuration: webConfiguration)
        webView.uiDelegate = self
        webView.navigationDelegate = self

        loading = NVActivityIndicatorView(frame: CGRect.zero, type: .ballSpinFadeLoader, color: .black)

        return webView
    }

    // MARK: - Navigation actions

    @objc fileprivate func onFontAction(_ sender: UIBarButtonItem) {
        guard let fromView = sender.value(forKey: "view") as? UIView else {
            return
        }

        let fontView: FontView = .loadFromNib()
        fontView.frame = CGRect(x: 0, y: 8, width: 220, height: 188)

        let popover = Popover(
            options: [
                .cornerRadius(8),
                .dismissOnBlackOverlayTap(true),
                .arrowSize(CGSize(width: 32, height: 16)),
            ]
        )
        popover.layer.shadowOpacity = 0.5
        popover.layer.shadowOffset = CGSize(width: 2, height: 2)
        popover.layer.shadowRadius = 3
        popover.layer.opacity = 1
        popover.show(fontView, fromView: fromView)
    }

    @objc fileprivate func onGlobalAction() {}

    @objc fileprivate func onStarAction() {
        if !isLoggedIn {
            if news!.favorited == true {
                Defaults.favorites.value.removeAll(where: { $0 == news!.id })
            } else {
                Defaults.favorites.value.append(news!.id)
            }
            handleResponse()
            return
        }

        let params: [String: Any] = [
            "newsId": news!.id,
            "newsTitle": news?.title ?? "",
            "sourceId": news!.source.id,
            "favorite": !news!.favorited,
        ]
        post(url: "/favorite", params: params, indicator: false) { [unowned self] _ in
            self.handleResponse()
        }
    }

    fileprivate func handleResponse() {
        let favorited = !news!.favorited

        news!.favorited = favorited
        navigationItem.rightBarButtonItems?[2] = UIBarButtonItem(
            image: favorited ? #imageLiteral(resourceName: "ic_star_d") : #imageLiteral(resourceName: "ic_star"),
            style: .plain,
            target: self,
            action: #selector(onStarAction)
        )
        NotificationCenter.default.post(
            name: .favoriteChanged,
            object: nil,
            userInfo: ["newsId": self.news!.id, "favorited": favorited]
        )
    }

    @objc fileprivate func onCommentAction() {
        let vc = AppStoryboard.Main.viewController(CommentVC.self)
        vc.news = news
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc fileprivate func onShareAction() {
        var uri = ""
        if let url = news?.url {
            if url.starts(with: "https://t.co/") {
                uri = url.replacingOccurrences(of: "https://t.co/", with: "https://barq.news/n/")
            } else if url.starts(with: "https://twitter.com/") {
                let index = url.lastIndex(of: "/")!
                let id = url[index...]
                uri = "https://barq.news/t\(id)"
            } else {
                uri = url
            }
        }

        let vc = UIActivityViewController(activityItems: ["\(news?.title ?? "\n")\n\(uri)\n\("Share News".localized)"], applicationActivities: nil)
        present(vc, animated: true, completion: nil)
    }

    // MARK: - UITableViewDelegate, UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return news == nil ? 0 : 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case NewsDetailCellType.source.rawValue:
            return handleNewsCell(tableView: tableView, cellForRowAt: indexPath)
        case NewsDetailCellType.ads.rawValue:
            return handleAdsCell(tableView: tableView, cellForRowAt: indexPath)
        default:
            return handleWebViewCell(tableView: tableView, cellForRowAt: indexPath)
        }
    }

    fileprivate func handleNewsCell(tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: NewsCell.identifier, for: indexPath) as? NewsCell else {
            fatalError()
        }

        // source
        cell.sourceIcon.sd_setImage(with: URL(string: news?.source.imageUrl ?? ""), placeholderImage: #imageLiteral(resourceName: "tab_bg.png"))
        cell.sourceNameLabel.text = news?.source.name
        // timestamp
        cell.timestampLabel.text = news?.time.diffString
        // news title
        cell.titleLabel.text = news?.title
        // news image
        if let image = news?.image {
            cell.newsImageView.isHidden = false
            cell.imageHeightConstraint.constant = (tableView.bounds.width - 40) * news!.imageRatio
            cell.newsImageView.sd_setImage(with: URL(string: image), placeholderImage: #imageLiteral(resourceName: "tab_bg.png"))
        } else {
            cell.newsImageView.isHidden = true
        }
        // comment
        cell.commentLabel.text = news?.comment.description
        cell.bottomView.isHidden = true

        return cell
    }

    fileprivate func handleAdsCell(tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: NewsAdsCell.identifier, for: indexPath) as? NewsAdsCell else {
            fatalError()
        }

        if cell.contentView.subviews.isEmpty {
            cell.contentView.addSubview(adView)
            adView.center = cell.contentView.center
        }

        return cell
    }

    fileprivate func handleWebViewCell(tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: WebViewCell.identifier, for: indexPath) as? WebViewCell else {
            fatalError()
        }

        if cell.contentView.subviews.isEmpty, let urlString = news?.url, let url = URL(string: urlString) {
            cell.contentView.addSubview(webView)
            constrain(webView) {
                $0.leading == $0.superview!.leading
                $0.trailing == $0.superview!.trailing
                $0.top == $0.superview!.top
                $0.bottom == $0.superview!.bottom
            }
            cell.contentView.addSubview(loading)
            cell.contentView.bringSubviewToFront(loading)
            constrain(loading) {
                $0.width == 36
                $0.height == 36
                $0.center == $0.superview!.center
            }
            webView.load(URLRequest(url: url, cachePolicy: .reloadRevalidatingCacheData))
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case NewsDetailCellType.source.rawValue:
            return UITableView.automaticDimension

        case NewsDetailCellType.ads.rawValue:
            return Defaults.setting.value.adsNewsDetail ? adViewHeight : 0

        default:
            return webViewHeight
        }
    }
}

extension NewsDetailVC: WKNavigationDelegate, WKUIDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        loading.startAnimating()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if loading.isAnimating {
            loading.stopAnimating()
            loading.removeFromSuperview()
        }
        print("Loading web page failed: \(error)")
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if self.loading.isAnimating {
                self.loading.stopAnimating()
                self.loading.removeFromSuperview()
            }
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        if loading.isAnimating {
            loading.stopAnimating()
            loading.removeFromSuperview()
        }
        print("Loading web page failed: \(error)")
    }
}
