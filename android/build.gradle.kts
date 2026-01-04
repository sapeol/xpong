allprojects {
    repositories {
        google()
        mavenCentral()
    }
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

subprojects {
    if (project.name == "flutter_nearby_connections") {
        fun configureAndroid(p: Project) {
            val android = p.extensions.findByName("android")
            if (android != null) {
                try {
                    // Set namespace
                    val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
                    setNamespace.invoke(android, "com.nankai.flutter_nearby_connections")
                    
                    // Set compile options to Java 17
                    val compileOptions = android.javaClass.getMethod("getCompileOptions").invoke(android)
                    val setSourceCompatibility = compileOptions.javaClass.getMethod("setSourceCompatibility", JavaVersion::class.java)
                    val setTargetCompatibility = compileOptions.javaClass.getMethod("setTargetCompatibility", JavaVersion::class.java)
                    
                    setSourceCompatibility.invoke(compileOptions, JavaVersion.VERSION_17)
                    setTargetCompatibility.invoke(compileOptions, JavaVersion.VERSION_17)
                } catch (e: Exception) {
                    println("Failed to configure flutter_nearby_connections: ${e.message}")
                }
            }
        }

        if (project.state.executed) {
             configureAndroid(project)
        } else {
            project.afterEvaluate {
                configureAndroid(project)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
