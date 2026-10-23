// =============================================================================
// Companion code for "Database Concepts for Industrial Engineers".
//
// Standalone Gradle project, deliberately NOT part of the Quarto book build.
// `quarto render` neither builds nor needs this; the book references the code,
// and the code does not reference the book by number.
//
//   cd code && ./gradlew run          # runs the default example
//   cd code && ./gradlew build        # compiles everything
//
// The SQL scripts under sql/ are part of the same public project. They run on
// their own in DataGrip or DBeaver, and the Kotlin examples can execute them
// through the KSL database utilities.
//
// THIS PROJECT IS PUBLIC. Nothing instructor-only may live here, not even in
// a source set that the jar excludes, because what goes public is the SOURCE;
// the answers to the book's exercises are kept elsewhere.
// =============================================================================
plugins {
    kotlin("jvm") version "2.4.20"
    application
}

group = "edu.uark.dbconcepts"
version = "0.1.0"

repositories {
    mavenCentral()
}

dependencies {
    // The Kotlin Simulation Library, from Maven Central. Its database utilities
    // (ksl.utilities.io.dbutil) wrap JDBC for PostgreSQL, SQLite, and Derby.
    implementation("io.github.rossetti:KSLCore:R1.8.1")
    testImplementation(kotlin("test"))
}

kotlin {
    // KSL targets JVM 21; match it so the toolchains agree.
    jvmToolchain(21)
}

application {
    // Override from the command line, for example
    //   ./gradlew run -PmainClass=dbconcepts.connecting.CheckConnectionKt
    mainClass.set(
        providers.gradleProperty("mainClass").orElse("dbconcepts.connecting.CheckConnectionKt")
    )
}

tasks.named<JavaExec>("run") {
    // Run from the project directory so db.properties and sql/ resolve.
    workingDir = projectDir
}

tasks.test {
    useJUnitPlatform()
}

// The libraries source set (src/libraries/kotlin): the same small programs
// written with jOOQ, Exposed, and Ktorm (@sec-prog-libraries). It is kept apart
// so that the main examples depend on the KSL alone.
//
//   ./gradlew runLibrary -PmainClass=dbconcepts.libraries.jooq.JooqLotKt
val libraries: SourceSet by sourceSets.creating {
    compileClasspath += sourceSets.main.get().output
    runtimeClasspath += sourceSets.main.get().output
}
configurations[libraries.implementationConfigurationName].extendsFrom(configurations.implementation.get())
configurations[libraries.runtimeOnlyConfigurationName].extendsFrom(configurations.runtimeOnly.get())

dependencies {
    "librariesImplementation"("org.jooq:jooq:3.21.9")
    "librariesImplementation"("org.jetbrains.exposed:exposed-core:1.5.0")
    "librariesImplementation"("org.jetbrains.exposed:exposed-jdbc:1.5.0")
    "librariesImplementation"("org.ktorm:ktorm-core:4.2.1")
    "librariesImplementation"("org.ktorm:ktorm-support-postgresql:4.2.1")
}

tasks.register<JavaExec>("runLibrary") {
    group = "application"
    description = "Runs a program of the libraries source set; set -PmainClass."
    classpath = libraries.runtimeClasspath
    mainClass.set(providers.gradleProperty("mainClass"))
    workingDir = projectDir
}
