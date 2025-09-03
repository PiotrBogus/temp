    static let mock = CarPlayParkingsErrorParser(
        getMessage: { error in
            if let err = error as? CarPlayParkingsError {
                switch err {
                case .requestError(let message):
                    return message ?? "Mocked request error"
                }
            }
            return "Mocked unknown error"
        }
    )
