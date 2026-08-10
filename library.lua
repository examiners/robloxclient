--[[
creds to original: https://github.com/Iucious/gamesense-ui/blob/main/main.lua

finished and completed ui lib by fade @ https://crankcheat.cc
]]

local library = {
	OnColorPicker = false,
	Renders = {},
	Connections = {},
}
local pages = {}
local sections = {}
local utility = {}
local createdObjects = {
	toggles = {},
	sliders = {},
	dropdowns = {},
	keybinds = {},
	colorpickers = {}
}
local rootFolderName = "skeet"
local configFolderName = "testgame"
local assetFiles = {
	["https://i.postimg.cc/TY6SmGj9/Gradient-Bar2.png"] = "GradientBar.png",
	["https://i.postimg.cc/Y91cKSfG/Inner-Border-Inner-Frame-Pattern.png"] = "InnerBFPattern.png",
	["https://i.postimg.cc/Y9xXzLz5/Inner-Inner-Pattern.png"] = "InnerInnerPattern.png",
	["https://i.postimg.cc/vmF3RtPL/Holder-Extra-Gradient1.png"] = "HolderExtraGradient.png",
	["https://i.postimg.cc/0ym0CJ8w/Extra-Arrow-Up-Image.png"] = "ExtraArrowUp.png",
	["https://i.postimg.cc/tJwF39wD/Extra-Arrow-Down-Image.png"] = "ExtraArrowDown.png",
	["https://i.postimg.cc/vmh9PrCt/scrollbarimage.png"] = "ScrollBar.png",
	["https://i.postimg.cc/zfz07S0k/Imagesarrow-shaded-Outline-Frame-Arrow.png"] = "OutlineFrameArrow.png",
	["https://i.postimg.cc/0jDYPbVX/Val-Sat-Picker-Dark.png"] = "SatPicker.png",
	["https://i.postimg.cc/90598ccC/Alpha-Picker-BG.png"] = "AlphaPicker.png",

	["https://i.postimg.cc/YCCwGgQ2/rage-icon.png"] = "RageIcon.png",
	["https://i.postimg.cc/KYdXHHwz/aimbot-icon.png"] = "AimbotIcon.png",
	["https://i.postimg.cc/G3P0XzQd/visuals-icon.png"] = "VisualsIcon.png",
	["https://i.postimg.cc/ZqcMnMN1/icons8-settings-100.png"] = "MiscIcon.png",
	["https://i.postimg.cc/jS5GdTrw/skins-icon.png"] = "SkinsIcon.png",
	["https://i.postimg.cc/prRSNbZ2/icons8-save-100.png"] = "ConfigIcon.png"
}
local cachedAssets = {}
do
	library.__index = library
	pages.__index = pages
	sections.__index = sections
end
--// Variables
local CoreGui = cloneref(game:GetService("CoreGui"))
local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local TweenService = cloneref(game:GetService("TweenService"))
local HttpService = cloneref(game:GetService("HttpService"))
local Workspace = cloneref(game:GetService("Workspace"))
local GuiService = cloneref(game:GetService("GuiService"))

local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

--// Utility functions
function utility:RenderObject(RenderType, RenderProperties, RenderHidden)
	local Render = Instance.new(RenderType)

	if RenderProperties and typeof(RenderProperties) == "table" then
		for Property, Value in pairs(RenderProperties) do
			if Property ~= "RenderTime" then
				Render[Property] = Value
			end
		end
	end
	
	library.Renders[#library.Renders + 1] = {Render, RenderProperties, RenderHidden, RenderProperties["RenderTime"] or nil}
	
	return Render
end

function utility:DestroyObject(Instance)
	if not Instance then return end
	for i = #library.Renders, 1, -1 do
		if library.Renders[i][1] == Instance then
			table.remove(library.Renders, i)
			break
		end
	end
	Instance:Destroy()
end

function utility:CreateConnection(ConnectionType, ConnectionCallback)
	local Connection = ConnectionType:Connect(ConnectionCallback)

	library.Connections[#library.Connections + 1] = Connection

	return Connection
end

function utility:MouseLocation()
	return UserInputService:GetMouseLocation()
end

function utility:MakeDraggable(UiObject)
	local Dragging = false
	local DragInput = nil
	local DragStart = nil
	local StartPos = nil
	
	local function Update(Input)
		if library.OnColorPicker then return end
		
		local Delta = Input.Position - DragStart
		local Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + Delta.X, StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y)
		TweenService:Create(UiObject, TweenInfo.new(0.1), {Position = Position}):Play()
	end
	
	utility:CreateConnection(UiObject.InputBegan, function(Input)
		local c
		if Input.UserInputType == Enum.UserInputType.MouseButton1 and UserInputService:GetFocusedTextBox() == nil then
			Dragging = true
			DragStart = Input.Position
			StartPos = UiObject.Position
			
			c = Input.Changed:Connect(function()
				if Input.UserInputState == Enum.UserInputState.End then
					Dragging = false
					c:Disconnect()
				end
			end)
		end
	end)
	
	utility:CreateConnection(UiObject.InputChanged, function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseMovement then
			DragInput = Input
		end
	end)

	
	utility:CreateConnection(UserInputService.InputChanged, function(Input)
		if Input == DragInput and Dragging then
			Update(Input)
		end
	end)
end

--// Cfg handling / assets

function utility:GetAsset(Asset)
	if cachedAssets[Asset] then
		return cachedAssets[Asset]
	end

	local Url = nil
	local Path = nil

	for a,b in pairs(assetFiles) do
		if b == Asset then
			Url = a
		end
	end

	if not Url then return "rbxassetid://" end

	Path = rootFolderName.."/assets/"..Asset

	if isfile(Path) then
		local rbxasset = getcustomasset(Path)
		cachedAssets[Asset] = rbxasset

		return rbxasset
	end	

	local sc, resp = pcall(function()
        return game:HttpGet(Url)
    end)

	if sc then
		writefile(Path, resp)

		local rbxasset = getcustomasset(Path)
		cachedAssets[Asset] = rbxasset

		return rbxasset
	else
		return ""
	end
end
--
function library:GetAsset(Asset)
	return utility:GetAsset(Asset)
end
--

function utility:MakeFolders()
	if not isfolder(rootFolderName) then
		makefolder(rootFolderName)
	end

	if not isfolder(rootFolderName.."/assets") then
		makefolder(rootFolderName.."/assets")
	end

	if not isfolder(rootFolderName.."/configs") then
		makefolder(rootFolderName.."/configs")
	end

	if not isfolder(rootFolderName.."/configs/"..configFolderName) then
		makefolder(rootFolderName.."/configs/"..configFolderName)
	end
end
do
	utility:MakeFolders()
end

function utility:SaveConfig(Name)
	if not Name then
		return false, "No config name provided"
	end

	local Path = rootFolderName.."/configs/"..configFolderName.."/"..Name..".json"

	local data = {
		toggles = {},
		sliders = {},
		dropdowns = {},
		keybinds = {},
		colorpickers = {}
	}

	for cat, obj in pairs(createdObjects) do
		if data[cat] then
			for i, v in pairs(obj) do
				local val = v:Get()
				if val ~= nil then
					if cat == "colorpickers" then
						local H,S,V = Color3.toHSV(val)
						val = string.format("%f,%f,%f", H, S, V)
					end
					data[cat][i] = val
				end
			end
		end
	end

	local Success, Encoded = pcall(HttpService.JSONEncode, HttpService, data)
	if not Success then
		return false, "File encode error"
	end

	writefile(Path,Encoded)

	return true, "Saved config "..Name
end
function library:SaveConfig(Name)
	return utility:SaveConfig(Name)
end

function utility:LoadConfig(Name)
	if not Name then
		return false, "No config name provided"
	end

	local Path = rootFolderName.."/configs/"..configFolderName.."/"..Name..".json"
	if not isfile(Path) then
		return false, "Invalid file"
	end

	local success, decoded = pcall(HttpService.JSONDecode, HttpService, readfile(Path))
	if not success then
		return false, "File decode error"
	end

	for cat, vals in pairs(decoded) do
		if createdObjects[cat] then
			for i, v in pairs(vals) do
				local obj = createdObjects[cat][i]
				if obj then
					if cat == "colorpickers" then
						local Split = string.split(v,",")
						v = Color3.fromHSV(tonumber(Split[1]),tonumber(Split[2]),tonumber(Split[3]))
					end
					obj:Set(v) 
				end
			end
		end
	end
	return true, "Loaded config "..Name
end
function library:LoadConfig(Name)
	return utility:LoadConfig(Name)
end


-- all credits to linoria lib
function utility:GetConfigList()
	local list = listfiles(rootFolderName.."/configs/"..configFolderName)

	local out = {}
	for i = 1, #list do
		local file = list[i]
		if file:sub(-5) == '.json' then
			local pos = file:find('.json', 1, true)
			local start = pos

			local char = file:sub(pos, pos)
			while char ~= '/' and char ~= '\\' and char ~= '' do
				pos = pos - 1
				char = file:sub(pos, pos)
			end

			if char == '/' or char == '\\' then
				table.insert(out, file:sub(pos + 1, start - 1))
			end
		end
	end

	return out
end
function library:GetConfigList()
	return utility:GetConfigList()
end

--// main
--//Window
function library:CreateWindow(Properties)
	Properties = Properties or {}
	--
	local Window = {
		Pages = {},
		Accent = (Properties.Accent or Color3.fromRGB(255, 120, 30)),
		Enabled = true,
		Key = (Properties.Key or Enum.KeyCode.RightControl)
	}
	--
	do
		local ScreenGui = utility:RenderObject("ScreenGui", {
			DisplayOrder = 9999,
			Enabled = true,
			IgnoreGuiInset = true,
			Parent = CoreGui,
			ResetOnSpawn = false,
			ZIndexBehavior = "Global"
		})
		-- //
		local ScreenGui_MainFrame = utility:RenderObject("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(25, 25, 25),
			BackgroundTransparency = 0,
			BorderColor3 = Color3.fromRGB(12, 12, 12),
			BorderMode = "Inset",
			BorderSizePixel = 1,
			Parent = ScreenGui,
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0, 660, 0, 560)
		})
		utility:MakeDraggable(ScreenGui_MainFrame)
		-- //
		local ScreenGui_MainFrame_InnerBorder = utility:RenderObject("Frame", {
			BackgroundColor3 = Color3.fromRGB(40, 40, 40),
			BackgroundTransparency = 0,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Parent = ScreenGui_MainFrame,
			Position = UDim2.new(0, 1, 0, 1),
			Size = UDim2.new(1, -2, 1, -2)
		})
		-- //
		local MainFrame_InnerBorder_InnerFrame = utility:RenderObject("Frame", {
			BackgroundColor3 = Color3.fromRGB(12, 12, 12),
			BackgroundTransparency = 0,
			BorderColor3 = Color3.fromRGB(60, 60, 60),
			BorderMode = "Inset",
			BorderSizePixel = 1,
			Parent = ScreenGui_MainFrame,
			Position = UDim2.new(0, 3, 0, 3),
			Size = UDim2.new(1, -6, 1, -6)
		})
		-- //
		local InnerBorder_InnerFrame_Tabs = utility:RenderObject("Frame", {
			BackgroundColor3 = Color3.fromRGB(12, 12, 12),
			BackgroundTransparency = 0,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Parent = MainFrame_InnerBorder_InnerFrame,
			Position = UDim2.new(0, 0, 0, 4),
			Size = UDim2.new(0, 74, 1, -4)
		})
		--
		local InnerBorder_InnerFrame_Pages = utility:RenderObject("Frame", {
			AnchorPoint = Vector2.new(1, 0),
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 0,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Parent = MainFrame_InnerBorder_InnerFrame,
			Position = UDim2.new(1, 0, 0, 4),
			Size = UDim2.new(1, -73, 1, -4)
		})
		--
		local InnerBorder_InnerFrame_TopGradient = utility:RenderObject("Frame", {
			BackgroundColor3 = Color3.fromRGB(12, 12, 12),
			BackgroundTransparency = 0,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Parent = MainFrame_InnerBorder_InnerFrame,
			Position = UDim2.new(0, 0, 0, 0),
			Size = UDim2.new(1, 0, 0, 4)
		})
		-- //
		local InnerFrame_Tabs_List = utility:RenderObject("UIListLayout", {
			Padding = UDim.new(0, 4),
			Parent = InnerBorder_InnerFrame_Tabs,
			FillDirection = "Vertical",
			HorizontalAlignment = "Left",
			VerticalAlignment = "Top"
		})
		--
		local InnerFrame_Tabs_Padding = utility:RenderObject("UIPadding", {
			Parent = InnerBorder_InnerFrame_Tabs,
			PaddingTop = UDim.new(0, 9)
		})
		--
		local InnerFrame_Pages_InnerBorder = utility:RenderObject("Frame", {
			BackgroundColor3 = Color3.fromRGB(45, 45, 45),
			BackgroundTransparency = 0,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Parent = InnerBorder_InnerFrame_Pages,
			Position = UDim2.new(0, 1, 0, 0),
			Size = UDim2.new(1, -1, 1, 0)
		})
		--
		local InnerFrame_TopGradient_Gradient = utility:RenderObject("ImageLabel", {
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Parent = InnerBorder_InnerFrame_TopGradient,
			Position = UDim2.new(0, 1, 0, 1),
			Size = UDim2.new(1, -2, 1, -2),
			Image = utility:GetAsset("GradientBar.png"),
			ImageColor3 = Color3.fromRGB(255, 255, 255)
		})
		-- //
		local Pages_InnerBorder_InnerFrame = utility:RenderObject("Frame", {
			BackgroundColor3 = Color3.fromRGB(20, 20, 20),
			BackgroundTransparency = 0,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Parent = InnerFrame_Pages_InnerBorder,
			Position = UDim2.new(0, 1, 0, 0),
			Size = UDim2.new(1, -1, 1, 0)
		})
		-- //
		local InnerBorder_InnerFrame_Folder = utility:RenderObject("Folder", {
			Parent = Pages_InnerBorder_InnerFrame
		})
		--
		local InnerBorder_InnerFrame_Pattern = utility:RenderObject("ImageLabel", {
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Parent = Pages_InnerBorder_InnerFrame,
			Position = UDim2.new(0, 0, 0, 0),
			Size = UDim2.new(1, 0, 1, 0),
			Image = utility:GetAsset("InnerBFPattern.png"),
			ImageColor3 = Color3.fromRGB(12, 12, 12),
			ScaleType = "Tile",
			TileSize = UDim2.new(0, 8, 0, 8)
		})
		
		--//kb list
		do
			library.KeybindList = {
				Visible = false,
				Entries = {}
			}

			local KeybindList_MainFrame = utility:RenderObject("Frame", {
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundColor3 = Color3.fromRGB(25, 25, 25),
				BackgroundTransparency = 0,
				BorderColor3 = Color3.fromRGB(12, 12, 12),
				BorderMode = "Inset",
				BorderSizePixel = 1,
				Parent = ScreenGui,
				Position = UDim2.new(0, 15, 0.5, 0),
				Size = UDim2.new(0, 225, 0, 0),
				Visible = false
			},true)

			local KeybindList_MainFrame_InnerBorder = utility:RenderObject("Frame", {
				BackgroundColor3 = Color3.fromRGB(40, 40, 40),
				BackgroundTransparency = 0,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Parent = KeybindList_MainFrame,
				Position = UDim2.new(0, 1, 0, 1),
				Size = UDim2.new(1, -2, 1, -2)
			},true)

			local kbMainFrame_InnerBorder_InnerFrame = utility:RenderObject("Frame", {
				BackgroundColor3 = Color3.fromRGB(12, 12, 12),
				BackgroundTransparency = 0,
				BorderColor3 = Color3.fromRGB(60, 60, 60),
				BorderMode = "Inset",
				BorderSizePixel = 1,
				Parent = KeybindList_MainFrame,
				Position = UDim2.new(0, 3, 0, 3),
				Size = UDim2.new(1, -6, 1, -6)
			},true)

			local kbInnerBorder_InnerFrame_TopGradient = utility:RenderObject("Frame", {
				BackgroundColor3 = Color3.fromRGB(12, 12, 12),
				BackgroundTransparency = 0,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Parent = kbMainFrame_InnerBorder_InnerFrame,
				Position = UDim2.new(0, 0, 0, 0),
				Size = UDim2.new(1, 0, 0, 4)
			},true)

			local kbInnerFrame_TopGradient_Gradient = utility:RenderObject("ImageLabel", {
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Parent = kbInnerBorder_InnerFrame_TopGradient,
				Position = UDim2.new(0, 1, 0, 1),
				Size = UDim2.new(1, -2, 1, -2),
				Image = utility:GetAsset("GradientBar.png"),
				ImageColor3 = Color3.fromRGB(255, 255, 255)
			},true)

			local listframe = utility:RenderObject("Frame", {
				Name = "listframe",
				BackgroundTransparency = 1,
				Parent = KeybindList_MainFrame,
				Position = UDim2.new(0, 3, 0, 6),
				Size = UDim2.new(1, -6, 0, 0), 
				AutomaticSize = Enum.AutomaticSize.Y
			},true)

			local uilistlayout = utility:RenderObject("UIListLayout", {
				Padding = UDim.new(0, 0),
				Parent = listframe,
				FillDirection = "Vertical",
				HorizontalAlignment = "Center",
				VerticalAlignment = "Top",
				SortOrder = Enum.SortOrder.LayoutOrder
			},true)

			utility:RenderObject("UIPadding", {
				Parent = listframe,
				PaddingBottom = UDim.new(0, 6) 
			},true)

			local kblisttext = utility:RenderObject("TextLabel", {
				AnchorPoint = Vector2.new(0, 0),
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				LayoutOrder = -1,
				Parent = listframe,
				Position = UDim2.new(0, 12, 0, 0),
				Size = UDim2.new(1, -26, 0, 20),
				ZIndex = 5,
				Font = "Code",
				RichText = true,
				Text = "<b>Keybinds</b>",
				TextColor3 = Color3.fromRGB(205, 205, 205),
				TextSize = 11,
				TextStrokeTransparency = 1,
				TextXAlignment = "Center"
			},true)
			
			utility:CreateConnection(uilistlayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
				local ContentHeight = uilistlayout.AbsoluteContentSize.Y
				KeybindList_MainFrame.Size = UDim2.new(0, 225, 0, ContentHeight + 20)
			end)

			function library.KeybindList:SetVisible(state)
				library.KeybindList.Visible = state
				KeybindList_MainFrame.Visible = state
			end

			function library.KeybindList:Update(Flag, Name, Key, IsActive)
				if not Key or Key == "None" or Key == "-" then
					if library.KeybindList.Entries[Flag] then
						library.KeybindList.Entries[Flag]:Destroy()
						library.KeybindList.Entries[Flag] = nil
					end
					return
				end

				local Entry = library.KeybindList.Entries[Flag]

				if not Entry then
					Entry = utility:RenderObject("Frame", {
						Parent = listframe,
						BackgroundTransparency = 1,
						Size = UDim2.new(1, -10, 0, 14),
						LayoutOrder = 1
					},true)

					local NameLbl = utility:RenderObject("TextLabel", {
						Parent = Entry,
						BackgroundTransparency = 1,
						Position = UDim2.new(0.05, 0, 0, 0),
						Size = UDim2.new(0.65, 0, 1, 0),
						Font = "Code",
						Name = "NameLabel",
						Text = Name,
						TextColor3 = Color3.fromRGB(150, 150, 150),
						TextSize = 10,
						TextXAlignment = "Left",
					},true)

					local KeyLbl = utility:RenderObject("TextLabel", {
						Parent = Entry,
						Name = "KeyLabel",
						BackgroundTransparency = 1,
						Position = UDim2.new(0.6, 0, 0, 0),
						Size = UDim2.new(0.35, 0, 1, 0),
						Font = "Code",
						Text = "["..tostring(Key).."]",
						TextColor3 = Color3.fromRGB(150, 150, 150),
						TextSize = 10,
						TextXAlignment = "Right"
					},true)

					library.KeybindList.Entries[Flag] = Entry
				end

				local Accent = Window.Accent or Color3.fromRGB(255, 120, 30)
				local TextCol = IsActive and Accent or Color3.fromRGB(150, 150, 150)
				local KeyCol = IsActive and Accent or Color3.fromRGB(150, 150, 150)

				if Entry and Entry:FindFirstChild("NameLabel") then
					Entry.NameLabel.TextColor3 = TextCol
					Entry.KeyLabel.Text = "["..tostring(Key).."]"
					Entry.KeyLabel.TextColor3 = KeyCol
				end
			end
		end

		--
		do -- // Functions
			function Window:SetPage(Page)
				for index, page in pairs(Window.Pages) do
					if page.Open and page ~= Page then
						page:Set(false)
					end
				end
			end
			--
			function Window:Fade(state)
				for index, render in pairs(library.Renders) do
					if not render[3] then
						if render[1].ClassName == "Frame" and (render[2]["BackgroundTransparency"] or 0) ~= 1 then
							TweenService:Create(render[1], TweenInfo.new(render[4] or 0.25, Enum.EasingStyle["Linear"], state and Enum.EasingDirection["Out"] or Enum.EasingDirection["In"]), {BackgroundTransparency = state and (render[2]["BackgroundTransparency"] or 0) or 1}):Play()
						elseif render[1].ClassName == "ImageLabel" then
							if (render[2]["BackgroundTransparency"] or 0) ~= 1 then
								TweenService:Create(render[1], TweenInfo.new(render[4] or 0.25, Enum.EasingStyle["Linear"], state and Enum.EasingDirection["Out"] or Enum.EasingDirection["In"]), {BackgroundTransparency = state and (render[2]["BackgroundTransparency"] or 0) or 1}):Play()
							end
							--
							if (render[2]["ImageTransparency"] or 0) ~= 1 then
								TweenService:Create(render[1], TweenInfo.new(render[4] or 0.25, Enum.EasingStyle["Linear"], state and Enum.EasingDirection["Out"] or Enum.EasingDirection["In"]), {ImageTransparency = state and (render[2]["ImageTransparency"] or 0) or 1}):Play()
							end
						elseif render[1].ClassName == "TextLabel" then
							if (render[2]["BackgroundTransparency"] or 0) ~= 1 then
								TweenService:Create(render[1], TweenInfo.new(render[4] or 0.25, Enum.EasingStyle["Linear"], state and Enum.EasingDirection["Out"] or Enum.EasingDirection["In"]), {BackgroundTransparency = state and (render[2]["BackgroundTransparency"] or 0) or 1}):Play()
							end
							--
							if (render[2]["TextTransparency"] or 0) ~= 1 then
								TweenService:Create(render[1], TweenInfo.new(render[4] or 0.25, Enum.EasingStyle["Linear"], state and Enum.EasingDirection["Out"] or Enum.EasingDirection["In"]), {TextTransparency = state and (render[2]["TextTransparency"] or 0) or 1}):Play()
							end
						elseif render[1].ClassName == "ScrollingFrame" then
							if (render[2]["BackgroundTransparency"] or 0) ~= 1 then
								TweenService:Create(render[1], TweenInfo.new(render[4] or 0.25, Enum.EasingStyle["Linear"], state and Enum.EasingDirection["Out"] or Enum.EasingDirection["In"]), {BackgroundTransparency = state and (render[2]["BackgroundTransparency"] or 0) or 1}):Play()
							end
							--
							if (render[2]["ScrollBarImageTransparency"] or 0) ~= 1 then
								TweenService:Create(render[1], TweenInfo.new(render[4] or 0.25, Enum.EasingStyle["Linear"], state and Enum.EasingDirection["Out"] or Enum.EasingDirection["In"]), {ScrollBarImageTransparency = state and (render[2]["ScrollBarImageTransparency"] or 0) or 1}):Play()
							end
						end
					end
				end
			end
			--
			function Window:Unload()
				ScreenGui:Remove()
				--
				for index, connection in pairs(library.Connections) do
					connection:Disconnect()
				end
				--
				library = nil
				utility = nil
			end
		end
		--
		do -- // Index Setting
			Window["TabsHolder"] = InnerBorder_InnerFrame_Tabs
			Window["PagesHolder"] = InnerBorder_InnerFrame_Folder
		end
		--
		do -- // Connections
			local OldPos = ScreenGui_MainFrame.Position
			utility:CreateConnection(UserInputService.InputBegan, function(Input)
				if Input.KeyCode and Input.KeyCode == Window.Key then
					Window.Enabled = not Window.Enabled
					--
					if Window.Enabled then
						ScreenGui_MainFrame.Position = OldPos
					else
						task.delay(.25,function()
							OldPos = ScreenGui_MainFrame.Position
							ScreenGui_MainFrame.Position = UDim2.new(0,0,5,0)
						end)
					end
					Window:Fade(Window.Enabled)
				end
			end)
		end
	end

	function Window:SetToggleKey(Key)
    	Window.Key = Key
	end
	--
	return setmetatable(Window, library)
end

--//Page
function library:CreatePage(Properties)
	Properties = Properties or {}
	--
	local Page = {
		Image = (Properties.image or Properties.Image or Properties.icon or Properties.Icon),
		Size = (Properties.size or Properties.Size or UDim2.new(0, 50, 0, 50)),
		Open = false,
		Window = self
	}
	--
	do
		local Page_Tab = utility:RenderObject("Frame", {
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Parent = Page.Window["TabsHolder"],
			Size = UDim2.new(1, 0, 0, 72)
		})
		-- //
		local Page_Tab_Border = utility:RenderObject("Frame", {
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 0,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Parent = Page_Tab,
			Size = UDim2.new(1, 0, 1, 0),
			Visible = false,
			ZIndex = 2,
			RenderTime = 0.15
		})
		--
		local Page_Tab_Image = utility:RenderObject("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Parent = Page_Tab,
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = Page.Size,
			ZIndex = 2,
			Image = Page.Image,
			ImageColor3 = Color3.fromRGB(100, 100, 100)
		})
		--
		local Page_Tab_Button = utility:RenderObject("TextButton", {
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Parent = Page_Tab,
			Size = UDim2.new(1, 0, 1, 0),
			Text = ""
		})
		-- //
		local Tab_Border_Inner = utility:RenderObject("Frame", {
			BackgroundColor3 = Color3.fromRGB(40, 40, 40),
			BackgroundTransparency = 0,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Parent = Page_Tab_Border,
			Position = UDim2.new(0, 0, 0, 1),
			Size = UDim2.new(1, 1, 1, -2),
			ZIndex = 2,
			RenderTime = 0.15
		})
		-- //
		local Border_Inner_Inner = utility:RenderObject("Frame", {
			BackgroundColor3 = Color3.fromRGB(20, 20, 20),
			BackgroundTransparency = 0,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Parent = Tab_Border_Inner,
			Position = UDim2.new(0, 0, 0, 1),
			Size = UDim2.new(1, 0, 1, -2),
			ZIndex = 2,
			RenderTime = 0.15
		})
		--
		local Inner_Inner_Pattern = utility:RenderObject("ImageLabel", {
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Parent = Border_Inner_Inner,
			Position = UDim2.new(0, 0, 0, 0),
			Size = UDim2.new(1, 0, 1, 0),
			Image = utility:GetAsset("InnerInnerPattern.png"),
			ImageColor3 = Color3.fromRGB(12, 12, 12),
			ScaleType = "Tile",
			TileSize = UDim2.new(0, 8, 0, 8),
			ZIndex = 2
		})
		-- //
		local Page_Page = utility:RenderObject("Frame", {
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Parent = Page.Window["PagesHolder"],
			Position = UDim2.new(0, 20, 0, 20),
			Size = UDim2.new(1, -40, 1, -40),
			Visible = false
		})
		-- //
		local Page_Page_Left = utility:RenderObject("Frame", {
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Parent = Page_Page,
			Position = UDim2.new(0, 0, 0, 0),
			Size = UDim2.new(0.5, -10, 1, 0)
		})
		--
		local Page_Page_Right = utility:RenderObject("Frame", {
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Parent = Page_Page,
			Position = UDim2.new(0.5, 10, 0, 0),
			Size = UDim2.new(0.5, -10, 1, 0)
		})
		-- //
		local Page_Left_List = utility:RenderObject("UIListLayout", {
			Padding = UDim.new(0, 18),
			Parent = Page_Page_Left,
			FillDirection = "Vertical",
			HorizontalAlignment = "Left",
			VerticalAlignment = "Top"
		})
		--
		local Page_Right_List = utility:RenderObject("UIListLayout", {
			Padding = UDim.new(0, 18),
			Parent = Page_Page_Right,
			FillDirection = "Vertical",
			HorizontalAlignment = "Left",
			VerticalAlignment = "Top"
		})
		--
		do -- // Index Setting
			Page["Page"] = Page_Page
			Page["Left"] = Page_Page_Left
			Page["Right"] = Page_Page_Right
		end
		--
		do -- // Functions
			function Page:Set(state)
				Page.Open = state
				--
				Page_Page.Visible = Page.Open
				Page_Tab_Border.Visible = Page.Open
				Page_Tab_Image.ImageColor3 = Page.Open and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(90, 90, 90)
				--
				if Page.Open then
					Page.Window:SetPage(Page)
				end
			end
		end
		--
		do -- // Connections
			utility:CreateConnection(Page_Tab_Button.MouseButton1Click, function(Input)
				if not Page.Open then
					Page:Set(true)
				end
			end)
			--
			utility:CreateConnection(Page_Tab_Button.MouseEnter, function(Input)
				Page_Tab_Image.ImageColor3 = Color3.fromRGB(172, 172, 172)
			end)
			--
			utility:CreateConnection(Page_Tab_Button.MouseLeave, function(Input)
				Page_Tab_Image.ImageColor3 = Page.Open and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(90, 90, 90)
			end)
		end
	end
	--
	if #Page.Window.Pages == 0 then Page:Set(true) end
	Page.Window.Pages[#Page.Window.Pages + 1] = Page
	return setmetatable(Page, pages)
end

--//Section
function pages:CreateSection(Properties)
	Properties = Properties or {}
	--
	local Section = {
		Name = (Properties.name or Properties.Name or Properties.title or Properties.Title or "New Section"),
		Size = (Properties.size or Properties.Size or 150),
		Side = (Properties.side or Properties.Side or "Left"),
		Content = {},
		Window = self.Window,
		Page = self
	}
	--
	do
		local Section_Holder = utility:RenderObject("Frame", {
			BackgroundColor3 = Color3.fromRGB(40, 40, 40),
			BackgroundTransparency = 0,
			BorderColor3 = Color3.fromRGB(12, 12, 12),
			BorderMode = "Inset",
			BorderSizePixel = 1,
			Parent = Section.Page[Section.Side],
			Size = UDim2.new(1, 0, 0, Section.Size),
			ZIndex = 2
		})
		-- //
		local Section_Holder_Extra = utility:RenderObject("Frame", {
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Parent = Section_Holder,
			Position = UDim2.new(0, 1, 0, 1),
			Size = UDim2.new(1, -2, 1, -2),
			ZIndex = 2
		})
		--
		local Section_Holder_Frame = utility:RenderObject("Frame", {
			BackgroundColor3 = Color3.fromRGB(23, 23, 23),
			BackgroundTransparency = 0,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Parent = Section_Holder,
			Position = UDim2.new(0, 1, 0, 1),
			Size = UDim2.new(1, -2, 1, -2),
			ZIndex = 2
		})
		--
		local Section_Holder_TitleInline = utility:RenderObject("Frame", {
			BackgroundColor3 = Color3.fromRGB(23, 23, 23),
			BackgroundTransparency = 0,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Parent = Section_Holder,
			Position = UDim2.new(0, 9, 0, -1),
			Size = UDim2.new(0, 0, 0, 2),
			ZIndex = 5
		})
		--
		local Section_Holder_Title = utility:RenderObject("TextLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Parent = Section_Holder,
			Position = UDim2.new(0, 12, 0, 0),
			Size = UDim2.new(1, -26, 0, 15),
			ZIndex = 5,
			Font = "Code",
			RichText = true,
			Text = "<b>" .. Section.Name .. "</b>",
			TextColor3 = Color3.fromRGB(205, 205, 205),
			TextSize = 11,
			TextStrokeTransparency = 1,
			TextXAlignment = "Left"
		})
		-- //
		local Holder_Extra_Gradient1 = utility:RenderObject("ImageLabel", {
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Parent = Section_Holder_Extra,
			Position = UDim2.new(0, 1, 0, 1),
			Rotation = 180,
			Size = UDim2.new(1, -2, 0, 20),
			Visible = false,
			ZIndex = 4,
			Image = utility:GetAsset("HolderExtraGradient.png"),
			ImageColor3 = Color3.fromRGB(23, 23, 23)
		})
		--
		local Holder_Extra_Gradient2 = utility:RenderObject("ImageLabel", {
			AnchorPoint = Vector2.new(0, 1),
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Parent = Section_Holder_Extra,
			Position = UDim2.new(0, 0, 1, 0),
			Size = UDim2.new(1, -2, 0, 20),
			Visible = false,
			ZIndex = 4,
			Image = utility:GetAsset("HolderExtraGradient.png"),
			ImageColor3 = Color3.fromRGB(23, 23, 23)
		})
		--
		local Holder_Extra_ArrowUp = utility:RenderObject("TextButton", {
			BackgroundColor3 = Color3.fromRGB(255, 0, 0),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Parent = Section_Holder_Extra,
			Position = UDim2.new(1, -21, 0, 0),
			Size = UDim2.new(0, 7 + 8, 0, 6 + 8),
			Text = "",
			Visible = false,
			ZIndex = 4
		})
		--
		local Holder_Extra_ArrowDown = utility:RenderObject("TextButton", {
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Parent = Section_Holder_Extra,
			Position = UDim2.new(1, -21, 1, -(6 + 8)),
			Size = UDim2.new(0, 7 + 8, 0, 6 + 8),
			Text = "",
			Visible = false,
			ZIndex = 4
		})
		-- //
		local Extra_ArrowUp_Image = utility:RenderObject("ImageLabel", {
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Parent = Holder_Extra_ArrowUp,
			Position = UDim2.new(0, 4, 0, 4),
			Size = UDim2.new(0, 7, 0, 6),
			Visible = true,
			ZIndex = 4,
			Image = utility:GetAsset("ExtraArrowUp.png"),
			ImageColor3 = Color3.fromRGB(205, 205, 205)
		})
		--
		local Extra_ArrowDown_Image = utility:RenderObject("ImageLabel", {
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Parent = Holder_Extra_ArrowDown,
			Position = UDim2.new(0, 4, 0, 4),
			Size = UDim2.new(0, 7, 0, 6),
			Visible = true,
			ZIndex = 4,
			Image = utility:GetAsset("ExtraArrowDown.png"),
			ImageColor3 = Color3.fromRGB(205, 205, 205)
		})
		--
		local Holder_Extra_Bar = utility:RenderObject("Frame", {
			AnchorPoint = Vector2.new(1, 0),
			BackgroundColor3 = Color3.fromRGB(45, 45, 45),
			BackgroundTransparency = 0,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Parent = Section_Holder_Extra,
			Position = UDim2.new(1, 0, 0, 0),
			Size = UDim2.new(0, 6, 1, 0),
			Visible = false,
			ZIndex = 4
		})
		--
		local Holder_Extra_Line = utility:RenderObject("Frame", {
			BackgroundColor3 = Color3.fromRGB(45, 45, 45),
			BackgroundTransparency = 0,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Parent = Section_Holder_Extra,
			Position = UDim2.new(0, 0, 0, -1),
			Size = UDim2.new(1, 0, 0, 1),
			ZIndex = 4
		})
		--
		local Holder_Frame_ContentHolder = utility:RenderObject("ScrollingFrame", {
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Parent = Section_Holder_Frame,
			Position = UDim2.new(0, 0, 0, 0),
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 4,
			AutomaticCanvasSize = "Y",
			BottomImage = utility:GetAsset("ScrollBar.png"),
			CanvasSize = UDim2.new(0, 0, 0, 0),
			MidImage = utility:GetAsset("ScrollBar.png"),
			ScrollBarImageColor3 = Color3.fromRGB(65, 65, 65),
			ScrollBarImageTransparency = 0,
			ScrollBarThickness = 5,
			TopImage = utility:GetAsset("ScrollBar.png"),
			VerticalScrollBarInset = "None"
		})
		-- //
		local Frame_ContentHolder_List = utility:RenderObject("UIListLayout", {
			Padding = UDim.new(0, 0),
			Parent = Holder_Frame_ContentHolder,
			FillDirection = "Vertical",
			HorizontalAlignment = "Center",
			VerticalAlignment = "Top"
		})
		--
		local Frame_ContentHolder_Padding = utility:RenderObject("UIPadding", {
			Parent = Holder_Frame_ContentHolder,
			PaddingTop = UDim.new(0, 15),
			PaddingBottom = UDim.new(0, 15)
		})
		--
		do -- // Section Init
			Section_Holder_TitleInline.Size = UDim2.new(0, Section_Holder_Title.TextBounds.X + 6, 0, 2)
		end
		--
		do -- // Index Setting
			Section["Holder"] = Holder_Frame_ContentHolder
			Section["Extra"] = Section_Holder_Extra
		end
		--
		do -- // Functions
			function Section:CloseContent()
				if Section.Content.Open then
					Section.Content:Close()
					--
					Section.Content = {}
				end
			end
		end
		--
		do -- // Connections
			utility:CreateConnection(Holder_Frame_ContentHolder:GetPropertyChangedSignal("AbsoluteCanvasSize"), function()
				Holder_Extra_Gradient1.Visible = Holder_Frame_ContentHolder.AbsoluteCanvasSize.Y > Holder_Frame_ContentHolder.AbsoluteWindowSize.Y
				Holder_Extra_Gradient2.Visible = Holder_Frame_ContentHolder.AbsoluteCanvasSize.Y > Holder_Frame_ContentHolder.AbsoluteWindowSize.Y
				Holder_Extra_Bar.Visible = Holder_Frame_ContentHolder.AbsoluteCanvasSize.Y > Holder_Frame_ContentHolder.AbsoluteWindowSize.Y
				--
				if (Holder_Frame_ContentHolder.AbsoluteCanvasSize.Y > Holder_Frame_ContentHolder.AbsoluteWindowSize.Y) then
					Holder_Extra_ArrowUp.Visible = (Holder_Frame_ContentHolder.CanvasPosition.Y > 5)
					Holder_Extra_ArrowDown.Visible = (Holder_Frame_ContentHolder.CanvasPosition.Y + 5 < (Holder_Frame_ContentHolder.AbsoluteCanvasSize.Y - Holder_Frame_ContentHolder.AbsoluteSize.Y))
				end
			end)
			--
			utility:CreateConnection(Holder_Frame_ContentHolder:GetPropertyChangedSignal("CanvasPosition"), function()
				if Section.Content.Open then
					Section.Content:Close()
					--
					Section.Content = {}
				end
				--
				Holder_Extra_ArrowUp.Visible = (Holder_Frame_ContentHolder.CanvasPosition.Y > 1)
				Holder_Extra_ArrowDown.Visible = (Holder_Frame_ContentHolder.CanvasPosition.Y + 1 < (Holder_Frame_ContentHolder.AbsoluteCanvasSize.Y - Holder_Frame_ContentHolder.AbsoluteSize.Y))
			end)
			--
			utility:CreateConnection(Holder_Extra_ArrowUp.MouseButton1Click, function()
				Holder_Frame_ContentHolder.CanvasPosition = Vector2.new(0, math.clamp(Holder_Frame_ContentHolder.CanvasPosition.Y - 10, 0, Holder_Frame_ContentHolder.AbsoluteCanvasSize.Y - Holder_Frame_ContentHolder.AbsoluteSize.Y))
			end)
			--
			utility:CreateConnection(Holder_Extra_ArrowDown.MouseButton1Click, function()
				Holder_Frame_ContentHolder.CanvasPosition = Vector2.new(0, math.clamp(Holder_Frame_ContentHolder.CanvasPosition.Y + 10, 0, Holder_Frame_ContentHolder.AbsoluteCanvasSize.Y - Holder_Frame_ContentHolder.AbsoluteSize.Y))
			end)
		end
	end
	--
	return setmetatable(Section, sections)
end

do -- // Content
	--//Toggle
	function sections:CreateToggle(FlagName, Properties)
		Properties = Properties or {}
		--
		local Content_ = {
			Name = (Properties.name or Properties.Name or Properties.title or Properties.Title or "New Toggle"),
			State = (Properties.state or Properties.State or Properties.def or Properties.Def or Properties.default or Properties.Default or false),
			Callback = (Properties.callback or Properties.Callback or Properties.callBack or Properties.CallBack or function() end),
			Window = self.Window,
			Page = self.Page,
			Section = self
		}
		createdObjects.toggles[FlagName] = Content_
		--
		do
			local Content_Holder = utility:RenderObject("Frame", {
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Parent = Content_.Section.Holder,
				Size = UDim2.new(1, 0, 0, 8 + 10),
				ZIndex = 3
			})
			-- //
			local Content_Holder_Outline = utility:RenderObject("Frame", {
				BackgroundColor3 = Color3.fromRGB(12, 12, 12),
				BackgroundTransparency = 0,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Parent = Content_Holder,
				Position = UDim2.new(0, 20, 0, 5),
				Size = UDim2.new(0, 8, 0, 8),
				ZIndex = 3
			})
			--
			local Content_Holder_Title = utility:RenderObject("TextLabel", {
				AnchorPoint = Vector2.new(0, 0),
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Parent = Content_Holder,
				Position = UDim2.new(0, 41, 0, 0),
				Size = UDim2.new(1, -41, 1, 0),
				ZIndex = 3,
				Font = "Code",
				RichText = true,
				Text = Content_.Name,
				TextColor3 = Color3.fromRGB(205, 205, 205),
				TextSize = 9,
				TextStrokeTransparency = 1,
				TextXAlignment = "Left"
			})
			--
			local Content_Holder_Title2 = utility:RenderObject("TextLabel", {
				AnchorPoint = Vector2.new(0, 0),
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Parent = Content_Holder,
				Position = UDim2.new(0, 41, 0, 0),
				Size = UDim2.new(1, -41, 1, 0),
				ZIndex = 3,
				Font = "Code",
				RichText = true,
				Text = Content_.Name,
				TextColor3 = Color3.fromRGB(205, 205, 205),
				TextSize = 9,
				TextStrokeTransparency = 1,
				TextTransparency = 0.5,
				TextXAlignment = "Left"
			})
			--
			local Content_Holder_Button = utility:RenderObject("TextButton", {
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Parent = Content_Holder,
				Size = UDim2.new(1, 0, 1, 0),
				Text = ""
			})
			-- //
			local Holder_Outline_Frame = utility:RenderObject("Frame", {
				BackgroundColor3 = Color3.fromRGB(77, 77, 77),
				BackgroundTransparency = 0,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Parent = Content_Holder_Outline,
				Position = UDim2.new(0, 1, 0, 1),
				Size = UDim2.new(1, -2, 1, -2),
				ZIndex = 3
			})
			-- //
			local Outline_Frame_Gradient = utility:RenderObject("UIGradient", {
				Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(140, 140, 140)),
				Enabled = true,
				Rotation = 90,
				Parent = Holder_Outline_Frame
			})
			--
			do -- // Functions
				function Content_:Set(state)
					Content_.State = state
					--
					Holder_Outline_Frame.BackgroundColor3 = Content_.State and Content_.Window.Accent or Color3.fromRGB(77, 77, 77)
					--
					Content_.Callback(Content_:Get())
				end
				--
				function Content_:Get()
					return Content_.State
				end
			end
			--
			do -- // Connections
				utility:CreateConnection(Content_Holder_Button.MouseButton1Click, function(Input)
					Content_:Set(not Content_:Get())
				end)
				--
				utility:CreateConnection(Content_Holder_Button.MouseEnter, function(Input)
					Outline_Frame_Gradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(180, 180, 180))
				end)
				--
				utility:CreateConnection(Content_Holder_Button.MouseLeave, function(Input)
					Outline_Frame_Gradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(140, 140, 140))
				end)
			end
			--
			Content_:Set(Content_.State)
		end
		--
		return Content_
	end

	--//Slider
	function sections:CreateSlider(FlagName,Properties)
		Properties = Properties or {}
		--
		local Content_ = {
			Name = (Properties.name or Properties.Name or Properties.title or Properties.Title or nil),
			State = (Properties.state or Properties.State or Properties.def or Properties.Def or Properties.default or Properties.Default or 0),
			Min = (Properties.min or Properties.Min or Properties.minimum or Properties.Minimum or 0),
			Max = (Properties.max or Properties.Max or Properties.maxmimum or Properties.Maximum or 100),
			Ending = (Properties.ending or Properties.Ending or Properties.suffix or Properties.Suffix or ""),
			Decimals = (1 / (Properties.decimals or Properties.Decimals or Properties.tick or Properties.Tick or 1)),
			Callback = (Properties.callback or Properties.Callback or Properties.callBack or Properties.CallBack or function() end),
			Holding = false,
			Window = self.Window,
			Page = self.Page,
			Section = self
		}
		createdObjects.sliders[FlagName] = Content_
		--
		do
			local Content_Holder = utility:RenderObject("Frame", {
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Parent = Content_.Section.Holder,
				Size = UDim2.new(1, 0, 0, (Content_.Name and 24 or 13) + 5),
				ZIndex = 3
			})
			-- //
			local Content_Holder_Outline = utility:RenderObject("Frame", {
				BackgroundColor3 = Color3.fromRGB(12, 12, 12),
				BackgroundTransparency = 0,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Parent = Content_Holder,
				Position = UDim2.new(0, 40, 0, Content_.Name and 18 or 5),
				Size = UDim2.new(1, -99, 0, 7),
				ZIndex = 3
			})
			--
			if Content_.Name then
				local Content_Holder_Title = utility:RenderObject("TextLabel", {
					AnchorPoint = Vector2.new(0, 0),
					BackgroundColor3 = Color3.fromRGB(0, 0, 0),
					BackgroundTransparency = 1,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Parent = Content_Holder,
					Position = UDim2.new(0, 41, 0, 4),
					Size = UDim2.new(1, -41, 0, 10),
					ZIndex = 3,
					Font = "Code",
					RichText = true,
					Text = Content_.Name,
					TextColor3 = Color3.fromRGB(205, 205, 205),
					TextSize = 9,
					TextStrokeTransparency = 1,
					TextXAlignment = "Left"
				})
				--
				local Content_Holder_Title2 = utility:RenderObject("TextLabel", {
					AnchorPoint = Vector2.new(0, 0),
					BackgroundColor3 = Color3.fromRGB(0, 0, 0),
					BackgroundTransparency = 1,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Parent = Content_Holder,
					Position = UDim2.new(0, 41, 0, 4),
					Size = UDim2.new(1, -41, 0, 10),
					ZIndex = 3,
					Font = "Code",
					RichText = true,
					Text = Content_.Name,
					TextColor3 = Color3.fromRGB(205, 205, 205),
					TextSize = 9,
					TextStrokeTransparency = 1,
					TextTransparency = 0.5,
					TextXAlignment = "Left"
				})
			end
			--
			local Content_Holder_Button = utility:RenderObject("TextButton", {
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Parent = Content_Holder,
				Size = UDim2.new(1, 0, 1, 0),
				Text = ""
			})
			-- //
			local Holder_Outline_Frame = utility:RenderObject("Frame", {
				BackgroundColor3 = Color3.fromRGB(71, 71, 71),
				BackgroundTransparency = 0,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Parent = Content_Holder_Outline,
				Position = UDim2.new(0, 1, 0, 1),
				Size = UDim2.new(1, -2, 1, -2),
				ZIndex = 3
			})
			-- //
			local Outline_Frame_Slider = utility:RenderObject("Frame", {
				BackgroundColor3 = Content_.Window.Accent,
				BackgroundTransparency = 0,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Parent = Holder_Outline_Frame,
				Position = UDim2.new(0, 0, 0, 0),
				Size = UDim2.new(0, 0, 1, 0),
				ZIndex = 3
			})
			--
			local Outline_Frame_Gradient = utility:RenderObject("UIGradient", {
				Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(175, 175, 175)),
				Enabled = true,
				Rotation = 270,
				Parent = Holder_Outline_Frame
			})
			-- //
			local Frame_Slider_Gradient = utility:RenderObject("UIGradient", {
				Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(175, 175, 175)),
				Enabled = true,
				Rotation = 90,
				Parent = Outline_Frame_Slider
			})
			-- //
			local Frame_Slider_Title = utility:RenderObject("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Parent = Outline_Frame_Slider,
				Position = UDim2.new(1, 0, 0.5, 1),
				Size = UDim2.new(0, 2, 1, 0),
				ZIndex = 3,
				Font = "Code",
				RichText = true,
				Text = "",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 11,
				TextStrokeTransparency = 0.5,
				TextXAlignment = "Center",
				RenderTime = 0.15
			})
			--
			local Frame_Slider_Title2 = utility:RenderObject("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Parent = Outline_Frame_Slider,
				Position = UDim2.new(1, 0, 0.5, 1),
				Size = UDim2.new(0, 2, 1, 0),
				ZIndex = 3,
				Font = "Code",
				RichText = true,
				Text = "",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 11,
				TextStrokeTransparency = 0.5,
				TextTransparency = 0,
				TextXAlignment = "Center",
				RenderTime = 0.15
			})
			--
			do -- // Functions
				function Content_:Set(state)
					Content_.State = math.clamp(math.round(state * Content_.Decimals) / Content_.Decimals, Content_.Min, Content_.Max)
					--
					local Ending = Content_.Ending
					if type(Ending) == "function" then
						Ending = Ending(Content_.State)
					end
					Frame_Slider_Title.Text = "<b>" .. Content_.State .. tostring(Ending or "") .. "</b>"
					Outline_Frame_Slider.Size = UDim2.new((1 - ((Content_.Max - Content_.State) / (Content_.Max - Content_.Min))), 0, 1, 0)
					--
					Content_.Callback(Content_:Get())
				end
				--
				function Content_:Refresh()
					local Mouse = utility:MouseLocation()
					--
					Content_:Set(math.clamp(math.floor((Content_.Min + (Content_.Max - Content_.Min) * math.clamp(Mouse.X - Outline_Frame_Slider.AbsolutePosition.X, 0, Holder_Outline_Frame.AbsoluteSize.X) / Holder_Outline_Frame.AbsoluteSize.X) * Content_.Decimals) / Content_.Decimals, Content_.Min, Content_.Max))
				end
				--
				function Content_:Get()
					return Content_.State
				end
			end
			--
			do -- // Connections
				utility:CreateConnection(Content_Holder_Button.MouseButton1Down, function(Input)
					Content_:Refresh()
					--
					Content_.Holding = true
					--
					Outline_Frame_Gradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(215, 215, 215))
					Frame_Slider_Gradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(215, 215, 215))
				end)
				--
				utility:CreateConnection(Content_Holder_Button.MouseEnter, function(Input)
					Outline_Frame_Gradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(215, 215, 215))
					Frame_Slider_Gradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(215, 215, 215))
				end)
				--
				utility:CreateConnection(Content_Holder_Button.MouseLeave, function(Input)
					Outline_Frame_Gradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Content_.Holding and Color3.fromRGB(215, 215, 215) or Color3.fromRGB(175, 175, 175))
					Frame_Slider_Gradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Content_.Holding and Color3.fromRGB(215, 215, 215) or Color3.fromRGB(175, 175, 175))
				end)
				--
				utility:CreateConnection(UserInputService.InputChanged, function(Input)
					if Content_.Holding then
						Content_:Refresh()
					end
				end)
				--
				utility:CreateConnection(UserInputService.InputEnded, function(Input)
					if Content_.Holding and Input.UserInputType == Enum.UserInputType.MouseButton1 then
						Content_.Holding = false
						--
						Outline_Frame_Gradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(175, 175, 175))
						Frame_Slider_Gradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(175, 175, 175))
					end
				end)
			end
			--
			Content_:Set(Content_.State)
		end
		--
		return Content_
	end

	--//Dropdown
	function sections:CreateDropdown(FlagName,Properties)
		Properties = Properties or {}
		--
		local Content_ = {
			Name = (Properties.name or Properties.Name or Properties.title or Properties.Title or "New Dropdown"),
			State = (Properties.state or Properties.State or Properties.def or Properties.Def or Properties.default or Properties.Default or 1),
			Options = (Properties.options or Properties.Options or Properties.list or Properties.List or {1, 2, 3}),
			Callback = (Properties.callback or Properties.Callback or Properties.callBack or Properties.CallBack or function() end),
			Content = {
				Open = false
			},
			Window = self.Window,
			Page = self.Page,
			Section = self
		}
		createdObjects.dropdowns[FlagName] = Content_
		--
		do
			local Content_Holder = utility:RenderObject("Frame", {
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Parent = Content_.Section.Holder,
				Size = UDim2.new(1, 0, 0, 34 + 5),
				ZIndex = 3
			})
			-- //
			local Content_Holder_Outline = utility:RenderObject("Frame", {
				BackgroundColor3 = Color3.fromRGB(12, 12, 12),
				BackgroundTransparency = 0,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Parent = Content_Holder,
				Position = UDim2.new(0, 40, 0, 15),
				Size = UDim2.new(1, -98, 0, 20),
				ZIndex = 3
			})
			--
			local Content_Holder_Title = utility:RenderObject("TextLabel", {
				AnchorPoint = Vector2.new(0, 0),
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Parent = Content_Holder,
				Position = UDim2.new(0, 41, 0, 4),
				Size = UDim2.new(1, -41, 0, 10),
				ZIndex = 3,
				Font = "Code",
				RichText = true,
				Text = Content_.Name,
				TextColor3 = Color3.fromRGB(205, 205, 205),
				TextSize = 9,
				TextStrokeTransparency = 1,
				TextXAlignment = "Left"
			})
			--
			local Content_Holder_Title2 = utility:RenderObject("TextLabel", {
				AnchorPoint = Vector2.new(0, 0),
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Parent = Content_Holder,
				Position = UDim2.new(0, 41, 0, 4),
				Size = UDim2.new(1, -41, 0, 10),
				ZIndex = 3,
				Font = "Code",
				RichText = true,
				Text = Content_.Name,
				TextColor3 = Color3.fromRGB(205, 205, 205),
				TextSize = 9,
				TextStrokeTransparency = 1,
				TextTransparency = 0.5,
				TextXAlignment = "Left"
			})
			--
			local Content_Holder_Button = utility:RenderObject("TextButton", {
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Parent = Content_Holder,
				Size = UDim2.new(1, 0, 1, 0),
				Text = ""
			})
			-- //
			local Holder_Outline_Frame = utility:RenderObject("Frame", {
				BackgroundColor3 = Color3.fromRGB(36, 36, 36),
				BackgroundTransparency = 0,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Parent = Content_Holder_Outline,
				Position = UDim2.new(0, 1, 0, 1),
				Size = UDim2.new(1, -2, 1, -2),
				ZIndex = 3
			})
			-- //
			local Outline_Frame_Gradient = utility:RenderObject("UIGradient", {
				Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(220, 220, 220)),
				Enabled = true,
				Rotation = 270,
				Parent = Holder_Outline_Frame
			})
			--
			local Outline_Frame_Title = utility:RenderObject("TextLabel", {
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Parent = Holder_Outline_Frame,
				Position = UDim2.new(0, 8, 0, 0),
				Size = UDim2.new(1, 0, 1, 0),
				ZIndex = 3,
				Font = "Code",
				RichText = true,
				Text = "",
				TextColor3 = Color3.fromRGB(155, 155, 155),
				TextSize = 9,
				TextStrokeTransparency = 1,
				TextXAlignment = "Left"
			})
			--
			local Outline_Frame_Title2 = utility:RenderObject("TextLabel", {
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Parent = Holder_Outline_Frame,
				Position = UDim2.new(0, 8, 0, 0),
				Size = UDim2.new(1, 0, 1, 0),
				ZIndex = 3,
				Font = "Code",
				RichText = true,
				Text = "",
				TextColor3 = Color3.fromRGB(155, 155, 155),
				TextSize = 9,
				TextStrokeTransparency = 1,
				TextTransparency = 0,
				TextXAlignment = "Left"
			})
			--
			local Outline_Frame_Arrow = utility:RenderObject("ImageLabel", {
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Parent = Holder_Outline_Frame,
				Position = UDim2.new(1, -11, 0.5, -4),
				Size = UDim2.new(0, 7, 0, 6),
				Image = utility:GetAsset("OutlineFrameArrow.png"),
				ImageColor3 = Color3.fromRGB(255, 255, 255),
				ZIndex = 3
			})
			--
			do -- // Functions
				function Content_:Set(state)
					Content_.State = state
					--
					Outline_Frame_Title.Text = Content_.Options[Content_:Get()]
					Outline_Frame_Title2.Text = Content_.Options[Content_:Get()]
					--
					Content_.Callback(Content_.Options[Content_:Get()])
					--
					if Content_.Content.Open then
						Content_.Content:Refresh(Content_:Get())
					end
				end
				--
				function Content_:Get()
					return Content_.State
				end
				--
				function Content_:Open()
					
					Content_.Section:CloseContent()
					--
					local Open = {}
					local Connections = {}
					--
					local InputCheck
					--
					--
					local Content_Open_Holder = utility:RenderObject("Frame", {
						BackgroundColor3 = Color3.fromRGB(0, 0, 0),
						BackgroundTransparency = 1,
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						Parent = Content_.Section.Extra,
						Position = UDim2.new(0, Content_Holder_Outline.AbsolutePosition.X - Content_.Section.Extra.AbsolutePosition.X, 0, Content_Holder_Outline.AbsolutePosition.Y - Content_.Section.Extra.AbsolutePosition.Y + 21),
						Size = UDim2.new(1, -98, 0, (18 * #Content_.Options) + 2),
						ZIndex = 6
					})
					-- //
					local Open_Holder_Outline = utility:RenderObject("Frame", {
						BackgroundColor3 = Color3.fromRGB(12, 12, 12),
						BackgroundTransparency = 0,
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						Parent = Content_Open_Holder,
						Position = UDim2.new(0, 0, 0, 0),
						Size = UDim2.new(1, 0, 1, 0),
						ZIndex = 6
					})
					-- //
					local Open_Holder_Outline_Frame = utility:RenderObject("Frame", {
						BackgroundColor3 = Color3.fromRGB(35, 35, 35),
						BackgroundTransparency = 0,
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						Parent = Open_Holder_Outline,
						Position = UDim2.new(0, 1, 0, 1),
						Size = UDim2.new(1, -2, 1, -2),
						ZIndex = 6
					})
					-- //
					for Index, Option in pairs(Content_.Options) do
						local Outline_Frame_Option = utility:RenderObject("Frame", {
							BackgroundColor3 = Color3.fromRGB(35, 35, 35),
							BackgroundTransparency = 0,
							BorderColor3 = Color3.fromRGB(0, 0, 0),
							BorderSizePixel = 0,
							Parent = Open_Holder_Outline_Frame,
							Position = UDim2.new(0, 0, 0, 18 * (Index - 1)),
							Size = UDim2.new(1, 0, 1 / #Content_.Options, 0),
							ZIndex = 6
						})
						-- //
						local Frame_Option_Title = utility:RenderObject("TextLabel", {
							BackgroundColor3 = Color3.fromRGB(0, 0, 0),
							BackgroundTransparency = 1,
							BorderColor3 = Color3.fromRGB(0, 0, 0),
							BorderSizePixel = 0,
							Parent = Outline_Frame_Option,
							Position = UDim2.new(0, 8, 0, 0),
							Size = UDim2.new(1, 0, 1, 0),
							ZIndex = 6,
							Font = "Code",
							RichText = true,
							Text = tostring(Option),
							TextColor3 = Index == Content_.State and Content_.Window.Accent or Color3.fromRGB(205, 205, 205),
							TextSize = 9,
							TextStrokeTransparency = 1,
							TextXAlignment = "Left"
						})
						--
						local Frame_Option_Title2 = utility:RenderObject("TextLabel", {
							BackgroundColor3 = Color3.fromRGB(0, 0, 0),
							BackgroundTransparency = 1,
							BorderColor3 = Color3.fromRGB(0, 0, 0),
							BorderSizePixel = 0,
							Parent = Outline_Frame_Option,
							Position = UDim2.new(0, 8, 0, 0),
							Size = UDim2.new(1, 0, 1, 0),
							ZIndex = 6,
							Font = "Code",
							RichText = true,
							Text = tostring(Option),
							TextColor3 = Index == Content_.State and Content_.Window.Accent or Color3.fromRGB(205, 205, 205),
							TextSize = 9,
							TextStrokeTransparency = 1,
							TextTransparency = 0.5,
							TextXAlignment = "Left"
						})
						--
						local Frame_Option_Button = utility:RenderObject("TextButton", {
							BackgroundColor3 = Color3.fromRGB(0, 0, 0),
							BackgroundTransparency = 1,
							BorderColor3 = Color3.fromRGB(0, 0, 0),
							BorderSizePixel = 0,
							Parent = Outline_Frame_Option,
							Size = UDim2.new(1, 0, 1, 0),
							Text = "",
							ZIndex = 6
						})
						--
						do -- // Connections
							local Clicked = utility:CreateConnection(Frame_Option_Button.MouseButton1Click, function(Input)
								Content_:Set(Index)
							end)
							--
							local Entered = utility:CreateConnection(Frame_Option_Button.MouseEnter, function(Input)
								Outline_Frame_Option.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
							end)
							--
							local Left = utility:CreateConnection(Frame_Option_Button.MouseLeave, function(Input)
								Outline_Frame_Option.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
							end)
							--
							Connections[#Connections + 1] = Clicked
							Connections[#Connections + 1] = Entered
							Connections[#Connections + 1] = Left
						end
						--
						Open[#Open + 1] = {Index, Frame_Option_Title, Frame_Option_Title2, Outline_Frame_Option, Frame_Option_Button}
					end
					--
					do -- // Functions
						function Content_.Content:Close()
							Content_.Content.Open = false
							--
							Holder_Outline_Frame.BackgroundColor3 = Color3.fromRGB(36, 36, 36)
							--
							for Index, Value in pairs(Connections) do
								Value:Disconnect()
							end
							--
							InputCheck:Disconnect()
							--
							for Index, Value in pairs(Open) do
								Value[2]:Remove()
								Value[3]:Remove()
								Value[4]:Remove()
								Value[5]:Remove()
							end
							--
							Content_Open_Holder:Remove()
							Open_Holder_Outline:Remove()
							Open_Holder_Outline_Frame:Remove()
							--
							function Content_.Content:Refresh() end
							--
							InputCheck = nil
							Connections = nil
							Open = nil
						end
						--
						function Content_.Content:Refresh(state)
							for Index, Value in pairs(Open) do
								Value[2].TextColor3 = Value[1] == Content_.State and Content_.Window.Accent or Color3.fromRGB(205, 205, 205)
								Value[3].TextColor3 = Value[1] == Content_.State and Content_.Window.Accent or Color3.fromRGB(205, 205, 205)
							end
						end
					end
					--
					Content_.Content.Open = true
					Content_.Section.Content = Content_.Content
					--
					Holder_Outline_Frame.BackgroundColor3 = Color3.fromRGB(46, 46, 46)
					--
					do -- // Connections
						task.wait()
						--
						InputCheck = utility:CreateConnection(UserInputService.InputBegan, function(Input)
							if Content_.Content.Open and Input.UserInputType == Enum.UserInputType.MouseButton1 then
								local Mouse = utility:MouseLocation()
								--
								if not (Mouse.X >= Content_Open_Holder.AbsolutePosition.X  and Mouse.Y >= (Content_Open_Holder.AbsolutePosition.Y + 36 + (36/2)) and Mouse.X <= (Content_Open_Holder.AbsolutePosition.X + Content_Open_Holder.AbsoluteSize.X) and Mouse.Y <= (Content_Open_Holder.AbsolutePosition.Y + Content_Open_Holder.AbsoluteSize.Y + 36 + (36/2))) then
									Content_.Section:CloseContent()
								end
							end
						end)
					end
				end
			end
			--
			do -- // Connections
				utility:CreateConnection(Content_Holder_Button.MouseButton1Down, function(Input)
					if Content_.Content.Open then
						Content_.Section:CloseContent()
					else
						Content_:Open()
					end
				end)
				--
				utility:CreateConnection(Content_Holder_Button.MouseEnter, function(Input)
					Holder_Outline_Frame.BackgroundColor3 = Color3.fromRGB(46, 46, 46)
				end)
				--
				utility:CreateConnection(Content_Holder_Button.MouseLeave, function(Input)
					Holder_Outline_Frame.BackgroundColor3 = Content_.Content.Open and Color3.fromRGB(46, 46, 46) or Color3.fromRGB(36, 36, 36)
				end)
			end
			--
			Content_:Set(Content_.State)
		end
		--
		return Content_
	end

	--//Keybind
	function sections:CreateKeybind(FlagName, Properties)
		Properties = Properties or {}

		local Content_ = {
			Name = (Properties.name or Properties.Name or Properties.title or Properties.Title or "New Keybind"),
			State = (Properties.state or Properties.State or Properties.def or Properties.Def or Properties.default or Properties.Default or nil),
			Mode = (Properties.mode or Properties.Mode or "Toggle"),
			Callback = (Properties.callback or Properties.Callback or Properties.callBack or Properties.CallBack or function() end),
			HeldCallback = (Properties.HeldCallback or function() end),
			KeyChangeCallback = (Properties.KeyChangeCallback or function() end),
			Active = false,
			Holding = false,
			Content = {
				Open = false
			},
			Window = self.Window,
			Page = self.Page,
			Section = self
		}
		createdObjects.keybinds[FlagName] = Content_

		local Keys = {
			KeyCodes = {"Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "A", "S", "D", "F", "G", "H", "J", "K", "L", "Z", "X", "C", "V", "B", "N", "M", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "0", "Insert", "Tab", "Home", "End", "LeftAlt", "LeftControl", "LeftShift", "RightAlt", "RightControl", "RightShift", "CapsLock"},
			Inputs = {"MouseButton1", "MouseButton2", "MouseButton3"},
			Shortened = {["MouseButton1"] = "M1", ["MouseButton2"] = "M2", ["MouseButton3"] = "M3", ["Insert"] = "INS", ["LeftAlt"] = "LA", ["LeftControl"] = "LC", ["LeftShift"] = "LS", ["RightAlt"] = "RA", ["RightControl"] = "RC", ["RightShift"] = "RS", ["CapsLock"] = "CL"}
		}

		do
			local Content_Holder = utility:RenderObject("Frame", {
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Parent = Content_.Section.Holder,
				Size = UDim2.new(1, 0, 0, 18),
				ZIndex = 3
			})

			local Content_Holder_Title = utility:RenderObject("TextLabel", {
				AnchorPoint = Vector2.new(0, 0),
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Parent = Content_Holder,
				Position = UDim2.new(0, 41, 0, 0),
				Size = UDim2.new(1, -41, 1, 0),
				ZIndex = 3,
				Font = "Code",
				RichText = true,
				Text = Content_.Name,
				TextColor3 = Color3.fromRGB(205, 205, 205),
				TextSize = 9,
				TextStrokeTransparency = 1,
				TextXAlignment = "Left"
			})

			local Content_Holder_Title2 = utility:RenderObject("TextLabel", {
				AnchorPoint = Vector2.new(0, 0),
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Parent = Content_Holder,
				Position = UDim2.new(0, 41, 0, 0),
				Size = UDim2.new(1, -41, 1, 0),
				ZIndex = 3,
				Font = "Code",
				RichText = true,
				Text = Content_.Name,
				TextColor3 = Color3.fromRGB(205, 205, 205),
				TextSize = 9,
				TextStrokeTransparency = 1,
				TextTransparency = 0.5,
				TextXAlignment = "Left"
			})

			local Content_Holder_Button = utility:RenderObject("TextButton", {
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Parent = Content_Holder,
				Size = UDim2.new(1, 0, 1, 0),
				Text = ""
			})

			local Content_Holder_Value = utility:RenderObject("TextLabel", {
				AnchorPoint = Vector2.new(0, 0),
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Parent = Content_Holder,
				Position = UDim2.new(0, 41, 0, 0),
				Size = UDim2.new(1, -61, 1, 0),
				ZIndex = 3,
				Font = "Code",
				RichText = true,
				Text =  "",
				TextColor3 = Color3.fromRGB(114, 114, 114),
				TextStrokeColor3 = Color3.fromRGB(15, 15, 15),
				TextSize = 9,
				TextStrokeTransparency = 0,
				TextXAlignment = "Right"
			})

			do
				function Content_:Set(state)
					Content_.State = state or {}
					Content_.Active = false

					local KeyName = (#Content_:Get() > 0 and Content_:Shorten(Content_:Get()[2]) or "-")
					Content_Holder_Value.Text = "[" .. KeyName .. "]"

					if library.KeybindList then
						local RealKey = (#Content_:Get() > 0 and Content_:Get()[2] or nil)
						library.KeybindList:Update(FlagName, Content_.Name, Content_:Shorten(RealKey), Content_.Active)
					end
				end

				function Content_:Get()
					return Content_.State
				end

				function Content_:IsHeld()
					return Content_.Active
				end

				function Content_:GetMode()
					return Content_.Mode
				end

				function Content_:GetKey()
					return Content_:Get()[2]
				end

				function Content_:Shorten(Str)
					if not Str then return "None" end
					for Index, Value in pairs(Keys.Shortened) do
						Str = string.gsub(Str, Index, Value)
					end
					return Str
				end

				function Content_:Change(Key)
					if Key.EnumType then
						if Key.EnumType == Enum.KeyCode or Key.EnumType == Enum.UserInputType then
							if table.find(Keys.KeyCodes, Key.Name) or table.find(Keys.Inputs, Key.Name) then
								local KeyType = Key.EnumType == Enum.KeyCode and "KeyCode" or "UserInputType"
								if Content_:Get()[1] == KeyType and Content_:Get()[2] == Key.Name then
									Content_:Set({})
								else
									Content_:Set({KeyType, Key.Name})
								end
								Content_.KeyChangeCallback(Content_:Get())
								return true
							end
						end
					end
				end

				function Content_:OpenModeMenu()
					Content_.Section:CloseContent()

					local Open = {}
					local Connections = {}
					local InputCheck

					local Modes = {"Toggle", "Hold"}

					local Content_Open_Holder = utility:RenderObject("Frame", {
						BackgroundColor3 = Color3.fromRGB(0, 0, 0),
						BackgroundTransparency = 1,
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						Parent = Content_.Section.Extra,
						Position = UDim2.new(0, Content_Holder_Value.AbsolutePosition.X - Content_.Section.Extra.AbsolutePosition.X + Content_Holder_Value.AbsoluteSize.X + 5, 0, Content_Holder.AbsolutePosition.Y - Content_.Section.Extra.AbsolutePosition.Y),
						Size = UDim2.new(0, 50, 0, (14 * #Modes) + 2),
						ZIndex = 6
					})

					local Open_Holder_Outline = utility:RenderObject("Frame", {
						BackgroundColor3 = Color3.fromRGB(40, 40, 40),
						BackgroundTransparency = 0,
						BorderColor3 = Color3.fromRGB(12, 12, 12),
						BorderMode = "Inset",
						BorderSizePixel = 1,
						Parent = Content_Open_Holder,
						Position = UDim2.new(0, 0, 0, 0),
						Size = UDim2.new(1, 0, 1, 0),
						ZIndex = 6
					})

					local Open_Holder_Outline_Frame = utility:RenderObject("Frame", {
						BackgroundColor3 = Color3.fromRGB(23, 23, 23),
						BackgroundTransparency = 0,
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						Parent = Open_Holder_Outline,
						Position = UDim2.new(0, 1, 0, 1),
						Size = UDim2.new(1, -2, 1, -2),
						ZIndex = 6
					})

					for Index, Mode in pairs(Modes) do
						local Outline_Frame_Option = utility:RenderObject("Frame", {
							BackgroundColor3 = Color3.fromRGB(23, 23, 23),
							BackgroundTransparency = 0,
							BorderColor3 = Color3.fromRGB(0, 0, 0),
							BorderSizePixel = 0,
							Parent = Open_Holder_Outline_Frame,
							Position = UDim2.new(0, 0, 0, 14 * (Index - 1)),
							Size = UDim2.new(1, 0, 1 / #Modes, 0),
							ZIndex = 6
						})

						local Frame_Option_Title = utility:RenderObject("TextLabel", {
							BackgroundColor3 = Color3.fromRGB(0, 0, 0),
							BackgroundTransparency = 1,
							BorderColor3 = Color3.fromRGB(0, 0, 0),
							BorderSizePixel = 0,
							Parent = Outline_Frame_Option,
							Position = UDim2.new(0, 8, 0, 0),
							Size = UDim2.new(1, 0, 1, 0),
							ZIndex = 6,
							Font = "Code",
							RichText = true,
							Text = Mode,
							TextColor3 = Mode == Content_.Mode and Content_.Window.Accent or Color3.fromRGB(205, 205, 205),
							TextSize = 9,
							TextStrokeTransparency = 1,
							TextXAlignment = "Left"
						})

						local Frame_Option_Title2 = utility:RenderObject("TextLabel", {
							BackgroundColor3 = Color3.fromRGB(0, 0, 0),
							BackgroundTransparency = 1,
							BorderColor3 = Color3.fromRGB(0, 0, 0),
							BorderSizePixel = 0,
							Parent = Outline_Frame_Option,
							Position = UDim2.new(0, 8, 0, 0),
							Size = UDim2.new(1, 0, 1, 0),
							ZIndex = 6,
							Font = "Code",
							RichText = true,
							Text = Mode,
							TextColor3 = Mode == Content_.Mode and Content_.Window.Accent or Color3.fromRGB(205, 205, 205),
							TextSize = 9,
							TextStrokeTransparency = 1,
							TextTransparency = 0.5,
							TextXAlignment = "Left"
						})

						local Frame_Option_Button = utility:RenderObject("TextButton", {
							BackgroundColor3 = Color3.fromRGB(0, 0, 0),
							BackgroundTransparency = 1,
							BorderColor3 = Color3.fromRGB(0, 0, 0),
							BorderSizePixel = 0,
							Parent = Outline_Frame_Option,
							Size = UDim2.new(1, 0, 1, 0),
							Text = "",
							ZIndex = 6
						})

						do
							local Clicked = utility:CreateConnection(Frame_Option_Button.MouseButton1Click, function(Input)
								Content_.Mode = Mode
								Content_.Active = false
								Content_.Content:Refresh()
							end)

							local Entered = utility:CreateConnection(Frame_Option_Button.MouseEnter, function(Input)
								Outline_Frame_Option.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
							end)

							local Left = utility:CreateConnection(Frame_Option_Button.MouseLeave, function(Input)
								Outline_Frame_Option.BackgroundColor3 = Color3.fromRGB(23, 23, 23)
							end)

							Connections[#Connections + 1] = Clicked
							Connections[#Connections + 1] = Entered
							Connections[#Connections + 1] = Left
						end

						Open[#Open + 1] = {Mode, Frame_Option_Title, Frame_Option_Title2, Outline_Frame_Option, Frame_Option_Button}
					end

					do
						function Content_.Content:Close()
							Content_.Content.Open = false

							for Index, Value in pairs(Connections) do
								Value:Disconnect()
							end

							if InputCheck then
								InputCheck:Disconnect()
							end

							for Index, Value in pairs(Open) do
								Value[2]:Remove()
								Value[3]:Remove()
								Value[4]:Remove()
								Value[5]:Remove()
							end

							Content_Open_Holder:Remove()
							Open_Holder_Outline:Remove()
							Open_Holder_Outline_Frame:Remove()

							function Content_.Content:Refresh() end

							InputCheck = nil
							Connections = nil
							Open = nil
						end

						function Content_.Content:Refresh()
							for Index, Value in pairs(Open) do
								Value[2].TextColor3 = Value[1] == Content_.Mode and Content_.Window.Accent or Color3.fromRGB(205, 205, 205)
								Value[3].TextColor3 = Value[1] == Content_.Mode and Content_.Window.Accent or Color3.fromRGB(205, 205, 205)
							end
						end
					end

					Content_.Content.Open = true
					Content_.Section.Content = Content_.Content

					do
						task.wait()

						InputCheck = utility:CreateConnection(UserInputService.InputBegan, function(Input)
							if Content_.Content.Open and Input.UserInputType == Enum.UserInputType.MouseButton1 then
								local Mouse = utility:MouseLocation()

								if not (Mouse.X >= Content_Open_Holder.AbsolutePosition.X and Mouse.Y >= (Content_Open_Holder.AbsolutePosition.Y + 36 + (36/2)) and Mouse.X <= (Content_Open_Holder.AbsolutePosition.X + Content_Open_Holder.AbsoluteSize.X) and Mouse.Y <= (Content_Open_Holder.AbsolutePosition.Y + Content_Open_Holder.AbsoluteSize.Y + 36 + (36/2))) then
									Content_.Section:CloseContent()
								end
							end
						end)
					end
				end
			end

			do
				utility:CreateConnection(Content_Holder_Button.MouseButton1Click, function(Input)
					Content_.Holding = true
					Content_Holder_Value.TextColor3 = Color3.fromRGB(255, 0, 0)
				end)

				utility:CreateConnection(Content_Holder_Button.MouseButton2Click, function(Input)
					if Content_.Content.Open then
						Content_.Section:CloseContent()
					else
						Content_:OpenModeMenu()
					end
				end)

				utility:CreateConnection(Content_Holder_Button.MouseEnter, function(Input)
					Content_Holder_Value.TextColor3 = Color3.fromRGB(164, 164, 164)
				end)

				utility:CreateConnection(Content_Holder_Button.MouseLeave, function(Input)
					Content_Holder_Value.TextColor3 = Content_.Holding and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(114, 114, 114)
				end)

				utility:CreateConnection(UserInputService.InputBegan, function(Input)
					if Content_.Holding then
						local Success = Content_:Change(Input.KeyCode.Name ~= "Unknown" and Input.KeyCode or Input.UserInputType)
						if Success then
							Content_.Holding = false
							Content_Holder_Value.TextColor3 = Color3.fromRGB(114, 114, 114)
						end
					end

					if Content_:Get()[1] and Content_:Get()[2] then
						if Input.KeyCode == Enum[Content_:Get()[1]][Content_:Get()[2]] or Input.UserInputType == Enum[Content_:Get()[1]][Content_:Get()[2]] then
							if Content_.Mode == "Hold" then
								Content_.Active = true
								Content_.HeldCallback(Content_.Active)

								if library.KeybindList then
									library.KeybindList:Update(FlagName, Content_.Name, Content_:Shorten(Content_:Get()[2]), true)
								end
							elseif Content_.Mode == "Toggle" then
								Content_.Active = not Content_.Active
								Content_.Callback(Content_.Active)

								if library.KeybindList then
									library.KeybindList:Update(FlagName, Content_.Name, Content_:Shorten(Content_:Get()[2]), Content_.Active)
								end
							end
						end
					end
				end)

				utility:CreateConnection(UserInputService.InputEnded, function(Input)
					if Content_:Get()[1] and Content_:Get()[2] then
						if Input.KeyCode == Enum[Content_:Get()[1]][Content_:Get()[2]] or Input.UserInputType == Enum[Content_:Get()[1]][Content_:Get()[2]] then
							if Content_.Mode == "Hold" then
								Content_.Active = false
								Content_.HeldCallback(Content_.Active)

								if library.KeybindList then
									library.KeybindList:Update(FlagName, Content_.Name, Content_:Shorten(Content_:Get()[2]), false)
								end
							end
						end
					end
				end)
			end

			Content_:Set(Content_.State)
		end

		return Content_
	end

	--//ColorPicker
	function sections:CreateColorpicker(FlagName,Properties)
		Properties = Properties or {}
		--
		local Content_ = {
			Name = (Properties.name or Properties.Name or Properties.title or Properties.Title or "New Colorpicker"),
			State = (Properties.state or Properties.State or Properties.def or Properties.Def or Properties.default or Properties.Default or Color3.fromRGB(255, 255, 255)),
			Transparency = (Properties.transparency or Properties.Transparency or 0),
			Callback = (Properties.callback or Properties.Callback or Properties.callBack or Properties.CallBack or function() end),
			Hue = 0,
			Sat = 0,
			Val = 1,
			Content = {
				Open = false
			},
			Window = self.Window,
			Page = self.Page,
			Section = self
		}
		createdObjects.colorpickers[FlagName] = Content_
		--
		do
			local Content_Holder = utility:RenderObject("Frame", {
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Parent = Content_.Section.Holder,
				Size = UDim2.new(1, 0, 0, 8 + 10),
				ZIndex = 3
			})
			-- //
			local Content_Holder_Outline = utility:RenderObject("Frame", {
				BackgroundColor3 = Color3.fromRGB(12, 12, 12),
				BackgroundTransparency = 0,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Parent = Content_Holder,
				Position = UDim2.new(1, -38, 0, 4),
				Size = UDim2.new(0, 17, 0, 9),
				ZIndex = 3
			})
			--
			local Content_Holder_Title = utility:RenderObject("TextLabel", {
				AnchorPoint = Vector2.new(0, 0),
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Parent = Content_Holder,
				Position = UDim2.new(0, 41, 0, 0),
				Size = UDim2.new(1, -41, 1, 0),
				ZIndex = 3,
				Font = "Code",
				RichText = true,
				Text = Content_.Name,
				TextColor3 = Color3.fromRGB(205, 205, 205),
				TextSize = 9,
				TextStrokeTransparency = 1,
				TextXAlignment = "Left"
			})
			--
			local Content_Holder_Title2 = utility:RenderObject("TextLabel", {
				AnchorPoint = Vector2.new(0, 0),
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Parent = Content_Holder,
				Position = UDim2.new(0, 41, 0, 0),
				Size = UDim2.new(1, -41, 1, 0),
				ZIndex = 3,
				Font = "Code",
				RichText = true,
				Text = Content_.Name,
				TextColor3 = Color3.fromRGB(205, 205, 205),
				TextSize = 9,
				TextStrokeTransparency = 1,
				TextTransparency = 0.5,
				TextXAlignment = "Left"
			})
			--
			local Content_Holder_Button = utility:RenderObject("TextButton", {
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Parent = Content_Holder,
				Size = UDim2.new(1, 0, 1, 0),
				Text = ""
			})
			-- //
			local Holder_Outline_Frame = utility:RenderObject("Frame", {
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 0,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Parent = Content_Holder_Outline,
				Position = UDim2.new(0, 1, 0, 1),
				Size = UDim2.new(1, -2, 1, -2),
				ZIndex = 3
			})
			-- //
			local Outline_Frame_Gradient = utility:RenderObject("UIGradient", {
				Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(140, 140, 140)),
				Enabled = true,
				Rotation = 90,
				Parent = Holder_Outline_Frame
			})
			--
			do -- // Functions
				function Content_:SetHSVFromRGB(Color)
					local H, S, V = Color3.toHSV(Color)
					Content_.Hue = H
					Content_.Sat = S
					Content_.Val = V

					Content_.State = Color3.fromHSV(H, S, V)
				end


				Content_:SetHSVFromRGB(Content_.State)

				function Content_:Set(state, transparency)
					Content_.State = state
					if transparency then
						Content_.Transparency = transparency
					end
					--
					Content_:SetHSVFromRGB(Content_.State)
					Holder_Outline_Frame.BackgroundColor3 = Content_.State
					--
					Content_.Callback(Content_:Get(), Content_.Transparency or 0)
				end
				--
				function Content_:Get()
					return Content_.State
				end
				--
				function Content_:Open()
					Content_.Section:CloseContent()
					--
					local Connections = {}
					local InputCheck
					local Dragging = {Sat = false, Hue = false, Alpha = false}
					--
					local Content_Open_Holder = utility:RenderObject("Frame", {
						BackgroundColor3 = Color3.fromRGB(0, 0, 0),
						BackgroundTransparency = 1,
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						Parent = Content_.Section.Extra,
						Position = UDim2.new(0, Content_Holder_Outline.AbsolutePosition.X - Content_.Section.Extra.AbsolutePosition.X, 0, Content_Holder_Outline.AbsolutePosition.Y - Content_.Section.Extra.AbsolutePosition.Y + 12),
						Size = UDim2.new(0, 180, 0, 192),
						ZIndex = 6
					})
					--
					local Open_Holder_Outline = utility:RenderObject("Frame", {
						BackgroundColor3 = Color3.fromRGB(60, 60, 60),
						BackgroundTransparency = 0,
						BorderColor3 = Color3.fromRGB(12, 12, 12),
						BorderMode = "Inset",
						BorderSizePixel = 1,
						Parent = Content_Open_Holder,
						Size = UDim2.new(1, 0, 1, 0),
						ZIndex = 6
					})
					--
					local Open_Outline_Frame = utility:RenderObject("Frame", {
						BackgroundColor3 = Color3.fromRGB(40, 40, 40),
						BackgroundTransparency = 0,
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						Parent = Open_Holder_Outline,
						Position = UDim2.new(0, 1, 0, 1),
						Size = UDim2.new(1, -2, 1, -2),
						ZIndex = 6
					})
					-- Saturation/Value Picker
					local ValSat_Picker_Outline = utility:RenderObject("Frame", {
						BackgroundColor3 = Color3.fromRGB(12, 12, 12),
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						Parent = Open_Outline_Frame,
						Position = UDim2.new(0, 4, 0, 4),
						Size = UDim2.new(0, 156, 0, 156),
						ZIndex = 6
					})
					local ValSat_Picker_Color = utility:RenderObject("Frame", {
						BackgroundColor3 = Color3.fromRGB(255, 0, 0),
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						Parent = ValSat_Picker_Outline,
						Position = UDim2.new(0, 1, 0, 1),
						Size = UDim2.new(1, -2, 1, -2),
						ZIndex = 6
					})
					local ValSat_Picker_Dark = utility:RenderObject("ImageLabel", {
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						Image = utility:GetAsset("SatPicker.png"), 
						Parent = ValSat_Picker_Color,
						Size = UDim2.new(1, 0, 1, 0),
						ZIndex = 7
					})
					local ValSat_Cursor = utility:RenderObject("Frame", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						Parent = ValSat_Picker_Dark,
						Position = UDim2.new(Content_.Sat, 0, 1 - Content_.Val, 0),
						Size = UDim2.new(0, 4, 0, 4),
						ZIndex = 8
					})
					-- Hue Picker
					local Hue_Picker_Outline = utility:RenderObject("Frame", {
						BackgroundColor3 = Color3.fromRGB(12, 12, 12),
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						Parent = Open_Outline_Frame,
						Position = UDim2.new(1, -16, 0, 4),
						Size = UDim2.new(0, 12, 0, 156),
						ZIndex = 6
					})
					local Hue_Picker_Color = utility:RenderObject("Frame", {
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						Parent = Hue_Picker_Outline,
						Position = UDim2.new(0, 1, 0, 1),
						Size = UDim2.new(1, -2, 1, -2),
						ZIndex = 6
					})
					local SequenceTable = {}
					for Hue = 0, 1, 0.1 do
						table.insert(SequenceTable, ColorSequenceKeypoint.new(Hue, Color3.fromHSV(Hue, 1, 1)))
					end
					local Hue_Gradient = utility:RenderObject("UIGradient", {
						Color = ColorSequence.new(SequenceTable),
						Rotation = 90,
						Parent = Hue_Picker_Color
					})
					local Hue_Cursor = utility:RenderObject("Frame", {
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						Parent = Hue_Picker_Color,
						Position = UDim2.new(0, 0, Content_.Hue, 0),
						Size = UDim2.new(1, 0, 0, 1),
						ZIndex = 7
					})
					-- Transparency Picker
					local Alpha_Picker_Outline = utility:RenderObject("Frame", {
						BackgroundColor3 = Color3.fromRGB(12, 12, 12),
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						Parent = Open_Outline_Frame,
						Position = UDim2.new(0, 4, 0, 164),
						Size = UDim2.new(0, 156, 0, 16),
						ZIndex = 6
					})

					local Alpha_Picker_BG = utility:RenderObject("ImageLabel", {
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						Image = utility:GetAsset("AlphaPicker.png"),
						Parent = Alpha_Picker_Outline,
						Position = UDim2.new(0, 1, 0, 1),
						Size = UDim2.new(1, -2, 1, -2),
						ZIndex = 6
					})
					local Alpha_Picker_Color = utility:RenderObject("Frame", {
						BackgroundColor3 = Content_.State,
						BackgroundTransparency = 0,
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						Parent = Alpha_Picker_BG,
						Size = UDim2.new(1, 0, 1, 0),
						ZIndex = 7
					})
					local Alpha_Cursor = utility:RenderObject("Frame", {
						AnchorPoint = Vector2.new(0.5, 0),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						Parent = Alpha_Picker_Color,
						Position = UDim2.new(1 - Content_.Transparency, 0, 0, 0),
						Size = UDim2.new(0, 1, 1, 0),
						ZIndex = 8
					})
					--
					local function UpdateDisplay()
						Content_.State = Color3.fromHSV(Content_.Hue, Content_.Sat, Content_.Val)
						ValSat_Picker_Color.BackgroundColor3 = Color3.fromHSV(Content_.Hue, 1, 1)
						ValSat_Cursor.Position = UDim2.new(Content_.Sat, 0, 1 - Content_.Val, 0)
						Hue_Cursor.Position = UDim2.new(0, 0, Content_.Hue, 0)
						Alpha_Picker_Color.BackgroundColor3 = Content_.State
						Alpha_Picker_Color.BackgroundTransparency = Content_.Transparency
						Alpha_Cursor.Position = UDim2.new(1 - Content_.Transparency, 0, 0, 0)
						Holder_Outline_Frame.BackgroundColor3 = Content_.State

						Content_.Callback(Content_.State, Content_.Transparency)
					end

					do -- // Connections
						local SatDrag = utility:CreateConnection(ValSat_Picker_Dark.InputBegan, function(Input)
							if Input.UserInputType == Enum.UserInputType.MouseButton1 then
								library.OnColorPicker = true
								Dragging.Sat = true
							end
						end)

						local HueDrag = utility:CreateConnection(Hue_Picker_Color.InputBegan, function(Input)
							if Input.UserInputType == Enum.UserInputType.MouseButton1 then
								library.OnColorPicker = true
								Dragging.Hue = true
							end
						end)

						local AlphaDrag = utility:CreateConnection(Alpha_Picker_Color.InputBegan, function(Input)
							if Input.UserInputType == Enum.UserInputType.MouseButton1 then
								library.OnColorPicker = true
								Dragging.Alpha = true
							end
						end)

						local InsetY = GuiService:GetGuiInset().Y

						local RenderStep = RunService.RenderStepped:Connect(function()
							if not (Dragging.Sat or Dragging.Hue or Dragging.Alpha) then return end
							local Mouse = utility:MouseLocation()

							if Dragging.Sat then
								local MinX = ValSat_Picker_Dark.AbsolutePosition.X
								local MaxX = MinX + ValSat_Picker_Dark.AbsoluteSize.X
								local MinY = ValSat_Picker_Dark.AbsolutePosition.Y
								local MaxY = MinY + ValSat_Picker_Dark.AbsoluteSize.Y
								Content_.Sat = (math.clamp(Mouse.X, MinX, MaxX) - MinX) / (MaxX - MinX)
								Content_.Val = 1 - ((math.clamp(Mouse.Y - InsetY, MinY, MaxY) - MinY) / (MaxY - MinY))
							end

							if Dragging.Hue then
								local MinY = Hue_Picker_Color.AbsolutePosition.Y
								local MaxY = MinY + Hue_Picker_Color.AbsoluteSize.Y
								Content_.Hue = (math.clamp(Mouse.Y - InsetY, MinY, MaxY) - MinY) / (MaxY - MinY)
							end

							if Dragging.Alpha then
								local MinX = Alpha_Picker_Color.AbsolutePosition.X
								local MaxX = MinX + Alpha_Picker_Color.AbsoluteSize.X
								Content_.Transparency = 1 - ((math.clamp(Mouse.X, MinX, MaxX) - MinX) / (MaxX - MinX))
							end

							UpdateDisplay()
						end)

						local DragEnd = utility:CreateConnection(UserInputService.InputEnded, function(Input)
							if Input.UserInputType == Enum.UserInputType.MouseButton1 then
								library.OnColorPicker = false
								Dragging.Sat = false
								Dragging.Hue = false
								Dragging.Alpha = false
							end
						end)

						Connections[#Connections + 1] = SatDrag
						Connections[#Connections + 1] = HueDrag
						Connections[#Connections + 1] = AlphaDrag
						Connections[#Connections + 1] = DragEnd
						Connections[#Connections + 1] = RenderStep 
					end
					--
					do -- // Functions
						function Content_.Content:Close()
							Content_.Content.Open = false
							for Index, Value in pairs(Connections) do
								Value:Disconnect()
							end
							if InputCheck then
								InputCheck:Disconnect()
							end
							Content_Open_Holder:Remove()
							function Content_.Content:Refresh() end
							InputCheck = nil
							Connections = nil
						end
						function Content_.Content:Refresh() end
					end
					--
					Content_.Content.Open = true
					Content_.Section.Content = Content_.Content
					UpdateDisplay()
					--
					task.wait()
					InputCheck = utility:CreateConnection(UserInputService.InputBegan, function(Input)
						if Content_.Content.Open and Input.UserInputType == Enum.UserInputType.MouseButton1 then
							local Mouse = utility:MouseLocation()
							if not (Mouse.X >= Content_Open_Holder.AbsolutePosition.X and Mouse.Y >= (Content_Open_Holder.AbsolutePosition.Y + 36 + (36/2)) and Mouse.X <= (Content_Open_Holder.AbsolutePosition.X + Content_Open_Holder.AbsoluteSize.X) and Mouse.Y <= (Content_Open_Holder.AbsolutePosition.Y + Content_Open_Holder.AbsoluteSize.Y + 36 + (36/2))) then
								if not (Mouse.X >= Content_Holder.AbsolutePosition.X and Mouse.Y >= Content_Holder.AbsolutePosition.Y and Mouse.X <= (Content_Holder.AbsolutePosition.X + Content_Holder.AbsoluteSize.X) and Mouse.Y <= (Content_Holder.AbsolutePosition.Y + Content_Holder.AbsoluteSize.Y)) then
									Content_.Section:CloseContent()
								end
							end
						end
					end)
				end
			end
			--
			do -- // Connections
				utility:CreateConnection(Content_Holder_Button.MouseButton1Click, function(Input)
					if Content_.Content.Open then
						Content_.Section:CloseContent()
					else
						Content_:Open()
					end
				end)
				--
				utility:CreateConnection(Content_Holder_Button.MouseEnter, function(Input)
					Outline_Frame_Gradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(180, 180, 180))
				end)
				--
				utility:CreateConnection(Content_Holder_Button.MouseLeave, function(Input)
					Outline_Frame_Gradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(140, 140, 140))
				end)
			end
			--
			Content_:Set(Content_.State)
		end
		--
		return Content_
	end

	--//Button
	function sections:CreateButton(Properties)
		Properties = Properties or {}
		--
		local Content_ = {
			Name = (Properties.name or Properties.Name or Properties.title or Properties.Title or Properties.text or Properties.Text or "New Button"),
			Callback = (Properties.callback or Properties.Callback or Properties.callBack or Properties.CallBack or function() end),
			Window = self.Window,
			Page = self.Page,
			Section = self
		}
		--
		do
			local Content_Holder = utility:RenderObject("Frame", {
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Parent = Content_.Section.Holder,
				Size = UDim2.new(1, 0, 0, 25 + 5),
				ZIndex = 3
			})
			--
			local Content_Holder_Outline = utility:RenderObject("Frame", {
				BackgroundColor3 = Color3.fromRGB(12, 12, 12),
				BackgroundTransparency = 0,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Parent = Content_Holder,
				Position = UDim2.new(0, 40, 0, 15),
				Size = UDim2.new(1, -98, 0, 20),
				ZIndex = 3
			})
			--
			local Content_Holder_Button = utility:RenderObject("TextButton", {
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Parent = Content_Holder,
				Size = UDim2.new(1, 0, 1, 0),
				Text = ""
			})
			--
			local Holder_Outline_Frame = utility:RenderObject("Frame", {
				BackgroundColor3 = Color3.fromRGB(36, 36, 36),
				BackgroundTransparency = 0,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Parent = Content_Holder_Outline,
				Position = UDim2.new(0, 1, 0, 1),
				Size = UDim2.new(1, -2, 1, -2),
				ZIndex = 3
			})
			--
			local Outline_Frame_Gradient = utility:RenderObject("UIGradient", {
				Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(220, 220, 220)),
				Enabled = true,
				Rotation = 270,
				Parent = Holder_Outline_Frame
			})
			--
			local Outline_Frame_Title = utility:RenderObject("TextLabel", {
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Parent = Holder_Outline_Frame,
				Size = UDim2.new(1, 0, 1, 0),
				ZIndex = 3,
				Font = "Code",
				RichText = true,
				Text = Content_.Name,
				TextColor3 = Color3.fromRGB(155, 155, 155),
				TextSize = 9,
				TextStrokeTransparency = 1,
				TextXAlignment = "Center"
			})
			--
			local Outline_Frame_Title2 = utility:RenderObject("TextLabel", {
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Parent = Holder_Outline_Frame,
				Size = UDim2.new(1, 0, 1, 0),
				ZIndex = 3,
				Font = "Code",
				RichText = true,
				Text = Content_.Name,
				TextColor3 = Color3.fromRGB(155, 155, 155),
				TextSize = 9,
				TextStrokeTransparency = 1,
				TextTransparency = 0.5,
				TextXAlignment = "Center"
			})
			--
			do -- // Connections
				utility:CreateConnection(Content_Holder_Button.MouseButton1Click, function(Input)
					Content_.Callback()
				end)
				--
				utility:CreateConnection(Content_Holder_Button.MouseEnter, function(Input)
					Holder_Outline_Frame.BackgroundColor3 = Color3.fromRGB(46, 46, 46)
				end)
				--
				utility:CreateConnection(Content_Holder_Button.MouseLeave, function(Input)
					Holder_Outline_Frame.BackgroundColor3 = Color3.fromRGB(36, 36, 36)
				end)
			end
		end
		--
		return Content_
	end

	--//TextBox
	function sections:CreateTextbox(Properties)
		Properties = Properties or {}

		local Content_ = {
			Name = (Properties.name or Properties.Name or Properties.title or Properties.Title or Properties.placeholder or Properties.Placeholder or "Enter text..."),
			Default = (Properties.default or Properties.Default or ""),
			Callback = (Properties.callback or Properties.Callback or function() end),

			Window = self.Window,
			Page = self.Page,
			Section = self
		}

		do
			local Content_Holder = utility:RenderObject("Frame", {
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Parent = Content_.Section.Holder,
				Size = UDim2.new(1, 0, 0, 25 + 5),
				ZIndex = 3
			})

			local Content_Holder_Outline = utility:RenderObject("Frame", {
				BackgroundColor3 = Color3.fromRGB(12, 12, 12),
				BorderSizePixel = 0,
				Parent = Content_Holder,
				Position = UDim2.new(0, 40, 0, 15),
				Size = UDim2.new(1, -98, 0, 20),
				ZIndex = 3
			})

			local Holder_Outline_Frame = utility:RenderObject("Frame", {
				BackgroundColor3 = Color3.fromRGB(36, 36, 36),
				BorderSizePixel = 0,
				Parent = Content_Holder_Outline,
				Position = UDim2.new(0, 1, 0, 1),
				Size = UDim2.new(1, -2, 1, -2),
				ZIndex = 3
			})

			local Outline_Frame_Gradient = utility:RenderObject("UIGradient", {
				Color = ColorSequence.new(
					Color3.fromRGB(255, 255, 255),
					Color3.fromRGB(220, 220, 220)
				),
				Rotation = 270,
				Parent = Holder_Outline_Frame
			})

			local TextBox = utility:RenderObject("TextBox", {
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Parent = Holder_Outline_Frame,
				Size = UDim2.new(1, -6, 1, 0),
				Position = UDim2.new(0, 3, 0, 0),
				ZIndex = 4,
				Font = "Code",
				Text = Content_.Default,
				PlaceholderText = Content_.Name,
				TextColor3 = Color3.fromRGB(155, 155, 155),
				TextSize = 9,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
				TextStrokeTransparency = 1,
				ClearTextOnFocus = false
			})

			-- interactions
			utility:CreateConnection(TextBox.Focused, function()
				Holder_Outline_Frame.BackgroundColor3 = Color3.fromRGB(46, 46, 46)
			end)

			utility:CreateConnection(TextBox.FocusLost, function()
				Holder_Outline_Frame.BackgroundColor3 = Color3.fromRGB(36, 36, 36)
				Content_.Callback(TextBox.Text)
			end)

			Content_.TextBox = TextBox
		end

		return Content_
	end

	--//Scrollframe
	function sections:CreateScrollFrame(Properties)
		Properties = Properties or {}

		local Content_ = {
			Size = (Properties.size or Properties.Size or 120),
			Items = {},
			SelectedIndex = nil,

			Window = self.Window,
			Page = self.Page,
			Section = self
		}

		do
			local Content_Holder = utility:RenderObject("Frame", {
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Parent = Content_.Section.Holder,
				Size = UDim2.new(1, 0, 0, Content_.Size + 10),
				ZIndex = 3
			})

			local Content_Holder_Outline = utility:RenderObject("Frame", {
				BackgroundColor3 = Color3.fromRGB(12, 12, 12),
				BorderSizePixel = 0,
				Parent = Content_Holder,
				Position = UDim2.new(0, 40, 0, 5),
				Size = UDim2.new(1, -98, 1, -10),
				ZIndex = 3
			})

			local Holder_Outline_Frame = utility:RenderObject("Frame", {
				BackgroundColor3 = Color3.fromRGB(36, 36, 36), 
				BackgroundTransparency = 0,
				BorderSizePixel = 0,
				Parent = Content_Holder_Outline,
				Position = UDim2.new(0, 1, 0, 1),
				Size = UDim2.new(1, -2, 1, -2),
				ZIndex = 3
			})

			utility:RenderObject("UIGradient", {
				Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(220, 220, 220)),
				Rotation = 270,
				Parent = Holder_Outline_Frame
			})

			local Scroll = utility:RenderObject("ScrollingFrame", {
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 0.999, 
				BorderSizePixel = 0,
				Parent = Holder_Outline_Frame,
				Position = UDim2.new(0, 4, 0, 4),
				Size = UDim2.new(1, -8, 1, -8),
				ZIndex = 4,
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				CanvasSize = UDim2.new(0, 0, 0, 0),
				ScrollBarImageColor3 = Color3.fromRGB(65, 65, 65),
				ScrollBarThickness = 4,
				VerticalScrollBarInset = Enum.ScrollBarInset.None,
				TopImage = utility:GetAsset("ScrollBar.png"),
				MidImage = utility:GetAsset("ScrollBar.png"),
				BottomImage = utility:GetAsset("ScrollBar.png")
			})

			local List = utility:RenderObject("UIListLayout", {
				Parent = Scroll,
				Padding = UDim.new(0, 2),
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
				VerticalAlignment = Enum.VerticalAlignment.Top
			})

			utility:RenderObject("UIPadding", {
				Parent = Scroll,
				PaddingTop = UDim.new(0, 2),
				PaddingBottom = UDim.new(0, 2)
			})

			Content_.Holder = Scroll

			local NORMAL = Color3.fromRGB(155, 155, 155)
			local SELECTED = Content_.Window.Accent or Color3.fromRGB(120, 255, 120)

			local function SetSelected(index)
				if Content_.SelectedIndex == index then return end

				if Content_.SelectedIndex then
					local old = Content_.Items[Content_.SelectedIndex]
					if old then
						old.TextColor3 = NORMAL
					end
				end

				Content_.SelectedIndex = index
				local new = Content_.Items[index]
				if new then
					new.TextColor3 = SELECTED
				end
			end

			function Content_:AddIndex(Text)
				local index = #Content_.Items + 1

				local Button = utility:RenderObject("TextButton", {
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Parent = Scroll,
					Size = UDim2.new(1, 0, 0, 14),
					ZIndex = 5,

					Font = "Code",
					Text = tostring(Text),
					TextSize = 9,
					TextColor3 = NORMAL,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextStrokeTransparency = 1
				})

				utility:CreateConnection(Button.MouseButton1Click, function()
					SetSelected(index)
				end)

				table.insert(Content_.Items, Button)
				return Button
			end

			function Content_:RemoveIndex(Index)
				local i

				if typeof(Index) == "number" then
					i = Index
				else
					for idx, Item in ipairs(Content_.Items) do
						if Item.Text == Index then
							i = idx
							break
						end
					end
				end

				if not i then return end

				Content_.Items[i]:Destroy()
				table.remove(Content_.Items, i)

				if Content_.SelectedIndex == i then
					Content_.SelectedIndex = nil
				elseif Content_.SelectedIndex and Content_.SelectedIndex > i then
					Content_.SelectedIndex -= 1
				end
			end

			function Content_:Clear()
				for _, Item in ipairs(Content_.Items) do
					Item:Destroy()
				end
				table.clear(Content_.Items)
				Content_.SelectedIndex = nil
			end

			function Content_:GetSelectedIndex()
				if not Content_.SelectedIndex then return nil end
				local Item = Content_.Items[Content_.SelectedIndex]
				return Content_.SelectedIndex, Item and Item.Text
			end
		end

		return Content_
	end
end

do	--// Preload assets
	local StatusText = Drawing.new("Text")
	StatusText.Position = Camera.ViewportSize / 2
	StatusText.Center = true
	StatusText.Outline = true
	StatusText.Visible = true
	StatusText.Size = 25

	for a,b in pairs(assetFiles) do
		StatusText.Text = "Downloading asset: "..b
		local call = utility:GetAsset(b)
	end

	StatusText:Remove()
end

return library