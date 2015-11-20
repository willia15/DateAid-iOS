//
//  DatesTableVC.swift
//  DateAid
//
//  Created by Aaron Williamson on 5/7/15.
//  Copyright (c) 2015 Aaron Williamson. All rights reserved.
//

import UIKit
import CoreData

protocol ReloadDatesTableDelegate {
    func reloadTableView()
}

class DatesTableVC: UITableViewController {
    
// MARK: PROPERTIES
    
    var menuIndexPath: Int?
    var typePredicate: NSPredicate?
    var fetchedResults: [Date]?
    var managedContext = CoreDataStack().managedObjectContext
    var sidebarMenuOpen: Bool?
    
    // Search
    var filteredResults = [Date]()
    var resultSearchController = UISearchController()
    
    var typeColorForNewDate = UIColor.birthdayColor() // nil menu index path defaults to birthday color
    let colorForType = ["birthday": UIColor.birthdayColor(), "anniversary": UIColor.anniversaryColor(), "custom": UIColor.customColor()]
    let typeStrings = ["dates", "birthdays", "anniversaries", "custom"]
    
// MARK: OUTLETS
    
    @IBOutlet weak var menuBarButtonItem: UIBarButtonItem!
    
// MARK: VIEW SETUP
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.logEvents(forString: "Main View")
        setAndPerformFetchRequest()
        registerDateCellNib()
        addRevealVCGestureRecognizers()
        configureNavigationBar()
        configureTabBar()
        addSearchBar()
        tableView.tableFooterView = UIView(frame: CGRectZero)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        addSearchBar()
        setAndPerformFetchRequest()
    }
    
    override func viewWillDisappear(animated: Bool) {
        resultSearchController.active = false
        super.viewWillDisappear(true)
    }
    
// MARK: HELPERS
    
    func addSearchBar() {
        resultSearchController = UISearchController(searchResultsController: nil)
        resultSearchController.searchResultsUpdater = self
        resultSearchController.dimsBackgroundDuringPresentation = false
        resultSearchController.searchBar.sizeToFit()
        resultSearchController.searchBar.tintColor = UIColor.birthdayColor()
        definesPresentationContext = true
        tableView.tableHeaderView = resultSearchController.searchBar
        tableView.reloadData()
    }
    
    func setAndPerformFetchRequest() {
        let datesFetch = NSFetchRequest(entityName: "Date")
        let datesInOrder = NSSortDescriptor(key: "equalizedDate", ascending: true)
        let namesInOrder = NSSortDescriptor(key: "name", ascending: true)
        datesFetch.sortDescriptors = [datesInOrder, namesInOrder]
        datesFetch.predicate = typePredicate
        
        do { fetchedResults = try managedContext.executeFetchRequest(datesFetch) as? [Date]
            if fetchedResults!.count > 0 {
                for date in fetchedResults! {
                    if date.equalizedDate < NSDate().formatDateIntoString() {
                        fetchedResults!.removeAtIndex(0)
                        fetchedResults!.append(date)
                    }
                }
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    func addRevealVCGestureRecognizers() {
        revealViewController().panGestureRecognizer()
        revealViewController().tapGestureRecognizer()
    }
    
    func registerDateCellNib() {
        let dateCellNib = UINib(nibName: "DateCell", bundle: nil)
        tableView.registerNib(dateCellNib, forCellReuseIdentifier: "DateCell")
    }
    
    func configureNavigationBar() {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "MMMM d"
        title = formatter.stringFromDate(NSDate())
        if let navBar = navigationController?.navigationBar {
            navBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor(), NSFontAttributeName: UIFont(name: "AvenirNext-Bold", size: 23)!]
            navBar.barTintColor = UIColor.birthdayColor()
            navBar.tintColor = UIColor.whiteColor()
        }
        menuBarButtonItem.target = self.revealViewController()
        menuBarButtonItem.action = Selector("revealToggle:")
    }
    
    func configureTabBar() {
        if let tabBar = tabBarController?.tabBar {
            tabBar.barTintColor = UIColor.birthdayColor()
            tabBar.tintColor = UIColor.whiteColor()
            for item in tabBar.items! {
                if let image = item.image {
                    item.image = image.imageWithColor(UIColor.whiteColor()).imageWithRenderingMode(.AlwaysOriginal)
                }
            }
        }
    }
    
    func addNoDatesLabel() {
        if resultSearchController.active == false {
            let label = UILabel(frame: CGRectMake(0, 0, tableView.bounds.size.width, tableView.bounds.size.height))
            if let indexPath = menuIndexPath {
                label.text = "No \(typeStrings[indexPath]) added"
            } else {
                label.text = "No dates found"
            }
            label.font = UIFont(name: "AvenirNext-Bold", size: 25)
            label.textColor = UIColor.lightGrayColor()
            label.textAlignment = .Center
            label.sizeToFit()
            tableView.backgroundView = label
            tableView.separatorStyle = .None
        }
    }
    
// MARK: SEGUE
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "DateDetailsVC" {
            let dateDetailsVC = segue.destinationViewController as! DateDetailsVC
            if resultSearchController.active == true {
                dateDetailsVC.dateObject = filteredResults[tableView.indexPathForSelectedRow!.row]
            } else {
                dateDetailsVC.dateObject = fetchedResults![tableView.indexPathForSelectedRow!.row]
            }
            dateDetailsVC.managedContext = managedContext
            dateDetailsVC.reloadDatesTableDelegate = self
        }
        if segue.identifier == "AddDateVC" {
            let addDateVC = segue.destinationViewController as! AddDateVC
            addDateVC.isBeingEdited = false
            addDateVC.managedContext = managedContext
            addDateVC.incomingColor = typeColorForNewDate
            addDateVC.reloadDatesTableDelegate = self
        }
    }
}

extension DatesTableVC { // UITableViewDataSource
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if resultSearchController.active {
            if filteredResults.count == 0 {
                addNoDatesLabel()
            }
            return filteredResults.count
        } else {
            if fetchedResults!.count == 0 {
                addNoDatesLabel()
            }
            return fetchedResults!.count
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let dateCell = tableView.dequeueReusableCellWithIdentifier("DateCell", forIndexPath: indexPath) as! DateCell
        let date: Date
        
        if resultSearchController.active == true {
            date = filteredResults[indexPath.row]
            if let abbreviatedName = date.abbreviatedName, let readableDate = date.date?.readableDate() {
                dateCell.name = date.type! == "birthday" ? abbreviatedName : date.name!
                dateCell.date = readableDate
            }
            
            if let colorIndex = menuIndexPath {
                switch colorIndex {
                case 1:
                    dateCell.nameLabel.textColor = colorForType["birthday"]
                case 2:
                    dateCell.nameLabel.textColor = colorForType["anniversary"]
                case 3:
                    dateCell.nameLabel.textColor = colorForType["custom"]
                default:
                    if let dateType = date.type {
                        dateCell.nameLabel.textColor = colorForType[dateType]
                    }
                }
            } else {
                if let dateType = date.type {
                    dateCell.nameLabel.textColor = colorForType[dateType]
                }
            }
            
        } else if let results = fetchedResults {
            date = results[indexPath.row]
            if let abbreviatedName = date.abbreviatedName, let readableDate = date.date?.readableDate() {
                dateCell.name = date.type! == "birthday" ? abbreviatedName : date.name!
                dateCell.date = readableDate
            }
            
            if let colorIndex = menuIndexPath {
                switch colorIndex {
                case 1:
                    dateCell.nameLabel.textColor = colorForType["birthday"]
                case 2:
                    dateCell.nameLabel.textColor = colorForType["anniversary"]
                case 3:
                    dateCell.nameLabel.textColor = colorForType["custom"]
                default:
                    if let dateType = date.type {
                        dateCell.nameLabel.textColor = colorForType[dateType]
                    }
                }
            } else {
                if let dateType = date.type {
                    dateCell.nameLabel.textColor = colorForType[dateType]
                }
            }
        }
        
        return dateCell
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        if editingStyle == .Delete {
            self.logEvents(forString: "Swiped to Delete")
            let dateToDelete = fetchedResults![indexPath.row]
            managedContext.deleteObject(dateToDelete)
            fetchedResults?.removeAtIndex(indexPath.row)
            
            do { try managedContext.save()
            } catch let error as NSError {
                print(error.localizedDescription)
            }
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        }
        
    }
}

extension DatesTableVC { // UITableViewDelegate
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 80
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        resultSearchController.searchBar.hidden = true
        self.performSegueWithIdentifier("DateDetailsVC", sender: self)
    }
    
}

extension DatesTableVC: ReloadDatesTableDelegate {

    func reloadTableView() {
        setAndPerformFetchRequest()
        tableView.reloadData()
    }
    
}

extension DatesTableVC: UISearchResultsUpdating {
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        filteredResults.removeAll(keepCapacity: false)
        let searchPredicate = NSPredicate(format: "name CONTAINS %@", searchController.searchBar.text!)
        let array = (fetchedResults! as NSArray).filteredArrayUsingPredicate(searchPredicate)
        filteredResults = array as! [Date]
        tableView.reloadData()
    }
    
}

//extension DatesTableVC: SWRevealViewControllerDelegate {
//
//    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
//        return sidebarMenuOpen == true ? nil : indexPath
//    }
//
//    func revealController(revealController: SWRevealViewController!,  willMoveToPosition position: FrontViewPosition) {
//        if position == .Left {
//             self.view.userInteractionEnabled = true
//            sidebarMenuOpen = false
//        } else {
//             self.view.userInteractionEnabled = false
//            sidebarMenuOpen = true
//        }
//    }
//
//    func revealController(revealController: SWRevealViewController!,  didMoveToPosition position: FrontViewPosition){
//        if position == .Left {
//             self.view.userInteractionEnabled = true
//            sidebarMenuOpen = false
//        } else {
//             self.view.userInteractionEnabled = false
//            sidebarMenuOpen = true
//        }
//    }
//
//}
