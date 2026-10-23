package dbconcepts.programming

import dbconcepts.connecting.BookDatabase
import java.sql.Connection
import java.sql.SQLException

/**
 * Counts a lot's measurements two ways: by pasting the lot number into the
 * SQL, which is open to SQL injection, and with a prepared statement, which is
 * not. Each way is run on the same three inputs. See @sec-prog-injection.
 *
 *   ./gradlew run -PmainClass=dbconcepts.programming.LotSearchKt
 */

// region unsafe
/** Wrong: the lot number becomes part of the SQL text. */
fun countMeasurementsUnsafely(
    connection: Connection, lotNumber: String
): Int {
    val sql = "SELECT COUNT(*) FROM quality.measurement AS m " +
        "JOIN quality.inspection AS i " +
        "ON i.inspection_pk = m.inspection_fk " +
        "WHERE i.lot_number = '$lotNumber'"
    connection.createStatement().use { statement ->
        statement.executeQuery(sql).use { rows ->
            rows.next()
            return rows.getInt(1)
        }
    }
}
// endregion

// region safe
/** Right: the lot number is a parameter, sent apart from the SQL. */
fun countMeasurements(
    connection: Connection, lotNumber: String
): Int {
    val sql = "SELECT COUNT(*) FROM quality.measurement AS m " +
        "JOIN quality.inspection AS i " +
        "ON i.inspection_pk = m.inspection_fk " +
        "WHERE i.lot_number = ?"
    connection.prepareStatement(sql).use { statement ->
        statement.setString(1, lotNumber)
        statement.executeQuery().use { rows ->
            rows.next()
            return rows.getInt(1)
        }
    }
}
// endregion

fun main() {
    // region inputs
    val inputs = listOf("L7005-03", "L7005-03' OR '1'='1", "L7005'03")
    // endregion
    BookDatabase.connect().use { db ->
        db.getConnection().use { connection ->
            for ((label, count) in listOf(
                "Pasted into the SQL" to ::countMeasurementsUnsafely,
                "As a parameter" to ::countMeasurements
            )) {
                println(label)
                for (input in inputs) {
                    val result = try {
                        "${count(connection, input)} measurements"
                    } catch (e: SQLException) {
                        e.message?.lineSequence()?.first() ?: "error"
                    }
                    println("  $input -> $result")
                }
            }
        }
    }
}
