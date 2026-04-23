import SwiftUI

enum WatchScreenState {
    case idle
    case scheduled
    case active
    case error
}

enum WatchCopyKey {
    case appName
    case wakeUpBy
    case noActiveAlarms
    case setOnIPhone
    case today
    case tomorrow
    case monitoring
    case scheduled
    case waiting
    case attention
    case openWatchToArm
    case synced
    case queued
    case watchOnly
    case stop
    case alarm
}

struct WatchCopy {
    let localeIdentifier: String

    private var normalizedIdentifier: String {
        localeIdentifier.replacingOccurrences(of: "_", with: "-").lowercased()
    }

    private var languageCode: String {
        if normalizedIdentifier.hasPrefix("zh-hans") { return "zh-Hans" }
        if normalizedIdentifier.hasPrefix("ar") { return "ar" }
        if normalizedIdentifier.hasPrefix("it") { return "it" }
        if normalizedIdentifier.hasPrefix("es") { return "es" }
        return "en"
    }

    func text(_ key: WatchCopyKey) -> String {
        switch languageCode {
        case "it":
            switch key {
            case .appName: return "Ninety"
            case .wakeUpBy: return "Sveglia entro"
            case .noActiveAlarms: return "Nessuna sveglia attiva"
            case .setOnIPhone: return "Imposta la prossima su iPhone"
            case .today: return "Oggi"
            case .tomorrow: return "Domani"
            case .monitoring: return "Monitoraggio attivo"
            case .scheduled: return "Sveglia programmata"
            case .waiting: return "In attesa della prossima sveglia"
            case .attention: return "Attenzione"
            case .openWatchToArm: return "Apri l'app su Watch per attivarla"
            case .synced: return "Sincronizzato"
            case .queued: return "Connesso"
            case .watchOnly: return "Solo Watch"
            case .stop: return "STOP"
            case .alarm: return "Sveglia"
            }
        case "es":
            switch key {
            case .appName: return "Ninety"
            case .wakeUpBy: return "Despertar antes de"
            case .noActiveAlarms: return "No hay alarmas activas"
            case .setOnIPhone: return "Configura la próxima en iPhone"
            case .today: return "Hoy"
            case .tomorrow: return "Mañana"
            case .monitoring: return "Seguimiento activo"
            case .scheduled: return "Alarma programada"
            case .waiting: return "Esperando la próxima alarma"
            case .attention: return "Atención"
            case .openWatchToArm: return "Abre la app en el Watch para activarla"
            case .synced: return "Sincronizado"
            case .queued: return "Conectado"
            case .watchOnly: return "Solo Watch"
            case .stop: return "DETENER"
            case .alarm: return "Alarma"
            }
        case "zh-Hans":
            switch key {
            case .appName: return "Ninety"
            case .wakeUpBy: return "最晚唤醒时间"
            case .noActiveAlarms: return "没有已激活的闹钟"
            case .setOnIPhone: return "请在 iPhone 上设置下一次闹钟"
            case .today: return "今天"
            case .tomorrow: return "明天"
            case .monitoring: return "监测中"
            case .scheduled: return "闹钟已安排"
            case .waiting: return "等待下一次闹钟"
            case .attention: return "注意"
            case .openWatchToArm: return "打开 Watch App 以激活"
            case .synced: return "已同步"
            case .queued: return "已连接"
            case .watchOnly: return "仅 Watch"
            case .stop: return "停止"
            case .alarm: return "闹钟"
            }
        case "ar":
            switch key {
            case .appName: return "Ninety"
            case .wakeUpBy: return "الاستيقاظ قبل"
            case .noActiveAlarms: return "لا توجد منبهات نشطة"
            case .setOnIPhone: return "اضبط المنبه التالي على iPhone"
            case .today: return "اليوم"
            case .tomorrow: return "غدًا"
            case .monitoring: return "المراقبة نشطة"
            case .scheduled: return "المنبه مجدول"
            case .waiting: return "بانتظار المنبه التالي"
            case .attention: return "تنبيه"
            case .openWatchToArm: return "افتح التطبيق على الساعة لتفعيله"
            case .synced: return "تمت المزامنة"
            case .queued: return "متصل"
            case .watchOnly: return "الساعة فقط"
            case .stop: return "إيقاف"
            case .alarm: return "منبه"
            }
        default:
            switch key {
            case .appName: return "Ninety"
            case .wakeUpBy: return "Wake up by"
            case .noActiveAlarms: return "No active alarms"
            case .setOnIPhone: return "Set your next alarm on iPhone"
            case .today: return "Today"
            case .tomorrow: return "Tomorrow"
            case .monitoring: return "Monitoring active"
            case .scheduled: return "Alarm scheduled"
            case .waiting: return "Waiting for the next alarm"
            case .attention: return "Attention"
            case .openWatchToArm: return "Open the Watch app to arm it"
            case .synced: return "Synced"
            case .queued: return "Connected"
            case .watchOnly: return "Watch only"
            case .stop: return "STOP"
            case .alarm: return "Alarm"
            }
        }
    }
}
