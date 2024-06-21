require "Light/PlayerPointLight_Network"
require "Light/PlayerPointLight_Manager"

PlayerPointLight = PlayerPointLight or {}



local function initLight(pointLight, isActive,addToCell)
    -- Get the player by their online ID
    local player = getPlayerByOnlineID(pointLight.playerID)
    if player == nil then
        return
    end

    -- Get the player's coordinates
    local x, y, z = player:getX(), player:getY(), player:getZ()

    -- Create a new light source and set it as active
    local lightSource = IsoLightSource.new(x, y, z, pointLight.r, pointLight.g, pointLight.b, pointLight.radius, -1)

    lightSource:setActive(isActive)

    if addToCell then
        local targetCell = getCell()
        targetCell:addLamppost(lightSource)
    end


    return lightSource
end

function PlayerPointLight:new(playerID,r,g,b,radius)

    local o = {}
    setmetatable(o, self)
    self.__index = self

    o.playerID = playerID
    o.r = r
    o.g = g
    o.b = b
    o.radius = radius
    o.lightSource = nil
    o.isActiveCallback = nil
    o.currentActive = false
    o.isRemoteActive = false
    o.index = PlayerPointLight.Manager.getLightCountFromPlayerID(playerID) + 1

    PlayerPointLight.Manager.addLight(playerID,o)

    return o

end

function PlayerPointLight:registerIsActiveCallback(isActive)
    self.isActiveCallback = isActive
end

---This function removes the point light from the game world and the local ModData.
-- DON'T CALL THIS FUNCTION DIRECTLY, USE PlayerPointLight.removePointLight(pointLight) INSTEAD
function PlayerPointLight:_remove()
    self:destroy()

    -- remove point light from local ModData
    PlayerPointLight.Manager.removeLight(self.playerID,self.index)
end

function PlayerPointLight:destroy()

    if self.lightSource ~= nil then
        local targetCell = getCell()
        targetCell:removeLamppost(self.lightSource)
        self.lightSource = nil
    end

end

function PlayerPointLight:update(isMoving)

    if isMoving then
        self:destroy()
        self.lightSource = initLight(self,true,true)
    else
        if self.lightSource == nil then
            self.lightSource = initLight(self,true,true)
        end
    end
end

---This function sets the active state of the point light.
-- and sends a command to the server to set the active state of the point light in the global ModData.
---@param value boolean
function PlayerPointLight:setActive(value)

    local player = getPlayer()
    local playerID = player:getOnlineID()

    if self.playerID ~= playerID then
        self.isRemoteActive = value
        return
    end

    self.currentActive = value

    sendClientCommand(player, PlayerPointLight_Network.Module, PlayerPointLight_Network.Commands.setRemoteActive,
    {
        playerID = self.playerID,
        index = self.index,
        value = value
    })

end

function PlayerPointLight:isActive()

    local player = getPlayer()

    if self.playerID ~= player:getOnlineID() then
        return self.isRemoteActive
    end

    -- if this is client player then we use the callback
    if self.isActiveCallback ~= nil then
        local currentActive = self.isActiveCallback(self)
        if currentActive ~= self.currentActive then
            self:setActive(currentActive)
        end
    end

    return self.currentActive
end

---This function tests whether the current point light is within the bounds of the client player.
-- It checks if the light source exists and if the player is within the light source's bounds.
-- Returns true if the point light is in bounds, false otherwise.
---@param pointLight table
---@return boolean
PlayerPointLight.isInBounds = function (pointLight)
    
    if PlayerPointLight.staticLight ~= nil then

        local light = PlayerPointLight.staticLight

        local parent = getPlayerByOnlineID(pointLight.playerID)

        if parent == nil then
            return false
        end

        local x = parent:getX()
        local y = parent:getY()
        local z = parent:getZ()

        light:setX(x)
        light:setY(y)
        light:setZ(z)

        return light:isInBounds()

    end

    return false

end

---This function creates a new point light with the specified color and radius.
---@param r number
---@param g number
---@param b number
---@param radius number
---@return table
PlayerPointLight.create = function (r,g,b,radius)

    -- Get the current player
    local player = getPlayer()
    local playerID = player:getOnlineID()

    local pointLight = PlayerPointLight:new(playerID,r,g,b,radius)

    -- Prepare the arguments for the client command
    local args = {}
    args.playerID = playerID
    args.r = r
    args.g = g
    args.b = b
    args.radius = radius
    args.index = pointLight.index

    sendClientCommand(player, PlayerPointLight_Network.Module, PlayerPointLight_Network.Commands.createRemote, args)

    return pointLight
end

---This function removes the specified point light from the game world and the local ModData.
-- and sends a command to the server to remove the point light from the global ModData.
---@param pointLight table
PlayerPointLight.remove = function (pointLight)

    local player = getPlayer()

    if pointLight == nil then
        return
    end

    pointLight:_remove()

    -- if the point light is not the client player's point light, send a command to the server to remove the point light
    if pointLight.playerID == player:getOnlineID() then
        sendClientCommand(player, PlayerPointLight_Network.Module, PlayerPointLight_Network.Commands.removeRemote,
        {
            playerID = pointLight.playerID,
            index = pointLight.index
        })
    end
end

return PlayerPointLight