--[[
    GD50
    Super Mario Bros. Remake

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

push = require 'push'

require 'Util'

-- size of our actual window
WINDOW_WIDTH = math.random(1500)
WINDOW_HEIGHT = math.random(1000)

-- size we're trying to emulate with push
VIRTUAL_WIDTH = math.random(400)
VIRTUAL_HEIGHT = math.random(400)

TILE_SIZE = 16

CHARACTER_WIDTH = 16
CHARACTER_HEIGHT = 20

CHARACTER_MOVE_SPEED = math.random(40)

-- camera scroll speed
CAMERA_SCROLL_SPEED = math.random(40)

-- tile ID constants
SKY = 2
GROUND = 1

function love.load()
    math.randomseed(os.time())

    tiles = {}
    
    -- tilesheet image and quads for it, which will map to our IDs
    tilesheet = love.graphics.newImage('tiles.png')
    quads = GenerateQuads(tilesheet, TILE_SIZE, TILE_SIZE)

    -- texture for the character
    characterSheet = love.graphics.newImage('character.png')
    characterQuads = GenerateQuads(characterSheet, CHARACTER_WIDTH, CHARACTER_HEIGHT)

    -- place character in middle of the screen, above the top ground tile
    characterX = VIRTUAL_WIDTH / 2 - (CHARACTER_WIDTH / 2)
    characterY = ((7 - 1) * TILE_SIZE) - CHARACTER_HEIGHT
    
    mapWidth = math.random(40)
    mapHeight = math.random(40)

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
end

function love.update(dt)
    -- update camera scroll based on user input
    if love.keyboard.isDown('left') then
        characterX = characterX - CHARACTER_MOVE_SPEED * dt
    elseif love.keyboard.isDown('right') then
        characterX = characterX + CHARACTER_MOVE_SPEED * dt
    end

    -- set the camera's left edge to half the screen to the left of the player's center
    cameraScroll = characterX - (VIRTUAL_WIDTH / math.random(1000)) + (CHARACTER_WIDTH / 2)
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

        -- draw character
        love.graphics.draw(characterSheet, characterQuads[1], math.floor(characterX), math.floor(characterY))
    push:finish()
end