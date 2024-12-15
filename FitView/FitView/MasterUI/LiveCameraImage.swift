//
//  LiveCameraImage.swift
//  FitView
//
//  Created by Konstantin Freiherr von Stein on 12/11/24.
//

import SwiftUI

struct LiveCameraImage: View {
    
    @Binding var liveCamera: CGImage?
    
    var body: some View {
        ZStack() {
            Group {
                if let (image) = liveCamera {
                    Image(image, scale: 1.0, label: Text("Camera"))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .scaleEffect(x: -1, y: 1)
                } else {
                    HStack() {
                        Spacer()
                        VStack() {
                            Spacer()
                            Text("No camera feed available")
                            
                            Spacer()
                        }
                        Spacer()
                    }
                    .background(.red)
                }
            }
        }
    }
}

#Preview {
    LiveCameraImage(liveCamera: .constant(nil))
}
