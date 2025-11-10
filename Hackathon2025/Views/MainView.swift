import SwiftUI

struct MainView: View {
    var body: some View {
        TabView {
            MercAI()
                .tabItem {
                    Label("MercAI", systemImage: "calendar")
                }
            SmartPath()
                .tabItem {
                    Label("SmartPath", systemImage: "books.vertical")
                }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}

#Preview {
    MainView()
}
