import Foundation

/// Centralized EN/AR string map — matches Android Strings.kt exactly.
public enum RayaStrings {
    public static func get(_ key: String, locale: String) -> String {
        let map = locale.hasPrefix("ar") ? ar : en
        return map[key] ?? en[key] ?? key
    }

    private static let en: [String: String] = [
        "online_now": "Online now",
        "start_chat": "Start a chat",
        "start_conversation": "Start a new conversation and ask me anything",
        "privacy_note": "We respect your privacy. Your conversations are encrypted and never shared.",
        "powered_by": "Powered by ",
        "teammates": "Teammates.ai",
        "welcome_form": "Welcome to our live chat! Please fill in the form below before starting the chat.",
        "full_name": "Full Name",
        "email": "Email",
        "phone_number": "Phone Number",
        "start_the_chat": "Start the chat",
        "starting_chat": "Starting the chat",
        "error_name": "Please enter your name!",
        "error_email": "Please enter a valid email address!",
        "error_phone": "Please enter a valid phone number!",
        "type_message": "Type your message...",
        "select_option": "Please select an option above",
        "connect_human": "Connect with human representative",
        "end_chat_title": "End Chat Session",
        "end_chat_subtitle": "Do you want to end this chat session?",
        "cancel": "Cancel",
        "end_session": "End Session",
        "skip": "Skip",
        "submit": "Submit",
        "characters": "characters",
        "ending_session": "Ending session...",
        "voice_message": "Voice message",
        "session_closed": "Session closed",
    ]

    private static let ar: [String: String] = [
        "online_now": "متصل الآن",
        "start_chat": "ابدأ محادثة",
        "start_conversation": "ابدأ محادثة جديدة واسأل أي شيء",
        "privacy_note": "نحن نحترم خصوصيتك. محادثاتك مشفرة ولم تتم مشاركتها أبدًا.",
        "powered_by": "مدعوم من ",
        "teammates": "Teammates.ai",
        "welcome_form": "مرحبًا بك في الدردشة المباشرة! يرجى تعبئة النموذج أدناه قبل بدء الدردشة.",
        "full_name": "الاسم الكامل",
        "email": "البريد الإلكتروني",
        "phone_number": "رقم الهاتف",
        "start_the_chat": "ابدأ الدردشة",
        "starting_chat": "جاري بدء الدردشة",
        "error_name": "الرجاء إدخال اسمك!",
        "error_email": "الرجاء إدخال بريد إلكتروني صحيح!",
        "error_phone": "الرجاء إدخال رقم هاتف صحيح!",
        "type_message": "اكتب رسالتك...",
        "select_option": "يرجى اختيار خيار أعلاه",
        "connect_human": "تواصل مع ممثل بشري",
        "end_chat_title": "إنهاء جلسة الدردشة",
        "end_chat_subtitle": "هل تريد إنهاء جلسة الدردشة هذه؟",
        "cancel": "إلغاء",
        "end_session": "إنهاء الجلسة",
        "skip": "تخطي",
        "submit": "إرسال",
        "characters": "حرف",
        "ending_session": "جاري إنهاء الجلسة...",
        "voice_message": "رسالة صوتية",
        "session_closed": "تم إغلاق الجلسة",
    ]
}
