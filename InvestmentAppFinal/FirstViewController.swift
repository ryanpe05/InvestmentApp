//
//  FirstViewController.swift
//  InvestmentAppFinal
//
//  Created by Ryan Peck on 6/13/17.
//  Copyright © 2017 Ryan Peck. All rights reserved.
//

import UIKit
import Foundation
import CoreData

class FirstViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var stockReturn: UILabel!
    @IBOutlet weak var stockReturnAmount: UILabel!
    @IBOutlet weak var StockTableView: UITableView!
    
    @IBOutlet weak var stockTitle: UILabel!
    @IBOutlet weak var AddButton: UIButton!
    @IBAction func addButton(_ sender: UIButton!) {
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
        self.StockTableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        self.StockTableView.dataSource = self
        self.StockTableView.delegate = self
        self.StockTableView.rowHeight = UITableViewAutomaticDimension;
        self.StockTableView.estimatedRowHeight = 44.0;
        
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
                if !isCoin{
                    self.dollarsSpent = self.dollarsSpent + (price*quantity)
                    apiCall()
                    let dollarPerformance = calculatePerformanceDollar(quant: quantity, initialPrice: price)
                    self.dollarReturn = Double(round(1000*(self.dollarReturn + dollarPerformance))/1000)
                    if(dollarReturn > 0){
                        stockReturnAmount.textColor = UIColor.green
                    }
                    else{
                        stockReturnAmount.textColor = UIColor.red
                    }
                    let percentPerformance = calculatePerformancePercent(quant: quantity, initialPrice: price)
                    self.percentReturn = Double(round(1000*(dollarReturn/dollarsSpent * 100))/1000)
                    if(percentReturn > 0){
                        stockReturn.textColor = UIColor.green
                    }
                    else{
                        stockReturn.textColor = UIColor.red
                    }
                    testItems.append([name,"\(Double(round(1000*dollarPerformance)/1000))","\(Double(round(1000*percentPerformance)/1000))"])
                    print("you purchased \(quantity) \(name) for \(price) dollars each")
                }
            }
        }
        catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        stockReturn.text = "Percent Return: \(percentReturn)%"
        stockReturnAmount.text = "Dollar Return: $\(dollarReturn)"
        if let navController = self.navigationController {
            navController.popViewController(animated: true)
        }
        self.StockTableView.reloadData()
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
            }
            self.isDoneStock = self.isDoneStock + 1
        }
        task3.resume()
        
        while true{
            if self.isDoneStock == 1 {
                priceArr.append(Double(round(1000*currentPrice)/1000))
                break
            }
        }
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
