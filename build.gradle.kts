import org.gradle.jvm.tasks.Jar

group = "app.shosetsu.ext"
version = "0.0.0"
description = "extensions"

plugins {
	kotlin("jvm") version "1.4.10"
	id("org.jetbrains.dokka") version "0.10.0"
	maven
}
tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile> { kotlinOptions.jvmTarget = "1.8" }

tasks.dokka {
	outputFormat = "html"
	outputDirectory = "$buildDir/javadoc"
}

val dokkaJar by tasks.creating(Jar::class) {
	group = JavaBasePlugin.DOCUMENTATION_GROUP
	description = "Assembles Kotlin docs with Dokka"
	classifier = "javadoc"
}

repositories {
	jcenter()
	mavenCentral()
	maven("https://jitpack.io")
}

dependencies {
	implementation(kotlin("stdlib"))
	implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8:1.4.10")
	testImplementation("junit:junit:4.12")
	implementation(kotlin("script-runtime"))
}

