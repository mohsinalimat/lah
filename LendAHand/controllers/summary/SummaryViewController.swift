//
//  SummaryViewController.swift
//  LendAHand
//
//  Created by Hoan Tran on 11/30/17.
//  Copyright © 2017 Hoan Tran. All rights reserved.
//

import UIKit
import FirebaseFirestore
//import Reusable

class SummaryViewController: UIViewController {
  var project: LocalCollection<Project>?
  var works: LocalCollection<Work>?
  var workers: LocalCollection<Worker>?
  var collapsibles = [WorkCollapsible]()
  
  static let cellID = "SummaryViewControllerCellID"

  var datax = [  Section(id: "colors", cells: ["blue", "white"]),
                Section(id: "numbers", cells: ["one", "two", "three"]),
                Section(id: "apples", cells: ["iPhone", "iPad", "iMac", "iBook"]),
                Section(id: "tennis", cells: ["Babolat"]),
                Section(id: "drinks", cells: ["water", "wine", "tea", "liquor", "juice"]),
                Section(id: "phases", cells: ["solid", "liquid", "steam", "plasma"]),
                Section(id: "planets", cells: ["venus", "mercury", "earth", "mars", "jupiter", "saturn", "uranus", "neptune"]),
              ]
  
  deinit {
    self.project?.stopListening()
    self.works?.stopListening()
    self.workers?.stopListening()
  }
  
  var contactAccessPermission = false {
    didSet {
      if contactAccessPermission {
        DispatchQueue.main.async {
          self.tableView.reloadData()
        }
      }
    }
  }
  
  var projectID: String? {
    didSet {
      if let id = self.projectID {
        setupProjectObservation(id)
        setupWorksObservation(id)
      }
    }
  }
  
  fileprivate func setupProjectObservation(_ projectID: String) {
    if  self.project == nil,
      let query = Constants.firestore.collection.projects?.whereField(FieldPath.documentID(), isEqualTo: projectID)
    {
      self.project = LocalCollection(query: query) { [unowned self] (changes) in
        if let name = self.project?[0].name {
          DispatchQueue.main.async {
            self.navigationItem.title = name
          }
        }
      }
      self.project?.listen()
    }
  }
  
  fileprivate func setupWorksObservation(_ projectID: String) {
    if  self.works == nil,
      let query = Constants.firestore.collection.works?
        .whereField(Constants.project, isEqualTo: projectID)
    {
      self.works = LocalCollection(query: query) { [unowned self] (changes) in
        
        self.sort()
        
        let duration: Int = self.collapsibles.reduce(0, { acc, next in
          acc + next.duration
        })
        
        let amount: Float = self.collapsibles.reduce(0.00, { acc, next in
          acc + next.amount
        })
        
        let earliest = self.earliestDate()
        let latest = self.latestDate()
        
        DispatchQueue.main.async {
          self.summaryBox.duration = duration
          self.summaryBox.amount = amount
          self.summaryBox.setDates(earliest: earliest, latest: latest)
          self.tableView.reloadData()
        }
      }
      self.works?.listen()
    }
  }
  
  private func earliestDate()->Date {
    var result = Date.distantFuture
    result = collapsibles.reduce(result, { earliest, next in
      let nextEarliest = next.earliestDate()
      if nextEarliest.compare(earliest) == .orderedAscending {
        return nextEarliest
      } else {
        return earliest
      }
    })
    return result
  }
  
  private func latestDate()->Date {
    var result = Date.distantPast
    result = collapsibles.reduce(result, { latest, next in
      let nextLatest = next.latestDate()
      if latest.compare(nextLatest) == .orderedAscending {
        return nextLatest
      }
      return latest
    })
    return result
  }
  
  
  fileprivate func setupWorkersObservation() {
    if  self.workers == nil,
      let query = Constants.firestore.collection.workers
    {
      self.workers = LocalCollection(query: query) { [unowned self] (changes) in
        DispatchQueue.main.async {
          self.tableView.reloadData()
        }
      }
      self.workers?.listen()
    }
  }
  
  fileprivate func requestContactAccess() {
    ContactMgr.shared.requestContactAccess() { permission in
      self.contactAccessPermission = permission
    }
  }
  
  lazy var tableView: UITableView = {
    let table = UITableView(frame: CGRect.zero, style: .grouped)
    table.translatesAutoresizingMaskIntoConstraints = false
    table.dataSource = self
    table.delegate = self
    return table
  }()
  
  fileprivate func setupTable() {
    tableView.register(SummaryCell.self, forCellReuseIdentifier: SummaryCell.cellID)
  }
  
  fileprivate func layout() {
    view.addSubview(tableView)
    view.addSubview(separator)
    view.addSubview(summaryBox)
    
    NSLayoutConstraint.activate([
      summaryBox.heightAnchor.constraint(equalToConstant: 45),
      summaryBox.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
      summaryBox.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor),
      summaryBox.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

      separator.heightAnchor.constraint(equalToConstant: 1),
      separator.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
      separator.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor),
      separator.bottomAnchor.constraint(equalTo: summaryBox.topAnchor, constant: 0),

      tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tableView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
      tableView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor),
      tableView.bottomAnchor.constraint(equalTo: separator.topAnchor, constant: 0),
      ])
  }
  
  let separator: UIView = {
    let s = UIView()
    s.translatesAutoresizingMaskIntoConstraints = false
    s.backgroundColor = UIColor(hex: "0Xe5e5e5")
    return s
  }()
  
  let summaryBox: SummaryBoxView = {
    let v = SummaryBoxView()
    v.translatesAutoresizingMaskIntoConstraints = false
    return v
  }()
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.navigationController?.navigationItem.largeTitleDisplayMode = .never
    self.navigationController?.navigationBar.prefersLargeTitles = false
    
    // toggling the button's state so that EDIT button is shown in enabled state (simulator)
    self.navigationItem.rightBarButtonItem?.isEnabled = false
    self.navigationItem.rightBarButtonItem?.isEnabled = true
  }
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = UIColor.cyan
    
    requestContactAccess()
    setupWorkersObservation()
    setupEditProject()
    layout()
    setupTable()

//    tableView.register(cellType: SummaryWorkCell.self)
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: SummaryViewController.cellID)
    tableView.register(SummaryHeaderView.self, forHeaderFooterViewReuseIdentifier: SummaryHeaderView.headerID)
  }

}




