import SwiftUI

struct SplashScreenView: View {
    @Binding var isActive: Bool
    
    @State private var logoScale: CGFloat = 0.65
    @State private var logoOpacity: Double = 0.0
    @State private var titleOpacity: Double = 0.0
    @State private var titleOffset: CGFloat = 24.0
    @State private var pulseRingScale: CGFloat = 1.0
    @State private var pulseRingOpacity: Double = 0.6
    @State private var progressAmount: CGFloat = 0.0
    @State private var isDismissing: Bool = false
    
    var body: some View {
        ZStack {
            // Full screen background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.98, blue: 1.0),
                    Color(red: 0.93, green: 0.94, blue: 0.97)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea(.all)
            
            // Full screen ambient background glow
            GeometryReader { proxy in
                Circle()
                    .fill(Color(red: 0.65, green: 0.11, blue: 0.19).opacity(0.07))
                    .frame(width: proxy.size.width * 1.4)
                    .position(x: proxy.size.width * 0.85, y: proxy.size.height * 0.18)
                
                Circle()
                    .fill(Color(red: 0.20, green: 0.45, blue: 0.90).opacity(0.06))
                    .frame(width: proxy.size.width * 1.1)
                    .position(x: proxy.size.width * 0.15, y: proxy.size.height * 0.82)
            }
            .ignoresSafeArea(.all)
            
            // Centered content
            VStack(spacing: 32) {
                Spacer()
                
                // Animated Bus Logo with Radar Waves
                ZStack {
                    // Outer radar ring
                    Circle()
                        .stroke(Color(red: 0.65, green: 0.11, blue: 0.19).opacity(0.25), lineWidth: 2)
                        .frame(width: 185, height: 185)
                        .scaleEffect(pulseRingScale)
                        .opacity(pulseRingOpacity)
                    
                    // Middle radar ring
                    Circle()
                        .stroke(Color(red: 0.65, green: 0.11, blue: 0.19).opacity(0.35), lineWidth: 1.5)
                        .frame(width: 155, height: 155)
                        .scaleEffect(pulseRingScale * 0.9)
                        .opacity(pulseRingOpacity)
                    
                    // Logo Image Card
                    Image("SplashLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 135, height: 135)
                        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 30, style: .continuous)
                                .stroke(Color.white.opacity(0.9), lineWidth: 2.5)
                        )
                        .shadow(color: Color(red: 0.65, green: 0.11, blue: 0.19).opacity(0.28), radius: 28, x: 0, y: 14)
                        .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 5)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                }
                
                // Titles and Subtitles (Clean Minimalist Branding)
                VStack(spacing: 8) {
                    Text("PUST Bus Tracking")
                        .font(.system(size: 29, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.12, green: 0.14, blue: 0.18))
                        .tracking(0.3)
                    
                    Text("Pabna University of Science & Technology")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(red: 0.65, green: 0.11, blue: 0.19))
                        .tracking(0.2)
                }
                .opacity(titleOpacity)
                .offset(y: titleOffset)
                
                Spacer()
                
                // Bottom minimalist animated progress bar
                VStack(spacing: 12) {
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.gray.opacity(0.18))
                            .frame(width: 150, height: 4.5)
                        
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.65, green: 0.11, blue: 0.19),
                                        Color(red: 0.90, green: 0.25, blue: 0.20)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(150 * progressAmount, 10), height: 4.5)
                    }
                }
                .padding(.bottom, 54)
                .opacity(titleOpacity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea(.all)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.all)
        .scaleEffect(isDismissing ? 1.08 : 1.0)
        .opacity(isDismissing ? 0.0 : 1.0)
        .onAppear {
            runAnimations()
        }
    }
    
    private func runAnimations() {
        // Logo Spring In
        withAnimation(.spring(response: 0.75, dampingFraction: 0.68, blendDuration: 0)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        // Titles Slide In
        withAnimation(.easeOut(duration: 0.6).delay(0.25)) {
            titleOpacity = 1.0
            titleOffset = 0
        }
        
        // Continuous Radar Pulse
        withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true).delay(0.2)) {
            pulseRingScale = 1.25
            pulseRingOpacity = 0.0
        }
        
        // Smooth Progress Fill
        withAnimation(.easeInOut(duration: 2.1)) {
            progressAmount = 1.0
        }
        
        // Auto Dismissal after 2.3s
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.3) {
            withAnimation(.easeInOut(duration: 0.45)) {
                isDismissing = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                isActive = false
            }
        }
    }
}
