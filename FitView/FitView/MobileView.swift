//
//  MobileView.swift
//  FitView
//
//  Created by Konstantin Freiherr von Stein on 11/12/24.
//

import SwiftUI

struct MobileView: View {
    
    @StateObject var viewModel = ViewModel()
    
    var body: some View {
        
        ZStack() {
            LiveCameraImage(liveCamera: $viewModel.liveCamera)
                .colorMultiply(.pink)
                .brightness(-0.10)
                .blur(radius: 0)
                .overlay() {
                    Rectangle()
                        .fill(.black)
                        .opacity(viewModel.liveCamera != nil ? 0 : 1)
                }
            VStack() {
                Text(viewModel.distance.description)
                    .font(.system(size: 80, weight: .black, design: .default))
                    .foregroundStyle(.pink)
                
                VStack() {
                    if viewModel.selectedMode == .Pushups {
                        Text("Going Down: \(viewModel.goingDown)")
                            .font(.system(size: 30, weight: .black, design: .default))
                    } else {
                        Text("Going Down: \(viewModel.goingToKnee)")
                            .font(.system(size: 30, weight: .black, design: .default))
                    }
                }
                
                Count(situpCount: $viewModel.count, doingSitups: $viewModel.doingExercise)
                    .frame(height: 340)

                VStack(alignment: .center, spacing: 15) {
                    
                    /*
                    #if os(iOS)
                    Image(uiImage: UIImage(imageLiteralResourceName: "situpicon.png"))
                        .iconModifier()
                    #elseif os(macOS)
                    
                    #endif
                    */
                    
                    Menu(content: {
                        Button("Situps") {
                            viewModel.selectedMode = .Situps
                        }
                        Button("Squats") {
                            viewModel.selectedMode = .Squats
                        }
                        Button("Pushups") {
                            viewModel.selectedMode = .Pushups
                        }
                        Divider()
                        Button("Lunges") {
                            viewModel.selectedMode = .Lunges
                        }
                    }, label: {Text(viewModel.selectedMode.rawValue)})
                    .menuStyle(.borderlessButton)
                    .frame(width: 100)
                    .buttonModifier()
                        
                    Button(viewModel.doingExercise ? "STOP" : "START") {
                        if viewModel.doingExercise == false {
                            viewModel.startCapture()
                        } else {
                            viewModel.stopCapture()
                        }
                    }
                    .buttonModifier()

                    HStack() {
                        Button("Start C") {
                            viewModel.startLiveVideo()
                        }  
                        
                        Button("Stop C") {
                            viewModel.stopLiveVideo()
                        }
                        
                        Button("ResetCount") {
                            viewModel.count = 0
                        }
                    }
                    
                    /*
                    #if os(iOS)
                    Image(uiImage: UIImage(imageLiteralResourceName: "squatcion.png"))
                        .iconModifier()
                    #elseif os(macOS)
                    
                    #endif
                    */
                        
                    
                }
                .frame(height: 100)
            }
        }
        .background(.black)
    }
}

#Preview {
    MobileView()
        .frame(width: 600, height: 900)
}
