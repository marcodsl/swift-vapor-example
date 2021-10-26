import Fluent

final class User: Model {
    static let schema = "users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "email")
    var email: String

    @Field(key: "password")
    var password: String

    init() {  }

    init(email: String, password: String) {
        self.email = email
        self.password = password
    }
}