import Vapor

func routes(_ app: Application) throws {
    let usersController = UsersController()

    app.post("users", use: usersController.createUser)
    app.get("users", use: usersController.getUsers)
    app.get("users", ":id", use: usersController.getUserById)
    app.put("users", ":id", use: usersController.updateUserById)
    app.delete("users", ":id", use: usersController.deleteUserById)
}
