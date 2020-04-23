//
//  SearchVC.swift
//  news
//
//  Created by Eliot Gravett on 2019/6/14.
//  Copyright © 2019 Barq. All rights reserved.
//

import UIKit
import DZNEmptyDataSet

class SearchVC: UIViewController {
    @IBOutlet weak var segment: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!

    var sources: [Source] = []
    var filtered: [Source] = []
    var searchText: String = ""
    var searchController: UISearchController!

    var paddingView: UIView {
        let vc = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 12))
        vc.backgroundColor = .clear
        return vc
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Search".localized

        setupSearchBar()
        setup(tableView, cellClass: [CategoryCell.self])
        tableView.tableHeaderView = paddingView
        tableView.tableFooterView = paddingView

        loadData()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        searchController.dismiss(animated: false, completion: nil)
    }

    func setupSearchBar() {
        definesPresentationContext = true
        searchController = UISearchController(searchResultsController: nil)
        searchController.dimsBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false

        navigationItem.searchController = searchController

        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder = "Search for News".localized
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.semanticContentAttribute = .forceRightToLeft
        if let textField = searchController.searchBar.value(forKey: "searchField") as? UITextField {
            textField.textColor = .white
        }
    }

    func loadData() {
        get(url: "/search") { [unowned self] res in
            let sources = res.arrayValue.map(Source.init)
            if self.isLoggedIn {
                self.sources = sources
            } else {
                self.sources = sources.map {
                    var source = $0
                    source.isMySource = Defaults.sources.value.contains($0.id)
                    return source
                }
            }
            self.tableView.reloadData()
        }
    }

    func search() {
        if searchText.isEmpty {
            filtered = []
        } else if segment.selectedSegmentIndex == 0 {
            filtered = sources.filter { $0.isMySource && ($0.name?.lowercased().contains(searchText) == true) }
        } else {
            filtered = sources.filter { $0.name?.lowercased().contains(searchText) == true }
        }
        tableView.reloadData()
    }

    @IBAction func onSegmentAction(_ sender: UISegmentedControl) {
        search()
    }
}


// MARK: -SearchBar
extension SearchVC: UISearchResultsUpdating, UISearchBarDelegate {
    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text {
            self.searchText = searchText.lowercased()
            self.search()
        }
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let searchText = searchBar.text, !searchText.isEmpty {
            self.searchText = searchText.lowercased()
            self.search()
        }
    }
}


// MARK: - UITableView
extension SearchVC: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filtered.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CategoryCell.identifier, for: indexPath) as? CategoryCell else {
            fatalError()
        }

        let source = filtered[indexPath.row]

        cell.nameLabel.text = source.name
        cell.iconImageView.sd_setImage(with: URL(string: source.imageUrl ?? ""), placeholderImage: #imageLiteral(resourceName: "tab_bg.png"))

        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let vc = NewsVC()
        vc.type = .search
        vc.source = filtered[indexPath.row]
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - Empty State
extension SearchVC: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    func customView(forEmptyDataSet scrollView: UIScrollView!) -> UIView! {
        let view: EmptyView = .loadFromNib()
        view.imageView.image = #imageLiteral(resourceName: "empty_source")
        view.titleLabel.text = "No result found!".localized
        view.messageLabel.text = "Please expand your search to find more results".localized
        return view
    }
}
