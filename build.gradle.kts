repositories {}

typewriter {
    namespace = "typewritermc"

    extension {
        name = "Navigation"
        shortDescription = "Store destinations for path streams"
        description = """
            |Adds entries to store and clear player destinations in-memory.
            |This enables Custom Commands to set a destination that RoadNetwork path streams can consume later.
            """.trimMargin()
        engineVersion = rootProject.extra["typewriterEngineVersion"] as String
        channel = com.typewritermc.moduleplugin.ReleaseChannel.NONE

        paper()
    }
}

