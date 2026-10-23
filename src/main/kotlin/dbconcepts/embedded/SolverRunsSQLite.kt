package dbconcepts.embedded

import dbconcepts.simulation.SolverRun
import ksl.utilities.io.dbutil.Database
import java.nio.file.Files
import java.nio.file.Path

// Quick tables in an embedded database (@sec-appembedded-ksl): the solver runs
// of @sec-simdb-project written by the KSL to a SQLite file, then summarized
// with SQL. The file is build/embedded/solver-runs.db, recreated on each run.

fun main() {
    // region create
    val dir = Files.createDirectories(Path.of("build", "embedded"))
    val db = Database.createSimpleDb(
        tableDefinitions = setOf(SolverRun()),
        dbName = "solver-runs.db",
        dbDirectory = dir
    )
    // endregion
    // region insert
    val runs = listOf(
        SolverRun(1, "Rosenbrock", "SA-slow", 1, 10.05, 900, 0.005),
        SolverRun(2, "Rosenbrock", "SA-slow", 2, 10.30, 1000, 0.030),
        SolverRun(3, "Rosenbrock", "RS", 1, 10.20, 1000, 0.020),
        SolverRun(4, "Rosenbrock", "RS", 2, 10.90, 1000, 0.090)
    )
    val inserted = db.insertAllDbDataIntoTable(runs, "solver_run")
    println("Inserted $inserted rows into solver_run")
    // endregion
    // region query
    val sql = """
        SELECT solverLabel, COUNT(*) AS runs,
               ROUND(AVG(gap), 3) AS average_gap
        FROM solver_run
        GROUP BY solverLabel
        ORDER BY solverLabel
        """.trimIndent()
    db.fetchCachedRowSet(sql)?.let { rs ->
        while (rs.next()) {
            println("%-8s %d  %.3f".format(rs.getString(1), rs.getInt(2), rs.getDouble(3)))
        }
    }
    // endregion
}
