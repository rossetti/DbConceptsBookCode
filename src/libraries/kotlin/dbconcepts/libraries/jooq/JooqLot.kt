package dbconcepts.libraries.jooq

import dbconcepts.connecting.BookDatabase
import org.jooq.SQLDialect
import org.jooq.impl.DSL
import org.jooq.impl.DSL.field
import org.jooq.impl.DSL.name
import org.jooq.impl.DSL.table
import java.math.BigDecimal

/**
 * A lot's measurements, and a new defect type, with jOOQ's SQL builder,
 * without generated classes. See @sec-prog-libraries.
 *
 *   ./gradlew runLibrary -PmainClass=dbconcepts.libraries.jooq.JooqLotKt
 */
fun main() {
    BookDatabase.connect().use { db ->
        db.getConnection().use { connection ->
            // region query
            val sql = DSL.using(connection, SQLDialect.POSTGRES)
            val m = table(name("quality", "measurement")).`as`("m")
            val i = table(name("quality", "inspection")).`as`("i")
            val c = table(name("quality", "characteristic")).`as`("c")
            val characteristic = field(name("c", "name"), String::class.java)
            val value = field(name("m", "measured_value"), BigDecimal::class.java)
            val query = sql.select(characteristic, value)
                .from(m)
                .join(i).on(field(name("i", "inspection_pk"))
                    .eq(field(name("m", "inspection_fk"))))
                .join(c).on(field(name("c", "characteristic_pk"))
                    .eq(field(name("m", "characteristic_fk"))))
                .where(field(name("i", "lot_number"), String::class.java)
                    .eq("L7005-03"))
                .orderBy(characteristic)
            println(query.sql)
            for (row in query.fetch()) println("  ${row.value1()}: ${row.value2()}")
            // endregion
            // region insert
            val defectType = table(name("quality", "defect_type"))
            sql.insertInto(defectType,
                field(name("defect_code")), field(name("description")))
                .values("WRP", "Warp")
                .execute()
            println("Defect types: ${sql.fetchCount(defectType)}")
            // endregion
        }
    }
}
