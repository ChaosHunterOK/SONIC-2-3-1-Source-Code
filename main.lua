local love = require("love")
local fast = require("fast")
fast.fpsCap = 60

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
            local scaleX = screenW / image:getWidth()
            local scaleY = screenH / image:getHeight()
            love.graphics.draw(image, 0, 0, 0, scaleX, scaleY)
        end

        love.graphics.printf(errorMessage, xOffset, 100, screenW - xOffset - 50, "left")
        love.graphics.printf("DM copilucusarmale on Discord to report this goofy error", xOffset, 35, screenW - xOffset - 50, "left")

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
local gamestate = "credits"

local isMobile = false
local os_device = love.system.getOS()
if os_device == "Android" or os_device == "iOS" then
    isMobile = true
end

gravity = 625

local floor, abs, min, max, atan2, deg = math.floor, math.abs, math.min, math.max, math.atan2, math.deg
local thing = 650
local camera = {x = 0, y = 0, targetX = 0, targetY = 0, locked = false}
local camera_3d = {x = thing / 2, y = 5, z = thing / 2, yaw = 0, pitch = 0, roll = 0}
local chaser = {x = -200, y = 0, z = -200, speed = 23}

local moveSpeed, mouseSensitivity = 8, 0.002
local walkTime = 0

local canvas
scale_factor = 1
offset_x = 0
offset_y = 0
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

local idk_img = fast.getImage("images/idk.png")
local chase_img = fast.getImage("images/chase.png")
local bush_img = fast.getImage("images/bush.png")
local egg_mob = fast.getImage("images/egg_mob.png")

knuck_bg = fast.getImage("images/background/knuck.png")
knuck_bg2 = fast.getImage("images/background/knuck2.png")
knuck_bg3 = fast.getImage("images/background/knuck3.png")

local selectionImages = {
    selection_box = fast.getImage("images/selection/box.png"),
    tails_selection = fast.getImage("images/selection/tails_selection.png"),
    knuck_selection = fast.getImage("images/selection/knuckles_selection.png"),
    eggman_selection = fast.getImage("images/selection/eggman_selection.png"),

    dead_tails = fast.getImage("images/selection/dead_tails.png"),
    dead_knuckles = fast.getImage("images/selection/dead_knuckles.png"),
    dead_eggman = fast.getImage("images/selection/dead_eggman.png")
}

local mapImages = {
    test2 = fast.getImage("images/maps/test2.png"),
    test3 = fast.getImage("images/maps/map1.png"),
    knuck1 = fast.getImage("images/maps/knuck1.png"),
    gh1 = fast.getImage("images/maps/gh1.png"),
    testmap = fast.getImage("images/maps/testmap.png")
}

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
    reboot_old = "sounds/reboot_old.ogg",
    bossMusic = "music/Demo_fight.mp3",
    tails_stage = "music/tails_stage.ogg",
    demo_song = "music/demo_song.ogg",
    glitch_sound = "sounds/glitch_sound.mp3",
    jump_sound = "sounds/jump_sound.mp3",
    laugh_sound = "sounds/laugh.mp3",
    S3K_9A = "sounds/S3K_9A.wav",
    lights_off = "sounds/lights-sound-effect.mp3",
    error_sound = "sounds/error_sound.mp3",
    sonic_error_sound = "sounds/sonic_error_sound.mp3"
}

local sounds = {}

for name, path in pairs(soundDefs) do
    sounds[name] = love.audio.newSource(path, (path:find("music") and "stream") or "static")
end

local images = {}
local quads = {}
selectionState = "tails"
selectionIndex = 1
selectionOptions = {"tails", "knuckles", "eggman"}

local mapFiles = {
    map = "images/maps/test.png",
    map1 = "images/maps/map2.png",
    map2 = "images/maps/knuck2.png",
    map3 = "images/maps/gh2.png",
    testmap2 = "images/maps/testmap.png"
}

local maps = {}
function getMap(name)
    if not maps[name] then
        maps[name] = loadMap(mapFiles[name])
    end
    return maps[name]
end

function loadMap(path)
    local img = fast.getImage(path)
    local imageData = love.image.newImageData(path)
    local w, h = imageData:getDimensions()
    local collision = {}
    collision.width, collision.height = w, h
    imageData:mapPixel(function(x, y, r, g, b, a)
        collision[y * w + x + 1] = a > 0.1
        return r, g, b, a
    end)
    imageData:release()
    return {image = img, collision = collision, width = w, height = h}
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
        acceleration = 100,
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
        targetX = 0,
        targetY = 0,
        fakeAngle = 0,
        _coyote = 0,
        _jumpBuf = 0,
        physics_enabled = opts.physics_enabled or false
    }
end

local function loadFrames(basePath, count)
    return fast.getFrames(basePath, count)
end

local chunkSize, renderDistance = 4, 24
leftwImage = fast.getImage("images/arrows/leftw.png")
rightwImage = fast.getImage("images/arrows/rightw.png")

flashAlpha, flashDuration, flashTimer = 0, 0.5, 0
local isFlashing = false
local function initCharacterSprite(character, defaultSprite)
    character.currentSprite = defaultSprite
    character.spriteIndex = 1
    return character
end

local function initArraySprite(character, spriteArray)
    character.spriteIndex = 1
    character.currentSprite = spriteArray[1]
    return character
end

function flashScreen(duration)
    flashAlpha = 1
    flashDuration = duration or 0.5
    flashTimer = flashDuration
    isFlashing = true
end

transitionAlpha, transitioning, transitionTarget, transitionSpeed = 1, false, "", 1.5
colorPhaseTime, colorTimer, colorLerp = 0.25, 0, 0
function startTransition(target)
    transitioning = true
    transitionTarget = target
    colorTimer = 0
    colorLerp = 0
end

stage1 = fast.getImage(spritesFolder.."sonic_demo.exe/anim/knuckles/stage1.png")
stage1_vis = true
s1 = createCharacter{x = 100, y = 50}
s1.stage2 = loadFrames(spritesFolder .. "sonic_demo.exe/anim/knuckles/stage2/", 2)
stage2_vis = true
stage3 = fast.getImage(spritesFolder.."sonic_demo.exe/anim/knuckles/stage3.png")
stage3_vis = true

local tail_tails = {
    x = 100,
    y = 50,
    width = 32,
    height = 32
}
tail_tails.idle = loadFrames(spritesFolder .. "tail/", 5)

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

local credits_text = {}
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
    radius = 60,
    active = false
}

joystickBaseImage = fast.getImage("images/mobile_stuff/base.png")
joystickKnobImage = fast.getImage("images/mobile_stuff/knob.png")
jumpButtonImage = fast.getImage("images/mobile_stuff/jump.png")

local tails = createCharacter{ x = 100, y = 50, maxSpeed = 200 }
tails.idle = fast.getImage(spritesFolder .. "tails/idle.png")
tails.down = fast.getImage(spritesFolder .. "tails/down.png")
tails.fall = fast.getImage(spritesFolder .. "tails/fall.png")
tails.up = fast.getImage(spritesFolder .. "tails/up.png")
tails.walk = loadFrames(spritesFolder .. "tails/walking/", 8)
tails.jump = loadFrames(spritesFolder .. "tails/jump/", 3)
tails.run = loadFrames(spritesFolder .. "tails/run/", 2)
tails.damage = loadFrames(spritesFolder .. "tails/damage/", 2)
tails = initCharacterSprite(tails, tails.idle)

local knuckles = createCharacter{ x = 100, y = 50, maxSpeed = 200 }
knuckles.idle = fast.getImage(spritesFolder .. "knuckles/idle.png")
knuckles.walk = loadFrames(spritesFolder .. "knuckles/walking/", 7)
knuckles.run = loadFrames(spritesFolder .. "knuckles/run/", 4)
knuckles.jump = loadFrames(spritesFolder .. "knuckles/jump/", 5)
knuckles = initCharacterSprite(knuckles, knuckles.idle)

local eggman = createCharacter{ x = 3300, y = 50, maxSpeed = 140 }
eggman.idle = fast.getImage(spritesFolder .. "eggman/idle.png")
eggman.down = fast.getImage(spritesFolder .. "eggman/down.png")
eggman.walk = loadFrames(spritesFolder .. "eggman/walking/", 3)
eggman.run = loadFrames(spritesFolder .. "eggman/walking/", 3)
eggman.jump = loadFrames(spritesFolder .. "eggman/walking/", 1)
eggman.crashed = fast.getImage(spritesFolder.."eggman/crashed.png")
eggman = initCharacterSprite(eggman, eggman.idle)

local sonic_demoexe = createCharacter{x = -100, y = -140 }
sonic_demoexe.idle = fast.getImage(spritesFolder .. "sonic_demo.exe/idle.png")
sonic_demoexe.crouch = fast.getImage(spritesFolder .. "sonic_demo.exe/crouch.png")
sonic_demoexe.anim_tails = loadFrames(spritesFolder .. "sonic_demo.exe/anim/tails/", 8)
sonic_demoexe.float = loadFrames(spritesFolder .. "sonic_demo.exe/float/", 2)
sonic_demoexe.jump = loadFrames(spritesFolder .. "sonic_demo.exe/jump/", 5)
sonic_demoexe.run = loadFrames(spritesFolder .. "sonic_demo.exe/run/", 4)
sonic_demoexe.walk = loadFrames(spritesFolder .. "sonic_demo.exe/walk/", 6)
sonic_demoexe.fly = loadFrames(spritesFolder .. "sonic_demo.exe/fly/fly", 2)
sonic_demoexe.fall = loadFrames(spritesFolder .. "sonic_demo.exe/fall/", 2)
sonic_demoexe.kill_tails = loadFrames(spritesFolder .. "sonic_demo.exe/kill/test/", 7)
sonic_demoexe.fly_anim = loadFrames(spritesFolder .. "sonic_demo.exe/fly/anim/", 3)
sonic_demoexe.cr4sh = fast.getImage(spritesFolder.."sonic_demo.exe/fly/anim/cr4sh.png")
sonic_demoexe.anim_tails = loadFrames(spritesFolder.."sonic_demo.exe/anim/tails/", 8)
sonic_demoexe = initCharacterSprite(sonic_demoexe, sonic_demoexe.idle)

test_character = createCharacter{x = -100, y = -140, maxSpeed = 200 }
test_character.idle = fast.getImage(spritesFolder .. "sonic_demo.exe/idle.png")
test_character.run = loadFrames(spritesFolder .. "sonic_demo.exe/run/", 4)
test_character.walk = loadFrames(spritesFolder .. "sonic_demo.exe/walk/", 6)
test_character.jump = loadFrames(spritesFolder .. "sonic_demo.exe/jump/", 5)
test_character = initCharacterSprite(test_character, test_character.idle)

local sonic_demoexe_screen = createCharacter{x = 0, y = 355}
sonic_demoexe_screen.idle = fast.getImage(spritesFolder .. "screen/idle_new.png")
sonic_demoexe_screen.grab = loadFrames(spritesFolder .. "screen/grab/", 5)
sonic_demoexe_screen = initCharacterSprite(sonic_demoexe_screen, sonic_demoexe_screen.idle)

local fire_bg = initCharacterSprite(fire_bg, fire_bg.idle)
local tail_tails = initArraySprite(tail_tails, tail_tails.idle)
local s1 = initArraySprite(s1, s1.stage2)

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
    credits = {
        {name = "CopiluCuSarmale", role = "Director, Game Dev, Artist, Animator, Coder, Document, Composer", img = "copilucusarmale.png"},
        {name = "Replayer", role = "Game Tester, Document, Sonic_DEMO.exe's laugh", img = "replayer.png"},
        {name = "Leon", role = "Document", img = "leon.png"},
        {name = "Saunter", role = "Coder, Composer", img = "saunter.png"},
        {name = "Trigavid", role = "Composer", img = "trigavid.png"},
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

function clamp(val, minVal, maxVal) return max(minVal, min(maxVal, val)) end
function lerp(a, b, t) return a + (b - a) * t end

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
    camera_3d.yaw = camera_3d.yaw + (targetYaw - camera_3d.yaw) * min(dt * smoothSpeed, 1)
    camera_3d.pitch = camera_3d.pitch + (targetPitch - camera_3d.pitch) * min(dt * smoothSpeed, 1)
    camera_3d.roll = camera_3d.roll + (targetRoll - camera_3d.roll) * min(dt * rollReturnSpeed, 1)
    targetRoll = targetRoll + (0 - targetRoll) * min(dt * rollReturnSpeed, 1)
    local inputX, inputZ = 0, 0
    if love.keyboard.isDown("w") then inputZ = inputZ + 1 end
    if love.keyboard.isDown("s") then inputZ = inputZ - 1 end
    if love.keyboard.isDown("a") then inputX = inputX - 1 end
    if love.keyboard.isDown("d") then inputX = inputX + 1 end
    if joystick.dy < -0.2 then inputZ = inputZ + 1 end
    if joystick.dy >  0.2 then inputZ = inputZ - 1 end
    if joystick.dx < -0.2 then inputX = inputX - 1 end
    if joystick.dx >  0.2 then inputX = inputX + 1 end
    local len = inputX*inputX + inputZ*inputZ
    if len > 0 then
        len = 1 / math.sqrt(len)
        inputX, inputZ = inputX * len, inputZ * len
    end

    local accel = min(dt * 12, 1)
    velX = velX + (inputX * moveSpeed - velX) * accel
    velZ = velZ + (inputZ * moveSpeed - velZ) * accel

    if abs(velX) > 0.01 or abs(velZ) > 0.01 then
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
        local speedFactor = 1 + max(0, (20 - dist) / 20) * 2
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
    preloadTiles()
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

local function updateSprite(dt, spriteTable, char)
    char.spriteIndex = char.spriteIndex + dt * 10
    if char.spriteIndex >= #spriteTable + 1 then
        char.spriteIndex = 1
    end
    char.currentSprite = spriteTable[floor(char.spriteIndex)] or spriteTable[1]
end

local sonic_demoexe_triggered = false
local sonic_demoexe_animating = false
local sonic_demoexe_wait_timer = 0

local currentColor = {1, 1, 1}
local lerpSpeed = 5

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
tort_visible2 = false
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
    sounds.cr4sh_sound:stop()
    cheat_time = cheat_time + dt

    if cheat_time >= 5 and cheating_alpha < 0.36 then
        cheating_alpha = min(0.36, cheating_alpha + 0.1 * dt)
        cheating_vis = true
        sonic_demoexe_screen.currentSprite = sonic_demoexe_screen.idle
    end

    if cheat_time >= 12 and not soundPlayed2 then
        cheating_vis = false
        cheating_vis2 = true
        sounds.enterSound:play()
        soundPlayed2 = true
    end

    if cheat_time >= 13 and cheating_alpha2 > 0 then
        cheating_alpha2 = max(0, cheating_alpha2 - 0.1 * dt)
    end

    if cheat_time >= 20 then
        cheating_vis2 = false
        cheating_vis = true
        local grab = sonic_demoexe_screen.grab
        updateSprite(dt * 1.35, grab, sonic_demoexe_screen)
        if sonic_demoexe_screen.spriteIndex > #grab then
            sonic_demoexe_screen.spriteIndex = #grab
        end
        if cheat_time >= 25 then
            gamestate = "william"
        end
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

function getControls()
    local jdx = joystick.active and (joystick.dx or 0) or 0
    local jdy = joystick.active and (joystick.dy or 0) or 0

    local moveRight = love.keyboard.isDown("right") or jdx > JOYSTICK_MOVE_THRESHOLD
    local moveLeft = love.keyboard.isDown("left") or jdx < -JOYSTICK_MOVE_THRESHOLD
    local jump  = love.keyboard.isDown("space") or love.keyboard.isDown("a") or jumpButton.active

    local lookUp = (love.keyboard.isDown("up") or jdy < -JOYSTICK_LOOK_THRESHOLD) and not jump and not moveRight and not moveLeft
    local lookDown = (love.keyboard.isDown("down") or jdy >  JOYSTICK_LOOK_THRESHOLD) and not jump and not moveRight and not moveLeft

    return moveRight, moveLeft, jump, lookUp, lookDown
end

TOP_SPEED, GROUND_ACCEL, GROUND_DECEL = 220, 780, 1500
GROUND_FRICTION, AIR_ACCEL, AIR_DECEL = 1300, 400, 360
JUMP_VELOCITY, JUMP_HOLD_TIME, COYOTE_TIME, JUMP_BUFFER = -310, 0.18, 0.10, 0.10
AIR_DRAG, MAX_STEP_HEIGHT = 0.99609375, 10

function approach(v, target, amt)
    if v < target then return min(v + amt, target)
    elseif v > target then return max(v - amt, target) end
    return v
end

function checkCollision(char, map, x, y)
    if type(map) == "string" then
        map = getMap(map)
        if not map then return false end
    end

    local halfW, halfH = char.width / 2, char.height / 2
    local left, right = floor(x - halfW), floor(x + halfW - 1)
    local top, bottom = floor(y - halfH), floor(y + halfH - 1)

    for ty = top, bottom do
        if ty >= 0 and ty < map.height then
            for tx = left, right do
                if tx >= 0 and tx < map.width then
                    local idx = ty * map.width + tx + 1
                    if map.collision[idx] then
                        return true
                    end
                end
            end
        end
    end
    return false
end

function getGroundY(char, map, baseX, baseY)
    local startY = floor(baseY + char.height / 2)
    for y = startY, startY + MAX_STEP_HEIGHT do
        if checkCollision(char, map, baseX, y - char.height / 2) then
            return y - char.height / 2
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

    char.y = approach(char.y, groundY, SNAP_SPEED * dt)
    local distance = abs(char.y - groundY)
    char.grounded = distance < 1
    if char.grounded and char.velocity.y > 0 then
        char.velocity.y = 0
    end

    return true
end

function getGroundSlope(char, map, x, y)
    local step = 2
    local yL = getGroundY(char, map, x - step, y)
    local yR = getGroundY(char, map, x + step, y)

    if yL and yR then
        local dy = yR - yL
        local dx = (step * 2)
        return atan2(dy, dx)
    end
    return 0
end

function applySlopePhysics(char, vx, vy, slopeAngle, dt)
    local speed = vx
    local sinA, cosA = math.sin(slopeAngle), math.cos(slopeAngle)
    local vxs = speed * cosA
    local vys = speed * sinA
    vy = vy + 400 * dt  

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

function test_update(dt, char, map)
    local mapObj = getMap(map)
    if not mapObj then return end
    local mapWidth, mapHeight = mapObj.width or 2000, mapObj.height or 1080
    char.velocity = char.velocity or {x = 0, y = 0}
    char.jumping = char.jumping or false
    char.grounded = char.grounded or false
    char._coyote = char._coyote or 0
    char._jumpBuf = char._jumpBuf or 0

    local vx, vy = char.velocity.x, char.velocity.y

    local moveRight, moveLeft, jump, lookUp, lookDown = getControls()
    local inputDir = quantize((moveRight and 1 or 0) - (moveLeft and 1 or 0))
    local isDemoWithPhysics = (char == sonic_demoexe) and (sonic_demoexe.physics_enabled == true)

    if tail_tails and tail_tails.idle then
        updateSprite(dt * 0.5, tail_tails.idle, tail_tails)
    end

    snapToGround(char, map, dt)
    local grounded = char.grounded

    char._coyote = grounded and COYOTE_TIME or math.max(0, char._coyote - dt)
    char._jumpBuf = jump and JUMP_BUFFER or math.max(0, char._jumpBuf - dt)

    if char == sonic_demoexe and isDemoWithPhysics then
        if grounded then
            vx = approach(vx, 0, (GROUND_FRICTION))
        else
            vx = vx * AIR_DRAG
            vy = vy + (char.jumping and 1250) * dt
        end
    elseif char ~= sonic_demoexe then
            if grounded and (lookUp or lookDown) then
                local groundY = getGroundY(char, map, char.x, char.y)
                if groundY then
                    char.y, vy, vx = groundY, 0, 0
                end
                char.currentSprite = lookUp and (char.up or char.idle) or (char.down or char.idle)
                char.angle, char.fakeAngle = 0, 0
                char.velocity.x, char.velocity.y = vx, vy
                return
            elseif moveRight or moveLeft then
                char.direction = moveRight and 1 or -1
                local accel = char.acceleration
                local maxS = char.maxSpeed
                vx = clamp(vx + accel * inputDir * dt, -maxS, maxS)
            else
                if grounded then
                    local slopeAngle = getGroundSlope(char, map, char.x, char.y)
                    vx, vy = applySlopePhysics(char, vx, vy, slopeAngle, dt)
                    if inputDir ~= 0 then
                        vx = clamp(vx + GROUND_ACCEL * inputDir * dt, -TOP_SPEED, TOP_SPEED)
                    else
                        vx = approach(vx, 0, GROUND_FRICTION * dt)
                    end
                else
                    if inputDir ~= 0 then
                        vx = clamp(vx + AIR_ACCEL * inputDir * dt, -TOP_SPEED, TOP_SPEED)
                    else
                        vx = approach(vx, 0, AIR_DECEL * dt)
                    end
                end
                if grounded then
                    vx = vx * (1 - GROUND_FRICTION)
                    if math.abs(vx) < 0.1 then
                        vx = 0
                    end
                else
                    vx = vx * AIR_DRAG
                end
                if math.abs(vx) == 0 and not char.jumping then
                    char.angle, char.fakeAngle = 0, 0
                end
            end
            if (jump and grounded) or (char._jumpBuf > 0 and char._coyote > 0 and not char.jumping) then
                vy = char.jumpHeight
                char.jumping, char.grounded, char._jumpBuf = true, false, 0
                if sounds and sounds.jump_sound then sounds.jump_sound:play() end
            end

            if (char._jumpBuf > 0 and char._coyote > 0 and not char.jumping) then
                vy = char.jumpHeight
                char.jumping, char.grounded = true, false
                char._jumpBuf = 0
                if sounds and sounds.jump_sound then sounds.jump_sound:play() end
            end

            if jump and grounded then
                local slopeAngle = getGroundSlope(char, map, char.x, char.y)
                vx = vx + JUMP_VELOCITY * math.sin(slopeAngle) * -1
                vy = JUMP_VELOCITY * math.cos(slopeAngle) -50
                char.jumping, char.grounded = true, false
            end

            local absVx = math.abs(vx)
            if not char.grounded then
                if char.jumping then
                    if char.jump then updateSprite(dt, char.jump, char) end
                else
                    if char.walk then
                        updateSprite(dt * 0.75, char.walk, char)
                    else
                        char.currentSprite = char.jump or char.idle
                    end
                end
            elseif not jump and char.jumping and vy < 0 then
                if char.jump then updateSprite(dt, char.jump, char) end
            elseif char.grounded and lookUp and vx == 0 then
                char.currentSprite = char.up or char.idle
            elseif char.grounded and lookDown and vx == 0 then
                char.currentSprite = char.down or char.idle
            elseif absVx >= (char.runThreshold or 175) then
                if char.run then updateSprite(dt, char.run, char) end
            elseif absVx > 0 then
                local speedScale = (absVx / (char.maxSpeed or 200)) + 0.3
                if char.walk then updateSprite(dt * speedScale, char.walk, char) end
            else
                if lookUp and vx == 0 then
                    char.currentSprite = char.up or char.idle
                elseif lookDown and vx == 0 then
                    char.currentSprite = char.down or char.idle
                else
                    char.currentSprite = char.idle
                end
            end
        end

    if not char.grounded then
        vy = vy + (char.jumping and 625 or 400) * dt
        vx = vx * AIR_DRAG
    end

    local nextX, nextY = char.x + vx * dt, char.y + vy * dt
    if not checkCollision(char, map, nextX, char.y) then
        char.x = nextX
    else
        local stepped
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
            char.grounded = true
            char.jumping = false
            vy = 0
            snapToGround(char, map, dt)
        elseif vy < 0 then
            char.grounded = false
            vy = 0
            char.y = char.y + 1
        end
    end

    char.x = clamp(char.x, 15, mapWidth - 15)
    char.velocity.x, char.velocity.y = vx, vy
    if char ~= sonic_demoexe then
        if char.y >= mapHeight + 40 then love.event.quit() end
        updateCamera(dt, char, mapWidth, mapHeight)
    end
    updateGamestate(dt, char)
end

local hs_timer = 7
local hs_totalTime = 0
local tails_hiding = false
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

sonic_demoexe.bounceCount = 0
bossfightTimer = sounds.bossMusic:getDuration("seconds")
bossfightTimer = 0
bossfightActive = false

blackScreen = false
blackTimer = 0

local function handleBounce(knuck, demo, dt)
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
    updateSprite(dt * 0.5, s1.stage2, s1)
    if not demo_vis then
        local demo = sonic_demoexe
        demo.currentSprite = demo.crouch
        demo.x, demo.y, demo.direction = 6453, 772, -1
    end

    if knuckles.x >= 2400 then stage1_vis = false end
    if knuckles.x >= 4250 then
        stage2_vis, knuck_bg, demo_vis = false, knuck_bg2, true
    end
    if knuckles.x >= 5350 then
        stage3_vis, knuck_bg = false, knuck_bg3
    end

    if knuckles.x <= 5990 then return end

    waiting_knuck = waiting_knuck + dt
    test_update(dt, sonic_demoexe, "map2")

    local map2 = getMap("map2")
    if not map2 then return end

    local targetCamX, camSpeed = map2.width - base_width, 950
    if not camera.locked then
        if camera.x < targetCamX then
            camera.x = min(camera.x + camSpeed * dt, targetCamX)
        end
        if camera.x >= targetCamX then
            camera.x = targetCamX
            camera.locked = true
        end
    end
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
        handleBounce(knuckles, demo, dt)

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
    if eggman.x < 1472 then
        if sonic_demoexe.grounded then
            updateSprite(dt, sonic_demoexe.float, sonic_demoexe)
        end

        if abs(eggman.y - sonic_demoexe.y) > 50 then
            sonic_demoexe.velocity.y = sonic_demoexe.jumpHeight
            updateSprite(dt, sonic_demoexe.fly, sonic_demoexe)
        end

        local dx = eggman.x - sonic_demoexe.x
        local dy = eggman.y - sonic_demoexe.y

        if dx ~= 0 then
            sonic_demoexe.x = sonic_demoexe.x + (dx / abs(dx)) * 682 * dt
        end

        local verticalSpeed = 305
        local deadzone = 10

        if abs(dy) > deadzone then
            sonic_demoexe.y = sonic_demoexe.y + (dy / abs(dy)) * verticalSpeed * dt
        end

        if eggman.x > sonic_demoexe.x then
            sonic_demoexe.direction = 1
        else
            sonic_demoexe.direction = -1
        end

        local triggerDistance = 125

        local dx = abs(eggman.x - sonic_demoexe.x)
        local dy = abs(eggman.y - sonic_demoexe.y)

        if not crashing and dx < triggerDistance and dy < triggerDistance then
            crashing = true
            crashTimer = 0
            charStatus.eggman_alive = false
            charStatus.eggman_lock = false
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

        local verticalSpeed = 305
        local deadzone = 10
        if abs(dy) > deadzone then
            sonic_demoexe.y = sonic_demoexe.y + (dy / abs(dy)) * verticalSpeed * dt
        end

        if not sonic_demoexe.grounded and sonic_demoexe.fly then
            updateSprite(dt, sonic_demoexe.fly, sonic_demoexe)
        elseif sonic_demoexe.grounded and sonic_demoexe.float then
            updateSprite(dt, sonic_demoexe.float, sonic_demoexe)
        end
        if math.abs(dx) < 32 and math.abs(dy) < 32 then
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

emhi_bg = fast.getImage("images/background/emerald hill.png")
menu_finished = fast.getImage("images/background/menu_finished.png")
menu = fast.getImage("images/background/menu.png")
menu2 = fast.getImage("images/background/menu2.png")

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
    if animation_timer3 >= 0.1 then
        animation_phase = "repeatable2"
    end
end

local repeatable2_timer = 0
local repeatable2_frame_duration = 0.075
local bg_vis = true

animHandlers.repeatable2 = function(dt)
    repeatable2_timer = repeatable2_timer + dt
    if repeatable2_timer >= repeatable2_frame_duration then
        repeatable2_timer = repeatable2_timer - repeatable2_frame_duration

        frame_index = (frame_index % #repeatable2_frames) + 1
        repeat_count = repeat_count + 1

        if repeat_count == 23 then
            sounds.cr4sh_sound:setLooping(true)
            sounds.cr4sh_sound:play()
            bg_vis = false
            menu2 = fast.getImage("images/background/menu3.png")
        end

        if repeat_count >= #repeatable2_frames then
            repeat_count = 0
            animation_phase = "black_screen"
        end
    end
end

animHandlers.black_screen = function(dt)
    sounds.cr4sh_sound:stop()
    bg_vis = true
    animation_timer2 = animation_timer2 + dt
    if animation_timer2 >= 0.2 then
        finished_transformation = true
        animation_phase = "done"
        frame_index3 = 1
        splash_timer = 0
        splash_done = false
    end
end
local animTime = 0.5
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
flickerMaxRepeats = 15
link = "https://docs.google.com/document/d/1J0nOXnQMULgsqhbdnPfF3uHCHJ0wMvX1BC4TgXKVpX8"
function menuscreen_update(dt)
    if gamestate ~= "menuscreen" then return end
    animation_timer = animation_timer + dt
    if animation_timer >= ANIM_SPEED and animHandlers[animation_phase] then
        animation_timer = 0
        animHandlers[animation_phase](dt)
    end

    --[[if finished_transformation and not splash_done then
        splash_timer = splash_timer + dt * 2
        if splash_timer >= 0.2011 then
            splash_timer = 0
            frame_index3 = frame_index3 + 1
            if frame_index3 >= #splash_frames.splash then
                frame_index3 = #splash_frames.splash
                splash_done = true
            end
        end
    end]]

    splash_done = true

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

        if (love.keyboard.isDown("return") or jumpButton.active) and finished_transformation then
            if sounds.laugh_sound then
                sounds.laugh_sound:play()
            end

            if not flickerActive then
                flickerActive = true
                flickerRepeat = 0
                flickerTimer = 0
                flickerSpeed = flickerInterval
                flickerMaxRepeats = 15
            end
        end

        if flickerActive then
            flickerTimer = flickerTimer + dt
            if flickerTimer >= flickerSpeed then
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
local greenHillZoneTitle = fast.getImage("images/zone/titles/zone.png")
local hideAndSeekZoneTitle = fast.getImage("images/zone/titles/h&s.png")
local DotTitle = fast.getImage("images/zone/titles/dot.png")
function drawTitleCard(stageNameImg, circleImg, actImg, baseX, baseY)
    drawStageCircle(circleImg, baseX + 10, baseY)
    drawStageName(stageNameImg, -baseX + 225, baseY)
    love.graphics.draw(stageActImg, baseX + greenHillZoneTitle:getWidth() - 25, baseY + circleImg:getHeight() - 4)
    drawStageAct(actImg, baseX + greenHillZoneTitle:getWidth() + 10, baseY + circleImg:getHeight() - 20)
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

local function updateScrollingBG(dt)
    if animation_phase == "initial" or not bg_vis then return end

    local width = menu:getWidth()
    bgX1, bgX2 = bgX1 + scroll_speed * dt, bgX2 + scroll_speed * dt
    if bgX1 >= width then bgX1 = bgX2 - width elseif bgX1 <= -width then bgX1 = bgX2 + width end
    if bgX2 >= width then bgX2 = bgX1 - width elseif bgX2 <= -width then bgX2 = bgX1 + width end
end

local function eggmanCrashThing(dt)
    if not crashing then
        love.window.setTitle("SONIC 2 3 1")
        test_update(dt, eggman, "map3")
        eggman_up(dt)
        return
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
end
local gamestateHandlers = {
    test = function(dt)
        test_update(dt, tails, "map")
        before_idk(dt)
        love.window.setTitle("SONIC 2 3 1")
    end,
    hs = function(dt)
        --if not tails_caught then
        test_update(dt, tails, "map1")
        --end
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
    end,
    knuck = function(dt)
        test_update(dt, knuckles, "map2")
        knuck_up(dt)
        love.window.setTitle("SONIC 2 3 1")
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
        love.window.setTitle("")
        cheating(dt)
    end,
    warning = function()
        if love.keyboard.isDown("return") or jumpButton.active then
            startTransition("error")
        end
    end,
}

function love.update(dt)
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

    if gamestate == "credits" then
        if love.keyboard.isDown("down") or joystick.dy > 0.2 then
            scrollY = scrollY + scrollSpeed * dt
        elseif love.keyboard.isDown("up") or joystick.dy < -0.2 then
            scrollY = scrollY - scrollSpeed * dt
        end

        local maxScroll = max(#credits * 120 - base_height + 50, 0)
        scrollY = max(0, min(scrollY, maxScroll))

        if love.keyboard.isDown("return") or jumpButton.active then
            openURL(link)
            love.event.quit()
        end
    elseif gamestate == "error" then
        elapsedTime4 = (elapsedTime4 or 0) + dt
        reboot_vis2 = elapsedTime4 >= 2 and elapsedTime4 < 6
        reboot_vis = elapsedTime4 >= 7

        if reboot_vis2 and not errorSoundPlayed then
            sounds.sonic_error_sound:play()
            errorSoundPlayed = true
        end

        if reboot_vis and not rebootDone then
            stageIncrementTimer = stageIncrementTimer or 0
            if not stageComplete then
                stageIncrementTimer = stageIncrementTimer + dt
                if stageIncrementTimer >= 0.5 then
                    stageIncrementTimer = stageIncrementTimer - 0.5
                    stageProgress = min(100, stageProgress + 10)
                    sounds.reboot_old:play()
                    stageComplete = stageProgress >= 100
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

    if gamestate ~= lastGamestate then
        titleCardPlayed = false
        lastGamestate = gamestate
    end
    if stages[gamestate] and not titleCardPlayed then
        triggerStageTitle()
        titleCardPlayed = true
    end

    menuscreen_update(dt)
    updateStageTitle(dt)
    updateScrollingBG(dt)
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

    local halfW, halfH = winWidth * 0.5, winHeight * 0.5
    local offsetX2 = (mouseX - halfW) * 0.025
    local offsetY2 = (mouseY - halfH) * 0.02

    local spacing = 100
    local baseX = halfW + offsetX2 + characterOffsetX
    local centerY = halfH + offsetY2

    love.graphics.draw(selectionImages.selection_box, halfW + offsetX2, centerY, 0, 1, 1,
    selectionImages.selection_box:getWidth() * 0.5, selectionImages.selection_box:getHeight() * 0.5)
    local characters = {
        { alive = charStatus.tails_alive, lock = charStatus.tails_lock, img = selectionImages.tails_selection, dead = selectionImages.dead_tails },
        { alive = charStatus.knuckles_alive, lock = charStatus.knuckles_lock, img = selectionImages.knuck_selection, dead = selectionImages.dead_knuckles },
        { alive = charStatus.eggman_alive, lock = charStatus.eggman_lock, img = selectionImages.eggman_selection, dead = selectionImages.dead_eggman }
    }

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
            love.graphics.draw(char.img, drawX, drawY, 0, scale, scale,
                char.img:getWidth() * 0.5, char.img:getHeight() * 0.5)
            if not char.lock then
                love.graphics.draw(lockImg, drawX - 10, drawY + 20, 0, scale, scale)
            end
        else
            love.graphics.draw(char.dead, drawX, drawY, 0, scale, scale,
                char.dead:getWidth() * 0.5, char.dead:getHeight() * 0.5)
        end
    end

    local arrowY = centerY - 25
    local leftArrowX = 50
    local rightArrowX = winWidth - 100

    local leftActive = love.keyboard.isDown("left") or joystick.dx < -0.5
    local rightActive = love.keyboard.isDown("right") or joystick.dx > 0.5

    if leftActive then
        love.graphics.setColor(0.5, 0.5, 0.5, selectionAlpha)
        leftArrowX = 40
    else
        love.graphics.setColor(1, 1, 1, selectionAlpha)
    end
    love.graphics.draw(leftwImage, leftArrowX, arrowY)

    if rightActive then
        love.graphics.setColor(0.5, 0.5, 0.5, selectionAlpha)
        rightArrowX = winWidth - 90
    else
        love.graphics.setColor(1, 1, 1, selectionAlpha)
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
        sprite = sprite[floor(char.spriteIndex + 0.5)] or sprite[1]
    end
    if sprite then
        local flipX = char.direction == -1 and -1 or 1
        local drawX = floor(char.x + offsetX + 0.5)
        local drawY = floor(char.y + offsetY + 0.5)

        love.graphics.draw(
            sprite,
            drawX,
            drawY,
            char.fakeAngle,
            flipX,
            1,
            floor(sprite:getWidth() / 2 + 0.5),
            floor(sprite:getHeight() / 2 + 0.5)
        )
    end
end

local function drawScrollingBG(image, x1, x2, offsetX, offsetY)
    local screenW, screenH = base_width, base_height
    if x1 + offsetX + image:getWidth() > 0 and x1 + offsetX < screenW then love.graphics.draw(image, x1 + offsetX, offsetY) end
    if x2 + offsetX + image:getWidth() > 0 and x2 + offsetX < screenW then love.graphics.draw(image, x2 + offsetX, offsetY) end
end

DEMO_MenuScreen = fast.getImage(spritesFolder.."menuscreen/splash/6.png")
greenHillZoneCircles = fast.getImage("images/zone/circles/g_hill.png")
greenHillZoneCircles_2 = fast.getImage("images/zone/circles/g_hill_2.png")
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
    local cy, sy = math.cos(-camera_3d.yaw), math.sin(-camera_3d.yaw)
    local cp, sp = math.cos(-camera_3d.pitch), math.sin(-camera_3d.pitch)

    local n = 0
    for t = 1, #baseplateTiles do
        local tile = baseplateTiles[t]
        if inRenderDistance(tile) then
            local verts = {}
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

                local invZ = 1 / (z2 * fovHalfTan)
                verts[i * 2 - 1] = x1 * invZ / aspect * hw + hw
                verts[i * 2]     = -y1 * invZ * hh + hh
            end

            if visible then
                local cx = (tile[1][1] + tile[3][1]) * 0.5 - camera_3d.x
                local cyPos = (tile[1][2] + tile[3][2]) * 0.5 - camera_3d.y
                local cz = (tile[1][3] + tile[3][3]) * 0.5 - camera_3d.z
                local distSq = cx*cx + cyPos*cyPos + cz*cz

                n = n + 1
                preloadedTiles[n] = preloadedTiles[n] or {}
                preloadedTiles[n].verts = verts
                preloadedTiles[n].col = tile[1][4]
                preloadedTiles[n].dist = distSq
            end
        end
    end
    for i = n + 1, #preloadedTiles do preloadedTiles[i] = nil end
end

local function draw_william()
    updateProjectionConstants()
    local cy, sy = math.cos(-camera_3d.yaw), math.sin(-camera_3d.yaw)
    local cp, sp = math.cos(-camera_3d.pitch), math.sin(-camera_3d.pitch)

    if not sounds.buildUPSound:isPlaying() then
        sounds.buildUPSound:play()
    end

    local coastFadeStart, coastFadeEnd = 45, 45
    local coastFadeStart2 = coastFadeStart * coastFadeStart
    local coastFadeEnd2   = coastFadeEnd * coastFadeEnd

    for i = 1, #preloadedTiles do
        local t = preloadedTiles[i]
        if t.verts and #t.verts >= 6 then
            local fade = clamp((coastFadeEnd2 - t.dist) / (coastFadeEnd2 - coastFadeStart2), 0, 1)
            local r, g, b = t.col[1] or 1, t.col[2] or 1, t.col[3] or 1
            love.graphics.setColor(r, g, b, fade)
            love.graphics.polygon("fill", t.verts)
        end
    end

    do
        local x, y, z = chaser.x - camera_3d.x, chaser.y - camera_3d.y, chaser.z - camera_3d.z
        local x1, z1 = x * cy - z * sy, x * sy + z * cy
        local y1 = y * cp - z1 * sp
        local z2 = y * sp + z1 * cp

        if z2 > 0.1 then
            local invZ = 1 / z2
            local scale = 25 * invZ
            local sx = x1 / (z2 * fovHalfTan * aspect)
            local sy = y1 / (z2 * fovHalfTan)

            local distSq = dist2(camera_3d, chaser)
            local fadeStart2, fadeEnd2 = 100*100, 15*15
            local alpha = clamp((fadeStart2 - distSq) / (fadeStart2 - fadeEnd2), 0, 1)

            love.graphics.setColor(1, 1, 1, alpha)
            love.graphics.draw(
                chase_img,
                sx * hw + hw - chase_img:getWidth() * scale / 2,
                -sy * hh + hh - chase_img:getHeight() * scale / 2,
                0, scale, scale
            )
        end
    end
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(idk_img, 0, 0, 0, base_width / idk_img:getWidth(), base_height / idk_img:getHeight())

    drawStats()
end

function draw_menuscreen()
    love.graphics.push()
    love.graphics.setColor(1, 1, 1, menuAlpha)
    love.graphics.translate(base_width/2, base_height/2)
    love.graphics.scale(menuShrink, menuShrink)
    love.graphics.translate(-base_width/2, -base_height/2)
    if finished_transformation then
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

        local t = min(pressTextTimer / pressTextAnimTime, 1)
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

    local t = min(timer / animTime, 1)
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
        sounds.sonic_theme:stop()
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
    return max(0, min(1, t))
end

function tails_tail_thing()
    local tailSprite = tail_tails.currentSprite
    local tailsSprite = tails.currentSprite

    if not tailSprite then
        print("idk")
        return
    end

    if tailsSprite == tails.idle or tailsSprite == tails.down or tailsSprite == tails.up then
        local flipX = (tails.direction == -1) and -1 or 1
        local offsetX = (flipX == 1) and -12 or 12

        local halfW = tailSprite:getWidth() * 0.5
        local halfH = tailSprite:getHeight() * 0.5

        love.graphics.draw(
            tailSprite,
            tails.x + offsetX, tails.y + 5,
            0,
            flipX, 1,
            halfW, halfH
        )
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

    if jumpButton.active then
        love.graphics.setColor(1, 1, 1, 0.75)
    else
        love.graphics.setColor(1, 1, 1, 1)
    end

    love.graphics.draw(
        jumpButtonImage,
        jumpButton.x - jumpButtonImage:getWidth() / 2 * SCALE,
        jumpButton.y - jumpButtonImage:getHeight() / 2 * SCALE,
        0,
        SCALE, SCALE
    )
end

local transitionCanvas = love.graphics.newCanvas(base_width, base_height)

function love.draw()
    love.graphics.setFont(Font)
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0,0,0,1)
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", 0, 0, base_width, base_height)
    love.graphics.setColor(1, 1, 1)

    local camX, camY = floor(camera.x + 0.5), floor(camera.y + 0.5)

    local function drawStageTitle(titleImg, circlesImg, actImg)
        if not showStageTitle then return end

        local remaining = stageTitleDuration - stageTitleTimer
        if remaining <= 0 then return end
        local alpha = (remaining < stageTitleFadeTime)
            and (remaining / stageTitleFadeTime)
            or 1

        if alpha <= 0 then return end
        love.graphics.setColor(0, 0, 0, alpha)
        love.graphics.rectangle("fill", 0, 0, base_width, base_height)
        love.graphics.setColor(1, 1, 1, 1)

        local y = base_height / 2 - 40
        local endX = (base_width - titleImg:getWidth()) / 2 - 60
        local slideX

        if remaining < stageTitleFadeTime then
            local exitProgress = 1 - (remaining / stageTitleFadeTime)
            slideX = lerp(endX, base_width + 130, linearTime(exitProgress))
        else
            local enterProgress = min(stageTitleTimer / stageTitleFadeTime, 1)
            slideX = lerp(-100, endX, linearTime(enterProgress))
        end

        drawTitleCard(titleImg, circlesImg, actImg, slideX, y)
    end

    if gamestate == "menuscreen" or gamestate == "selection" then
        local mx, my = love.mouse.getPosition()
        local px = (max(0, min(base_width, (mx-offset_x)/scale_factor)) - base_width/2) * 0.05
        local py = (max(0, min(base_height, (my-offset_y)/scale_factor)) - base_height/2) * 0.05
        drawScrollingBG(menu_finished, bgX1, bgX2, px*0.5, py*0.4)
    end

    if gamestate == "menuscreen" then
        draw_menuscreen()
    elseif gamestate == "selection" then
        selection()
    elseif gamestate == "test" then
        sounds.buildUPSound:stop()
        sounds.green_hill:play()
        love.graphics.setColor(currentColor)
        drawScrollingBG(emhi_bg, bgX1, bgX2, 0,0)
        love.graphics.setColor(1,1,1)

        love.graphics.push()
        love.graphics.translate(-camX, -camY)
        love.graphics.draw(mapImages.test2, 0,0)
        if sonic_demoexe.currentSprite then love.graphics.draw(sonic_demoexe.currentSprite,10948,730) end
        tails_tail_thing()
        char_draw(tails,0,2)
        love.graphics.pop()

        drawStats()
        drawStageTitle(greenHillZoneTitle, greenHillZoneCircles, stageActImg1)

    elseif gamestate == "hs" then
        love.graphics.push()
        if bushes_destroyed then love.graphics.draw(fire_bg.currentSprite,0,0) end
        love.graphics.translate(-camX, -camY)
        love.graphics.draw(mapImages.test3,0,0)
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
            love.graphics.setColor(0,0,0)
            love.graphics.print(text, base_width-w-17,33)
            love.graphics.setColor(1,1,0)
            love.graphics.print(text, base_width-w-20,30)
        end
        drawStageTitle(hideAndSeekZoneTitle, hideAndSeekZoneCircles, stageActImg2)

        if show_black_screen then
            love.graphics.setColor(0,0,0,1)
            love.graphics.rectangle("fill",0,0, base_width, base_height)
            love.graphics.setColor(1,1,1)
        end

    elseif gamestate == "knuck" then
        love.graphics.push()
        drawScrollingBG(knuck_bg,bgX1,bgX2,0,0)
        love.graphics.translate(-camX,-camY)
        love.graphics.draw(mapImages.knuck1)
        char_draw(knuckles,0,-2)
        if demo_vis then char_draw(sonic_demoexe,0,-2) end
        if stage1_vis then love.graphics.draw(stage1, 2544, 518) end
        if stage2_vis and s1.currentSprite then love.graphics.draw(s1.currentSprite, 4387, 864) end
        if stage3_vis then love.graphics.draw(stage3, 5481, 867) end

        if stage1_vis == false then
            if not soundPlayed10 then
            sounds.sound_fix:play()
            flashScreen(0.45)
            soundPlayed10 = true
            end
        end

        if stage3_vis == false then
            if not soundPlayed8 then
            sounds.sound_fix:play()
            flashScreen(0.45)
            soundPlayed8 = true
            end
        end
        
        if stage2_vis == false then
            if not soundPlayed9 then
            sounds.sound_fix:play()
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
        if bossfightActive then
            local text = string.format("TIME LEFT: %.1f", bossfightTimer)
            local w = Font:getWidth(text)
            love.graphics.setColor(0,0,0)
            love.graphics.print(text, base_width-w-17,33)
            love.graphics.setColor(1,1,0)
            love.graphics.print(text, base_width-w-20,30)
            love.graphics.setColor(1, 1, 1)
        end
        drawStats()
        drawStageTitle(greenHillZoneTitle, hideAndSeekZoneCircles, stageActImg1)

        if blackScreen then
            love.graphics.setColor(0,0,0,1)
            love.graphics.rectangle("fill",0,0, base_width, base_height)
        end
        love.graphics.setColor(1, 1, 1)
    elseif gamestate == "eggman" then
        sounds.egg:play()
        if not crashing2 then drawScrollingBG(menu,bgX1,bgX2,0,0) end
        love.graphics.push()
        love.graphics.translate(-camX,-camY)
        love.graphics.draw(egg_mob,3200,903)
        love.graphics.draw(mapImages.gh1,0,0)
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

    elseif gamestate == "torture" and tort_visible then
        love.graphics.setColor(1,1,1,0.355)
        if sonic_demoexe_screen.currentSprite then
            love.graphics.draw(sonic_demoexe_screen.currentSprite)
        end
        love.graphics.setColor(1,1,1)
        local t = love.timer.getTime()
        love.graphics.print("Ready to be",125,50+math.sin(t*2)*2)
        love.graphics.print("Tortured?",285,200+math.sin(t*2.2)*3)
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
                love.graphics.print(text, base_width/2-FontBig:getWidth(text)/2, base_height/2-FontBig:getHeight()/2+math.sin(t*2.2)*3)
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
        love.graphics.printf("WARNING!\nThis game contains flash light ...",0,base_height/2-45,base_width,"center")
    elseif gamestate == "cheating" then
        love.graphics.setColor(1,1,1,cheating_alpha)
        if sonic_demoexe_screen.currentSprite and cheating_vis then
            love.graphics.draw(sonic_demoexe_screen.currentSprite)
        end
        love.graphics.setColor(1,1,1,cheating_alpha2)
        local t = love.timer.getTime()
        if cheating_vis2 then
            love.graphics.print("How dare you cheat within my realm, my game.",40,50+math.sin(t*2.5)*3)
            love.graphics.print("I won't let you escape from your fate that easily.",75,157+math.sin(t*2)*2)
        end
    elseif gamestate == "testmap" then
        love.graphics.push()
        love.graphics.translate(-camX,-camY)
        love.graphics.draw(mapImages.testmap,0,0)
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
    local r1, g1, b1, r2, g2, b2
    if transitioning then
        r1, g1, b1 = 1, 1, 1
        r2, g2, b2 = 0, 0, 1
    else
        r1, g1, b1 = 0, 0, 1
        r2, g2, b2 = 1, 1, 1
    end

    local r = r1 + (r2 - r1) * colorLerp
    local g = g1 + (g2 - g1) * colorLerp
    local b = b1 + (b2 - b1) * colorLerp

    local qr, qg, qb = quantizeColor(r, g, b, levels)
    love.graphics.setBlendMode("multiply", "premultiplied")
    love.graphics.setColor(qr, qg, qb)
    love.graphics.draw(transitionCanvas)
    love.graphics.setBlendMode("alpha")
    if alpha > 0 then
        love.graphics.setColor(0, 0, 0, alpha)
        love.graphics.rectangle("fill", 0, 0, base_width, base_height)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

function drawStats()
    local x, y = 10, 10

    love.graphics.draw(images.score, x, y)
    drawNumberString(x + 100, y - 1, tostring(stats.score))

    local minutes = floor(gameTime / 60)
    local seconds = floor(gameTime % 60)
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
          selectionIndex = min(#selectionOptions, selectionIndex + 1)
          sounds.reboot_old:play()
        elseif key == "left" then
          selectionIndex = max(1, selectionIndex - 1)
          sounds.reboot_old:play()
        end
    end
end

function love.resize(w, h)
    updateCanvasScale()
    resizeFreezeTimer = 0.5
end

function updateCanvasScale()
    local window_width, window_height = love.graphics.getDimensions()
    local scale_x = window_width / base_width
    local scale_y = window_height / base_height

    scale_factor = math.min(scale_x, scale_y)

    local scaled_width = base_width * scale_factor
    local scaled_height = base_height * scale_factor

    offset_x = math.floor((window_width - scaled_width) / 2 + 0.5)
    offset_y = math.floor((window_height - scaled_height) / 2 + 0.5)

    offset_x = math.max(0, offset_x)
    offset_y = math.max(0, offset_y)
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
        targetPitch = max(-math.pi*0.5, min(math.pi*0.5, targetPitch + dy * mouseSensitivity))
        targetRoll  = max(-0.15, min(0.15, -dx * rollStrength))
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
    for _, t in pairs(touches) do
        if t.x and t.x > base_width * 0.5 then
            return
        end
    end
    jumpButton.active = false
end

function sign(x)
    if x > 0 then
        return 1
    elseif x < 0 then
        return -1
    else
        return 0
    end
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