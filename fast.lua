local love = require("love")
local lg, la, lt, lw, lm = love.graphics, love.audio, love.timer, love.window, love.math
local floor, random, tonumber = math.floor, love.math.random, tonumber

local fast = {
    cache = {
        images = {},
        fonts  = {},
        sounds = {},
        frames = {}
    },
    vsync = true,
    fpsCap = 0,
    _lastTime = lt.getTime(),
    _soundPool = {},
    maxSoundPool = 8,
    _gcTimer = 0
}

local images, fonts, sounds, frames = fast.cache.images, fast.cache.fonts, fast.cache.sounds, fast.cache.frames

function fast.getImage(path, filter)
    local img = images[path]
    if not img then
        img = lg.newImage(path)
        filter = filter or "nearest"
        img:setFilter(filter, filter)
        images[path] = img
    end
    return img
end

function fast.getFont(path, size)
    local key = path .. ":" .. size
    local f = fonts[key]
    if not f then
        f = lg.newFont(path, size)
        fonts[key] = f
    end
    return f
end

function fast.getSound(path, stype)
    stype = stype or "static"
    local pool = fast._soundPool[path]

    if not pool then
        local s = sounds[path] or la.newSource(path, stype)
        sounds[path] = s
        pool = {s}
        fast._soundPool[path] = pool
        return s
    end

    for i = 1, #pool do
        local src = pool[i]
        if not src:isPlaying() then
            return src
        end
    end

    if #pool < fast.maxSoundPool then
        local newS = sounds[path]:clone()
        pool[#pool + 1] = newS
        return newS
    end

    return pool[1]
end

local frames = {}
local MAX_CACHED_FRAMES = 50
local cacheOrder = {}

function fast.getFrames(basePath, count)
    local cached = frames[basePath]
    if cached then return cached end
    local fr = {}
    if count then
        for i = 1, count do
            fr[i] = fast.getImage(basePath .. i .. ".png")
        end
    else
        local files = love.filesystem.getDirectoryItems(basePath)
        table.sort(files)
        for _, file in ipairs(files) do
            if file:sub(-4):lower() == ".png" then
                fr[#fr + 1] = fast.getImage(basePath .. file)
            end
        end
    end
    frames[basePath] = fr
    table.insert(cacheOrder, basePath)
    while #cacheOrder > MAX_CACHED_FRAMES do
        local oldPath = table.remove(cacheOrder, 1)
        if frames[oldPath] then
            for i = 1, #frames[oldPath] do
                frames[oldPath][i] = nil
            end
            frames[oldPath] = nil
        end
    end

    return fr
end

function fast.reduceMemory(dt)
    fast._gcTimer = fast._gcTimer + (dt or 0)
    if fast._gcTimer >= 10 then
        fast._gcTimer = 0
        for path, pool in pairs(fast._soundPool) do
            local alive, n = {}, 0
            for i = 1, #pool do
                local s = pool[i]
                if s and s:isPlaying() then
                    n = n + 1
                    alive[n] = s
                end
            end
            if #alive > 0 then
                fast._soundPool[path] = alive
            else
                fast._soundPool[path] = nil
                sounds[path] = nil
            end
        end

        for k, v in pairs(images) do if not v then images[k] = nil end end
        for k, v in pairs(fonts) do if not v then fonts[k] = nil end end
        for k, v in pairs(frames) do if not v then frames[k] = nil end end

        collectgarbage("collect")
    end
end

function fast.limitFPS()
    local cap = fast.fpsCap
    if cap > 0 then
        local target = 1 / cap
        local now = lt.getTime()
        local sleepFor = target - (now - fast._lastTime)
        if sleepFor > 0 then lt.sleep(sleepFor) end
        fast._lastTime = lt.getTime()
    else
        fast._lastTime = lt.getTime()
    end
end

function fast.drawTextOutline(text, x, y, color, outlineColor, outlineSize)
    local setColor, print = lg.setColor, lg.print
    outlineSize = outlineSize or 1
    outlineColor = outlineColor or {0, 0, 0, 1}
    color = color or {1, 1, 1, 1}

    setColor(outlineColor)
    for dx = -outlineSize, outlineSize do
        for dy = -outlineSize, outlineSize do
            if dx ~= 0 or dy ~= 0 then
                print(text, x + dx, y + dy)
            end
        end
    end

    setColor(color)
    print(text, x, y)
end

function fast.clearAll()
    for k in pairs(images) do images[k] = nil end
    for k in pairs(fonts) do fonts[k] = nil end
    for k in pairs(sounds) do sounds[k] = nil end
    for k in pairs(frames) do frames[k] = nil end
    fast._soundPool = {}
    collectgarbage("collect")
end
return fast