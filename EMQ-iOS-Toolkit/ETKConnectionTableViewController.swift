//
//  ETKConnectionTableViewController.swift
//  EMQ-iOS-Toolkit
//
//  Created by Alex Yu on 22/03/2017.
//  Copyright © 2017 EMQ. All rights reserved.
//

import UIKit

class ETKConnectionTableViewController: UITableViewController, UISplitViewControllerDelegate {
    
    private var collapseDetailViewController = true
    var connections = [ETKConnectionMeta]()

    override func viewDidLoad() {
        super.viewDidLoad()
        splitViewController?.delegate = self
        
        // Uncomment the following line to preserve selection between presentations
         self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        let meta1 = ETKConnectionMeta()
        meta1.displayName = "Local Host"
        
        let meta2 = ETKConnectionMeta()
        meta2.displayName = "EMQ test server"
        
        let meta3 = ETKConnectionMeta()
        meta3.displayName = "Jason's Mac"
        
        connections.append(meta1)
        connections.append(meta2)
        connections.append(meta3)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return connections.count + 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.row == connections.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: "add", for: indexPath)
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "connection", for: indexPath)
        cell.textLabel!.text = connections[indexPath.row].displayName
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        collapseDetailViewController = false
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    
    // MARK: - UISplitViewControllerDelegate
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        return collapseDetailViewController;
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
