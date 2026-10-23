package dbconcepts.simulation

import ksl.utilities.io.dbutil.DbTableData

// A table defined by a Kotlin data class, the KSL's quick way to a database
// for experimental work (@sec-simdb-project). The program prints the
// CREATE TABLE statement the KSL generates from the class.

// region run-data
data class SolverRun(
    var runId: Int = -1,
    var problemName: String = "",
    var solverLabel: String = "",
    var repNum: Int = 0,
    var bestObjective: Double = 0.0,
    var numReplications: Int = 0,
    var gap: Double? = null
) : DbTableData("solver_run", listOf("runId"))
// endregion

fun main() {
    // region print-create
    println(SolverRun().createTableSQLStatement())
    // endregion
}
