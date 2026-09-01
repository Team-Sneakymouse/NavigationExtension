package com.typewritermc.navigation.entries.action

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.WithRotation
import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.entry.Criteria
import com.typewritermc.engine.paper.entry.Modifier
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.entries.ActionEntry
import com.typewritermc.engine.paper.entry.entries.ActionTrigger
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.navigation.DestinationStore
import com.typewritermc.navigation.entries.variables.StoredDestinationVariableEntry
import org.koin.java.KoinJavaComponent.get

@Entry(
    "set_stored_destination",
    "Store a destination for later path streaming",
    Colors.RED,
    "material-symbols:flag-circle"
)
class SetStoredDestinationActionEntry(
    override val id: String = "",
    override val name: String = "",
    override val criteria: List<Criteria> = emptyList(),
    override val modifiers: List<Modifier> = emptyList(),
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    val destination: Ref<StoredDestinationVariableEntry> = emptyRef(),
    @WithRotation
    val position: Var<Position> = ConstVar(Position.ORIGIN),
) : ActionEntry {
    override fun ActionTrigger.execute() {
        val entry = destination.get() ?: return
        val store = get<DestinationStore>(DestinationStore::class.java)
        store.set(player, entry.id, position.get(player, context))
    }
}

