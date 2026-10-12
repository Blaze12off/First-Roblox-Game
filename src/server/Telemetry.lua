local C=require(game.ReplicatedStorage.SimulatorShared.Config)
local RunService=game:GetService("RunService")
local Analytics=game:GetService("AnalyticsService")
local Telemetry={}
-- Supported API; opt-in only. Delivery is not claimed without Dashboard verification.
function Telemetry.Step(player,step,name)
    if not C.AnalyticsEnabled or RunService:IsStudio() then return end
    task.spawn(function()
        local ok=pcall(function() Analytics:LogOnboardingFunnelStepEvent(player,step,name) end)
        if not ok then warn("Simulator analytics event unavailable") end
    end)
end
return Telemetry
