//
//  UIListController.swift
//  EnsembleExample
//
//  Created by Oskari Rauta on 7.2.2016.
//  Copyright © 2016 Oskari Rauta. All rights reserved.
//

import UIKit
import CoreData
import Ensembles

class UIListController: UITableViewController, GTNotificationDelegate {

    var listItems : NSArray = NSArray()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "cloudDataDidDownload:", name:"DB_UPDATED", object:nil)
        
    }

    func displayNotification(msg: String) {
        let notification: GTNotification = GTNotification()
        notification.delegate = self
        notification.position = GTNotificationPosition.Top
        notification.animation = GTNotificationAnimation.Slide
        notification.backgroundColor = UIColor.darkGrayColor()
        notification.tintColor = UIColor.whiteColor()
        notification.blurEnabled = false
        notification.message = msg
        GTNotificationManager.sharedInstance.showNotification(notification)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func updateItems() {
        let fetchRequest = NSFetchRequest(entityName: "Values")
        var resultArray : NSArray? = nil

        fetchRequest.predicate = NSPredicate(format: "initial == %@", NSNumber(bool: false))
        
        do {
            resultArray = try CoreDataStack.defaultStack.managedObjectContext.executeFetchRequest(fetchRequest)
        } catch {
            return
        }

        if resultArray != nil {
            self.listItems = resultArray!
        }
        
    }
    
    override func viewDidAppear(animated: Bool) {
        self.displayNotification("App started")
    }
    
    override func viewWillAppear(animated: Bool) {
        self.updateItems()
    }

    override func viewDidDisappear(animated: Bool) {
        self.listItems = NSArray()
    }
    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.listItems.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: nil)
        let value = self.listItems.objectAtIndex(indexPath.row) as! Value
        cell.textLabel!.text = value.name
        cell.detailTextLabel!.text = value.value
        return cell
    }

    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            CoreDataStack.defaultStack.managedObjectContext.deleteObject(self.listItems.objectAtIndex(indexPath.row) as! Value)
            CoreDataStack.defaultStack.saveContext()
            CoreDataStack.defaultStack.syncWithCompletion(nil)
            self.updateItems()
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func refreshList(sender: AnyObject) {
        CoreDataStack.defaultStack.syncWithCompletion(nil)
        let itemCount = self.listItems.count
        self.updateItems()
        if itemCount != self.listItems.count {
            self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
        }
    }
    
    @IBAction func addNew(sender: AnyObject) {

        if self.tableView.editing {
            self.tableView.setEditing(false, animated: true)
        }
        
        self.tableView.beginUpdates()
        let value : Value = NSEntityDescription.insertNewObjectForEntityForName("Values", inManagedObjectContext: CoreDataStack.defaultStack.managedObjectContext) as! Value
        value.name = NSUUID().UUIDString
        value.value = NSUUID().UUIDString
        value.initial = NSNumber(bool: false)
        CoreDataStack.defaultStack.saveContext()
        CoreDataStack.defaultStack.syncWithCompletion(nil)
        self.updateItems()
        self.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: self.listItems.count-1, inSection: 0)], withRowAnimation: .Automatic)
        self.tableView.endUpdates()

    }

    @IBAction func editTable(sender: AnyObject) {
        self.tableView.setEditing(!self.tableView.editing, animated: true)
    }
    
    func cloudDataDidDownload(notif: NSNotification) {
        NSLog("Refreshing view")
        
        let itemCount = self.listItems.count
        self.updateItems()
        if itemCount != self.listItems.count {
            self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
        }
        
        self.displayNotification("Items updated from iCloud")
    }
    
    func notificationFontForMessageLabel(notification: GTNotification) -> UIFont {
        return UIFont.boldSystemFontOfSize(13.0)
    }
    
}
