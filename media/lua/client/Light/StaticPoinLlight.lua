
require "Light/StaticPointLight_Network"
require "Light/StaticPointLight_Manager"

StaticPointLight = StaticPointLight or {}

local function initLight(pointLight,isActive,addToCell)

    -- Get the light's coordinates
    local x, y, z = pointLight.x, pointLight.y, pointLight.z

    -- Create a new light source and set it as active
    local lightSource = IsoLightSource.new(x, y, z, pointLight.r, pointLight.g, pointLight.b, pointLight.radius, -1)

    lightSource:setActive(isActive)

    if addToCell then
        local targetCell = getCell()
        targetCell:addLamppost(lightSource)
    end


    return lightSource
end

function StaticPointLight:destroy()
    
    if self.lightSource ~= nil then
        local targetCell = getCell()
        targetCell:removeLamppost(self.lightSource)
        self.lightSource = nil
    end

end

function StaticPointLight:setActive(value)

    if value then
        if self.lightSource == nil then
            print("Recreating light source")
            self.lightSource = initLight(self, true, true)
        end
    else
        self:destroy()
    end

end

function StaticPointLight:_remove()
    self:destroy()

    StaticPointLight.Manager.removeLight(self.uniqueID)
end

function StaticPointLight:new(x, y, z, r, g, b , radius, uniqueID)

    local o = {}
    setmetatable(o,self)
    self.__index = self

    o.x = x
    o.y = y
    o.z = z
    o.r = r
    o.g = g
    o.b = b
    o.radius = radius
    o.uniqueID = uniqueID

    o.lightSource = initLight(o, true, true)

    StaticPointLight.Manager.addLight(uniqueID,o)

    -- initModData(getPlayer(), o, uniqueID)

    return o

end

--#endregion


--#region Client

---When using create, it doesn't really create the light but rather it sends command to the server to create
-- server-wide point light at that location
---@param x number
---@param y number
---@param z number
---@param r number
---@param g number
---@param b number
---@param radius number
StaticPointLight.create = function (x,y,z,r, g, b , radius)
    
    local args = {}
    args.x = x
    args.y = y
    args.z = z
    args.r = r
    args.g = g
    args.b = b
    args.radius = radius

    sendClientCommand(getPlayer(), StaticPointLight_Network.Module, StaticPointLight_Network.Commands.createGlobal, args)

end

StaticPointLight.remove = function (light)

    local args = {}
    args.uniqueID = light.uniqueID

    sendClientCommand(getPlayer(), StaticPointLight_Network.Module, StaticPointLight_Network.Commands.removeGlobal , args)
end

--#endregion

return StaticPointLight


