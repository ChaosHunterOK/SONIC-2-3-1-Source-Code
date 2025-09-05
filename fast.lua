local love = require("love")
local lg, la, lt, lw, lm = love.graphics, love.audio, love.timer, love.window, love.math
local floor, random, tonumber = math.floor, love.math.random, tonumber

local fast = {
    cache = {
        images = {},
        fonts = {},
        sounds = {}
    },
    vsync = true,
    fpsCap = 0,
    _lastTime = lt.getTime(),
    _soundPool = {}
}

local images = fast.cache.images
function fast.getImage(path, filter)
    local img = images[path]
    if not img then
        img = lg.newImage(path)
        local f = filter or "nearest"
        img:setFilter(f,f)
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
        local s = sounds[path]
        if not s then
            s = la.newSource(path, type)
            sounds[path] = s
        end
        pool = {s}
        fast._soundPool[path] = pool
        return s
    end
    for i=1,#pool do
        if pool[i]:isStopped() then
            return pool[i]
        end
    end
    local newS = sounds[path]:clone()
    pool[#pool+1] = newS
    return newS
end

function fast.randomColor(a)
    local r,g,b = random(), random(), random()
    return r,g,b,a or 1
end

function fast.hexColor(hex, a)
    hex = hex:gsub("#","")
    local r = tonumber(hex:sub(1,2),16)/255
    local g = tonumber(hex:sub(3,4),16)/255
    local b = tonumber(hex:sub(5,6),16)/255
    return r,g,b,a or 1
end

--fast.draw is kinda useless, might get updated soon, will get to that later
function fast.draw(obj, x, y, r, sx, sy, ox, oy, kx, ky)
    lg.draw(obj, x or 0, y or 0, r or 0, sx or 1, sy or sx or 1, ox or 0, oy or 0, kx or 0, ky or 0)
end

function fast.limitFPS()
    if fast.fpsCap > 0 then
        local target = 1 / fast.fpsCap
        local now = lt.getTime()
        local sleepFor = target - (now - fast._lastTime)
        if sleepFor > 0 then lt.sleep(sleepFor) end
        fast._lastTime = now
    end
end

function fast.setVsync(on)
    fast.vsync = on and 1 or 0
    local w,h,flags = lw.getMode()
    lw.setMode(w,h,{vsync = fast.vsync})
end

function fast.newBatch(image, max)
    return lg.newSpriteBatch(image, max or 2000)
end

return fast