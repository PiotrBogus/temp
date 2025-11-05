private func setupConstraints() {
    scrollView.snp.makeConstraints {
        $0.top.leading.trailing.equalToSuperview()
        $0.bottom.equalTo(primaryButtonContainer.snp.top)
    }

    mainContainer.snp.makeConstraints {
        $0.edges.equalToSuperview()
        $0.width.equalToSuperview()
        $0.bottom.equalTo(contentMessageView.snp.bottom).offset(32)
    }

    headerStackView.snp.makeConstraints {
        $0.top.equalToSuperview().offset(Constants.headerTopPadding)
        $0.leading.equalToSuperview().offset(Constants.defaultPadding)
        $0.trailing.equalToSuperview().inset(Constants.defaultPadding)
    }

    multiCheckbox.snp.makeConstraints {
        $0.top.equalTo(headerStackView.snp.bottom).offset(Constants.headerBottomPadding)
        $0.leading.trailing.equalToSuperview().inset(Constants.defaultPadding)
    }

    contentMessageView.snp.makeConstraints {
        $0.top.equalTo(multiCheckbox.snp.bottom).offset(Constants.defaultPadding)
        $0.leading.equalToSuperview().offset(Constants.defaultPadding)
        $0.trailing.equalToSuperview().inset(Constants.defaultPadding)
    }

    primaryButtonContainer.snp.makeConstraints {
        $0.leading.trailing.bottom.equalToSuperview()
    }

    primaryButton.snp.makeConstraints {
        $0.edges.equalToSuperview().inset(Constants.defaultPadding)
    }
}
