import SwiftUI

struct MainMenuView: View {
    var body: some View {
        NavigationView {
            ZStack {
                // Romanian background gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.15, blue: 0.05),
                        Color(red: 0.08, green: 0.20, blue: 0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 40) {
                    Spacer()

                    // Romanian Septica Title
                    VStack(spacing: 8) {
                        Text("🇷🇴 Septica 🇷🇴")
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.yellow, Color.red, Color.blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: .black, radius: 2, x: 1, y: 1)

                        Text("Jocul Tradițional Românesc de Cărți")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                    }

                    Spacer()

                    VStack(spacing: 20) {
                        NavigationLink(destination: GameSetupView { _ in }) {
                            MenuButtonView(
                                title: "Începe Jocul",
                                subtitle: "Joacă Septica Românească",
                                icon: "play.fill",
                                gradient: [Color.blue, Color.purple]
                            )
                            .accessibilityElement(children: .combine)
                            .accessibilityIdentifier("main-menu-start-game")
                            .accessibilityAddTraits(.isButton)
                        }

                        NavigationLink(destination: RulesView()) {
                            MenuButtonView(
                                title: "Regulile Jocului",
                                subtitle: "Învață să joci Septica",
                                icon: "book.fill",
                                gradient: [Color.orange, Color.red]
                            )
                            .accessibilityElement(children: .combine)
                            .accessibilityIdentifier("main-menu-rules")
                            .accessibilityAddTraits(.isButton)
                        }

                        NavigationLink(destination: SettingsView()) {
                            MenuButtonView(
                                title: "Setări",
                                subtitle: "Configurează jocul",
                                icon: "gearshape.fill",
                                gradient: [Color.green, Color.teal]
                            )
                            .accessibilityElement(children: .combine)
                            .accessibilityIdentifier("main-menu-settings")
                            .accessibilityAddTraits(.isButton)
                        }
                    }
                    .padding(.horizontal)

                    Spacer()
                }
                .padding()
            }
            .navigationBarHidden(true)
            .preferredColorScheme(.dark)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct MenuButtonView: View {
    let title: String
    let subtitle: String
    let icon: String
    let gradient: [Color]

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.white)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundColor(.white.opacity(0.7))
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: gradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}
