import SwiftUI
import IOKit.pwr_mgt


class ScreenAwakeManager: ObservableObject {
    @Published private(set) var isPreventingSleep = false
    private var assertionIDs: [IOPMAssertionID] = []
    
    func toggleSleepPrevention() {
        isPreventingSleep ? stopPreventingSleep() : startPreventingSleep()
    }
    
    private func startPreventingSleep() {
        let reason = "User requested to prevent sleep" as CFString
        var assertionID: IOPMAssertionID = 0
        
        let assertions: [(CFString, IOPMAssertionID)] = [
            (kIOPMAssertionTypePreventUserIdleSystemSleep as CFString, 0),
            (kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString, 0),
            (kIOPMAssertionTypeNoDisplaySleep as CFString, 0)
        ]
        
        for (assertionType, _) in assertions {
            let success = IOPMAssertionCreateWithName(
                assertionType,
                IOPMAssertionLevel(kIOPMAssertionLevelOn),
                reason,
                &assertionID
            )
            
            if success == kIOReturnSuccess {
                self.assertionIDs.append(assertionID)
            }
        }
        
        isPreventingSleep = !self.assertionIDs.isEmpty
    }
    
    private func stopPreventingSleep() {
        for assertionID in assertionIDs {
            IOPMAssertionRelease(assertionID)
        }
        assertionIDs.removeAll()
        isPreventingSleep = false
    }
}

struct ContentView: View {
    @StateObject private var manager = ScreenAwakeManager()
    @State private var isHovering = false
    @State private var rotationAngle: Double = 0
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            AnimatedBackground()
            
            VStack(spacing: 40) {
                Text("Luminary")
                    .font(.system(size: 36, weight: .ultraLight, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 30)
                
                ZStack {
                    Circle()
                        .fill(manager.isPreventingSleep ? Color(hex: "FFD700").opacity(0.15) : Color.white.opacity(0.05))
                        .frame(width: 180, height: 180)
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0)) {
                            manager.toggleSleepPrevention()
                            rotationAngle += 180
                            scale = 0.8
                        }
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0).delay(0.1)) {
                            scale = 1.0
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(manager.isPreventingSleep ? Color(hex: "FFD700").opacity(0.3) : Color.white.opacity(0.1))
                                .frame(width: 160, height: 160)
                            
                            Image(systemName: manager.isPreventingSleep ? "sun.max.fill" : "moon.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 80, height: 80)
                                .foregroundColor(manager.isPreventingSleep ? Color(hex: "FFD700") : .white)
                                .rotationEffect(.degrees(rotationAngle))
                                .scaleEffect(scale)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .scaleEffect(isHovering ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isHovering)
                    .onHover { hovering in
                        isHovering = hovering
                    }
                }
                .shadow(color: manager.isPreventingSleep ? Color(hex: "FFD700").opacity(0.3) : Color.white.opacity(0.1),
                        radius: 30, x: 0, y: 0)
                
                StatusView(isActive: manager.isPreventingSleep)
                
                Spacer()
            }
        }
        .frame(width: 300, height: 400)
        .preferredColorScheme(.dark)
    }
}

struct AnimatedBackground: View {
    @State private var phase: CGFloat = 0
    
    var body: some View {
        ZStack {
            RadialGradient(gradient: Gradient(colors: [Color(hex: "1A1A2E"), Color(hex: "16213E")]),
                           center: .center,
                           startRadius: 5,
                           endRadius: 300)
            
            GeometryReader { geometry in
                ForEach(0..<15) { i in
                    Circle()
                        .fill(Color.white.opacity(0.05))
                        .frame(width: CGFloat.random(in: 10...50), height: CGFloat.random(in: 10...50))
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                        .offset(y: phase)
                        .animation(
                            Animation.easeInOut(duration: Double.random(in: 5...10))
                                .repeatForever(autoreverses: true)
                                .delay(Double.random(in: 0...5)),
                            value: phase
                        )
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
                phase = 50
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct StatusView: View {
    let isActive: Bool
    @State private var offset: CGFloat = 20
    
    var body: some View {
        Text(isActive ? "Active" : "Inactive")
            .font(.system(size: 18, weight: .medium, design: .rounded))
            .foregroundColor(isActive ? Color(hex: "4CAF50") : Color(hex: "F44336"))
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(isActive ? Color(hex: "4CAF50").opacity(0.2) : Color(hex: "F44336").opacity(0.2))
            )
            .overlay(
                Capsule()
                    .stroke(isActive ? Color(hex: "4CAF50").opacity(0.5) : Color(hex: "F44336").opacity(0.5), lineWidth: 1)
            )
            .offset(y: offset)
            .animation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0), value: isActive)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0)) {
                    offset = 0
                }
            }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    ContentView()
}
