local handler = PacketHandler(0xD4)

function handler.onReceive(self, msg)
    local mount = msg:getByte() ~= 0
    self:toggleMount(mount)
end

handler:register()