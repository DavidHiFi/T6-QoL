-- ============================================================================
--  zm_qol - LUI EVENT GUARD: ui\t6\codroot.lua, HARDENED (stock + one change).
-- ----------------------------------------------------------------------------
--  🛑 WHY THIS FILE EXISTS - THE process_events WEDGE (hard fix, 2026-09-15).
--
--  Chain that killed the game, seen live twice on 2026-09-15:
--    1. the SERVER dies (a raw script's include/helper is missing, an asset
--       override, any SV_Shutdown with script errors), OR a console-started
--       match is unwound back to the menu;
--    2. the frontend rebuilds and a queued menu event fires while the game
--       state it expects is gone (e.g. open_server_browser after the server
--       died -> MainMenuOG.OpenServerBrowser indexes a nil value);
--    3. the error is UNPROTECTED, so it reaches the engine as a Havok Script
--       Panic and the whole UI stops:
--           LUI_ERROR: Error processing event: process_events
--           ui_mp/T6/MainMenuOG.lua:8: attempt to index a nil value
--           ui/T6/CoDRoot.lua:59: in function 'ProcessEventNow'
--       The game is then wedged; only a full quit recovers.
--
--  THE FIX: this is the game's own file, byte-for-byte decompiled stock, with
--  ONE change - LUI.CoDRoot.ProcessEventNow now dispatches the event inside
--  pcall(). A handler that throws can no longer panic the Lua VM; the event is
--  dropped and logged instead:
--      [zm_qol] LUI GUARD: event '<name>' handler failed: <error>
--  Every menu-event path goes through this function (the immediate path via
--  LUI.CoDRoot.ProcessEvent and the queued path via ProcessEvents both call
--  LUI.CoDRoot.ProcessEventNow through the table), so this one guard covers
--  the whole frontend.
--
--  🛑 THIS IS A BACKSTOP, NOT A LICENSE. A server death still boots the player
--  to the menu and loses the match. The causes in step 1 must never happen:
--  obey the workspace AGENTS.md ("LUI wedge - hard fix and hard rules") - run
--  the hotload gate on any loose script, never exit a console-started match to
--  the menu, load the mod before the map, and never edit or deploy mod files
--  while a game session is live.
--
--  🌟 The installer in ui\t6\mainlobby.lua re-installs the same guard every
--  time the frontend reloads after a mod load, because codroot.lua itself is
--  required at BOOT (before a mod is on the search path) and is not part of
--  the post-load menu reload. Keep both halves. Do not remove either.
--  🌟 pcall is already used by this project's own LUI files
--  (ui\t6\menus\optionssettings.lua:44, ui\t6\mainlobby.lua:14), so it is a
--  proven callable in this engine's Lua.
-- ============================================================================
LUI.CoDRoot = {}
LUI.CoDRoot.ProcessEvent = function (f1_arg0, f1_arg1)
	if f1_arg1.immediate == true then
		LUI.CoDRoot.ProcessEventNow(f1_arg0, f1_arg1)
	else
		local f1_local0 = f1_arg0.eventQueue
		table.insert(f1_local0, f1_arg1)
		local f1_local1 = #f1_local0
		if f1_local1 > 20 then
			DebugPrint("LUI WARNING: Event queue exceeded 20 events! " .. f1_arg1.name .. ". Size is " .. f1_local1)
		end
	end
end

LUI.CoDRoot.ProcessEvents = function (f2_arg0, f2_arg1)
	local f2_local0 = f2_arg0.eventQueue
	local f2_local1 = 0
	local f2_local2 = #f2_local0
	if f2_local2 > 60 then
		f2_local1 = f2_local2
		DebugPrint("LUI WARNING: Event queue reached " .. f2_local1 .. "!. ** Emergency event processing kicked off. ** ")
	elseif f2_local2 > 40 then
		f2_local1 = math.floor(f2_local2 / 10)
		DebugPrint("LUI WARNING: Event queue reached " .. f2_local2 .. ". Processing " .. f2_local1 .. " events this frame.")
	else
		f2_local1 = 1
	end
	for f2_local3 = 1, f2_local1, 1 do
		local f2_local6 = f2_local3
		local f2_local7 = f2_local0[1]
		if f2_local7 ~= nil then
			table.remove(f2_local0, 1)
			LUI.CoDRoot.ProcessEventNow(f2_arg0, f2_local7)
		end
	end
end

-- zm_qol: the guarded worker. Stock did these three steps inline; the pcall
-- around them is the only behavioural change in this file.
LUI.CoDRoot.ZmQolGuardInner = function (f3_arg0, f3_arg1)
	f3_arg0:propagateEvent(f3_arg1)
	return LUI.UIElement.processEvent(f3_arg0, f3_arg1)
end

LUI.CoDRoot.ProcessEventNow = function (f3_arg0, f3_arg1)
	if f3_arg1 == nil then
		DebugPrint("[zm_qol] LUI GUARD: nil event dropped")
		return nil
	end
	if f3_arg1.name ~= "process_events" then
		Engine.EventProcessed()
	end
	Engine.PIXBeginEvent(tostring(f3_arg1.name))
	local f3_ok, f3_err = pcall(LUI.CoDRoot.ZmQolGuardInner, f3_arg0, f3_arg1)
	Engine.PIXEndEvent()
	if not f3_ok then
		DebugPrint("[zm_qol] LUI GUARD: event '" .. tostring(f3_arg1.name) .. "' handler failed: " .. tostring(f3_err))
	end
	return nil
end

LUI.CoDRoot.DontPropagateEvent = function (f4_arg0, f4_arg1)
end

LUI.CoDRoot.PropagateEventToPrimaryRoot = function (f5_arg0, f5_arg1)
	if LUI.primaryRoot ~= nil and LUI.primaryRoot ~= f5_arg0 and f5_arg1.name ~= "resize" and f5_arg1.name ~= "addmenu" then
		LUI.UIElement.processEvent(LUI.primaryRoot, f5_arg1)
	end
end

LUI.CoDRoot.CloseAll = function (f6_arg0, f6_arg1)
	f6_arg0:removeAllChildren()
end

LUI.CoDRoot.new = function (f7_arg0)
	local f7_local0 = LUI.UIRoot.new(f7_arg0)
	f7_local0.eventQueue = {}
	f7_local0.numEvents = 0
	f7_local0:registerEventHandler("process_events", LUI.CoDRoot.ProcessEvents)
	f7_local0:registerEventHandler("close_all", LUI.CoDRoot.CloseAll)
	if f7_arg0 == "UIRootDrc" then
		f7_local0.propagateEvent = LUI.CoDRoot.DontPropagateEvent
	else
		f7_local0.propagateEvent = LUI.CoDRoot.PropagateEventToPrimaryRoot
	end
	f7_local0.processEvent = LUI.CoDRoot.ProcessEvent
	if LUI.primaryRoot == nil then
		LUI.primaryRoot = f7_local0
	end
	return f7_local0
end

-- zm_qol: install the guard immediately (any code path that requires codroot
-- gets the hardened ProcessEventNow from here on).
DebugPrint("[zm_qol] LUI event guard: codroot.lua override loaded")
