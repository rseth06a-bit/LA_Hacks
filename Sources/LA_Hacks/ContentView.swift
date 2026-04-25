import SwiftUI

@available(macOS 11.0, *)
struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.blue)
            Text("Hello, LA Hacks!")
        }
        .padding()
    }
}

@available(macOS 11.0, *)
#Preview {
    ContentView()
}