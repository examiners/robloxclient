local REPO = 'examiners/robloxclient'
local BRANCH = 'main'

local function rawURL(path)
	return ('https://raw.githubusercontent.com/%s/%s/%s'):format(REPO, BRANCH, path)
end

local FILES = {
	LIBRARY = rawURL('library.lua'),
	MAIN = rawURL('main.lua'),
	UNIVERSAL = rawURL('client/universal.lua')
}

local INJECTED = {
	['newvape/libraries/hash.lua'] = rawURL('libraries/hash.lua'),
	['newvape/libraries/prediction.lua'] = rawURL('libraries/prediction.lua'),
	['newvape/libraries/entity.lua'] = rawURL('libraries/entity.lua')
}

local supported = {
	[77790193039862] = {
		Name = '1.8 client',
		URL = rawURL('client/1.8.lua')
	},
	[893973440] = {
		Name = 'Flee the Facility',
		URL = rawURL('client/ftf.lua')
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

local function injectLibraries(lib)
	if not lib.Libraries.files then
		lib.Libraries.files = {}
	end
	for path, url in pairs(INJECTED) do
		if not lib.Libraries.files[path] then
			lib.Libraries.files[path] = fetch(url)
		end
	end
end

local function loadUniversal(lib)
	if lib.UniversalLoaded then return end
	notify('robloxclient', 'Loading universal...')
	injectLibraries(lib)
	runSource(fetch(FILES.UNIVERSAL))
	lib.UniversalLoaded = true
end

local client = supported[game.PlaceId]
if not client then
	notify('robloxclient', 'Unsupported game (PlaceId ' .. tostring(game.PlaceId) .. ')')
	return
end

local ok, err = pcall(function()
	if shared.library and shared.library.Loaded then
		local lib = shared.library
		shared.vape = lib
		loadUniversal(lib)
	else
		notify('robloxclient', 'Fetching UI library...')

		local library = runSource(fetch(FILES.LIBRARY))
		local lib = runSource(fetch(FILES.MAIN), library)

		shared.library = lib
		shared.vape = lib

		loadUniversal(lib)
	end

	notify(client.Name, 'Fetching from GitHub...')

	local code = fetch(client.URL)
	runSource(code)
end)

if not ok then
	notify(client.Name, 'Failed to load: ' .. tostring(err))
	return
end

notify(client.Name, 'Loaded.')
