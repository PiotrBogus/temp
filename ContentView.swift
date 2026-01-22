                return .merge(
                    .send {
                        .chartContainer(
                            .set(
                                selectors: shouldUpdateSelectors ? aggregate.selectors : nil,
                                dimensions: aggregate.dimensions
                            )
                        )
                    },
                    .send {
                        .delegate(.setTitle(aggregate.title))
                    }
                )
