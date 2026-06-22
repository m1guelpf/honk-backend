func rescue<T, E>(_ body: () throws(E) -> T, catch: (E) -> Void) -> T? {
	do {
		return try body()
	} catch {
		`catch`(error)
	}

	return nil
}

func rescue<T, E>(_ body: () async throws(E) -> T, catch: (E) -> Void) async -> T? {
	do {
		return try await body()
	} catch {
		`catch`(error)
	}

	return nil
}
