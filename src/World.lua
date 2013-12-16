function string.starts(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end

function string.ends(String,End)
   return End=='' or string.sub(String,-string.len(End))==End
end

local Constants = require 'conf'
local Drawable = require 'Drawable'
local Entity = require 'Entity'
local Player = require 'Player'
local Bullet = require 'Bullet'
local KeyboardInput = require 'input/KeyboardAndMouseInput'
local NetworkInput = require 'input/NetworkInput'

local atl = require 'lib/advanced-tiled-loader/Loader'

World = class('World', Drawable)

function World:initialize(networkClient)
  self.entities = {}
  self.networkClient = networkClient

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
    table.insert(self.entities, self.player)
    -- clone for now
    local ai = Player:new(self, playerLocationObject.x + 50, playerLocationObject.y, KeyboardAndMouseInput:new())
    table.insert(self.entities, ai)
  else
    self.player = Player:new(self, playerLocationObject.x, playerLocationObject.y, NetworkInput:new(self, self.networkClient, false))
    table.insert(self.entities, self.player)
    -- other players created on message
  end

  print("Map loaded.")
end

-- Insert Bullet
function World:insertBullet(angle, posX, posY)
	table.insert(self.entities, Bullet:new(self, posX, posY, angle))
  return self
end

-- Update logic
local updateWithNetworkInput = function(self, input)
  if string.starts(input, "Map") then
    local mapName = string.sub(input, 5, string.len(input) - 5)
    print("Load new map:", mapName)

    self:loadMap(mapName .. '.tmx')
  end
end
function World:update(dt)
  if self:isNetworkedWorld() then
    local networkData = self.networkClient:receive()
    if networkData then
      print(networkData)

      -- TODO parse network data and add forces etc
    end
  end

  for i, ent in pairs( self.entities ) do
    if ent.inputSource and networkData then
      print("Update input source")
      ent.inputSource:updateFromExternalInput(networkData)
    end

    ent:update(dt)
  end

  self.world:update(dt)
end

-- Render logic
function World:render()
  local translateX = Constants.SCREEN.WIDTH / 2 - self.player.body:getX()
  local translateY = Constants.SCREEN.HEIGHT / 2 - self.player.body:getY()

  love.graphics.translate(translateX, translateY)
  if self.map then
    self.map:autoDrawRange(translateX, translateY, 1, 0)
    self.map:draw()
  end

  for i, ent in pairs( self.entities ) do
    ent:render()
  end
end

return World
