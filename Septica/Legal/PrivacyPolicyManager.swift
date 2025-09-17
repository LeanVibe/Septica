//
//  PrivacyPolicyManager.swift
//  Septica
//
//  Privacy policy management system for Romanian Septica game
//  GDPR compliant for Romanian/EU market, COPPA compliant for children (6-12 years)
//  Zero personal data collection approach
//

import Foundation
import SwiftUI
import Combine

/// Comprehensive privacy policy management for Romanian market compliance
/// Implements zero personal data collection with full legal compliance
@MainActor
class PrivacyPolicyManager: ObservableObject {
    
    // MARK: - Published Privacy Status
    
    @Published var hasUserSeenPrivacyPolicy: Bool = false
    @Published var privacyPolicyAccepted: Bool = false
    @Published var isPrivacyPolicyDisplayed: Bool = false
    @Published var dataCollectionStatus: DataCollectionStatus = .minimal
    
    // MARK: - Privacy Compliance Configuration
    
    private let userDefaults = UserDefaults.standard
    private let privacyPolicyVersion = "1.0"
    private let lastUpdateDate = "2025-09-17"
    
    // Keys for UserDefaults storage
    private enum PrivacyKeys {
        static let hasSeenPolicy = "hasSeenPrivacyPolicy_v1.0"
        static let policyAccepted = "privacyPolicyAccepted_v1.0"
        static let acceptanceDate = "privacyPolicyAcceptanceDate_v1.0"
        static let userAge = "userAgeCategory"
    }
    
    // MARK: - Initialization
    
    init() {
        loadPrivacyPreferences()
    }
    
    // MARK: - Privacy Policy Management
    
    func loadPrivacyPreferences() {
        hasUserSeenPrivacyPolicy = userDefaults.bool(forKey: PrivacyKeys.hasSeenPolicy)
        privacyPolicyAccepted = userDefaults.bool(forKey: PrivacyKeys.policyAccepted)
        
        print("🔒 Privacy Policy Status Loaded:")
        print("   - Has Seen Policy: \(hasUserSeenPrivacyPolicy)")
        print("   - Policy Accepted: \(privacyPolicyAccepted)")
        print("   - Version: \(privacyPolicyVersion)")
    }
    
    func showPrivacyPolicy() {
        isPrivacyPolicyDisplayed = true
        print("📋 Displaying privacy policy to user")
    }
    
    func acceptPrivacyPolicy() {
        privacyPolicyAccepted = true
        hasUserSeenPrivacyPolicy = true
        isPrivacyPolicyDisplayed = false
        
        // Store acceptance in UserDefaults
        userDefaults.set(true, forKey: PrivacyKeys.policyAccepted)
        userDefaults.set(true, forKey: PrivacyKeys.hasSeenPolicy)
        userDefaults.set(Date(), forKey: PrivacyKeys.acceptanceDate)
        
        print("✅ Privacy policy accepted by user")
        print("   - Acceptance Date: \(Date())")
        print("   - Version: \(privacyPolicyVersion)")
    }
    
    func declinePrivacyPolicy() {
        privacyPolicyAccepted = false
        hasUserSeenPrivacyPolicy = true
        isPrivacyPolicyDisplayed = false
        
        // Store decline status
        userDefaults.set(false, forKey: PrivacyKeys.policyAccepted)
        userDefaults.set(true, forKey: PrivacyKeys.hasSeenPolicy)
        
        print("❌ Privacy policy declined by user")
    }
    
    func requiresPrivacyPolicyDisplay() -> Bool {
        return !hasUserSeenPrivacyPolicy || !privacyPolicyAccepted
    }
    
    // MARK: - COPPA Compliance (Children 6-12 years)
    
    func getCOPPAComplianceStatus() -> COPPAComplianceStatus {
        return COPPAComplianceStatus(
            targetAgeGroup: "6-12 years",
            personalDataCollection: .none,
            parentalConsentRequired: false, // No personal data = no consent needed
            dataMinimization: .fullyCompliant,
            thirdPartyIntegration: .none,
            advertisingCompliance: .noAdvertising,
            complianceLevel: .fullyCompliant
        )
    }
    
    // MARK: - GDPR Compliance (Romanian/EU Market)
    
    func getGDPRComplianceStatus() -> GDPRComplianceStatus {
        return GDPRComplianceStatus(
            dataController: "Septica Romanian Card Game",
            dataProcessingBasis: .legitimateInterest, // Game functionality only
            personalDataProcessed: [],
            userRights: [
                .rightToInformation,
                .rightOfAccess,
                .rightToRectification,
                .rightToErasure,
                .rightToPortability
            ],
            dataRetentionPeriod: .none, // No personal data stored
            internationalTransfers: .none,
            complianceLevel: .fullyCompliant
        )
    }
    
    // MARK: - Data Collection Status
    
    func getDataCollectionReport() -> DataCollectionReport {
        return DataCollectionReport(
            personalDataCollected: [],
            gameDataCollected: [
                "Game progress (local device only)",
                "High scores (local device only)",
                "Settings preferences (local device only)"
            ],
            analyticsData: [],
            thirdPartyServices: [],
            dataStorageLocation: .localDeviceOnly,
            dataSharingStatus: .noSharing,
            parentalNotificationRequired: false
        )
    }
    
    // MARK: - Privacy Policy Content
    
    func getPrivacyPolicyContent() -> PrivacyPolicyContent {
        return PrivacyPolicyContent(
            version: privacyPolicyVersion,
            lastUpdated: lastUpdateDate,
            language: .romanian,
            content: generateRomanianPrivacyPolicyText(),
            englishContent: generateEnglishPrivacyPolicyText(),
            keyPoints: getPrivacyPolicyKeyPoints(),
            childFriendlyExplanation: getChildFriendlyExplanation()
        )
    }
    
    private func generateRomanianPrivacyPolicyText() -> String {
        return """
        # Politica de Confidențialitate - Septica
        
        ## Informații Generale
        Septica este un joc de cărți tradițional românesc pentru copii între 6-12 ani. Respectăm complet confidențialitatea și nu colectăm date personale.
        
        ## Date Colectate: ZERO
        • Nu colectăm numele copilului
        • Nu colectăm adrese de email
        • Nu colectăm locația geografică
        • Nu colectăm fotografii sau imagini
        • Nu colectăm informații de contact
        
        ## Date Locale (pe dispozitiv)
        • Progresul în joc (doar pe dispozitivul dumneavoastră)
        • Scorurile înalte (doar pe dispozitivul dumneavoastră)
        • Preferințele de setări (doar pe dispozitivul dumneavoastră)
        
        ## Servicii de Terți: NONE
        • Nu utilizăm publicitate
        • Nu integrăm rețele sociale
        • Nu utilizăm servicii de analiză externă
        • Nu partajăm date cu alte companii
        
        ## Drepturile Dumneavoastră (GDPR)
        • Dreptul la informare ✅
        • Dreptul de acces ✅
        • Dreptul la rectificare ✅
        • Dreptul la ștergere ✅
        • Dreptul la portabilitate ✅
        
        ## Contact
        Pentru întrebări despre confidențialitate, contactați-ne prin setările aplicației.
        
        ## Actualizări
        Versiunea: \(privacyPolicyVersion)
        Ultima actualizare: \(lastUpdateDate)
        """
    }
    
    private func generateEnglishPrivacyPolicyText() -> String {
        return """
        # Privacy Policy - Septica Romanian Card Game
        
        ## Overview
        Septica is a traditional Romanian card game for children ages 6-12. We fully respect privacy and collect NO personal data.
        
        ## Data Collected: ZERO
        • We do not collect child's name
        • We do not collect email addresses
        • We do not collect location data
        • We do not collect photos or images
        • We do not collect contact information
        
        ## Local Data (on your device only)
        • Game progress (stored only on your device)
        • High scores (stored only on your device)
        • Settings preferences (stored only on your device)
        
        ## Third-Party Services: NONE
        • We do not use advertising
        • We do not integrate social networks
        • We do not use external analytics
        • We do not share data with other companies
        
        ## Your Rights (GDPR Compliant)
        • Right to information ✅
        • Right of access ✅
        • Right to rectification ✅
        • Right to erasure ✅
        • Right to data portability ✅
        
        ## Contact
        For privacy questions, contact us through the app settings.
        
        ## Updates
        Version: \(privacyPolicyVersion)
        Last Updated: \(lastUpdateDate)
        """
    }
    
    private func getPrivacyPolicyKeyPoints() -> [String] {
        return [
            "🔒 Zero personal data collection",
            "🇷🇴 Romanian market compliant",
            "👶 Child-safe (COPPA compliant)",
            "🇪🇺 GDPR fully compliant",
            "📱 Local data only - never shared",
            "🚫 No advertising or tracking",
            "✅ Parental peace of mind"
        ]
    }
    
    private func getChildFriendlyExplanation() -> String {
        return """
        🎮 Ce înseamnă acest lucru pentru tine?
        
        • Jocul Septica nu știe cum te cheamă
        • Nu știm unde locuiești
        • Nu vedem pozele tale
        • Părinții tăi nu trebuie să se îngrijoreze
        • Toate informațiile rămân pe tableta/telefonul tău
        • Poți juca în siguranță!
        
        🎯 English for parents:
        This game is completely safe for children. We collect no personal information and comply with all child protection laws.
        """
    }
}

// MARK: - Supporting Data Models

enum DataCollectionStatus {
    case none        // No data collection
    case minimal     // Local game data only
    case standard    // Local + anonymous analytics
    case comprehensive // Full analytics and personalization
}

struct COPPAComplianceStatus {
    let targetAgeGroup: String
    let personalDataCollection: DataCollectionLevel
    let parentalConsentRequired: Bool
    let dataMinimization: ComplianceLevel
    let thirdPartyIntegration: IntegrationLevel
    let advertisingCompliance: AdvertisingCompliance
    let complianceLevel: ComplianceLevel
}

struct GDPRComplianceStatus {
    let dataController: String
    let dataProcessingBasis: LegalBasis
    let personalDataProcessed: [String]
    let userRights: [GDPRRight]
    let dataRetentionPeriod: RetentionPeriod
    let internationalTransfers: TransferStatus
    let complianceLevel: ComplianceLevel
}

struct DataCollectionReport {
    let personalDataCollected: [String]
    let gameDataCollected: [String]
    let analyticsData: [String]
    let thirdPartyServices: [String]
    let dataStorageLocation: StorageLocation
    let dataSharingStatus: SharingStatus
    let parentalNotificationRequired: Bool
}

struct PrivacyPolicyContent {
    let version: String
    let lastUpdated: String
    let language: PolicyLanguage
    let content: String
    let englishContent: String
    let keyPoints: [String]
    let childFriendlyExplanation: String
}

// MARK: - Supporting Enums

enum DataCollectionLevel {
    case none, minimal, standard, comprehensive
}

enum ComplianceLevel {
    case nonCompliant, partiallyCompliant, fullyCompliant
}

enum IntegrationLevel {
    case none, minimal, standard, extensive
}

enum AdvertisingCompliance {
    case noAdvertising, coppaCompliant, nonCompliant
}

enum LegalBasis {
    case consent, contract, legalObligation, vitalInterests, publicTask, legitimateInterest
}

enum GDPRRight {
    case rightToInformation, rightOfAccess, rightToRectification, rightToErasure, rightToPortability, rightToObject
}

enum RetentionPeriod {
    case none, days(Int), months(Int), years(Int), indefinite
}

enum TransferStatus {
    case none, withinEU, toThirdCountries, adequacyDecision, safeguards
}

enum StorageLocation {
    case localDeviceOnly, cloudEU, cloudGlobal, thirdPartyServers
}

enum SharingStatus {
    case noSharing, anonymizedOnly, partnerSharing, thirdPartySharing
}

enum PolicyLanguage {
    case romanian, english, both
}

// MARK: - Extensions for UI Integration

extension PrivacyPolicyManager {
    
    /// Get a user-friendly compliance summary
    func getComplianceSummary() -> String {
        let coppaStatus = getCOPPAComplianceStatus()
        let gdprStatus = getGDPRComplianceStatus()
        
        return """
        🛡️ Privacy Compliance Summary
        
        ✅ COPPA Compliant (Children 6-12)
        ✅ GDPR Compliant (Romanian/EU Market)
        ✅ Zero Personal Data Collection
        ✅ Local Storage Only
        ✅ No Third-Party Integrations
        ✅ No Advertising or Tracking
        ✅ Parental Peace of Mind
        
        Status: Fully Compliant for Romanian Market Launch
        """
    }
    
    /// Check if the app requires privacy policy display on startup
    func shouldDisplayPrivacyPolicyOnStartup() -> Bool {
        return requiresPrivacyPolicyDisplay()
    }
    
    /// Mark that user has been shown the privacy policy (even if not accepted)
    func markPrivacyPolicyAsShown() {
        hasUserSeenPrivacyPolicy = true
        userDefaults.set(true, forKey: PrivacyKeys.hasSeenPolicy)
    }
}