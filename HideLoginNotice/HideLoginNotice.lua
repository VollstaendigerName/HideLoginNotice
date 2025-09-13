-- =============================================================================
-- === HideLoginNotice Core Logic (HideLoginNotice.lua)                      ===
-- =============================================================================
--[[
    AddOn Name:         HideLoginNotice
    Description:        Hides friend login/logout notifications
    Version:            1.0.0
    Author:             VollständigerName
    Dependencies:       None
--]]
-- =============================================================================
--[[
    SYSTEM ARCHITECTURE:
    - Friend Notification Suppression Engine
    - Settings Persistence System
    - Slash Command Interface
    - Event-Based Initialization
--]]
-- =============================================================================

-- =============================================================================
-- == GLOBAL ADDON DEFINITION & VERSION CONTROL ================================
-- =============================================================================
--[[
    Purpose: Establishes fundamental addon identity and configuration
    Contains:
    - Addon metadata for ESO client recognition
    - Default settings configuration
    - Storage for original event handlers
--]]
HideLoginNotice = {
    name = "HideLoginNotice", -- Internal namespace identifier
    version = "1.0.0", -- Semantic version (Major=Breaking, Minor=Features, Patch=Fixes)
    -- Settings configuration
    settings = {
        enabled = true  -- Default: notifications hidden
    },
    originalHandlers = {} -- Original handler storage for restoration purposes
}

-- =============================================================================
-- == LOCALIZED ALIASES & RUNTIME REFERENCES ===================================
-- =============================================================================
--[[
    Purpose: Optimizes frequent access patterns and reduces overhead
    Contains:
    - Localized addon namespace reference
    - Cached event manager reference
--]]
local HLN = HideLoginNotice -- Local namespace alias
local NAME = HLN.name -- Immutable addon name
local EMSV = EVENT_MANAGER -- Event system shortcut

-- =============================================================================
-- == CORE FUNCTIONALITY: NOTIFICATION SUPPRESSION =============================
-- =============================================================================
--[[
    Function: SuppressedStatusHandler
    Purpose:
      Empty function that replaces the original status change handlers
      to effectively suppress friend login/logout notifications
      
    Process Flow:
      - Does nothing when called
      - Replaces the original chat system and router handlers
--]]
local function SuppressedStatusHandler()
    -- Empty function to suppress notifications
end

-- =============================================================================
-- == NOTICE EVENT HANDLER =====================================================
-- =============================================================================
--[[
    Function: HLN.UpdateHandlers
    Purpose:
      Applies or removes notification suppression based on current settings
      
    Process Flow:
      1. Checks enabled setting value
      2. Sets event handlers accordingly:
         - If true: Replaces with empty function to suppress notifications
         - If false: Restores original handlers to show notifications
--]]
function HLN.UpdateHandlers()
    -- Suppress notifications by replacing with empty handler
    if HLN.settings.enabled then
        ZO_ChatSystem_GetEventHandlers()[EVENT_FRIEND_PLAYER_STATUS_CHANGED] = SuppressedStatusHandler
        CHAT_ROUTER.registeredMessageFormatters[EVENT_FRIEND_PLAYER_STATUS_CHANGED] = SuppressedStatusHandler

    -- Restore original handlers to show notifications
    else
        ZO_ChatSystem_GetEventHandlers()[EVENT_FRIEND_PLAYER_STATUS_CHANGED] = HLN.originalHandlers.chatSystem
        CHAT_ROUTER.registeredMessageFormatters[EVENT_FRIEND_PLAYER_STATUS_CHANGED] = HLN.originalHandlers.chatRouter
    end
end

-- =============================================================================
-- == SLASH COMMAND IMPLEMENTATION =============================================
-- =============================================================================
--[[
    Function: Slash Command Handler
    Purpose:
      Provides user interaction via chat commands
      
    Process Flow:
      1. Toggles enabled setting when /hideloginnotice is called
      2. Immediately updates event handlers
      3. Provides visual feedback in chat
--]]
SLASH_COMMANDS["/hideloginnotice"] = function()
    HLN.settings.enabled = not HLN.settings.enabled -- Toggle setting
    HLN.UpdateHandlers() -- Immediate application of changes
    d("Login notifications: " .. (HLN.settings.enabled and "|cFF0000hidden|r" or "|c00FF00shown|r")) -- Visual feedback
end

-- =============================================================================
-- == ADDON INITIALIZATION =====================================================
-- =============================================================================
--[[
    Function: HLN.Initialize
    Purpose:
      Performs addon initialization routines
      
    Process Flow:
      1. Backs up original event handlers for later restoration
      2. Applies initial configuration based on settings
--]]
function HLN.Initialize()
    -- Backup original handlers
    HLN.originalHandlers.chatSystem = ZO_ChatSystem_GetEventHandlers()[EVENT_FRIEND_PLAYER_STATUS_CHANGED]
    HLN.originalHandlers.chatRouter = CHAT_ROUTER.registeredMessageFormatters[EVENT_FRIEND_PLAYER_STATUS_CHANGED]
    
    -- Apply initial configuration
    HLN.UpdateHandlers()
end

-- =============================================================================
-- == EVENT HANDLER: ADDON LOADED ==============================================
-- =============================================================================
--[[
    Function: OnAddOnLoaded
    Purpose:
      Handles the EVENT_ADD_ON_LOADED event to initialize the addon
      only when its specific data is available
      
    Process Flow:
      1. Checks if the loaded addon is our own
      2. Unregisters event handler after successful initialization
      3. Performs addon initialization
--]]
local function OnAddOnLoaded(event, addonName)
    if addonName == NAME then
        EMSV:UnregisterForEvent(NAME, EVENT_ADD_ON_LOADED) -- Event unregistration after successful loading
        HLN.Initialize() -- Addon initialization
    end
end

-- =============================================================================
-- == EVENT REGISTRATION =======================================================
-- =============================================================================
--[[
    Purpose: Registers necessary event handlers for addon operation
    Contains:
    - EVENT_ADD_ON_LOADED handler for delayed initialization
--]]
EMSV:RegisterForEvent(NAME, EVENT_ADD_ON_LOADED, OnAddOnLoaded)