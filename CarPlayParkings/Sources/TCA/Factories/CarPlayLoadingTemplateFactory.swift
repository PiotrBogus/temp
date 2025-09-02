import CarPlay

struct CarPlayLoadingTemplateFactory {
    static func make(message: String) -> CPAlertTemplate {
        return CPAlertTemplate(titleVariants: [message], actions: [])
    }
}
