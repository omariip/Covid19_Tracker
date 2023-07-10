//
//  CovidViewModel.swift
//  Data view model
//  Assignment2_omar
//
//  Created by Omar Abou Chaer on 2022-11-29.
//  Email: abouchae@sheridancollege.ca

import Foundation

// entity struct
struct CovidData: Codable {
    var provinceName: String = ""
    var date: String = ""
    var totalCases: Int = 0
    var weeklyCases: Int = 0
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        provinceName = try container.decode(String.self, forKey: .provinceName)
        date = try container.decode(String.self, forKey: .date)
        totalCases = Int(try container.decode(String.self, forKey: .totalCases)) ?? 0
        weeklyCases = Int(Double(try container.decode(String.self, forKey: .weeklyCases)) ?? 0.0)
    }
    
    enum CodingKeys: String, CodingKey {
        case provinceName = "prname"
        case date = "date"
        case totalCases = "totalcases"
        case weeklyCases = "numtotal_last7"
    }
}

class CovidViewModel: ObservableObject {
    
    // properties
    @Published var loadingFailed = false // for alert()
    var jsonData: [CovidData] = []
    var provinceData: [CovidData] = []
    var provinces = [0: "Canada", 1: "Ontario", 2: "Quebec", 3: "British Columbia", 4: "Alberta", 5: "Manitoba"]
    @Published var currentWeekIndex = 0
    @Published var currentWeeklyCases: Int = 0
    @Published var currentTotalCases: Int = 0
    @Published var weeks: [String] = []
    @Published var currentProvinceIndex = 0
    @Published var message = WebViewMessage()
    
    // functions
    func fetchData() {
        let urlString = "https://health-infobase.canada.ca/src/data/covidLive/covid19.json"
        guard let url = URL(string: urlString) else {
            // show alert
            print("Failed to generate url")
            return
        }
        
        // create URLSessionData Task
        // see lab 9
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            // 1. check error
            if error != nil {
                DispatchQueue.main.async {
                    self.loadingFailed = true
                }
            }
            // 2. check data
            guard let data = data else {
                self.loadingFailed = true
                return
            }
            //dump(data)
            // 3. decode JSON
            if let json = try? JSONDecoder().decode([CovidData].self, from: data) {
                // update the data in main thread
                DispatchQueue.main.async {
                    //dump(json)
                    self.jsonData = json
                    self.parseJson()
                }
            } else {
                self.loadingFailed = true
                return
            }
        }
        task.resume()
    }
    
    // process JSON
    func parseJson() {
        // set date format as ISO
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // compute # of dates to set the array size of values
        let SEC_PER_WEEK: Double = 60 * 60 * 24 * 7
        let firstWeek = dateFormatter.date(from: jsonData[0].date) ?? Date()
        let lastWeek = dateFormatter.date(from: jsonData[jsonData.count - 1].date) ?? Date()
        let sec = lastWeek.timeIntervalSince(firstWeek)
        let weekCount = Int(sec / SEC_PER_WEEK + 0.5) + 1
        //print(weekCount)
        
        // resize weeks array
        self.weeks = [String](repeating: "", count: weekCount)
        
        // fill the array
        for i in 0 ..< weekCount {
            let week = firstWeek + (Double(i) * SEC_PER_WEEK) // sec
            self.weeks[i] = dateFormatter.string(from: week) // sec -> "yyyy-MM-dd"
        }

        // make sure the current index is the latest
        currentWeekIndex = weeks.count - 1
        print(currentWeekIndex)
        //        provinceData = jsonData.filter { $0.provinceName == provinces[currentProvinceIndex] }
        changeProvince()
    }
    
    // handle province changes
    func changeProvince() {
        if(jsonData.count != 0) {
            
            
            provinceData = jsonData.filter { $0.provinceName == provinces[currentProvinceIndex] }
            
            let values = provinceData.map { $0.weeklyCases }

            var dict: [String:Any] = [:]
            dict["xs"] = weeks
            dict["ys"] = values
            let json = toJsonString(from: dict)
            //print(json)
            message.js = "drawChart(\(json))"
            
            changeWeek()
        }
    }
    
    // handle week changes
    func changeWeek() {
        if(jsonData.count != 0) {
            currentWeeklyCases = provinceData[currentWeekIndex].weeklyCases
            currentTotalCases = provinceData[currentWeekIndex].totalCases
        }
        
    }
}

// utility function to convert Swift object to JSON string
func toJsonString(from: Any) -> String
{
    // NOTE: you may use JSONEncoder instead,
    // but the object must conform Encodable protocol
    if let data = try? JSONSerialization.data(withJSONObject: from,
                                              options: []),
       let jsonString = String(data: data, encoding: .utf8)
    {
        return jsonString
    }
    else
    {
        // failed to encode, return empty object
        return "{}"
    }
}
