if _G.__AKSARA_LOADED then
	warn("[AS] Loader already executed. Skipping.")
	return
end
_G.__AKSARA_LOADED = true

local LOADER_VERSION = "0.0.0.1"
local MAX_RETRIES = 3
local RETRY_DELAY = 2

local Games = {
	[130342654546662] = {
		name    = "Sambung Kata",
		url     = "https://api.jnkie.com/api/v1/luascripts/public/8c83b82f794b3af8baefb73f2e3525ce9eaa864dce4cef4d4b05870444abc900/download",
		version = "0.0.0.1",
		author  = "Aksara Studios",
	},
}

local function log(msg)
	warn("[AS] " .. msg)
end

local function showNotification(title, text, duration)
	pcall(function()
		game:GetService("StarterGui"):SetCore("SendNotification", {
			Title = title,
			Text = text,
			Duration = duration or 5,
		})
	end)
end

local function validateEnvironment()
	if not loadstring then
		log("Environment error: loadstring is not available.")
		showNotification("Aksara Studios", "Executor not supported: missing loadstring", 8)
		return false
	end

	local httpOk = pcall(function()
		return game.HttpGetAsync
	end)

	if not httpOk then
		log("Environment error: HttpGetAsync is not available.")
		showNotification("Aksara Studios", "Executor not supported: missing HttpGetAsync", 8)
		return false
	end

	return true
end

local function fetchWithRetry(url)
	for attempt = 1, MAX_RETRIES do
		local ok, result = pcall(function()
			return game:HttpGetAsync(url)
		end)

		if ok and result and #result > 0 then
			return true, result
		end

		log("Fetch failed (attempt " .. attempt .. "/" .. MAX_RETRIES .. "): " .. tostring(result))

		if attempt < MAX_RETRIES then
			task.wait(RETRY_DELAY)
		end
	end

	return false, nil
end

if not validateEnvironment() then
	_G.__AKSARA_LOADED = nil
	return
end

local PlaceId = game.PlaceId
local entry = Games[PlaceId]

if not entry then
	log("Game not supported. PlaceId: " .. tostring(PlaceId))
	showNotification("Aksara Studios", "Game not supported.\nPlaceId: " .. tostring(PlaceId), 8)
	_G.__AKSARA_LOADED = nil
	return
end

log("Loader v" .. LOADER_VERSION)
log("Loading " .. entry.name .. " v" .. entry.version .. " by " .. entry.author)
showNotification("Aksara Studios", "Loading " .. entry.name .. "...", 3)

local startTime = tick()

local ok, source = fetchWithRetry(entry.url)

if not ok then
	log("Failed to fetch " .. entry.name .. " after " .. MAX_RETRIES .. " attempts.")
	showNotification("Aksara Studios", "Failed to load " .. entry.name .. ".\nCheck console (F9) for details.", 8)
	_G.__AKSARA_LOADED = nil
	return
end

local execOk, execErr = pcall(function()
	loadstring(source)()
end)

if not execOk then
	log("Runtime error in " .. entry.name .. ": " .. tostring(execErr))
	showNotification("Aksara Studios", "Error in " .. entry.name .. ".\nCheck console (F9).", 8)
	_G.__AKSARA_LOADED = nil
	return
end

local elapsed = string.format("%.2f", tick() - startTime)
log(entry.name .. " loaded successfully in " .. elapsed .. "s")
