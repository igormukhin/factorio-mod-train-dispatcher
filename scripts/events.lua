function script_on_init()

end

function script_on_load()

end

function script_on_configuration_changed()

end

function event_on_entity_renamed(e)
    -- game.print("Renamed " .. e.old_name .. " to " .. e.entity.backer_name)

    -- TODO: copy/pasting a station does fire on_entity_renamed

    -- rename the key in station_states
    local stationState = station_states[e.old_name]
    station_states[e.entity.backer_name] = stationState
    station_states[e.old_name] = nil

    refresh_units(e.entity.surface)
end

function event_on_train_changed_state(e)
    -- game.print("Train " .. e.train.id .. " changed state to " .. e.train.state)
    if e.train.state == defines.train_state.wait_station then
        --game.print("Train " .. e.train.id .. " arrived at " .. e.train.station.backer_name .. " on " .. e.tick)

        local stationState = get_station_state(e.train.station)
        stationState.lastArrivedAt = e.tick

        local trainState = get_train_state(e.train)
        trainState.waitingAtStation = e.train.station;

    else
        if e.train.station == nil then
            local trainState = get_train_state(e.train)
            if trainState.waitingAtStation ~= nil then
                local stationState = get_station_state(trainState.waitingAtStation)
                stationState.lastDepartedAt = e.tick
                --game.print("Set lastDepartedAt to " .. stationState.lastDepartedAt .. " for station " .. trainState.waitingAtStation.backer_name)
                trainState.waitingAtStation = nil
            end
        end
    end
end

function get_station_state(stopEntity)
    if not station_states[stopEntity.backer_name] then station_states[stopEntity.backer_name] = {} end
    return station_states[stopEntity.backer_name]
end

function get_train_state(trainEntity)
    if not train_states[trainEntity.id] then train_states[trainEntity.id] = {} end
    return train_states[trainEntity.id]
end

function get_dispatcher_postfix()
    return "Dispatcher";
end

function is_dispatcher(stopEntity)
    return string.ends(stopEntity.backer_name, get_dispatcher_postfix())
end

function get_unit_name(stopEntity)
    if is_dispatcher(stopEntity) then
        return stopEntity.backer_name:sub(1, stopEntity.backer_name:len() - get_dispatcher_postfix():len())
    else
        error("not a dispatcher")
    end
end

function refresh_units(surface)
    local stops = surface.find_entities_filtered{type = "train-stop" }
    table.clear(units)

    -- find unit names
    for _, stop in ipairs(stops) do
        if is_dispatcher(stop) then
            units[get_unit_name(stop)] = { endpoints = {} }
        end
    end

    -- find endpoints
    for _, stop in ipairs(stops) do
        if not is_dispatcher(stop) then
            for unitName, unitData in pairs(units) do
                if string.starts(stop.backer_name, unitName) then
                    unitData.endpoints[stop.backer_name] = true
                end
            end
        end
    end

    game.print(table.tostring(units))
end