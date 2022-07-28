//
//  BleView.swift
//  BlueToothDemo
//
//  Created by Ling on 2021/12/13.
//

import SwiftUI
import Charts

struct BleView: View {
    @Binding var words: String
    @EnvironmentObject var bleManager: BLEManagerVM
    
    @State var delayMicro: String = "0"
    @State var loopCount: String = "0"
    
    @State var height: CGFloat = 150
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    if bleManager.selectedDevise != nil {
                        Text("藍芽名稱: \(bleManager.selectedDevise!.peripheral.name ?? "")")
                        Text("RSSI: \(bleManager.selectedDevise!.rssi)")
                    }
                }
                .background(.gray)
                Spacer()
                Button {
                    print("disconnect...")
                    DispatchQueue.main.async {
                        bleManager.disconnect()
                        bleManager.selectedDevise = nil
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.pink)
                        .background(Color.white)
                        .clipShape(Circle())
                }
            }.padding()
            .frame(minWidth: 0, maxWidth: .infinity)
            .background(Color.gray)


            ScrollView {

                Text("控制區").font(.callout.bold())
                Divider()
                
                HStack {
                    // 燈泡區
                    Spacer()
                    Button {
                        // 燈泡
                        self.bleManager.witeValueForCharacteristic(ledData: bleManager.led)
                    } label: {
                        VStack(spacing: 10) {
                            Image(systemName: "lightbulb.circle")
                                .foregroundColor( self.bleManager.led == "0x01" ? .gray : .yellow) // or gray
                                .font(.system(size: 50))
                                .frame(height: 60)
                            Text("燈泡")
                                .font(.title3)
                        }
                        .frame(width: 130, height: 130)
                    }
                    Spacer();Divider();Spacer()
                    
                    // 電池
                    VStack(spacing: 10) {
                        Image(systemName: "battery.100")
                            .foregroundColor(.green) // or gray
                            .font(.system(size: 50))
                            .frame(height: 60)
                        Text("\(bleManager.battery) %")
                            .font(.title3)
                    }.frame(width: 130, height: 130)
                    Spacer()
                } // end HStack
                Divider()
                
                VStack {
                    HStack {
                        Image(systemName: "record.circle.fill")
                            .foregroundColor(.white) // or gray
                            .background(Color.blue)
                            .font(.system(size: 50))
                            .cornerRadius(.infinity)
                            .frame(height: 60)
                        
                        Text(bleManager.btnWords ?? "Btn State is Nil")
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    }
                }.frame( height: 130)
//                Divider()

                // 輸入區
//                VStack {
//                    Text("輸入控制")
//                    HStack {
//                        Text("Delay")
//                        TextField("", text: $delayMicro, prompt: Text("Microseconds"))
//                            .textFieldStyle(.roundedBorder)
//                            .keyboardType(.numberPad)
//                        Text("Loop")
//                        TextField("", text: $loopCount, prompt: Text("Loop"))
//                            .textFieldStyle(.roundedBorder)
//                            .keyboardType(.numberPad)
//                    }
//                    TextField("", text: $words, prompt: Text("Input messages"))
//                        .textFieldStyle(.roundedBorder)
//
//                    Button {
//                        let delay = Double(delayMicro)
//                        let loop = Int(loopCount)
//                        // 轉 二進位
//                        // 傳送...
//
//                    } label: {
//                        Text("Send")
//                            .frame(minWidth: 0, maxWidth: .infinity)
//                            .padding()
//                            .foregroundColor(Color.white)
//                            .background(Color.blue)
//                            .cornerRadius(12)
//                    }
//
//
//                }.padding(.vertical)
                Divider()
                
                VStack {
                    Chart(data: bleManager.resistorQueue.list)
                        .chartStyle(
                            AreaChartStyle(.quadCurve, fill:
                                            LinearGradient(gradient: .init(colors: [Color.blue, Color.blue.opacity(0.05)]), startPoint: .top, endPoint: .bottom)
                                          )
                        ).frame(height: 130)
                        .onAppear {
                            // 初始給值，與間隔
                            bleManager.resistorQueue.list = [Double](repeating: 0.2, count: 20)
                        }
                }.frame(height: 130)

            }.padding() // end ScrollView


        }
    }
}

struct BleView_Previews: PreviewProvider {
    static var previews: some View {
        BleView(words: .constant(""))
            .environmentObject(BLEManagerVM.init())
    }
}






/**
 * Dynamic Height for Text Field
 * 用法: DynamicHeightTextField(text: $words, height: .constant(150))
 * https://lostmoa.com/blog/DynamicHeightForTextFieldInSwiftUI/
 **/
struct DynamicHeightTextField: UIViewRepresentable {
    @Binding var text: String
    @Binding var height: CGFloat
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        
        textView.isEditable = true
        textView.isUserInteractionEnabled = true
        
        textView.isScrollEnabled = true
        textView.alwaysBounceVertical = false
        
        textView.text = text
        textView.backgroundColor = UIColor.clear
        
        context.coordinator.textView = textView
        textView.delegate = context.coordinator
        textView.layoutManager.delegate = context.coordinator
        
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(dynamicHeightTextField: self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate, NSLayoutManagerDelegate {
        
        var dynamicHeightTextField: DynamicHeightTextField
        weak var textView: UITextView?
        
        init(dynamicHeightTextField: DynamicHeightTextField) {
            self.dynamicHeightTextField = dynamicHeightTextField
        }
        
        func textViewDidChange(_ textView: UITextView) {
            self.dynamicHeightTextField.text = textView.text
        }
        
        func textView(
            _ textView: UITextView,
            shouldChangeTextIn range: NSRange,
            replacementText text: String) -> Bool {
                if (text == "\n") {
                    textView.resignFirstResponder()
                    return false
                }
                return true
            }
        
        func layoutManager(
            _ layoutManager: NSLayoutManager,
            didCompleteLayoutFor textContainer: NSTextContainer?,
            atEnd layoutFinishedFlag: Bool) {
            
            DispatchQueue.main.async { [weak self] in
                guard let view = self?.textView else {
                    return
                }
                let size = view.sizeThatFits(view.bounds.size)
                if self?.dynamicHeightTextField.height != size.height {
                    self?.dynamicHeightTextField.height = size.height
                }
            }

        }
    } // end class


}
