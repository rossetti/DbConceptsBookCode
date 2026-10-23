plugins {
    // Lets Gradle download a JDK matching jvmToolchain(21) in build.gradle.kts
    // when the machine has none, so the examples build without a manual install.
    id("org.gradle.toolchains.foojay-resolver-convention") version "1.0.0"
}

rootProject.name = "dbconcepts-code"
