//
//  CategoryVC.swift
//  news
//
//  Created by Eliot Gravett on 2019/5/23.
//  Copyright © 2019 Barq. All rights reserved.
//

import UIKit
import SwiftyJSON
import DZNEmptyDataSet

class SourceVC: UITableViewController {
    var category: Category!
    var sources: [Source] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        title = category.name?.localized
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        setup(tableView, cellClass: [SourceCell.self], pullToRefresh: true)
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self

        loadData()

        NotificationCenter.default.addObserver(self, selector: #selector(followChanged), name: .followChanged, object: nil)
    }

    func loadData(indicator: Bool = true) {
        guard let _ = category else {
            sources = []
            tableView.reloadData()
            tableView.refreshControl?.endRefreshing()
            return
        }

        get(url: "/sources/category_id/\(category!.id)", indicator: indicator, refreshControl: tableView.refreshControl) { [unowned self] res in
            if self.isLoggedIn {
                self.sources = res.arrayValue.map(Source.init)
            } else {
                self.sources = res.arrayValue.map {
                    var source = Source(json: $0)
                    source.isMySource = Defaults.sources.value.contains(source.id)
                    return source
                }
            }
            self.tableView.reloadData()
        }
    }

    override func onPullRefresh() {
        loadData(indicator: false)
    }

    @objc fileprivate func followChanged(_ notification: Notification) {
        guard let sourceId = notification.userInfo?["sourceId"] as? Int,
            let checked = notification.userInfo?["checked"] as? Bool,
            let index = sources.firstIndex(where: { $0.id == sourceId }) else {
                return
        }

        var source = sources[index]
        source.isMySource = checked
        if checked {
            source.followerCount += 1
        } else {
            source.followerCount -= 1
        }
        sources[index] = source
        tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sources.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SourceCell.identifier, for: indexPath) as? SourceCell else {
            fatalError()
        }

        let item = sources[indexPath.row]

        cell.bottomView.isHidden = indexPath.row < (sources.count - 1)
        cell.sourceImageView.sd_setImage(with: URL(string: item.imageUrl ?? ""), placeholderImage: #imageLiteral(resourceName: "tab_bg.png"))
        cell.sourceNameLabel.text = item.name
        cell.followerLabel.text = item.follower

        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let vc = NewsVC()
        vc.type = .newsPaper
        vc.source = sources[indexPath.row]
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension SourceVC: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return #imageLiteral(resourceName: "empty_logo.png")
    }
}
