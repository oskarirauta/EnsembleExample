//
//  CoreDataStack.swift
//  SeamDemo
//
//  Created by Nofel Mahmood on 12/08/2015.
//  Copyright © 2015 CloudKitSpace. All rights reserved.
//

import UIKit
import CoreData
import Ensembles

class CoreDataStack: NSObject, CDEPersistentStoreEnsembleDelegate {
    
    static let defaultStack = CoreDataStack()

    var ensemble : CDEPersistentStoreEnsemble? = nil
    var cloudFileSystem : CDEICloudFileSystem? = nil
    
    // MARK: - Core Data stack

    lazy var storeName : String = {
        return NSBundle.mainBundle().objectForInfoDictionaryKey(kCFBundleNameKey as String) as! String
    }()
    
    lazy var sqlName : String = {
        return self.storeName + ".sqlite"
    }()
    
    lazy var icloudStoreName : String = {
        return self.storeName + "CloudStore"
    }()

    lazy var storeDescription : String = {
        return "Core data stack of " + self.storeName
    }()
    
    lazy var iCloudAppID : String = {
        return "iCloud." + NSBundle.mainBundle().bundleIdentifier!
    }()

    lazy var modelURL : NSURL = {
        return NSBundle.mainBundle().URLForResource(self.storeName, withExtension: "momd")!
    }()

    lazy var storeDirectoryURL : NSURL = {
        var directoryURL : NSURL? = nil
        do {
            try directoryURL = NSFileManager.defaultManager().URLForDirectory(NSSearchPathDirectory.ApplicationSupportDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true)
            directoryURL = directoryURL!.URLByAppendingPathComponent(NSBundle.mainBundle().bundleIdentifier!, isDirectory: true)
        } catch {
            NSLog("Unresolved error: Application's document directory is unreachable")
            abort()
        }
        return directoryURL!
    }()
    
    lazy var storeURL : NSURL = {
        return self.storeDirectoryURL.URLByAppendingPathComponent(self.sqlName)
//       return self.applicationDocumentsDirectory.URLByAppendingPathComponent(self.sqlName)
    }()
    
    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.dprados.CoreDataSpike" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource(self.storeName, withExtension: "momd")
        return NSManagedObjectModel(contentsOfURL: modelURL!)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store

        let coordinator : NSPersistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        
        var options = [NSObject: AnyObject]()
        options[NSMigratePersistentStoresAutomaticallyOption] = NSNumber(bool: true)
        options[NSInferMappingModelAutomaticallyOption] = NSNumber(bool: true)
        
        do {
            try NSFileManager.defaultManager().createDirectoryAtURL(self.storeDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            NSLog("Unresolved error: local database storage position is unavailable.")
            abort()
        }
        
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: self.storeURL, options: options)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = "There was an error creating or loading the application's saved data."
            dict[NSUnderlyingErrorKey] = error as? NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        return managedObjectContext
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }
    
    static func save() {
        CoreDataStack.defaultStack.saveContext()
    }
    
    func enableEnsemble() {
        CoreDataStack.defaultStack.cloudFileSystem = CDEICloudFileSystem(ubiquityContainerIdentifier: nil)
        CoreDataStack.defaultStack.ensemble = CDEPersistentStoreEnsemble(ensembleIdentifier: self.storeName, persistentStoreURL: self.storeURL, managedObjectModelURL: self.modelURL, cloudFileSystem: CoreDataStack.defaultStack.cloudFileSystem)
        CoreDataStack.defaultStack.ensemble!.delegate = CoreDataStack.defaultStack
    }
    
    func persistentStoreEnsemble(ensemble: CDEPersistentStoreEnsemble!, didSaveMergeChangesWithNotification notification: NSNotification!) {
        CoreDataStack.defaultStack.managedObjectContext.performBlockAndWait({ () -> Void in
            CoreDataStack.defaultStack.managedObjectContext.mergeChangesFromContextDidSaveNotification(notification)
        })
        if notification != nil {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.02 * Double(NSEC_PER_MSEC))), dispatch_get_main_queue(), {
                NSLog("Database was updated from iCloud")
                CoreDataStack.defaultStack.saveContext()
                NSNotificationCenter.defaultCenter().postNotificationName("DB_UPDATED", object: nil)
            })
        }
    }
    
    func persistentStoreEnsemble(ensemble: CDEPersistentStoreEnsemble!, globalIdentifiersForManagedObjects objects: [AnyObject]!) -> [AnyObject]! {
        NSLog("%@", (objects as NSArray).valueForKeyPath("uniqueIdentifier") as! [AnyObject])
        return (objects as NSArray).valueForKeyPath("uniqueIdentifier") as! [AnyObject]
    }
    
    func syncWithCompletion(completion: (() -> Void)!) {

        if CoreDataStack.defaultStack.ensemble!.leeched {
            CoreDataStack.defaultStack.ensemble!.mergeWithCompletion({ (error:NSError?) -> Void in
                if error != nil && error!.code != 103 {
                    NSLog("Error in merge: %@", error!)
                } else if error != nil && error!.code == 103 {
                    self.performSelector("syncWithCompletion:", withObject: nil, afterDelay: 1.0)
                } else {
                    if completion != nil {
                        completion()
                    }
                }
            })
        } else {
            CoreDataStack.defaultStack.ensemble!.leechPersistentStoreWithCompletion({ (error:NSError?) -> Void in
                if error != nil && error!.code != 103 {
                    NSLog("Error in leech: %@", error!)
                } else if error != nil && error!.code == 103 {
                    self.performSelector("syncWithCompletion:", withObject: nil, afterDelay: 1.0)
                } else {
                    self.performSelector("syncWithCompletion:", withObject: nil, afterDelay: 1.0)
                    if completion != nil {
                        completion()
                    }
                }
            })
        }
        
    }

}
