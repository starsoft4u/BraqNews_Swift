//
//  NewsVC.swift
//  news
//
//  Created by Eliot Gravett on 2019/5/23.
//  Copyright © 2019 Barq. All rights reserved.
//

import DZNEmptyDataSet
import GoogleMobileAds
import SwiftDate
import SwiftyJSON
import UIKit
import UIScrollView_InfiniteScroll

enum NewsType {
    case last, magazine, search, newsPaper, favorite, myNews

    func value() -> String {
        switch self {
        case .last: return "last"
        case .magazine: return "category"
        case .favorite: return "favorite"
        default: return "source"
        }
    }

    func adEnable() -> Bool {
        switch self {
        case .last: return Defaults.setting.value.adsLastNews
        case .newsPaper: return Defaults.setting.value.adsNewspaper
        case .magazine: return Defaults.setting.value.adsMagazine
        default: return false
        }
    }
}

class NewsVC: UITableViewController {
    var type: NewsType = .last
    var source: Source?
    var data: [Any] = []
    var minId = 0

    var isFirstTime = true
    var header: NewsHeaderView!

    var adsToLoad = [GADBannerView]()
    var loadStateForAds = [GADBannerView: Bool]()
    let adOffset = 2
    let adInterval = UIDevice.current.userInterfaceIdiom == .pad ? 16 : 8
    let adViewHeight = CGFloat(250)

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if data.isEmpty {
            loadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = type == .last ? "Last News".localized : source?.name
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        if type == .last {
            setupNavigationButtons()
        }

        setup(tableView, cellClass: [NewsCell.self, NewsAdsCell.self], pullToRefresh: true)
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self

        if type != .favorite {
            tableView.infiniteScrollTriggerOffset = 200
            tableView.addInfiniteScroll { _ in
                self.loadData(refresh: false, indicator: false)
            }
        }

        if type.value() == "source", let source = source {
            header = .loadFromNib()
            header.backgroundImageView.sd_setImage(with: URL(string: source.backgroundUrl ?? ""), placeholderImage: #imageLiteral(resourceName: "tab_bg.png"))
            header.sourceImageView.sd_setImage(with: URL(string: source.imageUrl ?? ""), placeholderImage: #imageLiteral(resourceName: "tab_bg.png"))
            header.sourceNameLabel.text = source.name
            header.descriptionLabel.text = source.description
            updateSourceView()
            header.tappedButton = onFollowAction
            header.tappedSwitch = onNotifyAction
            header.sizeToFit()
        }

        NotificationCenter.default.addObserver(self, selector: #selector(commentChanged), name: .commentChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(favoriteChanged), name: .favoriteChanged, object: nil)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if let headerView = tableView.tableHeaderView {
            let height = CGFloat(300)
            var headerFrame = headerView.frame

            if height != headerFrame.size.height {
                headerFrame.size.height = height
                headerView.frame = headerFrame
                tableView.tableHeaderView = headerView
            }
        }
    }

    func loadData(refresh: Bool = true, indicator: Bool = true) {
        var empty = false
        if type == .last, !isLoggedIn, Defaults.sources.value.isEmpty {
            empty = true
        } else if type == .favorite, !isLoggedIn, Defaults.favorites.value.isEmpty {
            empty = true
        } else if type != .last, type != .favorite, source == nil {
            empty = true
        }

        if empty {
            isFirstTime = false
            data = []
            minId = 0
            tableView.reloadData()
            tableView.refreshControl?.endRefreshing()
            return
        }

        if refresh {
            minId = 0
            adsToLoad.removeAll()
            loadStateForAds.removeAll()
            if type != .favorite, tableView.infiniteScrollIndicatorView == nil {
                tableView.addInfiniteScroll { _ in self.loadData(refresh: false, indicator: false) }
            }
        }

        var params: [String: Any] = ["minId": minId]

        if type == .last, !isLoggedIn {
            params["type"] = "source_ids"
            params["id"] = Defaults.sources.value.map(String.init).joined(separator: "_")
        } else if type == .favorite, !isLoggedIn {
            params["type"] = "favorite_ids"
            params["id"] = Defaults.favorites.value.map(String.init).joined(separator: "_")
        } else {
            params["type"] = type.value()
            params["id"] = (type == .last || type == .favorite) ? Defaults.userId.value : source!.id
        }

        post(url: "/fetch_news", params: params, indicator: indicator, refreshControl: tableView.refreshControl) { [unowned self] res in
            let favorites = Defaults.favorites.value
            let news: [News] = res.arrayValue.map { json in
                var item = News(json: json)
                if !self.isLoggedIn {
                    item.favorited = favorites.contains(item.id)
                }
                return item
            }

            if refresh {
                self.data.removeAll()
                self.data.append(contentsOf: news)
                if !self.data.isEmpty, self.tableView.tableHeaderView == nil {
                    self.tableView.tableHeaderView = self.header
                }
                self.tableView.reloadData()
            } else {
                let start = self.data.count
                self.data.append(contentsOf: news)
                if self.type.adEnable() {
                    self.setupAds()
                }
                let end = self.data.count

                self.tableView.finishInfiniteScroll()

                let rows = (start..<end).map { IndexPath(row: $0, section: 0) }
                self.tableView.beginUpdates()
                self.tableView.insertRows(at: rows, with: .fade)
                self.tableView.endUpdates()
            }

            if news.isEmpty {
                self.tableView.removeInfiniteScroll()
            } else {
                self.minId = news.map { $0.id }.min()!
            }
        }
    }

    override func onPullRefresh() {
        loadData(indicator: false)
    }

    fileprivate func onFollowAction() {
        guard let source = source else { return }

        let checked = source.isMySource
        if isLoggedIn {
            get(url: "/register_source/id/\(source.id)/register/\(checked ? 0 : 1)") { [unowned self] _ in
                self.handleFollow(!checked)
            }
        } else {
            handleFollow(!checked)
        }
    }

    fileprivate func handleFollow(_ follow: Bool) {
        if follow {
            Defaults.sources.value.append(source!.id)
            source!.followerCount += 1
        } else {
            Defaults.sources.value.removeAll(where: { $0 == source!.id })
            source!.followerCount -= 1
        }

        source!.isMySource = follow

        updateSourceView()

        NotificationCenter.default.post(
            name: .followChanged,
            object: nil,
            userInfo: ["sourceId": self.source!.id, "checked": follow]
        )
    }

    fileprivate func onNotifyAction(checked: Bool) {
        if header.notifySwitch.isEnabled, isLoggedIn {
            get(url: "/block_source/id/\(source!.id)/block/\(checked ? 0 : 1)") { [unowned self] _ in
                self.handleNotify(checked)
            }
        } else {
            handleNotify(checked)
        }
    }

    fileprivate func handleNotify(_ checked: Bool) {
        if checked {
            Defaults.notifications.value.append(source!.id)
            subscribeNotification(topic: source!.id.description, subscribe: true)
        } else {
            Defaults.notifications.value.removeAll(where: { $0 == source!.id })
            subscribeNotification(topic: source!.id.description, subscribe: false)
        }
    }

    fileprivate func updateSourceView() {
        header.followersLabel.text = "Followers %".localize(value: source!.followerCount.description)
        header.buttonState(check: source!.isMySource)
        header.notifySwitch.isOn = source!.isMySource && Defaults.notifications.value.contains(source!.id)
        header.notifySwitch.isEnabled = source!.isMySource && Defaults.notifyGlobal.value
    }

    @objc fileprivate func commentChanged(_ notification: Notification) {
        guard let newsId = notification.userInfo?["newsId"] as? Int,
            let commentCount = notification.userInfo?["commentCount"] as? Int,
            let index = data.firstIndex(where: { ($0 as? News)?.id == newsId }) else {
            return
        }
        var news = data[index] as! News
        news.comment = commentCount
        data[index] = news as Any
        tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
    }

    @objc fileprivate func favoriteChanged(_ notification: Notification) {
        guard let newsId = notification.userInfo?["newsId"] as? Int,
            let favorited = notification.userInfo?["favorited"] as? Bool,
            let index = data.firstIndex(where: { ($0 as? News)?.id == newsId }) else {
            return
        }

        if type == .favorite {
            data.remove(at: index)
            tableView.reloadData()
        } else {
            var news = data[index] as! News
            news.favorited = favorited
            data[index] = news as Any
            tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
        }
    }

    // MARK: - Ads

    fileprivate func setupAds() {
        guard !data.isEmpty else {
            return
        }

        // Ensure subview layout has been performed before accessing subview sizes.
        tableView.layoutIfNeeded()

        // if preloading ads
        let loading = !adsToLoad.isEmpty

        var index = adOffset
        while index < data.count {
            if data[index] is News {
                let adSize = GADAdSizeFromCGSize(CGSize(width: tableView.contentSize.width, height: adViewHeight))
                let adView = GADBannerView(adSize: adSize)
                adView.adUnitID = Constants.adsUnitId
                adView.rootViewController = self
                adView.delegate = self

                data.insert(adView, at: index)
                adsToLoad.append(adView)
            }

            index += adInterval
        }

        if !loading {
            preloadNextAd()
        }
    }

    // Preload banner ads sequentially. Dequeue and load next ad from `adsToLoad` list.
    func preloadNextAd() {
        if !adsToLoad.isEmpty {
            let ad = adsToLoad.removeFirst()
            let adRequest = GADRequest()
//            adRequest.testDevices = [kGADSimulatorID]
            ad.load(adRequest)
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let news = data[indexPath.row] as? News {
            return handleNewsCell(tableView: tableView, cellForRowAt: indexPath, for: news)
        } else {
            return handleAdsCell(tableView: tableView, cellForRowAt: indexPath, for: data[indexPath.row] as! GADBannerView)
        }
    }

    fileprivate func handleNewsCell(tableView: UITableView, cellForRowAt indexPath: IndexPath, for news: News) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: NewsCell.identifier, for: indexPath) as? NewsCell else {
            fatalError()
        }

        // source
        cell.sourceIcon.sd_setImage(with: URL(string: news.source.imageUrl ?? ""), placeholderImage: #imageLiteral(resourceName: "tab_bg.png"))
        cell.sourceNameLabel.text = news.source.name
        // timestamp
        cell.timestampLabel.text = news.time.diffString
        // news title
        cell.titleLabel.text = news.title
        // news image
        if let image = news.image {
            cell.newsImageView.isHidden = false
            cell.imageHeightConstraint.constant = (tableView.bounds.width - 40) * news.imageRatio
            cell.newsImageView.sd_setImage(with: URL(string: image), placeholderImage: #imageLiteral(resourceName: "tab_bg.png"))
        } else {
            cell.newsImageView.isHidden = true
        }
        // comment
        cell.commentLabel.text = news.comment.description
        cell.tappedComment = {
            let vc = AppStoryboard.Main.viewController(CommentVC.self)
            vc.news = news
            self.navigationController?.pushViewController(vc, animated: true)
        }
        // share
        cell.tappedShare = {
            var uri = ""
            if let url = news.url {
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
            
            let vc = UIActivityViewController(activityItems: ["\(news.title ?? "\n")\n\(uri)\n\("Share News".localized)"], applicationActivities: nil)
            self.present(vc, animated: true, completion: nil)
        }

        return cell
    }

    fileprivate func handleAdsCell(tableView: UITableView, cellForRowAt indexPath: IndexPath, for bannerView: GADBannerView) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: NewsAdsCell.identifier, for: indexPath) as? NewsAdsCell else {
            fatalError()
        }

        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        cell.contentView.addSubview(bannerView)
        bannerView.center = cell.contentView.center

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let news = data[indexPath.row] as? News else {
            return
        }

        let vc = NewsDetailVC()
        vc.news = news
        navigationController?.pushViewController(vc, animated: true)
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let bannerView = data[indexPath.row] as? GADBannerView {
            return loadStateForAds[bannerView] == true ? adViewHeight : 0
        } else {
            return UITableView.automaticDimension
        }
    }
}

extension NewsVC: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    func verticalOffset(forEmptyDataSet scrollView: UIScrollView!) -> CGFloat {
        return type.value() == "source" ? 120 : 0
    }

    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        guard isFirstTime else {
            return nil
        }

        isFirstTime = false

        return #imageLiteral(resourceName: "empty_logo.png")
    }

    func customView(forEmptyDataSet scrollView: UIScrollView!) -> UIView! {
        guard !isFirstTime else {
            return nil
        }
        let view: EmptyView = .loadFromNib()
        view.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: 200)
        view.imageView.image = #imageLiteral(resourceName: "empty_source")
        switch type {
        case .favorite:
            view.titleLabel.text = "You don’t have any news in your favorite".localized
            view.messageLabel.text = "To add news to your favorite click on star on top bar of any news".localized

        case .last:
            view.titleLabel.text = "No sources available!".localized
            view.messageLabel.text = "Please add new sources to view news here".localized
            view.button.isHidden = false
            view.tappedButton = { self.addSource() }

        default:
            view.titleLabel.text = "No news available!".localized
            view.messageLabel.isHidden = true
            view.button.isHidden = true
        }

        return view
    }
}

extension NewsVC: GADBannerViewDelegate {
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        loadStateForAds[bannerView] = true
        preloadNextAd()
    }

    func adView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: GADRequestError) {
        print("Failed to receive ad: \(error)")
        preloadNextAd()
    }
}
