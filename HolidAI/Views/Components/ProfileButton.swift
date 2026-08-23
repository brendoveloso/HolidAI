import SwiftUI

struct ProfileButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "person.crop.circle.fill")
                .font(.title2)
                .frame(width: 44, height: 44)
        }
        .accessibilityLabel("Perfil")
    }
}

extension View {
    func rootHeader(profileAction: @escaping () -> Void) -> some View {
        toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ProfileButton(action: profileAction)
            }
        }
        .navigationBarTitleDisplayMode(.large)
    }
}
