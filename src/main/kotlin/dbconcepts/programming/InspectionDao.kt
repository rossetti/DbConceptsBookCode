package dbconcepts.programming

import java.math.BigDecimal
import java.sql.Connection
import java.sql.SQLException
import java.time.LocalDateTime

// region classes
/** One inspection of a lot, as the quality lab knows it. */
data class Inspection(
    val lotNumber: String,
    val partNumber: String,
    val employeeNumber: String,
    val inspectedAt: LocalDateTime
)

/** One measurement taken in an inspection. */
data class Measurement(
    val characteristic: String,
    val value: BigDecimal
)
// endregion

/**
 * A data access object for inspections: the one place that holds the SQL for
 * creating, reading, updating, and deleting them. Callers work with
 * [Inspection] and [Measurement] objects and business keys (lot, part, and
 * employee numbers); the surrogate keys never leave this class. See
 * @sec-prog-crud.
 *
 * A lot is assumed to be inspected once (@sec-nf-decomposition), so a lot
 * number finds one inspection.
 */
class InspectionDao(private val connection: Connection) {

    // region create
    /** Records an inspection and its measurements, all or none. */
    fun create(
        inspection: Inspection, measurements: List<Measurement>
    ): Int {
        connection.autoCommit = false
        try {
            val key = insertInspection(inspection)
            for (m in measurements) {
                insertMeasurement(key, inspection.partNumber, m)
            }
            connection.commit()
            return key
        } catch (e: SQLException) {
            connection.rollback()
            throw e
        } finally {
            connection.autoCommit = true
        }
    }
    // endregion

    // region insert-inspection
    private fun insertInspection(inspection: Inspection): Int {
        val sql = """
            INSERT INTO quality.inspection
                (part_fk, operator_fk, inspected_at, lot_number)
            VALUES ((SELECT part_pk FROM production.part
                     WHERE part_number = ?),
                    (SELECT operator_pk FROM production.operator
                     WHERE employee_number = ?),
                    ?, ?)
        """.trimIndent()
        val key = arrayOf("inspection_pk")
        connection.prepareStatement(sql, key).use { statement ->
            statement.setString(1, inspection.partNumber)
            statement.setString(2, inspection.employeeNumber)
            statement.setObject(3, inspection.inspectedAt)
            statement.setString(4, inspection.lotNumber)
            statement.executeUpdate()
            statement.generatedKeys.use { keys ->
                keys.next()
                return keys.getInt(1)
            }
        }
    }
    // endregion

    // region insert-measurement
    private fun insertMeasurement(
        inspectionKey: Int, partNumber: String, m: Measurement
    ) {
        val sql = """
            INSERT INTO quality.measurement
                (inspection_fk, characteristic_fk, measured_value)
            VALUES (?,
                    (SELECT c.characteristic_pk
                     FROM quality.characteristic AS c
                     JOIN production.part AS p ON p.part_pk = c.part_fk
                     WHERE p.part_number = ? AND c.name = ?),
                    ?)
        """.trimIndent()
        connection.prepareStatement(sql).use { statement ->
            statement.setInt(1, inspectionKey)
            statement.setString(2, partNumber)
            statement.setString(3, m.characteristic)
            statement.setBigDecimal(4, m.value)
            statement.executeUpdate()
        }
    }
    // endregion

    // region read
    /** The inspection of a lot, or null if the lot has none. */
    fun findByLot(lotNumber: String): Inspection? {
        val sql = """
            SELECT i.lot_number, p.part_number, o.employee_number,
                   i.inspected_at
            FROM quality.inspection AS i
            JOIN production.part AS p ON p.part_pk = i.part_fk
            JOIN production.operator AS o ON o.operator_pk = i.operator_fk
            WHERE i.lot_number = ?
        """.trimIndent()
        connection.prepareStatement(sql).use { statement ->
            statement.setString(1, lotNumber)
            statement.executeQuery().use { rows ->
                if (!rows.next()) return null
                return Inspection(
                    lotNumber = rows.getString("lot_number"),
                    partNumber = rows.getString("part_number"),
                    employeeNumber = rows.getString("employee_number"),
                    inspectedAt = rows.getObject(
                        "inspected_at", LocalDateTime::class.java)
                )
            }
        }
    }
    // endregion

    /** The measurements of a lot's inspection, by characteristic. */
    fun measurementsOf(lotNumber: String): List<Measurement> {
        val sql = """
            SELECT c.name, m.measured_value
            FROM quality.measurement AS m
            JOIN quality.inspection AS i ON i.inspection_pk = m.inspection_fk
            JOIN quality.characteristic AS c
              ON c.characteristic_pk = m.characteristic_fk
            WHERE i.lot_number = ?
            ORDER BY c.name
        """.trimIndent()
        val result = mutableListOf<Measurement>()
        connection.prepareStatement(sql).use { statement ->
            statement.setString(1, lotNumber)
            statement.executeQuery().use { rows ->
                while (rows.next()) {
                    result.add(Measurement(rows.getString("name"), rows.getBigDecimal("measured_value")))
                }
            }
        }
        return result
    }

    // region update
    /** Corrects one measured value; returns the number of rows changed. */
    fun correctMeasurement(lotNumber: String, characteristic: String, value: BigDecimal): Int {
        val sql = """
            UPDATE quality.measurement
            SET measured_value = ?
            WHERE inspection_fk IN (SELECT inspection_pk
                                    FROM quality.inspection
                                    WHERE lot_number = ?)
              AND characteristic_fk IN (SELECT characteristic_pk
                                        FROM quality.characteristic
                                        WHERE name = ?)
        """.trimIndent()
        connection.prepareStatement(sql).use { statement ->
            statement.setBigDecimal(1, value)
            statement.setString(2, lotNumber)
            statement.setString(3, characteristic)
            return statement.executeUpdate()
        }
    }
    // endregion

    // region delete
    /** Deletes a lot's inspection with its measurements and defect counts. */
    fun delete(lotNumber: String): Int {
        val children = listOf("quality.measurement", "quality.defect_count")
        connection.autoCommit = false
        try {
            for (table in children) {
                connection.prepareStatement(
                    "DELETE FROM $table WHERE inspection_fk IN " +
                        "(SELECT inspection_pk FROM quality.inspection WHERE lot_number = ?)"
                ).use { statement ->
                    statement.setString(1, lotNumber)
                    statement.executeUpdate()
                }
            }
            val deleted = connection.prepareStatement(
                "DELETE FROM quality.inspection WHERE lot_number = ?"
            ).use { statement ->
                statement.setString(1, lotNumber)
                statement.executeUpdate()
            }
            connection.commit()
            return deleted
        } catch (e: SQLException) {
            connection.rollback()
            throw e
        } finally {
            connection.autoCommit = true
        }
    }
    // endregion
}
