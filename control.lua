require("scripts.utils")
require("scripts.events")
require("scripts.commands")

script.on_init(script_on_init)
script.on_load(script_on_load)
script.on_configuration_changed(script_on_configuration_changed)

script.on_event(defines.events.on_entity_renamed, event_on_entity_renamed)
script.on_event(defines.events.on_train_changed_state, event_on_train_changed_state)

commands.add_command("td-status", {"", "Status of the Train Dispatcher mod"}, command_status)

script.on_event(defines.events.on_tick,
    function ()
        script.on_event(defines.events.on_tick, nil)
        init()
    end
)
