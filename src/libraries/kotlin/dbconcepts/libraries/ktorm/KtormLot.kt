package dbconcepts.libraries.ktorm

import dbconcepts.connecting.BookDatabase
import org.ktorm.database.Database
import org.ktorm.dsl.asc
import org.ktorm.dsl.count
import org.ktorm.dsl.eq
import org.ktorm.dsl.from
import org.ktorm.dsl.innerJoin
import org.ktorm.dsl.insert
import org.ktorm.dsl.map
import org.ktorm.dsl.orderBy
import org.ktorm.dsl.select
import org.ktorm.dsl.where
import org.ktorm.dsl.forEach
import org.ktorm.schema.Table
import org.ktorm.schema.decimal
import org.ktorm.schema.int
import org.ktorm.schema.varchar

/**
 * A lot's measurements, and a new defect type, with Ktorm's SQL DSL. See
 * @sec-prog-libraries.
 *
 *   ./gradlew runLibrary -PmainClass=dbconcepts.libraries.ktorm.KtormLotKt
 */

// region tables
object Inspections : Table<Nothing>("inspection", schema = "quality") {
    val inspectionPk = int("inspection_pk").primaryKey()
    val lotNumber = varchar("lot_number")
}

object Characteristics : Table<Nothing>("characteristic", schema = "quality") {
    val characteristicPk = int("characteristic_pk").primaryKey()
    val name = varchar("name")
}

object Measurements : Table<Nothing>("measurement", schema = "quality") {
    val inspectionFk = int("inspection_fk")
    val characteristicFk = int("characteristic_fk")
    val measuredValue = decimal("measured_value")
}

object DefectTypes : Table<Nothing>("defect_type", schema = "quality") {
    val defectTypePk = int("defect_type_pk").primaryKey()
    val defectCode = varchar("defect_code")
    val description = varchar("description")
}
// endregion

fun main() {
    BookDatabase.connect().use { db ->
        val database = Database.connect(db.dataSource)
        // region query
        database.from(Measurements)
            .innerJoin(Inspections,
                on = Measurements.inspectionFk eq Inspections.inspectionPk)
            .innerJoin(Characteristics,
                on = Measurements.characteristicFk eq Characteristics.characteristicPk)
            .select(Characteristics.name, Measurements.measuredValue)
            .where { Inspections.lotNumber eq "L7005-03" }
            .orderBy(Characteristics.name.asc())
            .forEach { row ->
                println("  ${row[Characteristics.name]}: " +
                    "${row[Measurements.measuredValue]}")
            }
        // endregion
        // region insert
        database.insert(DefectTypes) {
            set(it.defectCode, "WRP")
            set(it.description, "Warp")
        }
        val types = database.from(DefectTypes).select(count())
            .map { it.getInt(1) }.first()
        println("Defect types: $types")
        // endregion
    }
}
