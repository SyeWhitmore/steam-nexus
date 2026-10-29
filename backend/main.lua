local millennium = require("millennium")
local function on_load()
    millennium.ready()
end
return { on_load = on_load }
