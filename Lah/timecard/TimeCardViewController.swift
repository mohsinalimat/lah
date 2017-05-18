//
//  TimeCardViewController.swift
//  Lah
//
//  Created by Hoan Tran on 5/17/17.
//  Copyright © 2017 Pego Consulting. All rights reserved.
//

import UIKit

class TimeCardViewController: UITableViewController {
    var bill: Billable?
    @IBOutlet weak var rate: UITextField!

    var rateDelegate = CurrencyTextFieldDelegate()
    
    var isValidated: Bool {
        // rate
        guard let rate = self.rate.text else { return false }
        if rate.isEmpty { return false }
        if rate.characters.count == 1 && rate.characters.first == "$" { return false }
        
        return true
    }
    

    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let bill = self.bill {
            rate.text = "$\(bill.rate.roundedTo(places: 2))"
        }
        
        self.navigationItem.title = "Edit"
        self.navigationItem.rightBarButtonItem  = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(self.save))
        self.navigationItem.rightBarButtonItem?.isEnabled = self.isValidated
        self.rate.addTarget(self, action: #selector(checkSaveEnability(_:)), for: .editingChanged)
        self.rate.delegate = rateDelegate
    }

    func checkSaveEnability(_ textField: UITextField) {
        self.navigationItem.rightBarButtonItem?.isEnabled = self.isValidated
    }



    func save() {
        if self.rate.text?.characters.count == 0 {
            print("nothing")
        } else {
            if var rate = self.rate.text {
                if rate.characters.first == "$" {
                    rate.remove(at: rate.startIndex)
                }
                let newRate = Float(rate)
                print("rate \(newRate ?? 0.00)")
                
            } else {
                print("no rate")
            }
        }
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        return nil
    }
    
    
    
    // MARK: - Table view data source

//    override func numberOfSections(in tableView: UITableView) -> Int {
//        // #warning Incomplete implementation, return the number of sections
//        return 0
//    }
//
//    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        // #warning Incomplete implementation, return the number of rows
//        return 0
//    }

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}