local REPO = 'examiners/robloxclient'
local BRANCH = 'main'

local supported = {
	[77790193039862] = {
		Name = '1.8 client',
		URL = ('https://raw.githubusercontent.com/%s/%s/client/1.8.lua'):format(REPO, BRANCH)
	},
	[893973440] = {
		Name = 'Flee the Facility',
		URL = ('https://raw.githubusercontent.com/%s/%s/client/ftf.lua'):format(REPO, BRANCH)
	}
}

local stockKey = "v" .. "ape"

local compile = loadstring or function(source)
	return load(source)
end

local function resolveLibrary()
	shared.library = shared.library or shared[stockKey]
	return shared.library
end

local function notify(title, text)
	local lib = resolveLibrary()
	if lib and lib.CreateNotification then
		pcall(function()
			lib:CreateNotification(title, text)
		end)
	else
		warn('[robloxclient] ' .. tostring(title) .. ' - ' .. tostring(text))
	end
end

local client = supported[game.PlaceId]
if not client then
	notify('robloxclient', 'Unsupported game (PlaceId ' .. tostring(game.PlaceId) .. ')')
	return
end

notify(client.Name, 'Fetching from GitHub...')

local ok, code = pcall(function()
	return game:HttpGet(client.URL, true)
end)

if not ok then
	notify(client.Name, 'Failed to fetch: ' .. tostring(code))
	return
end

local timeout = tick() + 20
repeat
	task.wait()
	resolveLibrary()
until (shared.library and shared.library.Loaded) or tick() > timeout

if not (shared.library and shared.library.Loaded) then
	notify(client.Name, 'Vape library (shared.vape) is not loaded. Run the Vape loader first, then run this.')
	return
end

local fn = compile(code)
if not fn then
	notify(client.Name, 'Failed to parse client script.')
	return
end

local ok, err = pcall(fn)
if not ok then
	notify(client.Name, 'Failed to load: ' .. tostring(err))
	return
end

notify(client.Name, 'Loaded.')
