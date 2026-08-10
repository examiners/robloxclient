local REPO = 'examiners/robloxclient'
local BRANCH = 'main'

local FILES = {
	LIBRARY = ('https://raw.githubusercontent.com/%s/%s/library.lua'):format(REPO, BRANCH),
	MAIN = ('https://raw.githubusercontent.com/%s/%s/main.lua'):format(REPO, BRANCH)
}

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

local compile = loadstring or function(source)
	return load(source)
end

local function notify(title, text)
	local lib = shared.library
	if lib and lib.CreateNotification then
		pcall(function()
			lib:CreateNotification(title, text)
		end)
	else
		warn('[robloxclient] ' .. tostring(title) .. ' - ' .. tostring(text))
	end
end

local function fetch(url)
	local ok, result = pcall(function()
		return game:HttpGet(url, true)
	end)
	if not ok then
		error('Failed to fetch ' .. url .. ': ' .. tostring(result), 0)
	end
	return result
end

local function runSource(source, ...)
	local fn = compile(source)
	if not fn then
		error('Failed to parse script from GitHub.', 0)
	end
	return fn(...)
end

local client = supported[game.PlaceId]
if not client then
	notify('robloxclient', 'Unsupported game (PlaceId ' .. tostring(game.PlaceId) .. ')')
	return
end

if shared.library and shared.library.Loaded then
	notify(client.Name, 'Fetching from GitHub...')

	local ok, err = pcall(function()
		local code = fetch(client.URL)
		runSource(code)
	end)

	if not ok then
		notify(client.Name, 'Failed to load: ' .. tostring(err))
		return
	end

	notify(client.Name, 'Loaded.')
	return
end

notify('robloxclient', 'Fetching UI library...')

local ok, err = pcall(function()
	local library = runSource(fetch(FILES.LIBRARY))

	local lib = runSource(fetch(FILES.MAIN), library)

	shared.library = lib

	notify(client.Name, 'Fetching from GitHub...')

	local code = fetch(client.URL)
	runSource(code)
end)

if not ok then
	notify(client.Name, 'Failed to load: ' .. tostring(err))
	return
end

notify(client.Name, 'Loaded.')
