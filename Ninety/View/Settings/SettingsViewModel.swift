//
//  SettingsViewModel.swift
//  Ninety
//
//  Created by Deimante Valunaite on 11/07/2024.
//

import SwiftUI
import UserNotifications

// MARK: - App Theme

enum AppTheme: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case night = "Night"
    
    var id: String { rawValue }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .night: return .dark
        }
    }
    
    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .night: return "moon.stars.fill"
        }
    }
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case italian = "it"
    case chinese = "zh-Hans"
    case spanish = "es"
    case arabic = "ar"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english:
            return "English"
        case .italian:
            return "Italiano"
        case .chinese:
            return "中文"
        case .spanish:
            return "Español"
        case .arabic:
            return "العربية"
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
        case .chinese:
            return chineseTranslation ?? self
        case .spanish:
            return spanishTranslation ?? self
        case .arabic:
            return arabicTranslation ?? self
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
        case "Next Up": return "Prossima sveglia"
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

    private var chineseTranslation: String? {
        switch self {
        case "SMART ALARM": return "智能闹钟"
        case "Wake Window": return "唤醒窗口"
        case "Haptic Pre-Alarm": return "触觉预闹钟"
        case "APPEARANCE": return "外观"
        case "Automatic": return "自动"
        case "PERMISSIONS": return "权限"
        case "Notifications": return "通知"
        case "Apple Health": return "Apple 健康"
        case "GENERAL": return "通用"
        case "Language": return "语言"
        case "About Ninety": return "关于 Ninety"
        case "Settings": return "设置"
        case "Version": return "版本"
        case "Smart sleep tracking powered by on-device ML. Your data stays on your devices.":
            return "由端侧机器学习驱动的智能睡眠追踪。你的数据始终保留在你的设备上。"
        case "Done": return "完成"
        case "Next Up": return "下一次"
        case "Select": return "选择"
        case "Alarm On": return "闹钟已开启"
        case "Alarm Off": return "闹钟已关闭"
        case "Sleep History": return "睡眠记录"
        case "Diagnostics": return "诊断"
        case "Set Wake Time": return "设置起床时间"
        case "Light": return "浅色"
        case "Night": return "夜间"
        case "System": return "系统"
        default: return nil
        }
    }

    private var spanishTranslation: String? {
        switch self {
        case "SMART ALARM": return "ALARMA INTELIGENTE"
        case "Wake Window": return "Ventana de despertar"
        case "Haptic Pre-Alarm": return "Prealarma háptica"
        case "APPEARANCE": return "APARIENCIA"
        case "Automatic": return "Automático"
        case "PERMISSIONS": return "PERMISOS"
        case "Notifications": return "Notificaciones"
        case "Apple Health": return "Apple Health"
        case "GENERAL": return "GENERAL"
        case "Language": return "Idioma"
        case "About Ninety": return "Acerca de Ninety"
        case "Settings": return "Ajustes"
        case "Version": return "Versión"
        case "Smart sleep tracking powered by on-device ML. Your data stays on your devices.":
            return "Seguimiento inteligente del sueño impulsado por ML en el dispositivo. Tus datos permanecen en tus dispositivos."
        case "Done": return "Listo"
        case "Next Up": return "Siguiente"
        case "Select": return "Seleccionar"
        case "Alarm On": return "Alarma activada"
        case "Alarm Off": return "Alarma desactivada"
        case "Sleep History": return "Historial de sueño"
        case "Diagnostics": return "Diagnóstico"
        case "Set Wake Time": return "Configurar hora"
        case "Light": return "Claro"
        case "Night": return "Noche"
        case "System": return "Sistema"
        default: return nil
        }
    }

    private var arabicTranslation: String? {
        switch self {
        case "SMART ALARM": return "المنبه الذكي"
        case "Wake Window": return "نافذة الاستيقاظ"
        case "Haptic Pre-Alarm": return "منبه لمسي مسبق"
        case "APPEARANCE": return "المظهر"
        case "Automatic": return "تلقائي"
        case "PERMISSIONS": return "الأذونات"
        case "Notifications": return "الإشعارات"
        case "Apple Health": return "صحّة Apple"
        case "GENERAL": return "عام"
        case "Language": return "اللغة"
        case "About Ninety": return "حول Ninety"
        case "Settings": return "الإعدادات"
        case "Version": return "الإصدار"
        case "Smart sleep tracking powered by on-device ML. Your data stays on your devices.":
            return "تتبع ذكي للنوم مدعوم بالتعلم الآلي على الجهاز. تبقى بياناتك على أجهزتك."
        case "Done": return "تم"
        case "Next Up": return "التالي"
        case "Select": return "اختيار"
        case "Alarm On": return "المنبه مفعّل"
        case "Alarm Off": return "المنبه متوقف"
        case "Sleep History": return "سجل النوم"
        case "Diagnostics": return "التشخيص"
        case "Set Wake Time": return "ضبط وقت الاستيقاظ"
        case "Light": return "فاتح"
        case "Night": return "ليلي"
        case "System": return "النظام"
        default: return nil
        }
    }
}

class SettingsViewModel: ObservableObject {
    @AppStorage("appTheme") var selectedTheme: AppTheme = .system
    
    // Smart Alarm configuration
    @AppStorage("smartWakeWindow") var smartWakeWindow: Int = 30 // minutes before alarm to start sensing
    @AppStorage("hapticAlarm") var hapticAlarm: Bool = true // vibrate gently before ringing
    @AppStorage("saveToHealthKit") var saveToHealthKit: Bool = true // save sleep data
    
    @AppStorage("isNotificationsEnabled") var isNotificationsEnabled: Bool = false {
        didSet {
            if isNotificationsEnabled {
                enableNotifications()
            }
        }
    }
    
    func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isNotificationsEnabled = (settings.authorizationStatus == .authorized)
            }
        }
    }
    
    private func enableNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            DispatchQueue.main.async {
                if success {
                    self.isNotificationsEnabled = true
                } else {
                    self.isNotificationsEnabled = false
                }
            }
        }
    }
}
