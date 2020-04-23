//
//  MagazineVC.swift
//  news
//
//  Created by Eliot Gravett on 2019/5/23.
//  Copyright © 2019 Barq. All rights reserved.
//

import UIKit
import DZNEmptyDataSet

class MagazineVC: UITableViewController {
    var categories: [Category] = []

    var margin: UIView {
        let vc = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 12))
        vc.backgroundColor = .clear
        return vc
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Magazine".localized
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        setupNavigationButtons()

        setup(tableView, cellClass: [MagazineCell.self], pullToRefresh: true)
        tableView.tableHeaderView = margin
        tableView.tableFooterView = margin
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self

        loadData()
    }

    func loadData(indicator: Bool = true) {
        get(url: "/list_categories/channel/2", indicator: indicator, refreshControl: tableView.refreshControl) { [unowned self] data in
            self.categories = data.arrayValue.map(Category.init)
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
        return categories.count
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MagazineCell.identifier, for: indexPath) as? MagazineCell else {
            fatalError()
        }

        let category = categories[indexPath.row]

        cell.magazineImageView.sd_setImage(with: URL(string: category.imageUrl ?? ""), placeholderImage: #imageLiteral(resourceName: "tab_bg.png"))
        cell.magazineNameLabel.text = category.name

        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let item = categories[indexPath.row]

        let vc = NewsVC()
        vc.type = .magazine
        vc.source = Source(id: item.id, name: item.name)
        navigationController?.pushViewController(vc, animated: true)
    }

}

extension MagazineVC: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return #imageLiteral(resourceName: "empty_logo.png")
    }
}
