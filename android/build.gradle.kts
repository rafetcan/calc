import com.android.build.gradle.LibraryExtension
import org.gradle.api.JavaVersion

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Eklenti modüllerinin (google_mobile_ads vb.) Java 8 uyarılarını kaldırmak için.
// `:app` kendi build.gradle.kts içinde zaten 17; burada yalnızca library eklentileri.
subprojects {
    plugins.withId("com.android.library") {
        extensions.configure<LibraryExtension>("android") {
            compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
/*
dependencies {
  implementation("com.google.android.gms:play-services-ads:23.6.0")
}
*/
