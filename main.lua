local love = require("love")
love.graphics.setDefaultFilter("nearest", "nearest")

local spritesFolder = "images/sprites/"
local stats = {score = 0, rings = 0}
local gameTime = 0
local gamestate = "test"

local ok, discord = pcall(require, "ffi/discord")
local startTime = os.time()

local isMobile = false
local os_device = love.system.getOS()
if os_device == "Android" or os_device == "iOS" then
    isMobile = true
end

gravity = 600

local base_width, base_height = 500, 250
local thing = 650
local camera = {x = 0, y = 0}
local camera_3d = {x = thing / 2, y = 5, z = thing / 2, yaw = 0, pitch = 0, roll = 0}
local chaser = {x = -200, y = 0, z = -200, speed = 23}

local moveSpeed, mouseSensitivity = 8, 0.002
local walkTime = 0

local canvas
scale_factor = 1
offset_x = 0
offset_y = 0

rebooting_Vis = false
rebootingTimer = 0
lastPlayedCycle = -1

local ringAnimState = true
local ringAnimTimer = 0
local ringAnimSpeed = 0.2
local characterOffsetX = 0

local tails_alive = true
local knuckles_alive = true
local eggman_alive = true

local tails_lock = true
local knuckles_lock = false
local eggman_lock = false

local idk_img = love.graphics.newImage("images/idk.png")
local chase_img = love.graphics.newImage("images/chase.png")
local bush_img = love.graphics.newImage("images/bush.png")
local egg_mob = love.graphics.newImage("images/egg_mob.png")

knuck_bg = love.graphics.newImage("images/background/knuck.png")
knuck_bg2 = love.graphics.newImage("images/background/knuck2.png")
knuck_bg3 = love.graphics.newImage("images/background/knuck3.png")

local selection_box = love.graphics.newImage("images/selection/box.png")
local tails_selection = love.graphics.newImage("images/selection/tails_selection.png")
local knuck_selection = love.graphics.newImage("images/selection/knuckles_selection.png")
local eggman_selection = love.graphics.newImage("images/selection/eggman_selection.png")

local dead_tails = love.graphics.newImage("images/selection/dead_tails.png")
local dead_knuckles = love.graphics.newImage("images/selection/dead_knuckles.png")
local dead_eggman = love.graphics.newImage("images/selection/dead_eggman.png")

local test2 = love.graphics.newImage("images/maps/test2.png")
local test3 = love.graphics.newImage("images/maps/map1.png")
local knuck1 = love.graphics.newImage("images/maps/knuck1.png")
local gh1 = love.graphics.newImage("images/maps/gh1.png")

lockImg = love.graphics.newImage("images/lock.png")

Font = love.graphics.newFont("font/font.ttf", 16)
FontBig = love.graphics.newFont("font/font.ttf", 32)
Font2 = love.graphics.newFont("font/sonicdebugfont.ttf", 12)
Font3 = love.graphics.newFont("font/sonicfont.ttf", 32)
Font4 = love.graphics.newFont("font/font2.ttf", 16)

local soundDefs = {
    sonic_theme = "music/sonic_theme.ogg",
    intro_1990 = "music/intro_1990.mp3",
    green_hill = "music/Green_Hill.ogg",
    rebootSound = "sounds/reboot.ogg",
    flames = "sounds/flames.ogg",
    buildUPSound = "sounds/buildUP.ogg",
    denySound = "sounds/deny.ogg",
    hitStaticSound = "sounds/hitStatic.ogg",
    enterSound = "sounds/enter.ogg",
    walking_on_metalSound = "sounds/walking_on_metal.mp3",
    reboot_old = "sounds/reboot_old.ogg",
    metalSound = "sounds/metal.ogg",
    bossMusic = "music/boss.ogg",
    tails_stage = "music/tails_stage.ogg",
    demo_song = "music/demo_song.ogg",
    glitch_sound = "sounds/glitch_sound.mp3",
    jump_sound = "sounds/jump_sound.mp3",
    torture_sound = "sounds/torture.mp3",
    laugh_sound = "sounds/laugh.mp3",
    S3K_9A = "sounds/S3K_9A.wav",
    lights_off = "sounds/lights-sound-effect.mp3",
    error_sound = "sounds/error_sound.mp3"
}

local sounds = {}

for name, path in pairs(soundDefs) do
    sounds[name] = love.audio.newSource(path, "static")
end

local images = {}
local quads = {}
selectionState = "tails"
selectionIndex = 1
selectionOptions = {"tails", "knuckles", "eggman"}

local function loadMap(imagePath)
    local img = love.graphics.newImage(imagePath)
    local imageData = love.image.newImageData(imagePath)
    local w, h = imageData:getDimensions()
    local collision = {}

    imageData:mapPixel(function(x, y, r, g, b, a)
        collision[y] = collision[y] or {}
        collision[y][x] = a > 0.1
        return r, g, b, a
    end)

    return {
        image = img,
        collision = collision,
        width = w,
        height = h
    }
end

map  = loadMap("images/maps/test.png")
map1 = loadMap("images/maps/map2.png")
map2 = loadMap("images/maps/knuck2.png")
map3 = loadMap("images/maps/gh2.png")

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
        jumpHeight = -350,
        acceleration = 100,
        maxSpeed = opts.maxSpeed or 175,
        friction = 2,
        onGroundY = 0,
        isDead = false,
        fallTimer = 0,
        jumpSpeed = 100,
        fallSpeed = 100,
        isPresent = true,
        angle = 0,
        visible = true,
        runThreshold = opts.runThreshold or 175,
        lastGroundedY = 0,
        spriteIndex = 1,
        currentSprite = nil,
        startedChase = false,
        randomJumpTimer = 0,
    }
end

local chunkSize, renderDistance = 4, 24
leftwImage = love.graphics.newImage("images/arrows/leftw.png")
rightwImage = love.graphics.newImage("images/arrows/rightw.png")

flashAlpha = 0
flashDuration = 0.5
flashTimer = 0
local isFlashing = false

function flashScreen(duration)
    flashAlpha = 1
    flashDuration = duration or 0.5
    flashTimer = flashDuration
    isFlashing = true
end

local function loadFrames(basePath, count)
    local frames = {}
    for i = 1, count do
        frames[i] = love.graphics.newImage(basePath .. i .. ".png")
    end
    return frames
end

local transitionAlpha = 1
local transitioning = false
local transitionTarget = ""
local transitionSpeed = 1.5

function startTransition(target)
  transitioning = true
  transitionTarget = target
end

stage1 = love.graphics.newImage(spritesFolder.."sonic_demo.exe/anim/knuckles/stage1.png")
stage1_vis = true
local s1 = createCharacter{x = 100, y = 50}
s1.stage2 = loadFrames(spritesFolder .. "sonic_demo.exe/anim/knuckles/stage2/", 2)
stage2_vis = true
stage3 = love.graphics.newImage(spritesFolder.."sonic_demo.exe/anim/knuckles/stage3.png")
stage3_vis = true

local tails = createCharacter{ x = 100, y = 50, maxSpeed = 200 }
tails.idle = love.graphics.newImage(spritesFolder .. "tails/idle.png")
tails.down = love.graphics.newImage(spritesFolder .. "tails/down/1.png")
tails.walk = loadFrames(spritesFolder .. "tails/walking/", 8)
tails.jump = loadFrames(spritesFolder .. "tails/jump/", 3)
tails.run = loadFrames(spritesFolder .. "tails/run/", 2)

local knuckles = createCharacter{ x = 100, y = 50, maxSpeed = 400 }
knuckles.idle = love.graphics.newImage(spritesFolder .. "knuckles/idle.png")
knuckles.walk = loadFrames(spritesFolder .. "knuckles/walking/", 7)
knuckles.run = loadFrames(spritesFolder .. "knuckles/run/", 4)
knuckles.jump = loadFrames(spritesFolder .. "knuckles/jump/", 5)
knuckles.wait = loadFrames(spritesFolder .. "knuckles/confused/", 2)

local eggman = createCharacter{ x = 3300, y = 50, maxSpeed = 140 }
eggman.idle = love.graphics.newImage(spritesFolder .. "eggman/idle.png")
eggman.walk = loadFrames(spritesFolder .. "eggman/walking/", 3)
eggman.run = loadFrames(spritesFolder .. "eggman/walking/", 3)
eggman.jump = loadFrames(spritesFolder .. "eggman/walking/", 1)

local sonic_demoexe = createCharacter{x = -100, y = -140 }
sonic_demoexe.idle = love.graphics.newImage(spritesFolder .. "sonic_demo.exe/idle.png")
sonic_demoexe.crouch = love.graphics.newImage(spritesFolder .. "sonic_demo.exe/crouch.png")
sonic_demoexe.anim_tails = loadFrames(spritesFolder .. "sonic_demo.exe/anim/tails/", 8)
sonic_demoexe.float = loadFrames(spritesFolder .. "sonic_demo.exe/float/", 2)
sonic_demoexe.jump = loadFrames(spritesFolder .. "sonic_demo.exe/jump/", 5)
sonic_demoexe.run = loadFrames(spritesFolder .. "sonic_demo.exe/run/", 4)
sonic_demoexe.walk = loadFrames(spritesFolder .. "sonic_demo.exe/walk/", 6)
sonic_demoexe.fly = loadFrames(spritesFolder .. "sonic_demo.exe/fly/fly", 2)
sonic_demoexe.kill_tails = loadFrames(spritesFolder .. "sonic_demo.exe/kill/test/", 7)

local fire_bg = createCharacter{}
fire_bg.idle = loadFrames("images/background/fire/", 3)

local sonic_demoexe_screen = createCharacter{x = 0, y = 355}
sonic_demoexe_screen.idle = love.graphics.newImage(spritesFolder .. "screen/idle.png")

local tail_tails = {
    x = 100,
    y = 50,
    width = 32,
    height = 32
}
tail_tails.idle = loadFrames(spritesFolder .. "tail/", 5)

local menuShrink = 1
local menuAlpha = 1
local shrinkingMenu = false
local selectionScale = 3
local selectionAlpha = 0

local frames = loadFrames(spritesFolder .. "menuscreen/", 6)
local repeatable_frames = loadFrames(spritesFolder .. "menuscreen/repeatble/", 2)
local repeatable2_frames = loadFrames(spritesFolder .. "menuscreen/repeatble2/", 2)

local splash_frames = {}
splash_frames.splash = loadFrames(spritesFolder .. "menuscreen/splash2/", 13)
splash_frames.idle = loadFrames(spritesFolder .. "menuscreen/play/", 6)

function initCharacterSprite(character, defaultSprite)
    character.currentSprite = defaultSprite
    character.spriteIndex = 1
    return character
end

function initArraySprite(character, spriteArray)
    character.spriteIndex = 1
    character.currentSprite = spriteArray[math.floor(character.spriteIndex)]
    return character
end

tails = initCharacterSprite(tails, tails.idle)
knuckles = initCharacterSprite(knuckles, knuckles.idle)
eggman = initCharacterSprite(eggman, eggman.idle)
tail_tails = initArraySprite(tail_tails, tail_tails.idle)
sonic_demoexe = initCharacterSprite(sonic_demoexe, sonic_demoexe.idle)
sonic_demoexe_screen = initCharacterSprite(sonic_demoexe_screen, sonic_demoexe_screen.idle)
s1 = initArraySprite(s1, s1.stage2)

title = love.graphics.newImage(spritesFolder .. "menuscreen/title.png")
circle = love.graphics.newImage(spritesFolder .. "menuscreen/circle.png")
smth = love.graphics.newImage("images/segamenu.png")

local colorTL = {0x42/255, 0x5B/255, 0x1D/255, 1}
local colorTR = {0xA2/255, 0xA0/255, 0x20/255, 1}

local targetYaw, targetPitch = 0, 0

local function createBaseplate(w, d)
    local tiles, idx = {}, 0
    for z = 0, d - 1 do
        local zPos = z
        for x = 0, w - 1 do
            local col = ((x + z) % 2 == 0) and colorTL or colorTR
            idx = idx + 1
            local xPos = x
            tiles[idx] = {
                {xPos, 0, zPos,col},
                {xPos + 1, 0, zPos, col},
                {xPos + 1, 0, zPos + 1, col},
                {xPos, 0, zPos + 1, col}
            }
        end
    end
    return tiles
end

local credits_text = {}
local credits_y = 0
local line_height = 20
local message_alpha = 0

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
    radius = 50,
    active = false
}

joystickBaseImage = love.graphics.newImage("images/mobile_stuff/base.png")
joystickKnobImage = love.graphics.newImage("images/mobile_stuff/knob.png")
jumpButtonImage = love.graphics.newImage("images/mobile_stuff/jump.png")

function love.load()
    love.window.setMode(base_width * SCALE, base_height * SCALE, {
        fullscreen = false,
        resizable = false,
        vsync = true,
        highdpi = true,
    })
    love.window.setTitle("SONIC 2 3 1")
    love.window.setIcon(love.image.newImageData("images/game_icon.png"))
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
    images.score = love.graphics.newImage("images/stats/score.png")
    images.time = love.graphics.newImage("images/stats/time.png")
    images.rings = love.graphics.newImage("images/stats/rings.png")
    images.numbers = love.graphics.newImage("images/stats/numbers.png")
    images.william = love.graphics.newImage("images/stats/live.png")

    quads.numbers = {}
    local w, h = images.numbers:getDimensions()
    for i = 0, 9 do
        quads.numbers[i] = love.graphics.newQuad(i * 7, 0, 7, 11, w, h)
    end

    local rw, rh = images.rings:getDimensions()
    quads.rings = {
        top = love.graphics.newQuad(0, 0, 40, 16, rw, rh),
        bottom = love.graphics.newQuad(0, 16, 40, 16, rw, rh),
    }

    startTime = love.timer.getTime()
    freezeScreen = false

    startTime = love.timer.getTime()

    baseplateTiles = createBaseplate(thing, thing)

    local file_content = love.filesystem.read("credits.txt")
    if file_content then
        for line in file_content:gmatch("[^\n]+") do
            table.insert(credits_text, line)
        end
    else
        table.insert(credits_text, "No credits file")
    end
    credits_y = base_height
end

function clamp(val, minVal, maxVal)
    return math.max(minVal, math.min(maxVal, val))
end

function lerp(a, b, t)
    return a + (b - a) * t
end

local function dist2(a, b)
    local dx, dy, dz = a.x-b.x, a.y-b.y, a.z-b.z
    return dx*dx + dy*dy + dz*dz
end

local velX, velZ = 0, 0
local bobAmount = 0
local targetRoll = 0
local rollStrength = 0.02
local rollReturnSpeed = 5

function william_update(dt)
    local smoothSpeed = 8
    camera_3d.yaw = camera_3d.yaw + (targetYaw - camera_3d.yaw) * math.min(dt * smoothSpeed, 1)
    camera_3d.pitch = camera_3d.pitch + (targetPitch - camera_3d.pitch) * math.min(dt * smoothSpeed, 1)
    camera_3d.roll = camera_3d.roll + (targetRoll - camera_3d.roll) * math.min(dt * rollReturnSpeed, 1)
    targetRoll = targetRoll + (0 - targetRoll) * math.min(dt * rollReturnSpeed, 1)
    local inputX, inputZ = 0, 0
    if love.keyboard.isDown("w") or joystick.dy < -0.2 then inputZ = inputZ + 1 end
    if love.keyboard.isDown("s") or joystick.dy > 0.2 then inputZ = inputZ - 1 end
    if love.keyboard.isDown("a") or joystick.dx > 0.2 then inputX = inputX - 1 end
    if love.keyboard.isDown("d") or joystick.dx < -0.2 then inputX = inputX + 1 end
    local len = inputX*inputX + inputZ*inputZ
    if len > 0 then
        len = 1 / math.sqrt(len)
        inputX, inputZ = inputX * len, inputZ * len
    end

    local accel = math.min(dt * 12, 1)
    velX = velX + (inputX * moveSpeed - velX) * accel
    velZ = velZ + (inputZ * moveSpeed - velZ) * accel

    if math.abs(velX) > 0.01 or math.abs(velZ) > 0.01 then
        walkTime = walkTime + dt * 10
        bobAmount = bobAmount + ((math.sin(walkTime) * 0.1) - bobAmount) * dt * 8
    else
        bobAmount = bobAmount - bobAmount * dt * 8
    end
    camera_3d.y = 5 + bobAmount

    local sy, cy = math.sin(camera_3d.yaw), math.cos(camera_3d.yaw)
    camera_3d.x = camera_3d.x + (velX * cy - velZ * sy) * dt
    camera_3d.z = camera_3d.z + (velX * sy + velZ * cy) * dt

    local dx, dy, dz = camera_3d.x - chaser.x, camera_3d.y - chaser.y, camera_3d.z - chaser.z
    local distSq = dx*dx + dy*dy + dz*dz
    if distSq > 0.01 then
        local dist = math.sqrt(distSq)
        local speedFactor = 1 + math.max(0, (20 - dist) / 20) * 2
        local lerpAmt = dt * 4
        local targetVx = dx / dist * chaser.speed * speedFactor
        local targetVy = dy / dist * chaser.speed * speedFactor
        local targetVz = dz / dist * chaser.speed * speedFactor
        chaser.vx = (chaser.vx or 0) + (targetVx - (chaser.vx or 0)) * lerpAmt
        chaser.vy = (chaser.vy or 0) + (targetVy - (chaser.vy or 0)) * lerpAmt
        chaser.vz = (chaser.vz or 0) + (targetVz - (chaser.vz or 0)) * lerpAmt

        chaser.x = chaser.x + chaser.vx * dt
        chaser.y = chaser.y + chaser.vy * dt
        chaser.z = chaser.z + chaser.vz * dt
    end
    if distSq < 1 then
        gamestate = "game_over"
    end
end

local function inRenderDistance(tile)
    local dx, dz = tile[1][1]-camera_3d.x, tile[1][3]-camera_3d.z
    local maxDist = renderDistance
    return dx*dx + dz*dz <= maxDist*maxDist
end

function love.mousemoved(x, y, dx, dy)
    targetYaw = targetYaw - dx * mouseSensitivity
    targetPitch = math.max(-math.pi/2, math.min(math.pi/2, targetPitch + dy * mouseSensitivity))
    targetRoll = math.max(-0.15, math.min(0.15, -dx * rollStrength))
end

local function easeInOutCubic(t)
    return t < 0.5 and 4 * t * t * t or 1 - math.pow(-2 * t + 2, 3) / 2
end

local function easeOutCubic(t)
    return 1 - (1 - t)^3
end

local function isSolidPixel(x, y, map)
    local tx = math.floor(x)
    local ty = math.floor(y)

    if tx < 0 or ty < 0 or tx >= map.width or ty >= map.height then
        return false
    end

    if map.collision[ty] and map.collision[ty][tx] then
        return true
    end

    return false
end

local function isPassThroughTile(x, y)
    return false
end

local MAX_STEP_HEIGHT = 10

local function checkCollision(char, map, x, y, ignoreBelow)
    local left = math.floor(x - char.width / 2)
    local right = math.floor(x + char.width / 2 - 1)
    local top = math.floor(y - char.height / 2)
    local bottom = math.floor(y + char.height / 2 - 1)

    for ty = top, bottom do
        for tx = left, right do
            if isSolidPixel(tx, ty, map) then
                if ignoreBelow and ty >= bottom then
                    if isPassThroughTile(tx, ty) then
                    else
                        return true
                    end
                else
                    return true
                end
            end
        end
    end
    return false
end

local function updateSprite(dt, spriteTable, char)
    char.spriteIndex = char.spriteIndex + dt * 10
    if char.spriteIndex >= #spriteTable + 1 then
        char.spriteIndex = 1
    end
    char.currentSprite = spriteTable[math.floor(char.spriteIndex)] or spriteTable[1]
end

local sonic_demoexe_triggered = false
local sonic_demoexe_animating = false
local sonic_demoexe_wait_timer = 0

local currentColor = {1, 1, 1}
local targetColor = {1, 1, 1}
local lerpSpeed = 5

local function before_idk(dt)
    if tails.x < 10695 then
        sonic_demoexe.currentSprite = sonic_demoexe.anim_tails[1]
    end
    if not sonic_demoexe_triggered and math.floor(tails.x) >= 10695 then
        sonic_demoexe_triggered = true
        sonic_demoexe_animating = true
        sonic_demoexe.spriteIndex = 1
        sonic_demoexe.currentSprite = sonic_demoexe.anim_tails[1]
    end
    if sonic_demoexe_animating then
        sonic_demoexe.spriteIndex = sonic_demoexe.spriteIndex + dt * 10
        if sonic_demoexe.spriteIndex >= #sonic_demoexe.anim_tails + 1 then
            sonic_demoexe.spriteIndex = #sonic_demoexe.anim_tails
            sonic_demoexe_animating = false
            sonic_demoexe_wait_timer = 0.1
        else
            sonic_demoexe.currentSprite = sonic_demoexe.anim_tails[math.floor(sonic_demoexe.spriteIndex)]
        end
    end
    if sonic_demoexe_wait_timer > 0 then
        sonic_demoexe_wait_timer = sonic_demoexe_wait_timer - dt
        if sonic_demoexe_wait_timer <= 0 then
            gamestate = "torture"
        end
    end

    if tails.x >= 10000 then
        targetColor = {0.1, 0.1, 0.1}
        sounds.green_hill:stop()
    elseif tails.x >= 8260 then
        targetColor = {0.25, 0.25, 0.25}
        sounds.green_hill:setPitch(0.5)
    elseif tails.x >= 4800 then
        targetColor = {0.5, 0.5, 0.5}
        sounds.green_hill:setPitch(0.75)
    else
        targetColor = {1, 1, 1}
        sounds.green_hill:setPitch(1)
    end
    for i = 1, 3 do
        currentColor[i] = lerp(currentColor[i], targetColor[i], lerpSpeed * dt)
    end
end

tort_visible = false
tort_visible2 = false
tort_time = 0
local soundPlayed = false

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
        startTransition("hs")
    end
end

function getControls()
    local moveRight = love.keyboard.isDown("right") or joystick.dx > 0.2
    local moveLeft = love.keyboard.isDown("left")  or joystick.dx < -0.2
    local jump = love.keyboard.isDown("space") or jumpButton.active
    local lookUp = love.keyboard.isDown("up") or (joystick.dy < -0.25 and not jump)
    local lookDown = love.keyboard.isDown("down") and not jump or (joystick.dy > 0.25 and not jump)
    local fallThroughInput = love.keyboard.isDown("down") and jump or (joystick.dy > 0.25 and jump)

    return moveRight, moveLeft, jump, lookUp, lookDown, fallThroughInput
end

local crashing = false
local crashTimer = 0
local crashDuration = 4
local crashAlpha = 0
local crashMaxAlpha = 0.5
local fadeDuration = 0.25

local function getGroundAngle(char, map)
    local sampleDist = 6
    local yLeft, yRight = char.y, char.y

    for i = 0, MAX_STEP_HEIGHT + 5 do
        if not checkCollision(char, map, char.x - sampleDist, char.y - i) then
            yLeft = char.y - i
            break
        end
    end

    for i = 0, MAX_STEP_HEIGHT + 5 do
        if not checkCollision(char, map, char.x + sampleDist, char.y - i) then
            yRight = char.y - i
            break
        end
    end

    local dy = yRight - yLeft
    local dx = sampleDist * 2

    if math.abs(dy) <= 6 then
        dy = 0
    end

    local angle = math.atan2(dy, dx)
    return angle, dy
end

local function quantizeAngle(angle)
    local deg = math.deg(angle)
    if deg > 22.5 then
        deg = 45
    elseif deg < -22.5 then
        deg = -45
    else
        deg = 0
    end
    return math.rad(deg)
end

local function test_update(dt, char, map)
    local mapWidth  = map.width  or 2000
    local mapHeight = map.height or 1080
    local smoothFactor = 0.085
    
    if char ~= sonic_demoexe then
        local targetX = clamp(char.x - base_width / 2, 0, mapWidth - base_width)
        local targetY = clamp(char.y - base_height / 2 - 30, 0, mapHeight - base_height)
        camera.x = lerp(camera.x, targetX, smoothFactor)
        camera.y = lerp(camera.y, targetY, smoothFactor)
    end

    if not char.grounded then
        char.velocity.y = char.velocity.y + gravity * dt
    end

    if tail_tails.idle then
        updateSprite(dt * 0.5, tail_tails.idle, tail_tails)
    end

    local moveRight, moveLeft, jump, lookUp, lookDown, fallThroughInput = getControls()
    char.inputLeft, char.inputRight = moveLeft, moveRight

    if char ~= sonic_demoexe then
        if char.grounded and (lookUp or lookDown) then
            char.velocity.x = 0
            char.spriteIndex = 1
            char.currentSprite = lookUp and (char.up or char.idle) or (char.down or char.idle)
            char.angle = 0
            return
        end

        if moveRight or moveLeft then
            local dir = moveRight and 1 or -1
            char.direction = dir
            char.velocity.x = clamp(char.velocity.x + dir * char.acceleration * dt, -char.maxSpeed, char.maxSpeed)

            if char.jumping then
                updateSprite(dt, char.jump, char)
                char.angle = 0
            elseif math.abs(char.velocity.x) >= char.runThreshold then
                updateSprite(dt, char.run, char)
            else
                updateSprite(dt, char.walk, char)
            end
        else
            char.velocity.x = char.velocity.x * 0.85
            if math.abs(char.velocity.x) <= 2 then
                char.velocity.x = 0
                if not char.jumping then
                    char.spriteIndex = 1
                    char.currentSprite = char.idle
                    char.angle = 0
                else
                    updateSprite(dt, char.jump, char)
                end
            else
                updateSprite(dt, char.jumping and char.jump or char.walk, char)
            end
        end

        if jump and char.grounded and not fallThroughInput then
            char.velocity.y = char.jumpHeight
            char.spriteIndex = 1
            updateSprite(dt, char.jump, char)
            char.jumping = true
            char.grounded = false
            sounds.jump_sound:play()
        end
    end

    if char.grounded then
        local rawAngle, dy = getGroundAngle(char, map)
        local angle = quantizeAngle(rawAngle)
        char.angle = angle

        if math.abs(char.velocity.x) >= char.runThreshold and math.abs(math.deg(angle)) >= 80 then
            char.velocity.y = 0
            char.y = char.y - char.velocity.x * dt * (char.direction or 1)
            if not checkCollision(char, map, char.x, char.y - 1) then
                char.velocity.y = char.jumpHeight
                char.jumping = true
                char.grounded = false
                sounds.jump_sound:play()
            end
        elseif dy ~= 0 then
            char.y = char.y + dy * 0.5
        end
    end

    local nextX = char.x + char.velocity.x * dt
    local nextY = char.y + char.velocity.y * dt

    if not checkCollision(char, map, nextX, char.y) then
        char.x = nextX
    else
        local stepped = false
        for step = 1, MAX_STEP_HEIGHT do
            if not checkCollision(char, map, nextX, char.y - step) then
                char.x = nextX
                char.y = char.y - step
                stepped = true
                break
            end
        end
        if not stepped then char.velocity.x = 0 end
    end
    local function applyVertical(nextY, fallThrough)
        if not checkCollision(char, map, char.x, nextY, fallThrough) then
            char.y = nextY
            char.grounded = false
        else
            if char.velocity.y < 0 then
                char.velocity.y = 0
                char.jumping = true
                char.grounded = false
                char.y = char.y + 1
            else
                local foundGround = false
                for i = 0, MAX_STEP_HEIGHT do
                    if not checkCollision(char, map, char.x, nextY - i, fallThrough) then
                        char.y = nextY - i
                        char.velocity.y = 0
                        char.grounded = true
                        char.jumping = false
                        foundGround = true
                        break
                    end
                end
                if not foundGround then
                    char.velocity.y = 0
                    char.grounded = true
                    char.jumping = false
                end
            end
        end
    end

    if fallThroughInput then
        applyVertical(nextY, true)
    else
        applyVertical(nextY, false)
    end
    if char.grounded then
        local yDiff = math.abs(char.y - (char.lastGroundedY or char.y))
        if yDiff <= 1 then
            char.y = char.lastGroundedY or char.y
        else
            char.lastGroundedY = char.y
        end
    else
        char.lastGroundedY = char.y
    end
    if char.x < 15 then
        char.x = 15
        char.velocity.x = math.max(0, char.velocity.x)
    elseif char.x > mapWidth - 15 then
        char.x = mapWidth - 15
        char.velocity.x = math.min(0, char.velocity.x)
    end

    if char ~= sonic_demoexe and char.y >= mapHeight + 40 then
        love.event.quit()
    end

    updateGamestate(dt, char)
end

function math.sign(x)
    return (x > 0 and 1) or (x < 0 and -1) or 0
end

local hs_timer = 7
local hs_totalTime = 0
local tails_hiding = false
local tails_caught = false
local bushes_destroyed = false
local hide_sound_played = false
local bushes = {
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

function knuck_up(dt)
    updateSprite(dt * 0.5, s1.stage2, s1)

    if not demo_vis then
        sonic_demoexe.currentSprite = sonic_demoexe.crouch
        sonic_demoexe.x = 6453
        sonic_demoexe.y = 772
        sonic_demoexe.direction = -1
    end

    if knuckles.x >= 2400 then stage1_vis = false end
    if knuckles.x >= 4250 then
        stage2_vis = false
        knuck_bg = knuck_bg2
        demo_vis = true
    end
    if knuckles.x >= 5350 then
        stage3_vis = false
        knuck_bg = knuck_bg3
    end

    if knuckles.x > 5990 then
        idk_fix = true
    end

    if knuckles.x > 5990 then
        waiting_knuck = waiting_knuck + dt

        if waiting_knuck >= 3 then
            if sonic_demoexe.x > 6484 then
                sonic_demoexe.direction = -1
            elseif sonic_demoexe.x < 5993 then
                sonic_demoexe.direction = 1
            end

            if math.random() < 0.002 then
                if knuckles.x > sonic_demoexe.x then
                    sonic_demoexe.direction = 1
                else
                    sonic_demoexe.direction = -1
                end
            end

            if sonic_demoexe.direction ~= previousDirection then
                demo_speed = math.random(375, 400)
                previousDirection = sonic_demoexe.direction
            end

            if not demo_speed then demo_speed = 380 end

            local accel = 800
            local targetSpeed = demo_speed * sonic_demoexe.direction

            jumpTimer = jumpTimer + dt
            if jumpTimer >= jumpInterval and not sonic_demoexe.jumping then
                jumpTimer = 0
                if math.random() <= 0.4 then
                    sonic_demoexe.velocity.y = sonic_demoexe.jumpHeight
                    sonic_demoexe.jumping = true
                    sonic_demoexe.grounded = false
                end
            end

            if sonic_demoexe.velocity.x < targetSpeed then
                sonic_demoexe.velocity.x = math.min(sonic_demoexe.velocity.x + accel * dt, targetSpeed)
            elseif sonic_demoexe.velocity.x > targetSpeed then
                sonic_demoexe.velocity.x = math.max(sonic_demoexe.velocity.x - accel * dt, targetSpeed)
            end

            if sonic_demoexe.jumping then
                updateSprite(dt, sonic_demoexe.jump, sonic_demoexe)
            elseif math.abs(sonic_demoexe.velocity.x) < math.abs(targetSpeed) * 0.9 then
                updateSprite(dt, sonic_demoexe.walk, sonic_demoexe)
            else
                updateSprite(dt, sonic_demoexe.run, sonic_demoexe)
            end
            if sonic_demoexe.grounded then
                sonic_demoexe.jumping = false
            end

            if sonic_demoexe.x < 5991 then
                sonic_demoexe.x = 5991
                sonic_demoexe.velocity.x = math.max(0, sonic_demoexe.velocity.x)
            end
        end
        test_update(dt, sonic_demoexe, map2)
    end
end

local error_sound_played = false
function eggman_up(dt)
    if eggman.x < 1472 then
        if sonic_demoexe.grounded then
            updateSprite(dt, sonic_demoexe.float, sonic_demoexe)
        end

        if math.abs(eggman.y - sonic_demoexe.y) > 50 then
            sonic_demoexe.velocity.y = sonic_demoexe.jumpHeight
            updateSprite(dt, sonic_demoexe.fly, sonic_demoexe)
        end

        local dx = eggman.x - sonic_demoexe.x
        local dy = eggman.y - sonic_demoexe.y

        if dx ~= 0 then
            sonic_demoexe.x = sonic_demoexe.x + (dx / math.abs(dx)) * 682 * dt
        end

        local verticalSpeed = 305
        local deadzone = 10

        if math.abs(dy) > deadzone then
            sonic_demoexe.y = sonic_demoexe.y + (dy / math.abs(dy)) * verticalSpeed * dt
        end

        if eggman.x > sonic_demoexe.x then
            sonic_demoexe.direction = 1
        else
            sonic_demoexe.direction = -1
        end

        local triggerDistance = 125

        local dx = math.abs(eggman.x - sonic_demoexe.x)
        local dy = math.abs(eggman.y - sonic_demoexe.y)

        if not crashing and dx < triggerDistance and dy < triggerDistance then
            crashing = true
            crashTimer = 0
            love.window.setTitle("SONIC 2 3 1 (Not responding.)")
            if not error_sound_played then
                sounds.error_sound:play()
                error_sound_played = true
            end
        end
    else
        sonic_demoexe.x = 2894
        sonic_demoexe.y = 1255
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
        if not lights_off_played then
            sounds.lights_off:play()
            lights_off_played = true
            flashScreen(0.54)
        end
    end

    local moveRight, moveLeft, jump, lookUp, lookDown, fallThroughInput = getControls()
    tails_hiding = false
    for _, bush in ipairs(bushes) do
        if tails.x > bush.x and tails.x < bush.x + bush_img:getWidth() and
           tails.y > bush.y and tails.y < bush.y + bush_img:getHeight() and
           lookDown then
            tails_hiding = true
            break
        end
    end

    if tails_caught then
        tails.velocity.y = tails.velocity.y + gravity * dt
        sonic_demoexe.velocity.y = sonic_demoexe.velocity.y + gravity * dt

        local nextTailY = tails.y + tails.velocity.y * dt
        local nextSonicY = sonic_demoexe.y + sonic_demoexe.velocity.y * dt

        if not checkCollision(tails, map1, tails.x, nextTailY) then
            tails.y = nextTailY
            tails.grounded = false
        else
            tails.y = nextTailY
            tails.velocity.y = 0
            tails.grounded = true
        end

        if not checkCollision(sonic_demoexe, map1, sonic_demoexe.x, nextSonicY) then
            sonic_demoexe.y = nextSonicY
            sonic_demoexe.grounded = false
        else
            sonic_demoexe.y = nextSonicY
            sonic_demoexe.velocity.y = 0
            sonic_demoexe.grounded = true
        end

        updateSprite(dt, sonic_demoexe.kill_tails, sonic_demoexe)
        if sonic_demoexe.spriteIndex >= #sonic_demoexe.kill_tails then
            sonic_demoexe.spriteIndex = #sonic_demoexe.kill_tails
            show_black_screen = true
            sounds.flames:stop()
        end
        return
    end

    updateSprite(dt * 0.5, fire_bg.idle, fire_bg)

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

    if hs_timer <= 0 then
        if sonic_demoexe.grounded then
            updateSprite(dt, sonic_demoexe.float, sonic_demoexe)
        end

        if math.abs(tails.y - sonic_demoexe.y) > 50 then
            sonic_demoexe.velocity.y = sonic_demoexe.jumpHeight
            updateSprite(dt, sonic_demoexe.fly, sonic_demoexe)
        end

        local dx = tails.x - sonic_demoexe.x

        if dx ~= 0 then
            sonic_demoexe.x = sonic_demoexe.x + (dx / math.abs(dx)) * 355 * dt
        end

        local dy = tails.y - sonic_demoexe.y
        local verticalSpeed = 305
        local deadzone = 10

        if math.abs(dy) > deadzone then
            sonic_demoexe.y = sonic_demoexe.y + (dy / math.abs(dy)) * verticalSpeed * dt
        end

        if tails.x > sonic_demoexe.x then
            sonic_demoexe.direction = 1
        else
            sonic_demoexe.direction = -1
        end

        if not tails_hiding and
           math.abs(tails.x - sonic_demoexe.x) < 32 and
           math.abs(tails.y - sonic_demoexe.y) < 32 then
            if not tails_caught then
                tails_caught = true
                tails_caught_timer = 0
                tails.currentSprite = nil
                tails.velocity.x, tails.velocity.y = 0, 0
                sonic_demoexe.spriteIndex = 1
                sonic_demoexe.velocity.x, sonic_demoexe.velocity.y = 0, 0
            end
        end
    end
end

local animation_phase = "initial"
local animation_timer = 0
local frame_index = 1
local frame_index3 = 1
local max_repeats = 12
local repeat_count = 0
local max_final_repeats = 4
local animation_timer2 = 0
local animation_timer3 = 0
finished_transformation = false
splash_timer = 0
splash_done = false

emhi_bg = love.graphics.newImage("images/background/emerald hill.png")
menu_finished = love.graphics.newImage("images/background/menu_finished.png")
menu = love.graphics.newImage("images/background/menu.png")
menu2 = love.graphics.newImage("images/background/menu2.png")

local bgX1 = 0
local bgX2 = menu:getWidth()
local scroll_speed = 50

local ANIM_SPEED = 0.25
local animHandlers = {}

animHandlers.initial = function(dt)
    frame_index = frame_index + 1
    if frame_index > #frames then
        frame_index = 1
        animation_phase = "repeatable"
    end
end

animHandlers.repeatable = function(dt)
    frame_index = (frame_index % #repeatable_frames) + 1
    repeat_count = repeat_count + 1
    if repeat_count >= max_repeats * #repeatable_frames then
        repeat_count = 0
        animation_phase = "screen"
    end
end

animHandlers.screen = function(dt)
    animation_timer3 = animation_timer3 + dt
    if animation_timer3 >= 0.0001 then
        animation_phase = "repeatable2"
    end
end

animHandlers.repeatable2 = function(dt)
    sounds.sonic_theme:stop()
    frame_index = (frame_index % #repeatable2_frames) + 1
    repeat_count = repeat_count + 1
    if repeat_count >= max_final_repeats * #repeatable2_frames then
        repeat_count = 0
        animation_phase = "black_screen"
    end
end

animHandlers.black_screen = function(dt)
    animation_timer2 = animation_timer2 + dt
    if animation_timer2 >= 0.0001 then
        finished_transformation = true
        animation_phase = "done"
        frame_index3 = 1
        splash_timer = 0
        splash_done = false
    end
end
local animTime = 1
local timer = 0
local pressTextAnimTime = 2.2
local pressTextTimer = 0
local pressTextStartY = base_height + 50
local pressTextTargetY = (base_height / 2) + 70
local frames_idk_d = 1
local frameDelay = 25
local frameCounter = 0

local flickerTimer = 0
local flickerInterval = 0.5
local showPressText = true
local flickerActive = false
function menuscreen_update(dt)
    if gamestate ~= "menuscreen" then return end

    animation_timer = animation_timer + dt
    if animation_timer >= ANIM_SPEED and animHandlers[animation_phase] then
        animation_timer = 0
        animHandlers[animation_phase](dt)
    end

    if finished_transformation and not splash_done then
        splash_timer = splash_timer + dt
        if splash_timer >= 0.2011 then
            splash_timer = 0
            frame_index3 = frame_index3 + 1
            if frame_index3 >= #splash_frames.splash then
                frame_index3 = #splash_frames.splash
                splash_done = true
            end
        end
    end

    if splash_done then
        frameCounter = frameCounter + 1
        if frameCounter >= frameDelay then
            frameCounter = 0
            frames_idk_d = frames_idk_d + 1
            if frames_idk_d > #splash_frames.idle then
                frames_idk_d = 1
            end
        end
        sounds.buildUPSound:play()

        if finished_transformation then
            pressTextTimer = math.min(pressTextTimer + dt, pressTextAnimTime)
        end

        if love.keyboard.isDown("return") and finished_transformation then
            shrinkingMenu = true
            if sounds.laugh_sound then
                sounds.laugh_sound:play()
            end
        end
        flickerActive = true
        if flickerActive then
            flickerTimer = flickerTimer + dt
            if flickerTimer >= flickerInterval then
                flickerTimer = 0
                showPressText = not showPressText
            end
        end
    end

    if timer < animTime then
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

function drawStageName(img, x, y)
    love.graphics.draw(img, x, y)
end
function drawStageCircle(img, x, y)
    love.graphics.draw(img, x, y)
end
function drawStageAct(img, x, y)
    love.graphics.draw(img, x, y)
end
function drawTitleCard(stageNameImg, circleImg, actImg, baseX, baseY)
    drawStageCircle(circleImg, baseX + 10, baseY)
    drawStageName(stageNameImg, baseX, baseY)
    love.graphics.draw(stageActImg, baseX + stageNameImg:getWidth() - 25, baseY + circleImg:getHeight() - 4)
    drawStageAct(actImg, baseX + stageNameImg:getWidth() + 10, baseY + circleImg:getHeight() - 20)
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

function updateGamestate(dt, char)
    if gamestate ~= prevGamestate and gamestate ~= "eggman" then
        char.x = 100
        char.y = 50
        prevGamestate = gamestate
    end
end

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

function love.update(dt)
    gameTime = gameTime + dt
    if ok and discord then
        discord.runCallbacks()
    end
    update_flash(dt)

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

    if gamestate == "test" then
        test_update(dt, tails, map)
        before_idk(dt)
    elseif gamestate == "hs" then
        test_update(dt, tails, map1)
        hide_and_seek(dt)
        if show_black_screen then
            sounds.flames:stop()
            tails_caught_timer = tails_caught_timer + dt
            if tails_caught_timer >= 4 then
                show_black_screen = false
                tails_alive = false
                knuckles_lock = true
                tails_lock = false
                --startTransition("selection")
                gamestate = "selection"
            end
        end
    elseif gamestate == "knuck" then
        test_update(dt, knuckles, map2)
        knuck_up(dt)
    elseif gamestate == "eggman" then
        if not crashing then
            test_update(dt, eggman, map3)
            eggman_up(dt)
        else
            sonic_demoexe.currentSprite = sonic_demoexe.fly[1]
            eggman.currentSprite = eggman.idle
        end

        if crashing then
            crashTimer = crashTimer + dt

            if crashTimer <= fadeDuration then
                crashAlpha = (crashTimer / fadeDuration) * crashMaxAlpha
            else
                crashAlpha = crashMaxAlpha
            end

            if crashTimer >= crashDuration then
                gamestate = "cheating"
                love.window.setTitle("SONIC 2 3 1")
                crashing = false
                crashTimer = 0
                crashAlpha = 0
            end
        end
    elseif gamestate == "torture" then
        torture(dt)
    elseif gamestate == "william" then
        william_update(dt)
        love.mouse.setRelativeMode(true)
    elseif gamestate == "warning" and love.keyboard.isDown("return") then
        startTransition("error")
    else
        love.mouse.setRelativeMode(false)
    end

    if gamestate == "selection" then
        if love.keyboard.isDown("return") then
            if selectionIndex == 1 and tails_lock then
                startTransition("test")
            elseif selectionIndex == 2 and knuckles_lock then
                startTransition("knuck")
            elseif selectionIndex == 3 and eggman_lock then
                startTransition("eggman")
            end
        end

        zoomTimer = math.min(zoomTimer + dt, zoomDuration)
        local t = easeInOutCubic(zoomTimer / zoomDuration)

        selectionScale = 3 + (1 - 3) * t
        selectionAlpha = 0 + (1 - 0) * t

        if zoomTimer >= zoomDuration then
            selectionScale = 1
            selectionAlpha = 1
        end
    end

    if gamestate == "credits" then
        local total_text_height = #credits_text * line_height
        credits_y = credits_y - (scroll_speed * dt)

        if credits_y < -total_text_height then
            gamestate = "doc"
        end
    elseif gamestate == "doc" then
        if message_alpha < 1 then
            message_alpha = message_alpha + dt * 0.5
        end
    end

    menuscreen_update(dt)
    updateStageTitle(dt)
    if animation_phase ~= "initial" then
        bgX1 = bgX1 + scroll_speed * dt
        bgX2 = bgX2 + scroll_speed * dt
    
        if bgX1 >= menu:getWidth() then
            bgX1 = bgX2 - menu:getWidth()
        end
    
        if bgX2 >= menu:getWidth() then
            bgX2 = bgX1 - menu:getWidth()
        end
    end
    if gamestate == "error" then
        elapsedTime4 = (elapsedTime4 or 0) + dt

        if elapsedTime4 >= 7 then
            reboot_vis = true
        elseif elapsedTime4 >= 2 then
            reboot_vis2 = true
        end

        if reboot_vis and not rebootDone then
            if not stageComplete then
                stageProgress = math.min(100, stageProgress + dt * 50)

                if stageProgress >= 100 then
                    stageComplete = true
                    stageDelay = 0
                end
            else
                stageDelay = stageDelay + dt
                if stageDelay >= 1 then
                    currentStage = currentStage + 1
                    if currentStage > #loadingStages then
                        rebootDone = true
                        stageDelay = 0
                    else
                        stageProgress = 0
                        stageComplete = false
                    end
                end
            end
        elseif rebootDone then
            fadeBlack = math.min(1, fadeBlack + dt * 0.5)
            if fadeBlack >= 1 then
                helloFade = math.min(1, helloFade + dt * 0.5)
                if helloFade >= 1 then
                    helloWilliamTimer = (helloWilliamTimer or 0) + dt
                    if helloWilliamTimer >= 2 then
                        gamestate = "menuscreen"
                    end
                end
            end
        end
    end

    if gamestate == "game_over" then
        waiting = waiting + dt
        if waiting >= 3 then
            startTransition("credits")
        end
    end

    if transitioning then
        transitionAlpha = math.min(transitionAlpha + transitionSpeed * dt, 1)
        if transitionAlpha >= 1 then
            gamestate = transitionTarget
            transitioning = false
        end
    else
        transitionAlpha = math.max(transitionAlpha - transitionSpeed * dt, 0)
    end
    if shrinkingMenu then
        shrinkTimer = math.min(shrinkTimer + dt, shrinkDuration)
        local t = shrinkTimer / shrinkDuration
        local eased = easeOutCubic(t)
        menuShrink = 1 - (1 - 0.5) * eased
        menuAlpha  = 1 - eased

        if shrinkTimer >= shrinkDuration then
            shrinkingMenu = false
            gamestate = "selection"
        end
    end

    if gamestate ~= lastGamestate then
        titleCardPlayed = false
        lastGamestate = gamestate
    end
    if stages[gamestate] and not titleCardPlayed then
        triggerStageTitle()
        titleCardPlayed = true
    end
end

local function drawNumberString(x, y, str)
    str = tostring(str)
    for i = 1, #str do
        local ch = str:sub(i, i)
        if ch:match("%d") then
            love.graphics.draw(images.numbers, quads.numbers[tonumber(ch)], x, y)
            x = x + 9
        elseif ch == ":" then
            x = x + 7
        end
    end
end

soundPlayed8 = false
soundPlayed9 = false
soundPlayed10 = false

function selection()
    local winWidth, winHeight = base_width, base_height
    local mouseX, mouseY = love.mouse.getPosition()

    love.graphics.push()
    love.graphics.translate(winWidth/2, winHeight/2)
    love.graphics.scale(selectionScale, selectionScale)
    love.graphics.translate(-winWidth/2, -winHeight/2)
    love.graphics.setColor(1, 1, 1, selectionAlpha)
    local halfW, halfH = winWidth / 2, winHeight / 2
    local offsetX2 = (mouseX - halfW) * 0.025
    local offsetY2 = (mouseY - halfH) * 0.02

    local spacing = 100
    local baseX = (winWidth / 2) + offsetX2 + characterOffsetX
    local centerY = (winHeight / 2) + offsetY2

    local boxX = winWidth / 2 + offsetX2
    local boxY = centerY
    love.graphics.draw(selection_box, boxX, boxY, 0, 1, 1, selection_box:getWidth() / 2, selection_box:getHeight() / 2)

    local characters = {
        { name = "tails", alive = tails_alive, lock = tails_lock, img = tails_selection, dead = dead_tails },
        { name = "knuckles", alive = knuckles_alive, lock = knuckles_lock, img = knuck_selection, dead = dead_knuckles },
        { name = "eggman", alive = eggman_alive, lock = eggman_lock, img = eggman_selection, dead = dead_eggman }
    }

    for i, char in ipairs(characters) do
        local xOffset = (i - selectionIndex) * spacing
        local scale = (i == selectionIndex) and 1 or 0.65
        local yOffset = (i == selectionIndex) and 0 or 25

        local drawX = baseX + xOffset
        local drawY = centerY + yOffset

        local alpha = (i == selectionIndex) and 1 or 0.7
        love.graphics.setColor(1, 1, 1, alpha * selectionAlpha)

        if char.alive then
            love.graphics.draw(char.img, drawX, drawY, 0, scale, scale, char.img:getWidth() / 2, char.img:getHeight() / 2)

            if not char.lock then
                love.graphics.draw(lockImg, drawX - 10, drawY + 20, 0, scale, scale)
            end
        else
            love.graphics.draw(char.dead, drawX, drawY, 0, scale, scale, char.dead:getWidth() / 2, char.dead:getHeight() / 2)
        end
    end
    love.graphics.setColor(1, 1, 1, selectionAlpha)
    local arrowY = boxY - 25
    local leftArrowX = 50
    local rightArrowX = winWidth - 100

    if love.keyboard.isDown("left") then 
        love.graphics.setColor(0.5, 0.5, 0.5 * selectionAlpha)
        leftArrowX = 40
    else 
        love.graphics.setColor(1, 1, selectionAlpha)
    end
    love.graphics.draw(leftwImage, leftArrowX, arrowY)

    if love.keyboard.isDown("right") then 
        love.graphics.setColor(0.5, 0.5, 0.5 * selectionAlpha)
        rightArrowX = winWidth - 90
    else 
        love.graphics.setColor(1, 1, selectionAlpha)
    end
    love.graphics.draw(rightwImage, rightArrowX, arrowY)

    love.graphics.setColor(1, 1, 1)

    love.graphics.pop()
end

local function char_draw(char, offsetX, offsetY)
    if not char.isPresent or not char.currentSprite then return end
    offsetX = offsetX or 0
    offsetY = offsetY or 0

    local sprite = char.currentSprite
    if type(sprite) == "table" then
        sprite = sprite[math.floor(char.spriteIndex)] or sprite[1]
    end
    if sprite then
        local flipX = char.direction == -1 and -1 or 1
        love.graphics.draw(
            sprite,
            char.x + offsetX,
            char.y + offsetY,
            char.angle,
            flipX,
            1,
            sprite:getWidth() / 2,
            sprite:getHeight() / 2
        )
    end
end

local function drawScrollingBG(image, x1, x2, offsetX, offsetY)
    love.graphics.draw(image, x1 + offsetX, offsetY)
    love.graphics.draw(image, x2 + offsetX, offsetY)
end

DEMO_MenuScreen = love.graphics.newImage(spritesFolder.."menuscreen/splash/6.png")

local greenHillZoneTitle = love.graphics.newImage("images/zone/titles/zone.png")
greenHillZoneTitle_2 = love.graphics.newImage("images/zone/titles/g_hill.png")
local udZoneTitle = love.graphics.newImage("images/zone/titles/u_d.png")
local hideAndSeekZoneTitle = love.graphics.newImage("images/zone/titles/h&s.png")
local DotTitle = love.graphics.newImage("images/zone/titles/dot.png")
labTitle = love.graphics.newImage("images/zone/titles/us.png")

greenHillZoneCircles = love.graphics.newImage("images/zone/circles/g_hill.png")
greenHillZoneCircles_2 = love.graphics.newImage("images/zone/circles/g_hill_2.png")
local udZoneCircles = love.graphics.newImage("images/zone/circles/u_d.png")
local hideAndSeekZoneCircles = love.graphics.newImage("images/zone/circles/h&s.png")
local DotCircles = love.graphics.newImage("images/zone/circles/dot.png")
labCircles = love.graphics.newImage("images/zone/circles/us.png")

stageActImg = love.graphics.newImage("images/zone/act/act.png")
stageActImg1 = love.graphics.newImage("images/zone/act/1.png")
stageActImg2 = love.graphics.newImage("images/zone/act/2.png")

function linear(a, b, t)
    a = tonumber(a) or 0
    b = tonumber(b) or 0
    t = tonumber(t) or 0
    if t < 0 then t = 0 elseif t > 1 then t = 1 end

    return a + (b - a) * t
end

function openURL(url)
    local success = false
    local osType = love.system.getOS()

    if osType == "Windows" then
        success = os.execute('start "" "' .. url .. '"')
    elseif osType == "OS X" then
        success = os.execute('open "' .. url .. '"')
    else
        success = os.execute('xdg-open "' .. url .. '"')
    end

    if not success then
        print("Failed to open URL.")
    end
end

function draw_william()
    love.graphics.push()

    local w, h = base_width, base_height
    local hw, hh = w * 0.5, h * 0.5
    local aspect = w / h
    local fovRad = math.rad(70)

    if not sounds.buildUPSound:isPlaying() then
        sounds.buildUPSound:play()
    end

    local cy, sy = math.cos(-camera_3d.yaw), math.sin(-camera_3d.yaw)
    local cp, sp = math.cos(-camera_3d.pitch), math.sin(-camera_3d.pitch)
    local fovHalfTan = math.tan(fovRad / 2)
    local coastFadeStart = 50
    local coastFadeEnd = 80

    for t = 1, #baseplateTiles do
        local tile = baseplateTiles[t]
        if inRenderDistance(tile) then
            local screenVerts = {}
            local visible = true

            for i = 1, 4 do
                local v = tile[i]
                local x, y, z = v[1] - camera_3d.x, v[2] - camera_3d.y, v[3] - camera_3d.z
                local x1, z1 = x * cy - z * sy, x * sy + z * cy
                local y1 = y * cp - z1 * sp
                local z2 = y * sp + z1 * cp

                if z2 <= 0.1 then
                    visible = false
                    break
                end
                local sx = x1 / (z2 * fovHalfTan * aspect)
                local sy = y1 / (z2 * fovHalfTan)
                screenVerts[i] = {sx * hw + hw, -sy * hh + hh}
            end

            if visible then
                local centerX = (tile[1][1] + tile[3][1]) * 0.5
                local centerY = (tile[1][2] + tile[3][2]) * 0.5
                local centerZ = (tile[1][3] + tile[3][3]) * 0.5
                local dx = centerX - camera_3d.x
                local dy = centerY - camera_3d.y
                local dz = centerZ - camera_3d.z
                local dist = math.sqrt(dx * dx + dy * dy + dz * dz)

                local fade = clamp((coastFadeEnd - dist) / (coastFadeEnd - coastFadeStart), 0, 1)
                local col = tile[1][4]
                love.graphics.setColor(col[1], col[2], col[3], col[4] * fade)

                love.graphics.polygon(
                    "fill",
                    screenVerts[1][1], screenVerts[1][2],
                    screenVerts[2][1], screenVerts[2][2],
                    screenVerts[3][1], screenVerts[3][2],
                    screenVerts[4][1], screenVerts[4][2]
                )
            end
        end
    end
    do
        local x, y, z = chaser.x - camera_3d.x, chaser.y - camera_3d.y, chaser.z - camera_3d.z
        local x1, z1 = x * cy - z * sy, x * sy + z * cy
        local y1 = y * cp - z1 * sp
        local z2 = y * sp + z1 * cp

        if z2 > 0.1 then
            local scale = 25 / z2
            local sx = x1 / (z2 * fovHalfTan * aspect)
            local sy = y1 / (z2 * fovHalfTan)

            local fadeStart, fadeEnd = 100, 15
            local dist = math.sqrt(dist2(camera_3d, chaser))
            local alpha = clamp((fadeStart - dist) / (fadeStart - fadeEnd), 0, 1)

            love.graphics.setColor(1, 1, 1, alpha)
            love.graphics.draw(
                chase_img,
                sx * hw + hw - chase_img:getWidth() * scale / 2,
                -sy * hh + hh - chase_img:getHeight() * scale / 2,
                0, scale, scale
            )
        end
    end

    love.graphics.pop()
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(idk_img, 0, 0, 0, w/idk_img:getWidth(), h/idk_img:getHeight())
    drawStats()
end

function draw_menuscreen()
    love.graphics.push()
    love.graphics.setColor(1, 1, 1, menuAlpha)
    love.graphics.translate(base_width/2, base_height/2)
    love.graphics.scale(menuShrink, menuShrink)
    love.graphics.translate(-base_width/2, -base_height/2)
    if finished_transformation then
        sounds.sonic_theme:setLooping(false)
        sounds.sonic_theme:stop()

        local mouseX, mouseY = love.mouse.getPosition()
        mouseX = (mouseX - offset_x) / scale_factor
        mouseY = (mouseY - offset_y) / scale_factor
        local offsetX = (mouseX - base_width) * 0.05
        local offsetY = (mouseY - base_height) * 0.05

        local demoX = (base_width - DEMO_MenuScreen:getWidth()) / 2 + offsetX * 0.5
        local demoY = (base_height - DEMO_MenuScreen:getHeight()) / 2 + offsetY * 0.4
        if not splash_done then
            love.graphics.draw(splash_frames.splash[frame_index3], demoX, demoY- 10)
        else
            love.graphics.draw(splash_frames.idle[frames_idk_d], demoX, demoY- 10)
        end

        local t = math.min(pressTextTimer / pressTextAnimTime, 1)
        local easedT = easeInOutCubic(t)
        local currentY = pressTextStartY + (pressTextTargetY - pressTextStartY) * easedT
        local text = "Press start to play."
        local textWidth = FontBig:getWidth(text)
        if not flickerActive or showPressText then
            love.graphics.print(text, (base_width - textWidth) / 2 + offsetX * 0.5 + 70, currentY + offsetY * 0.4)
        end
        love.graphics.pop()
        return
    end
    sounds.sonic_theme:play()
    sounds.sonic_theme:setLooping(true)

    local bgImg = (animation_phase == "repeatable2") and menu2 or menu
    local colorMod = (animation_phase == "repeatable2") and 0.5 or 1
    love.graphics.setColor(colorMod, colorMod, colorMod)
    drawScrollingBG(bgImg, bgX1, bgX2, 0, 0)
    love.graphics.setColor(1, 1, 1)

    local demoX = (base_width - DEMO_MenuScreen:getWidth()) / 2
    local demoY = (base_height - DEMO_MenuScreen:getHeight()) / 2

    local t = math.min(timer / animTime, 1)
    local currentY = linear(demoY + 10, demoY - 10, t)

    local circleX = (base_width - circle:getWidth()) / 2
    local circleY = (base_height - circle:getHeight()) / 2

    if animation_phase ~= "repeatable2" then
        love.graphics.draw(circle, circleX, circleY + 30)
    end

    if animation_phase == "initial" then
        love.graphics.draw(frames[frame_index], demoX, currentY)
    elseif animation_phase == "repeatable" then
        love.graphics.draw(repeatable_frames[frame_index], demoX, demoY - 10)
    elseif animation_phase == "repeatable2" then
        love.graphics.draw(repeatable2_frames[frame_index], demoX, demoY - 10)
    end

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
    return math.max(0, math.min(1, t))
end

function tails_tail_thing()
        if tail_tails.currentSprite and (
            tails.currentSprite == tails.idle or
            tails.currentSprite == tails.down or
            tails.currentSprite == tails.up
        ) then
            local flipX = (tails.direction == -1) and -1 or 1
            local offsetX = (flipX == 1) and -12 or 12
            love.graphics.draw(
                tail_tails.currentSprite,
                tails.x + offsetX, tails.y + 5,
                0,
                flipX, 1,
                tail_tails.currentSprite:getWidth() / 2,
                tail_tails.currentSprite:getHeight() / 2
            )
        elseif not tail_tails.currentSprite then
            print("idk")
        end
end

function mobile_stuff_draw()
    love.graphics.setColor(1, 1, 1)

    love.graphics.draw(
        joystickBaseImage,
        joystick.x - joystickBaseImage:getWidth() / 2 * SCALE,
        joystick.y - joystickBaseImage:getHeight() / 2 * SCALE,
        0,
        SCALE, SCALE
    )

    local knobX = joystick.x + joystick.dx * joystick.radius
    local knobY = joystick.y + joystick.dy * joystick.radius
    love.graphics.draw(
        joystickKnobImage,
        knobX - joystickKnobImage:getWidth() / 2 * SCALE,
        knobY - joystickKnobImage:getHeight() / 2 * SCALE,
        0,
        SCALE, SCALE
    )

    love.graphics.draw(
        jumpButtonImage,
        jumpButton.x - jumpButtonImage:getWidth() / 2 * SCALE,
        jumpButton.y - jumpButtonImage:getHeight() / 2 * SCALE,
        0,
        SCALE, SCALE
    )
end

function love.draw()
    love.graphics.setFont(Font)
    love.graphics.setCanvas(canvas)love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", 0, 0, base_width * 2, base_height * 2)
    love.graphics.setColor(1, 1, 1)

    local function drawStageTitle(titleImg, circlesImg, actImg)
        if showStageTitle then
            local alpha = 1
            if stageTitleTimer > stageTitleDuration - stageTitleFadeTime then
                alpha = (stageTitleDuration - stageTitleTimer) / stageTitleFadeTime
            end
            alpha = clamp(alpha, 0, 1)

            love.graphics.setColor(0, 0, 0, alpha)
            love.graphics.rectangle("fill", 0, 0, base_width, base_height)
            love.graphics.setColor(1, 1, 1, 1)

            local enterProgress = math.min(stageTitleTimer / stageTitleFadeTime, 1)
            local startX, endX = -100, base_width / 2 - (titleImg:getWidth() / 2) - 60
            local slideX = lerp(startX, endX, linearTime(enterProgress))

            if stageTitleTimer > stageTitleDuration - stageTitleFadeTime then
                local exitProgress = 1 - ((stageTitleDuration - stageTitleTimer) / stageTitleFadeTime)
                slideX = lerp(endX, base_width + 130, linearTime(exitProgress))
            end

            local y = base_height / 2 - 40
            drawTitleCard(titleImg, circlesImg, actImg, slideX, y)
        end
    end

    if gamestate == "menuscreen" or gamestate == "selection" then
        local mouseX, mouseY = love.mouse.getPosition()
        mouseX = (mouseX - offset_x) / scale_factor
        mouseY = (mouseY - offset_y) / scale_factor
        local offsetX = (mouseX - base_width) * 0.05
        local offsetY = (mouseY - base_height) * 0.05
        drawScrollingBG(menu_finished, bgX1, bgX2, offsetX * 0.5, offsetY * 0.4)
    end

    if gamestate == "menuscreen" then
        draw_menuscreen()
        love.graphics.setColor(1, 1, 1)
    elseif gamestate == "test" then
        sounds.buildUPSound:stop()
        sounds.green_hill:play()
        love.graphics.setColor(currentColor)
        drawScrollingBG(emhi_bg, bgX1, bgX2, 0, 0)
        love.graphics.setColor(1, 1, 1)

        love.graphics.push()
        love.graphics.translate(-math.floor(camera.x), -math.floor(camera.y))
        love.graphics.draw(test2, 0, 0)

        if sonic_demoexe.currentSprite then
            love.graphics.draw(sonic_demoexe.currentSprite, 10948, 730)
        end

        tails_tail_thing()
        char_draw(tails, 0, 2)
        love.graphics.pop()

        drawStats()
        drawStageTitle(greenHillZoneTitle, greenHillZoneCircles, stageActImg1)
        love.graphics.setColor(1, 1, 1)
    elseif gamestate == "hs" then
        love.graphics.push()
        if bushes_destroyed then
            love.graphics.draw(fire_bg.currentSprite, 0, 0)
        end
        love.graphics.translate(-math.floor(camera.x), -math.floor(camera.y))
        love.graphics.draw(test3, 0, 0)

        if not tails_caught and tails.currentSprite then
            tails_tail_thing()
            char_draw(tails, 0, 2)
        end

        for _, bush in ipairs(bushes) do
            love.graphics.draw(bush_img, bush.x, bush.y)
        end

        char_draw(sonic_demoexe, 0, 2)
        love.graphics.pop()

        drawStats()

        if not bushes_destroyed then
            local timerText = string.format("HIDING TIME LEFT: %.1f", hs_timer)
            local timerWidth = love.graphics.getFont():getWidth(timerText)
            love.graphics.setColor(0, 0, 0)
            love.graphics.print(timerText, base_width - timerWidth - 17, 33)
            love.graphics.setColor(1, 1, 0)
            love.graphics.print(timerText, base_width - timerWidth - 20, 30)
        end

        drawStageTitle(hideAndSeekZoneTitle, hideAndSeekZoneCircles, stageActImg2)

        if show_black_screen then
            love.graphics.setColor(0, 0, 0, 1)
            love.graphics.rectangle("fill", 0, 0, base_width, base_height)
        end
        love.graphics.setColor(1, 1, 1)
    elseif gamestate == "knuck" then
        love.graphics.push()
        drawScrollingBG(knuck_bg, bgX1, bgX2, 0, 0)
        love.graphics.translate(-math.floor(camera.x), -math.floor(camera.y))
        love.graphics.draw(knuck1)
        char_draw(knuckles, 0, -2)

        if demo_vis then char_draw(sonic_demoexe, 0, -2) end
        if stage1_vis then love.graphics.draw(stage1, 2544, 518) end
        if stage2_vis and s1.currentSprite then love.graphics.draw(s1.currentSprite, 4387, 864) end
        if stage3_vis then love.graphics.draw(stage3, 5481, 867) end

        if stage1_vis == false then
            if not soundPlayed10 then
            sounds.rebootSound:play()
            flashScreen(0.45)
            soundPlayed10 = true
            end
        end

        if stage3_vis == false then
            if not soundPlayed8 then
            sounds.rebootSound:play()
            flashScreen(0.45)
            soundPlayed8 = true
            end
        end
        
        if stage2_vis == false then
            if not soundPlayed9 then
            sounds.rebootSound:play()
            flashScreen(0.45)
            soundPlayed9 = true
            end
        end

        if idk_fix then
            if knuckles.x < 5991 then
                knuckles.x = 5991
                knuckles.velocity.x = math.max(0, knuckles.velocity.x)
            end
        end
        love.graphics.pop()
        drawStats()
        drawStageTitle(greenHillZoneTitle, hideAndSeekZoneCircles, stageActImg1)
        love.graphics.setColor(1, 1, 1)
    elseif gamestate == "eggman" then
        drawScrollingBG(menu, bgX1, bgX2, 0, 0)
        love.graphics.push()
        love.graphics.translate(-math.floor(camera.x), -math.floor(camera.y))
        love.graphics.draw(egg_mob, 3200, 903)
        love.graphics.draw(gh1, 0, 0)
        char_draw(sonic_demoexe, 0, -2)
        char_draw(eggman, 0, -8)
        love.graphics.pop()
        drawStats()
        drawStageTitle(greenHillZoneTitle, hideAndSeekZoneCircles, stageActImg1)

        if crashing then
            love.graphics.setColor(1, 1, 1, crashAlpha)
            love.graphics.rectangle("fill", 0, 0, base_width, base_height)
        end
        love.graphics.setColor(1, 1, 1)
    elseif gamestate == "torture" and tort_visible then
        love.graphics.setColor(1, 1, 1, 0.355)
        if sonic_demoexe_screen.currentSprite then
            love.graphics.draw(sonic_demoexe_screen.currentSprite)
        end
        love.graphics.setColor(1, 1, 1, 1)
        local t = love.timer.getTime()
        love.graphics.print("Ready to be", 125, 50 + math.sin(t*2)*2)
        love.graphics.print("Tortured?", 285, 200 + math.sin(t*2.2)*3)
        love.graphics.setColor(1, 1, 1)
    elseif gamestate == "selection" then
        selection()
        love.graphics.setColor(1, 1, 1)
    elseif gamestate == "william" then
        draw_william()
        drawStageTitle(DotTitle, DotCircles, stageActImg1)
        love.graphics.setColor(1, 1, 1)
    elseif gamestate == "error" then
        love.graphics.clear(0,0,0,1)
        if reboot_vis and not rebootDone then
            for i = 1, currentStage do
                local stageText = loadingStages[i]
                local text = i < currentStage and stageText.." 100%" or stageText.." "..math.floor(stageProgress).."%"
                love.graphics.print(text, 20, 20 + (i-1)*20)
            end
        elseif rebootDone then
            love.graphics.setColor(0, 0, 0, fadeBlack)
            love.graphics.rectangle("fill", 0, 0, base_width, base_height)
            if fadeBlack >= 1 then
                love.graphics.setFont(FontBig)
                love.graphics.setColor(0.045, 0.045, 0.045, helloFade)
                local text = "HELLO WILLIAM."
                love.graphics.print(text, base_width/2 - FontBig:getWidth(text)/2, base_height/2 - FontBig:getHeight()/2)
            end
        elseif reboot_vis2 then
            love.graphics.setFont(FontBig)
            love.graphics.print("An Error has Occurred.", 20, 20)
        end
        love.graphics.setColor(1, 1, 1)
    elseif gamestate == "credits" then
        for i, line in ipairs(credits_text) do
            love.graphics.printf(line, 10, credits_y + (i - 1) * line_height, base_width - 20, "center")
        end
    elseif gamestate == "doc" then
        love.graphics.setColor(1,1,1,message_alpha)
        love.graphics.printf("Press Enter to open the Document", 0, base_height/2, base_width, "center")
    elseif gamestate == "warning" then
        love.graphics.printf("WARNING!\nThis game contains flash light and it might also be buggy as well, which will be fixed in the very next updates of the game.\n\nPress start to play.", 0, base_height/2 - 45, base_width, "center")
    elseif gamestate == "cheating" then
    end

    if transitionAlpha > 0 then
        love.graphics.setColor(0, 0, 0, transitionAlpha)
        love.graphics.rectangle("fill", 0, 0, base_width * 2, base_height * 2)
    end
    if isFlashing then
        love.graphics.setColor(1, 1, 1, flashAlpha)
        love.graphics.rectangle("fill", 0, 0, base_width * 2, base_height * 2)
    end

    love.graphics.setColor(1, 1, 1, 1)
    if isMobile then
        mobile_stuff_draw()
    end
    love.graphics.setCanvas()
    love.graphics.draw(canvas, offset_x, offset_y, 0, scale_factor, scale_factor)
end

function drawStats()
    local x, y = 10, 10

    love.graphics.draw(images.score, x, y)
    drawNumberString(x + 100, y - 1, tostring(stats.score))

    local minutes = math.floor(gameTime / 60)
    local seconds = math.floor(gameTime % 60)
    local timeStr = string.format("%d:%02d", minutes, seconds)

    love.graphics.draw(images.time, x, y + 16)
    drawNumberString(x + 50, y + 15, timeStr)

    love.graphics.draw(images.rings, quads.rings[ringAnimState and "top" or "bottom"], x, y + 32)
    drawNumberString(x + 75, y + 31, tostring(stats.rings))

    love.graphics.draw(images.william, x, 225)
end

function love.keyreleased(key)
    if gamestate == "selection" then
        if key == "right" then
          selectionIndex = math.min(#selectionOptions, selectionIndex + 1)
          sounds.reboot_old:play()
        elseif key == "left" then
          selectionIndex = math.max(1, selectionIndex - 1)
          sounds.reboot_old:play()
        end
        if key == "escape" then
            startTransition("menuscreen")
        end
    end
end

function love.resize(w, h)
    updateCanvasScale()
end

function updateCanvasScale()
    local window_width, window_height = love.graphics.getDimensions()
    
    local scale_x = window_width / base_width
    local scale_y = window_height / base_height
    scale_factor = math.min(scale_x, scale_y)
    
    local scaled_width = base_width * scale_factor
    local scaled_height = base_height * scale_factor
    offset_x = (window_width - scaled_width) / 2
    offset_y = (window_height - scaled_height) / 2
end

function love.run()
    if love.load then love.load(love.arg.parseGameArguments(arg), arg) end

    if love.timer then love.timer.step() end

    local dt = 0
    local fps = 60
    local frameTime = 1 / fps

    return function()
        if love.event then
            love.event.pump()
            for name, a,b,c,d,e,f in love.event.poll() do
                if name == "quit" then
                    if not love.quit or not love.quit() then
                        return a or 0
                    end
                end
                love.handlers[name](a,b,c,d,e,f)
            end
        end

        if love.timer then
            love.timer.step()
            dt = love.timer.getDelta()
        end

        if love.update then love.update(dt) end

        if love.graphics and love.graphics.isActive() then
            love.graphics.origin()
            love.graphics.clear(love.graphics.getBackgroundColor())

            if love.draw then love.draw() end

            love.graphics.present()
        end
        local sleepTime = frameTime - love.timer.getDelta()
        if sleepTime > 0 then
            love.timer.sleep(sleepTime)
        end
    end
end

function love.keypressed(key)
    if gamestate == "doc" and key == "return" then
        openURL("https://docs.google.com/document/d/1J0nOXnQMULgsqhbdnPfF3uHCHJ0wMvX1BC4TgXKVpX8")
        love.event.quit()
    end
end

function love.touchpressed(id, x, y)
    if not isMobile then return end

    x = (x - offset_x) / scale_factor
    y = (y - offset_y) / scale_factor

    touches[id] = {x=x, y=y}

    if x <= base_width / 2 then
        joystick.active = true
        joystick.dx = (x - joystick.x) / joystick.radius
        joystick.dy = (y - joystick.y) / joystick.radius
    end

    if x > base_width / 2 then
        jumpButton.active = true
    end

    if splash_done and finished_transformation then
        shrinkingMenu = true
        if sounds.laugh_sound then
            sounds.laugh_sound:play()
        end
    end

    if gamestate == "warning" then
        startTransition("error")
    end
end

function love.touchmoved(id, x, y)
    if not isMobile or not touches[id] then return end

    x = (x - offset_x) / scale_factor
    y = (y - offset_y) / scale_factor

    touches[id].x, touches[id].y = x, y

    if joystick.active and x <= base_width / 2 then
        local dx = x - joystick.x
        local dy = y - joystick.y
        local len = math.sqrt(dx*dx + dy*dy)
        local maxDist = joystick.radius
        if len > maxDist then
            dx = dx / len * maxDist
            dy = dy / len * maxDist
        end
        joystick.dx = dx / joystick.radius
        joystick.dy = dy / joystick.radius
    end
end

function love.touchreleased(id, x, y)
    if not isMobile then return end
    touches[id] = nil

    local leftActive, rightActive = false, false
    for _, t in pairs(touches) do
        if t.x <= base_width / 2 then leftActive = true end
        if t.x > base_width / 2 then rightActive = true end
    end

    if not leftActive then
        joystick.active = false
        joystick.dx = 0
        joystick.dy = 0
    end

    if not rightActive then
        jumpButton.active = false
    end
end