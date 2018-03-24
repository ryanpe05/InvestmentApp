//
//  AddViewController.swift
//  InvestmentAppFinal
//
//  Created by Ryan Peck on 7/1/17.
//  Copyright © 2017 Ryan Peck. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class AddViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var SearchBar: UISearchBar!

    class TickerMO: NSManagedObject {
        @NSManaged var name: String
        @NSManaged var initials: String
    }
    @IBOutlet weak var backButtonPress: UIBarButtonItem!
    @IBAction func backButton(_ sender: UIBarButtonItem!) {
        print("going back")
        self.performSegue(withIdentifier: "BackButtonPress", sender: self)
    }

    var startPoint = 0 //initial index for results
    var newWord = false //if we have not changed words, remember indexes, for speed
    var inSearchMode = false //are we searching?
    var tickerArr = [[String]]() //holds tickers after fetching from core data
    var tickers: [NSManagedObject] = [] //the actual ticker object
    var searchResults = [[String]]() //the results of our search
    
    override func viewDidLoad() {
        print("we are in the addviewcontroller")
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        // searchController.searchResultsUpdater = self
        //definesPresentationContext = true
        self.tableView.tableHeaderView = self.SearchBar
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.rowHeight = 55;
        self.SearchBar.delegate = self
        self.SearchBar.returnKeyType = UIReturnKeyType.done
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        //1
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        
        let managedContext =
            appDelegate.persistentContainer.viewContext
        //2
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Ticker")
        //3
        do {
            tickers = try managedContext.fetch(fetchRequest)
            var tickerName = String()
            var tickerInitials = String()
            for ticker in tickers{
                tickerName = ticker.value(forKeyPath: "name") as! String
                tickerInitials = ticker.value(forKeyPath: "initials") as! String
                var currentTicker = [String]()
                currentTicker.append(tickerName)
                currentTicker.append(tickerInitials)
                tickerArr.append(currentTicker)
            }
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func filterContentForSearchText(searchText: String) {
        let sizeOfResults = tickerArr.count
        print(sizeOfResults)
        print(searchText)
        searchResults.removeAll()
        for i in 0...sizeOfResults-1{
            if tickerArr[i][0].lowercased().range(of: searchText.lowercased()) != nil{
                searchResults.append(tickerArr[i])
            }
            else if tickerArr[i][1].lowercased().range(of: searchText.lowercased()) != nil{
                searchResults.append(tickerArr[i])
            }
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if inSearchMode {
            
            return searchResults.count
        }
        
        return searchResults.count
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        if SearchBar.text == nil || SearchBar.text == "" {
            
            inSearchMode = false
            view.endEditing(true)
            tableView.reloadData()
            
        } else {
            
            inSearchMode = true
            print("Searching")
            self.filterContentForSearchText(searchText: SearchBar.text!)
            tableView.reloadData()
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let currentCell = tableView.cellForRow(at: indexPath)! as! CustomCell
        let initials = (currentCell.cellLabel?.text)! as String
        let name = (currentCell.detailCellLabel?.text)! as String
        tableView.deselectRow(at: indexPath, animated: true)
        saveRecentClick(name: name,initials: initials)
        self.performSegue(withIdentifier: "AddEquityForm", sender: self)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        let cell = CustomCell(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 75), title: searchResults[indexPath.row][0])
        cell.cellLabel?.text = searchResults[indexPath.row][1]
        cell.detailCellLabel?.text = searchResults[indexPath.row][0]
        return cell
    }
    
    class CustomCell: UITableViewCell {
        var cellLabel: UILabel!
        var detailCellLabel: UILabel!
        
        init(frame: CGRect, title: String) {
            super.init(style: UITableViewCellStyle.default, reuseIdentifier: "cell")
            
            cellLabel = UILabel(frame: CGRect(x: 20, y: 0, width: 100.0, height: 40))
            detailCellLabel = UILabel(frame: CGRect(x: 20, y: 30, width: 200.0, height: 20))
            addSubview(cellLabel)
            addSubview(detailCellLabel)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
        }
    }
    
    func saveRecentClick(name: String, initials: String) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let entity = NSEntityDescription.entity(forEntityName: "Recent",
                                                in: managedContext)!
        
        let recent = NSManagedObject(entity: entity,
                                     insertInto: managedContext)
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Recent")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try managedContext.execute(deleteRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        recent.setValue(false, forKeyPath: "coin")
        recent.setValue(name, forKeyPath: "name")
        recent.setValue(initials, forKeyPath: "initials")
        
        do {
            try managedContext.save()
            print(recent.value(forKey: "name") as! String)
            
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
}

