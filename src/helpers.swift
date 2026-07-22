import MetaCodable

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

func tap<T, E>(_ value: T, _ body: (inout T) throws(E) -> Void) throws(E) -> T {
	var value = value
	try body(&value)
	return value
}

public struct ExplicitNullCoder<T: Codable>: HelperCoder {
	public func decode(from decoder: Decoder) throws -> T {
		try T(from: decoder)
	}

	public func decodeIfPresent(from decoder: any Decoder) throws -> T? {
		try T?(from: decoder)
	}

	public func encode(_ value: T, to encoder: Encoder) throws {
		try value.encode(to: encoder)
	}

	public func encodeIfPresent(_ value: T?, to encoder: any Encoder) throws {
		try value.encode(to: encoder)
	}

	public func encodeIfPresent<EncodingContainer: KeyedEncodingContainerProtocol>(_ value: T?, to container: inout EncodingContainer, atKey key: EncodingContainer.Key) throws {
		try value.encode(to: container.superEncoder(forKey: key))
	}
}
