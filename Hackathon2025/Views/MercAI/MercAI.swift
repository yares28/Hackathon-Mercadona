import SwiftUI

struct MercAI: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "calendar")
                    .font(.system(size: 48))
                Text("MercAI")
                    .font(.title).bold()
                Text("Contenido de ejemplo para verificar el TabView.")
                    .multilineTextAlignment(.center)
            }
            .padding()
            .navigationTitle("MercAI")
        }
    }
}
