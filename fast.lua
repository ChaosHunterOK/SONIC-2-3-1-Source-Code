local love = require("love")
local lg, la, lt, lw, lm = love.graphics, love.audio, love.timer, love.window, love.math

local fast = {
    cache = {
        images = {},
        fonts = {},
        sounds = {}
    },
    vsync  = true,
    fpsCap = 0,
    _lastTime = lt.getTime()
}

function fast.getImage(path, filter)
    local img = fast.cache.images[path]
    if not img then
        img = lg.newImage(path)
        img:setFilter(filter or "nearest", filter or "nearest")
        fast.cache.images[path] = img
    end
    return img
end

function fast.getFont(path, size)
    local key = path .. ":" .. tostring(size)
    local f = fast.cache.fonts[key]
    if not f then
        f = lg.newFont(path, size)
        fast.cache.fonts[key] = f
    end
    return f
end

function fast.getSound(path, type)
    type = type or "static" -- "static" or "stream"
    local s = fast.cache.sounds[path]
    if not s then
        s = la.newSource(path, type)
        fast.cache.sounds[path] = s
    end
    return s:clone()
end

function fast.randomColor(a)
    return lm.random(), lm.random(), lm.random(), a or 1
end

function fast.hexColor(hex, a)
    hex = hex:gsub("#","")
    return tonumber(hex:sub(1,2), 16) / 255,
           tonumber(hex:sub(3,4), 16) / 255,
           tonumber(hex:sub(5,6), 16) / 255,
           a or 1
end

function fast.limitFPS()
    if fast.fpsCap > 0 then
        local target = 1 / fast.fpsCap
        local now = lt.getTime()
        local sleepFor = target - (now - fast._lastTime)
        if sleepFor > 0 then lt.sleep(sleepFor) end
        fast._lastTime = lt.getTime()
    end
end

function fast.setVsync(on)
    fast.vsync = on and 1 or 0
    local w, h, flags = lw.getMode()
    lw.setMode(w, h, {vsync = fast.vsync})
end

function fast.newBatch(image, max)
    return lg.newSpriteBatch(image, max or 2000)
end

return fast