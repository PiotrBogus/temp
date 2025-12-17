    func isSystemESimConfiguratorAvailable(configuratorLink: String) -> Bool {
        // Below iOS 17.4 configurator doesn't work
        guard #available(iOS 17.4, *),
              let url = URL(string: configuratorLink) else { return false }
        return UIApplication.shared.canOpenURL(url)
    }
