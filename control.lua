-- test

--[[
script.on_event({defines.events.on_tick},
    function (e)
        if e.tick % 300 == 0 then
            game.print("Igor")
        end
    end
)
]]--
