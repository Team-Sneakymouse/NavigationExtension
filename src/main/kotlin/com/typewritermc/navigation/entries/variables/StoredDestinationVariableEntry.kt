package com.typewritermc.navigation.entries.variables

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.GenericConstraint
import com.typewritermc.core.extension.annotations.VariableData
import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.entry.entries.VarContext
import com.typewritermc.engine.paper.entry.entries.VariableEntry
import com.typewritermc.engine.paper.entry.entries.cast
import com.typewritermc.engine.paper.entry.entries.getData
import com.typewritermc.navigation.DestinationStore
import org.koin.java.KoinJavaComponent.get

@Entry(
    "stored_destination_variable",
    "A per-player stored destination (in-memory)",
    Colors.GREEN,
    "material-symbols:flag-circle-rounded"
)
@Tags("variable")
@GenericConstraint(Position::class)
@VariableData(StoredDestinationVariableData::class)
class StoredDestinationVariableEntry(
    override val id: String = "",
    override val name: String = "",
) : VariableEntry {
    override fun <T : Any> get(context: VarContext<T>): T {
        val data = context.getData<StoredDestinationVariableData>()
        val default = data?.default ?: Position.ORIGIN

        val store = get<DestinationStore>(DestinationStore::class.java)
        val stored = store.get(context.player, id)
        return context.cast(stored ?: default)
    }
}

private data class StoredDestinationVariableData(
    val default: Position = Position.ORIGIN,
)

