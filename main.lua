local love = require("love")
local fast = require("fast")
fast.fpsCap = 64

local buttons = {"Copy", "Quit"}
local selected = 1
love.graphics.setDefaultFilter("nearest", "nearest")

Font = fast.getFont("font/font.ttf", 16)
FontBig = fast.getFont("font/font.ttf", 32)

local base_width, base_height = 500, 250
function love.errhand(msg)
    love.graphics.reset()
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    love.graphics.setFont(Font)

    local errorMessage = tostring(msg)
    local image = love.graphics.newImage("images/error.png")
    image:setFilter("nearest", "nearest")

    local xOffset = 550
    local btnY = screenH - 100
    local btnSpacing = 100

    while true do
        love.event.pump()
        for e, a in love.event.poll() do
            if e == "quit" then return end

            if e == "keypressed" then
                if a == "right" then
                    selected = (selected % #buttons) + 1
                elseif a == "left" then
                    selected = (selected - 2) % #buttons + 1
                elseif a == "return" or a == "kpenter" then
                    if buttons[selected] == "Copy" then
                        love.system.setClipboardText(errorMessage)
                    elseif buttons[selected] == "Quit" then
                        return
                    end
                end
            end
        end
        love.graphics.setColor(1,1,1)

        if image then
            local scaleX, scaleY = screenW / image:getWidth(), screenH / image:getHeight()
            love.graphics.draw(image, 0, 0, 0, scaleX, scaleY)
        end

        love.graphics.printf(errorMessage, xOffset, 100, screenW - xOffset - 50, "left")
        love.graphics.printf("DM copilucusarmale or saunter_thesequel on Discord to report this goofy error", xOffset, 30, screenW - xOffset - 50, "left")

        local btnX = xOffset
        for i, btn in ipairs(buttons) do
            love.graphics.setColor(i == selected and {1,0.5,0} or {1,1,1})
            love.graphics.print(btn, btnX, btnY)
            btnX = btnX + btnSpacing
        end

        love.graphics.present()
        love.timer.sleep(0.01)
    end
end

local ok, discord = pcall(require, "ffi/discord")
local startTime = os.time()

local spritesFolder = "images/sprites/"
local stats = {score = 0, rings = 0}
local gameTime = 0
local gamestate = "testmap"

local isMobile = false
local os_device = love.system.getOS()
if os_device == "Android" or os_device == "iOS" then
    isMobile = true
end

gravity = 625

local floor, abs, min, max, atan2, deg, sqrt, sin, cos = math.floor, math.abs, math.min, math.max, math.atan2, math.deg, math.sqrt, math.sin, math.cos
local thing = 650
local camera = {x = 0, y = 0, targetX = 0, targetY = 0, locked = false}
local camera_3d = {x = thing / 2, y = 5, z = thing / 2, yaw = 0, pitch = 0, roll = 0}
local chaser = {x = -200, y = 0, z = -200, speed = 23}

local moveSpeed, mouseSensitivity = 8, 0.002
local walkTime = 0

local canvas
scale_factor, offset_x, offset_y = 1, 0, 0
resizeFreezeTimer = 0

rebooting_Vis, rebootingTimer, lastPlayedCycle = false, 0, -1

local ringAnimState = true
local ringAnimTimer = 0
local ringAnimSpeed = 0.2
local characterOffsetX = 0

local charStatus = {
    tails_alive = true,
    knuckles_alive = true,
    eggman_alive = true,
    tails_lock = true,
    knuckles_lock = false,
    eggman_lock = false
}

idk_img = fast.getImage("images/idk.png")
bush_img = fast.getImage("images/bush.png")
egg_mob = fast.getImage("images/egg_mob.png")

jumpscare = fast.getImage("images/jump.png")
knuck_bg = fast.getImage("images/background/knuck.png")

local selectionImages = {
    selection_box = fast.getImage("images/selection/box.png"),
    tails_selection = fast.getImage("images/selection/tails_selection.png"),
    knuck_selection = fast.getImage("images/selection/knuckles_selection.png"),
    eggman_selection = fast.getImage("images/selection/eggman_selection.png"),

    dead_tails = fast.getImage("images/selection/dead_tails.png"),
    dead_knuckles = fast.getImage("images/selection/dead_knuckles.png"),
    dead_eggman = fast.getImage("images/selection/dead_eggman.png")
}

local mapImages = {}
local mapPaths = {
    test2 = "images/maps/test2.png",
    test3 = "images/maps/map1.png",
    knuck1 = "images/maps/knuck1.png",
    gh1 = "images/maps/gh1.png",
    testmap = "images/maps/testmap.png"
}
function loadMapImage(name)
    if mapImages[name] then return mapImages[name] end

    local path = mapPaths[name]
    if not love.filesystem.getInfo(path) then return nil end
    local imgData = love.image.newImageData(path)
    local w, h = imgData:getWidth(), imgData:getHeight()
    local hasPixels = false

    for y = 0, h - 1 do
        for x = 0, w - 1 do
            local _, _, _, a = imgData:getPixel(x, y)
            if a > 0.01 then
                hasPixels = true
                break
            end
        end
        if hasPixels then break end
    end

    if hasPixels then
        mapImages[name] = love.graphics.newImage(imgData)
    end

    imgData:release()
    return mapImages[name]
end

lockImg = fast.getImage("images/lock.png")

local soundDefs = {
    sonic_theme = "music/sonic_theme.ogg",
    intro_1990 = "music/intro_1990.mp3",
    green_hill = "music/Green_Hill.ogg",
    rebootSound = "sounds/reboot.ogg",
    flames = "sounds/flames.ogg",
    buildUPSound = "sounds/buildUP.ogg",
    denySound = "sounds/deny.ogg",
    egg = "music/egg.mp3",
    enterSound = "sounds/enter.ogg",
    cr4sh_sound = "sounds/cr4sh_sound.mp3",
    sound_fix = "sounds/sound_fix.mp3",
    reboot_old = "sounds/reboot_old.mp3",
    bossMusic = "music/Demo_fight.mp3",
    hitStatic = "sounds/hitStatic.ogg",
    placeholder = "music/exeexe.exe thing.mp3",
    jump_sound = "sounds/jump_sound.mp3",
    laugh_sound = "sounds/laugh.mp3",
    S3K_9A = "sounds/S3K_9A.wav",
    lights_off = "sounds/lights-sound-effect.mp3",
    error_sound = "sounds/error_sound.mp3",
    sound = "sounds/sound.mp3",
    sonic_error_sound = "sounds/sonic_error_sound.mp3"
}

local sounds = {}

for name, path in pairs(soundDefs) do
    sounds[name] = fast.getSound(path, path:find("music") and "stream")
end

local images = {}
local quads = {}
selectionState = "tails"
selectionIndex = 1
selectionOptions = {"tails", "knuckles", "eggman"}
local mapFolders = {
    map = {width = 11264, height = 1024},
    map1 = {width = 11392, height = 1280},
    map2 = {width = 6501, height = 1233},
    map3 = {width = 4052, height = 1009},
    testmap2 = {width = 1952, height = 696}
}

local maps = {}
local currentMapName = nil

function unloadMap(name)
    local map = maps[name]
    if map then
        if map.tiles then
            for _, tile in ipairs(map.tiles) do
                tile.image:release()
                tile.image = nil
            end
        end
        map.collision = nil
        maps[name] = nil
        collectgarbage("collect")
    end
end

function getMap(name)
    if currentMapName and currentMapName ~= name then
        --unloadMap(currentMapName)
    end
    currentMapName = name

    local map = maps[name]
    if not map then
        map = loadMap(name)
        maps[name] = map
    end
    return map
end

function loadMap(name)
    local folderInfo = mapFolders[name]
    if not folderInfo then
        error("No folder info for map: " .. tostring(name))
    end

    local tiles = {}
    local w, h = folderInfo.width, folderInfo.height
    local collision = {}
    local xPos, yPos = 0, 0
    local rowHeight = 0
    local i = 1

    while true do
        local path = string.format("images/maps/%s/tile%d.png", name, i)
        if not love.filesystem.getInfo(path) then break end
        local imgData = love.image.newImageData(path)
        local tw, th = imgData:getWidth(), imgData:getHeight()

        local hasPixels = false
        for ty = 0, th - 1 do
            for tx = 0, tw - 1 do
                local _, _, _, a = imgData:getPixel(tx, ty)
                if a > 0.01 then
                    hasPixels = true
                    local mapX = xPos + tx
                    local mapY = yPos + ty
                    collision[mapY * w + mapX + 1] = true
                end
            end
        end

        imgData:release()

        if hasPixels then
            table.insert(tiles, {path = path, x = xPos, y = yPos, w = tw, h = th, image = nil})
        end

        xPos = xPos + tw
        if th > rowHeight then rowHeight = th end
        if xPos >= w then
            xPos = 0
            yPos = yPos + rowHeight
            rowHeight = 0
        end
        i = i + 1
    end

    return {
        tiles = tiles,
        collision = collision,
        width = w,
        height = h
    }
end

local function createCharacter(opts)
    opts = opts or {}
    return {
        x = opts.x or 0,
        y = opts.y or 0,
        width = 32,
        height = 32,
        speed = 35,
        velocity = { x = 0, y = 0 },
        grounded = opts.grounded or false,
        jumping = opts.jumping or false,
        direction = 1,
        jumpHeight = -375,
        acceleration = 135,
        maxSpeed = opts.maxSpeed or 175,
        friction = 2,
        onGroundY = 0,
        fallTimer = 0,
        isPresent = true,
        angle = 0,
        visible = true,
        runThreshold = opts.runThreshold or 175,
        spriteIndex = 1,
        currentSprite = nil,
        fakeAngle = 0,
        jumpHeldTime = 0,
        _coyote = 0,
        _jumpBuf = 0,
        _stuck_timer = 0,
        canJump = true,
        hasJumpedOnCatch = false,
        physics_enabled = opts.physics_enabled or false
    }
end

local showDebug = false

local function loadFrames(basePath, count)
    return fast.getFrames(basePath, count)
end

local chunkSize, renderDistance = 4, 22

flashAlpha, flashDuration, flashTimer = 0, 0.5, 0
local isFlashing = false

function flashScreen(duration)
    flashAlpha, flashTimer = 1, duration or 0.5
    flashDuration, isFlashing = flashTimer, true
end

transitionAlpha, transitioning, transitionTarget, transitionSpeed = 1, false, "", 1.5
colorPhaseTime, colorTimer, colorLerp = 0.25, 0, 0
function startTransition(target)
    transitioning = true
    transitionTarget = target
    colorTimer = 0
    colorLerp = 0
end

function initSprite(character, spriteFrames)
    character.spriteIndex = 1
    if type(spriteFrames) == "table" then
        character.currentSprite = spriteFrames[1]
    else
        character.currentSprite = spriteFrames
    end
    return character
end

function loadCharacterSprites(folder, def)
    local c = createCharacter(def)
    for name, data in pairs(def.sprites) do
        local path = folder .. name
        if data.count then
            c[name] = fast.getFrames(path .. "/", data.count)
        else
            c[name] = fast.getImage(path .. ".png")
        end
    end
    return initSprite(c, c.idle or c.walk or c.run)
end

menuShrink = 1
local menuAlpha = 1
local shrinkingMenu = false
local selectionScale = 3
local selectionAlpha = 0

local frames = loadFrames(spritesFolder .. "menuscreen/", 6)
local repeatable_frames = loadFrames(spritesFolder .. "menuscreen/repeatble/", 2)
local repeatable2_frames = loadFrames(spritesFolder .. "menuscreen/lookin/", 25)

local splash_frames = {}
splash_frames.splash = loadFrames(spritesFolder .. "menuscreen/lookin/", 25)
splash_frames.idle = loadFrames(spritesFolder .. "menuscreen/play/", 6)

local fire_bg = createCharacter{}
fire_bg.idle = loadFrames("images/background/fire/", 3)

title = fast.getImage(spritesFolder .. "menuscreen/title.png")
circle = fast.getImage(spritesFolder .. "menuscreen/circle.png")
smth = fast.getImage("images/segamenu.png")

local colorTL = {0x42/255, 0x5B/255, 0x1D/255, 1}
local colorTR = {0xA2/255, 0xA0/255, 0x20/255, 1}

local targetYaw, targetPitch = 0, 0

local function createBaseplate(width, depth)
    local tiles = {}
    local idx = 1

    for z = 0, depth - 1 do
        for x = 0, width - 1 do
            local col = ((x + z) % 2 == 0) and colorTL or colorTR
            tiles[idx] = {
                {x, 0, z, col},
                {x + 1, 0, z, col},
                {x + 1, 0, z + 1, col},
                {x, 0, z + 1, col}
            }
            idx = idx + 1
        end
    end

    return tiles
end
local SCALE = 2
local touches = {}

local joystick = {
    x = 45, y = base_height - 45,
    radius = 25,
    active = false,
    dx = 0,
    dy = 0
}

local jumpButton = {
    x = base_width - 45, y = base_height - 45,
    radius = 60,
    active = false
}

uiAssets = {
    joystickBase = fast.getImage("images/mobile_stuff/base.png"),
    joystickKnob = fast.getImage("images/mobile_stuff/knob.png"),
    jumpButton = fast.getImage("images/mobile_stuff/jump.png"),
    warrow = fast.getImage("images/arrows/w.png"),
}

local tails = loadCharacterSprites(spritesFolder .. "tails/", {
    x = 100, y = 50, maxSpeed = 200,
    sprites = {
        idle = {}, down = {}, fall = {}, up = {},
        walk = {count = 8}, jump = {count = 3},
        run = {count = 2}, damage = {count = 2}
    }
})

local knuckles = loadCharacterSprites(spritesFolder .. "knuckles/", {
    x = 100, y = 50, maxSpeed = 200,
    sprites = {
        idle = {}, walk = {count = 7}, run = {count = 4}, jump = {count = 5}
    }
})

local eggman = loadCharacterSprites(spritesFolder .. "eggman/", {
    x = 3300, y = 50, maxSpeed = 140,
    sprites = {
        idle = {}, down = {}, walk = {count = 3}, run = {count = 3},
        jump = {count = 1}, crashed = {}
    }
})

local sonic_demoexe = loadCharacterSprites(spritesFolder .. "sonic_demo.exe/", {
    x = -100, y = -140,
    sprites = {
        idle = {}, crouch = {},
        anim_tails = {count = 8}, float = {count = 2},
        jump = {count = 5}, run = {count = 4}, walk = {count = 6},
        fly = {count = 2}, fall = {count = 2}, kill_tails = {count = 7},
        fly_anim = {count = 3}, cr4sh = {}
    }
})

test_character = loadCharacterSprites(spritesFolder .. "sonic_demo.exe/", {
    x = 50, y = 50,
    sprites = {
        idle = {}, crouch = {},
        anim_tails = {count = 8}, float = {count = 2},
        jump = {count = 5}, run = {count = 4}, walk = {count = 6},
        fly = {count = 2}, fall = {count = 2}, kill_tails = {count = 7},
        fly_anim = {count = 3}, cr4sh = {}
    }
})

local sonic_demoexe_screen = loadCharacterSprites(spritesFolder .. "screen/", {
    x = 0, y = 0,
    sprites = {
        grab = {count = 5}, idle = {}
    }
})

s1 = loadCharacterSprites(spritesFolder .. "sonic_demo.exe/anim/knuckles/", {
    x = 100, y = 50,
    sprites = {
        idle = {}, stage2 = {count = 2}, stage3 = {},
    }
})
stage1_vis = true
stage2_vis = true
stage3_vis = true

local tail_tails = {}
tail_tails.image = fast.getImage(spritesFolder .. "tail/1.png")
tail_tails.idle = loadFrames(spritesFolder .. "tail/", 5)

local fire_bg = initSprite(fire_bg, fire_bg.idle)
local tail_tails = initSprite(tail_tails, tail_tails.idle)
local s1 = initSprite(s1, s1.stage2)

local demo_3d = {
    chase_img = fast.getImage(spritesFolder.."demo/chase.png"),
    silly_img = fast.getImage(spritesFolder.."demo/silly.png"),
    side_imgs = loadFrames(spritesFolder.."demo/side/", 8),
    state = "chasing",
    stop_timer = 0,
    current_side = 1,
    has_stopped_once = false
}

local stopDistance = 10

local credits = {}
scrollY = 0
scrollSpeed = 200

function love.load()
    love.window.setMode(base_width * SCALE, base_height * SCALE, {
        fullscreen = false,
        resizable = true,
        vsync = true,
        highdpi = true,
    })
    fast.fpsCap = 64
    love.window.setTitle("SONIC 2 3 1")
    love.window.setIcon(love.image.newImageData("images/game_icon.png"))
    if canvas then canvas:release() end
    canvas = love.graphics.newCanvas(base_width, base_height)
    updateCanvasScale()

    if ok and discord then
        local success, err = pcall(function()
            discord.initialize("1408498323890896917")
            discord.updatePresence {
                details = "Hello there.",
                state = "",
                startTimestamp = startTime,
                largeImageKey = "game_logo",
                largeImageText = "SONIC 2 3 1",
                smallImageKey = "small_icon",
                smallImageText = "1.0"
            }
        end)

        if not success then
            print("Discord presence failed: " .. tostring(err))
        end
    else
        print("no discord RPC")
    end
    credits = {
        {name = "CopiluCuSarmale", role = "Director, Pixel Artist, Artist, Animator, Coder, Document, Composer", img = "copilucusarmale.png"},
        {name = "Replayer", role = "Game Tester, Document, Sonic_DEMO.exe's laugh", img = "replayer.png"},
        {name = "Leon", role = "Document", img = "leon.png"},
        {name = "Saunter", role = "Coder, Composer", img = "saunter.png"},
        {name = "Trigavid", role = "Composer", img = "trigavid.png"},
        {name = "Irealism01", role = "Game tester (for mobile)", img = "irealism01.png"},
        {name = "Riadlyn", role = "Composer, Pixel Artist", img = "riadlyn.png"},
        {name = "SEGA", role = "Sonic, Tails, Knuckles, Eggman and mostly the rest", img = "sega.png"},
        {name = "RealDev", role = "the Sonic 1 Title Screen Font (Expanded)", img = "RealDev.png"}
    }

    for i, c in ipairs(credits) do
        local path = "images/credits/" .. c.img
        if love.filesystem.getInfo(path) then
            c.image = fast.getImage(path)
        else
            c.image = fast.getImage("images/credits/unknown.png")
        end
    end

    images.score = fast.getImage("images/stats/score.png")
    images.time = fast.getImage("images/stats/time.png")
    images.rings = fast.getImage("images/stats/rings.png")
    images.numbers = fast.getImage("images/stats/numbers.png")
    images.william = fast.getImage("images/stats/live.png")

    quads.numbers = {}
    local w, h = images.numbers:getDimensions()
    for i = 0, 10 do
        quads.numbers[i] = love.graphics.newQuad(i * 7, 0, 7, 11, w, h)
    end

    local rw, rh = images.rings:getDimensions()
    quads.rings = {
        top = love.graphics.newQuad(0, 0, 40, 16, rw, rh),
        bottom = love.graphics.newQuad(0, 16, 40, 16, rw, rh),
    }

    startTime = love.timer.getTime()
    baseplateTiles = createBaseplate(thing, thing)
    credits_y = base_height
end

function clamp(val, minVal, maxVal) return max(minVal, min(maxVal, val)) end
function lerp(a, b, t) return a + (b - a) * t end

local velX, velZ = 0, 0
local bobAmount = 0
local targetRoll = 0
local rollStrength = 0.02
local rollReturnSpeed = 5

function getRelativeAngle(player, chaser)
    local dx, dz = player.x - chaser.x, player.z - chaser.z
    local angleToPlayer = atan2(dz, dx)
    local diff = angleToPlayer - player.yaw
    while diff < -math.pi do diff = diff + 2*math.pi end
    while diff >  math.pi do diff = diff - 2*math.pi end
    return deg(diff)
end

hasPlayedFlashSound = false
function william_update(dt)
    sounds.egg:stop()
    local smoothSpeed = 8
    camera_3d.yaw = camera_3d.yaw + (targetYaw - camera_3d.yaw) * min(dt * smoothSpeed, 1)
    camera_3d.pitch = camera_3d.pitch + (targetPitch - camera_3d.pitch) * min(dt * smoothSpeed, 1)
    camera_3d.roll = camera_3d.roll + (targetRoll - camera_3d.roll) * min(dt * rollReturnSpeed, 1)
    targetRoll = targetRoll + (0 - targetRoll) * min(dt * rollReturnSpeed, 1)
    local inputX, inputZ = 0, 0
    if love.keyboard.isDown("w") then inputZ = 1 end
    if love.keyboard.isDown("s") then inputZ = inputZ - 1 end
    if love.keyboard.isDown("a") then inputX = -1 end
    if love.keyboard.isDown("d") then inputX = inputX + 1 end
    inputX = inputX + (joystick.active and joystick.dx or 0)
    inputZ = inputZ + (joystick.active and -joystick.dy or 0)
    local lenSq = inputX*inputX + inputZ*inputZ
    if lenSq > 0 then
        local invLen = 1 / sqrt(lenSq)
        inputX, inputZ = inputX * invLen, inputZ * invLen
    end

    local accel = min(dt * 12, 1)
    velX = velX + (inputX * moveSpeed - velX) * accel
    velZ = velZ + (inputZ * moveSpeed - velZ) * accel

    if abs(velX) > 0.01 or abs(velZ) > 0.01 then
        walkTime = walkTime + dt * 10
        bobAmount = bobAmount + ((sin(walkTime) * 0.1) - bobAmount) * dt * 8
    else
        bobAmount = bobAmount - bobAmount * dt * 8
    end
    camera_3d.y = 5 + bobAmount

    local sy, cy = sin(camera_3d.yaw), cos(camera_3d.yaw)
    camera_3d.x = camera_3d.x + (velX * cy - velZ * sy) * dt
    camera_3d.z = camera_3d.z + (velX * sy + velZ * cy) * dt

    local dx, dy, dz = camera_3d.x - chaser.x, camera_3d.y - chaser.y, camera_3d.z - chaser.z
    local distSq = dx*dx + dy*dy + dz*dz
    local dist = sqrt(distSq)

    if demo_3d.state == "chasing" then
        if dist < stopDistance and not demo_3d.has_stopped_once then
            demo_3d.state = "stopped"
            demo_3d.stop_timer = 0
            demo_3d.current_side = 1
            demo_3d.has_stopped_once = true
        else
            local speedFactor = 1 + max(0, (20 - dist) / 20) * 2
            local lerpAmt = dt * 4
            local targetVx = dx / dist * chaser.speed * speedFactor
            local targetVy = dy / dist * chaser.speed * speedFactor
            local targetVz = dz / dist * chaser.speed * speedFactor
            local function lerpVec(current, target, amt)
                return (current or 0) + (target - (current or 0)) * amt
            end
            chaser.vx = lerpVec(chaser.vx, targetVx, lerpAmt)
            chaser.vy = lerpVec(chaser.vy, targetVy, lerpAmt)
            chaser.vz = lerpVec(chaser.vz, targetVz, lerpAmt)

            chaser.x = chaser.x + chaser.vx * dt
            chaser.y = chaser.y + chaser.vy * dt
            chaser.z = chaser.z + chaser.vz * dt
        end

    elseif demo_3d.state == "stopped" then
        demo_3d.stop_timer = demo_3d.stop_timer + dt

        if not hasPlayedFlashSound then
            sounds.sound_fix:play()
            hasPlayedFlashSound = true
        end

        if abs(velX) > 0.01 or abs(velZ) > 0.01 then
            local angle = getRelativeAngleFromMovement(camera_3d, chaser)
            local index = floor(((angle + 180) / 45) + 0.5) % 8 + 1
            demo_3d.current_side = index
        end
        if demo_3d.stop_timer >= 12 then
            demo_3d.state = "chasing"
        end
    end

    if distSq < 1 then
        gamestate = "game_over"
    end

    preloadTiles()
end

function getRelativeAngleFromMovement(player, chaser)
    local dx, dz = player.x - chaser.x, player.z - chaser.z
    local angleToPlayer = atan2(dz, dx)
    return deg(angleToPlayer)
end

local function inRenderDistance(tile)
    local dx, dz = tile[1][1]-camera_3d.x, tile[1][3]-camera_3d.z
    local maxDist = renderDistance
    return dx*dx + dz*dz <= maxDist*maxDist
end

function love.mousemoved(x, y, dx, dy)
    if gamestate == "william" then
        targetYaw = targetYaw - dx * mouseSensitivity
        targetPitch = max(-math.pi/2, min(math.pi/2, targetPitch + dy * mouseSensitivity))
        targetRoll = max(-0.15, min(0.15, -dx * rollStrength))
    end
end

local function easeInOutCubic(t)
    return t < 0.5 and 4 * t * t * t or 1 - math.pow(-2 * t + 2, 3) / 2
end

local function easeOutCubic(t)
    return 1 - (1 - t)^3
end

local function updateSprite(dt, spriteTable, char, speed)
    if not char.spriteIndex then
        char.spriteIndex = 1
    end

    char.spriteIndex = char.spriteIndex + dt * (speed or 10)
    if char.spriteIndex >= #spriteTable + 1 then
        char.spriteIndex = 1
    end
    char.currentSprite = nil
    char.currentSprite = spriteTable[floor(char.spriteIndex)] or spriteTable[1]
end

local sonic_demoexe_triggered = false
local sonic_demoexe_animating = false
local sonic_demoexe_wait_timer = 0

local currentColor = {1, 1, 1}
local lerpSpeed = 5

menu3 = fast.getImage("images/background/menu3.png")

local MenuImagesDamn = {}
MenuImagesDamn[1] = fast.getImage("images/background/screen/1.png")
MenuImagesDamn[2] = fast.getImage("images/background/screen/2.png")
MenuImagesDamn[3] = fast.getImage("images/background/screen/3.png")
MenuImagesDamn[4] = fast.getImage("images/background/screen/4.png")

function before_idk(dt)
    local tX = tails.x
    local anim = sonic_demoexe.anim_tails
    local n = #anim
    if tX < 10695 then
        sonic_demoexe.currentSprite = anim[1]
    end
    if not sonic_demoexe_triggered and tX >= 10695 then
        sonic_demoexe_triggered = true
        sonic_demoexe_animating = true
        sonic_demoexe.spriteIndex = 1
        sonic_demoexe.currentSprite = anim[1]
    end
    if sonic_demoexe_animating then
        local index = sonic_demoexe.spriteIndex + dt * 10
        if index >= n then
            index = n
            sonic_demoexe_animating = false
            sonic_demoexe_wait_timer = 0.1
        end
        sonic_demoexe.spriteIndex = index
        sonic_demoexe.currentSprite = anim[floor(index)]
    end

    if sonic_demoexe_wait_timer > 0 then
        sonic_demoexe_wait_timer = sonic_demoexe_wait_timer - dt
        if sonic_demoexe_wait_timer <= 0 then
            gamestate = "torture"
        end
    end

    local pitch, target
    if tX >= 10000 then
        target = {0.1, 0.1, 0.1}
        pitch = nil
        sounds.green_hill:stop()
    elseif tX >= 8260 then
        target = {0.25, 0.25, 0.25}
        pitch = 0.5
    elseif tX >= 4800 then
        target = {0.5, 0.5, 0.5}
        pitch = 0.75
    else
        target = {1, 1, 1}
        pitch = 1
    end
    if pitch then
        sounds.green_hill:setPitch(pitch)
    end

    for i=1,3 do
        currentColor[i] = lerp(currentColor[i], target[i], lerpSpeed * dt)
    end
end

tort_visible = false
tort_time = 0
local soundPlayed = false
local soundPlayed2 = false

function torture(dt)
    tort_time = tort_time + dt

    if tort_time >= 2 and not soundPlayed then
        sounds.enterSound:play()
        soundPlayed = true
    end

    if tort_time >= 2 then
        tort_visible = true
    end

    if tort_time >= 7 then
        gamestate = "hs"
    end
end

cheat_time = 0
cheating_vis = false
cheating_vis2 = false
cheating_alpha = 0
cheating_alpha2 = 0.7
function cheating(dt)
    sounds.egg:stop()
    local screen = sonic_demoexe_screen
    sounds.cr4sh_sound:stop()
    cheat_time = cheat_time + dt

    if cheat_time >= 25 then
        gamestate = "william"
    elseif cheat_time >= 20 then
        cheating_vis2, cheating_vis = false, true
        local grab = screen.grab
        updateSprite(dt * 1.35, grab, screen)
        if screen.spriteIndex > #grab then
            screen.spriteIndex = 5
        end
    elseif cheat_time >= 13 then
        if cheating_alpha2 > 0 then
            cheating_alpha2 = max(0, cheating_alpha2 - 0.1 * dt)
        end
    elseif cheat_time >= 12 and not soundPlayed2 then
        cheating_vis, cheating_vis2 = false, true
        sounds.enterSound:play()
        soundPlayed2 = true
    elseif cheat_time >= 5 and cheating_alpha < 0.36 then
        cheating_alpha = min(0.36, cheating_alpha + 0.1 * dt)
        cheating_vis = true
        screen.currentSprite = screen.idle
    end
end

local crashing = false
local crashing2 = false
local crashTimer = 0
local crashAlpha = 0
local crashMaxAlpha = 0.5
local fadeDuration = 0.25

local JOYSTICK_MOVE_THRESHOLD = 0.25
local JOYSTICK_LOOK_THRESHOLD = 0.35

local activeGamepad = nil
function love.joystickadded(j)
    activeGamepad = j
end
function love.joystickremoved(j)
    if activeGamepad == j then activeGamepad = nil end
end

function getControls()
    local jdx = joystick.active and (joystick.dx or 0) or 0
    local jdy = joystick.active and (joystick.dy or 0) or 0
    local gdx, gdy = 0, 0
    local gjump, glookUp, glookDown = false, false, false

    if activeGamepad then
        gdx = activeGamepad:getAxis(1) or 0
        gdy = activeGamepad:getAxis(2) or 0
        gjump = activeGamepad:isDown(1) or activeGamepad:isDown(2)
        glookUp = gdy < -JOYSTICK_LOOK_THRESHOLD
        glookDown = gdy > JOYSTICK_LOOK_THRESHOLD
    end
    local moveRight = love.keyboard.isDown("right") or jdx > JOYSTICK_MOVE_THRESHOLD or gdx > JOYSTICK_MOVE_THRESHOLD
    local moveLeft = love.keyboard.isDown("left")  or jdx < -JOYSTICK_MOVE_THRESHOLD or gdx < -JOYSTICK_MOVE_THRESHOLD
    local jump = love.keyboard.isDown("space") or love.keyboard.isDown("a") or love.keyboard.isDown("z") or jumpButton.active or gjump

    local lookUp = (love.keyboard.isDown("up") or jdy < -JOYSTICK_LOOK_THRESHOLD or glookUp) and not jump and not moveRight and not moveLeft
    local lookDown = (love.keyboard.isDown("down") or jdy > JOYSTICK_LOOK_THRESHOLD or glookDown) and not jump and not moveRight and not moveLeft

    return moveRight, moveLeft, jump, lookUp, lookDown
end

TOP_SPEED, GROUND_ACCEL, GROUND_DECEL = 220, 780, 1500
GROUND_FRICTION, AIR_ACCEL, AIR_DECEL = 1300, 400, 360
JUMP_VELOCITY, JUMP_HOLD_TIME, COYOTE_TIME, JUMP_BUFFER = -310, 0.18, 0.10, 0.10
AIR_DRAG, MAX_STEP_HEIGHT = 0.99609375, 10

function approach(v, target, amt)
    if v < target then return math.min(v + amt, target)
    elseif v > target then return math.max(v - amt, target)
    end
    return v
end

function checkCollision(char, map, x, y)
    if type(map) == "string" then map = getMap(map) end
    if not map then return false end

    local w, h = map.width, map.height
    local coll = map.collision

    local halfW  = char.width * 0.5
    local halfH  = char.height * 0.5

    local left = floor(x - halfW)
    local right = floor(x + halfW - 1)
    local top = floor(y - halfH)
    local bottom = floor(y + halfH - 1)

    if left < 0 or right >= w or top < 0 then
        return true
    end
    if bottom >= h then
        return false
    end

    for ty = top, bottom do
        local row = ty * w
        for tx = left, right do
            if coll[row + tx + 1] then
                return true
            end
        end
    end

    return false
end

function getGroundY(char, map, baseX, baseY)
    if type(map) == "string" then map = getMap(map) end
    if not map or not map.collision then return nil end
    local startY = floor(baseY + char.height * 0.5)
    local endY = min(startY + MAX_STEP_HEIGHT, map.height - 1)

    for y = startY, endY do
        if checkCollision(char, map, baseX, y - char.height * 0.5) then
            return y - char.height * 0.5
        end
    end
    return nil
end

SNAP_SPEED = 300
function snapToGround(char, map, dt)
    if char.jumping then
        char.grounded = false
        return false
    end

    local groundY = getGroundY(char, map, char.x, char.y)
    if not groundY then
        char.grounded = false
        return false
    end

    local newY = approach(char.y, groundY, SNAP_SPEED * dt)
    char.y = newY

    local grounded = abs(newY - groundY) < 1
    char.grounded = grounded

    if grounded and char.velocity.y > 0 then
        char.velocity.y = 0
    end

    return grounded
end

function getGroundSlope(char, map, x, y)
    local step = 2
    local yL = getGroundY(char, map, x - step, y)
    local yR = getGroundY(char, map, x + step, y)
    if yL and yR then
        return atan2(yR - yL, (step * 2))
    end
    return 0
end

function applySlopePhysics(char, vx, vy, slopeAngle, dt)
    local sinA, cosA = sin(slopeAngle), cos(slopeAngle)
    local vxs = vx * cosA
    local vys = vx * sinA
    vy = vy + (gravity or 400) * dt
    return vxs, vy + vys
end

GROUND_FRICTION = 0.125
local CAM_HZ_BOUND, CAM_VT_BOUND = 16, 48
function updateCamera(dt, char, mapWidth, mapHeight)
    local targetX, targetY = camera.x, camera.y
    local screenCenterX = camera.x + base_width / 2
    local screenCenterY = camera.y + base_height / 2

    if char.x > screenCenterX + CAM_HZ_BOUND then targetX = targetX + (char.x - (screenCenterX + CAM_HZ_BOUND))
    elseif char.x < screenCenterX - CAM_HZ_BOUND then targetX = targetX - ((screenCenterX - CAM_HZ_BOUND) - char.x) end

    if char.y > screenCenterY + CAM_VT_BOUND then targetY = targetY + (char.y - (screenCenterY + CAM_VT_BOUND))
    elseif char.y < screenCenterY - CAM_VT_BOUND then targetY = targetY - ((screenCenterY - CAM_VT_BOUND) - char.y) end

    camera.x = floor(clamp(targetX, 0, mapWidth - base_width) + 0.5)
    camera.y = floor(clamp(targetY, 0, mapHeight - base_height) + 0.5)
end

local tails_caught = false
local tails_caught2 = false
function sign(x) return (x>0 and 1) or (x<0 and -1) or 0 end
bgOffsetX = 0
bgScrollSpeed = 0.15
function test_update(dt, char, map)
    local mapObj = getMap(map)
    if not mapObj then return end

    local mapWidth, mapHeight = mapObj.width or 2000, mapObj.height or 1080
    char.velocity = char.velocity or {x = 0, y = 0}
    char.jumping = char.jumping or false
    char.grounded = char.grounded or false
    char._coyote = char._coyote or 0
    char._jumpBuf = char._jumpBuf or 0
    char.jumpHeldTime = char.jumpHeldTime or 0
    char._stuck_timer = char._stuck_timer or 0

    if gamestate ~= char._last_gamestate and char ~= sonic_demoexe then
        char._stuck_timer = 0.15
        char._last_gamestate = gamestate
    end
    if char._stuck_timer > 0 and char ~= sonic_demoexe then
        char._stuck_timer = char._stuck_timer - dt
        char.velocity.x, char.velocity.y = 0, 0
        char.currentSprite = char.idle
        return
    end

    local vx, vy = char.velocity.x, char.velocity.y
    local moveRight, moveLeft, jump, lookUp, lookDown = getControls()
    local inputDir = quantize((moveRight and 1 or 0) - (moveLeft and 1 or 0))
    local isDemoWithPhysics = (char == sonic_demoexe) and (sonic_demoexe.physics_enabled == true)

    if tail_tails and tail_tails.idle then updateSprite(dt * 0.5, tail_tails.idle, tail_tails)end

    snapToGround(char, map, dt)
    local grounded = char.grounded

    if grounded then
        local groundY = getGroundY(char, map, char.x, char.y)
        if groundY then
            char.y, vy = groundY, 0
            char.jumping = false
        end
    else
        vy = vy + (char.jumping and 625 or 400) * dt
    end

    char._coyote = grounded and COYOTE_TIME or max(0, char._coyote - dt)
    char._jumpBuf = jump and JUMP_BUFFER or max(0, char._jumpBuf - dt)

    if char == sonic_demoexe and isDemoWithPhysics then
        if grounded then
            vx = approach(vx, 0, GROUND_FRICTION)
        else
            vx = vx * AIR_DRAG
            vy = vy + (char.jumping and 1250 or 0) * dt
        end
    elseif char ~= sonic_demoexe then
        if grounded and (lookUp or lookDown) then
            char.currentSprite = lookUp and (char.up or char.idle) or (char.down or char.idle)
            char.angle, char.fakeAngle = 0, 0
            char.velocity.x, char.velocity.y = 0, 0
            return
        elseif moveRight or moveLeft then
            char.direction = moveRight and 1 or -1
            local accel, maxS = char.acceleration, char.maxSpeed
            vx = vx + accel * inputDir * dt
        else
            if grounded then
                local slopeAngle = getGroundSlope(char, map, char.x, char.y)
                vx, vy = applySlopePhysics(char, vx, vy, slopeAngle, dt)
                vx = (inputDir ~= 0) and clamp(vx + GROUND_ACCEL * inputDir * dt, -TOP_SPEED, TOP_SPEED)or approach(vx, 0, GROUND_FRICTION * dt)
            else
                vx = (inputDir ~= 0) and clamp(vx + AIR_ACCEL * inputDir * dt, -TOP_SPEED, TOP_SPEED) or approach(vx, 0, AIR_DECEL * dt)
            end
            vx = vx * (grounded and (1 - GROUND_FRICTION) or AIR_DRAG)
        end
        vx = clamp(vx, - (char.maxSpeed or 200), (char.maxSpeed or 200))
        if abs(vx) < 0.05 and not moveRight and not moveLeft then
            vx = 0
        end
        local canPerformJump = char.canJump and (grounded or (char._coyote > 0))
        if char._jumpBuf > 0 and canPerformJump and not char.jumping then
            char.jumping = true
            char.grounded = false
            char._jumpBuf = 0
            char.jumpHeldTime = 0
            local slopeAngle = getGroundSlope(char, map, char.x, char.y)
            vx = vx + JUMP_VELOCITY * -math.sin(slopeAngle) * 0.25
            vy = JUMP_VELOCITY * math.cos(slopeAngle)
            if sounds and sounds.jump_sound then sounds.jump_sound:play() end
        end

        if char.jumping and jump and char.jumpHeldTime < JUMP_HOLD_TIME then
            char.jumpHeldTime = char.jumpHeldTime + dt
            vy = vy - gravity * dt * 0.65
        end
        local absVx = abs(vx)
        if not char.grounded then
            if char.jumping then if char.jump then updateSprite(dt, char.jump, char) end
            else if char.walk then updateSprite(dt * 0.75, char.walk, char)
            else char.currentSprite = char.jump or char.idle end end
        elseif lookUp and vx == 0 then
            char.currentSprite = char.up or char.idle
        elseif lookDown and vx == 0 then
            char.currentSprite = char.down or char.idle
        elseif absVx >= (char.runThreshold or 175) then
            if char.run then updateSprite(dt, char.run, char) end
        elseif absVx > 0 and char.walk then
            updateSprite(dt * ((absVx / (char.maxSpeed or 200)) + 0.3), char.walk, char)
        else
            char.currentSprite = char.idle
        end
    end
    local nextX, nextY = char.x + vx * dt, char.y + vy * dt
    if not checkCollision(char, map, nextX, char.y) then
        char.x = nextX
    else
        local stepped = false
        for step = 1, MAX_STEP_HEIGHT do
            if not checkCollision(char, map, nextX, char.y - step) then
                char.x, char.y, stepped = nextX, char.y - step, true
                break
            end
        end
        if not stepped then vx = 0 end
    end
    if not checkCollision(char, map, char.x, nextY) then
        char.y = nextY
        char.grounded = false
    else
        if vy > 0 then
            char.grounded, char.jumping, vy = true, false, 0
            snapToGround(char, map, dt)
        elseif vy < 0 then
            char.grounded, vy, char.y = false, 0, char.y + 1
        end
    end

    if grounded or abs(vx) > 0 then
        local scrollFactor = bgScrollSpeed * clamp(abs(vx) / (char.maxSpeed or 200), 0.2, 1.0)
        bgOffsetX = bgOffsetX - vx * dt * scrollFactor
    end
    char.x = clamp(char.x, 15, mapWidth - 15)
    char.velocity.x, char.velocity.y = vx, vy
    if char ~= sonic_demoexe then
        local fellOff = (char.y >= mapHeight + 40)
        updateGamestate(char, fellOff)
        updateCamera(dt, char, mapWidth, mapHeight)
    else
        updateGamestate(char, false)
    end
end

local colorCycleTimer = 0
local colorCycleIndex = 1
local colorCycleInterval = 0.25
local colorPalettes = {
    {
        {0x24/255, 0x48/255, 0xD8/255},
        {0x6C/255, 0x90/255, 0xFC/255},
        {0xB4/255, 0xD8/255, 0xFC/255},
        {0xD8/255, 0xFC/255, 0xFC/255},
    },
    {
        {0x6C/255, 0x90/255, 0xFC/255},
        {0xB4/255, 0xD8/255, 0xFC/255},
        {0xD8/255, 0xFC/255, 0xFC/255},
        {0x24/255, 0x48/255, 0xD8/255},
    },
    {
        {0xB4/255, 0xD8/255, 0xFC/255},
        {0xD8/255, 0xFC/255, 0xFC/255},
        {0x24/255, 0x48/255, 0xD8/255},
        {0x6C/255, 0x90/255, 0xFC/255},
    },
    {
        {0xD8/255, 0xFC/255, 0xFC/255},
        {0x24/255, 0x48/255, 0xD8/255},
        {0x6C/255, 0x90/255, 0xFC/255},
        {0xB4/255, 0xD8/255, 0xFC/255},
    },
}

local hs_timer = 7
local hs_totalTime = 0
local tails_hiding = false
bushes_destroyed = false
hide_sound_played = false
bushes = {
    {x = 562, y = 665},
    {x = 1061, y = 740},
    {x = 2452, y = 690},
    {x = 3052, y = 747}
}
tails_caught_timer = 0
show_black_screen = false
idk_fix = false
local waiting_knuck = 0
demo_vis = false

local demo_speed = 400
local previousDirection = sonic_demoexe.direction

local jumpTimer = 0
local jumpInterval = 1

sonic_demoexe.bounceCount = 0
bossfightTimer = sounds.bossMusic:getDuration("seconds")
bossfightTimer = 0
bossfightActive = false

blackScreen = false
blackTimer = 0

local function keepDemoOnGround(demo, map)
    if not demo or not map or not map.height then return end
    local groundY = getGroundY(demo, map, demo.x, demo.y)
    if groundY then
        if demo.y > groundY then
            demo.y = groundY
            demo.velocity.y = 0
            demo.grounded = true
            demo.jumping = false
        end
    else
        if demo.y > map.height - demo.height then
            demo.y = map.height - demo.height
            demo.velocity.y = 0
            demo.grounded = true
        end
    end
end

local function handleBounce(knuck, demo, dt, map)
    if not knuck or not demo or not map or not map.height then return end
    local overlapX = abs(knuck.x - demo.x) < (knuck.width + demo.width) / 2
    local overlapY = abs(knuck.y - demo.y) < (knuck.height + demo.height) / 2

    if overlapX and overlapY then
        if knuck.jumping or demo.jumping then
            local bounceStrength = 200
            demo.bounceCount = (demo.bounceCount or 0) + 1

            if demo.bounceCount >= 2 then
                demo.velocity.y = 0
                demo.jumping = false
                demo.grounded = false
                demo.bounceCount = 0
                demo.currentSprite = demo.fall
                demo.spriteIndex = 1
                demo.fallTimer = 0
                if map then
                    local safety = 0
                    while checkCollision(demo, map, demo.x, demo.y) and safety < 32 do
                        demo.y = demo.y - 1
                        safety = safety + 1

                        if demo.y > map.height - demo.height then
                            demo.y = map.height - demo.height
                            demo.velocity.y = 0
                            demo.grounded = true
                        end
                    end
                end
            else
                knuck.velocity.y = -bounceStrength
                demo.velocity.y = -bounceStrength
                knuck.jumping = true
                knuck.grounded = false
                demo.jumping = true
                demo.grounded = false
                local horizontalPush = 50
                if knuck.x < demo.x then
                    knuck.velocity.x = knuck.velocity.x - horizontalPush
                    demo.velocity.x = demo.velocity.x + horizontalPush
                else
                    knuck.velocity.x = knuck.velocity.x + horizontalPush
                    demo.velocity.x = demo.velocity.x - horizontalPush
                end

                if map then
                    local safety = 0
                    while checkCollision(demo, map, demo.x, demo.y) and safety < 32 do
                        demo.y = demo.y - 1
                        safety = safety + 1

                        if demo.y > map.height - demo.height then
                            demo.y = map.height - demo.height
                            demo.velocity.y = 0
                            demo.grounded = true
                        end
                    end
                    safety = 0
                    while checkCollision(knuck, map, knuck.x, knuck.y) and safety < 32 do
                        knuck.y = knuck.y - 1
                        safety = safety + 1
                    end
                end
            end
        end

        if not knuck.jumping then
            blackScreen = true
            blackTimer = 3
            sounds.bossMusic:stop()
            bossfightActive = false
            bossfightTimer = 0
            eggman_lock = true
        end
    end
end

function knuck_up(dt)
    if stage1_vis then s1.currentSprite = s1.idle end
    if not stage1_vis then updateSprite(dt * 0.5, s1.stage2, s1) end
    if not stage2_vis then s1.currentSprite = s1.stage3 end
    if not demo_vis then
        local demo = sonic_demoexe
        demo.currentSprite = demo.crouch
        demo.x, demo.y, demo.direction = 6453, 788, -1
    end

    if knuckles.x >= 2400 then stage1_vis = false end
    if knuckles.x >= 4250 then
        stage2_vis, knuck_bg, demo_vis = false, fast.getImage("images/background/knuck2.png"), true
    end
    if knuckles.x >= 5350 then
        stage3_vis, knuck_bg = false, fast.getImage("images/background/knuck3.png")
    end

    if knuckles.x <= 5990 then return end

    waiting_knuck = waiting_knuck + dt
    local map2 = getMap("map2")
    if not map2 then return end
    camera.x = map2.width - base_width
    idk_fix = true

    if waiting_knuck >= 2 and not bossfightActive and not blackScreen then
        sounds.bossMusic:play()
        bossfightActive = true
        bossfightTimer = sounds.bossMusic:getDuration("seconds")
    end

    if bossfightActive and not blackScreen then
        bossfightTimer = max(0, bossfightTimer - dt)
        if bossfightTimer == 0 then
            bossfightActive = false
            sounds.bossMusic:stop()
            blackScreen, blackTimer = true, 3
        end
    end

    if blackScreen then
        blackTimer = blackTimer - dt
        if blackTimer <= 0 then
            blackScreen = false
            charStatus.knuckles_alive = false
            charStatus.knuckles_lock = false
            charStatus.eggman_lock = true
            gamestate = "selection"
        end
        return
    end

    local demo = sonic_demoexe
    if bossfightActive and demo then
        test_update(dt, demo, "map2")
        demo.physics_enabled = false
        if demo.x > 6484 then
            demo.direction = -1
        elseif demo.x < 5993 then
            demo.direction = 1
        elseif math.random() < 0.002 then
            demo.direction = (knuckles.x > demo.x) and 1 or -1
        end

        if demo.direction ~= previousDirection then
            demo_speed = math.random(375, 400)
            previousDirection = demo.direction
        end
        demo_speed = demo_speed or 380
        local targetSpeed = demo_speed * demo.direction

        jumpTimer = jumpTimer + dt
        if jumpTimer >= jumpInterval and not demo.jumping then
            jumpTimer = 0
            if math.random() <= 0.4 then
                demo.velocity.y = demo.jumpHeight
                demo.jumping, demo.grounded = true, false
            end
        end
        handleBounce(knuckles, demo, dt, map2)
        keepDemoOnGround(demo, map2)

        if demo.velocity.x < targetSpeed then
            demo.velocity.x = min(demo.velocity.x + demo_speed * dt, targetSpeed)
        elseif demo.velocity.x > targetSpeed then
            demo.velocity.x = max(demo.velocity.x - demo_speed * dt, targetSpeed)
        end
        if demo.currentSprite == demo.fall then
            updateSprite(dt, demo.fall, demo)
        elseif demo.jumping then
            updateSprite(dt, demo.jump, demo)
        elseif abs(demo.velocity.x) < abs(targetSpeed) * 0.9 then
            updateSprite(dt, demo.walk, demo)
        else
            updateSprite(dt, demo.run, demo)
        end

        if demo.grounded then demo.jumping = false end
        if demo.x < 5991 then
            demo.x = 5991
            demo.velocity.x = max(0, demo.velocity.x)
        end
    end
end

local error_sound_played = false
function eggman_up(dt)
    if eggman.x >= 1472 then
        sonic_demoexe.x, sonic_demoexe.y = 2894, 1255
        return
    end

    local demo = sonic_demoexe
    local dx, dy = eggman.x - demo.x, eggman.y - demo.y

    if demo.grounded then
        updateSprite(dt, demo.float, demo)
    elseif abs(dy) > 50 then
        demo.velocity.y = demo.jumpHeight
        updateSprite(dt, demo.fly, demo)
    end
    if dx ~= 0 then
        demo.x = demo.x + (dx / abs(dx)) * 682 * dt
    end
    if abs(dy) > 10 then
        demo.y = demo.y + (dy / abs(dy)) * 305 * dt
    end
    demo.direction = (eggman.x > demo.x) and 1 or -1
    if not crashing and abs(dx) < 125 and abs(dy) < 125 then
        crashing, crashTimer = true, 0
        charStatus.eggman_alive, charStatus.eggman_lock = false, false
        sounds.egg:stop()
        if not error_sound_played then
            sounds.error_sound:play()
            error_sound_played = true
        end
    end
end

local lights_off_played = false
function hide_and_seek(dt)
    hs_totalTime = hs_totalTime + dt
    if (hs_totalTime >= 45 or hs_timer <= 0) and not bushes_destroyed then
        bushes = {}
        bushes_destroyed = true
        sounds.flames:play()
        hs_timer = 0
        hs_totalTime = 45
        sounds.placeholder:play()
        if not lights_off_played then
            sounds.lights_off:play()
            lights_off_played = true
            flashScreen(0.54)
        end
    end

    local moveRight, moveLeft, jump, lookUp, lookDown = getControls()
    tails_hiding = false
    for _, bush in ipairs(bushes) do
        if tails.x > bush.x and tails.x < bush.x + bush_img:getWidth() and
           tails.y > bush.y and tails.y < bush.y + bush_img:getHeight() and lookDown then
            tails_hiding = true
            break
        end
    end

    if tails_caught then
        tails.velocity.x = 0
        tails.velocity.y = tails.velocity.y + gravity * dt
        test_update(dt, sonic_demoexe, "map1")
        tails.canJump = false

        if tails.grounded then
            tails.currentSprite = tails.fall
            tails.velocity.y = 0
        else
            updateSprite(dt, tails.damage, tails)
        end
        if sonic_demoexe.grounded then
            if sonic_demoexe.kill_tails then
                tails_caught2 = true
                updateSprite(dt, sonic_demoexe.kill_tails, sonic_demoexe)
                if sonic_demoexe.spriteIndex >= #sonic_demoexe.kill_tails then
                    sonic_demoexe.spriteIndex = #sonic_demoexe.kill_tails
                    show_black_screen = true
                end
            end
        elseif sonic_demoexe.fall then
            updateSprite(dt, sonic_demoexe.fall, sonic_demoexe)
        end

        return
    end

    updateSprite(dt * 0.7, fire_bg.idle, fire_bg)
    if tails_hiding then
        hs_timer = 12
        if not hide_sound_played then
            sounds.S3K_9A:play()
            hide_sound_played = true
        end
    else
        if hs_totalTime >= 3 then
            hs_timer = hs_timer - dt
        end
        hide_sound_played = false
    end
    if hs_timer <= 0 and not tails_caught then
        local dx = tails.x - sonic_demoexe.x
        local dy = tails.y - sonic_demoexe.y
        if dx ~= 0 then
            sonic_demoexe.x = sonic_demoexe.x + (dx / abs(dx)) * 542 * dt
        end

        local verticalSpeed = 220 --305
        local deadzone = 10
        if abs(dy) > deadzone then
            sonic_demoexe.y = sonic_demoexe.y + (dy / abs(dy)) * verticalSpeed * dt
        end

        if not sonic_demoexe.grounded and sonic_demoexe.fly then
            updateSprite(dt, sonic_demoexe.fly, sonic_demoexe)
        elseif sonic_demoexe.grounded and sonic_demoexe.float then
            updateSprite(dt, sonic_demoexe.float, sonic_demoexe)
        end
        if abs(dx) < 32 and abs(dy) < 32 then
            sounds.placeholder:stop()
            tails_caught = true
            sonic_demoexe.physics_enabled = true
            tails.velocity.x = 0
            tails.currentSprite = tails.fall

            if not sonic_demoexe.hasJumpedOnCatch then
                sonic_demoexe.velocity.x = 0
                sonic_demoexe.velocity.y = -300
                sonic_demoexe.hasJumpedOnCatch = true
            end
        end
    end
end

local animation_phase = "wait"
local frame_index = 1
local repeat_count = 0
local animation_timergugg = 0
local animation_timer2 = 0
local animation_timer3 = 0
finished_transformation = false
local bg_vis = true

emhi_bg = fast.getImage("images/background/emerald hill.png")
menu_finished = fast.getImage("images/background/menu_finished.png")
menu = fast.getImage("images/background/menu.png")
local scroll_speed = 50
anim_timer = 0

local ANIM_SPEED = 0.25
local animHandlers = {}

function nextFrame(frames, idx)
    if not frames or #frames == 0 then return 1 end
    return (idx % #frames) + 1
end

animHandlers.wait = function(dt)
    animation_timergugg = animation_timergugg + dt
    if animation_timergugg >= 0.05 then
        animation_phase = "initial"
        frame_index = 1
        --animation_timergugg = 0
    end
end

animHandlers.initial = function(dt)
    frame_index = frame_index + 1
    if frames and frame_index > #frames then
        frame_index = 1
        animation_phase = "repeatable"
        repeat_count = 0
    end
end

animHandlers.repeatable = function(dt)
    frame_index = nextFrame(repeatable_frames, frame_index)
    repeat_count = repeat_count + 1
    if repeat_count >= (9 * #repeatable_frames) then
        repeat_count = 0
        animation_phase = "screen"
        animation_timer3 = 0
    end
end

animHandlers.screen = function(dt)
    animation_timer3 = animation_timer3 + dt
    if animation_timer3 >= 0.1 then
        animation_timer3 = 0
        animation_phase = "repeatable2"
        repeat_count = 0
    end
end

idk_bg_cool = false
animHandlers.repeatable2 = function(dt)
    animation_timer3 = animation_timer3 + dt
    if animation_timer3 >= 0.075 then
        animation_timer3 = 0
        frame_index = nextFrame(repeatable2_frames, frame_index)
        repeat_count = repeat_count + 1

        if repeat_count == 23 then
            if sounds.cr4sh_sound then
                idk_bg_cool = true
                sounds.cr4sh_sound:setLooping(true)
                sounds.cr4sh_sound:play()
            end
            bg_vis = false
        end

        if repeat_count >= #repeatable2_frames then
            repeat_count = 0
            animation_phase = "black_screen"
            animation_timer2 = 0
        end
    end
end

animHandlers.black_screen = function(dt)
    if sounds.cr4sh_sound then
        idk_bg_cool = false
        sounds.cr4sh_sound:stop()
    end
    bg_vis = true
    animation_timer2 = animation_timer2 + dt
    if animation_timer2 >= 0.2 then
        finished_transformation = true
        animation_phase = "done"
    end
end
local animTime = 0.25
local timer = 0
local pressTextAnimTime = 2.2
local pressTextTimer = 0
local pressTextStartY = base_height + 50
local pressTextTargetY = (base_height / 2) + 70
local frames_idk_d = 1
local frameDelay = 25
local frameCounter = 0

local flickerTimer = 0
local flickerInterval = 0.1
local showPressText = true
local flickerActive = false
flickerRepeat = 0
flickerMaxRepeats = 15
link = "https://docs.google.com/document/d/1J0nOXnQMULgsqhbdnPfF3uHCHJ0wMvX1BC4TgXKVpX8"

function updateColorCycle(dt)
    colorCycleTimer = colorCycleTimer + dt
    if colorCycleTimer >= colorCycleInterval then
        colorCycleTimer = colorCycleTimer - colorCycleInterval
        colorCycleIndex = colorCycleIndex + 1
        if colorCycleIndex > #colorPalettes then
            colorCycleIndex = 1
        end
    end
end

local splashFrameTime = 0.3
local splashTimer = 0

function menuscreen_update(dt)
    if gamestate ~= "menuscreen" then return end
    anim_timer = anim_timer + dt
    if anim_timer >= ANIM_SPEED then
        anim_timer = anim_timer - ANIM_SPEED
        local handler = animHandlers[animation_phase]
        if handler then
            handler(dt)
        end
    end
    frameCounter = frameCounter + 1
    splashTimer = splashTimer + dt
    if splashTimer >= splashFrameTime then
        splashTimer = splashTimer * splashFrameTime
        frames_idk_d = nextFrame(splash_frames.idle, frames_idk_d)
    end
    if finished_transformation then
        pressTextTimer = min(pressTextTimer + dt, pressTextAnimTime)
        if not sounds.buildUPSound:isPlaying() then
            sounds.buildUPSound:play()
        end
    end
    if finished_transformation and (love.keyboard.isDown("return") or jumpButton.active) then
        if sounds.laugh_sound and not flickerActive then
            if sounds.sound then sounds.sound:play() end
            sounds.laugh_sound:play()
            flickerActive = true
            flickerRepeat, flickerTimer = 0, 0
        end
    end
    if flickerActive then
        flickerTimer = flickerTimer + dt
        if flickerTimer >= flickerInterval then
            flickerTimer = 0
            showPressText = not showPressText
            flickerRepeat = flickerRepeat + 1
            if flickerRepeat >= flickerMaxRepeats then
                flickerActive = false
                showPressText = false
                shrinkingMenu = true
            end
        end
    end
    if timer < animTime and animation_phase ~= "wait" then
        timer = timer + dt
    end
end
local zoomTimer = 0
local zoomDuration = 2

local shrinkTimer = 0
local shrinkDuration = 2.25
elapsedTime4 = 0
reboot_vis = false
reboot_vis2 = false

local helloWilliamTimer = 0
local greenHillZoneTitle = fast.getImage("images/zone/titles/zone.png")
local hideAndSeekZoneTitle = fast.getImage("images/zone/titles/h&s.png")
local DotTitle = fast.getImage("images/zone/titles/dot.png")
function drawTitleCard(stageNameImg, circleImg, actImg, baseX, baseY)
    love.graphics.draw(circleImg, baseX + 10, baseY)
    love.graphics.draw(stageNameImg, -baseX + 225, baseY)
    love.graphics.draw(stageActImg, baseX + greenHillZoneTitle:getWidth() - 25, baseY + circleImg:getHeight() - 4)
    love.graphics.draw(actImg, baseX + greenHillZoneTitle:getWidth() + 10, baseY + circleImg:getHeight() - 20)
end

stageTitleTimer = 0
stageTitleDuration = 3.0
stageTitleFadeTime = 0.5
showStageTitle = false

function triggerStageTitle()
    stageTitleTimer = 0
    showStageTitle = true
end

local loadingStages = {
    "Loading codes...",
    "Loading images...",
    "Loading sounds & music...",
    "Loading frame animations..."
}
local currentStage = 1
local stageProgress = 0
local stageDelay = 0
local stageComplete = false
local rebootDone = false
local fadeBlack = 0
local helloFade = 0

function updateStageTitle(dt)
    if showStageTitle then
        stageTitleTimer = stageTitleTimer + dt
        if stageTitleTimer > stageTitleDuration then
            showStageTitle = false
        end
    end
end

local prevGamestate = gamestate
local waiting = 0

function updateGamestate(char, fellOff)
    local spawns = {
        default = {x = 100, y = 625},
        eggman  = {x = 3300, y = 50},
        testmap = {x = 100, y = 65},
    }
    local spawn

    if gamestate == "eggman" then
        spawn = spawns.eggman
    elseif gamestate == "testmap" then
        spawn = spawns.testmap
    else
        spawn = spawns.default
    end
    if gamestate ~= prevGamestate or fellOff then
        char.x, char.y = spawn.x, spawn.y
        char.velocity.x, char.velocity.y = 0, 0
        char.jumping, char.grounded = false, false
        prevGamestate = gamestate
    end
    if fellOff then
        if sounds and sounds.hitStatic then
            flashScreen(0.5)
            sounds.hitStatic:stop()
            sounds.hitStatic:play()
        end
    end
end

sounds.hitStatic:setVolume(1.8)
local stages = { test = true, hs = true, knuck = true, eggman = true, william = true }
lastGamestate = nil
titleCardPlayed = false

function update_flash(dt)
        if isFlashing then
        flashTimer = flashTimer - dt
        flashAlpha = flashTimer / flashDuration

        if flashTimer <= 0 then
            isFlashing = false
            flashAlpha = 0
        end
    end
end

function ring_anim(dt)
    if stats.rings == 0 then
        ringAnimTimer = ringAnimTimer + dt
        if ringAnimTimer >= ringAnimSpeed then
            ringAnimTimer = 0
            ringAnimState = not ringAnimState
        end
    else
        ringAnimState = true
        ringAnimTimer = 0
    end
end

local joystickCooldown = 0
local returnPressed = false
errorSoundPlayed = false

local scroll = {
    [1] = 0,
    [2] = 0,
    [3] = 0,
    [4] = 0
}

local scrollSpeeds = {
    [1] = 110,
    [2] = 60,
    [3] = 40,
    [4] = 100
}

scrollX = 0
local function updateScrollingBG(dt)
    if animation_phase == "wait" or not bg_vis then return end
    local width = menu:getWidth()
    scrollX = (scrollX + scroll_speed * dt) % width
    for i = 1, #MenuImagesDamn do
        local img = MenuImagesDamn[i]
        if img then
            local w = img:getWidth()
            scroll[i] = (scroll[i] + scrollSpeeds[i] * dt) % w
        end
    end
end

local function eggmanCrashThing(dt)
    if not crashing then
        sonic_demoexe.currentSprite = sonic_demoexe.fly
        love.window.setTitle("SONIC 2 3 1")
        test_update(dt, eggman, "map3")
        eggman_up(dt)
        sounds.egg:play()
        return
    end

    if crashing then
        sounds.egg:stop()
    end

    if not crashing2 then
        sounds.egg:stop()
        sonic_demoexe.currentSprite = sonic_demoexe.fly[1]
        eggman.currentSprite = eggman.idle
        ringAnimState = false
    end

    crashTimer = crashTimer + dt
    love.window.setTitle("SONIC 2 3 1 (Not responding)")

    crashAlpha = (crashTimer <= fadeDuration)
        and (crashTimer / fadeDuration) * crashMaxAlpha
        or crashMaxAlpha

    if crashTimer >= 7 then
        updateSprite(dt * 0.5, sonic_demoexe.fly_anim, sonic_demoexe)
        sonic_demoexe.spriteIndex = min(sonic_demoexe.spriteIndex, #sonic_demoexe.fly_anim)
    end

    if not crashing2 and crashTimer >= 10 then
        crashing, crashing2 = false, true
        love.window.setTitle("")
    end

    if crashing2 and crashTimer < 12 then
        sounds.cr4sh_sound:play()
        mapImages.gh1 = fast.getImage("images/maps/gh1_crashed.png")
        eggman.currentSprite = eggman.crashed
        sonic_demoexe.currentSprite = sonic_demoexe.cr4sh
    elseif crashTimer >= 12 then
        gamestate, crashing2, crashAlpha = "cheating", false, 0
    end
    releaseCharacter(knuckles)
    releaseCharacter(s1)
end

function releaseCharacter(charName)
    local char = _G[charName]
    if not char then return end
    if char.currentSprite then
        if type(char.currentSprite) == "table" then
            for _, img in ipairs(char.currentSprite) do
                if img.release then img:release() end
            end
        elseif char.currentSprite.release then
            char.currentSprite:release()
        end
    end
    if char.walk then
        for _, img in ipairs(char.walk) do if img.release then img:release() end end
    end
    _G[charName] = nil
end

local gamestateHandlers = {
    test = function(dt)
        test_update(dt, tails, "map")
        before_idk(dt)
        love.window.setTitle("SONIC 2 3 1")
    end,
    hs = function(dt)
        test_update(dt, tails, "map1")
        hide_and_seek(dt)
        if show_black_screen then
            sounds.flames:stop()
            tails_caught_timer = tails_caught_timer + dt
            if tails_caught_timer >= 4 then
                show_black_screen, charStatus.tails_alive = false, false
                charStatus.knuckles_lock, charStatus.tails_lock = true, false
                gamestate = "selection"
            end
        end
        zoomTimer = 0
        zoomDuration = 2
    end,
    knuck = function(dt)
        releaseCharacter(tails)
        releaseCharacter(tail_tails)
        releaseCharacter(fire_bg)
        test_update(dt, knuckles, "map2")
        knuck_up(dt)
        love.window.setTitle("SONIC 2 3 1")
        zoomTimer = 0
        zoomDuration = 2
    end,
    testmap = function(dt)
        test_update(dt, test_character, "testmap2")
    end,
    eggman = eggmanCrashThing,
    torture = torture,
    william = function(dt)
        william_update(dt)
        love.mouse.setRelativeMode(true)
    end,
    cheating = function(dt)
        releaseCharacter(eggman)
        love.window.setTitle("")
        cheating(dt)
    end,
    warning = function()
        if love.keyboard.isDown("return") or jumpButton.active then
            startTransition("error")
        end
    end,
}

function checkStageTitle(gamestate, stages)
    if gamestate ~= lastGamestate then
        titleCardPlayed = false
        lastGamestate = gamestate
    end
    if stages[gamestate] and not titleCardPlayed then
        triggerStageTitle()
        titleCardPlayed = true
    end
end

function love.update(dt)
    fast.limitFPS()
    if resizeFreezeTimer > 0 then
        resizeFreezeTimer = resizeFreezeTimer - dt
        if resizeFreezeTimer < 0 then
            resizeFreezeTimer = 0
        end
        return
    end
    gameTime = gameTime + dt
    if ok and discord then
        discord.runCallbacks()
    end
    fast.reduceMemory(dt)
    update_flash(dt)
    ring_anim(dt)

    local handler = gamestateHandlers[gamestate]
    if handler then
        handler(dt)
    else
        love.mouse.setRelativeMode(false)
    end

    if love.timer.getTime() % 5 < dt then
        print("Lua memory: " .. collectgarbage("count")/1024 .. " MB")
    end

    if gamestate == "selection" then
        tails_caught = false
        tails_caught2 = false
        camera.locked = false
        sonic_demoexe.physics_enabled = false
        if (love.keyboard.isDown("return") or jumpButton.active) then
            if not returnPressed then
                returnPressed = true
                local choice = ({
                    [1] = {lock = charStatus.tails_lock, state = "test"},
                    [2] = {lock = charStatus.knuckles_lock, state = "knuck"},
                    [3] = {lock = charStatus.eggman_lock, state = "eggman"}
                })[selectionIndex]
                if choice and choice.lock then
                    startTransition(choice.state)
                end
            end
        else
            returnPressed = false
        end

        if joystickCooldown > 0 then
            joystickCooldown = joystickCooldown - dt
        elseif abs(joystick.dx) > 0.5 then
            selectionIndex = max(1, min(#selectionOptions, selectionIndex + (joystick.dx > 0 and 1 or -1)))
            sounds.reboot_old:play()
            joystickCooldown = 0.25
        end

        zoomTimer = min(zoomTimer + dt, zoomDuration)
        local t = easeInOutCubic(zoomTimer / zoomDuration)
        selectionScale = 3 + (1 - 3) * t
        selectionAlpha = t
        if zoomTimer >= zoomDuration then
            selectionScale, selectionAlpha = 1, 1
        end

        local titles = {"2", "3", "1"}
        love.window.setTitle(titles[selectionIndex] or "")
    else
        joystickCooldown = 0
        returnPressed = false
    end

    for _, s in ipairs(sounds) do
        s:setVolume(0)
    end
    updateActiveCharacter()
    if gamestate == "credits" then
        if love.keyboard.isDown("down") or joystick.dy > 0.2 then
            scrollY = scrollY + scrollSpeed * dt
        elseif love.keyboard.isDown("up") or joystick.dy < -0.2 then
            scrollY = scrollY - scrollSpeed * dt
        end

        local maxScroll = max(#credits * 120 - base_height + 50, 0)
        scrollY = max(0, min(scrollY, maxScroll))

        if love.keyboard.isDown("return") or jumpButton.active then
            love.system.openURL(link)
            love.event.quit()
        end
    elseif gamestate == "error" then
        elapsedTime4 = (elapsedTime4 or 0) + dt
        reboot_vis2 = (elapsedTime4 >= 2 and elapsedTime4 < 6)
        reboot_vis  = (elapsedTime4 >= 7)
        if reboot_vis2 and not errorSoundPlayed then
            sounds.sonic_error_sound:play()
            errorSoundPlayed = true
        end

        if reboot_vis and not rebootDone then
            stageIncrementTimer = (stageIncrementTimer or 0) + dt
            if not stageComplete then
                if stageIncrementTimer >= 0.5 then
                    stageIncrementTimer = stageIncrementTimer - 0.5
                    stageProgress = min(100, stageProgress + 10)
                    sounds.reboot_old:play()
                    stageComplete = (stageProgress >= 100)
                    if stageComplete then stageDelay = 0 end
                end
            else
                stageDelay = stageDelay + dt
                if stageDelay >= 1 then
                    currentStage = currentStage + 1
                    if currentStage > #loadingStages then
                        rebootDone, stageDelay = true, 0
                    else
                        stageProgress, stageComplete = 0, false
                    end
                end
            end
        elseif rebootDone then
            fadeBlack = min(1, fadeBlack + dt * 0.5)
            if fadeBlack >= 1 then
                helloFade = min(1, helloFade + dt * 0.5)
                if helloFade >= 1 then
                    helloWilliamTimer = (helloWilliamTimer or 0) + dt
                    if helloWilliamTimer >= 2 then
                        gamestate = "menuscreen"
                    end
                end
            end
        end
    elseif gamestate == "game_over" then
        waiting = waiting + dt
        if waiting >= 3 then startTransition("credits") end
    end
    if transitioning then
        transitionAlpha = min(transitionAlpha + transitionSpeed * dt, 1)
        if transitionAlpha >= 1 then
            gamestate = transitionTarget
            transitioning = false
        end
    else
        transitionAlpha = max(transitionAlpha - transitionSpeed * dt, 0)
    end

    colorTimer = colorTimer + dt
    local phase = floor(colorTimer / colorPhaseTime) % 2
    colorLerp = ((colorTimer % colorPhaseTime) / colorPhaseTime) * (phase == 0 and 1 or -1) + (phase == 1 and 1 or 0)

    if shrinkingMenu then
        shrinkTimer = min(shrinkTimer + dt, shrinkDuration)
        local eased = easeOutCubic(shrinkTimer / shrinkDuration)
        menuShrink = 1 - (1 - 0.5) * eased
        menuAlpha = 1 - eased
        if shrinkTimer >= shrinkDuration then
            shrinkingMenu = false
            gamestate = "selection"
        end
    end

    checkStageTitle(gamestate, stages)
    menuscreen_update(dt)
    updateStageTitle(dt)
    updateScrollingBG(dt)
    updateColorCycle(dt)
end

local function drawNumberString(x, y, str)
    str = tostring(str)
    for i = 1, #str do
        local byte = str:byte(i)
        if byte >= 48 and byte <= 57 then
            local digit = byte - 48
            love.graphics.draw(images.numbers, quads.numbers[digit], x, y)
            x = x + 9
        elseif byte == 58 then
            love.graphics.draw(images.numbers, quads.numbers[10], x, y)
            x = x + 9
        end
    end
end

function love.keypressed(key)
    if key == "f3" then
        showDebug = not showDebug
    end
end

soundPlayed8 = false
soundPlayed9 = false
soundPlayed10 = false

function selection()
    local winWidth, winHeight = base_width, base_height
    local mouseX, mouseY = love.mouse.getPosition()
    local halfW, halfH = winWidth * 0.5, winHeight * 0.5
    local offsetX = (mouseX - halfW) * 0.025
    local offsetY = (mouseY - halfH) * 0.02

    love.graphics.push()
    love.graphics.translate(halfW, halfH)
    love.graphics.scale(selectionScale, selectionScale)
    love.graphics.translate(-halfW, -halfH)
    love.graphics.setColor(1, 1, 1, selectionAlpha)

    local baseX = halfW + offsetX + characterOffsetX
    local centerY = halfH + offsetY
    love.graphics.draw(selectionImages.selection_box,baseX,centerY,0,1, 1,selectionImages.selection_box:getWidth() * 0.5,selectionImages.selection_box:getHeight() * 0.5)
    local characters = {
        { alive = charStatus.tails_alive, lock = charStatus.tails_lock, img = selectionImages.tails_selection, dead = selectionImages.dead_tails },
        { alive = charStatus.knuckles_alive, lock = charStatus.knuckles_lock, img = selectionImages.knuck_selection, dead = selectionImages.dead_knuckles },
        { alive = charStatus.eggman_alive, lock = charStatus.eggman_lock, img = selectionImages.eggman_selection, dead = selectionImages.dead_eggman }
    }

    local spacing = 100
    for i, char in ipairs(characters) do
        local isSelected = (i == selectionIndex)
        local xOffset = (i - selectionIndex) * spacing
        local scale = isSelected and 1 or 0.65
        local yOffset = isSelected and 0 or 25
        local alpha = isSelected and 1 or 0.7

        local drawX = baseX + xOffset
        local drawY = centerY + yOffset

        love.graphics.setColor(1, 1, 1, alpha * selectionAlpha)

        if char.alive then
            love.graphics.draw(char.img,drawX,drawY,0,scale, scale,char.img:getWidth() * 0.5,char.img:getHeight() * 0.5)
            if not char.lock then
                love.graphics.draw(lockImg, drawX - 10, drawY + 20, 0, scale, scale)
            end
        else
            love.graphics.draw(char.dead,drawX,drawY,0,scale, scale,char.dead:getWidth() * 0.5,char.dead:getHeight() * 0.5)
        end
    end
    local arrowY = centerY - 25
    local leftActive = love.keyboard.isDown("left") or joystick.dx < -0.5
    local rightActive = love.keyboard.isDown("right") or joystick.dx > 0.5

    local function drawArrow(active, x, y, flipX)
        love.graphics.setColor(active and {0.5, 0.5, 0.5, selectionAlpha} or {1, 1, 1, selectionAlpha})
        love.graphics.draw(uiAssets.warrow, x, y, 0, flipX, 1)
    end

    drawArrow(leftActive, 50, arrowY, 1)
    drawArrow(rightActive, winWidth - 50, arrowY + 1, -1)

    love.graphics.setColor(1, 1, 1)
    love.graphics.pop()
end

local activeChar = nil
function updateActiveCharacter()
    if gamestate == "test" or gamestate == "hs" then
        activeChar = tails
    elseif gamestate == "knuck" then
        activeChar = knuckles
    elseif gamestate == "eggman" then
        activeChar = eggman
    elseif gamestate == "testmap" then
        activeChar = test_character
    else
        activeChar = tails
    end
end

local function char_draw(char, offsetX, offsetY)
    if not (char.isPresent and char.currentSprite) then return end

    offsetX, offsetY = offsetX or 0, offsetY or 0
    local sprite = char.currentSprite
    if type(sprite) == "table" then
        sprite = sprite[floor(char.spriteIndex + 0.5)] or sprite[1]
    end
    if not sprite then return end

    local flipX = (char.direction == -1) and -1 or 1
    local drawX = floor(char.x + offsetX + 0.5)
    local drawY = floor(char.y + offsetY + 0.5)
    local w, h = sprite:getWidth(), sprite:getHeight()
    local ox, oy = floor(w * 0.5 + 0.5), floor(h * 0.5 + 0.5)

    love.graphics.draw(sprite, drawX, drawY, char.fakeAngle, flipX, 1, ox, oy)
end

local function drawScrollingBG(img, x, y)
    local width = img:getWidth()
    love.graphics.draw(img, -scrollX + x, y)
    love.graphics.draw(img, -scrollX + width + x, y)
end

DEMO_MenuScreen = fast.getImage(spritesFolder.."menuscreen/splash/6.png")
greenHillZoneCircles = fast.getImage("images/zone/circles/g_hill.png")
local hideAndSeekZoneCircles = fast.getImage("images/zone/circles/h&s.png")
local DotCircles = fast.getImage("images/zone/circles/dot.png")
labCircles = fast.getImage("images/zone/circles/us.png")

stageActImg = fast.getImage("images/zone/act/act.png")
stageActImg1 = fast.getImage("images/zone/act/1.png")
stageActImg2 = fast.getImage("images/zone/act/2.png")

function linear(a, b, t)
    a = tonumber(a) or 0
    b = tonumber(b) or 0
    t = tonumber(t) or 0
    t = max(0, min(1, t))
    return a + (b - a) * t
end

preloadedTiles = {}
local hw, hh, aspect, fovRad, fovHalfTan

function updateProjectionConstants()
    local w, h = base_width, base_height
    hw, hh = w * 0.5, h * 0.5
    aspect = w / h
    fovRad = math.rad(70)
    fovHalfTan = math.tan(fovRad / 2)
end

function preloadTiles()
    updateProjectionConstants()
    local yaw, pitch = -camera_3d.yaw, -camera_3d.pitch
    local cy, sy = cos(yaw), sin(yaw)
    local cp, sp = cos(pitch), sin(pitch)

    local camX, camY, camZ = camera_3d.x, camera_3d.y, camera_3d.z
    local n = 0

    for t = 1, #baseplateTiles do
        local tile = baseplateTiles[t]
        if inRenderDistance(tile) then
            local visible = true
            local verts = {}

            for i = 1, 4 do
                local v = tile[i]
                local dx, dy, dz = v[1] - camX, v[2] - camY, v[3] - camZ
                local x1 = dx * cy - dz * sy
                local z1 = dx * sy + dz * cy
                local y1 = dy * cp - z1 * sp
                local z2 = dy * sp + z1 * cp

                if z2 <= 0.1 then
                    visible = false
                    break
                end

                local invZ = 1 / (z2 * fovHalfTan)
                local screenX = x1 * invZ / aspect * hw + hw
                local screenY = -y1 * invZ * hh + hh

                verts[i * 2 - 1] = screenX
                verts[i * 2] = screenY
            end

            if visible then
                local v1, v3 = tile[1], tile[3]
                local cx = (v1[1] + v3[1]) * 0.5 - camX
                local cyMid = (v1[2] + v3[2]) * 0.5 - camY
                local cz = (v1[3] + v3[3]) * 0.5 - camZ
                local distSq = cx * cx + cyMid * cyMid + cz * cz

                n = n + 1
                local ptile = preloadedTiles[n] or {}
                ptile.verts = verts
                ptile.col = v1[4]
                ptile.dist = distSq
                preloadedTiles[n] = ptile
            end
        end
    end
    for i = n + 1, #preloadedTiles do
        preloadedTiles[i] = nil
    end
end

function draw_demo3d()
    updateProjectionConstants()
    local cy, sy = cos(-camera_3d.yaw), sin(-camera_3d.yaw)
    local cp, sp = cos(-camera_3d.pitch), sin(-camera_3d.pitch)

    local x, y, z = chaser.x - camera_3d.x, chaser.y - camera_3d.y, chaser.z - camera_3d.z
    local x1, z1 = x * cy - z * sy, x * sy + z * cy
    local y1 = y * cp - z1 * sp
    local z2 = y * sp + z1 * cp
    local dx, dy, dz = camera_3d.x - chaser.x, camera_3d.y - chaser.y, camera_3d.z - chaser.z

    if z2 > 0.1 then
        local invZ = 1 / z2
        local scale = 25 * invZ
        local sx = x1 / (z2 * fovHalfTan * aspect)
        local sy = y1 / (z2 * fovHalfTan)

        local distSq = dx*dx + dy*dy + dz*dz
        local fadeStart2, fadeEnd2 = 100*100, 15*15
        local alpha = clamp((fadeStart2 - distSq) / (fadeStart2 - fadeEnd2), 0, 1)

        love.graphics.setColor(1, 1, 1, alpha)

        local img
        if demo_3d.state == "chasing" then
            img = demo_3d.chase_img
        else
            img = demo_3d.side_imgs[demo_3d.current_side]
        end

        love.graphics.draw(
            img,
            sx * hw + hw - img:getWidth() * scale / 2,
            -sy * hh + hh - img:getHeight() * scale / 2,
            0, scale, scale
        )
    end
end

local function draw_william()
    updateProjectionConstants()
    if not sounds.buildUPSound:isPlaying() then
        sounds.buildUPSound:play()
    end

    for i = 1, #preloadedTiles do
        local t = preloadedTiles[i]
        if t.verts and #t.verts >= 6 then
            local r, g, b = t.col[1] or 1, t.col[2] or 1, t.col[3] or 1
            love.graphics.setColor(r, g, b, 1)
            love.graphics.polygon("fill", t.verts)
        end
    end

    draw_demo3d()
    love.graphics.setColor(1, 1, 1, 1)
    draw_flashlight()
    love.graphics.draw(idk_img, 0, 0, 0, base_width / idk_img:getWidth(), base_height / idk_img:getHeight())

    drawStats()
end
function draw_flashlight()
    if demo_3d.state == "stopped" then
        local alpha = 1
        if demo_3d.stop_timer > 1 then
            alpha = 1 - (demo_3d.stop_timer - 1) / 1
        end
        alpha = clamp(alpha, 0, 1)

        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.draw(jumpscare, 0, 0, 0, base_width / jumpscare:getWidth(), base_height / jumpscare:getHeight())
        love.graphics.setColor(1, 1, 1, 1)
    end
end

function draw_menuscreen()
    love.graphics.push()
    love.graphics.setColor(1, 1, 1, menuAlpha)
    love.graphics.translate(base_width/2, base_height/2)
    love.graphics.scale(menuShrink, menuShrink)
    love.graphics.translate(-base_width/2, -base_height/2)
    if finished_transformation then
        menu = fast.getImage("images/background/menu.png")
        sounds.sonic_theme:stop()

        local mouseX, mouseY = love.mouse.getPosition()
        mouseX = (mouseX - offset_x) / scale_factor
        mouseY = (mouseY - offset_y) / scale_factor
        local offsetX = (mouseX - base_width) * 0.05
        local offsetY = (mouseY - base_height) * 0.05

        local demoX = (base_width - DEMO_MenuScreen:getWidth()) / 2 + offsetX * 0.5
        local demoY = (base_height - DEMO_MenuScreen:getHeight()) / 2 + offsetY * 0.4
        love.graphics.draw(splash_frames.idle[frames_idk_d], demoX, demoY- 10)

        local t = min(pressTextTimer / pressTextAnimTime, 1)
        local easedT = easeInOutCubic(t)
        local currentY2 = pressTextStartY + (pressTextTargetY - pressTextStartY) * easedT
        local text = "Press start to play."
        local textWidth = FontBig:getWidth(text)
        if not flickerActive or showPressText then
            love.graphics.print(text, (base_width - textWidth) / 2 + offsetX * 0.5 + 70, currentY2 + offsetY * 0.4)
        end
        love.graphics.pop()
        return
    end
    sounds.sonic_theme:play()
    sounds.sonic_theme:setLooping(true)
    local colorMod = (animation_phase == "repeatable2") and 0.5 or 1
    love.graphics.setColor(colorMod, colorMod, colorMod)
    -- drawScrollingBG(menu, 0, 0)
    if not idk_bg_cool then
        for i = 1, #MenuImagesDamn do
            local img = MenuImagesDamn[i]
            if img then
                local w = img:getWidth()
                local y = 0

                if i == 4 then
                    local palette = colorPalettes[colorCycleIndex]
                    local shader = love.graphics.newShader([[
                        extern vec3 color1;
                        extern vec3 color2;
                        extern vec3 color3;
                        extern vec3 color4;
                        extern float colorMod;

                        vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
                            vec4 pixel = Texel(tex, texture_coords);
                            vec3 c = pixel.rgb;
                            if (c.r > 0.58 && c.g < 0.2 && c.b > 0.4) {c = color1;
                            } else if (c.r >= 0.733 && c.g <= 0.2 && c.b >= 0.6) {c = color2;
                            } else if (c.r > 0.8 && c.g < 0.4 && c.b > 0.7) {c = color3;
                            } else if (c.r > 0.9 && c.g < 0.5 && c.b > 0.8) {c = color4;
                            }
                            c *= colorMod;
                            return vec4(c, pixel.a);
                        }
                    ]])
                    shader:send("color1", palette[1])
                    shader:send("color2", palette[2])
                    shader:send("color3", palette[3])
                    shader:send("color4", palette[4])
                    shader:send("colorMod", colorMod)
                    love.graphics.setShader(shader)
                    love.graphics.draw(img, -scroll[i], y)
                    love.graphics.draw(img, -scroll[i] + w, y)
                    love.graphics.setShader()
                else
                    love.graphics.draw(img, -scroll[i], y)
                    love.graphics.draw(img, -scroll[i] + w, y)
                end
            end
        end
    end
    love.graphics.setColor(1, 1, 1)
    local demoX = (base_width - DEMO_MenuScreen:getWidth()) / 2
    local demoY = (base_height - DEMO_MenuScreen:getHeight()) / 2

    --i kinda forgot how to code
    local currentY = demoY - 10

    local circleX = (base_width - circle:getWidth()) / 2
    local circleY = (base_height - circle:getHeight()) / 2

    if animation_phase ~= "repeatable2" then
        love.graphics.draw(circle, circleX, circleY + 30)
    end

    love.graphics.setScissor(0, 0, base_width, 175)
    if animation_phase == "initial" then
        local t = min(timer / animTime, 1)
        local currentY = linear(demoY + 70, demoY - 10, t)
        love.graphics.draw(frames[frame_index], demoX, currentY)
    elseif animation_phase == "repeatable" then
        love.graphics.draw(repeatable_frames[frame_index], demoX, currentY)
    elseif animation_phase == "repeatable2" then
        if idk_bg_cool then
            drawScrollingBG(menu3, 0, 0)
        end
        sounds.sonic_theme:stop()
        love.graphics.draw(repeatable2_frames[frame_index], demoX, currentY)
    end
    love.graphics.setScissor()

    if animation_phase ~= "repeatable2" then
        love.graphics.draw(title, (base_width - title:getWidth()) / 2, demoY + 75)
        love.graphics.draw(smth, base_width - 75, base_height - 12)
    end

    if animation_phase == "screen" or animation_phase == "black_screen" then
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("fill", 0, 0, base_width * 2, base_height * 2)
        sounds.sonic_theme:stop()
        love.graphics.setColor(1, 1, 1)
    end
    love.graphics.pop()
    love.graphics.setColor(1, 1, 1, 1)
end

function linearTime(t)
    return clamp(t, 0, 1)
end

function tails_tail_thing()
    local tailsSprite = tails.currentSprite

    if tailsSprite == tails.idle or tailsSprite == tails.down or tailsSprite == tails.up then
        local flipX = (tails.direction == -1) and -1 or 1
        local offsetX = (flipX == 1) and -12 or 12

        local currentFrame = tail_tails.currentSprite
        if type(currentFrame) == "userdata" then
            local halfW = currentFrame:getWidth() * 0.5
            local halfH = currentFrame:getHeight() * 0.5
            love.graphics.draw(currentFrame, tails.x + offsetX, tails.y + 5, 0, flipX, 1, halfW, halfH)
        end
    else
        print("idle")
    end
end

function mobile_stuff_draw()
    love.graphics.setColor(1, 1, 1)

    love.graphics.draw(uiAssets.joystickBase,joystick.x - uiAssets.joystickBase:getWidth() / 2 * SCALE,joystick.y - uiAssets.joystickBase:getHeight() / 2 * SCALE,0,SCALE, SCALE)

    local knobX = joystick.x + joystick.dx * joystick.radius
    local knobY = joystick.y + joystick.dy * joystick.radius
    love.graphics.draw(uiAssets.joystickKnob,knobX - uiAssets.joystickKnob:getWidth() / 2 * SCALE,knobY - uiAssets.joystickKnob:getHeight() / 2 * SCALE,0,SCALE, SCALE)

    if jumpButton.active then
        love.graphics.setColor(1, 1, 1, 0.75)
    else
        love.graphics.setColor(1, 1, 1, 1)
    end

    love.graphics.draw(uiAssets.jumpButton,jumpButton.x - uiAssets.jumpButton:getWidth() / 2 * SCALE,jumpButton.y - uiAssets.jumpButton:getHeight() / 2 * SCALE,0,SCALE, SCALE)
    love.graphics.setColor(1, 1, 1, 1)
end

function drawDebug(character)
    if not showDebug then return end
    love.graphics.setColor(0, 0, 0, 0.65)
    love.graphics.rectangle("fill", 8, 8, 280, 155)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("=== DEBUG SCREEN ===", 16, 12)
    love.graphics.print(string.format("Pos: (%.1f, %.1f)", character.x, character.y), 16, 32)
    love.graphics.print(string.format("Vel: (%.1f, %.1f)", character.velocity.x, character.velocity.y), 16, 48)
    love.graphics.print(string.format("Speed: %.1f", math.sqrt(character.velocity.x^2 + character.velocity.y^2)), 16, 64)
    love.graphics.print("Grounded: " .. tostring(character.grounded), 16, 80)
    love.graphics.print("Jumping: " .. tostring(character.jumping), 16, 96)
    love.graphics.print("Direction: " .. character.direction, 16, 112)
    love.graphics.print(string.format("Sprite Index: %.1f", character.spriteIndex), 16, 128)
    love.graphics.print(string.format("FPS: %d", love.timer.getFPS()), 16, 144)
end

function drawStageTitle(titleImg, circlesImg, actImg)
        if not showStageTitle then return end

        local remaining = stageTitleDuration - stageTitleTimer
        local alpha = 1
        if remaining < stageTitleFadeTime then
            alpha = remaining / stageTitleFadeTime
        end

        alpha = clamp(alpha, 0, 1)
        if alpha <= 0 then return end

        love.graphics.setColor(0, 0, 0, alpha)
        love.graphics.rectangle("fill", 0, 0, base_width, base_height)
        love.graphics.setColor(1, 1, 1, 1)

        local enterProgress = clamp(stageTitleTimer / stageTitleFadeTime, 0, 1)
        local startX = -100
        local endX = (base_width - titleImg:getWidth()) / 2 - 60
        local slideX = lerp(startX, endX, linearTime(enterProgress))

        if remaining < stageTitleFadeTime then
            local exitProgress = 1 - (remaining / stageTitleFadeTime)
            slideX = lerp(endX, base_width + 130, linearTime(exitProgress))
        end

        local y = base_height / 2 - 40
        drawTitleCard(titleImg, circlesImg, actImg, slideX, y)
end

function drawShadowedText(text, x, y)
    love.graphics.setColor(0, 0, 0)
    love.graphics.print(text, x + 1, y + 1)
    love.graphics.setColor(1, 1, 0)
    love.graphics.print(text, x, y)
    love.graphics.setColor(1, 1, 1)
end

function drawLayer(img, speed)
    local iw = img:getWidth()
    bgOffsetX = bgOffsetX % iw
    local offset = bgOffsetX * speed
    love.graphics.draw(img, -offset, 0)
    love.graphics.draw(img, -offset + iw, 0)
end

function test_draw(camX, camY)
        sounds.buildUPSound:stop()
        sounds.green_hill:play()
        love.graphics.setColor(currentColor)
        --drawScrollingBG(emhi_bg, 0,0)
        drawLayer(emhi_bg, 1)
        love.graphics.setColor(1,1,1)

        love.graphics.push()
        love.graphics.translate(-camX, -camY)
        love.graphics.draw(loadMapImage("test2"), 0,0)
        if sonic_demoexe.currentSprite then love.graphics.draw(sonic_demoexe.currentSprite,10948,730) end
        tails_tail_thing()
        char_draw(tails,0,2)
        love.graphics.pop()

        drawStats()
        drawStageTitle(greenHillZoneTitle, greenHillZoneCircles, stageActImg1)
end

function hs_draw(camX, camY)
        love.graphics.push()
        if bushes_destroyed then love.graphics.draw(fire_bg.currentSprite,0,0) end
        love.graphics.translate(-camX, -camY)
        love.graphics.draw(loadMapImage("test3"),0,0)
        if not tails_caught2 and tails.currentSprite then
            tails_tail_thing()
            char_draw(tails,0,2)
        end
        for _,b in ipairs(bushes) do love.graphics.draw(bush_img,b.x,b.y) end
        char_draw(sonic_demoexe,0,2)
        love.graphics.pop()

        drawStats()
        if not bushes_destroyed then
            local text = string.format("HIDING TIME LEFT: %.1f", hs_timer)
            local w = Font:getWidth(text)
            drawShadowedText(text, base_width - w - 20, 30)
        end
        drawStageTitle(hideAndSeekZoneTitle, hideAndSeekZoneCircles, stageActImg2)

        if show_black_screen then
            love.graphics.setColor(0,0,0,1)
            love.graphics.rectangle("fill",0,0, base_width, base_height)
            love.graphics.setColor(1,1,1)
        end
end

function knuck_draw(camX, camY)
        love.graphics.push()
        drawScrollingBG(knuck_bg,0,0)
        love.graphics.translate(-camX,-camY)
        love.graphics.draw(loadMapImage("knuck1"))
        char_draw(knuckles,0,-2)
        if demo_vis then char_draw(sonic_demoexe,0,-2) end
        if stage1_vis then love.graphics.draw(s1.currentSprite, 2544, 518) end
        if stage2_vis and s1.currentSprite then love.graphics.draw(s1.currentSprite, 4387, 864) end
        if stage3_vis then love.graphics.draw(s1.currentSprite, 5481, 867) end

        local function checkStage(stageVis, soundFlag)
            if not stageVis and not _G[soundFlag] then
                sounds.sound_fix:play()
                flashScreen(0.45)
                _G[soundFlag] = true
            end
        end

        checkStage(stage1_vis, "soundPlayed10")
        checkStage(stage2_vis, "soundPlayed9")
        checkStage(stage3_vis, "soundPlayed8")

        if idk_fix and knuckles.x < 5991 then
            knuckles.x = 5991
            knuckles.velocity.x = math.max(0, knuckles.velocity.x)
        end
        love.graphics.pop()
        if bossfightActive then
            local text = string.format("TIME LEFT: %.1f", bossfightTimer)
            local w = Font:getWidth(text)
            drawShadowedText(text, base_width - w - 20, 30)
        end
        drawStats()
        drawStageTitle(greenHillZoneTitle, hideAndSeekZoneCircles, stageActImg1)

        if blackScreen then
            love.graphics.setColor(0,0,0,1)
            love.graphics.rectangle("fill",0,0, base_width, base_height)
        end
        love.graphics.setColor(1, 1, 1)
end

MenuImagesDamn2 = {}
MenuImagesDamn2[1] = love.graphics.newImage("images/background/gh/1.png")
MenuImagesDamn2[2] = love.graphics.newImage("images/background/gh/2.png")
MenuImagesDamn2[3] = love.graphics.newImage("images/background/gh/3.png")
MenuImagesDamn2[4] = love.graphics.newImage("images/background/gh/4.png")
MenuImagesDamn2[5] = love.graphics.newImage("images/background/gh/5.png")
MenuImagesDamn2[6] = love.graphics.newImage("images/background/gh/6.png")

function eggman_draw(camX, camY)
    if not crashing2 then 
        drawScrollingBG(MenuImagesDamn2[1], 0, 0)
        drawScrollingBG(MenuImagesDamn2[2], 5, 0)
        drawScrollingBG(MenuImagesDamn2[3], 0, 0)
        drawLayer(MenuImagesDamn2[4], 0.4)
        local palette = colorPalettes[colorCycleIndex]
        local colorMod = 1.0

        if palette then
                    local shader = love.graphics.newShader([[
                        extern vec3 color1;
                        extern vec3 color2;
                        extern vec3 color3;
                        extern vec3 color4;
                        extern float colorMod;

                        vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
                            vec4 pixel = Texel(tex, texture_coords);
                            vec3 c = pixel.rgb;
                            if (c.r > 0.58 && c.g < 0.2 && c.b > 0.4) {c = color1;
                            } else if (c.r >= 0.733 && c.g <= 0.2 && c.b >= 0.6) {c = color2;
                            } else if (c.r > 0.8 && c.g < 0.4 && c.b > 0.7) {c = color3;
                            } else if (c.r > 0.9 && c.g < 0.5 && c.b > 0.8) {c = color4;
                            }
                            c *= colorMod;
                            return vec4(c, pixel.a);
                        }
                    ]])

            shader:send("color1", palette[1])
            shader:send("color2", palette[2])
            shader:send("color3", palette[3])
            shader:send("color4", palette[4])
            shader:send("colorMod", colorMod)

            love.graphics.setShader(shader)
            drawLayer(MenuImagesDamn2[5], 0.25)
            drawLayer(MenuImagesDamn2[6], 0.75)
            love.graphics.setShader()
        else
            drawLayer(MenuImagesDamn2[5], 0.25)
            drawLayer(MenuImagesDamn2[6], 0.75)
        end
    end
        love.graphics.push()
        love.graphics.translate(-camX,-camY)
        love.graphics.draw(egg_mob,3200,903)
        love.graphics.draw(loadMapImage("gh1"),0,0)
        char_draw(sonic_demoexe,0,-2)
        char_draw(eggman,0,-8)
        love.graphics.pop()
        if not crashing2 then
            drawStats()
            drawStageTitle(greenHillZoneTitle, labCircles, stageActImg1)
        end
        if crashing and not crashing2 then
            love.graphics.setColor(1,1,1,crashAlpha)
            love.graphics.rectangle("fill",0,0,base_width,base_height)
        end
end

local transitionCanvas
if transitionCanvas then transitionCanvas:release() end
transitionCanvas = love.graphics.newCanvas(base_width, base_height)

function love.draw()
    love.graphics.setFont(Font)
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0,0,0,1)
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", 0, 0, base_width, base_height)
    love.graphics.setColor(1, 1, 1)
    local camX, camY = floor(camera.x + 0.5), floor(camera.y + 0.5)

    if gamestate == "menuscreen" or gamestate == "selection" then
        local mx, my = love.mouse.getPosition()
        local px = (max(0, min(base_width, (mx-offset_x)/scale_factor)) - base_width/2) * 0.05
        local py = (max(0, min(base_height, (my-offset_y)/scale_factor)) - base_height/2) * 0.05
        drawScrollingBG(menu_finished, px*0.5, py*0.4)
    end

    if gamestate == "menuscreen" then
        draw_menuscreen()
    elseif gamestate == "selection" then
        selection()
    elseif gamestate == "test" then
        test_draw(camX, camY)
    elseif gamestate == "hs" then
        hs_draw(camX, camY)
    elseif gamestate == "knuck" then
        knuck_draw(camX, camY)
    elseif gamestate == "eggman" then
        eggman_draw(camX, camY)
    elseif gamestate == "torture" and tort_visible then
        love.graphics.setColor(1,1,1,0.355)
        if sonic_demoexe_screen.currentSprite then
            love.graphics.draw(sonic_demoexe_screen.currentSprite)
        end
        love.graphics.setColor(1,1,1)
        local t = love.timer.getTime()
        love.graphics.print("Ready to be",125,50+sin(t*2)*2)
        love.graphics.print("Tortured?",285,200+sin(t*2.2)*3)
    elseif gamestate == "william" then
        draw_william()
        drawStageTitle(DotTitle, DotCircles, stageActImg1)
    elseif gamestate == "error" then
        love.graphics.clear(0,0,0,1)
        if reboot_vis and not rebootDone then
            for i=1,currentStage do
                local stageText = loadingStages[i]
                local text = i<currentStage and stageText.." 100%" or stageText.." "..floor(stageProgress).."%"
                love.graphics.print(text,20,20+(i-1)*20)
            end
        elseif rebootDone then
            love.graphics.setColor(0,0,0,fadeBlack)
            love.graphics.rectangle("fill",0,0,base_width,base_height)
            local t = love.timer.getTime()
            if fadeBlack>=1 then
                love.graphics.setFont(FontBig)
                love.graphics.setColor(0.045,0.045,0.045,helloFade)
                local text="HELLO WILLIAM."
                love.graphics.print(text, base_width/2-FontBig:getWidth(text)/2, base_height/2-FontBig:getHeight()/2+sin(t*2.2)*3)
            end
        elseif reboot_vis2 then
            love.graphics.setFont(FontBig)
            love.graphics.print("An Error has Occurred.",20,20)
        end
    elseif gamestate == "credits" then
        local xLeft = 50
        local xRight = 250
        local y = 50 - scrollY

        for i, c in ipairs(credits) do
            love.graphics.setColor(1, 1, 1)
            love.graphics.rectangle("line", xLeft, y, 150, 100, 0)
            love.graphics.draw(c.image, xLeft + 75 - c.image:getWidth()/2, y + 50 - c.image:getHeight()/2)
            love.graphics.rectangle("line", xRight, y, base_width - xRight - 50, 100)
            love.graphics.printf(c.name .. "\n" .. c.role, xRight + 10, y + 10, base_width - xRight - 70, "left")
            y = y + 120
        end
        fast.drawTextOutline("Press Enter to open the Document",base_width / 2 - 150,base_height - 40,{1,1,1,1},{0,0,0,1},2)
    elseif gamestate == "warning" then
        love.graphics.printf("WARNING!\nThis game contains flash light and can still be buggy at times...\nPress ENTER / Jump Button to play.",0,base_height/2-45,base_width,"center")
    elseif gamestate == "cheating" then
        love.graphics.setColor(1,1,1,cheating_alpha)
        if sonic_demoexe_screen.currentSprite and cheating_vis then
            love.graphics.draw(sonic_demoexe_screen.currentSprite)
        end
        love.graphics.setColor(1,1,1,cheating_alpha2)
        local t = love.timer.getTime()
        if cheating_vis2 then
            love.graphics.print("How dare you cheat within my realm, my game.",40,50+sin(t*2.5)*3)
            love.graphics.print("I won't let you escape from your fate that easily.",75,157+sin(t*2)*2)
        end
    elseif gamestate == "testmap" then
        love.graphics.push()
        love.graphics.translate(-camX,-camY)
        love.graphics.draw(loadMapImage("testmap"),0,0)
        char_draw(test_character,0,-2)
        love.graphics.pop()
        drawStats()
    end

    if transitionAlpha>0 then drawTransition(transitionAlpha) end
    if isFlashing then
        love.graphics.setColor(1,1,1,flashAlpha)
        love.graphics.rectangle("fill",0,0, base_width*2, base_height*2)
    end

    love.graphics.setColor(1, 1, 1, 1)
    if isMobile then mobile_stuff_draw() end
    drawDebug(activeChar)
    love.graphics.setCanvas()
    love.graphics.draw(canvas, offset_x, offset_y, 0, scale_factor, scale_factor)
end

function quantizeColor(r, g, b, levels)
    levels = levels or 4
    local step = 1 / (levels - 1)
    local qr = floor(r / step + 0.5) * step
    local qg = floor(g / step + 0.5) * step
    local qb = floor(b / step + 0.5) * step
    return qr, qg, qb
end
local lastColorLerp
function drawTransition(alpha)
    local levels = 4
    if transitioning or colorLerp ~= lastColorLerp then
        transitionCanvas:renderTo(function()
            love.graphics.clear()
            love.graphics.setColor(1, 1, 1)
            love.graphics.draw(canvas)
        end)
        lastColorLerp = colorLerp
    end
    local fromColor = transitioning and {1, 1, 1} or {0, 0, 1}
    local toColor   = transitioning and {0, 0, 1} or {1, 1, 1}
    local r = fromColor[1] + (toColor[1] - fromColor[1]) * colorLerp
    local g = fromColor[2] + (toColor[2] - fromColor[2]) * colorLerp
    local b = fromColor[3] + (toColor[3] - fromColor[3]) * colorLerp
    local qr, qg, qb = quantizeColor(r, g, b, levels)
    love.graphics.setBlendMode("multiply", "premultiplied")
    love.graphics.setColor(qr, qg, qb)
    love.graphics.draw(transitionCanvas)
    love.graphics.setBlendMode("alpha")
    if alpha > 0 then
        love.graphics.setColor(0, 0, 0, alpha)
        love.graphics.rectangle("fill", 0, 0, base_width, base_height)
    end

    love.graphics.setColor(1, 1, 1)
end

function drawStats()
    local x, y = 10, 10
    love.graphics.draw(images.score, x, y)
    drawNumberString(x + 100, y - 1, stats.score)
    local minutes = floor(gameTime / 60)
    local seconds = floor(gameTime % 60)
    local timeStr
    if seconds < 10 then
        timeStr = minutes .. ":0" .. seconds
    else
        timeStr = minutes .. ":" .. seconds
    end
    love.graphics.draw(images.time, x, y + 16)
    drawNumberString(x + 50, y + 15, timeStr)
    love.graphics.draw(
        images.rings,
        quads.rings[ringAnimState and "top" or "bottom"],
        x, y + 32
    )
    drawNumberString(x + 75, y + 31, stats.rings)
    love.graphics.draw(images.william, x, 225)
end

function love.keyreleased(key)
    if gamestate == "selection" then
        if key == "right" then
          selectionIndex = min(#selectionOptions, selectionIndex + 1)
          sounds.reboot_old:play()
        elseif key == "left" then
          selectionIndex = max(1, selectionIndex - 1)
          sounds.reboot_old:play()
        end
    end
end

function safeRelease(resource)
    if resource and resource.release then
        resource:release()
    end
end

function love.resize(w, h)
    if canvas then
        safeRelease(canvas)
    end
    canvas = love.graphics.newCanvas(base_width, base_height)
    updateCanvasScale()
    resizeFreezeTimer = 0.5
end

function updateCanvasScale()
    local window_width, window_height = love.graphics.getDimensions()
    local scale_x = window_width / base_width
    local scale_y = window_height / base_height

    scale_factor = min(scale_x, scale_y)

    local scaled_width = base_width * scale_factor
    local scaled_height = base_height * scale_factor

    offset_x = floor((window_width - scaled_width) / 2 + 0.5)
    offset_y = floor((window_height - scaled_height) / 2 + 0.5)

    offset_x = max(0, offset_x)
    offset_y = max(0, offset_y)

    if transitionCanvas then
        safeRelease(transitionCanvas)
    end
    transitionCanvas = love.graphics.newCanvas(base_width, base_height)
end

local cameraTouchID = nil
local joystickTouchID = nil
local lastTouchX, lastTouchY = nil, nil

function normalizeCoords(x, y)
    return (x - offset_x) / scale_factor, (y - offset_y) / scale_factor
end

function updateJoystick(x, y)
    local dx, dy = x - joystick.x, y - joystick.y
    local len = dx * dx + dy * dy
    local maxDist = joystick.radius
    if len > maxDist * maxDist and len > 0 then
        local scale = maxDist / math.sqrt(len)
        dx, dy = dx * scale, dy * scale
    end
    joystick.dx, joystick.dy = dx / maxDist, dy / maxDist
end

function love.touchpressed(id, x, y)
    if not isMobile then return end

    x, y = normalizeCoords(x, y)
    touches[id] = {x=x, y=y}

    if x <= base_width * 0.5 then
        if not joystickTouchID then
            joystickTouchID = id
            joystick.active = true
            updateJoystick(x, y)
        end
        return
    end

    if not cameraTouchID and gamestate == "william" then
        cameraTouchID = id
        lastTouchX, lastTouchY = x, y
    else
        jumpButton.active = true
    end
end

function love.touchmoved(id, x, y)
    if not isMobile or not touches[id] then return end

    x, y = normalizeCoords(x, y)
    touches[id].x, touches[id].y = x, y

    if id == joystickTouchID and joystick.active then
        updateJoystick(x, y)
    elseif id == cameraTouchID and gamestate == "william" then
        local dx, dy = x - lastTouchX, y - lastTouchY
        targetYaw   = targetYaw - dx * mouseSensitivity
        targetPitch = math.max(-math.pi*0.5, math.min(math.pi*0.5, targetPitch + dy * mouseSensitivity))
        targetRoll  = math.max(-0.15, math.min(0.15, -dx * rollStrength))
        lastTouchX, lastTouchY = x, y
    end
end

function love.touchreleased(id, x, y)
    if not isMobile then return end
    touches[id] = nil

    if id == joystickTouchID then
        joystickTouchID = nil
        joystick.active = false
        joystick.dx, joystick.dy = 0, 0
    elseif id == cameraTouchID and gamestate == "william" then
        cameraTouchID, lastTouchX, lastTouchY = nil, nil, nil
    end
    local rightSideTouch = false
    for _, t in pairs(touches) do
        if t.x and t.x > base_width * 0.5 then
            rightSideTouch = true
            break
        end
    end
    jumpButton.active = rightSideTouch
end

function quantize(v)
    if abs(v) < 0.25 then
        return 0
    elseif v > 0 then
        return 1
    else
        return -1
    end
end

function love.quit()
    fast.clearAll()
end