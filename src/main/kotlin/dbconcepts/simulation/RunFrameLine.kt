package dbconcepts.simulation

import dbconcepts.connecting.BookDatabase
import ksl.simulation.Model
import ksl.utilities.io.dbutil.KSLDatabase
import ksl.utilities.io.dbutil.KSLDatabaseObserver

/**
 * Builds stage K of the book's database: reads the hand truck frame's routing
 * from the production schema, simulates the frame line in two scenarios, and
 * lets the KSL record both experiments in its own schema, ksl_db, of the same
 * database. See @sec-simdb-outputs.
 *
 *   DBCONCEPTS_DATABASE=dbconcepts_k ./gradlew run -PmainClass=dbconcepts.simulation.RunFrameLineKt
 *
 * scripts/build-simulation-db.sh runs it against a fresh copy of stage Q.
 */

// region routing-sql
/** The routing of a part, with each work center's machines: all, and staffed. */
const val ROUTING_SQL = """
    SELECT w.work_center_code, o.setup_minutes, o.run_minutes_per_unit,
           COUNT(DISTINCT m.machine_pk) AS machines,
           COUNT(DISTINCT c.machine_fk) AS staffed_machines
    FROM production.operation AS o
    JOIN production.part AS p ON p.part_pk = o.manufactured_part_fk
    JOIN production.work_center AS w ON w.work_center_pk = o.work_center_fk
    LEFT JOIN production.machine AS m ON m.work_center_fk = w.work_center_pk
    LEFT JOIN production.certification AS c ON c.machine_fk = m.machine_pk
    WHERE p.part_number = ?
    GROUP BY o.operation_number, w.work_center_code,
             o.setup_minutes, o.run_minutes_per_unit
    ORDER BY o.operation_number
"""
// endregion

/** The routing of [partNumber], counting only staffed machines unless [allMachines]. */
fun readRouting(partNumber: String, allMachines: Boolean): List<RoutingStep> {
    val steps = mutableListOf<RoutingStep>()
    BookDatabase.connect().use { db ->
        db.getConnection().use { connection ->
            connection.prepareStatement(ROUTING_SQL.trimIndent()).use { statement ->
                statement.setString(1, partNumber)
                statement.executeQuery().use { rows ->
                    while (rows.next()) {
                        steps.add(RoutingStep(
                            workCenterCode = rows.getString("work_center_code"),
                            setupMinutes = rows.getBigDecimal("setup_minutes").toDouble(),
                            runMinutesPerUnit = rows.getBigDecimal("run_minutes_per_unit").toDouble(),
                            machines = rows.getInt(if (allMachines) "machines" else "staffed_machines")
                        ))
                    }
                }
            }
        }
    }
    return steps
}

fun main() {
    // region ksl-database
    val db = BookDatabase.connect()
    db.executeCommand("DROP SCHEMA IF EXISTS ksl_db CASCADE")
    KSLDatabase.executeKSLDbCreationScriptOnDatabase(db)
    db.defaultSchemaName = "ksl_db"
    val kslDb = KSLDatabase(db)
    // endregion
    // region scenarios
    val scenarios = listOf(
        "TwoWelders" to readRouting("FR-110", allMachines = false),
        "ThreeWelders" to readRouting("FR-110", allMachines = true)
    )
    for ((experiment, routing) in scenarios) {
        val model = Model("FrameLine", autoCSVReports = false)
        model.experimentName = experiment
        model.numberOfReplications = 30
        model.lengthOfReplication = 30.0 * 24.0 * 60.0
        model.lengthOfReplicationWarmUp = 5.0 * 24.0 * 60.0
        model.resetStartStreamOption = true
        FrameLine(model, routing, lotSize = 100,
            meanMinutesBetweenLots = 400.0, name = "Line")
        KSLDatabaseObserver(model, kslDb)
        model.simulate()
        println("$experiment: ${routing.joinToString { "${it.workCenterCode} x${it.machines}" }}")
    }
    // endregion
}
