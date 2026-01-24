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
    val project = this
    
    // Define the fix as a reusable function
    val applyAndroidFix = {
        if (project.extensions.findByName("android") != null) {
            val android = project.extensions.getByName("android")
            try {
                // 1. Force Compile SDK to 36 (Fixes 'lStar' error)
                val setCompileSdk = android.javaClass.getMethod("setCompileSdkVersion", Int::class.javaPrimitiveType)
                setCompileSdk.invoke(android, 36)
                
                // 2. Fix Namespace (Fixes isar_flutter_libs build failure)
                val getNamespace = android.javaClass.getMethod("getNamespace")
                val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
                
                if (getNamespace.invoke(android) == null) {
                    val cleanName = project.name.replace("-", "_")
                    val ns = if (project.name == "isar_flutter_libs") "dev.isar.isar_flutter_libs" 
                             else "cc.koto.fluent_lyrics.$cleanName"
                    setNamespace.invoke(android, ns)
                }
            } catch (e: Exception) {
                // Method might not exist in some non-android subprojects
            }
        }
    }

    // Apply immediately if already evaluated, otherwise wait
    if (project.state.executed) {
        applyAndroidFix()
    } else {
        project.afterEvaluate { 
            applyAndroidFix()
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
