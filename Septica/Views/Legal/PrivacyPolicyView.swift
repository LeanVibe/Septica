//
//  PrivacyPolicyView.swift
//  Septica
//
//  Child-friendly privacy policy display for Romanian Septica game
//  GDPR and COPPA compliant presentation with Romanian cultural styling
//

import SwiftUI

struct PrivacyPolicyView: View {
    @ObservedObject var privacyManager: PrivacyPolicyManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingFullPolicy = false
    @State private var languageSelection: PolicyLanguage = .romanian
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header with Romanian cultural styling
                    HeaderSection()
                    
                    // Child-friendly key points
                    KeyPointsSection()
                    
                    // Language toggle
                    LanguageSelectionSection()
                    
                    // Full policy content
                    PolicyContentSection()
                    
                    // Child-friendly explanation
                    ChildFriendlySection()
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
            .navigationTitle("Confidențialitate")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Închide") {
                        privacyManager.markPrivacyPolicyAsShown()
                        dismiss()
                    }
                }
            }
            .overlay(alignment: .bottom) {
                ActionButtonsSection()
            }
        }
        .preferredColorScheme(.dark) // Romanian game aesthetic
    }
    
    @ViewBuilder
    private func HeaderSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "shield.checkered")
                    .font(.largeTitle)
                    .foregroundColor(.green)
                
                VStack(alignment: .leading) {
                    Text("Septica este sigur pentru copii")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Joc tradițional românesc, 100% confidențial")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Compliance badges
            HStack(spacing: 8) {
                ComplianceBadge(text: "GDPR ✅", color: .blue)
                ComplianceBadge(text: "COPPA ✅", color: .green)
                ComplianceBadge(text: "România ✅", color: .red)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    @ViewBuilder
    private func KeyPointsSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("De ce este sigur:")
                .font(.headline)
                .foregroundColor(.primary)
            
            ForEach(privacyManager.getPrivacyPolicyContent().keyPoints, id: \.self) { point in
                HStack(alignment: .top, spacing: 12) {
                    Text("•")
                        .font(.title2)
                        .foregroundColor(.green)
                    
                    Text(point)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.green.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    @ViewBuilder
    private func LanguageSelectionSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Limbă / Language:")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(spacing: 16) {
                Button(action: { languageSelection = .romanian }) {
                    HStack {
                        Text("🇷🇴")
                        Text("Română")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(languageSelection == .romanian ? .blue : .clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(.blue, lineWidth: 1)
                            )
                    )
                    .foregroundColor(languageSelection == .romanian ? .white : .blue)
                }
                
                Button(action: { languageSelection = .english }) {
                    HStack {
                        Text("🇬🇧")
                        Text("English")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(languageSelection == .english ? .blue : .clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(.blue, lineWidth: 1)
                            )
                    )
                    .foregroundColor(languageSelection == .english ? .white : .blue)
                }
                
                Spacer()
            }
        }
    }
    
    @ViewBuilder
    private func PolicyContentSection() -> some View {
        let content = privacyManager.getPrivacyPolicyContent()
        let displayText = languageSelection == .romanian ? content.content : content.englishContent
        
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Politica completă:")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: { showingFullPolicy.toggle() }) {
                    HStack {
                        Text(showingFullPolicy ? "Ascunde" : "Arată")
                        Image(systemName: showingFullPolicy ? "chevron.up" : "chevron.down")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            
            if showingFullPolicy {
                ScrollView {
                    Text(displayText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxHeight: 300)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.ultraThinMaterial)
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.gray.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            )
    }
    
    @ViewBuilder
    private func ChildFriendlySection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pentru copii și părinți:")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(privacyManager.getPrivacyPolicyContent().childFriendlyExplanation)
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    @ViewBuilder
    private func ActionButtonsSection() -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                // Decline button
                Button(action: {
                    privacyManager.declinePrivacyPolicy()
                    dismiss()
                }) {
                    Text("Nu accept")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.red, lineWidth: 2)
                        )
                }
                
                // Accept button
                Button(action: {
                    privacyManager.acceptPrivacyPolicy()
                    dismiss()
                }) {
                    Text("Accept - Să jucăm!")
                        .font(.body)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.green)
                        )
                }
            }
            
            Text("Părinți: Acceptând, confirmați că ați citit politica de confidențialitate")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(.ultraThickMaterial)
    }
}

// MARK: - Supporting Components

struct ComplianceBadge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(color)
            )
    }
}

// MARK: - Preview

struct PrivacyPolicyView_Previews: PreviewProvider {
    static var previews: some View {
        PrivacyPolicyView(privacyManager: PrivacyPolicyManager())
    }
}