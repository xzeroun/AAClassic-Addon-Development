CUIC_ADDON_LIST = 9000001
function CreateAddonsListFrame()
  local frame = CreateWindow("addonsList", "UIParent")
  frame:SetExtent(800, 415)
  frame:SetCloseOnEscape(true)
  frame:AddAnchor("CENTER", "UIParent", 0, 0)
  frame:SetTitle("Installed Addons")
  frame:Show(false)
  local sideMargin, titleMargin, bottomMargin = GetWindowMargin()
  local list = W_CTRL.CreatePageScrollListCtrl("adList", frame)
  list:Show(true)
  list:AddAnchor("TOPLEFT", frame, 4, 44 + sideMargin / 2)
  list:AddAnchor("BOTTOMRIGHT", frame, 0, bottomMargin)
  local NameSetFunc = function(subItem, data, setValue)
    if setValue then
      subItem.nameLabel:SetText(data.name)
    else
      subItem.nameLabel:SetText("")
    end
  end
  local DescSetFunc = function(subItem, data, setValue)
    if setValue and data.desc ~= nil then
      subItem:SetText(data.desc)
    else
      subItem:SetText("")
    end
  end
  local VerSetFunc = function(subItem, data, setValue)
    if setValue then
      subItem:SetText(data.version)
    else
      subItem:SetText("")
    end
  end
  local AutSetFunc = function(subItem, data, setValue)
    if setValue then
      subItem:SetText(data.author)
    else
      subItem:SetText("")
    end
  end
  local OptionSetFunc = function(subItem, data, setValue)
    if setValue then
      subItem.options:Show(data.settings.enabled)
      subItem.options.name = data.name
      subItem.options.settings = data.settings
      subItem.addon = data
      subItem.selectCheck:Show(true)
      subItem.selectCheck:SetChecked(data.settings.enabled)
    else
      subItem:Show(false)
    end
  end
  local NameColumnLayoutSetFunc = function(frame, rowIndex, colIndex, subItem)
    local nameLabel = subItem:CreateChildWidget("label", "nameLabel", 0, true)
    nameLabel:Show(true)
    nameLabel:SetExtent(140, 25)
    nameLabel:AddAnchor("CENTER", subItem, 3, -1)
    nameLabel.style:SetAlign(ALIGN_CENTER)
    ApplyTextColor(nameLabel, FONT_COLOR.DEFAULT)
  end
  local OptionsColumnLayoutSetFunc = function(frame, rowIndex, colIndex, subItem)
    local optionButton = frame:CreateChildWidget("button", subItem:GetId() .. ".optionsButton", 0, true)
    optionButton:AddAnchor("CENTER", subItem, -3, 0)
    subItem.options = optionButton
    subItem.options.name = ""
    subItem.options:Show(false)
    subItem.options.rowIndex = rowIndex
    function subItem.options:OnClick(arg)
      local data = frame:GetDataByViewIndex(rowIndex, colIndex)
      if data ~= nil and data.OnSettingToggle ~= nil then
        data.OnSettingToggle()
      else
        local subFrame = CreateWindow("addonSettings", frame)
        subFrame:SetExtent(800, 415)
        subFrame:SetCloseOnEscape(true)
        subFrame:AddAnchor("RIGHT", frame, 0, 0)
        subFrame:SetTitle(subItem.options.name .. " Settings")
        subFrame:Show(true)
        CreateAddonsListSettings(subFrame, subItem, subItem.options.settings)
      end
    end
    subItem.options:SetHandler("OnMouseUp", subItem.options.OnClick)
    ApplyButtonSkin(optionButton, BUTTON_CONTENTS.APPELLATION)
    local selectCheck = CreateCheckButton(subItem:GetId() .. ".selectCheck", subItem)
    selectCheck:Show(true)
    selectCheck:AddAnchor("LEFT", optionButton, "RIGHT", 5, 0)
    subItem.selectCheck = selectCheck
    subItem.selectCheck.rowIndex = rowIndex
    function selectCheck:CheckBtnCheckChagnedProc(checked)
      local data = frame:GetDataByViewIndex(rowIndex, colIndex)
      data.settings.enabled = checked
      SaveAddonSettings()
    end
  end
  list:InsertColumn("Name", 140, LCCIT_STRING, NameSetFunc, nil, nil, NameColumnLayoutSetFunc)
  list:InsertColumn("Description", 300, LCCIT_STRING, DescSetFunc, nil, nil)
  list:InsertColumn("Version", 100, LCCIT_STRING, VerSetFunc, nil, nil)
  list:InsertColumn("Author", 110, LCCIT_STRING, AutSetFunc, nil, nil)
  list:InsertColumn("Options", 110, LCCIT_STRING, OptionSetFunc, nil, nil, OptionsColumnLayoutSetFunc)
  list:InsertRows(10, false)
  list.listCtrl:DisuseSorting()
  DrawListCtrlUnderLine(list.listCtrl)
  for i = 1, #list.listCtrl.column do
    SettingListColumn(list.listCtrl, list.listCtrl.column[i])
    DrawListCtrlColumnSperatorLine(list.listCtrl.column[i], #list.listCtrl.column, i)
    if i == #list.listCtrl.column then
      list.listCtrl.column[i]:Enable(false)
    end
  end
  frame.list = list
  function frame:UpdateAddonList()
    local addons = API_STORE.addons
    local settings = API_STORE.settings
    list:DeleteAllDatas()
    list.pageControl:SetCurrentPage(1, false)
    for k, v in ipairs(addons) do
      list:InsertData(k, 1, v)
      list:InsertData(k, 2, v)
      list:InsertData(k, 3, v)
      list:InsertData(k, 4, v)
      list:InsertData(k, 5, v)
    end
  end
  local refreshButton = frame:CreateChildWidget("button", "refreshButton", 0, true)
  refreshButton:AddAnchor("BOTTOMRIGHT", frame, -sideMargin, -sideMargin)
  refreshButton:Show(true)
  refreshButton:SetExtent(28, 28)
  ApplyButtonSkin(refreshButton, BUTTON_BASIC.RESET)
  function refreshButton:OnClick()
    InitAddons()
    LoadAddons()
  end
  refreshButton:SetHandler("OnClick", refreshButton.OnClick)
  return frame
end
local getSetting = function(path, settings)
  local current = settings
  for part in string.gmatch(path, "([^%.]+)") do
    if current[part] then
      current = current[part]
    else
      return nil
    end
  end
  return current
end
local setSetting = function(path, value, settingsTable)
  local current = settingsTable
  local parts = {}
  for part in string.gmatch(path, "([^%.]+)") do
    table.insert(parts, part)
  end
  for i = 1, #parts - 1 do
    local part = parts[i]
    if type(current[part]) ~= "table" then
      if current[part] == nil then
        current[part] = {}
      else
        error("Path conflict: '" .. part .. "' is not a table and cannot have nested settings.")
      end
    end
    current = current[part]
  end
  local lastPart = parts[#parts]
  current[lastPart] = value
end
local function CreateSettingsSliderBar(parent, controlArg, optionId, sliderValue, settings)
  local sliderbar = CreateSlider("sliderbar", parent)
  sliderbar.controlType = "sliderbar"
  local titleBarWidth = 0
  if parent.optionTitle ~= nil then
    sliderbar:AddAnchor("LEFT", parent, 0, 0)
    titleBarWidth = parent.optionTitle:GetExtent()
  else
    sliderbar:AddAnchor("TOPLEFT", parent, 15, 0)
  end
  if sliderValue ~= nil then
    sliderbar:AddAnchor("RIGHT", parent, -40, 0)
  else
    sliderbar:AddAnchor("RIGHT", parent, -15, 0)
  end
  parent.sliderbar = sliderbar
  if controlArg ~= nil and type(controlArg) == "table" then
    sliderbar.label = {}
    for i = 1, #controlArg do
      local label = W_CTRL.CreateLabel("label[" .. i .. "]", sliderbar)
      label:SetHeight(15)
      label:SetAutoResize(true)
      label.style:SetFontSize(FONT_SIZE.SMALL)
      label:SetText(controlArg[i])
      sliderbar.label[i] = label
    end
    if sliderValue == nil then
      local insetTable = {
        {123, 240},
        {
          90,
          183,
          273
        },
        {
          73,
          147,
          217,
          292
        }
      }
      sliderbar.marking = {}
      for i = 1, #controlArg do
        local marking = sliderbar:CreateImageDrawable(TEXTURE_PATH.OPTION, "background")
        marking:SetCoords(0, 24, 9, 14)
        marking:SetExtent(9, 14)
        if i == 1 then
          marking:AddAnchor("LEFT", sliderbar, 0, 0)
        elseif i == #controlArg then
          marking:AddAnchor("RIGHT", sliderbar, -2, 0)
        else
          marking:AddAnchor("LEFT", sliderbar, insetTable[#controlArg - 3][i - 1], 0)
        end
        sliderbar.marking[i] = marking
      end
    end
    if #controlArg == 2 then
      sliderbar:SetMinMaxValues(tonumber(controlArg[1]), tonumber(controlArg[2]))
    end
  end
  local valLabel = W_CTRL.CreateLabel(".valLabel", sliderbar)
  valLabel:SetExtent(30, 20)
  valLabel:AddAnchor("LEFT", sliderbar, "RIGHT", 5, 0)
  valLabel.style:SetAlign(ALIGN_CENTER)
  ApplyTextColor(valLabel, FONT_COLOR.BLUE)
  valLabel.style:SetFontSize(FONT_SIZE.LARGE)
  function sliderbar:Init()
    if optionId ~= nil then
      self.originalValue = getSetting(optionId, settings)
      self:SetValue(self.originalValue, false)
      valLabel:SetText(tostring(math.floor(self.originalValue)))
    end
  end
  function sliderbar:Save()
    if optionId ~= nil then
      local value = math.floor(self:GetValue())
      setSetting(optionId, value, settings)
      if parent.changeHandler ~= nil then
        parent.changeHandler(value)
      end
    end
  end
  function sliderbar:OnSliderChanged(arg)
    local controlValue = self:GetValue() or 0
    valLabel:SetText(tostring(math.floor(controlValue)))
  end
  sliderbar:SetHandler("OnSliderChanged", sliderbar.OnSliderChanged)
  return sliderbar
end
local function CreateSettingCheckbox(frame, label, settings, settingPath)
  local checkbox = optionLocale:CreateCheckButton(frame, label, 4)
  checkbox.controlType = "checkbox"
  function checkbox:Init()
    local val = getSetting(settingPath, settings)
    if val ~= nil then
      self:SetChecked(val, false)
    end
  end
  function checkbox:Save()
    local isChecked = self:GetChecked()
    setSetting(settingPath, isChecked, settings)
  end
  return checkbox
end
function CreateAddonsListSettings(parent, subItem, settings)
  local frame = CreateScrollWindow(parent, "scrollWnd", 0)
  frame:Show(true)
  frame:AddAnchor("TOPLEFT", parent, 15, 20)
  frame:AddAnchor("BOTTOMRIGHT", parent, -15, -15)
  frame.totalHeight = 0
  frame.insetHeight = 0
  frame.content.optionFrames = {}
  function frame:InsertNewOption(controlType, textInfo, insertable, optionId, changeHandler, controlArg2, indentation, targetAnchorType)
    if insertable == false then
      return
    end
    local tip = ""
    local titleText = ""
    local controlArg
    if textInfo ~= nil then
      titleText = textInfo.titleStr
      tip = textInfo.tooltipStr
      controlArg = textInfo.controlStr
    end
    local index = #self.content.optionFrames + 1
    local optionFrame = self.content:CreateChildWidget("window", "optionFrames", index, true)
    optionFrame:Show(true)
    optionFrame.changeHandler = changeHandler
    optionFrame.controlType = controlType
    local width = self.content:GetExtent()
    if index == 1 then
      optionFrame:AddAnchor("TOPLEFT", self.content, 0, 0)
    elseif self.content.optionFrames[index - 1] ~= nil then
      optionFrame.targetAnchorType = targetAnchorType or OPTION_ITEM_TARGET_ANCHOR_BOTTOM
      local targetAnchor, offsetX
      if optionFrame.targetAnchorType == OPTION_ITEM_TARGET_ANCHOR_LEFT then
        targetAnchor = "TOPLEFT"
        if self.content.optionFrames[index - 1].targetAnchorType == OPTION_ITEM_TARGET_ANCHOR_LEFT then
          offsetX = 0
        else
          offsetX = width / 2
        end
      else
        targetAnchor = "BOTTOMLEFT"
        if self.content.optionFrames[index - 1].targetAnchorType == OPTION_ITEM_TARGET_ANCHOR_LEFT then
          offsetX = -width / 2
        else
          offsetX = 0
        end
      end
      optionFrame:AddAnchor("TOPLEFT", self.content.optionFrames[index - 1], targetAnchor, offsetX, 0)
      if controlType == OPTION_PARTITION_LINE then
        CreatePartitionImage(frame, optionFrame, self.content.optionFrames[index - 1])
        optionFrame:AddAnchor("TOPLEFT", self.content.optionFrames[index - 1], targetAnchor, offsetX, self.insetHeight)
        self.totalHeight = self.totalHeight + self.insetHeight
        return optionFrame
      end
    end
    indentation = indentation or 0
    local leftInset = 10 + indentation
    local optionTitle
    local optionContent = {}
    local tooltipTarget = optionFrame
    if titleText ~= nil and titleText ~= "" then
      optionTitle = optionLocale:CreatTitleWidget(optionFrame)
      optionTitle:Show(true)
      optionTitle:AddAnchor("LEFT", optionFrame, leftInset, 0)
      optionLocale:SetTitleExtent(controlType, optionTitle, width, leftInset)
      optionTitle.style:SetAlign(ALIGN_LEFT)
      optionTitle:SetText(titleText)
      ApplyTextColor(optionTitle, FONT_COLOR.MIDDLE_TITLE)
      if controlType == "subBigTitle" then
        optionTitle.style:SetFontSize(FONT_SIZE.LARGE)
        optionTitle.style:SetAlign(ALIGN_LEFT)
      end
      optionFrame.optionTitle = optionTitle
      tooltipTarget = optionTitle
    end
    if controlType == "textAndButton" and textInfo ~= nil and textInfo.contentStr ~= nil then
      for i, contentStr in next, textInfo.contentStr, nil do
        optionContent[i] = optionFrame:CreateChildWidget("textbox", "optionContent" .. tostring(i), 0, true)
        optionContent[i]:SetAutoResize(true)
        optionContent[i]:SetHeight(FONT_SIZE.MIDDLE)
        optionContent[i]:SetWidth(width)
        optionContent[i]:SetLineSpace(5)
        optionContent[i].style:SetFontSize(FONT_SIZE.MIDDLE)
        optionContent[i].style:SetAlign(ALIGN_LEFT)
        ApplyTextColor(optionContent[i], FONT_COLOR.DEFAULT)
        optionContent[i]:SetText(contentStr)
      end
    end
    if controlType == "sliderbar" then
      if optionTitle ~= nil then
        optionFrame:SetExtent(width, 80)
        optionTitle:RemoveAllAnchors()
        optionTitle:AddAnchor("TOPLEFT", optionFrame, leftInset, 10)
      else
        optionFrame:SetExtent(width, 60)
      end
    elseif controlType == "radiobuttonH" then
      optionLocale:SetRadioButtonHHeight(optionTitle, optionFrame, width)
      if optionTitle ~= nil then
        optionTitle:RemoveAllAnchors()
        optionTitle:AddAnchor("TOPLEFT", optionFrame, leftInset, 8)
      else
        optionFrame:SetExtent(width, 30)
      end
    elseif controlType == "radiobuttonV" then
      optionFrame:SetExtent(width, 4 + #controlArg * 25 + 25)
      if optionTitle ~= nil then
        optionTitle:RemoveAllAnchors()
        optionTitle:AddAnchor("TOPLEFT", optionFrame, leftInset, 8)
      else
        optionFrame:SetExtent(width, 4 + #controlArg * 25)
      end
    elseif controlType == "textAndButton" then
      local contentHeight = 0
      for _, content in next, optionContent, nil do
        if contentHeight > 0 then
          contentHeight = contentHeight + 12
        end
        contentHeight = contentHeight + content:GetHeight()
      end
      if optionTitle ~= nil then
        optionTitle:RemoveAllAnchors()
        optionTitle:AddAnchor("TOPLEFT", optionFrame, leftInset, 8)
        optionFrame:SetExtent(width, 130 + contentHeight)
      else
        optionFrame:SetExtent(width, 64 + contentHeight)
      end
    else
      optionFrame:SetExtent(width, 30)
    end
    local optionControl
    if controlType == "checkbox" then
      optionControl = CreateSettingCheckbox(optionFrame, controlArg, settings, optionId)
      if titleText == nil then
        tooltipTarget = optionControl.textButton
      end
    elseif controlType == "combobox" then
      optionControl = CreateOptionCombobox(optionFrame, controlArg, optionId, controlArg2)
    elseif controlType == "sliderbar" then
      optionControl = CreateSettingsSliderBar(optionFrame, controlArg, optionId, controlArg2, settings)
    elseif controlType == "radiobuttonH" then
      optionControl = CreateOptionRadioButton(optionFrame, controlArg, optionId, "horizen")
    elseif controlType == "radiobuttonV" then
      optionControl = CreateOptionRadioButton(optionFrame, controlArg, optionId, "vertical")
    elseif controlType == "keybindingcontrol" then
      optionControl = CreateOptionKeyBindingControl(optionFrame, controlArg, optionId)
    elseif controlType == "textAndButton" then
      optionControl = optionFrame:CreateChildWidget("button", "textAndButton", 0, true)
      optionControl.controlType = "textAndButton"
      optionControl:SetText(controlArg)
      ApplyButtonSkin(optionControl, BUTTON_BASIC.DEFAULT)
    else
      self.totalHeight = self.totalHeight + optionFrame:GetHeight()
      return optionFrame
    end
    tooltipTarget.tip = tip
    if optionControl ~= nil then
      optionControl.title = optionTitle
      function optionControl:Cancel()
        if self.originalValue ~= nil then
          SetOptionItemValue(optionId, self.originalValue)
        end
      end
      function optionControl:AttachChildWidget(widget, anchors)
        widget:AddAnchor(unpack(anchors))
        local _, sheight = F_LAYOUT.GetExtentWidgets(optionTitle, widget)
        optionFrame:SetHeight(sheight + 8)
      end
      if optionTitle ~= nil then
        if controlType == "sliderbar" then
          optionControl:AddAnchor("TOPLEFT", optionTitle, "BOTTOMLEFT", 0, 5)
          local controlWidth = optionControl:GetWidth()
          for i = 1, #optionControl.label do
            local label = optionControl.label[i]
            if i == 1 then
              label:AddAnchor("TOPLEFT", optionControl, "BOTTOMLEFT", 0, 3)
            elseif i == #controlArg then
              label:AddAnchor("TOPRIGHT", optionControl, "BOTTOMRIGHT", 0, 3)
            else
              local labelWidth = label:GetWidth()
              label:AddAnchor("TOPLEFT", optionControl, "BOTTOMLEFT", controlWidth / (#optionControl.label - 1) * (i - 1) - labelWidth / 2, 3)
            end
          end
        elseif controlType == "radiobuttonH" then
          optionControl:SetOffset(optionTitle, 0, optionTitle:GetHeight() + 5, 180)
        elseif controlType == "radiobuttonV" then
          optionControl:SetOffset(optionTitle, 0, optionTitle:GetHeight() + 5, 8)
        elseif controlType == "textAndButton" then
          local prevControl = optionTitle
          local height = 15
          for _, content in next, optionContent, nil do
            content:AddAnchor("TOPLEFT", prevControl, "BOTTOMLEFT", 0, height)
            prevControl = content
            height = 12
          end
          optionControl:AddAnchor("TOPLEFT", prevControl, "BOTTOMLEFT", 0, 15)
        else
          optionControl:AddAnchor("LEFT", optionTitle, "RIGHT", 0, 0)
        end
      elseif controlType == "radiobuttonH" then
        optionControl:SetOffset(optionFrame, leftInset, 8, 180)
      elseif controlType == "radiobuttonV" then
        optionControl:SetOffset(optionFrame, leftInset, 8, 8)
      else
        optionControl:AddAnchor("LEFT", optionFrame, leftInset, 0)
      end
      optionFrame.optionControl = optionControl
      function optionFrame:Init()
        optionFrame.Init()
      end
      function optionFrame:Save()
        optionFrame.Save()
      end
      function optionFrame:Cancel()
        optionFrame.Cancel()
      end
      function optionFrame:Enable(enable)
        if controlType == "radiobuttonH" then
          optionControl:Enable(enable)
        elseif controlType == "radiobuttonV" then
          optionControl:Enable(enable)
        end
      end
      if tooltipTarget.tip ~= nil and tooltipTarget.tip ~= "" then
        local OnEnter = function(self)
          SetHorizonTooltip(self.tip, self, 5)
        end
        tooltipTarget:SetHandler("OnEnter", OnEnter)
        local OnLeave = function()
          HideTooltip()
        end
        tooltipTarget:SetHandler("OnLeave", OnLeave)
      end
    end
    self.totalHeight = self.totalHeight + optionFrame:GetHeight()
    return optionControl
  end
  for k, v in pairs(settings) do
    local skip = false
    if k == "enabled" then
      skip = true
    end
    local textInfo
    if settings.s_options[k] ~= nil then
      textInfo = settings.s_options[k]
      if settings.s_options[k].hide then
        skip = true
      end
    else
      textInfo = {titleStr = k}
    end
    if not skip then
      if type(v) == "boolean" then
        frame:InsertNewOption("checkbox", textInfo, true, k, nil)
      end
      if type(v) == "number" then
        frame:InsertNewOption("sliderbar", textInfo, true, k, nil, true)
      end
    end
  end
  function frame:Init()
    for i = 1, #self.content.optionFrames do
      if self.content.optionFrames[i].optionControl ~= nil then
        self.content.optionFrames[i].optionControl:Init()
      end
    end
  end
  function frame:Save()
    for i = 1, #self.content.optionFrames do
      if self.content.optionFrames[i].optionControl ~= nil then
        self.content.optionFrames[i].optionControl:Save()
      end
    end
    SaveAddonSettings()
  end
  frame:Init()
  local saveButton = frame:CreateChildWidget("button", ".saveBtn", 0, true)
  ApplyButtonSkin(saveButton, BUTTON_BASIC.DEFAULT)
  saveButton:SetExtent(120, 33)
  saveButton:AddAnchor("BOTTOMLEFT", frame, -1, -1)
  saveButton:SetText("Save")
  function saveButton:OnClick()
    frame:Save()
  end
  saveButton:SetHandler("OnClick", saveButton.OnClick)
  return frame
end
addonsList = CreateAddonsListFrame()
function ToggleAddonListWnd()
  addonsList:Show(true)
end
addonsList:Show(false)
ADDON:RegisterContentTriggerFunc(CUIC_ADDON_LIST, ToggleAddonListWnd)
