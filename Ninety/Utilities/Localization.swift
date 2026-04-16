import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case italian = "it"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english:
            return "English"
        case .italian:
            return "Italiano"
        }
    }
}

extension String {
    func localized(for languageCode: String) -> String {
        guard let language = AppLanguage(rawValue: languageCode) else {
            return self
        }

        switch language {
        case .english:
            return self
        case .italian:
            return italianTranslation ?? self
        }
    }

    private var italianTranslation: String? {
        switch self {
        case "SMART ALARM": return "SVEGLIA INTELLIGENTE"
        case "Wake Window": return "Finestra di sveglia"
        case "Haptic Pre-Alarm": return "Pre-sveglia aptica"
        case "APPEARANCE": return "ASPETTO"
        case "Automatic": return "Automatico"
        case "PERMISSIONS": return "PERMESSI"
        case "Notifications": return "Notifiche"
        case "Apple Health": return "Apple Health"
        case "GENERAL": return "GENERALE"
        case "Language": return "Lingua"
        case "About Ninety": return "Informazioni su Ninety"
        case "Settings": return "Impostazioni"
        case "Ninety": return "Ninety"
        case "Version": return "Versione"
        case "Smart sleep tracking powered by on-device ML. Your data stays on your devices.":
            return "Monitoraggio del sonno intelligente con ML on-device. I tuoi dati restano sui tuoi dispositivi."
        case "Done": return "Chiudi"
        case "Next Up": return "Prossima"
        case "Select": return "Seleziona"
        case "Alarm On": return "Sveglia attiva"
        case "Alarm Off": return "Sveglia disattivata"
        case "Sleep History": return "Cronologia sonno"
        case "Diagnostics": return "Diagnostica"
        case "Set Wake Time": return "Imposta orario"
        case "Light": return "Chiaro"
        case "Night": return "Notte"
        case "System": return "Sistema"
        default: return nil
        }
    }
}
