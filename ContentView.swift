import Foundation

class FileLogger {
    static let shared = FileLogger()
    
    private var logFileURL: URL

    private init() {
        let fileName = "app_log.txt"
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        logFileURL = documents.appendingPathComponent(fileName)

        // Create the log file if it doesn't exist
        if !FileManager.default.fileExists(atPath: logFileURL.path) {
            FileManager.default.createFile(atPath: logFileURL.path, contents: nil, attributes: nil)
        }
    }

    func log(_ message: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let logMessage = "[\(timestamp)] \(message)\n"
        if let handle = try? FileHandle(forWritingTo: logFileURL) {
            handle.seekToEndOfFile()
            if let data = logMessage.data(using: .utf8) {
                handle.write(data)
            }
            handle.closeFile()
        }
    }

    func getLogFileURL() -> URL {
        return logFileURL
    }
}
