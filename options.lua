local _, ZT = ...;

--- @type StdUi
local StdUi = LibStub('StdUi');

local defaults = {
	showMine  = {
		INTERRUPT  = true,
		HARDCC     = true,
		STHARDCC   = true,
		SOFTCC     = true,
		STSOFTCC   = true,
		EXTERNAL   = true,
		HEALING    = true,
		DISPEL     = true,
		DEFMDISPEL = true,
		UTILITY    = true,
		PERSONAL   = true,
		IMMUNITY   = true,
		DAMAGE     = true,
		TANK       = true,
	},
	blacklist = {},

	debugEvents = false,
	debugMessages = false,
	debugTracking = false,
};

local spellValidator = function(self)
	local text = self:GetText();
	text = text:trim();
	local name, rank, icon, _, _, _, spellId = GetSpellInfo(text);

	if not name then
		StdUi:MarkAsValid(self, false);
		return false;
	end

	self:SetText(name);
	self.value = spellId;
	self.icon:SetTexture(icon);

	StdUi:MarkAsValid(self, true);
	return true;
end

StdUi:RegisterWidget('SpellBox', function(stdUi, parent, width, height)
	local editBox = stdUi:EditBox(parent, width, height, '', spellValidator);
	editBox:SetTextInsets(23, 3, 3, 3);

	local iconFrame = stdUi:Panel(editBox, 16, 16);
	stdUi:GlueLeft(iconFrame, editBox, 2, 0, true);

	local icon = stdUi:Texture(iconFrame, 16, 16, 134400);
	icon:SetAllPoints();

	editBox.icon = icon;

	iconFrame:SetScript('OnEnter', function ()
		if editBox.value then
			GameTooltip:SetOwner(editBox);
			GameTooltip:SetSpellByID(editBox.value)
			GameTooltip:Show();
		end
	end)

	iconFrame:SetScript('OnLeave', function ()
		if editBox.value then
			GameTooltip:Hide();
		end
	end)

	return editBox;
end);

StdUi:RegisterWidget('SpellInfo', function(stdUi, parent, width, height)
	local frame = stdUi:Panel(parent, width, height);

	local iconFrame = stdUi:Panel(frame, 16, 16);
	stdUi:GlueLeft(iconFrame, frame, 2, 0, true);

	local icon = stdUi:Texture(iconFrame, 16, 16);
	icon:SetAllPoints();

	local btn = stdUi:SquareButton(frame, 16, 16, 'DELETE');
	StdUi:GlueRight(btn, frame, -3, 0, true);

	local text = stdUi:Label(frame);
	text:SetPoint('LEFT', icon, 'RIGHT', 3, 0);
	text:SetPoint('RIGHT', btn, 'RIGHT', -3, 0);

	frame.removeBtn = btn;
	frame.icon = icon;
	frame.text = text;

	btn.parent = frame;

	iconFrame:SetScript('OnEnter', function()
		GameTooltip:SetOwner(frame);
		GameTooltip:SetSpellByID(frame.spellId);
		GameTooltip:Show();
	end)

	iconFrame:SetScript('OnLeave', function()
		GameTooltip:Hide();
	end)

	function frame:SetSpell(nameOrId)
		local name, rank, i, _, _, _, spellId = GetSpellInfo(nameOrId);
		self.spellId = spellId;
		self.spellName = name;

		self.icon:SetTexture(i);
		self.text:SetText(name);
	end

	return frame;
end);

StdUi:RegisterWidget('SpellCheckbox', function(stdUi, parent, width, height)
	local checkbox = stdUi:Checkbox(parent, '', width, height);
	checkbox.spellId = nil;
	checkbox.spellName = '';

	local iconFrame = stdUi:Panel(checkbox, 16, 16);
	iconFrame:SetPoint('LEFT', checkbox.target, 'RIGHT', 5, 0);

	local icon = stdUi:Texture(iconFrame, 16, 16);
	icon:SetAllPoints();

	checkbox.icon = icon;

	checkbox.text:SetPoint('LEFT', iconFrame, 'RIGHT', 5, 0);

	checkbox:SetScript('OnEnter', function()
		if checkbox.spellId then
			GameTooltip:SetOwner(checkbox);
			GameTooltip:SetSpellByID(checkbox.spellId);
			GameTooltip:Show();
		end
	end)

	checkbox:SetScript('OnLeave', function()
		GameTooltip:Hide();
	end)

	function checkbox:SetSpell(nameOrId)
		local name, rank, i, _, _, _, spellId = GetSpellInfo(nameOrId);
		self.spellId = spellId;
		self.spellName = name;

		self.icon:SetTexture(i);
		self.text:SetText(name);
	end

	return checkbox;
end);

local function update(parent, spellInfo, data)
	spellInfo:SetSpell(data);
	StdUi:SetObjSize(spellInfo, nil, 20);
	spellInfo:SetPoint('RIGHT');
	spellInfo:SetPoint('LEFT');

	if not spellInfo.removeBtn.hasOnClick then
		spellInfo.removeBtn:SetScript('OnClick', function(self)
			local spellId = self.parent.spellId;
			local spellList = parent:GetParent():GetParent();

			for k, v in pairs(spellList.data) do
				if v == spellId then
					tremove(spellList.data, k);
					break
				end
			end

			spellList:RefreshList();
		end);

		spellInfo.removeBtn.hasOnClick = true;
	end

	return spellInfo;
end

StdUi:RegisterWidget('SpellList', function(stdUi, parent, width, height, data)
	local spellList = StdUi:ScrollFrame(parent, 200, 400);
	spellList.frameList = {};
	spellList.data = data;

	function spellList:RefreshList()
		StdUi:ObjectList(spellList.scrollChild, self.frameList, 'SpellInfo', update, self.data);
	end

	spellList:RefreshList();

	return spellList;
end);

function ZT:BuildOptionsFrame()

end

function ZT:RegisterOptions()
	if not ZenTrackerDb or type(ZenTrackerDb) ~= 'table' then
		ZenTrackerDb = defaults;
	end

	self.db = ZenTrackerDb;

	if self.optionsFrame then
		return;
	end

	local optionsFrame = StdUi:PanelWithTitle(UIParent, 100, 100, 'Zen Tracker');
	optionsFrame.name = 'Zen Tracker';
	optionsFrame:Hide();

	self.optionsFrame = optionsFrame;

	StdUi:EasyLayout(optionsFrame, { padding = { top = 40 } });

	local debugEvents = StdUi:Checkbox(optionsFrame, 'Debug Events');
	if self.db.debugEvents then debugEvents:SetChecked(true); end
	debugEvents.OnValueChanged = function(_, flag) self.db.debugEvents = flag; end

	local debugMessages = StdUi:Checkbox(optionsFrame, 'Debug Messages');
	if self.db.debugMessages then debugMessages:SetChecked(true); end
	debugMessages.OnValueChanged = function(_, flag) self.db.debugMessages = flag; end

	local debugTracking = StdUi:Checkbox(optionsFrame, 'Debug Tracking');
	if self.db.debugTracking then debugTracking:SetChecked(true); end
	debugTracking.OnValueChanged = function(_, flag) self.db.debugTracking = flag; end

	local addSpell = StdUi:SpellBox(optionsFrame, nil, 20);
	local addSpellBtn = StdUi:Button(optionsFrame, nil, 20, '+');
	local blacklistFrame = StdUi:SpellList(optionsFrame, 200, 400, self.db.blacklist);

	addSpellBtn:SetScript('OnClick', function ()
		local spellId = addSpell:GetValue();
		if spellId then
			if tContains(ZT.db.blacklist, spellId) then
				print('Spell ' .. spellId .. ' is already on blacklist!');
			else
				tinsert(ZT.db.blacklist, spellId);
				blacklistFrame:RefreshList();
			end
		else
			print('Not valid spell/aura');
		end
	end);

	optionsFrame:AddRow():AddElements(debugEvents, debugMessages, debugTracking, { column = 'even' });

	local addSpellRow = optionsFrame:AddRow();
	addSpellRow:AddElement(addSpell, { column = 5 });
	addSpellRow:AddElement(addSpellBtn, { column = 1 });

	optionsFrame:AddRow():AddElements(blacklistFrame, { column = 6 });

	optionsFrame:SetScript('OnShow', function(of)
		of:DoLayout();
	end);

	InterfaceOptions_AddCategory(self.optionsFrame);
end