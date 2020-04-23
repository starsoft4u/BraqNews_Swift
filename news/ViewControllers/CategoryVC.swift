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

enum NewsChannel: Int, CaseIterable {
    case newspaper = 1, magazine, tvChannels, webSources, government, sportsClubs

    func title() -> String {
        let titles = ["News Paper", "Magazine", "TV Channels", "Web Sources", "Government", "Sports Clubs"]
        return titles[self.rawValue - 1].localized
    }

    func icon() -> String {
        return "ic_channel\(self.rawValue)"
    }
}

enum CategoryPage: String {
    case newspaper = "News Paper"
    case modifySource = "Edit Source"
}

class CategoryVC: UITableViewController {
    var page: CategoryPage = .newspaper
    var tableData: [Category] = []

    var paddingView: UIView {
        let vc = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 12))
        vc.backgroundColor = .clear
        return vc
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = page.rawValue.localized
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        if page == .newspaper {
            setupNavigationButtons()
        }

        setup(tableView, cellClass: [CategoryCell.self], pullToRefresh: page != .modifySource)
        tableView.tableHeaderView = paddingView
        tableView.tableFooterView = paddingView
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self

        if page == .modifySource {
            tableData = [Category(id: 0, name: "My Sources".localized, iconUrl: "ic_channel0")]
            tableData.append(contentsOf: NewsChannel.allCases.map { Category(id: $0.rawValue, name: $0.title(), iconUrl: $0.icon()) })
            tableView.reloadData()
        } else {
            loadData()
        }
    }

    func loadData(indicator: Bool = true) {
        get(url: "/list_categories/channel/1", indicator: indicator, refreshControl: tableView.refreshControl) { [unowned self] res in
            self.tableData = res.arrayValue.map(Category.init)
            self.tableView.reloadData()
        }
    }

    override func onPullRefresh() {
        loadData(indicator: false)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CategoryCell.identifier, for: indexPath) as? CategoryCell else {
            fatalError()
        }

        let item = tableData[indexPath.row]

        let urlString = item.iconUrl ?? item.imageUrl
        if let icon = urlString, !icon.lowercased().starts(with: "http") {
            cell.iconImageView.image = UIImage(named: icon) ?? #imageLiteral(resourceName: "tab_bg.png")
        } else {
            cell.iconImageView.sd_setImage(with: URL(string: urlString ?? ""), placeholderImage: #imageLiteral(resourceName: "tab_bg.png"))
        }
        cell.nameLabel.text = item.name

        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let item = tableData[indexPath.row]

        switch page {
        case .newspaper:
            let vc = SourceVC()
            vc.category = item
            navigationController?.pushViewController(vc, animated: true)

        case .modifySource:
            let vc = SourceSelectVC()
            vc.pageTitle = item.name
            vc.channel = item.id
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}

extension CategoryVC: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return #imageLiteral(resourceName: "empty_logo.png")
    }
}
