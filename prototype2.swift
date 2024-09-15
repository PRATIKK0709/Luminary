import SwiftUI
import IOKit.pwr_mgt

@main
struct ScreenAwakeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}

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
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color(#colorLiteral(red: 0.09019608051, green: 0, blue: 0.3019607961, alpha: 1)), Color(#colorLiteral(red: 0.1215686277, green: 0.01176470611, blue: 0.4235294163, alpha: 1))]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 40) {
                Text("Luminary")
                    .font(.system(size: 32, weight: .thin, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 30)
                
                ZStack {
                    Circle()
                        .fill(manager.isPreventingSleep ? Color(#colorLiteral(red: 1, green: 0.8392156863, blue: 0.03921568627, alpha: 1)) : Color(#colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)))
                        .frame(width: 120, height: 120)
                        .shadow(color: manager.isPreventingSleep ? Color(#colorLiteral(red: 1, green: 0.8392156863, blue: 0.03921568627, alpha: 0.5)) : Color.clear, radius: 20, x: 0, y: 0)
                    
                    Image(systemName: manager.isPreventingSleep ? "sun.max.fill" : "moon.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                        .foregroundColor(.white)
                }
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0)) {
                        manager.toggleSleepPrevention()
                    }
                }
                
                Text(manager.isPreventingSleep ? "Screen Awake" : "Screen May Sleep")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(manager.isPreventingSleep ? Color(#colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)).opacity(0.3) : Color(#colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1)).opacity(0.3))
                    )
                
                Spacer()
            }
        }
        .frame(width: 300, height: 400)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}


#Preview {
    ContentView()
}
