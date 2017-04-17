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
    
    private let metaToControllerMap = NSMapTable<ETKConnMeta, UIViewController>.weakToStrongObjects()
    
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
        cell.detailTextLabel!.text = "topics: \(meta.subscriptions.description)"
        
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
        }
        
        // create or reuse detail view controller
        let meta = connections[indexPath.row]
        var naviVC: UINavigationController? = nil
        
        if let obj = metaToControllerMap.object(forKey: meta) {
            naviVC = obj as? UINavigationController
        } else {
            let sb = UIStoryboard(name: "Main", bundle: Bundle.main)
            naviVC = sb.instantiateViewController(withIdentifier: "detailNavi") as? UINavigationController
            metaToControllerMap.setObject(naviVC, forKey: meta)
        }
        
        let detailVC = naviVC!.viewControllers.first as! ETKMessageViewController
        
        detailVC.meta = meta
        
        self.showDetailViewController(naviVC!, sender: self)
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
            let meta = ETKConnMetaManager.sharedManager.remove(at: indexPath.row)
            metaToControllerMap.removeObject(forKey: meta)
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    
    // MARK: - UISplitViewControllerDelegate
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        return collapseDetailViewController;
    }

}
