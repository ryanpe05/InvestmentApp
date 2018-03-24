//
//  SecondViewController.swift
//  InvestmentAppFinal
//
//  Created by Ryan Peck on 6/13/17.
//  Copyright © 2017 Ryan Peck. All rights reserved.
//

import UIKit
import Foundation
import CoreData

class SecondViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var currencyReturn: UILabel!
    @IBOutlet weak var currencyReturnAmount: UILabel!
    
    @IBOutlet weak var CurrencyTable: UITableView!
    @IBOutlet weak var currencyTitle: UILabel!
    @IBOutlet weak var addCurrency: UIButton!
    
    @IBAction func addCurrency(_ sender: UIButton!) {
        print("button pressed")
        self.performSegue(withIdentifier: "AddInvestmentPress", sender: self)
    }
    
    var percentReturn = 0.0
    var dollarReturn = 0.0
    var isCoin = false
    var testItems = [[String]]()
    var priceArr = [Double]()
    var BTCrate = 0.0 //the bitcoin to USD exchange rate
    var rateTable = [[String]]() //array of exchange rates
    var currentPrice: Double = 0.0
    var isDone = 0
    var isDoneStock = 0
    var name = "error"
    var dollarsSpent = 0.0
    var initials = "ERR"
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        super.viewWillAppear(animated)
        // Do any additional setup after loading the view, typically from a nib.
        //totalTitle.center.x = self.view.center.x
        self.CurrencyTable.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        self.CurrencyTable.dataSource = self
        self.CurrencyTable.delegate = self
        self.CurrencyTable.rowHeight = UITableViewAutomaticDimension;
        self.CurrencyTable.estimatedRowHeight = 44.0;
        
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        
        // fetch the investments from core data
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Investments")
        self.testItems = [[String]]()
        do{
            let investments = try managedContext.fetch(fetchRequest)
            for investment in investments{
                name = investment.value(forKeyPath: "name") as! String
                initials = investment.value(forKeyPath: "initials") as! String
                let quantity = investment.value(forKeyPath: "quantity") as! Double
                let price = investment.value(forKeyPath: "initPrice") as! Double
                self.isCoin = investment.value(forKeyPath: "coin") as! Bool
                if isCoin{
                    self.dollarsSpent = self.dollarsSpent + (price*quantity)
                    apiCall()
                    let dollarPerformance = calculatePerformanceDollar(quant: quantity, initialPrice: price)
                    self.dollarReturn = Double(round(1000*(self.dollarReturn + dollarPerformance))/1000)
                    if(dollarReturn > 0){
                        currencyReturnAmount.textColor = UIColor.green
                    }
                    else{
                        currencyReturnAmount.textColor = UIColor.red
                    }
                    let percentPerformance = calculatePerformancePercent(quant: quantity, initialPrice: price)
                    self.percentReturn = Double(round(1000*(dollarReturn/dollarsSpent * 100))/1000)
                    if(percentReturn > 0){
                        currencyReturn.textColor = UIColor.green
                    }
                    else{
                        currencyReturn.textColor = UIColor.red
                    }
                    testItems.append([name,"\(Double(round(1000*dollarPerformance)/1000))","\(Double(round(1000*percentPerformance)/1000))"])
                    print("you purchased \(quantity) \(name) for \(price) dollars each")
                }
            }
        }
        catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        currencyReturn.text = "Percent Return: \(percentReturn)%"
        currencyReturnAmount.text = "Dollar Return: $\(dollarReturn)"
        if let navController = self.navigationController {
            navController.popViewController(animated: true)
        }
        self.CurrencyTable.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section : Int) -> Int{
        return testItems.count
    }
    
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        print(indexPath.row)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        let cell = CustomCell(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 75), title: testItems[indexPath.row][1])
        cell.cellLabel.text = testItems[indexPath.row][0]
        cell.detailCellLabel.text = "\(priceArr[indexPath.row])"
        if(testItems[indexPath.row][1].characters.first == "-"){
            testItems[indexPath.row][1].remove(at: testItems[indexPath.row][1].startIndex)
            cell.performance.textColor = UIColor.red
        }
        else{
            cell.performance.textColor = UIColor.green
        }
        cell.performance.text = "$\(testItems[indexPath.row][1])"
        if(testItems[indexPath.row][2].characters.first == "-"){
            testItems[indexPath.row][2].remove(at: testItems[indexPath.row][2].startIndex)
            cell.performancePercent.textColor = UIColor.red
        }
        else{
            cell.performancePercent.textColor = UIColor.green
        }
        cell.performancePercent.text = "\(testItems[indexPath.row][2])%"
        return cell
    }
    
    func calculatePerformancePercent(quant: Double, initialPrice: Double) -> Double{
        let totalCurrentPrice1 = currentPrice * quant
        let totalInitPrice1 = initialPrice * quant
        return (totalCurrentPrice1/totalInitPrice1)*100 - 100
    }
    
    func calculatePerformanceDollar(quant: Double, initialPrice: Double) -> Double{
        let totalCurrentPrice2 = currentPrice * quant
        let totalInitPrice2 = initialPrice * quant
        return totalCurrentPrice2 - totalInitPrice2
    }
    
    func apiCall(){
        print("calling API")
        self.isDone = 0
        //find exchange rates for all the coins
        let url = URL(string: "https://poloniex.com/public?command=returnTicker")
        let task = URLSession.shared.dataTask(with: url!) {(data, response, error) in
            let json = try? JSONSerialization.jsonObject(with: data!, options: []) as! [String: Any]
            let keys = Array(json!.keys)
            for key in keys{
                let start = key.startIndex
                let end = key.index(key.startIndex, offsetBy: 3)
                let range = start..<end
                if key.substring(with: range) == "BTC" {
                    if let currencyStruct = json![key] as? [String: Any]{
                        let lastRate = currencyStruct["last"] as? String
                        let start2 = key.index(key.startIndex, offsetBy: 4)
                        let end2 = key.endIndex
                        let range2 = start2..<end2
                        let currency = key.substring(with: range2)
                        self.rateTable.append([currency, lastRate!])
                    }
                }
            }
            self.isDone = self.isDone + 1
        }
        task.resume()
        
        //find the worth of BTC to convert to dollars
        print("coindesk API now")
        let url2 = URL(string: "https://api.coindesk.com/v1/bpi/currentprice/USD.json")
        let task2 = URLSession.shared.dataTask(with: url2!) {(data, response, error) in
            let json2 = try? JSONSerialization.jsonObject(with: data!, options: []) as! [String: Any]
            if let USDlayer1 = json2!["bpi"] as? [String: Any]{
                if let USDlayer2 = USDlayer1["USD"] as? [String: Any]{
                    if let rate = USDlayer2["rate"] as? String{
                        print(rate)
                        let temp = rate.replacingOccurrences(
                            of: ",",
                            with: "",
                            options: .literal,
                            range: nil)
                        self.BTCrate = Double(temp)!
                    }
                }
            }
            self.isDone = self.isDone + 1
            print(self.BTCrate)
        }
        task2.resume()
        
        while true{
            if self.isDone == 2 {
                currentPrice = calculateCost()
                print(currentPrice)
                priceArr.append(Double(round(1000*currentPrice)/1000))
                break
            }
        }
    }
    
    func calculateCost() -> Double{
        let sizeOfResults = self.rateTable.count
        for i in 0...sizeOfResults-1{
            if self.rateTable[i][0] == initials{
                self.currentPrice = Double(self.rateTable[i][1])! * self.BTCrate
                return currentPrice
            }
            else if initials == "BTC"{
                self.currentPrice = self.BTCrate
                return currentPrice
            }
        }
        return 0.0
    }
    
    class CustomCell: UITableViewCell {
        var cellLabel: UILabel!
        var detailCellLabel: UILabel!
        var performance: UILabel!
        var performancePercent: UILabel!
        
        init(frame: CGRect, title: String) {
            super.init(style: UITableViewCellStyle.default, reuseIdentifier: "cell")
            
            cellLabel = UILabel(frame: CGRect(x: 20, y: 0, width: 100.0, height: 20))
            detailCellLabel = UILabel(frame: CGRect(x: 30, y: 20, width: 200.0, height: 20))
            performance = UILabel(frame: CGRect(x: 200, y: 0, width: 150.0, height: 20))
            performancePercent = UILabel(frame: CGRect(x: 200, y: 20, width: 150.0, height: 20))
            addSubview(cellLabel)
            addSubview(detailCellLabel)
            addSubview(performance)
            addSubview(performancePercent)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
        }
    }
    
}
