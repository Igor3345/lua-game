
local View = {}
View.__index = View

function View:new(model)
    local self = setmetatable({}, View)
    self.model = model
    return self
end

function View:render()
    self.model:dump()
end

function View:prompt()
    io.write("> ")
    io.flush()
end

function View:readInput()
    return io.read("*line")
end

return View