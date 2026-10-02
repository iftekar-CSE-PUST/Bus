import SwiftUI

struct ContentView: View {
    @State private var isSplashActive: Bool = true
    @State private var isWebLoaded: Bool = false
    
    var body: some View {
        ZStack {
            // Main Webview
            WebViewContainer(isLoaded: $isWebLoaded)
                .ignoresSafeArea(.keyboard, edges: .bottom)
            
            // Full Screen Smooth Animated Splash Screen Overlay
            if isSplashActive {
                SplashScreenView(isActive: $isSplashActive)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea(.all)
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.all)
    }
}

#Preview {
    ContentView()
}
