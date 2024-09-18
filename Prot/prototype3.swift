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
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 40) {
                Text("Luminary")
                    .font(.system(size: 28, weight: .light, design: .rounded))
                    .foregroundColor(.white)
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        manager.toggleSleepPrevention()
                    }
                }) {
                    Image(systemName: manager.isPreventingSleep ? "sun.max.fill" : "moon.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .foregroundColor(manager.isPreventingSleep ? .yellow : .gray)
                }
                .buttonStyle(PlainButtonStyle())
                
                Text(manager.isPreventingSleep ? "Active" : "Inactive")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(manager.isPreventingSleep ? .green : .red)
            }
        }
        .frame(width: 250, height: 350)
    }
}


#Preview {
    ContentView()
}
