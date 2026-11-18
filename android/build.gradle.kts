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

                // 3. Strip applicationIdSuffix from library modules.
                // Flutter 3.50's gradle plugin copies the app's build types onto
                // every plugin via initWith (see flutter_tools PluginHandler
                // .copyAppBuildTypesToPlugin), which drags the app's .debug/.profile
                // applicationIdSuffix onto library modules. AGP rejects that on a
                // com.android.library. Clear it only for libraries; the :app module
                // keeps its intentional suffixes.
                if (project.plugins.hasPlugin("com.android.library")) {
                    val getBuildTypes = android.javaClass.getMethod("getBuildTypes")
                    @Suppress("UNCHECKED_CAST")
                    val buildTypes = getBuildTypes.invoke(android) as Iterable<Any?>
                    buildTypes.forEach { bt ->
                        if (bt != null) {
                            try {
                                val setSuffix = bt.javaClass.getMethod("setApplicationIdSuffix", String::class.java)
                                setSuffix.invoke(bt, null)
                            } catch (e: NoSuchMethodException) {
                                // Build type does not expose the setter; nothing to strip.
                            }
                        }
                    }
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
