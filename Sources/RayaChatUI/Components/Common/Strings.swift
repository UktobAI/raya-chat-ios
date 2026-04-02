import Foundation

/// Centralized EN/AR string map. No iOS resources — keeps the SDK lightweight.
public enum RayaStrings {
    public static func get(_ key: String, locale: String) -> String {
        let map = locale.hasPrefix("ar") ? ar : en
        return map[key] ?? en[key] ?? key
    }

    private static let en: [String: String] = [
        "start_chat": "Start a chat",
        "start_the_chat": "Start the chat",
        "starting_chat": "Starting chat...",
        "type_message": "Type your message...",
        "full_name": "Full name",
        "email": "Email",
        "phone_number": "Phone number",
        "welcome_form": "Please share your details to start a chat",
        "powered_by": "Powered by",
        "teammates": "Teammates.ai",
        "privacy_note": "By chatting, you agree to our privacy policy.",
        "online_now": "Online now",
        "error_name": "Please enter your name",
        "error_email": "Please enter a valid email",
        "error_phone": "Please enter a valid phone number",
        "cancel": "Cancel",
        "end_session": "End Session",
        "end_chat_title": "End Chat",
        "end_chat_message": "Are you sure you want to end this chat session?",
        "select_option": "Select an option above",
        "skip": "Skip",
        "submit": "Submit",
        "connect_human": "Connect with a person",
        "feedback_placeholder": "Share your thoughts...",
        "session_closed": "Session closed",
    ]

    private static let ar: [String: String] = [
        "start_chat": "ابدأ محادثة",
        "start_the_chat": "ابدأ المحادثة",
        "starting_chat": "جاري بدء المحادثة...",
        "type_message": "اكتب رسالتك...",
        "full_name": "الاسم الكامل",
        "email": "البريد الإلكتروني",
        "phone_number": "رقم الهاتف",
        "welcome_form": "يرجى مشاركة بياناتك لبدء المحادثة",
        "powered_by": "مدعوم من",
        "teammates": "Teammates.ai",
        "privacy_note": "بالدردشة، فإنك توافق على سياسة الخصوصية الخاصة بنا.",
        "online_now": "متصل الآن",
        "error_name": "يرجى إدخال اسمك",
        "error_email": "يرجى إدخال بريد إلكتروني صالح",
        "error_phone": "يرجى إدخال رقم هاتف صالح",
        "cancel": "إلغاء",
        "end_session": "إنهاء الجلسة",
        "end_chat_title": "إنهاء المحادثة",
        "end_chat_message": "هل أنت متأكد أنك تريد إنهاء جلسة المحادثة هذه؟",
        "select_option": "اختر خيارًا أعلاه",
        "skip": "تخطي",
        "submit": "إرسال",
        "connect_human": "التواصل مع شخص",
        "feedback_placeholder": "شاركنا أفكارك...",
        "session_closed": "تم إغلاق الجلسة",
    ]
}
