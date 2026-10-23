package dbconcepts.programming

import dbconcepts.connecting.BookDatabase
import ksl.utilities.io.CSVUtil
import java.io.PrintWriter
import java.math.BigDecimal
import java.nio.file.Files
import java.nio.file.Path

/**
 * Moves the measurements out of the database and back in: exports the table
 * to CSV with the KSL, reads the file back with CSVUtil, and loads it into a
 * staging table with a batch of prepared inserts in one transaction; then
 * writes the whole quality schema to an Excel workbook. See @sec-prog-io.
 *
 *   ./gradlew run -PmainClass=dbconcepts.programming.RoundTripKt
 */
fun main() {
    BookDatabase.connect().use { db ->
        // A method given a table name alone, such as numRows below, looks in
        // the default schema, so set it to the schema this program works in.
        db.defaultSchemaName = "quality"
        // region export
        val file = Path.of("build/measurement.csv")
        PrintWriter(file.toFile()).use { out ->
            db.exportTableAsCSV("measurement", "quality", out, header = true)
        }
        val lines = Files.readAllLines(file)
        println("Exported ${lines.size - 1} rows; the file begins:")
        for (line in lines.take(3)) println("  $line")
        // endregion
        // region staging
        db.executeCommand(
            "CREATE TABLE quality.measurement_staging (" +
                "inspection_fk INTEGER, characteristic_fk INTEGER, " +
                "measured_value NUMERIC(10,4))"
        )
        // endregion
        // region batch
        val rows = CSVUtil.readRows(file, skipLines = 1)
        db.getConnection().use { connection ->
            connection.autoCommit = false
            val sql = "INSERT INTO quality.measurement_staging VALUES (?, ?, ?)"
            connection.prepareStatement(sql).use { statement ->
                for (row in rows) {
                    statement.setInt(1, row[1].toInt())
                    statement.setInt(2, row[2].toInt())
                    statement.setBigDecimal(3, BigDecimal(row[3]))
                    statement.addBatch()
                }
                val counts = statement.executeBatch()
                println("Sent ${counts.size} inserts in one batch")
            }
            connection.commit()
        }
        println("Rows staged: ${db.numRows("measurement_staging")}")
        // endregion
        // region excel
        db.exportToExcel("quality", "quality", Path.of("build"))
        println("Wrote a workbook to build/, a sheet per table")
        // endregion
    }
}
