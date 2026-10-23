package dbconcepts.programming

import dbconcepts.connecting.BookDatabase
import ksl.utilities.io.CSVUtil
import java.math.BigDecimal
import java.nio.file.Path
import java.sql.SQLException
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter

/**
 * Records a lot's inspection from a gauge's CSV file with an [InspectionDao],
 * then reads, corrects, and deletes it, so that each of the four CRUD
 * operations runs once and the database ends as it began. A second file, with
 * a misspelled characteristic, shows a transaction that records nothing. See
 * @sec-prog-crud.
 *
 *   ./gradlew run -PmainClass=dbconcepts.programming.RecordInspectionKt
 */

// region read-gauge
/** Reads a gauge's file: one inspection, and a measurement per line. */
fun readGaugeFile(path: Path): Pair<Inspection, List<Measurement>> {
    val stamp = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm")
    val rows = CSVUtil.readRows(path, skipLines = 1)
    val first = rows.first()
    val inspection = Inspection(
        lotNumber = first[0],
        partNumber = first[1],
        employeeNumber = first[2],
        inspectedAt = LocalDateTime.parse(first[3], stamp)
    )
    val measurements = rows.map { Measurement(it[4], BigDecimal(it[5])) }
    return inspection to measurements
}
// endregion

fun main() {
    BookDatabase.connect().use { db ->
        db.getConnection().use { connection ->
            // region create
            val dao = InspectionDao(connection)
            val (inspection, measurements) =
                readGaugeFile(Path.of("data/gauge-L7005-09.csv"))
            val key = dao.create(inspection, measurements)
            println("Created inspection $key for lot ${inspection.lotNumber}")
            // endregion
            // region read
            println(dao.findByLot("L7005-09"))
            for (m in dao.measurementsOf("L7005-09")) println("  $m")
            // endregion
            // region update
            val changed = dao.correctMeasurement(
                "L7005-09", "Length", BigDecimal("12.0003"))
            val length = dao.measurementsOf("L7005-09")[1]
            println("Updated $changed measurement: $length")
            // endregion
            // region failure
            val (next, nextMeasurements) =
                readGaugeFile(Path.of("data/gauge-L7005-10.csv"))
            try {
                dao.create(next, nextMeasurements)
            } catch (e: SQLException) {
                println("Refused: ${e.message?.lineSequence()?.first()}")
            }
            val recorded = dao.findByLot("L7005-10") != null
            println("Lot L7005-10 recorded: $recorded")
            // endregion
            // region delete
            val deleted = dao.delete("L7005-09")
            println("Deleted $deleted inspection; " +
                "lot L7005-09 recorded: ${dao.findByLot("L7005-09") != null}")
            // endregion
        }
    }
}
