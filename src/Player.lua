local Constants = require 'conf'
local class = require 'lib/middleclass'
local Entity = require 'Entity'

Player = class('Player', Entity)

-- Init logic
function Player:initialize(world, x, y, inputSource)
  Entity:initialize(world)
  self.inputSource = inputSource
  
  self.body = love.physics.newBody(self.world, x, y, 'dynamic')
  self.body:setFixedRotation(true)
  self.shape = love.physics.newRectangleShape(Constants.SIZES.PLAYER.X, Constants.SIZES.PLAYER.Y)
  self:createFixture()
  self.fixture:setFriction(self.fixture:getFriction() * 1.75)

  self.bodyTexture = love.graphics.newImage('assets/textures/player/body.png')
  self.armTexture = love.graphics.newImage('assets/textures/player/arm.png')
  self.legTexture = love.graphics.newImage('assets/textures/player/leg_left.png')

  self.color = { 200, 0, 0, 255 }

  self.jumpWasPressed = false
  self.hasFallen = false
  self._oldVY = 0

  self.armRotation = 0
  self.legRotation = 0
end

function Player:update(dt)
  self.armRotation = self.armRotation+ dt

  local direction = self.inputSource:getDirection()
  local vX, vY = self.body:getLinearVelocity()

  -- X
  if direction == InputSource.Direction.left then
    if vX > 0 then
      self.body:applyLinearImpulse(Constants.SIZES.PLAYER.LEFT / 10, 0)
    else
      self.body:applyForce(Constants.SIZES.PLAYER.LEFT, 0)
    end
  elseif direction == InputSource.Direction.right then
    if vX < 0 then
      self.body:applyLinearImpulse(Constants.SIZES.PLAYER.RIGHT / 10, 0)
    else
      self.body:applyForce(Constants.SIZES.PLAYER.RIGHT, 0)
    end
  end
  
  -- Y
  if vY < 0 then
    self.hasFallen = true
  elseif vY == 0 and self._oldVY - vY < 1 then
    self.hasFallen = false
  end
  if self.inputSource:shouldJump() then
    if not self.hasFallen then
      self.body:applyLinearImpulse(0, Constants.SIZES.PLAYER.JUMP)
    end
  end
  self._oldVY = vY
end

function Player:render()
  love.graphics.setColor(self.color)

  local baseX = self.body:getX() - Constants.SIZES.PLAYER.X / 2
  local baseY = self.body:getY() - Constants.SIZES.PLAYER.Y / 2

  local scaleBodyX = self.bodyTexture:getWidth() / Constants.SIZES.PLAYER.SCALE / self.bodyTexture:getWidth()
  local scaleBodyY = self.bodyTexture:getHeight() / Constants.SIZES.PLAYER.SCALE / self.bodyTexture:getHeight()

  local scaleArmX = self.armTexture:getWidth() / Constants.SIZES.PLAYER.SCALE / self.armTexture:getWidth()
  local scaleArmY = self.armTexture:getHeight() / Constants.SIZES.PLAYER.SCALE / self.armTexture:getHeight()

  local scaleLegX = self.legTexture:getWidth() / Constants.SIZES.PLAYER.SCALE / self.legTexture:getWidth()
  local scaleLegY = self.legTexture:getHeight() / Constants.SIZES.PLAYER.SCALE / self.legTexture:getHeight()

  love.graphics.draw(self.bodyTexture, baseX, baseY, 0, scaleBodyX, scaleBodyY)

  love.graphics.draw(self.armTexture, baseX - Constants.SIZES.PLAYER.ARM_X_OFFSET + self.armTexture:getWidth() * scaleArmX - 5, baseY + Constants.SIZES.PLAYER.ARM_Y_OFFSET, self.armRotation, scaleArmX, scaleArmX, self.armTexture:getWidth(), self.armTexture:getHeight() / 2)
  love.graphics.draw(self.armTexture, baseX + Constants.SIZES.PLAYER.ARM_X_OFFSET + self.armTexture:getWidth() * scaleArmX - 5, baseY + Constants.SIZES.PLAYER.ARM_Y_OFFSET, self.armRotation, scaleArmX, scaleArmY, self.armTexture:getWidth(), self.armTexture:getHeight() / 2)
  
  love.graphics.draw(self.legTexture, baseX - Constants.SIZES.PLAYER.LEG_X_OFFSET + self.legTexture:getWidth() * scaleLegX + 12.5, baseY + Constants.SIZES.PLAYER.LEG_Y_OFFSET, self.legRotation, scaleLegX, scaleLegY, self.legTexture:getWidth() / 2, 2)
  love.graphics.draw(self.legTexture, baseX + Constants.SIZES.PLAYER.LEG_X_OFFSET + self.legTexture:getWidth() * scaleLegX + 12.5, baseY + Constants.SIZES.PLAYER.LEG_Y_OFFSET, self.legRotation, scaleLegX, scaleLegY, self.legTexture:getWidth() / 2, 2)
  -- love.graphics.draw(self.texture, self.body:getX() - Constants.SIZES.PLAYER.X/2, self.body:getY() -  Constants.SIZES.PLAYER.Y/2, 0, Constants.SIZES.PLAYER.X / self.texture:getWidth(), Constants.SIZES.PLAYER.Y / self.texture:getHeight())
end

return Player
