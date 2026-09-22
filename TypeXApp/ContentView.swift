import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("TypeX")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                
                Text("Design your keyboard.")
                    .font(.title3)
                    .foregroundStyle(.secondary)

                KeyboardPreview()
                    .padding(.horizontal)

                Button("Customize Keyboard") {
                    // Customization screen will be added next.
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("TypeX")
        }
    }
}

private struct KeyboardPreview: View {
    private let rows = KeyboardLayout.qwerty.rows

    var body: some View {
        VStack(spacing: 7) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 5) {
                    ForEach(row, id: \.self) { key in
                        Text(key)
                            .font(.system(size: 13, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                            .background(.thinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
