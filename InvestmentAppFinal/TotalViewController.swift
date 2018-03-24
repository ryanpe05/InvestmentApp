//
//  TotalViewController.swift
//  InvestmentAppFinal
//
//  Created by Ryan Peck on 6/13/17.
//  Copyright © 2017 Ryan Peck. All rights reserved.
//
// alphavantage api key 3KIYFEI3Z8ANCHZW

import Foundation
import CoreData
import UIKit

class TotalViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var totValue: UILabel!
    @IBOutlet weak var resultsTable: UITableView!
    @IBOutlet weak var totalTitle: UILabel!
    @IBOutlet weak var totReturn: UILabel!
    
    @IBOutlet weak var totReturnAmount: UILabel!
    @IBOutlet weak var Day: UIButton!
    @IBOutlet weak var Month: UIButton!
    @IBOutlet weak var All: UIButton!
    @IBOutlet weak var Year: UIButton!
    
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
    var totValueNum = 0.0
    var repeatName = false
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // self.view.translatesAutoresizingMaskIntoConstraints = false
        // Do any additional setup after loading the view, typically from a nib.
        // totalTitle.center.x = self.view.center.x
        self.resultsTable.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        self.resultsTable.dataSource = self
        self.resultsTable.delegate = self
        self.resultsTable.rowHeight = UITableViewAutomaticDimension;
        self.resultsTable.estimatedRowHeight = 44.0;
        
        // constraints to help organize
        let horizontalConstraintMonth = NSLayoutConstraint(item: Month, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: NSLayoutAttribute.rightMargin, multiplier: 0.3, constant: 0)
        let horizontalConstraintDay = NSLayoutConstraint(item: Day, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: NSLayoutAttribute.rightMargin, multiplier: 0.125, constant: 0)
        let horizontalConstraintYear = NSLayoutConstraint(item: Year, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: NSLayoutAttribute.rightMargin, multiplier: 0.625, constant: 0)
        let horizontalConstraintAll = NSLayoutConstraint(item: All, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: NSLayoutAttribute.rightMargin, multiplier: 0.875, constant: 0)
        let verticalConstraintMonth = NSLayoutConstraint(item: Month, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: NSLayoutAttribute.centerY, multiplier: 1, constant: 200)
        let verticalConstraintDay = NSLayoutConstraint(item: Day, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: NSLayoutAttribute.centerY, multiplier: 1, constant: 200)
        let verticalConstraintYear = NSLayoutConstraint(item: Year, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: NSLayoutAttribute.centerY, multiplier: 1, constant: 200)
        let verticalConstraintAll = NSLayoutConstraint(item: All, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: NSLayoutAttribute.centerY, multiplier: 1, constant: 200)
        let widthConstraintMonth = NSLayoutConstraint(item: Month, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1, constant: 50)
        let widthConstraintDay = NSLayoutConstraint(item: Day, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1, constant: 50)
        let widthConstraintYear = NSLayoutConstraint(item: Year, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1, constant: 50)
        let widthConstraintAll = NSLayoutConstraint(item: All, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1, constant: 50)
        let heightConstraintMonth = NSLayoutConstraint(item: Month, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1, constant: 50)
        let heightConstraintDay = NSLayoutConstraint(item: Day, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1, constant: 50)
        let heightConstraintYear = NSLayoutConstraint(item: Year, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1, constant: 50)
        let heightConstraintAll = NSLayoutConstraint(item: All, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1, constant: 50)

        view.addConstraints([horizontalConstraintMonth, verticalConstraintMonth, widthConstraintMonth, heightConstraintMonth])
        view.addConstraints([horizontalConstraintDay, verticalConstraintDay, widthConstraintDay, heightConstraintDay])
        view.addConstraints([horizontalConstraintYear, verticalConstraintYear, widthConstraintYear, heightConstraintYear])
        view.addConstraints([horizontalConstraintAll, verticalConstraintAll, widthConstraintAll, heightConstraintAll])
        Month.translatesAutoresizingMaskIntoConstraints = false
        Year.translatesAutoresizingMaskIntoConstraints = false
        Day.translatesAutoresizingMaskIntoConstraints = false
        All.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(Month)
        view.addSubview(Year)
        view.addSubview(Day)
        view.addSubview(All)
        
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
            }
        
        // fetch the investments from core data
        self.testItems = [[String]]()
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Investments")
        do{
            let investments = try managedContext.fetch(fetchRequest)
            priceArr = [Double]()
            for investment in investments{
                repeatName = false
                name = investment.value(forKeyPath: "name") as! String
                initials = investment.value(forKeyPath: "initials") as! String
                let quantity = investment.value(forKeyPath: "quantity") as! Double
                let price = investment.value(forKeyPath: "initPrice") as! Double
                self.isCoin = investment.value(forKeyPath: "coin") as! Bool
                self.dollarsSpent = self.dollarsSpent + (price*quantity)
                apiCall()
                let dollarPerformance = calculatePerformanceDollar(quant: quantity, initialPrice: price)
                self.dollarReturn = Double(round(100*(self.dollarReturn + dollarPerformance))/100)
                if(dollarReturn > 0){
                    totReturnAmount.textColor = UIColor.green
                }
                else{
                    totReturnAmount.textColor = UIColor.red
                }
                let percentPerformance = calculatePerformancePercent(quant: quantity, initialPrice: price)
                self.percentReturn = Double(round(100*(dollarReturn/dollarsSpent * 100))/100)
                if(percentReturn > 0){
                    totReturn.textColor = UIColor.green
                }
                else{
                    totReturn.textColor = UIColor.red
                }
                for i in 0 ..< testItems.count{
//                    if name == testItems[i][0]{
//                        print("The names match")
//                        print(name)
//                        print(testItems[i])
//                        self.testItems[i][1] = String(Double(testItems[i][1])! + Double(round(100*dollarPerformance)/100))
//                        let numerator = currentPrice*(Double(testItems[i][4])!+quantity)
//                        let denominator = Double(testItems[i][3])!*Double(testItems[i][4])!+quantity*price
//                        self.testItems[i][2] = String(Double(testItems[i][2])! + numerator/denominator)
//                        repeatName = true
//                    }
                }
                if !repeatName{
                    testItems.append([name,"\(Double(round(100*dollarPerformance)/100))","\(Double(round(100*percentPerformance)/100))"])
                    priceArr.append(Double(round(1000*currentPrice)/1000))
                    print(testItems)
                    print(priceArr)
                }
                //print("you purchased \(quantity) \(name) for \(price) dollars each")
                self.totValueNum = self.totValueNum + dollarsSpent + dollarPerformance
            }
        }
        catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        self.totValueNum = Double(round(100*totValueNum)/100)
        totReturn.text = "Percent Return: \(percentReturn)%"
        totReturnAmount.text = "Dollar Return: $\(dollarReturn)"
        totValue.text = "Portfolio Value: $\(totValueNum)"
        self.resultsTable.reloadData()
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
        if isCoin {
            print("coin API")
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
                    break
                }
            }
        }
        else{
            print("stock API")
            self.isDoneStock = 0
            let url3 = URL(string: "https://www.alphavantage.co/query?function=TIME_SERIES_INTRADAY&symbol=" + initials + "&interval=1min&apikey=3KIYFEI3Z8ANCHZW")
            let task3 = URLSession.shared.dataTask(with: url3!) {(data, response, error) in
                let json3 = try? JSONSerialization.jsonObject(with: data!, options: []) as! [String: Any]
                if let dataObject = json3!["Time Series (1min)"] as? [String: Any]{
                    let keys3 = Array(dataObject.keys)
                    if let mostRecent = dataObject[keys3[0]] as? [String: Any]{
                        print(mostRecent)
                        let keys4 = Array(mostRecent.keys)
                        print(keys4)
                        if let close = mostRecent["4. close"]{
                            print(close)
                            self.currentPrice = Double(close as! String)!
                        }
                        else{
                            print("failure")
                        }
                    }
                    else{
                        print("failed on mostRecent")
                    }
                }
                else{
                    print("failed on json conversion")
                }
                self.isDoneStock = self.isDoneStock + 1
            }
            task3.resume()
            
            while true{
                if self.isDoneStock == 1 {
                    break
                }
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
