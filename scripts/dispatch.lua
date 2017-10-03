function dispatch_all()
    for unitName, _ in pairs(units) do
        dispatch_unit(unitName)
    end
end

function dispatch_unit(unitName)
    local unit = units[unitName]

    local trains = find_trains_to_dispatch(unit)

    while true do
        if table.len(trains) == 0 then
            return
        end

        local endpoint = find_endpoint_to_dispatch(unit)
        if endpoint == nil then
            return
        end

        do_dispatch(trains[1], endpoint)
        table.remove(trains, 1)
    end
end

function find_trains_to_dispatch(unit)
    local trains = main_surface.get_trains()
    local found = {}
    for _, train in ipairs(trains) do
        if train.station.backer_name == unit.unitName then
            table.insert(found, train)
        end
    end
    return found
end

function find_endpoint_to_dispatch(unit)
    return nil
end

function do_dispatch(train, endpoint)
end