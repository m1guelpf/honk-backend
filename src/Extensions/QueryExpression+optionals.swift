import SQLiteData

extension QueryExpression where QueryValue: _OptionalPromotable {
	var asOptional: SQLQueryExpression<QueryValue._Optionalized> {
		SQLQueryExpression("\(self)", as: QueryValue._Optionalized.self)
	}
}
