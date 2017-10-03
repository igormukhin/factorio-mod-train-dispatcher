function command_status()
    game.print("station_states: " .. table.tostring(station_states))
    game.print("train_states: " .. table.tostring(train_states))
    game.print("units: " .. table.tostring(units))

    for sn, _ in pairs(game.surfaces) do
        game.print("surface: " .. sn)
    end
end

function command_refresh()
    refresh_units()
end