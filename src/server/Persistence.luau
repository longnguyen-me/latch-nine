--!strict
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Persistence = {}
local memoryOnly = RunService:IsStudio() and not Config.PersistenceInStudio
local store: any = nil
local token = game.JobId .. ":" .. HttpService:GenerateGUID(false)
local held: {[number]: boolean} = {}
local busy: {[number]: boolean} = {}
local touched: {[number]: number} = {}
local acquiring: {[number]: boolean} = {}
local leases: {[number]: string} = {}
local owners: {[number]: any} = {}

local function retry(callback: () -> any): (boolean, any)
	local result: any
	for attempt = 1, 3 do
		local ok, value = pcall(callback)
		if ok then return true, value end
		result = value
		if attempt < 3 then task.wait(2 ^ (attempt - 1) + math.random() * 0.3) end
	end
	return false, result
end

function Persistence.load(userId: number, rules: any): (any, string)
	if held[userId] or busy[userId] or acquiring[userId] then
		return nil, "Your previous shop is still saving. Wait a moment and rejoin."
	end
	if memoryOnly then
		local profile = rules.newProfile()
		profile.cash = Config.StudioTestCash
		held[userId] = true; touched[userId] = os.time(); owners[userId] = profile
		leases[userId] = HttpService:GenerateGUID(false)
		return profile, "SESSION ONLY / Studio"
	end
	acquiring[userId] = true
	local lease = token .. ":" .. HttpService:GenerateGUID(false)
	local reason = "Data service unavailable. Please rejoin."
	local ok, record = retry(function()
		if not store then store = DataStoreService:GetDataStore(Config.DataStoreName) end
		return store:UpdateAsync("player_" .. userId, function(old: any)
			local data = if old == nil then rules.newProfile() else (if type(old) == "table" then rules.migrate(old.data) else nil)
			if not data then
				reason = "Save data needs a version migration. Existing data was preserved."; return nil
			end
			if old and old.lock and old.lock.id ~= lease and os.time() - old.lock.at < Config.LockSeconds then
				reason = "Your previous shop is still saving. Wait a moment and rejoin."; return nil
			end
			return {data = data, lock = {id = lease, at = os.time()}}
		end)
	end)
	acquiring[userId] = nil
	if not ok or not record then return nil, reason end
	held[userId] = true; touched[userId] = os.time(); leases[userId] = lease; owners[userId] = record.data
	return record.data, "CLOUD SAVE / active"
end

function Persistence.safe(userId: number): boolean
	return held[userId] == true and (memoryOnly or os.time() - (touched[userId] or 0) < Config.LockSeconds - 30)
end

local function copy(value: any): any
	if type(value) ~= "table" then return value end
	local result: any = {}
	for key, child in pairs(value) do result[key] = copy(child) end
	return result
end

function Persistence.save(userId: number, profile: any, release: boolean): (boolean, string)
	-- Serialize all writes per key; snapshot only after any preceding write finishes.
	local lease = leases[userId]
	while busy[userId] do task.wait(0.05) end
	if not held[userId] or leases[userId] ~= lease or owners[userId] ~= profile then return false, "Session ownership lost" end
	busy[userId] = true
	if memoryOnly then
		if release then held[userId] = nil; touched[userId] = nil; leases[userId] = nil; owners[userId] = nil end
		busy[userId] = nil; return true, "SESSION ONLY / Studio"
	end
	local snapshot = copy(profile)
	local now = os.time()
	local ok, result = retry(function()
		return store:UpdateAsync("player_" .. userId, function(old: any)
			if type(old) ~= "table" or not old.lock or old.lock.id ~= lease then return nil end
			return {data = snapshot, lock = if release then nil else {id = lease, at = now}}
		end)
	end)
	busy[userId] = nil
	if ok and result then
		touched[userId] = now
		if release then held[userId] = nil; touched[userId] = nil; leases[userId] = nil; owners[userId] = nil end
		return true, "CLOUD SAVE / saved"
	end
	if ok then held[userId] = nil; return false, "Session ownership lost" end
	return false, "CLOUD SAVE / retrying"
end

return Persistence
