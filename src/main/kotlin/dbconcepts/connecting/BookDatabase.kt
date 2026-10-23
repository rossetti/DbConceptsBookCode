package dbconcepts.connecting

import ksl.utilities.io.dbutil.Database
import ksl.utilities.io.dbutil.PostgresDb
import java.nio.file.Files
import java.nio.file.Path
import java.util.Properties

/**
 * Opens the PostgreSQL database that the examples use, with the connection
 * settings read from a properties file (by default `db.properties` in the
 * working directory). See `db.properties.example` for the keys.
 *
 * Keeping the settings in a file rather than in the source means a password is
 * never committed, and every example connects the same way.
 */
object BookDatabase {

    /** The default location of the connection settings. */
    val defaultPropertiesPath: Path = Path.of("db.properties")

    /** Reads the connection settings, failing with a clear message if the file is missing. */
    fun readProperties(path: Path = defaultPropertiesPath): Properties {
        require(Files.exists(path)) {
            "No connection settings at ${path.toAbsolutePath()}. " +
                "Copy db.properties.example to db.properties and fill it in."
        }
        return Properties().apply { Files.newBufferedReader(path).use { load(it) } }
    }

    /**
     * Connects to the database named in the settings file, or to [database]
     * on the same server if it is given. The environment variable
     * DBCONCEPTS_DATABASE, if set, also names another database: the book's
     * generators use it to run a program against a copy of a stage.
     */
    fun connect(path: Path = defaultPropertiesPath, database: String? = null): Database {
        val p = readProperties(path)
        val dbName = database ?: System.getenv("DBCONCEPTS_DATABASE")
            ?: p.getProperty("database", "dbconcepts")
        val dataSource = PostgresDb.createDataSource(
            dbServerName = p.getProperty("host", "localhost"),
            dbName = dbName,
            user = p.getProperty("user", "postgres"),
            pWord = p.getProperty("password", ""),
            portNumber = p.getProperty("port", "5432").toInt()
        )
        return Database(dataSource, dbName)
    }
}
