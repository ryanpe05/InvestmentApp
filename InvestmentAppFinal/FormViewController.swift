//
//  FormViewController.swift
//  InvestmentAppFinal
//
//  Created by Ryan Peck on 7/29/17.
//  Copyright © 2017 Ryan Peck. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class FormViewController: UIViewController, UITextViewDelegate {
    
    @IBOutlet weak var submissionClick: UIButton!
    @IBAction func submissionClicked(_ sender: UIButton) {
        print("submission")
        saveSubmission(quantity: Double(quantity))
        if(isCoin){
            self.performSegue(withIdentifier: "returnCurrency", sender: self)
        }
        else{
            self.performSegue(withIdentifier: "returnStock", sender: self)
        }
    }
    
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    var selectedDate = "Hello"
    var isCoin = true
    var name = "error"
    var initials = "ERR"
    var BTCrate = 0.0 //the bitcoin to USD exchange rate
    var rateTable = [[String]]() //array of exchange rates
    var currentPrice: Double = 0.0
    var isDone = 0
    var quantity = 0.0
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        super.viewWillAppear(animated)
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(FormViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        let screenSize = UIScreen.main.bounds
        let screenWidth = screenSize.width
        let screenHeight = screenSize.height
        
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: screenWidth, height: 21))
        label.center = CGPoint(x: screenWidth/2, y: screenHeight/10)
        label.textAlignment = .center
        
        let label2 = UILabel(frame: CGRect(x: 0, y: 0, width: screenWidth/2, height: 21))
        label2.center = CGPoint(x: screenWidth/4, y: screenHeight/5)
        label2.textAlignment = .center
        label2.text = "Price"
        
        let label3 = UILabel(frame: CGRect(x: 0, y: 0, width: screenWidth/2, height: 21))
        label3.center = CGPoint(x: 3*screenWidth/4, y: screenHeight/5)
        label3.textAlignment = .center
        label3.text = "Quantity"
        
        let textViewPrice = UITextView(frame: CGRect(x: 0, y: 0, width: screenWidth/2, height: 40))
        self.automaticallyAdjustsScrollViewInsets = false
        textViewPrice.center = CGPoint(x: screenWidth/4, y: screenHeight/5+31)
        textViewPrice.textAlignment = .center
        textViewPrice.delegate = self
        textViewPrice.tag = 0
        
        let textViewQuantity = UITextView(frame: CGRect(x: 0, y: 0, width: screenWidth/2, height: 40))
        self.automaticallyAdjustsScrollViewInsets = false
        textViewQuantity.center = CGPoint(x: 3*screenWidth/4, y: screenHeight/5+31)
        textViewQuantity.textAlignment = .center
        textViewQuantity.delegate = self
        textViewQuantity.tag = 1

        let myColor = UIColor.black
        textViewPrice.layer.borderColor = myColor.cgColor
        textViewQuantity.layer.borderColor = myColor.cgColor
        
        textViewPrice.layer.borderWidth = 1.0
        textViewQuantity.layer.borderWidth = 1.0
        
        
        let datePicker: UIDatePicker = UIDatePicker()
        
        // Posiiton date picket within a view
        datePicker.frame = CGRect(x: 10, y: 50, width: screenWidth, height: 200)
        datePicker.center = CGPoint(x: screenWidth/2, y: screenHeight/5 + 151)
        
        // Set some of UIDatePicker properties
        datePicker.timeZone = NSTimeZone.local
        datePicker.backgroundColor = UIColor.white
        
        // Add an event to call onDidChangeDate function when value is changed.
        datePicker.addTarget(self, action: #selector(self.datePickerValueChanged(_:)), for: .valueChanged)
        //set datePickerMode to date
        datePicker.datePickerMode = .date
        self.view.addSubview(datePicker)
        
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Recent")
        do{
            let mostRecentClick = try managedContext.fetch(fetchRequest)
            isCoin = mostRecentClick[0].value(forKeyPath: "coin") as! Bool
            name = mostRecentClick[0].value(forKeyPath: "name") as! String
            initials = mostRecentClick[0].value(forKeyPath: "initials") as! String
        }
        catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        if isCoin {
            label.text = "Purchase of \(name)"
            print("You clicked on the coin \(name)")
            
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
                    let cost = calculateCost()
                    label2.text = "Price"
                    textViewPrice.text = "\(cost)"
                    textViewPrice.textColor = UIColor.lightGray
                    break
                }
            }
        }
        else{
            label.text = "You clicked on the stock \(name)"
        }
        self.view.addSubview(label)
        self.view.addSubview(label2)
        self.view.addSubview(label3)
        self.view.addSubview(textViewPrice)
        self.view.addSubview(textViewQuantity)
        
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        print("I am editing")
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = UIColor.black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Placeholder"
            textView.textColor = UIColor.lightGray
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if textView.text != nil && textView.text != "."{
            if textView.tag == 1{
                quantity = Double(textView.text)!
            }
            else{
                currentPrice = Double(textView.text)!
            }
        }
    }
    
    func datePickerValueChanged(_ sender: UIDatePicker){
        
        // Create date formatter
        let dateFormatter: DateFormatter = DateFormatter()
        
        // Set date format
        dateFormatter.dateFormat = "MM/dd/yyyy"
        
        // Apply date format
        selectedDate = dateFormatter.string(from: sender.date)
        
        
        print("Selected value \(selectedDate)")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
    
    func saveSubmission(quantity: Double) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let entity = NSEntityDescription.entity(forEntityName: "Investments",
                                                in: managedContext)!
        
        let submission = NSManagedObject(entity: entity,
                                     insertInto: managedContext)

        submission.setValue(isCoin, forKeyPath: "coin")
        submission.setValue(name, forKeyPath: "name")
        submission.setValue(currentPrice, forKeyPath: "initPrice")
        submission.setValue(quantity, forKeyPath: "quantity")
        submission.setValue(initials, forKeyPath: "initials")
        submission.setValue(selectedDate, forKeyPath: "buyDate")
        
        do {
            try managedContext.save()
            
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }

    
}
