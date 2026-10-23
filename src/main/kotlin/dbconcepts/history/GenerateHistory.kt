package dbconcepts.history

import ksl.utilities.random.rvariable.KSLRandom
import java.math.BigDecimal
import java.math.RoundingMode
import java.nio.file.Files
import java.nio.file.Path
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter

/**
 * Generates stage G of HG Industries' database: a year of order history
 * (April 2026 through March 2027) and six months of inspections (April
 * through September 2026), appended to the base data of stages D1 to Q.
 *
 * The output is an SQL script, written once and committed, so a reader loads
 * the history like any other stage and never needs to run this program. The
 * program is kept beside the data so the data can be regenerated, and so that
 * how it was made is not a mystery.
 *
 *   cd code && ./gradlew run -PmainClass=dbconcepts.history.GenerateHistoryKt
 *
 * Every random choice is drawn from its own KSL random number stream, named in
 * [Streams]. The streams start from the same seeds on every run, so the
 * output is identical every time, and changing how one thing is generated
 * (say, quantities) leaves every other stream's draws unchanged.
 *
 * The script refers to rows by their business identifiers (order numbers, part
 * numbers, lot numbers), never by surrogate key values, so it does not depend
 * on how many rows the base stages inserted.
 */
fun main(args: Array<String>) {
    val output = Path.of(args.firstOrNull() ?: "sql/history/g-history.sql")
    val history = History().apply { generate() }
    Files.createDirectories(output.parent)
    Files.writeString(output, history.toSql())
    println("Wrote $output: ${history.summary()}")
}

/** One KSL random number stream per source of randomness. */
private object Streams {
    const val ORDER_PLACED = 1
    const val ORDER_DAY = 2
    const val LINE_COUNT = 3
    const val PRODUCT = 4
    const val QUANTITY = 5
    const val NO_REQUESTED_DATE = 6
    const val SHIP_DELAY = 7
    const val PARTIAL = 8
    const val PARTIAL_SHARE = 9
    const val REMAINDER_DELAY = 10
    const val CARRIER = 11
    const val AXLE_DIAMETER = 12
    const val AXLE_LENGTH = 13
    const val WELD_FAILURE = 14
    const val WELD_STRENGTH = 15
    const val COATING = 16
    const val DEFECTS = 17
}

// The period of the history.
private val ORDERS_FROM: LocalDate = LocalDate.of(2026, 4, 1)
private val ORDERS_TO: LocalDate = LocalDate.of(2027, 3, 31)
private val INSPECTIONS_FROM: LocalDate = LocalDate.of(2026, 4, 1)
private val INSPECTIONS_TO: LocalDate = LocalDate.of(2026, 9, 30)
private val POLY_CART_LAUNCH: LocalDate = LocalDate.of(2026, 9, 1)

/** How often and how much a customer orders. */
private enum class Size(val weeklyOrderProbability: Double, val meanQuantity: Double) {
    SMALL(0.18, 4.0), MEDIUM(0.45, 9.0), LARGE(0.90, 20.0)
}

private data class Customer(
    val number: String, val name: String, val city: String, val state: String,
    val size: Size?, val isNew: Boolean
) {
    /** Customers in Oklahoma, Kansas, and Texas are served from Tulsa. */
    val warehouse: String get() = if (state in setOf("OK", "KS", "TX")) "W-TUL" else "W-FAY"
}

private data class Product(val number: String, val listPrice: BigDecimal, val isCart: Boolean)

private data class Order(val number: String, val date: LocalDate, val requestedShipDate: LocalDate?, val customer: Customer)
private data class OrderLine(val order: Order, val lineNumber: Int, val product: Product, val quantity: Int, val unitPrice: BigDecimal)
private data class Shipment(var number: String, val date: LocalDate, val carrier: String, val order: Order)
private data class ShipmentLine(val shipment: Shipment, val line: OrderLine, val quantity: Int)
private data class Inspection(val part: String, val operator: String, val at: LocalDateTime, val lot: String)
private data class Measurement(val inspection: Inspection, val characteristic: String, val value: BigDecimal)
private data class DefectCount(val inspection: Inspection, val defectCode: String, val quantity: Int)

private val CUSTOMERS = listOf(
    // The base customers, with how they order from April 2026 on. C-1008 still never orders.
    Customer("C-1001", "Riverside Hardware", "Fayetteville", "AR", Size.LARGE, false),
    Customer("C-1002", "Summit Farm Supply", "Springdale", "AR", Size.MEDIUM, false),
    Customer("C-1003", "Cedar Creek Home Center", "Tulsa", "OK", Size.LARGE, false),
    Customer("C-1004", "Midtown Tool Supply", "Joplin", "MO", Size.SMALL, false),
    Customer("C-1005", "Prairie Garden Center", "Fort Smith", "AR", Size.MEDIUM, false),
    Customer("C-1006", "Lakeside Distributors", "Springfield", "MO", Size.LARGE, false),
    Customer("C-1007", "Tri-County Farm and Home", "Bentonville", "AR", Size.MEDIUM, false),
    Customer("C-1008", "Northgate Hardware", "Little Rock", "AR", null, false),
    // New customers, added by this stage.
    Customer("C-1009", "Rogers Farm Supply", "Rogers", "AR", Size.MEDIUM, true),
    Customer("C-1010", "Boston Mountain Hardware", "Harrison", "AR", Size.SMALL, true),
    Customer("C-1011", "Riverbend Home and Garden", "Conway", "AR", Size.MEDIUM, true),
    Customer("C-1012", "Big Creek Supply", "Russellville", "AR", Size.SMALL, true),
    Customer("C-1013", "Muskogee Tool and Farm", "Muskogee", "OK", Size.MEDIUM, true),
    Customer("C-1014", "Green Country Hardware", "Broken Arrow", "OK", Size.LARGE, true),
    Customer("C-1015", "Red Dirt Supply", "Stillwater", "OK", Size.SMALL, true),
    Customer("C-1016", "Prairie Wind Farm Store", "Enid", "OK", Size.SMALL, true),
    Customer("C-1017", "Canadian River Home Center", "Norman", "OK", Size.MEDIUM, true),
    Customer("C-1018", "Gateway Hardware", "Branson", "MO", Size.SMALL, true),
    Customer("C-1019", "Table Rock Supply", "Kimberling City", "MO", Size.SMALL, true),
    Customer("C-1020", "Queen City Farm and Garden", "Springfield", "MO", Size.MEDIUM, true),
    Customer("C-1021", "Neosho Valley Supply", "Neosho", "MO", Size.SMALL, true),
    Customer("C-1022", "Flint Hills Farm Store", "Emporia", "KS", Size.MEDIUM, true),
    Customer("C-1023", "Sunflower Hardware", "Wichita", "KS", Size.LARGE, true),
    Customer("C-1024", "Cherokee Strip Supply", "Ponca City", "OK", Size.SMALL, true),
    Customer("C-1025", "Piney Woods Hardware", "Texarkana", "TX", Size.MEDIUM, true),
    Customer("C-1026", "East Texas Farm and Ranch", "Tyler", "TX", Size.MEDIUM, true),
    Customer("C-1027", "Red River Supply", "Paris", "TX", Size.SMALL, true),
    Customer("C-1028", "Delta Farm Store", "Pine Bluff", "AR", Size.SMALL, true),
    Customer("C-1029", "Crowley's Ridge Hardware", "Jonesboro", "AR", Size.MEDIUM, true),
    Customer("C-1030", "White River Home Center", "Batesville", "AR", Size.SMALL, true),
)

private val PRODUCTS = listOf(
    Product("HT-100", BigDecimal("89.00"), isCart = false),
    Product("HT-200", BigDecimal("139.00"), isCart = false),
    Product("GC-300", BigDecimal("119.00"), isCart = true),
    Product("GC-400", BigDecimal("149.00"), isCart = true),
)

/** Orders placed in a month, relative to the year's average. */
private val ORDER_SEASON = mapOf(
    1 to 0.7, 2 to 0.8, 3 to 1.2, 4 to 1.3, 5 to 1.3, 6 to 1.1,
    7 to 0.8, 8 to 0.8, 9 to 0.9, 10 to 1.0, 11 to 1.1, 12 to 0.9
)

/** Garden carts sell in the spring, hand trucks toward the end of the year. */
private fun productWeight(product: Product, month: Int): Double =
    if (product.isCart) (if (month in 3..6) 2.0 else 0.7)
    else (if (month in 10..12) 1.3 else 1.0)

private val CARRIERS = listOf("Boston Mountain Freight", "Tri-State Logistics", "Customer pickup")
private val CARRIER_CDF = doubleArrayOf(0.50, 0.85, 1.00)

private class History {
    val newCustomers = CUSTOMERS.filter { it.isNew }
    val orders = mutableListOf<Order>()
    val lines = mutableListOf<OrderLine>()
    val shipments = mutableListOf<Shipment>()
    val shipmentLines = mutableListOf<ShipmentLine>()
    val inspections = mutableListOf<Inspection>()
    val measurements = mutableListOf<Measurement>()
    val defects = mutableListOf<DefectCount>()

    fun generate() {
        generateOrders()
        generateShipments()
        generateInspections()
    }

    // ---------------------------------------------------------------- orders

    private fun generateOrders() {
        val ordering = CUSTOMERS.filter { it.size != null }
        var weekStart = ORDERS_FROM.with(DayOfWeek.MONDAY)
        val placed = mutableListOf<Order>()
        while (!weekStart.isAfter(ORDERS_TO)) {
            for (customer in ordering) {
                val p = minOf(0.95, customer.size!!.weeklyOrderProbability * ORDER_SEASON.getValue(weekStart.monthValue))
                if (KSLRandom.rBernoulli(p, Streams.ORDER_PLACED) == 1.0) {
                    val day = weekStart.plusDays(KSLRandom.rDUniform(0, 4, Streams.ORDER_DAY).toLong())
                    if (day in ORDERS_FROM..ORDERS_TO) placed += Order("", day, null, customer)
                }
            }
            weekStart = weekStart.plusWeeks(1)
        }
        // Number the orders in the order they were placed, continuing the base's SO-5012.
        placed.sortWith(compareBy({ it.date }, { it.customer.number }))
        placed.forEachIndexed { i, o ->
            val requested = if (KSLRandom.rBernoulli(0.05, Streams.NO_REQUESTED_DATE) == 1.0) null else o.date.plusDays(7)
            val order = Order("SO-${5013 + i}", o.date, requested, o.customer)
            orders += order
            generateLines(order)
        }
    }

    private fun generateLines(order: Order) {
        val count = KSLRandom.randomlySelect(intArrayOf(1, 2, 3), doubleArrayOf(0.50, 0.85, 1.00), Streams.LINE_COUNT)
        val available = PRODUCTS.filter { it.number != "GC-400" || !order.date.isBefore(POLY_CART_LAUNCH) }.toMutableList()
        for (lineNumber in 1..minOf(count, available.size)) {
            val product = pickWeighted(available, order.date.monthValue)
            available.remove(product)
            val size = order.customer.size!!
            val quantity = 1 + KSLRandom.rPoisson(size.meanQuantity - 1.0, Streams.QUANTITY)
            lines += OrderLine(order, lineNumber, product, quantity, price(product, quantity, size))
        }
    }

    private fun pickWeighted(products: List<Product>, month: Int): Product {
        val weights = products.map { productWeight(it, month) }
        var u = KSLRandom.rUniform(0.0, weights.sum(), Streams.PRODUCT)
        for ((product, weight) in products.zip(weights)) {
            u -= weight
            if (u <= 0.0) return product
        }
        return products.last()
    }

    /** List price, less 5% on a line of 24 or more and 3% for a large customer. */
    private fun price(product: Product, quantity: Int, size: Size): BigDecimal {
        var discount = BigDecimal.ZERO
        if (quantity >= 24) discount += BigDecimal("0.05")
        if (size == Size.LARGE) discount += BigDecimal("0.03")
        return (product.listPrice * (BigDecimal.ONE - discount)).setScale(2, RoundingMode.HALF_UP)
    }

    // ------------------------------------------------------------- shipments

    private fun generateShipments() {
        val made = mutableListOf<ShipmentLine>()
        for (order in orders) {
            val orderLines = lines.filter { it.order == order }
            val shipDate = businessDay(order.date.plusDays(KSLRandom.rDUniform(1, 5, Streams.SHIP_DELAY).toLong()))
            if (shipDate.isAfter(ORDERS_TO)) continue          // still open at the end of the year
            val first = Shipment("", shipDate, carrier(), order)
            // Now and then one line is short: part ships now, the rest later.
            val shortLine = if (KSLRandom.rBernoulli(0.08, Streams.PARTIAL) == 1.0)
                orderLines.firstOrNull { it.quantity >= 2 } else null
            for (line in orderLines) {
                val shipped = if (line == shortLine)
                    maxOf(1, (line.quantity * KSLRandom.rUniform(0.4, 0.8, Streams.PARTIAL_SHARE)).toInt())
                else line.quantity
                made += ShipmentLine(first, line, shipped)
            }
            shipments += first
            if (shortLine != null) {
                val shippedFirst = made.last { it.line == shortLine }.quantity
                val laterDate = businessDay(shipDate.plusDays(KSLRandom.rDUniform(5, 12, Streams.REMAINDER_DELAY).toLong()))
                if (!laterDate.isAfter(ORDERS_TO)) {            // otherwise it stays backordered
                    val second = Shipment("", laterDate, carrier(), order)
                    shipments += second
                    made += ShipmentLine(second, shortLine, shortLine.quantity - shippedFirst)
                }
            }
        }
        // Number the shipments in the order they left, continuing the base's SH-9011.
        shipments.sortWith(compareBy({ it.date }, { it.order.number }))
        shipments.forEachIndexed { i, s -> s.number = "SH-${9012 + i}" }
        val position = shipments.withIndex().associate { (i, s) -> s to i }
        shipmentLines += made.sortedWith(compareBy({ position.getValue(it.shipment) }, { it.line.lineNumber }))
    }

    private fun carrier(): String =
        CARRIERS[KSLRandom.randomlySelect(intArrayOf(0, 1, 2), CARRIER_CDF, Streams.CARRIER)]

    private fun businessDay(date: LocalDate): LocalDate = when (date.dayOfWeek) {
        DayOfWeek.SATURDAY -> date.plusDays(2)
        DayOfWeek.SUNDAY -> date.plusDays(1)
        else -> date
    }

    // ----------------------------------------------------------- inspections

    private fun generateInspections() {
        var daysSinceToolChange = 0
        var frameInspections = 0
        var cartInspections = 0
        var day = INSPECTIONS_FROM
        while (!day.isAfter(INSPECTIONS_TO)) {
            val dow = day.dayOfWeek
            if (dow != DayOfWeek.SATURDAY && dow != DayOfWeek.SUNDAY) {
                daysSinceToolChange = inspectAxle(day, daysSinceToolChange)
                if (dow == DayOfWeek.TUESDAY || dow == DayOfWeek.THURSDAY) inspectFrame(day, frameInspections++)
                if (dow == DayOfWeek.MONDAY || dow == DayOfWeek.WEDNESDAY) inspectCart(day, cartInspections++)
            }
            day = day.plusDays(1)
        }
    }

    /**
     * The lathe's tool wears, so the axle diameter creeps upward day by day
     * until the tool is changed, when it drops back: a sawtooth. The tool is
     * changed after a diameter above 0.6285 in, or after 25 working days.
     */
    private fun inspectAxle(day: LocalDate, daysSinceToolChange: Int): Int {
        val operator = if (day.dayOfMonth % 2 == 0) "E-202" else "E-205"
        val inspection = inspect("AX-10", operator, day.atTime(8, 0), day, "AX")
        val diameter = KSLRandom.rNormal(0.6240 + 0.00012 * daysSinceToolChange, 0.0004 * 0.0004, Streams.AXLE_DIAMETER)
        val length = KSLRandom.rNormal(12.0, 0.012 * 0.012, Streams.AXLE_LENGTH)
        measure(inspection, "Diameter", diameter, 4)
        measure(inspection, "Length", length, 3)
        if (diameter !in 0.62..0.63 || length !in 11.95..12.05) defects += DefectCount(inspection, "DIM", 1)
        count(inspection, "BUR", 0.12)
        return if (diameter > 0.6285 || daysSinceToolChange >= 25) 0 else daysSinceToolChange + 1
    }

    /** Linda Nguyen (E-203) reads coating thickness about 0.55 mil lower than Robert Hayes (E-204). */
    private fun coating(operator: String): Double =
        KSLRandom.rNormal(if (operator == "E-203") 2.55 else 3.10, 0.30 * 0.30, Streams.COATING)

    private fun inspectFrame(day: LocalDate, n: Int) {
        val operator = if (n % 2 == 0) "E-204" else "E-203"
        val inspection = inspect("FR-110", operator, day.atTime(13, 0), day, "FR")
        val weakWeld = KSLRandom.rBernoulli(0.04, Streams.WELD_FAILURE) == 1.0
        val strength = if (weakWeld) KSLRandom.rNormal(1450.0, 40.0 * 40.0, Streams.WELD_STRENGTH)
                       else KSLRandom.rNormal(1820.0, 55.0 * 55.0, Streams.WELD_STRENGTH)
        val thickness = coating(operator)
        measure(inspection, "Weld strength", strength, 0)
        measure(inspection, "Coating thickness", thickness, 1)
        if (strength < 1500.0) defects += DefectCount(inspection, "POR", 1 + KSLRandom.rPoisson(1.0, Streams.DEFECTS))
        paintDefects(inspection, thickness)
    }

    private fun inspectCart(day: LocalDate, n: Int) {
        val operator = if (n % 2 == 0) "E-204" else "E-203"
        val inspection = inspect("CF-310", operator, day.atTime(14, 0), day, "CF")
        val thickness = coating(operator)
        measure(inspection, "Coating thickness", thickness, 1)
        paintDefects(inspection, thickness)
    }

    /** Paint runs are the most common defect, and more common on a heavy coat. */
    private fun paintDefects(inspection: Inspection, thickness: Double) {
        count(inspection, "RUN", if (thickness > 3.6) 2.4 else 0.9)
        count(inspection, "SCR", 0.2)
    }

    private fun inspect(part: String, operator: String, at: LocalDateTime, day: LocalDate, suffix: String): Inspection {
        val lot = "L" + day.format(DateTimeFormatter.ofPattern("yyMMdd")) + "-" + suffix
        return Inspection(part, operator, at, lot).also { inspections += it }
    }

    private fun measure(inspection: Inspection, characteristic: String, value: Double, scale: Int) {
        measurements += Measurement(inspection, characteristic, BigDecimal(value).setScale(scale, RoundingMode.HALF_UP))
    }

    private fun count(inspection: Inspection, code: String, mean: Double) {
        val n = KSLRandom.rPoisson(mean, Streams.DEFECTS)
        if (n > 0) defects += DefectCount(inspection, code, n)
    }

    // ------------------------------------------------------------------- SQL

    fun summary(): String =
        "${newCustomers.size} customers, ${orders.size} orders, ${lines.size} order lines, " +
            "${shipments.size} shipments, ${shipmentLines.size} shipment lines, " +
            "${inspections.size} inspections, ${measurements.size} measurements, ${defects.size} defect counts"

    fun toSql(): String = buildString {
        appendLine(HEADER)
        appendLine("-- ${summary()}.")
        appendLine()
        insert("distribution.customer (customer_number, name, city, state)",
            null, newCustomers.map { listOf(q(it.number), q(it.name), q(it.city), q(it.state)) })
        insert("distribution.customer_order (order_number, order_date, requested_ship_date, customer_fk)",
            Join("v (order_number, order_date, requested_ship_date, customer_number)",
                "v.order_number, v.order_date::DATE, v.requested_ship_date::DATE, c.customer_pk",
                "JOIN distribution.customer c ON c.customer_number = v.customer_number"),
            orders.map { listOf(q(it.number), q(it.date), q(it.requestedShipDate), q(it.customer.number)) })
        insert("distribution.order_line (customer_order_fk, line_number, product_fk, quantity, unit_price)",
            Join("v (order_number, line_number, product_number, quantity, unit_price)",
                "o.customer_order_pk, v.line_number, p.product_pk, v.quantity, v.unit_price",
                "JOIN distribution.customer_order o ON o.order_number = v.order_number\n" +
                    "JOIN distribution.product p ON p.product_number = v.product_number"),
            lines.map { listOf(q(it.order.number), "${it.lineNumber}", q(it.product.number), "${it.quantity}", "${it.unitPrice}") })
        insert("distribution.shipment (shipment_number, shipped_on, carrier, customer_order_fk, warehouse_fk)",
            Join("v (shipment_number, shipped_on, carrier, order_number, warehouse_code)",
                "v.shipment_number, v.shipped_on::DATE, v.carrier, o.customer_order_pk, w.warehouse_pk",
                "JOIN distribution.customer_order o ON o.order_number = v.order_number\n" +
                    "JOIN distribution.warehouse w ON w.warehouse_code = v.warehouse_code"),
            shipments.map { listOf(q(it.number), q(it.date), q(it.carrier), q(it.order.number), q(it.order.customer.warehouse)) })
        insert("distribution.shipment_line (shipment_fk, order_line_fk, quantity)",
            Join("v (shipment_number, order_number, line_number, quantity)",
                "s.shipment_pk, l.order_line_pk, v.quantity",
                "JOIN distribution.shipment s ON s.shipment_number = v.shipment_number\n" +
                    "JOIN distribution.customer_order o ON o.order_number = v.order_number\n" +
                    "JOIN distribution.order_line l ON l.customer_order_fk = o.customer_order_pk AND l.line_number = v.line_number"),
            shipmentLines.map { listOf(q(it.shipment.number), q(it.line.order.number), "${it.line.lineNumber}", "${it.quantity}") })
        insert("quality.inspection (part_fk, operator_fk, inspected_at, lot_number)",
            Join("v (part_number, employee_number, inspected_at, lot_number)",
                "p.part_pk, e.operator_pk, v.inspected_at::TIMESTAMP, v.lot_number",
                "JOIN production.part p ON p.part_number = v.part_number\n" +
                    "JOIN production.operator e ON e.employee_number = v.employee_number"),
            inspections.map { listOf(q(it.part), q(it.operator), q(it.at.toString().replace('T', ' ')), q(it.lot)) })
        insert("quality.measurement (inspection_fk, characteristic_fk, measured_value)",
            Join("v (lot_number, characteristic, measured_value)",
                "i.inspection_pk, c.characteristic_pk, v.measured_value",
                "JOIN quality.inspection i ON i.lot_number = v.lot_number\n" +
                    "JOIN quality.characteristic c ON c.part_fk = i.part_fk AND c.name = v.characteristic"),
            measurements.map { listOf(q(it.inspection.lot), q(it.characteristic), "${it.value}") })
        insert("quality.defect_count (inspection_fk, defect_type_fk, quantity)",
            Join("v (lot_number, defect_code, quantity)",
                "i.inspection_pk, t.defect_type_pk, v.quantity",
                "JOIN quality.inspection i ON i.lot_number = v.lot_number\n" +
                    "JOIN quality.defect_type t ON t.defect_code = v.defect_code"),
            defects.map { listOf(q(it.inspection.lot), q(it.defectCode), "${it.quantity}") })
    }

    /** How rows given by business identifiers are turned into rows with keys. */
    private class Join(val alias: String, val select: String, val joins: String)

    private fun StringBuilder.insert(target: String, join: Join?, rows: List<List<String>>) {
        appendLine("INSERT INTO $target")
        if (join == null) {
            appendLine("VALUES")
            appendLine(rows.joinToString(",\n") { "    (" + it.joinToString(", ") + ")" } + ";")
        } else {
            appendLine("SELECT ${join.select}")
            appendLine("FROM (VALUES")
            appendLine(rows.joinToString(",\n") { "    (" + it.joinToString(", ") + ")" })
            appendLine(") AS ${join.alias}")
            appendLine(join.joins + ";")
        }
        appendLine()
    }

    private fun q(value: Any?): String = if (value == null) "NULL" else "'" + value.toString().replace("'", "''") + "'"
}

private val HEADER = """
-- HG Industries, stage G: a year of history.
--
-- GENERATED by dbconcepts.history.GenerateHistory in the companion code
-- project; edit that program, not this file. It appends to the base data:
--   * 22 new customers, and orders from April 2026 through March 2027, with
--     their order lines and shipments. Orders follow the seasons (carts in
--     the spring, hand trucks toward the end of the year); the poly cart
--     GC-400 is sold from September 2026; some lines ship in two parts; the
--     last orders of March 2027 are still open. C-1008 still never orders.
--   * Inspections from April through September 2026. The axle diameter rises
--     as the lathe's tool wears and drops at each tool change.
--
-- Requires: stage Q, loaded into a freshly reset database.
-- Load everything through this stage in one step: ../load/through-g.sql
""".trimIndent()
