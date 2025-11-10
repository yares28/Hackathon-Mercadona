import SwiftUI

struct SmartPath: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "books.vertical")
                    .font(.system(size: 48))
                Text("SmartPath")
                    .font(.title).bold()
                Text("Contenido de ejemplo para verificar el TabView.")
                    .multilineTextAlignment(.center)
            }
            .padding()
            .navigationTitle("SmartPath")
        }
    }
}
