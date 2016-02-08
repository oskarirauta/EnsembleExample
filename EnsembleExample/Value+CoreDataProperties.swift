//
//  Value+CoreDataProperties.swift
//  EnsembleExample
//
//  Created by Oskari Rauta on 7.2.2016.
//  Copyright © 2016 Oskari Rauta. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Value {

    @NSManaged var uniqueIdentifier: String?
    @NSManaged var name: String?
    @NSManaged var value: String?
    @NSManaged var initial: NSNumber?

}
