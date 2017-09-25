function script_on_init()

end

function script_on_load()

end

function script_on_configuration_changed()

end

function event_on_entity_renamed(e)
    game.print("Renamed " .. e.old_name .. " to " .. e.entity.backer_name)

    -- rename the key in station_states
    local stationState = station_states[e.old_name]
    station_states[e.entity.backer_name] = stationState
    station_states[e.old_name] = nil

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

function is_dispatcher(stopEntity)
    return stopEntity.backer_name:ends('Dispatcher')
end