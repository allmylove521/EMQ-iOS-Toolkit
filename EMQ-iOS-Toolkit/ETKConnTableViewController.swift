//
//  ETKConnTableViewController.swift
//  EMQ-iOS-Toolkit
//
//  Created by Alex Yu on 22/03/2017.
//  Copyright © 2017 EMQ. All rights reserved.
//

import UIKit

class ETKConnTableViewController: UITableViewController, UISplitViewControllerDelegate {
    
    private var collapseDetailViewController = true
    
    // shadow of metas
    private(set) var connections: [ETKConnMeta] {
        get {
            return ETKConnMetaManager.sharedManager.metas
        }
        set {
            
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        splitViewController?.delegate = self
        
        // Uncomment the following line to preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func viewDidAppear(_ animated: Bool) {
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
        let meta = connections[indexPath.row]
        
        let name = meta.displayName.isEmpty ? meta.host : meta.displayName
        cell.textLabel!.text = name
        
        meta.updateAction = { [weak meta] () -> () in
            let name = (meta?.displayName.isEmpty)! ? meta?.host : meta?.displayName
            cell.textLabel!.text = name
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        collapseDetailViewController = false
        
        // If select adding cell
        if indexPath.row == connections.count {
            _ = ETKConnMetaManager.sharedManager.createMeta()
            tableView.insertRows(at: [indexPath], with: .left)
            
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .top)
            
            let sender = tableView.cellForRow(at: indexPath)
            self.performSegue(withIdentifier: "cellDetail", sender: sender)
        }
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        if indexPath.row == connections.count {
            return false
        }
        return true
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            ETKConnMetaManager.sharedManager.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    
    // MARK: - UISplitViewControllerDelegate
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        return collapseDetailViewController;
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC = segue.destination as! UINavigationController
        let detailVC: ETKMessageViewController = destinationVC.topViewController as! ETKMessageViewController
        
        let cell = sender as! UITableViewCell
        let indexPath = tableView.indexPath(for: cell)
        detailVC.meta = connections[(indexPath?.row)!]
    }

}
