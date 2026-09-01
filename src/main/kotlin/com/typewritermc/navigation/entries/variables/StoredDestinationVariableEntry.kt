package com.typewritermc.navigation.entries.variables

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.VariableData
import com.google.gson.JsonObject
import com.typewritermc.core.utils.Generic
import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.World
import com.typewritermc.engine.paper.entry.entries.VarContext
import com.typewritermc.engine.paper.entry.entries.VariableEntry
import com.typewritermc.engine.paper.entry.entries.cast
import com.typewritermc.engine.paper.entry.entries.getData
import com.typewritermc.engine.paper.utils.toWorld
import com.typewritermc.navigation.DestinationStore
import org.koin.java.KoinJavaComponent.get

@Entry(
    "stored_destination_variable",
    "A per-player stored destination (in-memory)",
    Colors.GREEN,
    "material-symbols:flag-circle-rounded"
)
@Tags("variable")
@VariableData(StoredDestinationVariableData::class)
class StoredDestinationVariableEntry(
    override val id: String = "",
    override val name: String = "",
) : VariableEntry {
    override fun <T : Any> get(context: VarContext<T>): T {
        val store = get<DestinationStore>(DestinationStore::class.java)
        val stored = store.get(context.player, id)
        if (stored != null) {
            return context.cast(stored)
        }

        return context.cast(resolveDefault(context))
    }

    private fun resolveDefault(context: VarContext<*>): Position {
        val defaultJson = defaultJson(context.data)
        if (defaultJson != null && worldIdentifier(defaultJson).isEmpty()) {
            return positionFromJson(defaultJson, context.player.world.toWorld())
        }

        val data = context.getData<StoredDestinationVariableData>()
        val default = data?.default ?: Position.ORIGIN
        return if (default.world.identifier.isEmpty()) {
            default.withWorld(context.player.world.toWorld())
        } else {
            default
        }
    }

    private fun defaultJson(data: Generic): JsonObject? {
        if (!data.data.isJsonObject) return null
        val default = data.data.asJsonObject.get("default") ?: return null
        if (!default.isJsonObject) return null
        return default.asJsonObject
    }

    private fun worldIdentifier(defaultJson: JsonObject): String {
        val worldElement = defaultJson.get("world") ?: return ""
        if (worldElement.isJsonNull) return ""
        if (worldElement.isJsonPrimitive) return worldElement.asString
        if (worldElement.isJsonObject) {
            return worldElement.asJsonObject.get("identifier")?.asString ?: ""
        }
        return ""
    }

    private fun positionFromJson(defaultJson: JsonObject, world: World): Position {
        return Position(
            world,
            defaultJson.get("x")?.asDouble ?: 0.0,
            defaultJson.get("y")?.asDouble ?: 0.0,
            defaultJson.get("z")?.asDouble ?: 0.0,
            (defaultJson.get("yaw")?.asDouble ?: 0.0).toFloat(),
            (defaultJson.get("pitch")?.asDouble ?: 0.0).toFloat(),
        )
    }
}

private data class StoredDestinationVariableData(
    val default: Position = Position.ORIGIN,
)

