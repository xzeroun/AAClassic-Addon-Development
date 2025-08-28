CUIC_RAID_COMMAND_MESSAGE = 9002
CUIC_COMBAT_TEXT_FRAME = 9003
CUIC_TARGET_OF_TARGET_FRAME = 9004
CUIC_WATCH_TARGET_FRAME = 9005
CUIC_RAID_MANAGER = 9006
CUIC_COMMUNITY_WINDOW = 9007
CUIC_ENCHANT_WINDOW = 9008
CUIC_ADVENTURE_GUIDE = 9009
CUIC_RESIDENT_GLOBAL_TRADE = 9010
local blockedEvents = {
  HOUSE_TAX_INFO = true,
  UNIT_ENTERED_SIGHT = true,
  UNIT_LEAVED_SIGHT = true
}
local sanitizedEvents = {COMBAT_MSG = true}
local stealthBuffs = {
  599,
  600,
  601,
  5278,
  5279,
  5280,
  8224,
  8225
}
function AddonPatchWnd(wnd)
  if type(wnd) ~= "table" and type(wnd) ~= "userdata" then
    return wnd
  end
  if wnd.__addon_patched then
    return wnd
  end
  wnd.__addon_patched = true
  local rawRegister = wnd.RegisterEvent
  local rawSetHandler = wnd.SetHandler
  if type(rawRegister) == "function" then
    function wnd:RegisterEvent(eventName, callback)
      if blockedEvents[eventName] then
        ADDON_API.Log:Info("|cFFC13D36[Addon API] Event: '" .. eventName .. "' is not allowed to be registered.")
        return
      end
      return rawRegister(self, eventName, callback)
    end
  end
  if type(rawSetHandler) == "function" then
    function wnd:SetHandler(eventName, handler)
      if eventName == "OnEvent" and type(handler) == "function" then
        local function wrapped(self, event, ...)
          if blockedEvents[event] then
            ADDON_API.Log:Info("|cFFC13D36[Addon API] Event: '" .. event .. "' is not allowed to be handled.")
            return
          end
          if sanitizedEvents[event] then
          end
          if type(handler) == "function" then
            return handler(self, event, ...)
          end
        end
        return rawSetHandler(self, eventName, wrapped)
      end
      return rawSetHandler(self, eventName, handler)
    end
  end
  return wnd
end
local rawGetContent = ADDON.GetContent
local wrappedAddon = setmetatable({}, {
  __index = function(_, k)
    if k == "GetContent" then
      return function(_, ...)
        local wnd = rawGetContent(ADDON, ...)
        return AddonPatchWnd(wnd)
      end
    end
    local v = ADDON[k]
    if type(v) == "function" then
      return function(_, ...)
        return v(ADDON, ...)
      end
    end
    return v
  end
})
function CreateAddonSandbox(baseDir, api)
  local sandbox_loaded = {}
  api.baseDir = baseDir
  local sandboxEnv = {
    api = api,
    print = print,
    string = string,
    table = table,
    math = math,
    pairs = pairs,
    ipairs = ipairs,
    tonumber = tonumber,
    tostring = tostring,
    type = type,
    pcall = pcall,
    xpcall = xpcall,
    unpack = unpack,
    baseDir = baseDir,
    getmetatable = getmetatable,
    ADDON = wrappedAddon,
    BUTTON_BASIC = BUTTON_BASIC,
    BUTTON_CONTENTS = BUTTON_CONTENTS,
    CURSOR_PATH = CURSOR_PATH,
    FONT_COLOR = FONT_COLOR,
    FONT_SIZE = FONT_SIZE,
    TEXTURE_PATH = TEXTURE_PATH,
    F_SLOT = F_SLOT,
    F_UNIT = F_UNIT,
    SLOT_STYLE = SLOT_STYLE,
    STATUSBAR_STYLE = STATUSBAR_STYLE,
    COMBAT_TEXT_COLOR = COMBAT_TEXT_COLOR,
    ConvertColor = ConvertColor,
    ApplyTextColor = ApplyTextColor,
    ApplyButtonSkin = ApplyButtonSkin,
    X2Util = X2Util,
    X2Chat = X2Chat,
    X2Hotkey = X2Hotkey,
    X2NameTag = X2NameTag,
    X2Player = X2Player,
    chatTabWindow = chatTabWindow,
    chatWnd = chatWnd,
    petFrame = petFrame,
    CreateItemIconButton = CreateItemIconButton,
    combatTextLocale = combatTextLocale,
    ParseCombatMessage = ParseCombatMessage,
    GetTextureInfo = GetTextureInfo,
    UIC = {
      DEV_WINDOW = UIC_DEV_WINDOW,
      ABILITY_CHANGE = UIC_ABILITY_CHANGE,
      CHARACTER_INFO = UIC_CHARACTER_INFO,
      AUTH_MSG_WND = UIC_AUTH_MSG_WND,
      BUBBLE_ACTION_BAR = UIC_BUBBLE_ACTION_BAR,
      BAG = UIC_BAG,
      DEATH_AND_RESURRECTION_WND = UIC_DEATH_AND_RESURRECTION_WND,
      OPTION_FRAME = UIC_OPTION_FRAME,
      SYSTEM_CONFIG_FRAME = UIC_SYSTEM_CONFIG_FRAME,
      GAME_EXIT_FRAME = UIC_GAME_EXIT_FRAME,
      SLAVE_EQUIPMENT = UIC_SLAVE_EQUIPMENT,
      PLAYER_UNITFRAME = UIC_PLAYER_UNITFRAME,
      TARGET_UNITFRAME = UIC_TARGET_UNITFRAME,
      RAID_COMMAND_MESSAGE = CUIC_RAID_COMMAND_MESSAGE,
      COMBAT_TEXT_FRAME = CUIC_COMBAT_TEXT_FRAME,
      TARGET_OF_TARGET_FRAME = CUIC_TARGET_OF_TARGET_FRAME,
      WATCH_TARGET_FRAME = CUIC_WATCH_TARGET_FRAME,
      RAID_MANAGER = CUIC_RAID_MANAGER,
      COMMUNITY_WINDOW = CUIC_COMMUNITY_WINDOW,
      ENCHANT_WINDOW = CUIC_ENCHANT_WINDOW
    },
    ALIGN = {
      LEFT = ALIGN_LEFT,
      RIGHT = ALIGN_RIGHT,
      CENTER = ALIGN_CENTER,
      TOP = ALIGN_TOP,
      BOTTOM = ALIGN_BOTTOM,
      BOTTOM_RIGHT = ALIGN_BOTTOM_RIGHT,
      BOTTOM_LEFT = ALIGN_BOTTOM_LEFT,
      TOP_LEFT = ALIGN_TOP_LEFT,
      TOP_RIGHT = ALIGN_TOP_RIGHT
    },
    W_CTRL = W_CTRL,
    W_ICON = W_ICON,
    W_UNIT = W_UNIT,
    W_ETC = W_ETC,
    W_BAR = W_BAR,
    W_MONEY = W_MONEY,
    W_BTN = W_BTN,
    EQUIP_SLOT = {
      HEAD = ES_HEAD,
      NECK = ES_NECK,
      CHEST = ES_CHEST,
      WAIST = ES_WAIST,
      LEGS = ES_LEGS,
      HANDS = ES_HANDS,
      FEET = ES_FEET,
      ARMS = ES_ARMS,
      BACK = ES_BACK,
      EAR_1 = ES_EAR_1,
      EAR_2 = ES_EAR_2,
      FINGER_1 = ES_FINGER_1,
      FINGER_2 = ES_FINGER_2,
      UNDERSHIRT = ES_UNDERSHIRT,
      UNDERPANTS = ES_UNDERPANTS,
      MAINHAND = ES_MAINHAND,
      OFFHAND = ES_OFFHAND,
      RANGED = ES_RANGED,
      MUSICAL = ES_MUSICAL,
      BACKPACK = ES_BACKPACK,
      COSPLAY = ES_COSPLAY
    }
  }
  setmetatable(sandboxEnv, {__metatable = "locked"})
  function sandboxEnv.require(name)
    if name == "api" then
      return ADDON_API
    end
    if not sandbox_loaded[name] then
      local file, err = loadfile(baseDir .. "/" .. name .. ".lua")
      if not file then
        error("Error loading file " .. err)
      end
      local module_env = setmetatable({}, {__index = sandboxEnv})
      setfenv(file, module_env)
      sandbox_loaded[name] = file()
    end
    return sandbox_loaded[name]
  end
  return sandboxEnv
end
