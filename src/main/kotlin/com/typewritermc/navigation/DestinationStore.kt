package com.typewritermc.navigation

import com.typewritermc.core.extension.annotations.Singleton
import com.typewritermc.core.utils.point.Position
import org.bukkit.entity.Player
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap

@Singleton
class DestinationStore {
    private val destinations = ConcurrentHashMap<DestinationKey, Position>()

    fun set(player: Player, destinationVariableId: String, position: Position) {
        destinations[DestinationKey(player.uniqueId, destinationVariableId)] = position
    }

    fun get(player: Player, destinationVariableId: String): Position? {
        return destinations[DestinationKey(player.uniqueId, destinationVariableId)]
    }

    fun clear(player: Player, destinationVariableId: String) {
        destinations.remove(DestinationKey(player.uniqueId, destinationVariableId))
    }
}

private data class DestinationKey(
    val playerId: UUID,
    val destinationVariableId: String,
)

