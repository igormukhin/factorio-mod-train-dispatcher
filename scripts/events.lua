function init()
    if already_init then
        return
    end
    --noinspection GlobalCreationOutsideO
    already_init = true

    global.station_states = global.station_states or { }
    global.train_states = global.train_states or { }
    global.units = global.units or { }

    --noinspection GlobalCreationOutsideO
    station_states = global.station_states
    --noinspection GlobalCreationOutsideO
    train_states = global.train_states
    --noinspection GlobalCreationOutsideO
    units = global.units
end

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
        trainState.waitingAtStation = e.train.station

        if (is_dispatcher(e.train.station.backer_name)) then
            on_train_arrived_at_dipatcher(e.train)
        end

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
    return "Dispatcher"
end

function is_dispatcher(stopName)
    return string.ends(stopName, get_dispatcher_postfix())
end

function get_unit_name(dispatcherStopName)
    if is_dispatcher(dispatcherStopName) then
        return dispatcherStopName:sub(1, dispatcherStopName:len() - get_dispatcher_postfix():len())
    else
        error("not a dispatcher")
    end
end

function refresh_units(surface)
    local stops = surface.find_entities_filtered{type = "train-stop" }
    table.clear(units)

    -- find unit names
    for _, stop in ipairs(stops) do
        if is_dispatcher(stop.backer_name) then
            units[get_unit_name(stop.backer_name)] = { endpoints = {} }
        end
    end

    -- find endpoints
    for _, stop in ipairs(stops) do
        if not is_dispatcher(stop.backer_name) then
            for unitName, unitData in pairs(units) do
                if string.starts(stop.backer_name, unitName) then
                    unitData.endpoints[stop.backer_name] = true
                end
            end
        end
    end

    -- game.print(table.tostring(units))
end

function on_train_arrived_at_dipatcher(train)
    make_train_wait_at_dispatcher(train)
end

function make_train_wait_at_dispatcher(train)
    local wait_conditions = train.schedule.records[train.schedule.current].wait_conditions
    -- game.print(table.tostring(train.schedule))

    if table.len(wait_conditions) == 1
            and wait_conditions[1].type == "circuit"
            and wait_conditions[1].condition.comparator == ">"
            and wait_conditions[1].condition.first_signal
            and wait_conditions[1].condition.first_signal.name == "signal-A"
            and wait_conditions[1].condition.second_signal
            and wait_conditions[1].condition.second_signal.name == "signal-A" then
        --game.print("Yes")
        return
    end

    -- Update the wait conditions for the dispatcher station
    local new_wait_conditions = { { type="circuit", compare_type="and", condition={ comparator=">",
        first_signal={ type="virtual", name="signal-A" },
        second_signal={ type="virtual", name="signal-A" } } } }

    local new_schedule = table.deepcopy(train.schedule)
    new_schedule.records[train.schedule.current].wait_conditions = new_wait_conditions

    -- If the next station is not the endpoint station then use the old conditions for it
    local dispatcherName =  train.station.backer_name
    local nextRecIdx = get_train_schedule_next_record_index(train)
    local endpointRecord = { station=get_any_station_name_for_unit(dispatcherName), wait_conditions=wait_conditions }
    if nextRecIdx == nil then
        -- if dipatcher is the last in schedule then just add a station
        new_schedule.records[train.schedule.current + 1] = endpointRecord

    elseif not is_endpoint_of_unit(new_schedule.records[nextRecIdx].station, dispatcherName) then
        -- if then station of the schedule does not belong to the unit, then insert an endpoint
        table.insert(new_schedule.records, nextRecIdx, endpointRecord)
    end

    game.print(table.tostring(new_schedule))
    train.schedule = new_schedule
end

-- this do not loop
function get_train_schedule_next_record_index(train)
    local nextIdx = train.schedule.current + 1
    game.print(table.tostring({ nextIdx=nextIdx, recordsLen=table.len(train.schedule.records) } ));
    if nextIdx > table.len(train.schedule.records) then
        return nil
    end
    return nextIdx
end

function get_any_station_name_for_unit(dispatcherStopName)
    local unitName = get_unit_name(dispatcherStopName)

    local defaultValue = unitName .. "1"
    if not units[unitName] then
        return defaultValue
    end

    local endpoints = units[unitName].endpoints
    if endpoints == nil or table.len(endpoints) == 0 then
        return defaultValue
    else
        for endpointName, _ in pairs(endpoints) do
            return endpointName
        end
    end
end

function is_endpoint_of_unit(endpointStopName, dispatcherStopName)
    local unitName = get_unit_name(dispatcherStopName)
    if not units[unitName] then
        return false
    end

    local endpoints = units[unitName].endpoints
    if endpoints ~= nil then
        for endpointName, _ in pairs(endpoints) do
            if endpointName == endpointStopName then
                return true
            end
        end
    end
    return false
end