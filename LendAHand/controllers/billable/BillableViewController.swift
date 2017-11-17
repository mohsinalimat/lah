//
//  BillableViewController.swift
//  LendAHand
//
//  Created by Hoan Tran on 11/7/17.
//  Copyright © 2017 Hoan Tran. All rights reserved.
//

import UIKit

class BillableViewController: UIViewController {
  var currents: LocalCollection<Current>!
  var works: LocalCollection<Work>!
  var timer: Timer!
  
  static let cellID = "BillableCellID"
  var worker: Worker?
  var workerID: String?
  var observerToken: NSObjectProtocol?
  
  lazy var control: ClockControlView = {
    let v = ClockControlView()
    v.translatesAutoresizingMaskIntoConstraints = false
    v.delegate = self
    return v
  }()
  
  lazy var tableView: UITableView = {
    let table = UITableView()
    table.translatesAutoresizingMaskIntoConstraints = false
    table.dataSource = self
    table.delegate = self
    return table
  }()
  
  fileprivate func layoutTable() {
    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.widthAnchor.constraint(equalTo: view.widthAnchor),
      tableView.bottomAnchor.constraint(equalTo: control.topAnchor)
      ])
  }
  
//  var work: Work = {
//    let project = "0VXsIC8d14Q1x79F3H7y"
//    let start = Date()
//    let stop = Date(timeInterval: 3723, since: start)
//    let w = Work(rate: 7.8, isPaid: true, start: start, project: project, stop: stop, note: "One note to bring")
//    return w
//  }()
  
  fileprivate func setupHeader() {
    view.backgroundColor = UIColor.blue
    if let worker = self.worker {
      navigationItem.title = "Can not get name"
      ContactMgr.shared.fetchName(worker.contact) { name in
        if let name = name {
          self.navigationItem.title = name
        }
      }
    }
  }
  
  fileprivate func setupControl() {
    view.addSubview(control)
    NSLayoutConstraint.activate([
      control.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      control.leftAnchor.constraint(equalTo: view.leftAnchor),
      control.rightAnchor.constraint(equalTo: view.rightAnchor),
      control.heightAnchor.constraint(equalToConstant: 55)
      ])
    updateControl()
  }
  
  fileprivate func setupTable() {
    layoutTable()
    self.tableView.register(BillableCell.self, forCellReuseIdentifier: BillableCell.cellID)
    self.observerToken = NotificationCenter.default.addObserver(forName: .projectChanged, object: nil, queue: nil, using: {notif in
      DispatchQueue.main.async {
        self.tableView.reloadData()
      }
    })
  }
  
  fileprivate func unObserve() {
    if let token = self.observerToken {
      NotificationCenter.default.removeObserver(token)
      self.observerToken = nil
    }
  }
  
  fileprivate func cleanup() {
    unObserve()
    deinitCurrents()
    deinitWorks()
    clearTimer()
    self.worker = nil
    self.workerID = nil
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    cleanup()
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupHeader()
    setupControl()
    setupTable()
    setupCurrents()
    setupWorks()
//    print("--- INIT ---")
  }
  
  deinit {
//    print("--- DEINIT ---")
    cleanup()
  }
}

extension BillableViewController {
  func startTimer() {
    clearTimer()
    self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timerFired), userInfo: nil, repeats: true)
  }
  
  func clearTimer() {
    self.timer?.invalidate()
    self.timer = nil
  }
  
  @objc func timerFired(timer: Timer) {
    updateClock()
  }
}



extension BillableViewController {
  func setupWorks() {
    if let workerID = self.workerID {
      let query = Constants.firestore.collection.workers.document(workerID).collection(Constants.works)
      self.works = LocalCollection(query: query) { [unowned self] (changes) in
        DispatchQueue.main.async {
          self.tableView.reloadData()
        }
      }
      self.works.listen()
    }
  }
  
  func deinitWorks() {
    if let works = self.works {
      works.stopListening()
      self.works = nil
    }
  }
}


extension BillableViewController: ClockControlDelegate {
  
  func updateClock() {
    if let index = currentIndex() {
      let current = self.currents[index]
      control.update(current.start.elapsed())
    }
  }
  
  func updateControl() {
    if isOnTheClock() {
      control.showClockOut()
      startTimer()
    } else {
      control.showClockIn()
      clearTimer()
      control.clear()
    }
  }
  
  func currentIndex()->Int? {
    if let workerID = self.workerID {
      if let currents = self.currents {
        if currents.count > 0 {
          for i in 0...currents.count - 1 {
            if workerID == currents[i].worker {
              return i
            }
          }
        }
      }
    } else {
      print ("Err: workerID is not set")
    }
    return nil
  }
  
  func isOnTheClock()->Bool {
    if currentIndex() == nil {
      return false
    } else {
      return true
    }
  }
  
  func tapped() {
    if isOnTheClock() {
      clockOut()
    } else {
      clockIn()
    }
  }
  
  func clockIn() {
    self.control.showClockOut()
    if let workerID = self.workerID {
      let current = Current(
        worker: workerID,
        start: Date())
      Constants.firestore.collection.currents.addDocument(data: current.dictionary)
    } else {
      print ("Err: workerID is not set")
    }
  }
  
  func clockOut() {
    self.control.showClockIn()
    if let index = currentIndex() {
      if let currentID = self.currents.id(index) {
        let current = self.currents[index]
        //
        Constants.firestore.collection.currents.document(currentID).delete() { err in
          if let err = err {
            print("Err while deleting \(currentID): \(err)")
          }
        }
        
        //
        if let worker = self.worker {
          let work = Work(rate: worker.rate, isPaid: false, start: current.start, project: nil, stop: Date(), note: nil)
          Constants.firestore.collection.workers.document(current.worker).collection(Constants.works).addDocument(data: work.dictionary)
        } else {
          print ("Err: worker is not set; can save this work period")
        }
        
      }
    } else {
      print ("Err: can not index of the current entry")
    }
  }
  
  func setupCurrents() {
    let query = Constants.firestore.collection.currents
    self.currents = LocalCollection(query: query) { [unowned self] (changes) in
      //      changes.forEach(){ print ("[", $0.type, "]", $0) }
      self.updateControl()
    }
    self.currents.listen()
  }
  
  func deinitCurrents() {
    if let currents = self.currents {
      currents.stopListening()
      self.currents = nil
    }
  }
}



extension BillableViewController: UITableViewDataSource {
  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if let works = self.works {
      return works.count
    } else {
      return 0
    }
  }
  public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: BillableCell.cellID, for: indexPath) as! BillableCell
    cell.work = self.works[indexPath.row]
    return cell
  }
}



extension BillableViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 40
  }
}



