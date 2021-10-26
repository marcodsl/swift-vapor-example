import Fluent
import FluentSQLiteDriver
import Vapor

public func configure(_ app: Application) throws {
    app.databases.use(.sqlite(.memory), as: .sqlite)

    app.migrations.add(CreateUsersTable(), to: .sqlite)
    try app.autoMigrate().wait()

    try routes(app)
}
