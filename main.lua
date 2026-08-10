local library = ...

local cloneref = cloneref or function(obj)
	return obj
end

local CoreGui = cloneref(game:GetService('CoreGui'))
local Players = cloneref(game:GetService('Players'))
local Workspace = cloneref(game:GetService('Workspace'))
local RunService = cloneref(game:GetService('RunService'))
local UserInputService = cloneref(game:GetService('UserInputService'))

local lplr = Players.LocalPlayer

local ICON = 'rbxassetid://14736249347'

local lib = {
	Loaded = false,
	ThreadFix = setthreadidentity ~= nil,
	Cleanups = {},
	Modules = {},
	Categories = {},
	Libraries = {}
}

shared.library = lib

lib.gui = Workspace

local notifGui = Instance.new('ScreenGui')
notifGui.Name = 'RobloxClientNotifications'
notifGui.ResetOnSpawn = false
notifGui.IgnoreGuiInset = true
notifGui.DisplayOrder = 100
notifGui.Parent = CoreGui

local notifCount = 0

function lib:CreateNotification(title, text, duration)
	duration = duration or 5

	local holder = Instance.new('Frame')
	holder.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
	holder.BackgroundTransparency = 0.15
	holder.BorderSizePixel = 0
	holder.AnchorPoint = Vector2.new(1, 1)
	holder.Size = UDim2.new(0, 280, 0, 56)
	holder.Position = UDim2.new(1, -8, 1, -8 - (notifCount * 62))
	holder.ZIndex = 10
	holder.Parent = notifGui

	local bar = Instance.new('Frame')
	bar.BackgroundColor3 = Color3.fromRGB(255, 120, 30)
	bar.BorderSizePixel = 0
	bar.Size = UDim2.new(0, 3, 1, 0)
	bar.ZIndex = 11
	bar.Parent = holder

	local titleLabel = Instance.new('TextLabel')
	titleLabel.BackgroundTransparency = 1
	titleLabel.BorderSizePixel = 0
	titleLabel.Position = UDim2.new(0, 10, 0, 4)
	titleLabel.Size = UDim2.new(1, -16, 0, 16)
	titleLabel.Font = Enum.Font.GothamSemibold
	titleLabel.Text = tostring(title)
	titleLabel.TextColor3 = Color3.new(1, 1, 1)
	titleLabel.TextSize = 13
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
	titleLabel.ZIndex = 11
	titleLabel.Parent = holder

	local textLabel = Instance.new('TextLabel')
	textLabel.BackgroundTransparency = 1
	textLabel.BorderSizePixel = 0
	textLabel.Position = UDim2.new(0, 10, 0, 21)
	textLabel.Size = UDim2.new(1, -16, 0, 31)
	textLabel.Font = Enum.Font.Gotham
	textLabel.Text = tostring(text)
	textLabel.TextColor3 = Color3.fromRGB(205, 205, 205)
	textLabel.TextSize = 12
	textLabel.TextWrapped = true
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.TextYAlignment = Enum.TextYAlignment.Top
	textLabel.ZIndex = 11
	textLabel.Parent = holder

	notifCount = notifCount + 1

	task.delay(duration, function()
		holder:Destroy()
		notifCount = math.max(0, notifCount - 1)
	end)

	return holder
end

local function dispose(item)
	if typeof(item) == 'RBXScriptConnection' then
		pcall(function()
			item:Disconnect()
		end)
	elseif type(item) == 'function' then
		pcall(item)
	end
end

function lib:Clean(...)
	for i = 1, select('#', ...) do
		table.insert(self.Cleanups, select(i, ...))
	end
end

local window = library:CreateWindow({
	Accent = Color3.fromRGB(255, 120, 30),
	Key = Enum.KeyCode.RightControl
})

local flagCounter = 0
local function nextFlag()
	flagCounter = flagCounter + 1
	return 'robloxclient' .. flagCounter
end

local function wrap(content, holder, kind, props)
	props = props or {}
	local w = {
		_content = content,
		_holder = holder,
		_kind = kind,
		_hidden = props.Visible == false
	}
	if w._hidden then
		holder.Visible = false
	end
	return setmetatable(w, {
		__index = function(t, k)
			local c = t._content
			if t._kind == 'toggle' then
				if k == 'Enabled' then return c:Get() end
			elseif t._kind == 'slider' then
				if k == 'Value' then return c:Get() end
				if k == 'Min' then return c.Min end
				if k == 'Max' then return c.Max end
			elseif t._kind == 'dropdown' then
				if k == 'Value' then return c.Options[c:Get()] end
				if k == 'Index' then return c:Get() end
			elseif t._kind == 'textbox' then
				if k == 'Value' then return c.TextBox and c.TextBox.Text or '' end
			elseif t._kind == 'colorslider' then
				if k == 'Hue' then return c.Hue end
				if k == 'Sat' then return c.Sat end
				if k == 'Value' then return c.Val end
				if k == 'Opacity' then return 1 - (c.Transparency or 0) end
			end
			if k == 'Object' then return t._holder end
			return rawget(t, k)
		end,
		__newindex = function(t, k, v)
			local c = t._content
			if t._kind == 'toggle' and k == 'Enabled' then
				if c:Get() ~= v then
					c:Set(v)
				end
				return
			elseif t._kind == 'colorslider' and k == 'Opacity' then
				c:Set(c:Get(), 1 - v)
				return
			elseif t._kind == 'dropdown' and k == 'Value' then
				for i, opt in ipairs(c.Options) do
					if opt == v then
						c:Set(i)
						break
					end
				end
				return
			end
			rawset(t, k, v)
		end
	})
end

local function addElement(section, kind, props)
	props = props or {}
	local content

	if kind == 'toggle' then
		content = section:CreateToggle(nextFlag(), {
			name = props.Name,
			default = props.Default or false,
			callback = function() end
		})
		content.Callback = function(state)
			if props.Function then
				pcall(props.Function, state)
			end
		end
	elseif kind == 'slider' then
		content = section:CreateSlider(nextFlag(), {
			name = props.Name,
			min = props.Min or 0,
			max = props.Max or 100,
			suffix = props.Suffix or '',
			decimals = 1 / (props.Decimal or 1),
			default = props.Default or 0,
			callback = function() end
		})
		content.Callback = function(val)
			if props.Function then
				pcall(props.Function, val)
			end
		end
	elseif kind == 'dropdown' then
		content = section:CreateDropdown(nextFlag(), {
			name = props.Name,
			list = props.List or {},
			default = props.Default or 1,
			callback = function() end
		})
		content.Callback = function(selected)
			if props.Function then
				pcall(props.Function, selected)
			end
		end
	elseif kind == 'textbox' then
		content = section:CreateTextbox({
			name = props.Name,
			default = props.Default or '',
			callback = function(text)
				if props.Function then
					pcall(props.Function, text)
				end
			end
		})
	elseif kind == 'colorslider' then
		content = section:CreateColorpicker(nextFlag(), {
			name = props.Name,
			default = props.Default or Color3.new(1, 1, 1),
			transparency = props.DefaultOpacity and (1 - props.DefaultOpacity) or 0,
			callback = function() end
		})
		content.Callback = function(color)
			if props.Function then
				local h, s, v = Color3.toHSV(color)
				pcall(props.Function, h, s, v)
			end
		end
	end

	local children = section.Holder:GetChildren()
	local holder = children[#children]

	return wrap(content, holder, kind, props)
end

local function newCategory(name)
	local cat = {
		Name = name,
		Options = {},
		_leftH = 0,
		_rightH = 0,
		_page = window:CreatePage({
			image = ICON,
			size = UDim2.new(0, 48, 0, 48)
		})
	}

	function cat:CreateModule(props)
		props = props or {}
		local module = {
			Name = props.Name,
			Enabled = false,
			_clean = {},
			_elements = {},
			_h = 42,
			_category = self
		}

		local side = self._leftH <= self._rightH and 'Left' or 'Right'
		local section = self._page:CreateSection({name = props.Name, side = side, size = module._h})
		module._section = section
		if side == 'Left' then
			self._leftH = self._leftH + module._h
		else
			self._rightH = self._rightH + module._h
		end

		local toggleContent = section:CreateToggle(nextFlag(), {
			name = props.Name,
			default = false,
			callback = function() end
		})
		toggleContent.Callback = function(state)
			module:SetEnabled(state)
		end
		module._toggle = toggleContent

		local function resize()
			module._section.Holder.Parent.Parent.Size = UDim2.new(1, 0, 0, module._h)
		end

		function module:SetEnabled(state)
			state = state or false
			module.Enabled = state
			for _, e in ipairs(module._elements) do
				e.holder.Visible = state and not e.hidden
			end
			if not state then
				for _, item in ipairs(module._clean) do
					dispose(item)
				end
				table.clear(module._clean)
			end
			pcall(props.Function or function() end, state)
		end

		function module:Toggle()
			module._toggle:Set(not module.Enabled)
		end

		function module:Clean(...)
			for i = 1, select('#', ...) do
				table.insert(module._clean, select(i, ...))
			end
		end

		function module:_addElement(kind, props, height)
			local el = addElement(section, kind, props)
			table.insert(module._elements, {holder = el._holder, hidden = el._hidden})
			module._h = module._h + (height or 20)
			resize()
			return el
		end

		function module:CreateSlider(props)
			return module:_addElement('slider', props, 29)
		end

		function module:CreateToggle(props)
			return module:_addElement('toggle', props, 18)
		end

		function module:CreateDropdown(props)
			return module:_addElement('dropdown', props, 39)
		end

		function module:CreateTextBox(props)
			return module:_addElement('textbox', props, 30)
		end

		function module:CreateColorSlider(props)
			return module:_addElement('colorslider', props, 18)
		end

		function module:CreateTwoSlider(props)
			props = props or {}
			local minEl = module:_addElement('slider', {
				Name = (props.Name or '') .. ' (min)',
				Min = props.Min or 0,
				Max = props.Max or 100,
				Default = props.DefaultMin or 0,
				Decimal = props.Decimal
			}, 29)
			local maxEl = module:_addElement('slider', {
				Name = (props.Name or '') .. ' (max)',
				Min = props.Min or 0,
				Max = props.Max or 100,
				Default = props.DefaultMax or 0,
				Decimal = props.Decimal
			}, 29)
			return setmetatable({_min = minEl, _max = maxEl}, {
				__index = function(t, k)
					if k == 'GetRandomValue' then
						return function()
							local lo, hi = t._min.Value, t._max.Value
							if lo > hi then
								lo, hi = hi, lo
							end
							return Random.new():NextNumber(lo, hi)
						end
					end
					return rawget(t, k)
				end
			})
		end

		function module:CreateTargets(props)
			props = props or {}
			local function mk(name, def)
				return module:_addElement('toggle', {Name = name, Default = def}, 18)
			end
			return {
				Players = mk('Players', props.Players ~= false),
				NPCs = mk('NPCs', props.NPCs == true),
				Walls = mk('Walls', props.Walls == true)
			}
		end

		table.insert(lib.Modules, module)
		return module
	end

	lib.Categories[name] = cat
	return cat
end

local combat = newCategory('Combat')
local blatant = newCategory('Blatant')
local world = newCategory('World')
local render = newCategory('Render')
local utility = newCategory('Utility')

local friends = newCategory('Friends')
local fs = friends._page:CreateSection({name = 'Friends', side = 'Left', size = 80})
local fsH = 80
local function fadd(kind, props, height)
	local el = addElement(fs, kind, props)
	fsH = fsH + (height or 18)
	fs.Holder.Parent.Parent.Size = UDim2.new(1, 0, 0, fsH)
	return el
end
friends.Options['Use friends'] = fadd('toggle', {Name = 'Use friends', Default = false})
friends.Options['Recolor visuals'] = fadd('toggle', {Name = 'Recolor visuals', Default = true})
friends.Options['Friends color'] = fadd('colorslider', {Name = 'Friends color', Default = Color3.fromRGB(86, 236, 255)})
friends.ListEnabled = {}
fadd('textbox', {
	Name = 'Add friend',
	Function = function(text)
		if text and text ~= '' and not table.find(friends.ListEnabled, text) then
			table.insert(friends.ListEnabled, text)
		end
	end
}, 30)
fadd('textbox', {
	Name = 'Remove friend',
	Function = function(text)
		local i = text and table.find(friends.ListEnabled, text)
		if i then
			table.remove(friends.ListEnabled, i)
		end
	end
}, 30)

local main = newCategory('Main')
local ms = main._page:CreateSection({name = 'Main', side = 'Left', size = 40})
local msH = 40
local function madd(kind, props, height)
	local el = addElement(ms, kind, props)
	msH = msH + (height or 18)
	ms.Holder.Parent.Parent.Size = UDim2.new(1, 0, 0, msH)
	return el
end
main.Options['Use team color'] = madd('toggle', {Name = 'Use team color', Default = true})

local entitylib = {}

entitylib.List = {}
entitylib.character = nil
entitylib.isAlive = false
entitylib.EntityThreads = {}
entitylib.Connections = {}
entitylib.Running = false
entitylib.Events = {}
for _, eventName in {'LocalAdded', 'EntityAdded', 'EntityRemoved', 'EntityUpdated'} do
	local event = Instance.new('BindableEvent')
	event.Name = eventName
	entitylib.Events[eventName] = event
end

function entitylib.targetCheck(entity)
	if not entity or not entity.RootPart then return false end
	if entity.Health and entity.Health <= 0 then return false end
	return true
end

function entitylib.getUpdateConnections(entity)
	local signals = {}
	if entity.Humanoid then
		table.insert(signals, entity.Humanoid:GetPropertyChangedSignal('Health'))
	end
	return signals
end

function entitylib.getEntityColor(entity)
	if entity.Player and entity.Player.TeamColor then
		return entity.Player.TeamColor.Color
	end
	return nil
end

function entitylib.addEntity(char, plr)
	if not char or typeof(char) ~= 'Instance' then return end
	entitylib.EntityThreads[char] = task.spawn(function()
		local hum = char:WaitForChild('Humanoid', 10)
		local humrootpart = hum and char:WaitForChild('HumanoidRootPart', 10) or nil
		local head = char:WaitForChild('Head', 10) or humrootpart
		if hum and humrootpart then
			local entity = {
				Character = char,
				Head = head,
				Humanoid = hum,
				HumanoidRootPart = humrootpart,
				RootPart = humrootpart,
				HipHeight = hum.HipHeight + 2,
				Health = hum.Health,
				MaxHealth = hum.MaxHealth,
				NPC = plr == nil,
				Player = plr,
				Connections = {}
			}
			entity.Targetable = entitylib.targetCheck(entity)
			for _, signal in ipairs(entitylib.getUpdateConnections(entity)) do
				table.insert(entity.Connections, signal:Connect(function()
					entity.Health = hum.Health
					entity.MaxHealth = hum.MaxHealth
					entitylib.Events.EntityUpdated:Fire(entity)
				end))
			end
			if plr == lplr then
				entitylib.character = entity
				entitylib.isAlive = true
				entitylib.Events.LocalAdded:Fire(entity)
			else
				table.insert(entitylib.List, entity)
				entitylib.Events.EntityAdded:Fire(entity)
			end
		end
		entitylib.EntityThreads[char] = nil
	end)
end

function entitylib.addPlayer(plr)
	if not plr then return end
	table.insert(entitylib.Connections, plr.CharacterAdded:Connect(function(char)
		entitylib.addEntity(char, plr)
	end))
	if plr.Character then
		entitylib.addEntity(plr.Character, plr)
	end
end

function entitylib.removeEntity(entity)
	for i, v in ipairs(entitylib.List) do
		if v == entity then
			table.remove(entitylib.List, i)
			break
		end
	end
	entitylib.Events.EntityRemoved:Fire(entity)
end

function entitylib.removePlayer(plr)
	for i = #entitylib.List, 1, -1 do
		local entity = entitylib.List[i]
		if entity.Player == plr then
			table.remove(entitylib.List, i)
			entitylib.Events.EntityRemoved:Fire(entity)
		end
	end
end

function entitylib.refreshEntity(char, plr)
	for i, entity in ipairs(entitylib.List) do
		if entity.Character == char then
			table.remove(entitylib.List, i)
			entitylib.Events.EntityRemoved:Fire(entity)
			break
		end
	end
	entitylib.addEntity(char, plr)
end

function entitylib.start()
	if entitylib.Running then return end
	entitylib.Running = true
	local function track(plr)
		entitylib.addPlayer(plr)
	end
	for _, plr in ipairs(Players:GetPlayers()) do
		track(plr)
	end
	table.insert(entitylib.Connections, Players.PlayerAdded:Connect(track))
	table.insert(entitylib.Connections, Players.PlayerRemoving:Connect(entitylib.removePlayer))
end

function entitylib.AllPosition(props)
	props = props or {}
	local character = entitylib.character
	local origin = character and character.RootPart and character.RootPart.Position
	if not origin then return {} end

	local range = props.Range or 50
	local limit = props.Limit or 10
	local wantPlayers = props.Players ~= false
	local wantNPCs = props.NPCs ~= false
	local out = {}
	local rayParams

	if props.Wallcheck then
		rayParams = RaycastParams.new()
		rayParams.RespectCanCollide = true
	end

	for _, entity in ipairs(entitylib.List) do
		if #out >= limit then break end
		if not entity.RootPart then continue end
		if entity.Player ~= nil then
			if not wantPlayers then continue end
		elseif not wantNPCs then
			continue
		end
		if entity.Targetable == false then continue end
		if entity.Health and entity.Health <= 0 then continue end

		local position = entity.RootPart.Position
		local direction = position - origin
		if direction.Magnitude > range then continue end

		if rayParams then
			local filters = {}
			if character and character.Character and typeof(character.Character) == 'Instance' then
				table.insert(filters, character.Character)
			end
			if entity.Character and typeof(entity.Character) == 'Instance' then
				table.insert(filters, entity.Character)
			end
			rayParams.FilterDescendantsInstances = filters
			local hit = Workspace:Raycast(origin, direction, rayParams)
			if hit and not (entity.Character and typeof(entity.Character) == 'Instance' and hit.Instance:IsDescendantOf(entity.Character)) then
				continue
			end
		end

		table.insert(out, entity)
	end

	return out
end

function entitylib.EntityPosition(props)
	local list = entitylib.AllPosition(props)
	local entity = list[1]
	return entity and entity.RootPart.Position or nil
end

lib.Libraries.entity = entitylib
lib.Libraries.targetinfo = {Targets = {}}

function lib:Remove(name)
	for i, module in ipairs(self.Modules) do
		if module.Name == name then
			if module.Enabled then
				pcall(function()
					module:SetEnabled(false)
				end)
			end
			for _, item in ipairs(module._clean) do
				dispose(item)
			end
			table.clear(module._clean)
			pcall(function()
				module._section.Holder.Parent.Parent:Destroy()
			end)
			table.remove(self.Modules, i)
			break
		end
	end
end

function lib:Unload()
	for _, module in ipairs(self.Modules) do
		if module.Enabled then
			pcall(function()
				module:SetEnabled(false)
			end)
		end
		for _, item in ipairs(module._clean) do
			dispose(item)
		end
		table.clear(module._clean)
	end
	table.clear(self.Modules)

	for _, item in ipairs(self.Cleanups) do
		dispose(item)
	end
	table.clear(self.Cleanups)

	for _, connection in ipairs(entitylib.Connections) do
		pcall(function()
			connection:Disconnect()
		end)
	end
	table.clear(entitylib.Connections)

	for _, event in pairs(entitylib.Events) do
		pcall(function()
			event:Destroy()
		end)
	end

	pcall(function()
		window:Unload()
	end)
	pcall(function()
		notifGui:Destroy()
	end)

	self.Loaded = nil
end

lib.Loaded = true

return lib
