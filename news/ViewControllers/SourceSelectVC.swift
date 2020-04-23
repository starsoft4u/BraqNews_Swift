//
//  SourceSelectVC.swift
//  news
//
//  Created by Eliot Gravett on 2019/5/24.
//  Copyright © 2019 Barq. All rights reserved.
//

import DZNEmptyDataSet
import UIKit

class SourceSelectVC: UITableViewController {
    var pageTitle: String?
    var channel = 0
    var data: [(category: Category, children: [Source])] = []
    var isFirstTime = true

    override func viewDidLoad() {
        super.viewDidLoad()

        title = pageTitle
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        setup(tableView, cellClass: [SourceSelectCell.self])
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self

        loadData()
    }

    func loadData() {
        if channel == 0, !isLoggedIn, Defaults.sources.value.isEmpty {
            isFirstTime = false
            data = []
            tableView.reloadData()
            return
        }

        var url = ""
        if channel == 0 {
            url = "/my_sources"
            if !isLoggedIn {
                let ids = Defaults.sources.value.map(String.init).joined(separator: "_")
                url += "/source_ids/\(ids)"
            }
        } else {
            url = "/all_sources/channel/\(channel)"
        }
        get(url: url) { [unowned self] res in
            self.data = res.arrayValue.map {
                let category = Category(json: $0)
                var sources = $0["sources"].arrayValue.map(Source.init)
                if !self.isLoggedIn {
                    sources = sources.map { item in
                        var source = item
                        source.isMySource = Defaults.sources.value.contains(item.id)
                        return source
                    }
                }
                return (category: category, children: sources)
            }
            self.tableView.reloadData()
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return data.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data[section].children.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return data[section].category.name
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SourceSelectCell.identifier, for: indexPath) as? SourceSelectCell else {
            fatalError()
        }

        let source = data[indexPath.section].children[indexPath.row]

        cell.bottomView.isHidden = indexPath.row < (data[indexPath.section].children.count - 1)
        cell.sourceImageView.sd_setImage(with: URL(string: source.imageUrl ?? ""), placeholderImage: #imageLiteral(resourceName: "tab_bg.png"))
        cell.sourceNameLabel.text = source.name
        cell.followerLabel.text = source.follower
        cell.buttonState(check: source.isMySource)
        cell.onTappedButton = { [unowned self] in
            let checked = self.data[indexPath.section].children[indexPath.row].isMySource
            if self.isLoggedIn {
                self.get(url: "/register_source/id/\(source.id)/register/\(checked ? 0 : 1)") { _ in
                    self.handleSourceSelect(cell: cell, indexPath: indexPath, checked: !checked)
                }
            } else {
                self.handleSourceSelect(cell: cell, indexPath: indexPath, checked: !checked)

                self.data[indexPath.section].children[indexPath.row].isMySource = !checked
                cell.buttonState(check: !checked)
            }
        }

        return cell
    }

    fileprivate func handleSourceSelect(cell: SourceSelectCell, indexPath: IndexPath, checked: Bool) {
        // update my source
        data[indexPath.section].children[indexPath.row].isMySource = checked

        // update storage
        let source = data[indexPath.section].children[indexPath.row]
        if checked {
            Defaults.sources.value.append(source.id)
            Defaults.notifications.value.append(source.id)
            subscribeNotification(topic: source.id.description, subscribe: true)
        } else {
            Defaults.sources.value.removeAll(where: { $0 == source.id })
            Defaults.notifications.value.removeAll(where: { $0 == source.id })
            subscribeNotification(topic: source.id.description, subscribe: false)
        }

        // update ui
        cell.buttonState(check: checked)

        // event
        NotificationCenter.default.post(
            name: .followChanged,
            object: nil,
            userInfo: ["sourceId": data[indexPath.section].children[indexPath.row], "checked": checked]
        )
    }
}

extension SourceSelectVC: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
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
        if channel == 0 {
            view.messageLabel.text = "Please add new sources to view news here".localized
        } else {
            view.messageLabel.isHidden = true
        }
        view.button.isHidden = true
        return view
    }
}
