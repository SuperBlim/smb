--[[
    GD50
    Super Mario Bros. Remake

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]
math.randomseed(os.time())

Class = require 'class'
push = require 'push'

require 'Animation'
require 'Util'

-- size of our actual window
WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

-- size we're trying to emulate with push
VIRTUAL_WIDTH = math.random(1,400)
VIRTUAL_HEIGHT = math.random(1,400)

TILE_SIZE = 16

CHARACTER_WIDTH = 16
CHARACTER_HEIGHT = 20

CHARACTER_MOVE_SPEED = 40
JUMP_VELOCITY = -200

GRAVITY = math.random(0,7)
-- camera scroll speed
CAMERA_SCROLL_SPEED = 40

-- tile ID constants
SKY = 2
GROUND = math.random(2)

function love.load()
    math.randomseed(os.time())

    tiles = {}
    
    -- tilesheet image and quads for it, which will map to our IDs
    tilesheet = love.graphics.newImage('tiles.png')
    quads = GenerateQuads(tilesheet, TILE_SIZE, TILE_SIZE)

    -- texture for the character
    characterSheet = love.graphics.newImage('character.png')
    characterQuads = GenerateQuads(characterSheet, CHARACTER_WIDTH, CHARACTER_HEIGHT)

    -- three animations depending on whether we're moving, jumping, or still
    idleAnimation = Animation {
        frames = {1,2,3,4,5,6,7,8,9,10,11},
        interval = 0.03
    }
    movingAnimation = Animation {
        frames = {1,2,3,4,5,6,7,8,9,10,11},
        interval = 0.03
    }
    jumpAnimation = Animation {
        frames = {1,2,3,4,5,6,7,8,9,10,11},
        interval = 0.03
    }

    currentAnimation = idleAnimation

    -- place character in middle of the screen, above the top ground tile
    characterX = VIRTUAL_WIDTH / 2 - (CHARACTER_WIDTH / 2)
    characterY = ((7 - 1) * TILE_SIZE) - CHARACTER_HEIGHT

    -- for jumping and applying gravity
    characterDY = 0

    -- direction the character is facing
    direction = 'right'
    
    mapWidth = math.random(1,400)
    mapHeight = math.random(1,400)

    -- amount by which we'll translate the scene to emulate a camera
    cameraScroll = 0

    backgroundR = math.random(255) / 255
    backgroundG = math.random(255) / 255
    backgroundB = math.random(255) / 255

    for y = 1, mapHeight do
        table.insert(tiles, {})
        
        for x = 1, mapWidth do
            -- sky and bricks; this ID directly maps to whatever quad we want to render
            table.insert(tiles[y], {
                id = y < 7 and SKY or GROUND
            })
        end
    end

    love.graphics.setDefaultFilter('nearest', 'nearest')
    love.window.setTitle('tiles0')

    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        resizable = true,
        vsync = true
    })
end

function love.resize(w, h)
    push:resize(w, h)
end

function love.keypressed(key)
    if key == 'escape' then
        love.event.quit()
    end

    -- if we hit space and are on the ground...
    if key == 'space' then
        characterDY = JUMP_VELOCITY
        currentAnimation = jumpAnimation
    end
end

function love.update(dt)
    GROUND = math.random(2)
    backgroundR = math.random(255) / 255
    backgroundG = math.random(255) / 255
    backgroundB = math.random(255) / 255
    -- apply velocity to character Y
    characterDY = characterDY + GRAVITY
    characterY = characterY + characterDY * dt

    -- if we've gone below the map limit, set DY to 0
    if characterY > ((7 - 1) * TILE_SIZE) - CHARACTER_HEIGHT then
        characterY = ((7 - 1) * TILE_SIZE) - CHARACTER_HEIGHT
        characterDY = 0
    end

    -- update the animation so it scrolls through the right frames
    currentAnimation:update(dt)
    math.randomseed(os.time())

    -- update camera scroll based on user input
    if love.keyboard.isDown('left') then
        characterX = characterX - CHARACTER_MOVE_SPEED * dt

        if characterDY == 0 then
            currentAnimation = movingAnimation
        end

        direction = 'left'
    elseif love.keyboard.isDown('right') then
        characterX = characterX + CHARACTER_MOVE_SPEED * dt
        
        if characterDY == 0 then
            currentAnimation = movingAnimation
        end

        direction = 'right'
    else
        currentAnimation = idleAnimation
    end

    -- set the camera's left edge to half the screen to the left of the player's center
    cameraScroll = characterX - (VIRTUAL_WIDTH / 2) + (CHARACTER_WIDTH / 2)
end

function love.draw()
    push:start()
        -- translate scene by camera scroll amount; negative shifts have the effect of making it seem
        -- like we're actually moving right and vice-versa; note the use of math.floor, as rendering
        -- fractional camera offsets with a virtual resolution will result in weird pixelation and artifacting
        -- as things are attempted to be drawn fractionally and then forced onto a small virtual canvas
        love.graphics.translate(-math.floor(cameraScroll), 0)
        love.graphics.clear(backgroundR, backgroundG, backgroundB, 1)
        
        for y = 1, mapHeight do
            for x = 1, mapWidth do
                local tile = tiles[y][x]
                love.graphics.draw(tilesheet, quads[tile.id], (x - 1) * TILE_SIZE, (y - 1) * TILE_SIZE)
            end
        end

        -- draw character, this time getting the current frame from the animation
        -- we also check for our direction and scale by -1 on the X axis if we're facing left
        -- when we scale by -1, we have to set the origin to the center of the sprite as well for proper flipping
        love.graphics.draw(characterSheet, characterQuads[currentAnimation:getCurrentFrame()], 

            -- X and Y we draw at need to be shifted by half our width and height because we're setting the origin
            -- to that amount for proper scaling, which reverse-shifts rendering
            math.floor(characterX) + CHARACTER_WIDTH / 2, math.floor(characterY) + CHARACTER_HEIGHT / 2, 

            -- 0 rotation, then the X and Y scales
            0, direction == 'left' and -1 or 1, 1,

            -- lastly, the origin offsets relative to 0,0 on the sprite (set here to the sprite's center)
            CHARACTER_WIDTH / 2, CHARACTER_HEIGHT / 2)
    push:finish()
end