package dbconcepts.connecting

/**
 * Confirms that the PostgreSQL server is reachable with the settings in
 * db.properties, and reports the server version and the tables of the book's
 * database, schema by schema.
 *
 *   cd code && ./gradlew run
 */
fun main() {
    BookDatabase.connect().use { db ->
        // region check
        val rs = db.fetchCachedRowSet("SELECT current_setting('server_version')")
        if (rs != null && rs.next()) {
            println("Connected to PostgreSQL ${rs.getString(1)}")
        } else {
            println("Could not query the server. Check the settings in db.properties.")
            return
        }
        for (schema in listOf("distribution", "production", "quality")) {
            val tables = db.tableNames(schema).sorted()
            if (tables.isEmpty()) {
                println("$schema: (not loaded)")
            } else {
                println("$schema:")
                tables.chunked(4).forEach { println("    " + it.joinToString(", ")) }
            }
        }
        // endregion
    }
}
