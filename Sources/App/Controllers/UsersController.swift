import Fluent
import Vapor

extension EventLoopFuture {
    func mutateThrowing(_ callback: @escaping (Value) throws -> Void) -> EventLoopFuture<Value> {
        return self.flatMapThrowing { value in
            try callback(value)
            return value
        }
    }
}

struct UserResponse: Content {
    var id: UUID?
    var email: String
    var password: String

    static func fromUser(user: User) -> UserResponse {
        return UserResponse(id: user.id, email: user.email, password: user.password)
    }
}

struct CreateUserRequest: Content {
    var email: String
    var password: String

    func toUser() throws -> User {
        let digest = try Bcrypt.hash(password)
        return User(email: email, password: digest)
    }
}

struct UpdateUserRequest: Content {
    var password: String
}

extension CreateUserRequest: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("email", as: String.self, is: .email)
    }
}

final class UsersController {
    
    func createUser(_ req: Request) throws -> EventLoopFuture<UserResponse> {
        try CreateUserRequest.validate(content: req)
        let dto = try req.content.decode(CreateUserRequest.self)

        let user = try dto.toUser()

        return
            user
            .create(on: req.db)
            .map { UserResponse.fromUser(user: user) }
    }

    func getUsers(_ req: Request) -> EventLoopFuture<[UserResponse]> {
        return
            User
            .query(on: req.db)
            .all()
            .mapEach { UserResponse.fromUser(user: $0) }
    }

    func getUserById(_ req: Request) throws -> EventLoopFuture<UserResponse> {
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest)
        }

        return
            User
            .query(on: req.db)
            .filter(\.$id == id)
            .first()
            .unwrap(or: Abort(.notFound))
            .map { UserResponse.fromUser(user: $0) }
    }

    func updateUserById(_ req: Request) throws -> EventLoopFuture<Response> {
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest)
        }

        let dto = try req.content.decode(UpdateUserRequest.self)

        return
            User
            .query(on: req.db)
            .filter(\.$id == id)
            .first()
            .unwrap(or: Abort(.notFound))
            .mutateThrowing { user in user.password = try Bcrypt.hash(dto.password) }
            .flatMap { user in user.update(on: req.db).transform(to: Response(status: .noContent)) }

    }

    func deleteUserById(_ req: Request) throws -> EventLoopFuture<Response> {
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest)
        }

        return
            User
            .query(on: req.db)
            .filter(\.$id == id)
            .first()
            .unwrap(or: Abort(.notFound))
            .flatMap { user in user.delete(on: req.db).transform(to: Response(status: .noContent)) }
    }
}
