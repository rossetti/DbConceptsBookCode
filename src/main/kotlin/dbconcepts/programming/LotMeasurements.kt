package dbconcepts.programming

import dbconcepts.connecting.BookDatabase

/**
 * Lists the measurements of one inspected lot, with plain JDBC: a connection,
 * a prepared statement with the lot number as its parameter, and a result set
 * read row by row. Each is closed by `use`. See @sec-prog-jdbc.
 *
 *   ./gradlew run -PmainClass=dbconcepts.programming.LotMeasurementsKt
 */
fun main() {
    val lotNumber = "L7005-03"
    // region sql
    val sql = """
        SELECT c.name, c.unit, m.measured_value
        FROM quality.measurement AS m
        JOIN quality.inspection AS i
          ON i.inspection_pk = m.inspection_fk
        JOIN quality.characteristic AS c
          ON c.characteristic_pk = m.characteristic_fk
        WHERE i.lot_number = ?
        ORDER BY c.name
    """.trimIndent()
    // endregion
    // region run
    BookDatabase.connect().use { db ->
        db.getConnection().use { connection ->
            connection.prepareStatement(sql).use { statement ->
                statement.setString(1, lotNumber)
                statement.executeQuery().use { rows ->
                    println("Measurements of lot $lotNumber")
                    while (rows.next()) {
                        val name = rows.getString("name")
                        val unit = rows.getString("unit")
                        val value = rows.getBigDecimal("measured_value")
                        println("  $name: $value $unit")
                    }
                }
            }
        }
    }
    // endregion
}
