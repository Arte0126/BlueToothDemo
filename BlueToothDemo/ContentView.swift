//
//  ContentView.swift
//  BlueToothDemo
//
//  Created by Ling on 2021/12/7.
// 文獻： https://www.novelbits.io/intro-ble-mobile-development-ios-part-2/
//    https://www.novelbits.io/intro-ble-mobile-development-ios/
// 請的最清楚的：https://www.twblogs.net/a/5ba17fec2b71771a4da8d4e3
// https://www.freecodecamp.org/news/ultimate-how-to-bluetooth-swift-with-hardware-in-20-minutes/

// 將要實現 藍芽連結 寫值 收值 應用
// 將要實現 auto 連結

import SwiftUI
import CoreBluetooth

struct ContentView: View {
    @StateObject var bleManager = BLEManagerVM.init()
    
    @State var senString: String = ""
    @State var words: String = ""
    
    @State var isScannDeviseView: Bool = false
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Button {
                        // click...
                        isScannDeviseView.toggle()
                    } label: {
                        Text("藍芽掃描")
                            .foregroundColor(Color.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(15)
                            .padding()
                    }
                    if bleManager.isSwitchedOn {
                        Text("系統藍芽: 開啟")
                            .foregroundColor(.green)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .trailing)
                            .padding()
                    }else {
                        Text("系統藍芽: 關閉")
                            .foregroundColor(.red)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .trailing)
                            .padding()
                    }
                }
                Divider()
                
                if bleManager.selectedDevise != nil {
                    BleView(words: $words)
                        .environmentObject(bleManager)
                }else {
                    noConnectView()
                }
                
                
            }.navigationTitle("KYMCO")
            
                .sheet(isPresented: $isScannDeviseView, onDismiss: {
                    // onDismiss
                }, content: {
                    ScannDeviseView()
                        .environmentObject(bleManager)
                })
                
        }.navigationViewStyle(.stack)
    }
    
    func noConnectView()-> some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Text("尚未連接設備")
                Spacer()
            }
            Spacer()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}



struct ScannDeviseView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var bleManager: BLEManagerVM

    var body: some View {
        VStack {
            ZStack {
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }, label: {
                        Image(systemName: "arrow.backward")
                                .font(.largeTitle)
                            .foregroundColor(Color.gray)
                            .padding(.leading)
                    })
                }.frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                Text("Devises").font(.largeTitle)

            }.padding(.horizontal).padding(.top, 30)

            HStack {
                Button(action: {
                    self.bleManager.startScanning()
                }) {
                    Text("Start Scanning")
                        .padding()
                        .foregroundColor(Color.white)
                        .background(Color.green)
                        .cornerRadius(.infinity)
                }
                Spacer()
                Button(action: {
                    self.bleManager.stopScanning()
                }) {
                    Text("Stop Scanning")
                        .padding()
                        .foregroundColor(Color.white)
                        .background(Color.red)
                        .cornerRadius(.infinity)
                }
            }.padding()


            List {
                ForEach(bleManager.devises) { devise in
                    HStack {
                        Text("DeviseName: \(devise.peripheral.name ?? "")")
                        Spacer()
                        Text("RSSI: \(devise.rssi)")
                    }.onTapGesture(perform: {
                        bleManager.selectedDevise = devise
                        bleManager.connect(peripheral: bleManager.selectedDevise!.peripheral)
                        print("Selected \(bleManager.selectedDevise!.peripheral.name ?? "")")
                        presentationMode.wrappedValue.dismiss()
                    })
                }
            }
        }
    }
}

struct ScannDeviseView_Previews: PreviewProvider {
    static var previews: some View {
        ScannDeviseView()
            .environmentObject(BLEManagerVM.init())
    }
}
