printc(100, 255, 100, 255, "Lmaobox's dash is disabled until you unload this script")
printc(100, 255, 100, 255, "Using the dash and recharge key from Lmaobox")
printc(100, 255, 100, 255, "If you want to change the keys, change them from Lmaobox's menu")
printc(100, 255, 100, 255, "They will be reverted when the script is unloaded")

client.ChatPrintf("Lmaobox's dash is disabled until you unload this script")
client.ChatPrintf("Using the dash and recharge key from Lmaobox")
client.ChatPrintf("If you want to change the keys, change them from Lmaobox's menu")
client.ChatPrintf("They will be reverted when the script is unloaded")

local warpKey = gui.GetValue("dash move key")
local rechargeKey = gui.GetValue("force recharge key")

local warp = false
local recharge = false
local charge = 0

local CLC_MOVE = 9

local function OnCreateMove(cmd)
    if gui.GetValue("dash move key") ~= 0 then
        warpKey = gui.GetValue("dash move key")
        gui.SetValue("dash move key", 0)
    end

    if gui.GetValue("force recharge key") ~= 0 then
        rechargeKey = gui.GetValue("force recharge key")
        gui.SetValue("force recharge key", 0)
    end

    warp = input.IsButtonDown(warpKey)
    recharge = input.IsButtonDown(rechargeKey)

    if recharge then
        cmd.buttons = 0
    end
end

---@param msg NetMessage
local function SendNetMsg(msg)
    if msg:GetType() ~= CLC_MOVE then
        return true
    end

    if warp and charge > 0 and clientstate.GetChokedCommands() == 0 then
        local bf = BitBuffer()
        msg:WriteToBitBuffer(bf)

        bf:SetCurBit(8)
        bf:WriteInt(2, 4)
        bf:WriteInt(1, 3)

        bf:SetCurBit(8)
        msg:ReadFromBitBuffer(bf)

        bf:Delete()

        charge = charge - 1
    elseif recharge and charge < client.GetConVar("sv_maxusrcmdprocessticks") then
        charge = charge + 1
        return false
    end

    return true
end

local width, height = 100, 20

local function OnDraw()
    if clientstate.GetClientSignonState() <= E_SignonState.SIGNONSTATE_SPAWN then
        charge = 0
        return
    end

    local sw, sh = draw.GetScreenSize()
    local x, y = (sw*0.5 - width*0.5)//1, (sh*0.5 + height*0.5)//1

    draw.Color(0, 255, 255, 200)
    draw.OutlinedRect(x, y, x + width, y + height)

    local percent = charge/client.GetConVar("sv_maxusrcmdprocessticks")

    draw.Color(0, 255, 255, 200)
    draw.FilledRect(x + 2, y + 2, (x + (width*percent)//1) - 2, y + height - 2)
end

local function Unload()
    callbacks.Unregister("CreateMove", "smooth-dash-createmove")
    callbacks.Unregister("SendNetMsg", "smooth-dash-sendnetmsg")
    callbacks.Unregister("SendNetMsg", "smooth-dash-draw")

    gui.SetValue("dash move key", warpKey)
    gui.SetValue("force recharge key", rechargeKey)
end

callbacks.Register("CreateMove", "smooth-dash-createmove", OnCreateMove)
callbacks.Register("SendNetMsg", "smooth-dash-sendnetmsg", SendNetMsg)
callbacks.Register("Draw", "smooth-dash-draw", OnDraw)
callbacks.Register("Unload", Unload)