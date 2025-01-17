
local animationTime = 2

local PLUGIN = PLUGIN
PLUGIN.cameraFraction = 0

local function GetHeadBone(client)
    local head

    for i = 1, client:GetBoneCount() do
        local name = client:GetBoneName(i)

        if (string.find(name:lower(), "head")) then
            head = i
            break
        end
    end

    return head
end

function PLUGIN:PlayerBindPress(client, bind, bPressed)
    if (!client:GetNetVar("actEnterAngle")) then return end

    if (bind:find("+jump") and bPressed) then
        ix.command.Send("ExitAct")
        return true
    end
end

function PLUGIN:ShouldDrawLocalPlayer(client)
    if (client:GetNetVar("actEnterAngle") and self.cameraFraction > 0.25) then
        return true
    elseif (self.cameraFraction > 0.25) then
        return true
    end
end

local forwardOffset = 16
local backwardOffset = -32
local heightOffset = Vector(0, 0, 20)
local idleHeightOffset = Vector(0, 0, 6)
local traceMin = Vector(-4, -4, -4)
local traceMax = Vector(4, 4, 4)

function PLUGIN:CalcView(client, origin)
    if (client:CanOverrideView() and LocalPlayer():GetViewEntity() == LocalPlayer()) then
        return
    end

    local enterAngle = client:GetNetVar("actEnterAngle")
    local fraction = self.cameraFraction
    local offset = self.bIdle and forwardOffset or backwardOffset
    local height = self.bIdle and idleHeightOffset or heightOffset

    if (!enterAngle) then
        if (fraction > 0) then
            local view = {
                origin = LerpVector(fraction, origin, origin + self.forward * offset + height)
            }

            if (self.cameraTween) then
                self.cameraTween:update(FrameTime())
            end

            return view
        end

        return
    end

    local view = {}
    local forward = enterAngle:Forward()
    local head = GetHeadBone(client)

    if (head) then
        client:ManipulateBoneScale(head, Vector(0.01, 0.01, 0.01))

        local pos, ang = client:GetBonePosition(head)
        ang:RotateAroundAxis(ang:Right(), 270)
        ang:RotateAroundAxis(ang:Up(), 270)

        view.origin = pos + ang:Up() * 4
        view.angles = ang
    else
        view.origin = origin + forward * forwardOffset + height
    end

    view.origin = LerpVector(fraction, origin, view.origin)

    if (self.cameraTween) then
        self.cameraTween:update(FrameTime())
    end

    return view
end

net.Receive("ixActEnter", function()
    PLUGIN.bIdle = net.ReadBool()
    PLUGIN.forward = LocalPlayer():GetNetVar("actEnterAngle"):Forward()
    PLUGIN.cameraTween = ix.tween.new(animationTime, PLUGIN, {
        cameraFraction = 1
    }, "outQuint")

    LocalPlayer():ResetBoneMatrix()
end)

net.Receive("ixActLeave", function()
    PLUGIN.cameraTween = ix.tween.new(animationTime * 0.5, PLUGIN, {
        cameraFraction = 0
    }, "outQuint")

    LocalPlayer():ResetBoneMatrix()
end)
