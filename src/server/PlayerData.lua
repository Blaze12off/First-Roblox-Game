local C = require(game.ReplicatedStorage.SimulatorShared.Config)
local Schema = require(script.Parent.Schema)
local HttpService = game:GetService("HttpService")
local PlayerData = {}
PlayerData.__index = PlayerData

-- Injectable backend/clock are used by tests, never accessible through remotes.
function PlayerData.new(store, options)
    options = options or {}
    return setmetatable({store=store, profiles={}, loading={}, closing=false,
        now=options.now or os.time, wait=options.wait or task.wait,
        offline=options.offline == true, token=options.token or HttpService:GenerateGUID(false)}, PlayerData)
end
function PlayerData:_request(key, transform)
    for attempt = 1, C.Attempts do
        local ok, result = pcall(function() return self.store:UpdateAsync(key, transform) end)
        if ok then return true, result end
        if attempt < C.Attempts then self.wait(math.min(2 ^ (attempt-1), 4) + math.random()*0.2) end
    end
    return false, "unavailable"
end
local function validRecord(record)
    if type(record) ~= "table" or record.Schema ~= 1 or not Schema.Validate(record.Data) then return false end
    if type(record.Revision) ~= "number" or record.Revision % 1 ~= 0 or record.Revision < 0 then return false end
    local lock = record.Session
    return lock == nil or (type(lock)=="table" and type(lock.Token)=="string"
        and type(lock.Until)=="number" and lock.Until == lock.Until and lock.Until < math.huge)
end
function PlayerData:Load(userId)
    if self.closing or self.profiles[userId] or self.loading[userId] then return false, "busy" end
    self.loading[userId] = true
    if self.offline then
        self.profiles[userId] = {data=Schema.New(), lease=math.huge, status="ready", seq=0, savedSeq=0}
        self.loading[userId] = nil
        return true
    end
    local reason = "unavailable"
    local token = self.token .. ":" .. tostring(userId)
    local ok, record = self:_request("Player_"..userId, function(old)
        local now = self.now()
        if old ~= nil and not validRecord(old) then reason="corrupt"; return nil end
        if old and old.Session and old.Session.Token ~= token and old.Session.Until > now then
            reason="locked"; return nil
        end
        local data = old and Schema.Validate(old.Data) or Schema.New()
        return {Schema=1, Data=data, Revision=old and old.Revision or 0,
            Session={Token=token, Until=now+C.LeaseSeconds}}, {userId}
    end)
    self.loading[userId] = nil
    if not ok or not record or not validRecord(record) or not record.Session or record.Session.Token~=token then
        return false, reason
    end
    self.profiles[userId] = {data=Schema.Validate(record.Data), lease=record.Session.Until,
        status="ready", seq=0, savedSeq=0, token=token, revision=record.Revision}
    return true
end
function PlayerData:Get(userId)
    local p = self.profiles[userId]
    if not p or p.status ~= "ready" or self.closing then return nil end
    -- Stop granting progress before a stale server can overwrite a new session.
    if p.lease <= self.now()+10 then return nil end
    return p.data
end
function PlayerData:Changed(userId)
    local p = self.profiles[userId]
    if p then p.seq += 1 end
end
function PlayerData:Save(userId, release)
    local p = self.profiles[userId]
    if not p then return true end
    if release then p.status="closing" end
    -- One operation per key; exit waits for an autosave then writes the latest snapshot.
    while p.saving do self.wait(0.05) end
    if self.profiles[userId] ~= p then return true end
    p.saving = true
    local snapshot, seq = Schema.Copy(p.data), p.seq
    if not Schema.Validate(snapshot) then p.saving=false; return false, "corrupt" end
    if self.offline then
        p.savedSeq=seq; p.saving=false
        if release then self.profiles[userId]=nil end
        return true
    end
    local reason = "unavailable"
    local ok, result = self:_request("Player_"..userId, function(old)
        local now=self.now()
        if not validRecord(old) then reason="corrupt"; return nil end
        if not old.Session or old.Session.Token~=p.token or old.Session.Until <= now then
            reason="lost_lock"; return nil
        end
        return {Schema=1, Data=snapshot, Revision=old.Revision+1,
            Session=not release and {Token=p.token, Until=now+C.LeaseSeconds} or nil}, {userId}
    end)
    p.saving=false
    if ok and result and validRecord(result) then
        p.savedSeq=seq; p.revision=result.Revision
        if release then self.profiles[userId]=nil else p.lease=result.Session.Until end
        return true
    end
    if reason=="lost_lock" or reason=="corrupt" then p.status="failed" end
    return false, reason
end
return PlayerData
