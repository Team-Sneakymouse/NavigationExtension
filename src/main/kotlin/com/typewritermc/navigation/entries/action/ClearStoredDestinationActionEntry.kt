package com.typewritermc.navigation.entries.action

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.engine.paper.entry.Criteria
import com.typewritermc.engine.paper.entry.Modifier
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.entries.ActionEntry
import com.typewritermc.engine.paper.entry.entries.ActionTrigger
import com.typewritermc.navigation.DestinationStore
import com.typewritermc.navigation.entries.variables.StoredDestinationVariableEntry
import org.koin.java.KoinJavaComponent.get

@Entry(
    "clear_stored_destination",
    "Clear a stored destination",
    Colors.RED,
    "material-symbols:flag-circle-off"
)
class ClearStoredDestinationActionEntry(
    override val id: String = "",
    override val name: String = "",
    override val criteria: List<Criteria> = emptyList(),
    override val modifiers: List<Modifier> = emptyList(),
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    val destination: Ref<StoredDestinationVariableEntry> = emptyRef(),
) : ActionEntry {
    override fun ActionTrigger.execute() {
        val entry = destination.get() ?: return
        val store = get<DestinationStore>(DestinationStore::class.java)
        store.clear(player, entry.id)
    }
}

