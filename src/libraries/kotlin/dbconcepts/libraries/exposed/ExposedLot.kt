package dbconcepts.libraries.exposed

import dbconcepts.connecting.BookDatabase
import org.jetbrains.exposed.v1.core.JoinType
import org.jetbrains.exposed.v1.core.Table
import org.jetbrains.exposed.v1.core.eq
import org.jetbrains.exposed.v1.jdbc.Database
import org.jetbrains.exposed.v1.jdbc.insert
import org.jetbrains.exposed.v1.jdbc.select
import org.jetbrains.exposed.v1.jdbc.selectAll
import org.jetbrains.exposed.v1.jdbc.transactions.transaction

/**
 * A lot's measurements, and a new defect type, with Exposed's SQL DSL. The
 * tables are described once, as Kotlin objects. See @sec-prog-libraries.
 *
 *   ./gradlew runLibrary -PmainClass=dbconcepts.libraries.exposed.ExposedLotKt
 */

// region tables
object Inspection : Table("quality.inspection") {
    val inspectionPk = integer("inspection_pk")
    val lotNumber = varchar("lot_number", 12)
}

object Characteristic : Table("quality.characteristic") {
    val characteristicPk = integer("characteristic_pk")
    val name = varchar("name", 40)
}

object Measurement : Table("quality.measurement") {
    val inspectionFk = integer("inspection_fk")
    val characteristicFk = integer("characteristic_fk")
    val measuredValue = decimal("measured_value", 10, 4)
}

object DefectType : Table("quality.defect_type") {
    val defectTypePk = integer("defect_type_pk").autoIncrement()
    val defectCode = varchar("defect_code", 4)
    val description = varchar("description", 40)
}
// endregion

fun main() {
    BookDatabase.connect().use { db ->
        val database = Database.connect(db.dataSource)
        transaction(database) {
            // region query
            Measurement
                .join(Inspection, JoinType.INNER,
                    Measurement.inspectionFk, Inspection.inspectionPk)
                .join(Characteristic, JoinType.INNER,
                    Measurement.characteristicFk, Characteristic.characteristicPk)
                .select(Characteristic.name, Measurement.measuredValue)
                .where { Inspection.lotNumber eq "L7005-03" }
                .orderBy(Characteristic.name)
                .forEach { row ->
                    println("  ${row[Characteristic.name]}: " +
                        "${row[Measurement.measuredValue]}")
                }
            // endregion
            // region insert
            DefectType.insert {
                it[defectCode] = "WRP"
                it[description] = "Warp"
            }
            println("Defect types: ${DefectType.selectAll().count()}")
            // endregion
        }
    }
}
