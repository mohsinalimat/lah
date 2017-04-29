//
//  TimeCardViewController.swift
//  Lah
//
//  Created by Hoan Tran on 3/15/17.
//  Copyright © 2017 Pego Consulting. All rights reserved.
//

import UIKit

class TimeCardViewController: UIViewController, EditedWorkerDelegate {
    var worker: Worker?
    static let TimeCardSegue = "EditWorker"
    var dataSource: BillableDataSource?
    var tableDelegate: BillableTableDelegate?
    @IBOutlet weak var billableTable: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let workerKey = self.worker?.key {
            self.dataSource = BillableDataSource(tableView: self.billableTable, workerKey: workerKey)
            self.tableDelegate = BillableTableDelegate(tableView: self.billableTable, vc: self)
        }
        self.billableTable.reloadData()
        print(self.dataSource ?? "no data source")
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        guard let worker = self.worker, let lastName = self.worker?.lastName else { return }
        self.navigationItem.title = "\(worker.firstName) \(lastName)"
        self.billableTable.reloadData()
        print(self.dataSource ?? "no data source 2")
    }    
    
    @IBAction func cancel(_ sender: Any) {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func edit(_ sender: Any) {
        performSegue(withIdentifier: TimeCardViewController.TimeCardSegue, sender: self)
    }
    
    func setWorker(_ worker: Worker) {
        self.worker = worker
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == TimeCardViewController.TimeCardSegue {
            let upcoming: AddWorkerViewController = (( segue.destination ) as! UINavigationController).topViewController as! AddWorkerViewController
            upcoming.editedWorkerDelegate = self
            upcoming.worker = worker
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
