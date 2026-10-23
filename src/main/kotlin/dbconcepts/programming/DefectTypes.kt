package dbconcepts.programming

import dbconcepts.connecting.BookDatabase
import ksl.utilities.io.dbutil.DbTableData

/**
 * Works with the quality schema through the KSL's Database: lists its tables,
 * prints one, and reads, inserts, and updates rows through a data class that
 * extends DbTableData, with no SQL written in the program. See @sec-prog-ksl.
 *
 *   ./gradlew run -PmainClass=dbconcepts.programming.DefectTypesKt
 */

// region data-class
/** A row of quality.defect_type; the properties are named for its columns. */
data class DefectType(
    var defect_type_pk: Int = 0,
    var defect_code: String = "",
    var description: String = ""
) : DbTableData("defect_type", listOf("defect_type_pk"), autoIncField = true)
// endregion

fun main() {
    BookDatabase.connect().use { db ->
        // region browse
        db.defaultSchemaName = "quality"
        println("Tables: ${db.tableNames("quality").sorted()}")
        println("Rows of measurement: ${db.numRows("measurement")}")
        db.printTableAsText("defect_type")
        // endregion
        // region select
        val types = db.selectTableDataIntoDbData(::DefectType)
        println("Read ${types.size} defect types; the first is ${types.first()}")
        // endregion
        // region insert
        val warp = DefectType(defect_code = "WRP", description = "Warp")
        db.insertDbDataIntoTable(warp)
        println("Inserted $warp")
        // endregion
        // region update
        warp.description = "Warped frame"
        db.updateDbDataInTable(warp)
        println("Updated ${db.selectTableDataIntoDbData(::DefectType).last()}")
        // endregion
    }
}
