//
//  MyNewsVC.swift
//  news
//
//  Created by Eliot Gravett on 2019/6/23.
//  Copyright © 2019 Barq. All rights reserved.
//

import DZNEmptyDataSet
import UIKit

class MyNewsVC: UITableViewController {
    var tableData: [(category: Category, children: [Source])] = []
    var isFirstTime = true

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "My News".localized

        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        setupNavigationButtons()

        setup(tableView, cellClass: [SourceCell.self], pullToRefresh: true)
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self

        loadData()

        NotificationCenter.default.addObserver(self, selector: #selector(favoriteChanged), name: .favoriteChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(followChanged), name: .followChanged, object: nil)
    }

    func loadData(indicator: Bool = true) {
        if !isLoggedIn, Defaults.sources.value.isEmpty, Defaults.favorites.value.isEmpty {
            isFirstTime = false
            tableData = []
            tableView.reloadData()
            tableView.refreshControl?.endRefreshing()

        } else if isLoggedIn {
            get(url: "/my_news", indicator: indicator, refreshControl: tableView.refreshControl) { [unowned self] res in
                self.tableData = res.arrayValue.map {
                    let category = Category(json: $0)
                    let sources = $0["sources"].arrayValue.map(Source.init)
                    return (category: category, children: sources)
                }
                self.tableView.reloadData()
            }

        } else {
            if Defaults.sources.value.isEmpty {
                var source = Source(name: "My Favorite News".localized)
                source.followerCount = Defaults.favorites.value.count
                tableData = [(category: Category(name: "My Favorite".localized), children: [source])]
                tableView.reloadData()
                tableView.refreshControl?.endRefreshing()
            } else {
                let ids = Defaults.sources.value.map(String.init).joined(separator: "_")
                get(url: "/sources/categorize/1/source_ids/\(ids)", indicator: indicator, refreshControl: tableView.refreshControl) { [unowned self] res in
                    var source = Source(name: "My Favorite News")
                    source.followerCount = Defaults.favorites.value.count
                    self.tableData = [(category: Category(name: "My Favorite".localized), children: [source])]

                    let data: [(category: Category, children: [Source])] = res.arrayValue.map {
                        let category = Category(json: $0)
                        let sources: [Source] = $0["sources"].arrayValue.map {
                            var item = Source(json: $0)
                            item.isMySource = Defaults.sources.value.contains(item.id)
                            if item.isMySource {
                                item.followerCount += 1
                            }
                            return item
                        }
                        return (category: category, children: sources)
                    }

                    self.tableData.append(contentsOf: data)
                    self.tableView.reloadData()
                }
            }
        }
    }

    override func onPullRefresh() {
        loadData(indicator: false)
    }

    @objc fileprivate func favoriteChanged(_ notification: Notification) {
        loadData()
    }

    @objc fileprivate func followChanged(_ notification: Notification) {
        loadData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return tableData.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData[section].children.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return tableData[section].category.name?.localized
    }

    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else {
            return
        }

        header.backgroundColor = .bgColor
        header.backgroundView?.backgroundColor = .bgColor
        header.semanticContentAttribute = .forceRightToLeft

        header.textLabel?.font = Constants.Font.regular.withSize(19)
        header.textLabel?.semanticContentAttribute = .forceRightToLeft
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 36
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SourceCell.identifier, for: indexPath) as? SourceCell else {
            fatalError()
        }

        let source = tableData[indexPath.section].children[indexPath.row]

        cell.bottomView.isHidden = indexPath.row < (tableData[indexPath.section].children.count - 1)
        cell.sourceNameLabel.text = source.name?.localized
        if source.id == 0 {
            cell.sourceImageView.image = #imageLiteral(resourceName: "ic_favorite.png")
            cell.followerLabel.text = "% News in My Favorite".localize(value: source.followerCount.description)
        } else {
            cell.sourceImageView.sd_setImage(with: URL(string: source.imageUrl ?? ""), placeholderImage: #imageLiteral(resourceName: "tab_bg.png"))
            cell.followerLabel.text = source.follower
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let source = tableData[indexPath.section].children[indexPath.row]

        let vc = NewsVC()
        vc.type = source.id == 0 ? .favorite : .myNews
        vc.source = source
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension MyNewsVC: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
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
        view.imageView.image = #imageLiteral(resourceName: "empty_source")
        view.titleLabel.text = "No sources available!".localized
        view.messageLabel.text = "Please add new sources to view news here".localized
        view.button.isHidden = false
        view.tappedButton = { self.addSource() }
        return view
    }
}
