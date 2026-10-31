# Companion code

SQL scripts, the data of the book's own small databases, and Kotlin examples
for *Database Concepts for Industrial Engineers*
(<https://rossetti.github.io/DbConceptsBook/>). The Kotlin examples use the database utilities of the
[Kotlin Simulation Library (KSL)](https://github.com/rossetti/KSL) to work with
PostgreSQL.

This is a **standalone project**. The book refers to the code; the code does not
refer to the book by chapter or section number, and nothing here needs the book
in order to build or run.

## What you need

- **PostgreSQL** 16 or later, installed and running on your own machine, and
  **DataGrip** or **DBeaver** to work with it. See the book's appendix on
  installing PostgreSQL.
- **A JDK**, for the Kotlin examples only. The build declares
  `jvmToolchain(21)` to match the KSL; with the toolchain resolver in
  `settings.gradle.kts`, Gradle downloads a JDK 21 if your machine has none.

## Connecting

The examples read their connection settings from `db.properties` in this
directory. Only a template is distributed, because the real file holds your
password:

```sh
cp db.properties.example db.properties    # then edit it
./gradlew run                             # checks the connection
```

The SQL scripts need no configuration beyond a connection in DataGrip or
DBeaver. Open `sql/setup/check-connection.sql` there and run it.

## Layout

```
build.gradle.kts          Kotlin JVM + application plugin; KSL from Maven Central
db.properties.example     connection settings template (copy to db.properties)
gradlew, gradle/          the Gradle wrapper (committed, so the build is reproducible)
sql/
  setup/                  connection checks, and which-stage.sql: what a database holds
  <schema>/               one directory per schema: one script per stage
  load/                   through-<stage>.sql: rebuild the database to any stage;
                          add-k.sql: the simulation's output, for chapter 12
  transit/                Millbrook Transit, the exercise database outside HG
  embedded/               SQLite and DuckDB scripts for the embedded appendix
  public/                 load-public.sh and its manifest: fetch a public sample
                          database from its source (the data is never shipped)
data/                     CSV files for the book's own databases
src/main/kotlin/dbconcepts/
  connecting/             BookDatabase (opens the database) and CheckConnection
  programming/            JDBC, SQL injection, a DAO, the KSL's Database,
                          data frames, CSV and Excel (./gradlew run -PmainClass=...)
  <topic>/                one package per subject, named for the subject
src/libraries/kotlin/dbconcepts/libraries/
  jooq/, exposed/, ktorm/ the same small program in each library, kept in its own
                          source set so the rest depends on the KSL alone
                          (./gradlew runLibrary -PmainClass=...)
src/main/resources/
  logback.xml             quiets library logging so example output stands alone
src/test/kotlin/          checks that pin what the book prints
```

**A directory or package is named for its subject, not for a chapter number.**
Chapter numbers move when the book is revised, and a directory named `ch06` then
has to be renamed or it lies. The same rule applies to SQL script names.

## What is here

| Package / directory | Subject |
|---|---|
| `dbconcepts.connecting`, `sql/setup/` | Connecting to the server and checking the connection |
| `dbconcepts.history` | `GenerateHistory`, which generates stage G, a year of order history and six months of inspections, from seeded KSL random number streams |
| `sql/distribution/`, `sql/production/`, `sql/quality/`, `sql/load/` | The book's database, HG Industries, built in stages; see [`sql/README.md`](sql/README.md) |

## Changing the KSL version

The dependency is pinned in `build.gradle.kts`:

```kotlin
implementation("io.github.rossetti:KSLCore:R1.8.1")
```

## License

GPL-3.0. See [LICENSE](LICENSE).
