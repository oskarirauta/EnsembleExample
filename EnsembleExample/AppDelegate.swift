//
//  AppDelegate.swift
//  EnsembleExample
//
//  Created by Oskari Rauta on 7.2.2016.
//  Copyright © 2016 Oskari Rauta. All rights reserved.
//

import UIKit
import CoreData
import Ensembles

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        let _ : CoreDataStack = CoreDataStack.defaultStack
        
//        Value.ValueTypeInManagedObjectContext(CoreDataStack.defaultStack.managedObjectContext)
        CoreDataStack.defaultStack.saveContext()
        
        CoreDataStack.defaultStack.enableEnsemble()

        // Listen for local saves, and trigger merges
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "localSaveOccured:", name: CDEMonitoredManagedObjectContextDidSaveNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "cloudDataDidDownload:", name:CDEICloudFileSystemDidDownloadFilesNotification, object:nil)
        
        CoreDataStack.defaultStack.syncWithCompletion(nil);
        
        // Override point for customization after application launch.
        
        NSLog("App started")
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.

        let identifier : UIBackgroundTaskIdentifier = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler(nil)
        CoreDataStack.defaultStack.saveContext()
        CoreDataStack.defaultStack.syncWithCompletion( { () -> Void in
            UIApplication.sharedApplication().endBackgroundTask(identifier)
        })
        
    }

    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        NSLog("Received a remove notification")
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        CoreDataStack.defaultStack.syncWithCompletion(nil)
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        CoreDataStack.defaultStack.syncWithCompletion(nil)
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        CoreDataStack.defaultStack.saveContext()
    }

    func localSaveOccured(notif: NSNotification) {
        NSLog("Local save occured")
        CoreDataStack.defaultStack.syncWithCompletion(nil)
    }
    
    func cloudDataDidDownload(notif: NSNotification) {
        NSLog("Cloud data did download")
        CoreDataStack.defaultStack.syncWithCompletion(nil)
    }    
    
}

