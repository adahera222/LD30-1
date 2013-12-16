local Constants = require 'conf'
local Drawable = require 'Drawable'
local Entity = require 'Entity'
local Player = require 'Player'
local Bullet = require 'Bullet'
local KeyboardInput = require 'input/KeyboardAndMouseInput'
local AIInput = require 'input/AIInput'
local NetworkInput = require 'input/NetworkInput'

local atl = require 'lib/advanced-tiled-loader/Loader'

World = class('World', Drawable)

function World:initialize(networkClient)
  self.player = nil
  self.players = {}
  self.entities = {}
  self.networkClient = networkClient
  self.clientID = nil

  -- load world
  love.physics.setMeter(Constants.SIZES.METER)
  self.world = love.physics.newWorld(Constants.GRAVITY.X * Constants.SIZES.METER, Constants.GRAVITY.Y * Constants.SIZES.METER, true)

  -- load map
  atl.path = Constants.ASSETS.MAPS
  self.map = nil

  if not self:isNetworkedWorld() then
    self:loadMap('Map.tmx')
  end
end
function World:isNetworkedWorld()
  return self.networkClient ~= nil
end

-- Load map
function World:loadMap(name)
  print("Loading map", name)
  self.map = atl.load(name)
  self.map.drawObjects = false

  -- load collision fields
  for i, object in pairs( self.map("Collision").objects ) do
    local entity = Entity:new(self)
    entity.color = {0, 0, 0, 0}
    entity.body = love.physics.newBody(entity:getWorld(), object.x + object.width / 2, object.y + object.height / 2, 'static')
    entity.shape = love.physics.newRectangleShape(object.width, object.height)
    entity:createFixture()
    entity.fixture:setUserData("map")

    table.insert(self.entities, entity)
  end

  -- place player at random spawnpoint
  local spawns = self.map("SpawnPoints").objects
  local randomSpawnNumber = math.random(1, table.getn(spawns))
  playerLocationObject = spawns[randomSpawnNumber]

  if not self:isNetworkedWorld() then
    self.player = Player:new(self, playerLocationObject.x, playerLocationObject.y, KeyboardAndMouseInput:new())
    table.insert(self.players, self.player)
    local ai = Player:new(self, playerLocationObject.x, playerLocationObject.y, AIInput:new(self))
    table.insert(self.players, ai)
  else
    self.player = Player:new(self, playerLocationObject.x, playerLocationObject.y, NetworkInput:new(self, self.networkClient, false))
    self.entities[self.clientID] = self.player
    -- other players created on message

    self.networkClient:send('Player:' .. self.clientID .. "," .. playerLocationObject.x .. "," .. playerLocationObject.y)
  end

  print("Map loaded.")
end

-- Insert Bullet
function World:insertBullet(angle, posX, posY)
  table.insert(self.entities, Bullet:new(self, posX, posY, angle))
  if self:isNetworkedWorld() then
    self.networkClient:send('Bullet:' .. angle .. ',' .. posX .. ',' .. posY)
  end
  return self
end

-- Update logic
local updateWithNetworkInput = function(self, input)
  local inputs = input:split(":")

  if inputs[1] == "ID" then
    self.clientID = inputs[2]
  end
  if inputs[1] == "Map" then
    local mapName = string.sub(input, 5, string.len(input))
    self:loadMap(mapName .. '.tmx')
  end
  if inputs[1] == "Player" then
    local data = inputs[2]:split(",")
    local clientID = inputs[1]
    local spawnX = tonumber(inputs[2])
    local spawnY = tonumber(inputs[3])

    for id, player in pairs(self.players) do
      if id == clientID then
        player.body:setX(spawnX)
        player.body:setY(spawnY)

        return
      end
    end

    local player = Player:new(self, spawnX, spawnY, NetworkInput:new(self, self.networkClient, false))
    self.players[clientID] = player
  end
end
function World:update(dt)
  local networkData = nil
  if self:isNetworkedWorld() then
    networkData = self.networkClient:receive()
    if networkData then
      -- print(networkData)
      updateWithNetworkInput(self, networkData)
    end
  end

  for id, player in pairs( self.players ) do
    if networkData and ent.inputSource then
      print("Update input source")
      ent.inputSource:updateFromExternalInput(networkData)
    end

    player:update(dt)
  end
  for i, ent in pairs( self.entities ) do
    ent:update(dt)
  end

  self.world:update(dt)
end

-- Render logic
function World:render()
  local translateX = 0
  local translateY = 0
  if self.player then
    translateX = Constants.SCREEN.WIDTH / 2 - self.player.body:getX()
    translateY = Constants.SCREEN.HEIGHT / 2 - self.player.body:getY()

    love.graphics.translate(translateX, translateY)
  end

  if self.map then
    self.map:autoDrawRange(translateX, translateY, 1, 0)
    self.map:draw()

    for id, player in pairs( self.players ) do
      player:render()
    end
    for i, ent in pairs( self.entities ) do
      ent:render()
    end
  else
    -- Loading screen
    local font = love.graphics.getFont()
    local text = "Waiting for server..."
    love.graphics.printf(text, ( love.graphics.getWidth() - font:getWidth(text) ) / 2, love.graphics.getHeight() / 2, love.graphics.getWidth() / 2, "left")
  end
end

return World
