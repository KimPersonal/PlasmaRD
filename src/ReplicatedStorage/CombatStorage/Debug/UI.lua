local Tags = require(script.Parent.Tags)

local client = game:GetService("Players").LocalPlayer
local toggleBoxGrid = script.ToggleBoxGrid
local textList = script.TextList

local ToggleBox = {}
ToggleBox.name = "VOID"

function ToggleBox.new(name)
	local self = setmetatable({}, {__index = ToggleBox})
	self.name = name
	self.state = true
	self._event = Instance.new("BindableEvent")
	self.onToggle = self._event.Event
	
	self._uiFrame = script.ToggleBoxTemplate:Clone()
	self._uiFrame.Name = self.name
	self._uiFrame.TextLabel.Text = self.name
	self._uiFrame.Parent = toggleBoxGrid.Container
	toggleBoxGrid.Parent = client.PlayerGui
	
	self._uiFrame.ImageButton.MouseButton1Click:Connect(function()
		self.state = not self.state
		self._uiFrame.ImageButton.ImageTransparency = self.state and 0 or 1
		self._event:Fire(self.state)
	end)
	return self
end

local UI = {}
UI.toggleBox = ToggleBox
UI._list = {}
UI._toggles = {}

function UI.makeTagToggle(tag)
	if not UI._toggles[tag] then
		local box = ToggleBox.new(tag)
		box.onToggle:Connect(function(enabled)
			Tags.set(tag, enabled)
			UI.setTagItemsVisible(tag, enabled)
		end)
		UI._toggles[tag] = box
	end
end

function UI.setTagItemsVisible(tag, visible)
	for _, item in pairs(UI._list) do
		if item.tag == tag then
			item.label.Visible = visible
		end
	end
end

function UI.addListItem(name: string, startVal: any, tag: string)
	local label = script.ListItemTemplate:Clone()
	label.Name = name
	label.Text = name .. " : " .. tostring(startVal)
	label.Parent = textList.Container
	textList.Parent = client.PlayerGui
	
	local item = {label = label, value = startVal, tag = tag}
	UI._list[name] = item
	Tags.newTag(tag)
	UI.makeTagToggle(tag)
	
	return item
end

function UI.setListItem(name: string, newVal: any, newTag: string)
	local item = UI._list[name] or UI.addListItem(name, newVal, newTag)
	item.value = newVal
	item.tag = newTag or item.tag
	item.label.Text = name .. " : " .. tostring(item.value)
	item.label.Visible = Tags.get(item.tag)
end

function UI.incrementListItem(name, change)
	local item = UI._list[name]
	assert(item, "unknown debug item name")
	assert(typeof(item.value) == "number", "cannot increment non-number")
	item.value += change
	item.label.Text = name .. " : " .. tostring(item.value)
end

return UI