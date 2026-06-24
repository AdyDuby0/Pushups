-- Tracks the main side panels (Power Core, Market, Crafting) so only one is
-- open at a time. Each panel registers a close function; opening one closes
-- the others.

local Panels = {}
local registry = {}  -- name -> closeFn

function Panels.Register(name, closeFn)
    registry[name] = closeFn
end

-- Close every registered panel except the one named.
function Panels.CloseOthers(name)
    for n, closeFn in pairs(registry) do
        if n ~= name then closeFn() end
    end
end

return Panels
