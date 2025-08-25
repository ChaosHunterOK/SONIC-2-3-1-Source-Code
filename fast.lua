local love = require("love")
local lg = love.graphics
local fast = {
    cache = {
        images = {},
        fonts = {},
        sounds = {}
    },
    vsync = true,
    fpsCap = 0
}

function fast.getImage(path)
    if not fast.cache.images[path] then
        fast.cache.images[path] = lg.newImage(path)
        fast.cache.images[path]:setFilter("nearest", "nearest")
    end
    return fast.cache.images[path]
end

function fast.getFont(path, size)
    local key = path .. tostring(size)
    if not fast.cache.fonts[key] then
        fast.cache.fonts[key] = lg.newFont(path, size)
    end
    return fast.cache.fonts[key]
end

function fast.getSound(path, type)
    type = type or "static" -- "static" or "stream"
    if not fast.cache.sounds[path] then
        fast.cache.sounds[path] = love.audio.newSource(path, type)
    end
    return fast.cache.sounds[path]:clone()
end

function fast.randomColor()
    return love.math.random(), love.math.random(), love.math.random(), 1
end

function fast.hexColor(hex)
    hex = hex:gsub("#","")
    return tonumber("0x"..hex:sub(1,2))/255,
           tonumber("0x"..hex:sub(3,4))/255,
           tonumber("0x"..hex:sub(5,6))/255,
           1
end

local lastTime = 0
function fast.sleep(dt)
    if fast.fpsCap > 0 then
        local target = 1 / fast.fpsCap
        local sleepTime = target - (love.timer.getTime() - lastTime)
        if sleepTime > 0 then love.timer.sleep(sleepTime) end
        lastTime = love.timer.getTime()
    end
end

function fast.setVsync(on)
    fast.vsync = on and 1 or 0
    love.window.setMode(0, 0, {vsync = fast.vsync})
end

local lastTime = love.timer.getTime()

function fast.limitFPS()
    if fast.fpsCap > 0 then
        local target = 1 / fast.fpsCap
        local now = love.timer.getTime()
        local sleepTime = target - (now - lastTime)
        if sleepTime > 0 then
            love.timer.sleep(sleepTime)
        end
        lastTime = love.timer.getTime()
    end
end

function fast.newBatch(image, max)
    lg.newSpriteBatch(image, max or 2000)
end

return fast