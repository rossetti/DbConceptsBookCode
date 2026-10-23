package dbconcepts.simulation

import ksl.modeling.elements.EventGenerator
import ksl.modeling.elements.EventGeneratorIfc
import ksl.modeling.station.QObjectReceiverIfc
import ksl.modeling.station.SingleQStation
import ksl.modeling.variable.Counter
import ksl.modeling.variable.Response
import ksl.modeling.variable.TWResponse
import ksl.simulation.ModelElement
import ksl.utilities.random.rvariable.ExponentialRV
import ksl.utilities.random.rvariable.TriangularRV

/**
 * One operation of a routing, as the production schema records it: the work
 * center that performs it, its setup minutes, its run minutes per unit, and
 * the number of machines that can perform it.
 */
data class RoutingStep(
    val workCenterCode: String,
    val setupMinutes: Double,
    val runMinutesPerUnit: Double,
    val machines: Int
)

/**
 * The hand truck frame line of HG Industries: work orders for lots of frames
 * arrive at random and visit the routing's work centers in order, each a
 * station with a single queue and as many servers as it has machines. A
 * lot's time at a work center is its setup plus its run time for the whole
 * lot, varied by a triangular distribution from 10 percent below to 20
 * percent above. Times are in minutes; the time in shop is recorded in hours.
 * See @sec-simdb-inputs.
 */
class FrameLine(
    parent: ModelElement,
    routing: List<RoutingStep>,
    lotSize: Int,
    meanMinutesBetweenLots: Double,
    name: String? = null
) : ModelElement(parent, name) {

    private val workInProcess = TWResponse(parent = this, name = "WorkInProcess")
    private val timeInShop = Response(parent = this, name = "TimeInShop")
    private val lotsCompleted = Counter(parent = this, name = "LotsCompleted")

    private val arrivals = ExponentialRV(meanMinutesBetweenLots, 1)
    private val generator = EventGenerator(
        parent = this, generateAction = this::arrival,
        timeUntilFirstRV = arrivals, timeBtwEventsRV = arrivals,
        name = "LotArrivals"
    )

    // region stations
    /** The stations, one per routing step, in routing order. */
    val stations: List<SingleQStation> = routing.mapIndexed { i, step ->
        val minutes = step.setupMinutes + step.runMinutesPerUnit * lotSize
        SingleQStation(
            parent = this,
            activityTime = TriangularRV(0.9 * minutes, minutes, 1.2 * minutes, i + 2),
            initialCapacity = step.machines,
            name = step.workCenterCode
        )
    }

    init {
        for (i in 0 until stations.size - 1) stations[i].nextReceiver(stations[i + 1])
        stations.last().nextReceiver(Exit())
    }
    // endregion

    private fun arrival(generator: EventGeneratorIfc) {
        workInProcess.increment()
        stations.first().receive(QObject())
    }

    // region exit
    private inner class Exit : QObjectReceiverIfc {
        override fun receive(arrivingQObject: QObject) {
            timeInShop.value = (time - arrivingQObject.createTime) / 60.0
            lotsCompleted.increment()
            workInProcess.decrement()
        }
    }
    // endregion
}
