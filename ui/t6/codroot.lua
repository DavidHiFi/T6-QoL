-- ============================================================================
--  zm_qol - ui\t6\codroot.lua: Treyarch's file, decompiled unchanged, plus the
--  LUI event guard at the bottom.
--
--  Without the guard, an event handler that throws reaches the engine as
--      LUI_ERROR: Error processing event: process_events
--  and the UI VM stops; only a full quit recovers. The guard re-points
--  LUI.CoDRoot.ProcessEventNow at a dispatcher that runs the stock steps with
--  the handler inside pcall, logs
--      [zm_qol] LUI GUARD: event '<name>' handler failed: <error>
--  and returns every value a handler that succeeds returns. Both event paths
--  (ProcessEvent and the queued ProcessEvents) call ProcessEventNow through the
--  table, so this one entry covers the frontend.
--
--  Measured 2026-10-05: the engine loads this file from the mod's IWD at boot
--  UI init (the mod is already mounted by then) and again after loadmod, and
--  ui\t6\mainlobby.lua loads right beside it in both sets. Every load of this
--  file re-creates LUI.CoDRoot (defined below), so the block re-makes and
--  re-points the dispatcher each time; the install announce is once per
--  process. Keep both copies: either one alone installs the guard. The guard
--  installs and acts only while fs_game is zm_qol; under any other mod it
--  hands events to the stock code.
--
--  This is a backstop. A server death or a console match exited to the menu
--  still ends the match; see the workspace AGENTS.md "LUI wedge" rules.
-- ============================================================================
LUI.CoDRoot = {}
LUI.CoDRoot.ProcessEvent = function ( f1_arg0, f1_arg1 )
	if f1_arg1.immediate == true then
		LUI.CoDRoot.ProcessEventNow( f1_arg0, f1_arg1 )
	else
		local f1_local0 = f1_arg0.eventQueue
		table.insert( f1_local0, f1_arg1 )
		local f1_local1 = #f1_local0
		if f1_local1 > 20 then
			DebugPrint( "LUI WARNING: Event queue exceeded 20 events! " .. f1_arg1.name .. ". Size is " .. f1_local1 )
		end
	end
end

LUI.CoDRoot.ProcessEvents = function ( f2_arg0, f2_arg1 )
	local f2_local0 = f2_arg0.eventQueue
	local f2_local1 = 0
	local f2_local2 = #f2_local0
	if f2_local2 > 60 then
		f2_local1 = f2_local2
		DebugPrint( "LUI WARNING: Event queue reached " .. f2_local1 .. "!. ** Emergency event processing kicked off. ** " )
	elseif f2_local2 > 40 then
		f2_local1 = math.floor( f2_local2 / 10 )
		DebugPrint( "LUI WARNING: Event queue reached " .. f2_local2 .. ". Processing " .. f2_local1 .. " events this frame." )
	else
		f2_local1 = 1
	end
	for f2_local3 = 1, f2_local1, 1 do
		local f2_local6 = f2_local3
		local f2_local7 = f2_local0[1]
		if f2_local7 ~= nil then
			table.remove( f2_local0, 1 )
			LUI.CoDRoot.ProcessEventNow( f2_arg0, f2_local7 )
		end
	end
end

LUI.CoDRoot.ProcessEventNow = function ( f3_arg0, f3_arg1 )
	if f3_arg1.name ~= "process_events" then
		Engine.EventProcessed()
	end
	f3_arg0:propagateEvent( f3_arg1 )
	Engine.PIXBeginEvent( f3_arg1.name )
	local f3_local0 = LUI.UIElement.processEvent( f3_arg0, f3_arg1 )
	Engine.PIXEndEvent()
	return f3_local0
end

LUI.CoDRoot.DontPropagateEvent = function ( f4_arg0, f4_arg1 )
	
end

LUI.CoDRoot.PropagateEventToPrimaryRoot = function ( f5_arg0, f5_arg1 )
	if LUI.primaryRoot ~= nil and LUI.primaryRoot ~= f5_arg0 and f5_arg1.name ~= "resize" and f5_arg1.name ~= "addmenu" then
		LUI.UIElement.processEvent( LUI.primaryRoot, f5_arg1 )
	end
end

LUI.CoDRoot.CloseAll = function ( f6_arg0, f6_arg1 )
	f6_arg0:removeAllChildren()
end

LUI.CoDRoot.new = function ( f7_arg0 )
	local self = LUI.UIRoot.new( f7_arg0 )
	self.eventQueue = {}
	self.numEvents = 0
	self:registerEventHandler( "process_events", LUI.CoDRoot.ProcessEvents )
	self:registerEventHandler( "close_all", LUI.CoDRoot.CloseAll )
	if f7_arg0 == "UIRootDrc" then
		self.propagateEvent = LUI.CoDRoot.DontPropagateEvent
	else
		self.propagateEvent = LUI.CoDRoot.PropagateEventToPrimaryRoot
	end
	self.processEvent = LUI.CoDRoot.ProcessEvent
	if LUI.primaryRoot == nil then
		LUI.primaryRoot = self
	end
	return self
end

-- zm_qol LUI EVENT GUARD BEGIN (identical in ui\t6\codroot.lua and ui\t6\mainlobby.lua;
-- tools\check-lui-guard.ps1 fails the build if the two copies differ)
if ZmQolLuiGuardModActive == nil then
	ZmQolLuiGuardModActive = function ()
		local Ok, Value = pcall(function () return Dvar.fs_game:get() end)
		if not Ok or type(Value) ~= "string" then
			return false
		end
		Value = string.lower(Value)
		return Value == "mods/zm_qol" or Value == "zm_qol"
	end
end

-- The one text channel that provably reaches console_zm.log from LUI in this
-- build (measured 2026-10-05): set a dvar to the line, then send the dvar's
-- bare name. The engine answers in console_zm.log with
--     "zmqol_lui_guard" is: "<value>^7" default: "^7"
-- The old channels are measured dead in this build: an Engine.Exec "echo ..."
-- comes back as `Unknown command "echo"` with the payload discarded, and
-- DebugPrint produces no console_zm.log line at all.
local ZmQolGuardSay = function (Dvar, Value)
	pcall(Engine.Exec, 0, "set " .. Dvar .. " \"" .. Value .. "\"")
	pcall(Engine.Exec, 0, Dvar)
end

if LUI ~= nil and LUI.CoDRoot ~= nil and ZmQolLuiGuardModActive() then
	if LUI.CoDRoot.ZmQolGuardDispatch == nil and type(LUI.CoDRoot.ProcessEventNow) == "function" then
		-- The function being replaced. Kept so the guard can step aside when
		-- another mod is loaded, and never wrapped twice: a later run of this
		-- block finds ZmQolGuardDispatch set and only re-points the table entry.
		local Stock = LUI.CoDRoot.ProcessEventNow

		local Report = function (Event, Err)
			local Name = "nil"
			if type(Event) == "table" then
				Name = tostring(Event.name)
			end
			local Line = "[zm_qol] LUI GUARD: event '" .. Name .. "' handler failed: " .. tostring(Err)
			-- Newlines, double quotes and semicolons would break the one-line
			-- console set; flatten them before it goes through.
			local Safe = string.gsub(string.gsub(string.gsub(Line, "[\r\n]", " "), "\"", "'"), ";", " ")
			ZmQolGuardSay("zmqol_lui_guard_last", Safe)
		end

		-- Ends the PIX scope and hands back every value the handler returned,
		-- trailing nils included. A failed handler returns nil, as an
		-- unhandled event does.
		local Finish = function (Event, Ok, ...)
			Engine.PIXEndEvent()
			if not Ok then
				Report(Event, ...)
				return nil
			end
			return ...
		end

		LUI.CoDRoot.ZmQolGuardStock = Stock
		LUI.CoDRoot.ZmQolGuardDispatch = function (Root, Event)
			if not ZmQolLuiGuardModActive() then
				return Stock(Root, Event)
			end
			if Event == nil then
				Report(Event, "nil event dropped")
				return nil
			end
			-- Stock order: EventProcessed, propagate, PIX begin, handler, PIX end.
			if Event.name ~= "process_events" then
				Engine.EventProcessed()
			end
			local PropagateOk, PropagateErr = pcall(Root.propagateEvent, Root, Event)
			if not PropagateOk then
				Report(Event, PropagateErr)
			end
			Engine.PIXBeginEvent(Event.name)
			return Finish(Event, pcall(LUI.UIElement.processEvent, Root, Event))
		end
	end

	if LUI.CoDRoot.ZmQolGuardDispatch ~= nil then
		LUI.CoDRoot.ProcessEventNow = LUI.CoDRoot.ZmQolGuardDispatch
		-- Announce exactly once per process. The stored dvar value is the
		-- idempotency marker: it survives this file being re-executed (which
		-- re-creates LUI.CoDRoot and, with it, the dispatcher) and survives a
		-- UI VM rebuild, which a Lua global would not. Guard catches on the
		-- same boot go to zmqol_lui_guard_last and never disturb this marker.
		local Announced = false
		pcall(function ()
			Announced = UIExpression.DvarString(nil, "zmqol_lui_guard") == "[zm_qol] LUI event guard installed"
		end)
		if not Announced then
			ZmQolGuardSay("zmqol_lui_guard", "[zm_qol] LUI event guard installed")
		end
	end
end
-- zm_qol LUI EVENT GUARD END
