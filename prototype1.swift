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
    @State private var isHovering = false
    
    var body: some View {
        ZStack {
            RadialGradient(gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]),
                           center: .center, startRadius: 5, endRadius: 300)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Text("Luminary")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                ZStack {
                    Circle()
                        .fill(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 200, height: 200)
                        .shadow(color: manager.isPreventingSleep ? .blue : .gray, radius: 20, x: 0, y: 0)
                    
                    Image(systemName: manager.isPreventingSleep ? "sun.max.fill" : "moon.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .foregroundColor(.white)
                }
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0)) {
                        manager.toggleSleepPrevention()
                    }
                }
                
                Text(manager.isPreventingSleep ? "Screen will stay awake" : "Screen may sleep")
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack {
                    Text("Status:")
                        .foregroundColor(.white)
                    Text(manager.isPreventingSleep ? "Active" : "Inactive")
                        .foregroundColor(manager.isPreventingSleep ? .green : .red)
                        .fontWeight(.bold)
                }
                .padding()
                .background(Color.white.opacity(0.2))
                .cornerRadius(20)
                
                Spacer()
            }
            .padding()
        }
        .frame(width: 350, height: 500)
        .background(Color.black.opacity(0.1))
        .cornerRadius(20)
    }
}

#Preview {
    ContentView()
}
