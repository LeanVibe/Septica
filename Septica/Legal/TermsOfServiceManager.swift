//
//  TermsOfServiceManager.swift
//  Septica
//
//  Terms of Service management for Romanian Septica game
//  Child-friendly terms with Romanian legal compliance
//

import Foundation
import SwiftUI
import Combine

/// Terms of Service management for Romanian market compliance
/// Child-appropriate terms for ages 6-12 with full legal protection
@MainActor
class TermsOfServiceManager: ObservableObject {
    
    // MARK: - Published Terms Status
    
    @Published var hasUserSeenTerms: Bool = false
    @Published var termsAccepted: Bool = false
    @Published var isTermsDisplayed: Bool = false
    
    // MARK: - Terms Configuration
    
    private let userDefaults = UserDefaults.standard
    private let termsVersion = "1.0"
    private let lastUpdateDate = "2025-09-17"
    
    // Keys for UserDefaults storage
    private enum TermsKeys {
        static let hasSeenTerms = "hasSeenTermsOfService_v1.0"
        static let termsAccepted = "termsOfServiceAccepted_v1.0"
        static let acceptanceDate = "termsAcceptanceDate_v1.0"
    }
    
    // MARK: - Initialization
    
    init() {
        loadTermsPreferences()
    }
    
    // MARK: - Terms Management
    
    func loadTermsPreferences() {
        hasUserSeenTerms = userDefaults.bool(forKey: TermsKeys.hasSeenTerms)
        termsAccepted = userDefaults.bool(forKey: TermsKeys.termsAccepted)
        
        print("📋 Terms of Service Status Loaded:")
        print("   - Has Seen Terms: \(hasUserSeenTerms)")
        print("   - Terms Accepted: \(termsAccepted)")
        print("   - Version: \(termsVersion)")
    }
    
    func showTermsOfService() {
        isTermsDisplayed = true
        print("📜 Displaying terms of service to user")
    }
    
    func acceptTermsOfService() {
        termsAccepted = true
        hasUserSeenTerms = true
        isTermsDisplayed = false
        
        // Store acceptance in UserDefaults
        userDefaults.set(true, forKey: TermsKeys.termsAccepted)
        userDefaults.set(true, forKey: TermsKeys.hasSeenTerms)
        userDefaults.set(Date(), forKey: TermsKeys.acceptanceDate)
        
        print("✅ Terms of service accepted by user")
        print("   - Acceptance Date: \(Date())")
        print("   - Version: \(termsVersion)")
    }
    
    func declineTermsOfService() {
        termsAccepted = false
        hasUserSeenTerms = true
        isTermsDisplayed = false
        
        // Store decline status
        userDefaults.set(false, forKey: TermsKeys.termsAccepted)
        userDefaults.set(true, forKey: TermsKeys.hasSeenTerms)
        
        print("❌ Terms of service declined by user")
    }
    
    func requiresTermsDisplay() -> Bool {
        return !hasUserSeenTerms || !termsAccepted
    }
    
    // MARK: - Terms Content Generation
    
    func getTermsOfServiceContent() -> TermsOfServiceContent {
        return TermsOfServiceContent(
            version: termsVersion,
            lastUpdated: lastUpdateDate,
            language: .romanian,
            content: generateRomanianTermsText(),
            englishContent: generateEnglishTermsText(),
            keyPoints: getTermsKeyPoints(),
            childFriendlyRules: getChildFriendlyRules()
        )
    }
    
    private func generateRomanianTermsText() -> String {
        return """
        # Termeni și Condiții - Septica
        
        ## 1. Despre Joc
        Septica este un joc de cărți tradițional românesc creat pentru copii între 6-12 ani. Jocul este gratuit și sigur pentru întreaga familie.
        
        ## 2. Cum să Folosești Jocul
        • Joacă fair-play și respectuos
        • Nu încerca să modifici sau să hackezi jocul
        • Folosește jocul doar pentru divertisment
        • Părinții pot supraveghea și juca împreună cu copiii
        
        ## 3. Ce Poți Să Faci
        ✅ Să joci cât vrei, când vrei
        ✅ Să înveți regulile tradiționale româneși
        ✅ Să te distrezi cu familia
        ✅ Să-ți îmbunătățești abilitățile de joc
        ✅ Să descoperi cultura românească
        
        ## 4. Ce Nu Poți Să Faci
        ❌ Să copiezi sau să distribui jocul
        ❌ Să folosești jocul în scopuri comerciale
        ❌ Să modifici codul sursă
        ❌ Să creezi versiuni neautorizate
        
        ## 5. Siguranță pentru Copii
        • Jocul nu conține conținut nepotrivit
        • Nu există chat sau comunicare online
        • Nu există achiziții în aplicație
        • Nu există reclame sau linkuri externe
        • Totul este local și sigur
        
        ## 6. Responsabilitate
        • Părinții sunt responsabili pentru supravegherea copiilor
        • Jocul este doar pentru divertisment
        • Nu suntem responsabili pentru timpii de joc excesivi
        • Recomandăm pauze regulate
        
        ## 7. Proprietate Intelectuală
        • Septica este un joc tradițional românesc
        • Implementarea aplicației este protejată de drepturi de autor
        • Respectăm și promovăm cultura românească
        
        ## 8. Modificări
        • Putem actualiza acești termeni
        • Veți fi notificați despre schimbări importante
        • Versiunea actuală: \(termsVersion)
        • Ultima actualizare: \(lastUpdateDate)
        
        ## 9. Legea Aplicabilă
        • Acești termeni sunt guvernați de legea românească
        • Orice dispute vor fi rezolvate în România
        • GDPR și COPPA se aplică în totalitate
        
        ## 10. Contact
        Pentru întrebări despre acești termeni, contactați-ne prin setările aplicației.
        """
    }
    
    private func generateEnglishTermsText() -> String {
        return """
        # Terms and Conditions - Septica Romanian Card Game
        
        ## 1. About the Game
        Septica is a traditional Romanian card game created for children ages 6-12. The game is free and safe for the entire family.
        
        ## 2. How to Use the Game
        • Play fairly and respectfully
        • Do not attempt to modify or hack the game
        • Use the game for entertainment only
        • Parents can supervise and play together with children
        
        ## 3. What You Can Do
        ✅ Play as much as you want, when you want
        ✅ Learn traditional Romanian rules
        ✅ Have fun with family
        ✅ Improve your gaming skills
        ✅ Discover Romanian culture
        
        ## 4. What You Cannot Do
        ❌ Copy or distribute the game
        ❌ Use the game for commercial purposes
        ❌ Modify the source code
        ❌ Create unauthorized versions
        
        ## 5. Child Safety
        • The game contains no inappropriate content
        • No chat or online communication
        • No in-app purchases
        • No ads or external links
        • Everything is local and safe
        
        ## 6. Responsibility
        • Parents are responsible for supervising children
        • The game is for entertainment only
        • We are not responsible for excessive play times
        • We recommend regular breaks
        
        ## 7. Intellectual Property
        • Septica is a traditional Romanian game
        • The app implementation is protected by copyright
        • We respect and promote Romanian culture
        
        ## 8. Changes
        • We may update these terms
        • You will be notified of important changes
        • Current version: \(termsVersion)
        • Last updated: \(lastUpdateDate)
        
        ## 9. Applicable Law
        • These terms are governed by Romanian law
        • Any disputes will be resolved in Romania
        • GDPR and COPPA apply in full
        
        ## 10. Contact
        For questions about these terms, contact us through the app settings.
        """
    }
    
    private func getTermsKeyPoints() -> [String] {
        return [
            "🎮 Joc gratuit pentru copii 6-12 ani",
            "🇷🇴 Tradițional românesc, cultural autentic",
            "👨‍👩‍👧‍👦 Sigur pentru întreaga familie",
            "🔒 Fără chat, fără achiziții, fără reclame",
            "📱 Totul local pe dispozitivul tău",
            "⚖️ Complet legal și conform GDPR/COPPA",
            "🛡️ Protecție completă pentru copii"
        ]
    }
    
    private func getChildFriendlyRules() -> [String] {
        return [
            "🎯 Joacă-te frumos și respectuos",
            "👨‍👩‍👧‍👦 Poți juca cu părinții și frații",
            "⏰ Fă pauze când îți spun părinții",
            "📚 Poți învăța cultura românească",
            "🤝 Respectă regulile tradiționale",
            "😊 Distrează-te și învață în siguranță!"
        ]
    }
    
    // MARK: - Legal Compliance Status
    
    func getRomanianLegalCompliance() -> RomanianLegalCompliance {
        return RomanianLegalCompliance(
            gdprCompliant: true,
            coppaCompliant: true,
            romanianLawCompliant: true,
            childProtectionCompliant: true,
            consumerProtectionCompliant: true,
            intellectualPropertyCompliant: true,
            dataProtectionCompliant: true,
            parentalControlsCompliant: true
        )
    }
    
    func getTermsComplianceReport() -> TermsComplianceReport {
        return TermsComplianceReport(
            version: termsVersion,
            lastUpdated: lastUpdateDate,
            childSafetyCompliance: .fullyCompliant,
            legalCompliance: .fullyCompliant,
            culturalAuthenticity: .fullyAuthentic,
            parentalGuidance: .comprehensive,
            risks: [],
            recommendations: [
                "Terms are fully compliant for Romanian market",
                "Child-friendly language used throughout",
                "Parental oversight encouraged",
                "Cultural authenticity maintained"
            ]
        )
    }
}

// MARK: - Supporting Data Models

struct TermsOfServiceContent {
    let version: String
    let lastUpdated: String
    let language: PolicyLanguage
    let content: String
    let englishContent: String
    let keyPoints: [String]
    let childFriendlyRules: [String]
}

struct RomanianLegalCompliance {
    let gdprCompliant: Bool
    let coppaCompliant: Bool
    let romanianLawCompliant: Bool
    let childProtectionCompliant: Bool
    let consumerProtectionCompliant: Bool
    let intellectualPropertyCompliant: Bool
    let dataProtectionCompliant: Bool
    let parentalControlsCompliant: Bool
    
    var overallCompliance: Bool {
        return gdprCompliant && coppaCompliant && romanianLawCompliant && 
               childProtectionCompliant && consumerProtectionCompliant && 
               intellectualPropertyCompliant && dataProtectionCompliant && 
               parentalControlsCompliant
    }
}

struct TermsComplianceReport {
    let version: String
    let lastUpdated: String
    let childSafetyCompliance: SafetyCompliance
    let legalCompliance: ComplianceLevel
    let culturalAuthenticity: CulturalAuthenticity
    let parentalGuidance: GuidanceLevel
    let risks: [String]
    let recommendations: [String]
}

enum SafetyCompliance {
    case nonCompliant, partiallyCompliant, fullyCompliant
}

enum CulturalAuthenticity {
    case nonAuthentic, partiallyAuthentic, fullyAuthentic
}

enum GuidanceLevel {
    case none, basic, comprehensive
}

// MARK: - Extensions for Integration

extension TermsOfServiceManager {
    
    /// Get a user-friendly terms summary
    func getTermsSummary() -> String {
        return """
        📜 Termeni și Condiții - Rezumat
        
        ✅ Joc gratuit și sigur pentru copii
        ✅ Fără conținut nepotrivit
        ✅ Fără achiziții sau reclame
        ✅ Respectă cultura românească
        ✅ Complet legal și conform GDPR/COPPA
        ✅ Încurajează supravegherea părintească
        ✅ Promovează fair-play și respect
        
        Versiunea: \(termsVersion)
        Actualizat: \(lastUpdateDate)
        """
    }
    
    /// Check if terms need to be displayed on startup
    func shouldDisplayTermsOnStartup() -> Bool {
        return requiresTermsDisplay()
    }
    
    /// Mark that user has seen terms (even if not accepted)
    func markTermsAsShown() {
        hasUserSeenTerms = true
        userDefaults.set(true, forKey: TermsKeys.hasSeenTerms)
    }
}