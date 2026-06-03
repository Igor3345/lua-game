
local Config = require("config")
local Model = require("model")
local View = require("view")


local function parseMove(cmd)
    local parts = {}
    for part in cmd:gmatch("%S+") do
        table.insert(parts, part)
    end
    if #parts ~= 4 or parts[1] ~= 'm' then
        return nil
    end
    local x, y = tonumber(parts[2]), tonumber(parts[3])
    local d = parts[4]:lower()
    if not x or not y or not Config.DIRECTIONS[d] then
        return nil
    end
    return {
        from = {x = x, y = y},
        to = {
            x = x + Config.DIRECTIONS[d].dx,
            y = y + Config.DIRECTIONS[d].dy
        }
    }
end

local function trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local function main()
    math.randomseed(os.time())
    
    local model = Model:new()
    local view = View:new(model)
    
    model:init()
    view:render()
    
    while true do
        view:prompt()
        local input = view:readInput()
        if not input then break end
        
        input = trim(input):lower()
        
        if input == 'q' then
            print("Exiting. Good luck!")
            break
        end
        
        if input:sub(1,1) == 'm' then
            local move = parseMove(input)
            if not move then
                print("❌ Invalid format. Example: m 3 0 r")
                view:render()
            elseif not model:move(move.from, move.to) then
                print("❌ Move does not create matches!")
                view:render()
            else

                view:render()
                while model:tick() do
                    view:render()
                end

                if not model:hasValidMoves() then
                    print("⚠️ No valid moves! Shuffling...")
                    model:mix()
                    view:render()
                end
            end
        else
            print("❓ Commands: 'm x y d' = move, 'q' = quit")
            view:render()
        end
    end
end

main()