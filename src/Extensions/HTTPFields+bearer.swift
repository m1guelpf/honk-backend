import HTTPTypes

public struct BearerAuthentication: Sendable {
	public let token: String
}

public extension HTTPFields {
	/// Return Bearer authorization information from request
	var bearer: BearerAuthentication? {
		guard let authorization = self[.authorization], authorization.hasPrefix("Bearer ") else { return nil }

		return BearerAuthentication(token: String(authorization.dropFirst("Bearer ".count)))
	}
}
