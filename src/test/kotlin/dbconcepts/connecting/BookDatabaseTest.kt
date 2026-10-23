package dbconcepts.connecting

import java.nio.file.Files
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertTrue

// These checks need no database server. They pin how the connection settings
// are read, which every example depends on.
class BookDatabaseTest {

    @Test
    fun missingSettingsFileExplainsWhatToDo() {
        val path = Files.createTempDirectory("dbconcepts").resolve("db.properties")
        val e = assertFailsWith<IllegalArgumentException> { BookDatabase.readProperties(path) }
        assertTrue(e.message!!.contains("db.properties.example"))
    }

    @Test
    fun settingsAreReadFromTheFile() {
        val path = Files.createTempFile("db", ".properties")
        Files.writeString(path, "host=db.example.edu\nport=5433\ndatabase=plant\nuser=student\n")
        val p = BookDatabase.readProperties(path)
        assertEquals("db.example.edu", p.getProperty("host"))
        assertEquals("5433", p.getProperty("port"))
        assertEquals("plant", p.getProperty("database"))
    }
}
