//
//  AddCurrencyViewController.swift
//  InvestmentAppFinal
//
//  Created by Ryan Peck on 7/29/17.
//  Copyright © 2017 Ryan Peck. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class AddCurrencyViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var SearchBar: UISearchBar!
    
    var currArr: [[String]] = [["BTC", "Bitcoin"],["ETH", "Ethereum"],["LTC", "Litecoin"],["XRP", "Ripple"],
    ["DBG", "DigiByte"],["DASH", "Dash"],["XBC", "BitcoinPlus"],["STRAT", "Stratis"],
    ["ETC", "Ethereum Classic"],["BTS", "BitShares"],["XMR", "Monero"],["STR", "Stellar"],
    ["SC", "Siacoin"],["XEM", "NEM"],["BTCD", "BitcoinDark"],["FCT", "Factom"],
    ["ZEC", "Zcash"],["VIA", "Viacoin"],["DOGE", "Dogecoin"],["DCR", "Decred"],
    ["MAID", "MaidSafeCoin"],["HUC", "Huntercoin"],["GNT", "Golem"],["STEEM", "STEEM"],
    ["LSK", "Lisk"],["GAME", "GameCredits"],["NXT", "NXT"],["LBC", "LBRY Credits"],
    ["BLK", "BlackCoin"],["POT", "PotCoin"],["SYS", "Syscoin"],["NMC", "Namecoin"],
    ["BCN", "Bytecoin"],["PPC", "Peercoin"],["EMC2", "Einsteinium"],["ARDR", "Ardor"],
    ["AMP", "Synereo AMP"],["REP", "Augur"],["BURST", "Burst"],["XCP", "Counterparty"],
    ["GNO", "Gnosis"],["CLAM", "CLAMS"],["GRC", "Gridcoin Research"]]
    
    class RecentMO: NSManagedObject {
        @NSManaged var coin: Bool
        @NSManaged var name: String
    }
    
    @IBOutlet weak var backButtonPress: UIBarButtonItem!
    @IBAction func backButton(_ sender: UIBarButtonItem!) {
        print("going back")
        self.performSegue(withIdentifier: "BackButtonPress", sender: self)
    }

    var startPoint = 0 //initial index for results
    var newWord = false //if we have not changed words, remember indexes, for speed
    var inSearchMode = false //are we searching?
    var searchResults = [[String]]() //the results of our search

    override func viewDidLoad() {
        print("we are in the addcurrencyviewcontroller")
        super.viewDidLoad()
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
        
        
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func filterContentForSearchText(searchText: String) {
        let sizeOfResults = currArr.count
        print(sizeOfResults)
        print(searchText)
        searchResults.removeAll()
        for i in 0...sizeOfResults-1{
            if currArr[i][0].lowercased().range(of: searchText.lowercased()) != nil{
                searchResults.append(currArr[i])
            }
            else if currArr[i][1].lowercased().range(of: searchText.lowercased()) != nil{
                searchResults.append(currArr[i])
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
        self.performSegue(withIdentifier: "AddCurrencyForm", sender: self)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        let cell = CustomCell(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 75), title: searchResults[indexPath.row][0])
        cell.cellLabel?.text = searchResults[indexPath.row][0]
        cell.detailCellLabel?.text = searchResults[indexPath.row][1]
        return cell
    }

    class CustomCell: UITableViewCell {
        var cellButton: UIButton!
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
        recent.setValue(true, forKeyPath: "coin")
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
