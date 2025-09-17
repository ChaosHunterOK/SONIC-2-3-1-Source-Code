local love = require("love")
local lg, la, lt, lw, lm = love.graphics, love.audio, love.timer, love.window, love.math
local floor, random, tonumber = math.floor, love.math.random, tonumber

local fast = {
    cache = {
        images = {},
        fonts = {},
        sounds = {},
        frames = {}
    },
    vsync = true,
    fpsCap = 0,
    _lastTime = lt.getTime(),
    _soundPool = {},
    _polyBuffer = {},
    _polyBufferSize = 0,
    maxSoundPool = 8,
    _gcTimer = 0
}

local images = fast.cache.images
function fast.getImage(path, filter)
    local img = images[path]
    if not img then
        img = lg.newImage(path)
        local f = filter or "nearest"
        img:setFilter(f, f)
        images[path] = img
    end
    return img
end

local fonts = fast.cache.fonts
function fast.getFont(path, size)
    local key = path .. ":" .. size
    local f = fonts[key]
    if not f then
        f = lg.newFont(path, size)
        fonts[key] = f
    end
    return f
end

local sounds = fast.cache.sounds
function fast.getSound(path, type)
    type = type or "static"
    local pool = fast._soundPool[path]
    if not pool then
        local s = sounds[path] or la.newSource(path, type)
        sounds[path] = s
        pool = {s}
        fast._soundPool[path] = pool
        return s
    end
    for i=1,#pool do
        if not pool[i]:isPlaying() then
            return pool[i]
        end
    end
    if #pool < fast.maxSoundPool then
        local newS = sounds[path]:clone()
        pool[#pool+1] = newS
        return newS
    else
        return pool[1]
    end
end

function fast.getFrames(basePath, count)
    if fast.cache.frames[basePath] then
        return fast.cache.frames[basePath]
    end
    local frames = {}
    if count then
        for i=1, count do
            frames[i] = fast.getImage(basePath .. i .. ".png")
        end
    else
        local files = love.filesystem.getDirectoryItems(basePath)
        table.sort(files)
        for _, file in ipairs(files) do
            if file:sub(-4):lower() == ".png" then
                frames[#frames+1] = fast.getImage(basePath .. file)
            end
        end
    end
    fast.cache.frames[basePath] = frames
    return frames
end

function fast.clearCache()
    for k,v in pairs(fast.cache.images) do
        if v and v:typeOf("Texture") then v:release() end
        fast.cache.images[k] = nil
    end
    for k,v in pairs(fast.cache.fonts) do
        fast.cache.fonts[k] = nil
    end
    for k,v in pairs(fast.cache.sounds) do
        if v and v:typeOf("Source") then v:stop() end
        fast.cache.sounds[k] = nil
    end
    fast.cache.frames = {}
    fast._soundPool = {}
    collectgarbage("collect")
end

function fast.reduceMemory(dt)
    fast._gcTimer = fast._gcTimer + (dt or 0)
    if fast._gcTimer >= 10 then
        fast._gcTimer = 0
        for path, pool in pairs(fast._soundPool) do
            local alive = {}
            for _, s in ipairs(pool) do
                if s and (s:isPlaying() or #alive < fast.maxSoundPool) then
                    table.insert(alive, s)
                end
            end
            fast._soundPool[path] = alive
        end
        collectgarbage("collect")
    end
end

function fast.limitFPS()
    if fast.fpsCap > 0 then
        local target = 1 / fast.fpsCap
        local now = lt.getTime()
        local sleepFor = target - (now - fast._lastTime)
        if sleepFor > 0 then lt.sleep(sleepFor) end
        fast._lastTime = lt.getTime()
    else
        fast._lastTime = lt.getTime()
    end
end

return fast
