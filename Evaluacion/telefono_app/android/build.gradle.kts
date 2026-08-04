allprojects {
    //repositories {
        //google()
      //  mavenCentral()
    //}
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Algunos plugins (ej. flutter_local_notifications 19.5.0) traen hardcodeado
// compileSdk 35 en su propio build.gradle. En esta máquina solo hay
// instaladas las plataformas 34/36/36.1, así que forzamos 34 en todos los
// módulos de librería (los plugins) para no depender de descargar la 35.
// No afecta al módulo :app, que sigue usando flutter.compileSdkVersion.
subprojects {
    // :app ya quedó evaluado por el evaluationDependsOn(":app") de arriba,
    // así que afterEvaluate() ya no se puede registrar sobre él (y tampoco
    // hace falta: :app no es un módulo de librería).
    if (name != "app") {
        // afterEvaluate: el build.gradle propio del plugin (que fija
        // compileSdk 35) ya corrió para cuando esto se ejecuta, así que
        // nuestro valor gana.
        afterEvaluate {
            extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)?.let {
                it.compileSdk = 34
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
