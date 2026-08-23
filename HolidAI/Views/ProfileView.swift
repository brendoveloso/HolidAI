import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Label("Perfil", systemImage: "person.crop.circle.fill")
            } description: {
                Text("Configurações e foto de perfil estarão disponíveis futuramente.")
            }
            .navigationTitle("Perfil")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
