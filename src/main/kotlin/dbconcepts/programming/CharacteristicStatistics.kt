package dbconcepts.programming

import dbconcepts.connecting.BookDatabase
import ksl.utilities.io.dbutil.DatabaseIfc
import ksl.utilities.statistic.Statistic
import org.jetbrains.kotlinx.dataframe.api.convert
import org.jetbrains.kotlinx.dataframe.api.with

/**
 * Reads every measurement of one characteristic into a data frame with the
 * KSL, and summarizes it with a KSL Statistic and a process capability index,
 * as a quality engineer would before judging the process. See @sec-prog-ksl.
 *
 *   ./gradlew run -PmainClass=dbconcepts.programming.CharacteristicStatisticsKt
 */
fun main() {
    // region sql
    val sql = """
        SELECT i.lot_number, m.measured_value,
               c.lower_spec_limit, c.upper_spec_limit
        FROM quality.measurement AS m
        JOIN quality.inspection AS i
          ON i.inspection_pk = m.inspection_fk
        JOIN quality.characteristic AS c
          ON c.characteristic_pk = m.characteristic_fk
        JOIN production.part AS p ON p.part_pk = c.part_fk
        WHERE p.part_number = 'AX-10' AND c.name = 'Diameter'
        ORDER BY i.lot_number
    """.trimIndent()
    // endregion
    BookDatabase.connect().use { db ->
        // A NUMERIC column's values arrive as BigDecimal objects, so the
        // conversions below read each as a Number and take its Double.
        // region frame
        val frame = db.fetchOpenResultSet(sql)?.use { DatabaseIfc.toDataFrame(it) }
            ?: error("the query failed")
        val diameters = frame["measured_value"].values()
            .map { (it as Number).toDouble() }.toDoubleArray()
        // endregion
        // region show
        println(frame)
        // endregion
        // region statistic
        val stat = Statistic("AX-10 diameter", diameters)
        val lsl = (frame["lower_spec_limit"][0] as Number).toDouble()
        val usl = (frame["upper_spec_limit"][0] as Number).toDouble()
        val outside = diameters.count { it < lsl || it > usl }
        val cpk = minOf(usl - stat.average, stat.average - lsl) /
            (3.0 * stat.standardDeviation)
        println("n = %.0f, mean = %.5f, standard deviation = %.5f"
            .format(stat.count, stat.average, stat.standardDeviation))
        println("outside [%.4f, %.4f]: %d of %d; Cpk = %.2f"
            .format(lsl, usl, outside, diameters.size, cpk))
        // endregion
    }
}
