
local Config = require("config")

local Model = {}
Model.__index = Model

-- Constructor
function Model:new()
    local self = setmetatable({}, Model)
    self.field = {}
    self.width = Config.WIDTH
    self.height = Config.HEIGHT
    self.crystalTypes = Config.CRYSTAL_TYPES
    
    -- Реестр детекторов совпадений
    self.match_detectors = {}
    self:_register_default_detectors()
    
    return self
end

function Model:init()
    self.field = {}
    for y = 0, self.height - 1 do
        self.field[y] = {}
        for x = 0, self.width - 1 do
            self.field[y][x] = self:_randomCrystal()
        end
    end
    while #self:_findMatches() > 0 do
        for y = 0, self.height - 1 do
            for x = 0, self.width - 1 do
                self.field[y][x] = self:_randomCrystal()
            end
        end
    end
end

function Model:_randomCrystal()
    return self.crystalTypes[math.random(1, #self.crystalTypes)]
end

function Model:_isValid(x, y)
    return x >= 0 and x < self.width and y >= 0 and y < self.height
end

function Model:_register_default_detectors()

    self:add_match_detector("linear", function(model)
        local matches = {}
        local marked = {}
        for y = 0, model.height - 1 do
            marked[y] = {}
            for x = 0, model.width - 1 do marked[y][x] = false end
        end

        -- Горизонталь
        for y = 0, model.height - 1 do
            local x = 0
            while x < model.width do
                local crystal = model.field[y][x]
                local seq = {x}
                while x + #seq < model.width and model.field[y][x + #seq] == crystal do
                    table.insert(seq, x + #seq)
                end
                if #seq >= 3 then
                    for _, mx in ipairs(seq) do marked[y][mx] = true end
                end
                x = x + math.max(#seq, 1)
            end
        end

        -- Вертикаль
        for x = 0, model.width - 1 do
            local y = 0
            while y < model.height do
                local crystal = model.field[y][x]
                local seq = {y}
                while y + #seq < model.height and model.field[y + #seq][x] == crystal do
                    table.insert(seq, y + #seq)
                end
                if #seq >= 3 then
                    for _, my in ipairs(seq) do marked[my][x] = true end
                end
                y = y + math.max(#seq, 1)
            end
        end

        for y = 0, model.height - 1 do
            for x = 0, model.width - 1 do
                if marked[y][x] then
                    table.insert(matches, {x = x, y = y})
                end
            end
        end
        return matches
    end)
end

function Model:add_match_detector(name, detector_fn)
    self.match_detectors[name] = detector_fn
end

function Model:_findMatches()
    local all_matches = {}
    local seen = {}
    
    for _, detector_fn in pairs(self.match_detectors) do
        local detected = detector_fn(self)
        for _, pos in ipairs(detected) do
            local key = pos.y * self.width + pos.x
            if not seen[key] then
                seen[key] = true
                table.insert(all_matches, pos)
            end
        end
    end
    return all_matches
end

function Model:_removeCrystals(positions)
    for _, pos in ipairs(positions) do
        self.field[pos.y][pos.x] = nil
    end
end

function Model:_applyGravity()
    for x = 0, self.width - 1 do
        local writeY = self.height - 1
        for y = self.height - 1, 0, -1 do
            if self.field[y][x] ~= nil then
                if writeY ~= y then
                    self.field[writeY][x] = self.field[y][x]
                    self.field[y][x] = nil
                end
                writeY = writeY - 1
            end
        end
    end
end

function Model:_fillEmpty()
    for y = 0, self.height - 1 do
        for x = 0, self.width - 1 do
            if self.field[y][x] == nil then
                self.field[y][x] = self:_randomCrystal()
            end
        end
    end
end

function Model:tick()
    local matches = self:_findMatches()
    if #matches == 0 then
        return false
    end
    self:_removeCrystals(matches)
    self:_applyGravity()
    self:_fillEmpty()
    return true
end

function Model:move(from, to)
    if not self:_isValid(from.x, from.y) or not self:_isValid(to.x, to.y) then
        return false
    end
    local dx = math.abs(from.x - to.x)
    local dy = math.abs(from.y - to.y)
    if dx + dy ~= 1 then
        return false 
    end

    self.field[from.y][from.x], self.field[to.y][to.x] = 
        self.field[to.y][to.x], self.field[from.y][from.x]

    if #self:_findMatches() == 0 then
        self.field[from.y][from.x], self.field[to.y][to.x] = 
            self.field[to.y][to.x], self.field[from.y][from.x]
        return false
    end
    return true
end

function Model:mix()
    repeat
        for y = 0, self.height - 1 do
            for x = 0, self.width - 1 do
                self.field[y][x] = self:_randomCrystal()
            end
        end
    until #self:_findMatches() == 0
    -- ⚠️ Для прототипа: не гарантируем наличие ходов,
    -- но архитектура позволяет добавить проверку hasValidMoves()
end

function Model:dump()
    io.write("  ")
    for x = 0, self.width - 1 do
        io.write(x .. " ")
    end
    io.write("\n  ")
    for _ = 0, self.width - 1 do
        io.write("- ")
    end
    io.write("\n")
    
    -- Строки поля
    for y = 0, self.height - 1 do
        io.write(y .. "|")
        for x = 0, self.width - 1 do
            io.write(self.field[y][x] .. " ")
        end
        io.write("\n")
    end
end

-- Что бы ввести в игру новые типы камней и выстроить поведение при построении комбинаций нужно:
-- 1. Заменить строки 'A'..'F' на объекты типа Crystal {type='A', special=nil}
-- 2. В _findMatches() добавить проверку специальных эффектов
-- 3. В tick() обрабатывать цепочки активаций


function Model:hasValidMoves()
    for y = 0, self.height - 1 do
        for x = 0, self.width - 1 do
            for _, dir in pairs(Config.DIRECTIONS) do
                local nx, ny = x + dir.dx, y + dir.dy
                if self:_isValid(nx, ny) then
                    -- Пробный обмен
                    self.field[y][x], self.field[ny][nx] = 
                        self.field[ny][nx], self.field[y][x]
                    local matches = self:_findMatches()
                    -- Откат
                    self.field[y][x], self.field[ny][nx] = 
                        self.field[ny][nx], self.field[y][x]
                    if #matches > 0 then
                        return true
                    end
                end
            end
        end
    end
    return false
end

return Model