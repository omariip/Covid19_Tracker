//
//  ContentView.swift
//  the main view of the app
//  Assignment2_omar
//
//  Created by Omar Abou Chaer on 2022-11-29.
//  Email: abouchae@sheridancollege.ca

import SwiftUI

//@@FIXME: fix overlapping touching area of 2 Picker views
//Reference: https://developer.apple.com/forums/thread/687986?answerId=706782022#706782022
extension UIPickerView {
    open override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric,
                      height: UIView.noIntrinsicMetric)
    }
}

struct ContentView: View {
    
    // properties
    @State var url: URL? = Bundle.main.url(forResource: "test_chart", withExtension: "html", subdirectory: "chart_html")
    //@StateObject var message = WebViewMessage()
    @StateObject var vm = CovidViewModel() // viewModel of the app
    var provincesPicker: [String] = ["CA", "ON", "QC", "BC", "AB", "MB"]
    
    var body: some View {
        AdaptiveStack {
            VStack {
                Text("COVID-19: \(vm.provinces[vm.currentProvinceIndex] ?? "")")
                    .font(.largeTitle)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                // province picker view
                Picker("provinces", selection: $vm.currentProvinceIndex) {
                    ForEach(0 ..< provincesPicker.count, id: \.self) { i in
                        Text(provincesPicker[i]).tag(i)
                    }
                }
                .padding(10)
                .pickerStyle(.segmented)
                .frame(height: 15)
                .onChange(of: vm.currentProvinceIndex) { tag in
                    vm.changeProvince()
                }
                
                // weeks picker view
                Picker("weeks", selection: $vm.currentWeekIndex) {
                    ForEach(0 ..< vm.weeks.count, id: \.self) { i in
                        Text(vm.weeks[i]).tag(i)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 100)
                .clipped()
                .padding(.top, 4)
                .onChange(of: vm.currentWeekIndex) { tag in
                    vm.changeWeek()
                }
                
                VStack() {
                    Text("Confirmed Cases")
                        .padding(.bottom, 1)
                    
                    HStack {
                        VStack(alignment: .trailing) {
                            Text("Weekly")
                                .font(.system(size: 18, weight: .heavy))
                            
                            
                            Text("\(vm.currentWeeklyCases)")
                                .font(.system(size: 25, weight: .regular))
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                            
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Total")
                                .font(.system(size: 18, weight: .heavy))
                            Text("\(vm.currentTotalCases)")
                                .font(.system(size: 25, weight: .regular))
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                    }
                    .padding(.bottom, 2)
                    Text(verbatim: "Source: https://health-infobase.canada.ca")
                        .font(.system(size: 12))
                        .italic()
                        .foregroundColor(.gray)
                }
            }
            
            VStack() {
                WebView(url: url, message: vm.message)
                    .onAppear{
                        vm.fetchData()
                    }
            }
            
        }.alert("Error", isPresented: $vm.loadingFailed, actions: {
            Button("Try Again", action: {
                vm.loadingFailed = false
                vm.fetchData()
            })
            Button("Cancel", action: {})
        }, message: {
            Text("Error loading the data, please check your internet connection and try again")
        })
    }
    
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
