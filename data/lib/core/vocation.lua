-- Vocation Utility Functions for OpenTibia Server

-- Helper function to validate Vocation object
local function isValidVocation(vocation)
    return vocation and type(vocation) == "userdata" and vocation.getDemotion
end

-- Get the base vocation by traversing demotion hierarchy
-- @return: The base vocation object, or self if no base is found
function Vocation.getBase(self)
    if not isValidVocation(self) then
        print("[Warning] Vocation.getBase: Invalid vocation object")
        return self
    end

    local current = self
    local maxIterations = 100 -- Safeguard against infinite loops
    local iteration = 0

    while current:getDemotion() do
        local demotion = current:getDemotion()
        if not isValidVocation(demotion) then
            print("[Warning] Vocation.getBase: Invalid demotion for vocation")
            break
        end
        current = demotion
        iteration = iteration + 1
        if iteration >= maxIterations then
            print("[Error] Vocation.getBase: Possible circular demotion detected")
            break
        end
    end

    return current
end