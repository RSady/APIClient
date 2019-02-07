//
//  ApiClient.swift
//  InvoTrackerPE
//
//  Created by Ryan Sady on 1/26/19.
//  Copyright © 2019 Ryan Sady. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class APIClient {
    
    static let address: String = "webaddress"
    static let invoiceDateFormatter = DateFormatter()
    class func generateRequest(url: URL, poststring: String) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = poststring.data(using: .utf8)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        return request
    }
    
    enum Login {
        static func login(username: String, password: String, deviceId: String, completion: @escaping (_ error: Error?, _ data: JSON?) -> Void) {
            guard let urlString = URL(string: "loginAddress") else { return }
            let poststring = "username=\(username)&password=\(password)&deviceId=\(deviceId)"
            let request = generateRequest(url: urlString, poststring: poststring)
            
            Alamofire.request(request).responseJSON { (response) in
                if let error = response.error {
                    print(error)
                    completion(error, nil)
                    return
                }
                
                if let data = response.data {
                    do {
                        let json = try JSON(data: data)
                        let result = json["result"].boolValue
                        if result {
                            let token = json["token"].stringValue
                            UserDefaults.standard.set(token, forKey: "authToken")
                            completion(nil, json)
                        } else {
                            if let message = json["message"].string {
                                completion(message.errorDescription, nil)
                            }
                        }
                    } catch {
                        print("JSON Error: \(error)")
                        completion(APIErrors.jsonParseError, nil)
                    }
                    
                }
            }
        }
        
        static func resetPassword(emailAddress: String, completion: @escaping (_ error: Error?) -> Void) {
            guard let urlString = URL(string: "\(address)ResetPassword") else { return }
            let poststring = "email=\(emailAddress)"
            let request = generateRequest(url: urlString, poststring: poststring)
            
            Alamofire.request(request).responseJSON { (response) in
                if let error = response.error {
                    print(error)
                    completion(error)
                    return
                }
                
                if let data = response.data {
                    do {
                        let json = try JSON(data: data)
                        let result = json["result"].boolValue
                        if result {
                            completion(nil)
                        } else {
                            if let message = json["message"].string {
                                completion(message.errorDescription)
                            }
                        }
                    } catch {
                        print("JSON Error: \(error)")
                        completion(APIErrors.jsonParseError)
                    }
                    
                }
            }
        }
        
        static func createNewAccount(for company: NewCompany, completion: @escaping (_ error: Error?) -> Void) {
            guard let urlString = URL(string: "\(address)NewSignUp") else { return }
            let base64logo = convertImageToBase64(image: company.logo)
            let poststring = "companyName=\(company.companyName)&adminFirst=\(company.adminFirst)&adminLast=\(company.adminLast)&adminEmail=\(company.adminEmail)&adminPassword=\(company.adminPassword)&street=\(company.street)&city=\(company.city)&state=\(company.state)&zip=\(company.zip)&logo=\(base64logo)&referralCode=\(company.referralCode)"
            let request = generateRequest(url: urlString, poststring: poststring)
            
            Alamofire.request(request).responseJSON { (response) in
                if let error = response.error {
                    print(error)
                    completion(error)
                    return
                }
                
                if let data = response.data {
                    do {
                        let json = try JSON(data: data)
                        let result = json["result"].boolValue
                        if result {
                            let token = json["token"].stringValue
                            UserDefaults.standard.set(token, forKey: "authToken")
                            completion(nil)
                        } else {
                            if let message = json["message"].string {
                                completion(message.errorDescription)
                            }
                        }
                    } catch {
                        print("JSON Error: \(error)")
                        completion(APIErrors.jsonParseError)
                    }
                    
                }
            }
        }
    }
        
    enum Customers {
        static func getCustomers(completion: @escaping (_ error: Error?, _ data: [CustomerStruct]?) -> Void) {
        guard let urlString = URL(string: "\(address)GetCustomers") else { return }
        guard let authToken = UserDefaults.standard.value(forKey: "authToken") else {
            completion(APIErrors.authError, nil)
            return
        }
        let poststring = "token=\(authToken)"
        let request = generateRequest(url: urlString, poststring: poststring)
        var customers = [CustomerStruct]()
        Alamofire.request(request).responseJSON { (response) in
            if let error = response.error {
                DispatchQueue.main.async {
                    print(error)
                    completion(error.localizedDescription, nil)
                    return
                }
            }
            
            if let data = response.data {
                do {
                    let json = try JSON(data: data)
                    
                    let result = json["result"].boolValue
                    if result {
                        if let customerList = json["customers"].array {
                            for customer in customerList {
                                if let firstName = customer["firstName"].string,
                                    let lastName = customer["lastName"].string,
                                    let id = customer["id"].int,
                                    let mobile = customer["mobile"].string,
                                    let altMobile = customer["alternate"].string,
                                    let notes = customer["notes"].string,
                                    let email = customer["email"].string,
                                    let company = customer["companyName"].string,
                                    let billingStreet = customer["address"]["billing"]["street"].string,
                                    let billingCity = customer["address"]["billing"]["city"].string,
                                    let billingState = customer["address"]["billing"]["state"].string,
                                    let billingZip = customer["address"]["billing"]["zip"].string,
                                    let serviceStreet = customer["address"]["service"]["street"].string,
                                    let serviceCity = customer["address"]["service"]["city"].string,
                                    let serviceState = customer["address"]["service"]["state"].string,
                                    let serviceZip = customer["address"]["service"]["zip"].string {
                                    let searchText: String = {
                                        if company.count != 0 && firstName.count != 0 {
                                            return "\(company) \(firstName) \(lastName)"
                                        } else if firstName.count == 0 || lastName.count == 0 {
                                            return company
                                        } else if company.count == 0 {
                                            return "\(firstName) \(lastName)"
                                        } else {
                                            return ""
                                        }
                                    }()
                                    
                                    if let customFieldData = customer["customFields"].array {
                                        var fieldData = [[String: String]]()
                                        for data in customFieldData {
                                            if data["name"].string! != "" {
                                                //fieldData[data["name"].string!] = data["value"].string!
                                                fieldData.append(["name" : data["name"].stringValue, "value" : data["value"].stringValue])
                                            }
                                        }
                                        let customFieldData = fieldData
                                        let newCustomer = CustomerStruct(company: company, altMobile: altMobile, mobile: mobile, billingStreet: billingStreet, billingCity: billingCity, billingState: billingState, billingZip: billingZip, email: email, serviceStreet: serviceStreet, serviceCity: serviceCity, serviceState: serviceState, serviceZip: serviceZip, notes: notes, firstName: firstName, lastName: lastName, searchText: searchText, id: id, customFieldData: customFieldData)
                                        
                                        customers.append(newCustomer)
                                    } else {
                                        print("No Custom Field Data - Parse Error!")
                                        completion("Custom Data Error\n\(APIErrors.jsonParseError)", nil)
                                        
                                    }
                                } else {
                                    print("Customer Parse Error")
                                    completion("Customer Data Error\n\(APIErrors.jsonParseError)", nil)
                                }
                            }
                        } else {
                            print("Error Parsing Customers List")
                            completion("Customers Data Error\n\(APIErrors.jsonParseError)", nil)
                        }
                        
                        completion(nil, customers)
                    } else {
                        if let message = json["message"].string {
                            completion(message, nil)
                        }
                    }
                } catch {
                    print("JSON Error: \(error)")
                    completion(APIErrors.jsonParseError, nil)
                }
                
            }
        }
    }
    
        static func saveCustomer(customer: CustomerStruct, isNew: Bool, completion: @escaping (_ error: Error?, _ data: String?) -> Void) {
        guard let urlString = URL(string: "\(address)SaveCustomer") else { return }
        guard let authToken = UserDefaults.standard.value(forKey: "authToken") else {
            completion(APIErrors.authError, nil)
            return
        }
        let customerId: String = {
            if isNew {
                return "new"
            } else {
                return String(customer.id)
            }
        }()
        guard let jsonDict = try? JSONSerialization.data(withJSONObject: customer.customFieldData, options: [.sortedKeys]) else { return }
        guard let jsonString = String(data: jsonDict, encoding: .utf8) else { return }
        let poststring = "token=\(authToken)&id=\(customerId)&companyName=\(customer.company)&firstName=\(customer.firstName)&lastName=\(customer.lastName)&email=\(customer.email)&mobile=\(customer.mobile)&alternate=\(customer.altMobile)&billingStreet=\(customer.billingStreet)&billingCity=\(customer.billingCity)&billingState=\(customer.billingState)&billingZip=\(customer.billingZip)&serviceStreet=\(customer.serviceStreet)&serviceCity=\(customer.serviceCity)&serviceState=\(customer.serviceState)&serviceZip=\(customer.serviceZip)&notes=\(customer.notes)&customFields=\(jsonString)&sendEmail=\(isNew as Bool)"
        let request = generateRequest(url: urlString, poststring: poststring)
        Alamofire.request(request).responseJSON { (response) in
            if let error = response.error {
                DispatchQueue.main.async {
                    print(error)
                    completion(error.localizedDescription, nil)
                    return
                }
            }
            
            if let data = response.data {
                do {
                    let json = try JSON(data: data)
                    print(json)
                    let result = json["result"].boolValue
                    if result {
                        let newId: String? = {
                            if isNew {
                                return String(describing: json[""].int)
                            } else {
                                return nil
                            }
                        }()
                        
                        completion(nil, newId)
                    } else {
                        if let message = json["message"].string {
                            completion(message, nil)
                        }
                    }
                } catch {
                    print("JSON Error: \(error)")
                    completion(APIErrors.jsonParseError, nil)
                }
                
            }
        }
    }
    }

    enum Inventory {
    //NOTE: Inventory categories are in 'getInventory' call
        static func getInventory(completion: @escaping (_ error: Error?, _ data: InventoryData?) -> Void) {
            guard let urlString = URL(string: "\(address)GetInventory") else { return }
            guard let authToken = UserDefaults.standard.value(forKey: "authToken") else {
                completion(APIErrors.authError.rawValue, nil)
                return
            }
            let poststring = "token=\(authToken)"
            let request = generateRequest(url: urlString, poststring: poststring)
            var inventoryItems: [Inventory_Item] = [Inventory_Item]()
            var inventoryCategories: [Inventory_Category] = [Inventory_Category]()
            var inventoryUnits: [Inventory_Unit] = [Inventory_Unit]()
            Alamofire.request(request).responseJSON { (response) in
                if let error = response.error {
                    print(error)
                    completion(error.localizedDescription, nil)
                    return
                }
                
                if let data = response.data {
                    do {
                        let json = try JSON(data: data)
                        let result = json["result"].boolValue
                        if result {
                            if let inventory = json["inventory"].array {
                                for item in inventory {
                                    if let cost = item["cost"].string,
                                        let sku = item["sku"].string,
                                        let locationId = item["location"]["id"].int,
                                        let locationName = item["location"]["name"].string,
                                        let id = item["id"].int,
                                        let unit = item["unit"].string,
                                        let salePrice = item["salePrice"].string,
                                        let desc = item["description"].string,
                                        let infStock = item["infiniteStock"].int,
                                        let categoryId = item["category"]["id"].int,
                                        let categoryName = item["category"]["name"].string,
                                        let stock = item["stock"].float,
                                        let regularPrice = item["salePrice"].string,
                                        let emergencyPrice = item["emergencyPrice"].string,
                                        let afterHoursPrice = item["afterHoursPrice"].string,
                                        let supplyHouse = item["supplyHouse"].string {
                                        let infiniteStock: Bool = {
                                            if infStock == 0 {
                                                return false
                                            } else {
                                                return true
                                            }
                                        }()
                                        if let itemCost = Float.init(cost.replacingOccurrences(of: ",", with: "")),
                                            let price = Float.init(salePrice.replacingOccurrences(of: ",", with: "")) {
                                            let newItem = Inventory_Item(categoryId: categoryId, id: id, locationId: locationId, categoryName: categoryName, desc: desc, locationName: locationName, sku: sku, supplyHouse: supplyHouse, unit: unit, cost: itemCost, price: price, stock: stock, infiniteStock: infiniteStock, regularPrice: regularPrice, afterHoursPrice: afterHoursPrice, emergencyPrice: emergencyPrice, searchText: "\(locationName) \(sku) \(supplyHouse) \(unit) \(itemCost) \(price) \(desc)")
                                            inventoryItems.append(newItem)
                                        } else {
                                            print("Error Casting Cost from String to Float because Nic is a huge pain in the ass")
                                        }
                                    } else {
                                        print("Error Appending Inventory Items")
                                    }
                                }
                                
                                if let categories = json["categories"].array {
                                    //Parse Data
                                    for category in categories {
                                        if let id = category["id"].int,
                                            let name = category["name"].string {
                                            
                                            //New Category
                                            let newCategory = Inventory_Category(id: id, name: name)
                                            inventoryCategories.append(newCategory)
                                        } else {
                                            print("Error Appending Categories")
                                        }
                                    }
                                    
                                } else {
                                    print("Category Parsing Error")
                                }
                                
                                if let units = json["units"].array {
                                    //Parse Data
                                    for unit in units {
                                        if let id = unit["id"].int,
                                            let name = unit["name"].string {
                                            
                                            //New Unit
                                            let newUnit = Inventory_Unit(id: id, name: name)
                                            inventoryUnits.append(newUnit)
                                        } else {
                                            print("Error Appending Units")
                                        }
                                    }
                                } else {
                                    print("Unit Parsing Error")
                                }
                            } else {
                                print("Inventory Parsing Error")
                            }
                            var data: InventoryData = InventoryData()
                            data.items = inventoryItems
                            data.categories = inventoryCategories
                            data.units = inventoryUnits
                            completion(nil, data)
                        } else {
                            if let message = json["message"].string {
                                completion(message, nil)
                            }
                        }
                    } catch {
                        print("JSON Error: \(error)")
                        completion(APIErrors.jsonParseError, nil)
                    }
                    
                }
            }
            
        }
        
        static func saveInventoryItem(item: Inventory_Item, isNew: Bool, completion: @escaping (_ error: Error?) -> Void) {
            guard let urlString = URL(string: "\(address)SaveItem") else { return }
            guard let authToken = UserDefaults.standard.value(forKey: "authToken") else {
                completion(APIErrors.authError)
                return
            }
            let itemId: String = {
                if isNew {
                    return "new"
                } else {
                    return String(item.id)
                }
            }()
            
            let poststring = "token=\(authToken)&id=\(itemId)&category=\(item.categoryId)&sku=\(item.sku.percentEncodeForAPI())&description=\(item.desc.percentEncodeForAPI())&stock=\(item.stock)&cost=\(item.cost)&price=\(item.price)&emergencyPrice=\(item.emergencyPrice)&afterHoursPrice=\(item.afterHoursPrice)&unit=\(item.unit)&location=\(item.locationId)&supplyHouse=\(item.supplyHouse.percentEncodeForAPI())&infiniteStock=\(item.infiniteStock)"
            let request = generateRequest(url: urlString, poststring: poststring)
            Alamofire.request(request).responseJSON { (response) in
                if let error = response.error {
                    DispatchQueue.main.async {
                        print(error)
                        completion(error.localizedDescription)
                        return
                    }
                }
                
                if let data = response.data {
                    do {
                        let json = try JSON(data: data)
                        print(json)
                        let result = json["result"].boolValue
                        if result {
                            completion(nil)
                        } else {
                            if let message = json["message"].string {
                                completion(message)
                            }
                        }
                    } catch {
                        print("JSON Error: \(error)")
                        completion(APIErrors.jsonParseError)
                    }
                    
                }
            }
            
        }
        
        static func deleteInventoryItem(item: Inventory_Item, completion: @escaping (_ error: Error?) -> Void) {
            guard let urlString = URL(string: "\(address)DeleteItem") else { return }
            guard let authToken = UserDefaults.standard.value(forKey: "authToken") else {
                completion(APIErrors.authError)
                return
            }
            let poststring = "token=\(authToken)&id=\(item.id)"
            let request = generateRequest(url: urlString, poststring: poststring)
            Alamofire.request(request).responseJSON { (response) in
                if let error = response.error {
                    print(error)
                    completion(error.localizedDescription)
                    return
                }
                
                if let data = response.data {
                    do {
                        let json = try JSON(data: data)
                        let result = json["result"].boolValue
                        if result {
                            completion(nil)
                        } else {
                            if let message = json["message"].string {
                                completion(message)
                            }
                        }
                    } catch {
                        print("JSON Error: \(error)")
                        completion(APIErrors.jsonParseError)
                    }
                    
                }
            }
        }
        
        static func saveCategory(category: Inventory_Category, isNew: Bool, completion: @escaping (_ error: Error?) -> Void) {
            guard let urlString = URL(string: "\(address)NewCategory") else { return }
            guard let authToken = UserDefaults.standard.value(forKey: "authToken") else {
                completion(APIErrors.authError)
                return
            }
            let categoryId: String = {
                if isNew {
                    return "new"
                } else {
                    return "\(category.id)"
                }
            }()
            
            let poststring = "token=\(authToken)&id=\(categoryId)&name=\(category.name)"
            let request = generateRequest(url: urlString, poststring: poststring)
            Alamofire.request(request).responseJSON { (response) in
                if let error = response.error {
                    print(error)
                    completion(error.localizedDescription)
                    return
                }
                
                if let data = response.data {
                    do {
                        let json = try JSON(data: data)
                        let result = json["result"].boolValue
                        if result {
                            completion(nil)
                        } else {
                            if let message = json["message"].string {
                                completion(message)
                            }
                        }
                    } catch {
                        print("JSON Error: \(error)")
                        completion(APIErrors.jsonParseError.rawValue)
                    }
                    
                }
            }
            
        }
        
        static func deleteCategory(category: Inventory_Category, completion: @escaping (_ error: Error?) -> Void) {
            guard let urlString = URL(string: "\(address)DeleteCategory") else { return }
            guard let authToken = UserDefaults.standard.value(forKey: "authToken") else {
                completion(APIErrors.authError.rawValue)
                return
            }
            let poststring = "token=\(authToken)&id=\(category.id)"
            let request = generateRequest(url: urlString, poststring: poststring)
            Alamofire.request(request).responseJSON { (response) in
                if let error = response.error {
                    print(error)
                    completion(error.localizedDescription)
                    return
                }
                
                if let data = response.data {
                    do {
                        let json = try JSON(data: data)
                        let result = json["result"].boolValue
                        if result {
                            completion(nil)
                        } else {
                            if let message = json["message"].string {
                                completion(message)
                            }
                        }
                    } catch {
                        print("JSON Error: \(error)")
                        completion(APIErrors.jsonParseError.rawValue)
                    }
                    
                }
            }
        }
        
        static func newInventoryUnit(name: String, completion: @escaping (_ error: Error?) -> Void) {
            guard let urlString = URL(string: "\(address)NewUnit") else { return }
            guard let authToken = UserDefaults.standard.value(forKey: "authToken") else {
                completion(APIErrors.authError.rawValue)
                return
            }
            let poststring = "token=\(authToken)&name=\(name)"
            let request = generateRequest(url: urlString, poststring: poststring)
            Alamofire.request(request).responseJSON { (response) in
                if let error = response.error {
                    print(error)
                    completion(error.localizedDescription)
                    return
                }
                
                if let data = response.data {
                    do {
                        let json = try JSON(data: data)
                        let result = json["result"].boolValue
                        if result {
                            completion(nil)
                        } else {
                            if let message = json["message"].string {
                                completion(message)
                            }
                        }
                    } catch {
                        print("JSON Error: \(error)")
                        completion(APIErrors.jsonParseError)
                    }
                    
                }
            }
        }
        
        static func deleteInventoryUnit(unit: Inventory_Unit, completion: @escaping (_ error: Error?) -> Void) {
            guard let urlString = URL(string: "\(address)DeleteUnit") else { return }
            guard let authToken = UserDefaults.standard.value(forKey: "authToken") else {
                completion(APIErrors.authError)
                return
            }
            let poststring = "token=\(authToken)&id=\(unit.id)"
            let request = generateRequest(url: urlString, poststring: poststring)
            Alamofire.request(request).responseJSON { (response) in
                if let error = response.error {
                    print(error)
                    completion(error)
                    return
                }
                
                if let data = response.data {
                    do {
                        let json = try JSON(data: data)
                        let result = json["result"].boolValue
                        if result {
                            completion(nil)
                        } else {
                            if let message = json["message"].string {
                                completion(message.errorDescription)
                            }
                        }
                    } catch {
                        print("JSON Error: \(error)")
                        completion(APIErrors.jsonParseError)
                    }
                    
                }
            }
        }
        
        static func getInventoryLocations(completion: @escaping (_ error: Error?, _ data: [Inventory_Location]?) -> Void) {
            guard let urlString = URL(string: "\(address)GetLocationAccess") else { return }
            guard let authToken = UserDefaults.standard.value(forKey: "authToken") else {
                completion(APIErrors.authError, nil)
                return
            }
            let poststring = "token=\(authToken)"
            let request = generateRequest(url: urlString, poststring: poststring)
            Alamofire.request(request).responseJSON { (response) in
                if let error = response.error {
                    DispatchQueue.main.async {
                        print(error)
                        completion(error.localizedDescription, nil)
                        return
                    }
                }
                var inventoryLocations: [Inventory_Location] = [Inventory_Location]()
                if let data = response.data {
                    do {
                        let json = try JSON(data: data)
                        print(json)
                        let result = json["result"].boolValue
                        if result {
                            if let locations = json["locations"].array {
                                for location in locations {
                                    var accesses = [UserAccess]()
                                    if let name = location["name"].string,
                                        let id = location["id"].int,
                                        let userAccesses = location["userAccess"].array {
                                        for access in userAccesses {
                                            if let userId = access["userId"].int,
                                                let accessLevel = access["access"].int,
                                                let firstName = access["first"].string,
                                                let lastName = access["last"].string {
                                                
                                                let userAccess = UserAccess(userId: userId, access: accessLevel, firstName: firstName, lastName: lastName)
                                                accesses.append(userAccess)
                                            } else {
                                                print("No User Access Data")
                                            }
                                        }
                                        let newLocation = Inventory_Location(id: id, name: name, userAccess: accesses)
                                        inventoryLocations.append(newLocation)
                                    } else {
                                        print("Access Parsing Error")
                                        completion(APIErrors.jsonParseError, nil)
                                    }
                                }
                            } else {
                                print("Location Parsing Error")
                                completion(APIErrors.jsonParseError, nil)
                            }
                            
                            completion(nil, inventoryLocations)
                        } else {
                            if let message = json["message"].string {
                                completion(message.errorDescription, nil)
                            }
                        }
                    } catch {
                        print("JSON Error: \(error)")
                        completion(APIErrors.jsonParseError, nil)
                    }
                }
            }
        }
        
        static func saveInventoryLocation(location: Inventory_Location, isNew: Bool, completion: @escaping (_ error: String?) -> Void) {
            guard let urlString = URL(string: "\(address)SaveLocation") else { return }
            guard let authToken = UserDefaults.standard.value(forKey: "authToken") else {
                completion(APIErrors.authError.rawValue)
                return
            }
            let locationId: String = {
                if isNew {
                    return "new"
                } else {
                    return String(location.id)
                }
            }()
            let poststring = "token=\(authToken)&id=\(locationId)&name=\(location.name)"
            let request = generateRequest(url: urlString, poststring: poststring)
            Alamofire.request(request).responseJSON { (response) in
                if let error = response.error {
                    print(error)
                    completion(error.localizedDescription)
                    return
                }
                
                if let data = response.data {
                    do {
                        let json = try JSON(data: data)
                        let result = json["result"].boolValue
                        if result {
                            completion(nil)
                        } else {
                            if let message = json["message"].string {
                                completion(message)
                            }
                        }
                    } catch {
                        print("JSON Error: \(error)")
                        completion(APIErrors.jsonParseError.rawValue)
                    }
                    
                }
            }
        }
        
        static func deleteInventoryLocation(location: Inventory_Location, completion: @escaping (_ error: String?) -> Void) {
            guard let urlString = URL(string: "\(address)DeleteLocation") else { return }
            guard let authToken = UserDefaults.standard.value(forKey: "authToken") else {
                completion(APIErrors.authError.rawValue)
                return
            }
            let poststring = "token=\(authToken)&id=\(location.id)"
            let request = generateRequest(url: urlString, poststring: poststring)
            Alamofire.request(request).responseJSON { (response) in
                if let error = response.error {
                    print(error)
                    completion(error.localizedDescription)
                    return
                }
                
                if let data = response.data {
                    do {
                        let json = try JSON(data: data)
                        let result = json["result"].boolValue
                        if result {
                            completion(nil)
                        } else {
                            if let message = json["message"].string {
                                completion(message)
                            }
                        }
                    } catch {
                        print("JSON Error: \(error)")
                        completion(APIErrors.jsonParseError.rawValue)
                    }
                    
                }
            }
        }
        
        static func saveLocationAccess(location: Inventory_Location, access: UserAccess, completion: @escaping (_ error: Error?) -> Void) {
            guard let urlString = URL(string: "\(address)SaveLocationAccess") else { return }
            guard let authToken = UserDefaults.standard.value(forKey: "authToken") else {
                completion(APIErrors.authError)
                return
            }
            let poststring = "token=\(authToken)&id=\(location.id)&access=\(createPostData(from: location.userAccess))"
            let request = generateRequest(url: urlString, poststring: poststring)
            Alamofire.request(request).responseJSON { (response) in
                if let error = response.error {
                    print(error)
                    completion(error.localizedDescription)
                    return
                }
                
                if let data = response.data {
                    do {
                        let json = try JSON(data: data)
                        let result = json["result"].boolValue
                        if result {
                            completion(nil)
                        } else {
                            if let message = json["message"].string {
                                completion(message)
                            }
                        }
                    } catch {
                        print("JSON Error: \(error)")
                        completion(APIErrors.jsonParseError)
                    }
                }
            }
        }
    }
    
    enum Invoices {
        static func getInvoices(completion: @escaping (_ error: Error?, _ data: [InvoiceStruct]?) -> Void) {
            guard let urlString = URL(string: "\(address)GetInvoices") else { return }
            guard let authToken = UserDefaults.standard.value(forKey: "authToken") else {
                completion(APIErrors.authError, nil)
                return
            }
            let poststring = "token=\(authToken)"
            let request = generateRequest(url: urlString, poststring: poststring)
            invoiceDateFormatter.dateFormat = "MM/dd/yyyy"
            var invoices: [InvoiceStruct] = [InvoiceStruct]()
            Alamofire.request(request).responseJSON { (response) in
                if let error = response.error {
                    print(error)
                    completion(error, nil)
                    return
                }
                if let data = response.data {
                    do {
                        let jsonData = try JSON(data: data)
                        let result = jsonData["result"].bool
                        
                        if result == true {
                            if let invoiceList = jsonData["invoices"].array {
                                
                                for invoice in invoiceList {
                                    var billingAddress = InvoiceAddress(address: "", cityStateZip: "", phone: "", email: "")
                                    var shippingAddress = InvoiceAddress(address: "", cityStateZip: "", phone: "", email: "")
                                    var sentLogs = [String]()
                                    var itemList = [InvoiceItem]()
                                    var paymentList = [InvoicePayment]()
                                    var depositList = [InvoiceDeposit]()
                                    var attachments = [UIImage]()
                                    var notes = ""
                                    var taxRate = TaxRate(id: 0, name: "", rate: 0, isDefault: false)
                                    
                                    if let status = invoice["status"].string,
                                        let dateInvoiced = invoice["dateInvoiced"].string,
                                        let email = invoice["email"].string,
                                        let id = invoice["id"].int,
                                        let total = invoice["total"].float,
                                        let firstName = invoice["firstName"].string,
                                        let lastName = invoice["lastName"].string,
                                        let companyName = invoice["companyName"].string,
                                        let type = invoice["type"].string,
                                        let remaining = invoice["remaining"].string,
                                        let pricePoint = invoice["pricePoint"].string,
                                        let shipToCustomer = invoice["shipToCustomer"].int,
                                        let billToCustomer = invoice["billToCustomer"].int,
                                        let requiresSignature = invoice["components"]["invoice-customer-signature"]["value"].string,
                                        let invoiceNumber = invoice["components"]["invoice-number"]["value"].string {
                                        
                                        //Shipping Information
                                        var shippingStreet = ""
                                        var shippingCityStateZip = ""
                                        var shippingPhone = ""
                                        var shippingEmail = ""
                                        
                                        
                                        if let shipToAddress = invoice["components"]["ship-to-address"]["value"].string {
                                            shippingStreet = shipToAddress
                                        }
                                        if let shipToCityStateZip = invoice["components"]["ship-to-city-state-zip"]["value"].string {
                                            shippingCityStateZip = shipToCityStateZip
                                        }
                                        if let shipToPhone = invoice["components"]["ship-to-phone"]["value"].string {
                                            shippingPhone = shipToPhone
                                        }
                                        if let shipToEmail = invoice["components"]["ship-to-email"]["value"].string {
                                            shippingEmail = shipToEmail
                                        }
                                        shippingAddress = InvoiceAddress(address: shippingStreet, cityStateZip: shippingCityStateZip, phone: shippingPhone, email: shippingEmail)
                                        
                                        //Billing Information
                                        var billingStreet = ""
                                        var billingCityStateZip = ""
                                        var billingPhone = ""
                                        var billingEmail = ""
                                        
                                        if let billToAddress = invoice["components"]["bill-to-address"]["value"].string {
                                            billingStreet = billToAddress
                                        }
                                        if let billToCityStateZip = invoice["components"]["bill-to-city-state-zip"]["value"].string {
                                            billingCityStateZip = billToCityStateZip
                                        }
                                        if let billToPhone = invoice["components"]["bill-to-phone"]["value"].string {
                                            billingPhone = billToPhone
                                        }
                                        if let billToEmail = invoice["components"]["bill-to-email"]["value"].string {
                                            billingEmail = billToEmail
                                        }
                                        billingAddress = InvoiceAddress(address: billingStreet, cityStateZip: billingCityStateZip, phone: billingPhone, email: billingEmail)
                                        
                                        //Company Information
                                        var companyPhone = ""
                                        var companyEmail = ""
                                        var companyAddress = ""
                                        var companyCity = ""
                                        
                                        if let compAddress = invoice["components"]["company-address"]["value"].string {
                                            companyAddress = compAddress
                                        }
                                        if let compCity = invoice["components"]["company-city"]["value"].string {
                                            companyCity = compCity
                                        }
                                        if let compPhone = invoice["components"]["company-phone"]["value"].string {
                                            companyPhone = compPhone
                                        }
                                        if let compEmail = invoice["components"]["company-email"]["value"].string {
                                            companyEmail = compEmail
                                        }
                                        
                                        
                                        //Sent Log
                                        if let sentlog = invoice["sentLog"].arrayObject as? [String] {
                                            for log in sentlog {
                                                sentLogs.append(log)
                                            }
                                        } else {
                                            print("No Sent Logs")
                                        }
                                        
                                        //Invoice Items
                                        if let items = invoice["items"].array {
                                            //print(items)
                                            for item in items {
                                                if let itemId = item["itemId"].string,
                                                    let regular = item["regular"].string,
                                                    let emergency = item["emergency"].string,
                                                    let afterHours = item["afterHours"].string,
                                                    let desc = item["description"].string,
                                                    let qty = item["quantity"].string,
                                                    //let uuid = item["uuid"].int,
                                                    let price = item["price"].string,
                                                    let notes = item["notes"].string {
                                                    
                                                    var costValue = Float()
                                                    if let cost = item["cost"].float {
                                                        costValue = cost
                                                    } else {
                                                        costValue = 0
                                                    }
                                                    
                                                    let uuid: String = {
                                                        if let id = item["uuid"].string {
                                                            return id
                                                        } else {
                                                            if let id = item["uuid"].int {
                                                                return String(id)
                                                            }
                                                            return ""
                                                        }
                                                    }()
                                                    
                                                    let newItem = InvoiceItem(id: itemId, regular: regular, emergency: emergency, afterHours: afterHours, description: desc, quantity: qty, uuid: uuid, price: price, notes: notes, cost: costValue, total: 0)
                                                    
                                                    itemList.append(newItem)
                                                    
                                                } else {
                                                    print("\n*******************************\nError Parsing Item for \(item) \n*******************************\n")
                                                }
                                            }
                                        } else {
                                            //No Items
                                            print("No Item")
                                        }
                                        
                                        //Payments
                                        if let pymts = invoice["payments"].array {
                                            for payment in pymts {
                                                if let number = payment["number"].string,
                                                    let method = payment["method"].string,
                                                    let amount = payment["amount"].string,
                                                    let type = payment["type"].string,
                                                    let dateTime = payment["dateTime"].string,
                                                    let id = payment["id"].int {
                                                    
                                                    let dateStr = dateTime.split(separator: " ")
                                                    if dateStr.count == 2 {
                                                        let components = dateStr[0].split(separator: "-")
                                                        if components.count == 3 {
                                                            let day = components[2]
                                                            let month = components[1]
                                                            let year = components[0]
                                                            
                                                            let newPayment = InvoicePayment(number: number, method: method, amount: amount, type: type, dateTime: "\(month)/\(day)/\(year)", id: String(id))
                                                            paymentList.append(newPayment)
                                                        } else {
                                                            print("Date Component Count Error")
                                                        }
                                                    } else {
                                                        print("Payment Date Formatting Error")
                                                    }
                                                }
                                            }
                                        } else {
                                            //No Payments
                                            print("No Payments")
                                        }
                                        
                                        
                                        //Depsits
                                        if let deposits = invoice["deposits"].array {
                                            for deposit in deposits {
                                                if let type = deposit["type"].string,
                                                    let amount = deposit["amount"].string {
                                                    let newDeposit = InvoiceDeposit(type: type, amount: amount)
                                                    depositList.append(newDeposit)
                                                }
                                            }
                                        } else {
                                            print("No Deposits")
                                        }
                                        
                                        //Attachments
                                        if let attchmnts = invoice["attachments"].arrayObject as? [String] {
                                            for attachment in attchmnts {
                                                if let base64str: NSData = NSData(base64Encoded: attachment, options: NSData.Base64DecodingOptions.ignoreUnknownCharacters) {
                                                    if let imageData = base64str as NSData? {
                                                        if let newImage = UIImage(data: imageData as Data) {
                                                            attachments.append(newImage)
                                                        } else {
                                                            print("No UIImage: \(firstName) \(lastName)")
                                                        }
                                                    } else {
                                                        print("Error Loading Image Data: \(firstName) \(lastName)")
                                                    }
                                                } else {
                                                    print("Error Base 64")
                                                }
                                            }
                                        }
                                        
                                        //Tax Rate
                                        if let txRate = invoice["components"]["tax-rate"]["value"].string,
                                            let rateId = invoice["components"]["tax-rate"]["id"].string {
                                            
                                            if let rate = Float(txRate),
                                                let id = Int(rateId) {
                                                taxRate.rate = rate
                                                taxRate.id = id
                                                taxRate.name = txRate
                                            }
                                        }
                                        
                                        //Notes
                                        if let invNotes = invoice["components"]["invoice-notes"]["value"].string {
                                            notes = invNotes
                                        }
                                        
                                        //Create Invoice
                                        let signatureRequired: Bool = {
                                            if requiresSignature == "true" {
                                                return true
                                            } else {
                                                return false
                                            }
                                        }()
                                        //print("New Invoice Date: \(dateInvoiced)")
                                        let unixStamp = invoiceDateFormatter.date(from: dateInvoiced)
                                        let newInvoice = InvoiceStruct(total: total, remaining: remaining, id: id, status: status, type: type, dateInvoiced: dateInvoiced, email: email, firstName: firstName, lastName: lastName, companyName: companyName, items: itemList, payments: paymentList, deposits: depositList, billToCustomer: billToCustomer, billingAddress: billingAddress, shippingAddress: shippingAddress, shipToCustomer: shipToCustomer, signatureRequired: signatureRequired, sentLog: sentLogs, invoiceNumber: invoiceNumber, pricePoint: pricePoint, attachments: attachments, taxRate: taxRate, compName: companyName, companyAddress: companyAddress, companyCity: companyCity, companyEmail: companyEmail, companyPhone: companyPhone, notes: notes, searchText: "\(companyName) \(firstName) \(lastName) \(companyPhone) \(billingPhone) \(shippingPhone)", unixStamp: unixStamp)
                                        invoices.append(newInvoice)
                                        
                                    } else {
                                        print("Error Parseing Invoice Data")
                                    }
                                }
                            } else {
                                print("Error Parsing Invoice Lists")
                            }
                            completion(nil, invoices)
                        } else if result == false {
                            if let message = jsonData["message"].string {
                                completion(message.errorDescription, nil)
                            }
                        }
                    } catch {
                        print("JSON Error!: \(error.localizedDescription)")
                        completion(APIErrors.jsonParseError, nil)
                    }
                }
            }
        }
        
        static func deleteInvoice(invoice: InvoiceStruct, completion: @escaping (_ error: Error?) -> Void) {
            guard let urlString = URL(string: "\(address)DeleteInvoices") else { return }
            guard let authToken = UserDefaults.standard.value(forKey: "authToken") else {
                completion(APIErrors.authError)
                return
            }
            
            guard let invoiceId = invoice.id else { completion(APIErrors.noIdError); return }
            let poststring = "token=\(authToken)id=\(invoiceId)"
            let request = generateRequest(url: urlString, poststring: poststring)
            
            Alamofire.request(request).responseJSON { (response) in
                if let error = response.error {
                    print(error)
                    completion(error.localizedDescription)
                    return
                }
                
                if let data = response.data {
                    do {
                        let json = try JSON(data: data)
                        let result = json["result"].boolValue
                        if result {
                            completion(nil)
                        } else {
                            if let message = json["message"].string {
                                completion(message)
                            }
                        }
                    } catch {
                        print("JSON Error: \(error)")
                        completion(APIErrors.jsonParseError.rawValue)
                    }
                    
                }
            }
        }
        
        static func saveInvoice(invoice: InvoiceStruct, type: InvoiceType, shippingCustomer: CustomerStruct, billingCustomer: CustomerStruct, completion: @escaping (_ error: Error?) -> Void) {
            guard let urlString = URL(string: "\(address)SaveInvoices") else { return }
            guard let _ = UserDefaults.standard.value(forKey: "authToken") else {
                completion(APIErrors.authError)
                return
            }
            let poststring = createPoststring(for: invoice, invType: type, billCustomer: billingCustomer, shipCustomer: shippingCustomer)
            let request = generateRequest(url: urlString, poststring: poststring)
            
            Alamofire.request(request).responseJSON { (response) in
                if let error = response.error {
                    print(error)
                    completion(error.localizedDescription)
                    return
                }
                
                if let data = response.data {
                    do {
                        let jsonData = try JSON(data: data)
                        let result = jsonData["result"].bool
                        if result == true {
                            completion(nil)
                        } else if result == false {
                            if let message = jsonData["message"].string {
                                completion(message.errorDescription)
                            }
                        }
                    } catch {
                        print("JSON Error: \(error)")
                        completion(APIErrors.jsonParseError.rawValue)
                    }
                }
            }
        }
        
        static func getTaxRates(completion: @escaping(_ error: Error?, _ data: [TaxRate]?) -> Void) {
            guard let urlString = URL(string: "\(address)GetTaxRates") else { return }
            guard let authToken = UserDefaults.standard.value(forKey: "authToken") else {
                completion(APIErrors.authError, nil)
                return
            }
            
            let poststring = "token=\(authToken)"
            let request = generateRequest(url: urlString, poststring: poststring)
            var taxRates: [TaxRate] = [TaxRate]()
            Alamofire.request(request).responseJSON { (response) in
                if let error = response.error {
                    print(error)
                    completion(error.localizedDescription, nil)
                    return
                }
                
                if let data = response.data {
                    do {
                        let json = try JSON(data: data)
                        let result = json["result"].boolValue
                        if result {
                            if let taxes = json["taxRates"].array {
                                for taxRate in taxes {
                                    if let id = taxRate["id"].int,
                                        let name = taxRate["name"].string,
                                        let rate = taxRate["rate"].float,
                                        let isDefault = taxRate["isDefault"].bool {
                                        
                                        let newRate = TaxRate(id: id, name: name, rate: rate, isDefault: isDefault)
                                        taxRates.append(newRate)
                                    }
                                }
                            }
                            completion(nil, taxRates)
                        } else {
                            if let message = json["message"].string {
                                completion(message, nil)
                            }
                        }
                    } catch {
                        print("JSON Error: \(error)")
                        completion(APIErrors.jsonParseError, nil)
                    }
                    
                }
            }
        }
        
        static func saveTaxRate(taxRate: TaxRate, isNew: Bool, completion: @escaping (_ error: Error?) -> Void) {
            guard let urlString = URL(string: "\(address)SaveTaxRate") else { return }
            guard let authToken = UserDefaults.standard.value(forKey: "authToken") else {
                completion(APIErrors.authError)
                return
            }
            let taxRateId: String = {
                if isNew {
                    return "new'"
                } else {
                    return "\(taxRate.id)"
                }
            }()
            let poststring = "token=\(authToken)&id=\(taxRateId)"
            let request = generateRequest(url: urlString, poststring: poststring)
            Alamofire.request(request).responseJSON { (response) in
                if let error = response.error {
                    print(error)
                    completion(error.localizedDescription)
                    return
                }
                
                if let data = response.data {
                    do {
                        let json = try JSON(data: data)
                        let result = json["result"].boolValue
                        if result {
                            completion(nil)
                        } else {
                            if let message = json["message"].string {
                                completion(message)
                            }
                        }
                    } catch {
                        print("JSON Error: \(error)")
                        completion(APIErrors.jsonParseError)
                    }
                }
            }
        }
        
        static func deleteTaxRate(taxRate: TaxRate, completion: @escaping (_ error: Error?) -> Void) {
            guard let urlString = URL(string: "\(address)DeleteTaxRate") else { return }
            guard let authToken = UserDefaults.standard.value(forKey: "authToken") else {
                completion(APIErrors.authError)
                return
            }
            
            let poststring = "token=\(authToken)&id=\(taxRate.id)"
            let request = generateRequest(url: urlString, poststring: poststring)
            Alamofire.request(request).responseJSON { (response) in
                if let error = response.error {
                    print(error)
                    completion(error.localizedDescription)
                    return
                }
                
                if let data = response.data {
                    do {
                        let json = try JSON(data: data)
                        let result = json["result"].boolValue
                        if result {
                            completion(nil)
                        } else {
                            if let message = json["message"].string {
                                completion(message)
                            }
                        }
                    } catch {
                        print("JSON Error: \(error)")
                        completion(APIErrors.jsonParseError)
                    }
                }
            }
        }
        
        static func emailInvoice(invoice: InvoiceStruct, completion: @escaping (_ error: Error?) -> Void) {
            guard let urlString = URL(string: "\(address)DeleteTaxRate") else { return }
            guard let authToken = UserDefaults.standard.value(forKey: "authToken") else {
                completion(APIErrors.authError)
                return
            }
            guard let invoiceId = invoice.id else { completion(APIErrors.noIdError); return }
            let poststring = "token=\(authToken)&id=\(invoiceId)"
            let request = generateRequest(url: urlString, poststring: poststring)
            Alamofire.request(request).responseJSON { (response) in
                if let error = response.error {
                    print(error)
                    completion(error.localizedDescription)
                    return
                }
                
                if let data = response.data {
                    do {
                        let json = try JSON(data: data)
                        let result = json["result"].boolValue
                        if result {
                            completion(nil)
                        } else {
                            if let message = json["message"].string {
                                completion(message)
                            }
                        }
                    } catch {
                        print("JSON Error: \(error)")
                        completion(APIErrors.jsonParseError)
                    }
                }
            }
        }
        
        static func requestSignature(for invoice: InvoiceStruct, completion: @escaping (_ error: Error?) -> Void) {
            guard let urlString = URL(string: "\(address)RequestSignature") else { return }
            guard let authToken = UserDefaults.standard.value(forKey: "authToken") else {
                completion(APIErrors.authError)
                return
            }
            guard let invoiceId = invoice.id else { completion(APIErrors.noIdError); return }
            let poststring = "token=\(authToken)&id=\(invoiceId)"
            let request = generateRequest(url: urlString, poststring: poststring)
            Alamofire.request(request).responseJSON { (response) in
                if let error = response.error {
                    print(error)
                    completion(error.localizedDescription)
                    return
                }
                
                if let data = response.data {
                    do {
                        let json = try JSON(data: data)
                        let result = json["result"].boolValue
                        if result {
                            completion(nil)
                        } else {
                            if let message = json["message"].string {
                                completion(message)
                            }
                        }
                    } catch {
                        print("JSON Error: \(error)")
                        completion(APIErrors.jsonParseError)
                    }
                }
            }
        }
        
        static func convertToInvoice(invoice: InvoiceStruct, completion: @escaping (_ error: Error?) -> Void) {
            guard let urlString = URL(string: "\(address)ConvertToInvoice") else { return }
            guard let authToken = UserDefaults.standard.value(forKey: "authToken") else {
                completion(APIErrors.authError)
                return
            }
            guard let invoiceId = invoice.id else { completion(APIErrors.noIdError); return }
            let poststring = "token=\(authToken)&id=\(invoiceId)"
            let request = generateRequest(url: urlString, poststring: poststring)
            Alamofire.request(request).responseJSON { (response) in
                if let error = response.error {
                    print(error)
                    completion(error.localizedDescription)
                    return
                }
                
                if let data = response.data {
                    do {
                        let json = try JSON(data: data)
                        let result = json["result"].boolValue
                        if result {
                            completion(nil)
                        } else {
                            if let message = json["message"].string {
                                completion(message)
                            }
                        }
                    } catch {
                        print("JSON Error: \(error)")
                        completion(APIErrors.jsonParseError)
                    }
                }
            }
        }
        
        static func signInvoice(invoice: InvoiceStruct, signature: UIImage, completion: @escaping (_ error: Error?) -> Void) {
            guard let urlString = URL(string: "\(address)SignInvoice") else { return }
            guard let authToken = UserDefaults.standard.value(forKey: "authToken") else {
                completion(APIErrors.authError)
                return
            }
            guard let invoiceId = invoice.id else { completion(APIErrors.noIdError); return }
            let signatureString = convertImageToBase64(image: signature)
            let poststring = "token=\(authToken)&id=\(invoiceId)&signature=\(signatureString)"
            let request = generateRequest(url: urlString, poststring: poststring)
            Alamofire.request(request).responseJSON { (response) in
                if let error = response.error {
                    print(error)
                    completion(error.localizedDescription)
                    return
                }
                
                if let data = response.data {
                    do {
                        let json = try JSON(data: data)
                        let result = json["result"].boolValue
                        if result {
                            completion(nil)
                        } else {
                            if let message = json["message"].string {
                                completion(message)
                            }
                        }
                    } catch {
                        print("JSON Error: \(error)")
                        completion(APIErrors.jsonParseError)
                    }
                }
            }
        }
    }

    enum Users {
        static func getUsers(completion: @escaping (_ error: Error?, _ data: [UserStruct]?) -> Void) {
            guard let urlString = URL(string: "\(address)GetUsers") else { return }
            guard let authToken = UserDefaults.standard.value(forKey: "authToken") else {
                completion(APIErrors.authError, nil)
                return
            }
            
            let poststring = "token=\(authToken)"
            let request = generateRequest(url: urlString, poststring: poststring)
            var userData: [UserStruct] = [UserStruct]()
            Alamofire.request(request).responseJSON { (response) in
                if let error = response.error {
                    print(error)
                    completion(error.localizedDescription, nil)
                    return
                }
                
                if let data = response.data {
                    do {
                        let json = try JSON(data: data)
                        let result = json["result"].boolValue
                        if result {
                            if let users = json["users"].array {
                                for user in users {
                                    print(user)
                                    if let lastName = user["lastName"].string,
                                        let firstName = user["firstName"].string,
                                        let email = user["email"].string,
                                        let status = user["status"].string,
                                        let id = user["id"].int,
                                        let inventory = user["access"]["inventory"].int,
                                        let usersAcc = user["access"]["users"].int,
                                        let customers = user["access"]["customers"].int,
                                        let dashboard = user["access"]["dashboard"].int,
                                        let invoicing = user["access"]["invoicing"].int,
                                        let calendar = user["access"]["calendar"].int {
                                        
                                        let accessControl = UserAccessControl(inventory: inventory, users: usersAcc, customers: customers, dashboard: dashboard, invoicing: invoicing, calendar: calendar)
                                        let newUser = UserStruct(firstName: firstName, lastName: lastName, status: status, email: email, id: id, access: accessControl)
                                        userData.append(newUser)
                                    } else {
                                        print("No User Info")
                                    }
                                }
                            } else {
                                print("No User Data")
                                completion(APIErrors.jsonParseError, nil)
                            }
                            completion(nil, userData)
                        } else {
                            if let message = json["message"].string {
                                completion(message, nil)
                            }
                        }
                    } catch {
                        print("JSON Error: \(error)")
                        completion(APIErrors.jsonParseError, nil)
                    }
                    
                }
            }
        }
        
        static func setUserStatus(for user: UserStruct, status: String, completion: @escaping (_ error: Error?) -> Void) {
            guard let urlString = URL(string: "\(address)SetUserStatus") else { return }
            guard let authToken = UserDefaults.standard.value(forKey: "authToken") else {
                completion(APIErrors.authError)
                return
            }
            
            let poststring = "token=\(authToken)&id=\(user.id)&status=\(status)"
            let request = generateRequest(url: urlString, poststring: poststring)
            Alamofire.request(request).responseJSON { (response) in
                if let error = response.error {
                    print(error)
                    completion(error.localizedDescription)
                    return
                }
                
                if let data = response.data {
                    do {
                        let json = try JSON(data: data)
                        let result = json["result"].boolValue
                        if result {
                            completion(nil)
                        } else {
                            if let message = json["message"].string {
                                completion(message)
                            }
                        }
                    } catch {
                        print("JSON Error: \(error)")
                        completion(APIErrors.jsonParseError)
                    }
                }
            }
        }
        
        static func changeMyPassword(password: Password, completion: @escaping (_ error: Error?) -> Void) {
            guard let urlString = URL(string: "\(address)ChangeMyPassword") else { return }
            guard let authToken = UserDefaults.standard.value(forKey: "authToken") else {
                completion(APIErrors.authError)
                return
            }
            
            let poststring = "token=\(authToken)&currentPassword=\(password.current)&newPassword=\(password.new)&verifyPassword=\(password.verify)"
            let request = generateRequest(url: urlString, poststring: poststring)
            Alamofire.request(request).responseJSON { (response) in
                if let error = response.error {
                    print(error)
                    completion(error.localizedDescription)
                    return
                }
                
                if let data = response.data {
                    do {
                        let json = try JSON(data: data)
                        let result = json["result"].boolValue
                        if result {
                            completion(nil)
                        } else {
                            if let message = json["message"].string {
                                completion(message)
                            }
                        }
                    } catch {
                        print("JSON Error: \(error)")
                        completion(APIErrors.jsonParseError)
                    }
                }
            }
        }
        
        static func saveMyProfile(for user: UserStruct, completion: @escaping (_ error: Error?) -> Void) {
            guard let urlString = URL(string: "\(address)SaveMyProfile") else { return }
            guard let authToken = UserDefaults.standard.value(forKey: "authToken") else {
                completion(APIErrors.authError)
                return
            }
            
            let poststring = "token=\(authToken)&firstName=\(user.firstName)&lastName=\(user.lastName)&email=\(user.email)"
            let request = generateRequest(url: urlString, poststring: poststring)
            Alamofire.request(request).responseJSON { (response) in
                if let error = response.error {
                    print(error)
                    completion(error.localizedDescription)
                    return
                }
                
                if let data = response.data {
                    do {
                        let json = try JSON(data: data)
                        let result = json["result"].boolValue
                        if result {
                            completion(nil)
                        } else {
                            if let message = json["message"].string {
                                completion(message)
                            }
                        }
                    } catch {
                        print("JSON Error: \(error)")
                        completion(APIErrors.jsonParseError)
                    }
                }
            }
        }
        
        static func saveCompanyInfo(for company: Company, completion: @escaping (_ error: Error?) -> Void) {
            guard let urlString = URL(string: "\(address)SaveCompanyInfo") else { return }
            guard let authToken = UserDefaults.standard.value(forKey: "authToken") else {
                completion(APIErrors.authError)
                return
            }
            let companyLogo: String = {
                if let imageData = company.logo as Data? {
                    if let newImage = UIImage(data: imageData as Data) {
                        return convertImageToBase64(image: newImage)
                    }
                } else {
                    print("Error Loading Image Data")
                }
                return "clear"
            }()
            
            let poststring = "token=\(authToken)&companyName=\((company.name)!)&companyStreet=\(company.street ?? "")&companyCity=\(company.city ?? "")&companyState=\(company.state ?? "")&companyZip=\(company.zip ?? "")&companyPhone=\(company.phone ?? "")&companyEmail=\(company.companyEmail ?? "")companyEmailName=\(company.emailName ?? "")&companyLogo=\(companyLogo)"
            let request = generateRequest(url: urlString, poststring: poststring)
            Alamofire.request(request).responseJSON { (response) in
                if let error = response.error {
                    print(error)
                    completion(error.localizedDescription)
                    return
                }
                
                if let data = response.data {
                    do {
                        let json = try JSON(data: data)
                        let result = json["result"].boolValue
                        if result {
                            completion(nil)
                        } else {
                            if let message = json["message"].string {
                                completion(message)
                            }
                        }
                    } catch {
                        print("JSON Error: \(error)")
                        completion(APIErrors.jsonParseError)
                    }
                }
            }
        }
    }
    
    enum Calendar {
        static func getEvents(completion: @escaping (_ error: Error?, _ data: [CalendarEvnt]?) -> Void) {
            guard let urlString = URL(string: "\(address)GetEvents") else { return }
            guard let authToken = UserDefaults.standard.value(forKey: "authToken") else {
                completion(APIErrors.authError.rawValue, nil)
                return
            }
            let poststring = "authToken=\(authToken)"
            let request = generateRequest(url: urlString, poststring: poststring)
            var calendarEvents: [CalendarEvnt] = [CalendarEvnt]()
            let dateFormatter = DateFormatter()
            Alamofire.request(request).responseJSON { (response) in
                if let error = response.error {
                    print(error)
                    completion(error, nil)
                    return
                }
                
                if let data = response.data {
                    do {
                        let json = try JSON(data: data)
                        let result = json["result"].boolValue
                        if result {
                            if let eventData = json["events"].array {
                                dateFormatter.dateFormat = "yyyy-MM-dd' 'HH:mm:ss"
                                for event in eventData {
                                    if let allDay = event["allDay"].bool,
                                        let id = event["id"].int,
                                        let description = event["description"].string,
                                        let end = event["end"].string,
                                        let start = event["start"].string,
                                        let customer = event["customer"].int,
                                        let street = event["address"]["street"].string,
                                        let city = event["address"]["city"].string,
                                        let state = event["address"]["state"].string,
                                        let zip = event["address"]["zip"].string,
                                        let type = event["type"].string,
                                        let font = event["font"].string,
                                        let title = event["title"].string,
                                        let background = event["background"].string {
                                        
                                        let day = start.split(separator: " ")
                                        let newEvent = CalendarEvnt(allDay: allDay, title: title, background: background, font: font, street: street, city: city, state: state, zip: zip, startDay: String(day[0]), eventType: type, desc: description, company: 0, customer: customer, id: id, startDate: dateFormatter.date(from: start)!, endDate: dateFormatter.date(from: end)!)
                                        calendarEvents.append(newEvent)
                                        
                                    }
                                }
                                
                                completion(nil, calendarEvents)
                            } else {
                                print("Event Data Error")
                                completion(APIErrors.jsonParseError, nil)
                            }
                        } else {
                            if let message = json["message"].string {
                                completion(message.errorDescription, nil)
                            }
                        }
                    } catch {
                        print("JSON Error: \(error)")
                        completion(APIErrors.jsonParseError, nil)
                    }
                }
            }
        }
    
        static func deleteEvent(event: CalendarEvnt, completion: @escaping (_ error: Error?) -> Void) {
            guard let urlString = URL(string: "\(address)DeleteEvent") else { return }
            guard let authToken = UserDefaults.standard.value(forKey: "authToken") else {
                completion(APIErrors.authError)
                return
            }
            let poststring = "authToken=\(authToken)&id=\(event.id)"
            let request = generateRequest(url: urlString, poststring: poststring)
            Alamofire.request(request).responseJSON { (response) in
                if let error = response.error {
                    print(error)
                    completion(error.localizedDescription)
                    return
                }
                
                if let data = response.data {
                    do {
                        let json = try JSON(data: data)
                        let result = json["result"].boolValue
                        if result {
                            completion(nil)
                        } else {
                            if let message = json["message"].string {
                                completion(message)
                            }
                        }
                    } catch {
                        print("JSON Error: \(error)")
                        completion(APIErrors.jsonParseError.rawValue)
                    }
                    
                }
            }
        }
    
        static func saveEvent(event: CalendarEvnt, isNew: Bool, completion: @escaping (_ error: Error?) -> Void) {
            guard let urlString = URL(string: "\(address)SaveEvent") else { return }
            guard let authToken = UserDefaults.standard.value(forKey: "authToken") else {
                completion(APIErrors.authError.rawValue)
                return
            }
            let eventId: String = {
                if isNew {
                    return "new"
                } else {
                    return String(event.id)
                }
            }()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let poststring = "token=\(authToken)&id=\(eventId)&type=\(event.eventType)&start=\(event.startDay)&end=\(dateFormatter.string(from: event.endDate))&notes=\(event.desc)&title=\(event.title)&street=\(event.street)&city=\(event.city)&state=\(event.state)&zip=\(event.zip)&customer=\(event.customer)&allDay=\(event.allDay)"
            let request = generateRequest(url: urlString, poststring: poststring)
            Alamofire.request(request).responseJSON { (response) in
                if let error = response.error {
                    print(error)
                    completion(error.localizedDescription)
                    return
                }
                
                if let data = response.data {
                    do {
                        let json = try JSON(data: data)
                        let result = json["result"].boolValue
                        if result {
                            completion(nil)
                        } else {
                            if let message = json["message"].string {
                                completion(message)
                            }
                        }
                    } catch {
                        print("JSON Error: \(error)")
                        completion(APIErrors.jsonParseError.rawValue)
                    }
                    
                }
            }
        }
    
        static func saveType(type: Calendar_Type, isNew: Bool, completion: @escaping (_ error: Error?) -> Void) {
            guard let urlString = URL(string: "\(address)SaveCalendarType") else { return }
            guard let authToken = UserDefaults.standard.value(forKey: "authToken") else {
                completion(APIErrors.authError)
                return
            }
            let typeId: String = {
                if isNew {
                    return "new"
                } else {
                    return String(type.id)
                }
            }()
            let poststring = "token=\(authToken)&id=\(typeId)&name=\(type.name)&font=\(type.fontColor)&background=\(type.background)"
            let request = generateRequest(url: urlString, poststring: poststring)
            Alamofire.request(request).responseJSON { (response) in
                if let error = response.error {
                    print(error)
                    completion(error.localizedDescription)
                    return
                }
                
                if let data = response.data {
                    do {
                        let json = try JSON(data: data)
                        let result = json["result"].boolValue
                        if result {
                            completion(nil)
                        } else {
                            if let message = json["message"].string {
                                completion(message)
                            }
                        }
                    } catch {
                        print("JSON Error: \(error)")
                        completion(APIErrors.jsonParseError.rawValue)
                    }
                    
                }
            }
        }
        
        static func deleteType(type: Calendar_Type, completion: @escaping (_ error: Error?) -> Void) {
            guard let urlString = URL(string: "\(address)DeleteCalendarType") else { return }
            guard let authToken = UserDefaults.standard.value(forKey: "authToken") else {
                completion(APIErrors.authError)
                return
            }
            
            let poststring = "token=\(authToken)&id=\(type.id)&name=\(type.name)&font=\(type.fontColor)&background=\(type.background)"
            let request = generateRequest(url: urlString, poststring: poststring)
            Alamofire.request(request).responseJSON { (response) in
                if let error = response.error {
                    print(error)
                    completion(error.localizedDescription)
                    return
                }
                
                if let data = response.data {
                    do {
                        let json = try JSON(data: data)
                        let result = json["result"].boolValue
                        if result {
                            completion(nil)
                        } else {
                            if let message = json["message"].string {
                                completion(message)
                            }
                        }
                    } catch {
                        print("JSON Error: \(error)")
                        completion(APIErrors.jsonParseError.rawValue)
                    }
                    
                }
            }
        }
    
    }
    
    
    //MARK:Helper functions
    
    static private func createPostData(from accessLevels: [UserAccess]) -> String {
        var accessArray = [[String: AnyObject]]()
        
        for access in accessLevels {
            let accessLevel: [String: Any] = ["userId"     : access.userId,
                                              "accessLevel": access.access]
            accessArray.append(accessLevel as [String : AnyObject])
        }
        return accessArray.toJSONString()
    }
    
    ///Creates Poststring for Invoice
    static private func createPoststring(for invoice: InvoiceStruct, invType: InvoiceType, billCustomer: CustomerStruct, shipCustomer: CustomerStruct?) -> String {
        var authToken = ""
        var pricePoint = ""
        var totalAmount: Float = 0.0
        var remainingAmount: Float = 0.0
        var invoiceItems = [[String: AnyObject]]()
        var invoicePymnts = [[String: AnyObject]]()
        var invoiceDpsts = [[String: AnyObject]]()
        var invoiceAttachments = [[String: AnyObject]]()
        var components = [[String: AnyObject]]()
        var shipToCustomer: [String: AnyObject]
        var shipToAddress: [String: AnyObject]
        var shipToCityStateZip: [String: AnyObject]
        var shipToEmail: [String: AnyObject]
        var shipToPhone: [String: AnyObject]
        
        //JSON for Post String
        let invoiceId: String = {
            if invoice.id == 0 {
                return "new"
            } else {
                if let id = invoice.id {
                    return String(id)
                }
                return ""
            }
        }()
        
        let invoiceType: String = {
            if let inType = invoice.type {
                return inType.lowercased()
            } else {
                return "estimate"
            }
        }()
        
        if let auth = UserDefaults.standard.value(forKey: "authToken") as? String {
            authToken = auth
        }
        
        if let total = invoice.total {
            totalAmount = Float(total)
        }
        
        if let remaining = invoice.remaining {
            if let remainingFlt = Float.init(remaining) {
                remainingAmount = remainingFlt
            }
        }
        
        if let pricePt = invoice.pricePoint {
            pricePoint = pricePt.lowercased()
        }
        
        //MARK: Invoice Items
        if let items = invoice.items {
            for item in items {
                let newItem: [String: Any] = ["uuid" : item.uuid,
                                              "itemId" : item.id,
                                              "description" : item.description.percentEncodeForAPI(),
                                              "quantity" : item.quantity,
                                              "price" : item.price,
                                              "regular" : item.regular,
                                              "afterHours" : item.afterHours,
                                              "emergency" : item.emergency,
                                              "notes" : item.notes.percentEncodeForAPI(),
                                              "cost" : item.cost]
                invoiceItems.append(newItem as [String : AnyObject])
            }
            
            
        }
        
        //MARK: Invoice Payments
        if let payments = invoice.payments {
            for payment in payments {
                let newPayment: [String: Any] = ["id" : payment.id,
                                                 "date" : payment.dateTime.percentEncodeForAPI(),
                                                 "number" : payment.number.percentEncodeForAPI(),
                                                 "type" : payment.type.percentEncodeForAPI(),
                                                 "method" : payment.method.percentEncodeForAPI(),
                                                 "amount" : payment.amount.percentEncodeForAPI()]
                invoicePymnts.append(newPayment as [String : AnyObject])
            }
            
        }
        
        //MARK: Invoice Deposits
        if let deposits = invoice.deposits {
            for deposit in deposits {
                let newDeposit: [String: Any] = ["type" : deposit.type.percentEncodeForAPI(),
                                                 "amount" : deposit.amount.percentEncodeForAPI()]
                invoiceDpsts.append(newDeposit as [String : AnyObject])
            }
        }
        
        //MARL: Attachments
        if let attachments = invoice.attachments {
            for attachment in attachments {
                let base64 = convertImageToBase64(image: attachment)
                let newAttachment = ["type" : "image",
                                     "content" : base64]
                invoiceAttachments.append(newAttachment as [String : AnyObject])
            }
            
        }
        
        //MARK: Components
        let invoiceNumb: String = {
            if let invNum = invoice.invoiceNumber {
                return invNum
            } else {
                return ""
            }
        }()
        
        let companyAddress: [String: Any] = ["component" : "company-address",
                                             "value" : (invoice.companyAddress)!]
        let companyCity: [String: Any] = ["component" : "company-city",
                                          "value" : (invoice.companyCity)!]
        let companyEmail: [String: Any] = ["component" : "company-email",
                                           "value" : (invoice.companyEmail)!]
        let companyPhone: [String: Any] = ["component" : "company-phone",
                                           "value" : (invoice.companyPhone)!]
        let invoiceDate: [String: Any] = ["component" : "invoice-date",
                                          "value" : (invoice.dateInvoiced)!]
        let invoiceNumber: [String: Any] = ["component" : "invoice-number",
                                            "value" : invoiceNumb]
        let billToCustomer: [String: Any] = ["component" : "bill-to-customer",
                                             "value" : billCustomer.id]
        let billToAddress = ["component" : "bill-to-address", //MARK: Billing address
            "value" : invoice.billingAddress?.address.percentEncodeForAPI() ?? ""]
        let billToCityStateZip: [String: Any] = ["component" : "bill-to-city-state-zip",
                                                 "value" : invoice.billingAddress?.cityStateZip.percentEncodeForAPI() ?? ""]
        let billToPhone: [String: Any] = ["component" : "bill-to-phone",
                                          "value" : invoice.billingAddress?.phone.percentEncodeForAPI() ?? ""]
        let billToEmail: [String: Any] = ["component" : "bill-to-email",
                                          "value" : invoice.billingAddress?.email.percentEncodeForAPI() ?? ""]
        
        if shipCustomer != nil {
            shipToCustomer = ["component" : "ship-to-customer",
                              "value" : shipCustomer!.id] as [String : AnyObject]
            shipToAddress = ["component" : "ship-to-address", //MARK: Shipping address
                "value" : invoice.shippingAddress?.address.percentEncodeForAPI() ?? "" ] as [String : AnyObject]
            shipToCityStateZip = ["component" : "ship-to-city-state-zip",
                                  "value" : "\(invoice.shippingAddress?.cityStateZip.percentEncodeForAPI() ?? "")"] as [String : AnyObject]
            shipToPhone = ["component" : "ship-to-phone",
                           "value" : invoice.shippingAddress?.phone.percentEncodeForAPI() ?? ""] as [String : AnyObject]
            shipToEmail = ["component" : "ship-to-email",
                           "value" : invoice.shippingAddress?.email.percentEncodeForAPI() ?? ""] as [String : AnyObject]
            
            components.append(shipToCustomer as [String : AnyObject])
            components.append(shipToAddress as [String : AnyObject])
            components.append(shipToCityStateZip as [String : AnyObject])
            components.append(shipToPhone as [String : AnyObject])
            components.append(shipToEmail as [String : AnyObject])
        } else {
            print("No Shipping Customer")
        }
        
        let invoiceNotes: [String: Any] = ["component" : "invoice-notes",
                                           "value" : (invoice.notes)!]
        let taxRate: [String: Any] = ["component" : "tax-rate",
                                      "value" : invoice.taxRate!.rate,
                                      "id" : invoice.taxRate!.id]
        let reqSig: [String: Any] = ["component" : "invoice-customer-signature",
                                     "value" : "\((invoice.signatureRequired)!)"]
        
        components.append(companyAddress as [String : AnyObject])
        components.append(companyCity as [String : AnyObject])
        components.append(companyPhone as [String : AnyObject])
        components.append(companyEmail as [String : AnyObject])
        components.append(invoiceDate as [String : AnyObject])
        components.append(invoiceNumber as [String : AnyObject])
        components.append(billToCustomer as [String : AnyObject])
        components.append(billToAddress as [String : AnyObject])
        components.append(billToCityStateZip as [String : AnyObject])
        components.append(billToPhone as [String : AnyObject])
        components.append(billToEmail as [String : AnyObject])
        components.append(invoiceNotes as [String : AnyObject])
        components.append(taxRate as [String : AnyObject])
        components.append(reqSig as [String : AnyObject])
        
        return "token=\(authToken)&id=\(invoiceId)&type=\(invType.rawValue.percentEncodeForAPI())&total=\(totalAmount)&remaining=\(remainingAmount)&pricePoint=\(pricePoint.percentEncodeForAPI())&invoiceType=\(invoiceType.percentEncodeForAPI())&template=\(invoiceType.percentEncodeForAPI())&items=\(invoiceItems.toJSONString())&payments=\(invoicePymnts.toJSONString())&deposits=\(invoiceDpsts.toJSONString())&attachments=\(invoiceAttachments.toJSONString())&components=\(components.toJSONString())"
        
    }
    
    
    
    
    
    
}

