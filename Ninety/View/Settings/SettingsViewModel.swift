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
        case "Wake up by": return "Sveglia entro"
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
        case "Diagnostics": return "Diagnostica"
        case "Set Wake Time": return "Imposta orario"
        case "Haptic Feedback": return "Feedback aptico"
        case "Light": return "Chiaro"
        case "Night": return "Notte"
        case "System": return "Sistema"
        case "Next": return "Avanti"
        case "Welcome to Ninety": return "Benvenuto in Ninety"
        case "Ninety uses on-device machine learning to find the ideal moment to wake you — within the time you set.": return "Ninety utilizza il Machine Learning direttamente sul tuo dispositivo per trovare il momento perfetto per svegliarti — entro l'orario che imposti tu."
        case "Set Your Wake Time": return "Imposta il tuo orario"
        case "Tap the clock to choose when you need to be up. Ninety wakes you at the best point in your sleep cycle.": return "Tocca l'orologio per scegliere entro quando vuoi essere svegliato. Ninety ti sveglierà nel momento ideale del tuo ciclo di sonno."
        case "Customize Every Day": return "Personalizza ogni giorno"
        case "Each day can have its own wake-up time. Tap a day to select it and adjust the schedule.": return "Ogni giorno della settimana può avere un orario diverso. Tocca un giorno per selezionarlo e impostare la sua sveglia."
        case "On or Off. Your Call.": return "Attiva o disattiva"
        case "Toggle the alarm for each day independently — keep your weekdays and weekends perfectly balanced.": return "Accendi o spegni la sveglia per ogni singolo giorno in modo indipendente."
        case "Private by Design": return "100% sul dispositivo"
        case "Your sleep data never leaves your device. No servers, no cloud — everything runs locally on your iPhone.": return "I tuoi dati sul sonno non lasciano mai il tuo telefono. Nessun server, nessun cloud — solo tu e il tuo dispositivo."
        case "You're All Set": return "Sei pronto!"
        case "Everything is set up. Sweet dreams.": return "Tutto è configurato. Sogni d'oro!"
        case "Replay Tour": return "Ripeti il tutorial"
        default: return nil
        }
    }

    private var chineseTranslation: String? {
        switch self {
        case "SMART ALARM": return "智能闹钟"
        case "Wake Window": return "唤醒窗口"
        case "Wake up by": return "最晚唤醒时间"
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
        case "Diagnostics": return "诊断"
        case "Set Wake Time": return "设置起床时间"
        case "Haptic Feedback": return "触觉反馈"
        case "Light": return "浅色"
        case "Night": return "夜间"
        case "System": return "系统"
        case "Next": return "下一步"
        case "Welcome to Ninety": return "欢迎使用 Ninety"
        case "Ninety uses on-device machine learning to find the ideal moment to wake you — within the time you set.": return "Ninety 使用设备端机器学习，在您设定的时间内找到最佳唤醒时刻。"
        case "Set Your Wake Time": return "设置您的时间"
        case "Tap the clock to choose when you need to be up. Ninety wakes you at the best point in your sleep cycle.": return "点击时钟选择最晚唤醒时间。Ninety 会在您睡眠周期的理想时刻唤醒您。"
        case "Customize Every Day": return "自定义每一天"
        case "Each day can have its own wake-up time. Tap a day to select it and adjust the schedule.": return "每天可以设置不同的唤醒时间。点击某天来选择并设置闹钟。"
        case "On or Off. Your Call.": return "开启或关闭"
        case "Toggle the alarm for each day independently — keep your weekdays and weekends perfectly balanced.": return "独立开关每一天的闹钟。"
        case "Private by Design": return "100% 本地运行"
        case "Your sleep data never leaves your device. No servers, no cloud — everything runs locally on your iPhone.": return "您的睡眠数据永远不会离开手机。没有服务器、没有云端——只有您和您的设备。"
        case "You're All Set": return "准备就绪！"
        case "Everything is set up. Sweet dreams.": return "一切已配置完成。祝您好梦！"
        case "Replay Tour": return "重播教程"
        default: return nil
        }
    }

    private var spanishTranslation: String? {
        switch self {
        case "SMART ALARM": return "ALARMA INTELIGENTE"
        case "Wake Window": return "Ventana de despertar"
        case "Wake up by": return "Despertar antes de"
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
        case "Diagnostics": return "Diagnóstico"
        case "Set Wake Time": return "Configurar hora"
        case "Haptic Feedback": return "Retroalimentación háptica"
        case "Light": return "Claro"
        case "Night": return "Noche"
        case "System": return "Sistema"
        case "Next": return "Siguiente"
        case "Welcome to Ninety": return "Bienvenido a Ninety"
        case "Ninety uses on-device machine learning to find the ideal moment to wake you — within the time you set.": return "Ninety usa Machine Learning directamente en tu dispositivo para encontrar el momento perfecto para despertarte — dentro del horario que elijas."
        case "Set Your Wake Time": return "Configura tu hora"
        case "Tap the clock to choose when you need to be up. Ninety wakes you at the best point in your sleep cycle.": return "Toca el reloj para elegir la hora límite para despertar. Ninety te despertará en el momento ideal de tu ciclo de sueño."
        case "Customize Every Day": return "Personaliza cada día"
        case "Each day can have its own wake-up time. Tap a day to select it and adjust the schedule.": return "Cada día de la semana puede tener un horario diferente. Toca un día para seleccionarlo y configurar su alarma."
        case "On or Off. Your Call.": return "Activa o desactiva"
        case "Toggle the alarm for each day independently — keep your weekdays and weekends perfectly balanced.": return "Enciende o apaga la alarma para cada día de forma independiente."
        case "Private by Design": return "100% en el dispositivo"
        case "Your sleep data never leaves your device. No servers, no cloud — everything runs locally on your iPhone.": return "Tus datos de sueño nunca salen de tu teléfono. Sin servidores, sin nube — solo tú y tu dispositivo."
        case "You're All Set": return "¡Listo!"
        case "Everything is set up. Sweet dreams.": return "Todo está configurado. ¡Dulces sueños!"
        case "Replay Tour": return "Repetir tutorial"
        default: return nil
        }
    }

    private var arabicTranslation: String? {
        switch self {
        case "SMART ALARM": return "المنبه الذكي"
        case "Wake Window": return "نافذة الاستيقاظ"
        case "Wake up by": return "الاستيقاظ قبل"
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
        case "Diagnostics": return "التشخيص"
        case "Set Wake Time": return "ضبط وقت الاستيقاظ"
        case "Haptic Feedback": return "ردود فعل لمسية"
        case "Light": return "فاتح"
        case "Night": return "ليلي"
        case "System": return "النظام"
        case "Next": return "التالي"
        case "Welcome to Ninety": return "مرحباً بك في Ninety"
        case "Ninety uses on-device machine learning to find the ideal moment to wake you — within the time you set.": return "يستخدم Ninety تعلم الآلة مباشرة على جهازك للعثور على اللحظة المثالية لإيقاظك — ضمن الوقت الذي تحدده."
        case "Set Your Wake Time": return "اضبط وقتك"
        case "Tap the clock to choose when you need to be up. Ninety wakes you at the best point in your sleep cycle.": return "اضغط على الساعة لاختيار الوقت الأقصى للاستيقاظ. سيوقظك Ninety في اللحظة المثالية من دورة نومك."
        case "Customize Every Day": return "خصّص كل يوم"
        case "Each day can have its own wake-up time. Tap a day to select it and adjust the schedule.": return "يمكن لكل يوم من أيام الأسبوع أن يكون له وقت مختلف. اضغط على يوم لتحديده وضبط منبهه."
        case "On or Off. Your Call.": return "تفعيل أو تعطيل"
        case "Toggle the alarm for each day independently — keep your weekdays and weekends perfectly balanced.": return "قم بتشغيل أو إيقاف المنبه لكل يوم بشكل مستقل."
        case "Private by Design": return "100% على الجهاز"
        case "Your sleep data never leaves your device. No servers, no cloud — everything runs locally on your iPhone.": return "بيانات نومك لا تغادر هاتفك أبداً. لا خوادم، لا سحابة — أنت وجهازك فقط."
        case "You're All Set": return "أنت جاهز!"
        case "Everything is set up. Sweet dreams.": return "كل شيء مُعدّ. أحلام سعيدة!"
        case "Replay Tour": return "إعادة الجولة"
        default: return nil
        }
    }
}

class SettingsViewModel: ObservableObject {
    @AppStorage("appTheme") var selectedTheme: AppTheme = .system
    
    // Smart Alarm configuration
    @AppStorage("smartWakeWindow") var smartWakeWindow: Int = 30 // minutes before alarm to start sensing
    @AppStorage("hapticAlarm") var hapticAlarm: Bool = true // vibrate gently before ringing
    @AppStorage("hapticFeedbackEnabled") var hapticFeedbackEnabled: Bool = true // UI haptic feedback
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
