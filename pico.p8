pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
dt = 1/stat(7)

function _init()
	-- set btnp delay
	poke(0x5f5d, 2.5)
	
	state:set(editing)
end

function _update()
	state:update()
	
	-- update delta time
	dt = 1/stat(7)
end

function _draw()
	state:draw()
end

-- state
state = {
	active = nil
}

function state:set(new)
	self.active = new
	self.active:init()
end

function state:update()
	if self.active ~= nil then
		self.active:update()
	end
end

function state:draw()
	if self.active ~= nil then
		self.active:draw()
	end
end

-- state machine
state_machine = {}
state_machine.__index = state_machine

function state_machine:new()
	return setmetatable({
		states = {},
		active = nil,
	}, state_machine)
end

function state_machine:push(name, nstate)
	nstate:init()
	self.states[name] = nstate
end

function state_machine:set(name)
	self.active = self.states[name]
end

function state_machine:update()
	if self.active == nil then
		return
	end
	
	self.active:update()
end

function state_machine:draw()
	if self.active == nil then
		return
	end
	
	self.active:draw()
end

-- ui stuff
button = {}
button.__index = button

function button:new(x, y, text, action)
	local b = {
		x = x, y = y,
		text = text,
		
		action = action,
	}
	
	return setmetatable(b, button)
end

function button:update()
end

function button:draw(cl)
	?self.text,self.x,self.y,cl
end

handler = {}
handler.__index = handler

function handler:new()
	return setmetatable({
		elements = {},
		active = 1,
	}, handler)
end

function handler:add(ui)
	add(self.elements, ui)
end

function handler:update()
	for element in all(self.elements) do
		element:update()
	end
	
	if btnp(⬇️) then
		self.active += 1
		if self.active > #self.elements then
			self.active = 1 -- wrap around to top
		end
	end

	if btnp(⬆️) then
		self.active -= 1
		if self.active < 1 then
			self.active = #self.elements -- wrap around to bottom
		end
	end
	
	if btnp(❎) then
		self.elements[self.active]:action()
	end
end

function handler:draw()
	for idx,element in ipairs(self.elements) do
		local cl = settings.bdt
		if idx == self.active then
			cl = settings.bda
			?"!",element.x+(#element.text * 4) + 1,element.y, settings.bda
		end
		
		element:draw(cl)
	end
end
-->8
-- settings

cursor_type = {
	block = "block",
	ibeam = "ibeam",
}

settings = {
	bg = 5,
	bd = 8, bdt = 2, bda = 9,
	
	cs = 8, ct = cursor_type.block,
	lsh = true,
	lcl = 6,
}

tokens = {
	kill = 1,
	comma = 2,
	dot = 3,
	minus = 4,
	plus = 5,
	less = 6,
	more = 7,
	bracket_open = 8,
	bracket_close = 9,
}
-->8
-- editing

editing = {}

function editing:init()
	self.min = 0
	self.pos = {
		ln = 1, cm = self.min,
	}
	
	self.lines = {
		[1] = {}
	}
	
	self.states = state_machine:new()
	self.states:push("normal", normal)
	self.states:push("menu", menu)
	
	self.states:set("normal")
	
	self.active = {
		token = tokens.kill,
		
		show = true,
		blink_time = 0,
		blink_timeout = 0.30,
	}
		
	self.cursor = {
		show = true,
		
		blink_time = 0,
		blink_timeout = 0.25,
	}
	
	self.bounds = {
		l = 0, r = 15,
		u = 1, d = 14,
	}
	
	self.cam = {
		x = 0, y = 0,
	}
end

function editing:__incp(c)
	self.bounds.l += c
	self.bounds.r += c
	
	self.cam.x += c*8
end

function editing:__rmp(c)
	self.bounds.l -= c
	self.bounds.r -= c
	
	self.cam.x -= c*8
end

function editing:__incs(c)
	self.bounds.u += c
	self.bounds.d += c
	
	self.cam.y += c*8
end

function editing:__rms(c)
	self.bounds.u -= c
	self.bounds.d -= c
	
	self.cam.y -= c*8
end

function editing:update()
	-- cursor blinking
	local cur = self.cursor
	cur.blink_time += dt
	if cur.blink_time >= cur.blink_timeout then
		cur.show = not cur.show
		cur.blink_time = 0
	end	
	
	-- token blinking
	self.active.blink_time += dt
	if self.active.blink_time >= self.active.blink_timeout then
		self.active.show = not self.active.show
		self.active.blink_time = 0	
	end
	
	self.states:update()
end

function editing:draw()
	cls(settings.bg)
		
	-- cursor position
	local cx, cy = self.pos.cm * 8, self.pos.ln * 8
	
	-- line background
	if settings.lsh then
		rectfill(
			0, cy - self.cam.y,
			128, (cy - self.cam.y) + 7, 
			settings.lcl
		)
	end
	
	-- set camera for cursor and tokens
	--! the cursor line goes above the camera
	--! but not the cursor... idk how this works?
	camera(self.cam.x, self.cam.y)

	
	-- draw cursor
	if self.cursor.show then
		if settings.ct == cursor_type.ibeam then
			rectfill(
				cx, cy,
				cx, cy + 7,
				settings.cs 
			)
		elseif settings.ct == cursor_type.block then
			rectfill(
				cx + 1, cy,
				cx + 6, cy + 7,
				settings.cs 
			)
		end
	end
	
	-- tokens
	for il,ln in pairs(self.lines) do
		for it,tk in pairs(ln) do			
			spr(tk, it * 8, il * 8)
		end
	end
	
	-- reset camera for ui
	-- (the bands)
	camera(0, 0)
	
	self.states:draw()
	
	-- top band
	rectfill(
		0,0, 128, 6, settings.bd
	)
	?"brainf*ck.p8", 1, 1, settings.bdt
	
	-- bottom band
	local by = 121
	rectfill(
		0, by,
		128, by + 8,
		settings.bd
	)
	
	local bt = "ln " .. self.pos.ln .. " col " .. self.pos.cm
	?bt, 1, 122, settings.bdt
	
	rectfill(121, 122, 126, 126, 0)
	if self.active.show then
		spr(self.active.token, 120, 121)
	end
end
-->8
-- editor states

normal = {}

function normal:init()
end

function normal:update()
	self = editing
	-- token switching
	if btn(🅾️) then
		if btnp(⬅️) then
			if self.active.token > 1 then
				self.active.token -= 1
			end
		elseif btnp(➡️) then
			if self.active.token < 9 then
				self.active.token += 1
			end
		end
		
		-- open menu
		if btnp(⬇️) then
			menu.handle.active = 1
			self.states:set("menu")
		end
		
		return
	end
	
	-- place token
	if btnp(❎) then
		-- fill up empty lines
		if self.lines[self.pos.ln] == nil then
			for i=1,self.pos.ln do
				if self.lines[i] == nil then
					self.lines[i] = {}
				end
			end
		end
		
		-- if we want to delete
		if self.active.token == tokens.kill then
			self.lines[self.pos.ln][self.pos.cm] = nil
		else 
		-- place token down
			self.lines[self.pos.ln][self.pos.cm] = self.active.token
		end
	end
	
	-- position
	if btnp(➡️) then
		self.pos.cm += 1
		if self.pos.cm > self.bounds.r then
			self:__incp(1)
		end
	elseif btnp(⬅️) then
		if self.pos.cm > self.min then 
			self.pos.cm -= 1
			if self.pos.cm < self.bounds.l then
				self:__rmp(1)
			end
		end
	end
	
	if btnp(⬆️) then
		if self.pos.ln > 1 then
			self.pos.ln -= 1
			if self.pos.ln < self.bounds.u then
				self:__rms(1)
			end
		end
	elseif btnp(⬇️) then
		self.pos.ln += 1
		if self.pos.ln > self.bounds.d then
			self:__incs(1)
		end
	end
end

function normal:draw()
end

menu = {
	sx = 55, sy = 60,
	handle = handler:new(),
	__count = 0
}

function menu:create(text, action)
	self.__count += 1
	self.handle:add(
		button:new(
			1, 8*self.__count, text,
			action
		)
	)
end

function menu:init()
	self:create("run code", function()
		-- todo
	end)
	
	self:create("options", function()
		-- todo
	end)
	
	self:create("copy to clip", function()
		-- todo
	end)
	
	self:create("paste clip", function()
		local data = stat(4)
		
		local x = editing.pos.cm
		local y = editing.pos.ln
		
		for idx=1,#data do
			local ch = sub(data, idx, idx)
			
		end
	end)
	
	self:create("clear code", function()
		editing.lines = {
			{}
		}
	end)
	
	self:create("return", function()
		editing.states:set("normal")
	end)
	
	self.sy = self.__count * 8
end

function menu:update()
	self.handle:update()
end

function menu:draw()
	local rx = 0
	local ry = 7
	rectfill(
		rx, ry,
		rx+self.sx, ry+self.sy,
		settings.bd
	)
	
	self.handle:draw()
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000003b0000000e800009a00000022220000111100000000000000000000000000000000000000000000000000
00700700008082000009a00000000000000000000003b000000e80000009a000002eee0000ddd100000000000000000000000000000000000000000000000000
000770000008200000009000000280000cccccc0033333b000e8000000009a00002e00000000d100000000000000000000000000000000000000000000000000
00077000008082000009a00000082000011111100003bbb0000e80000009a000002e00000000d100000000000000000000000000000000000000000000000000
0070070000000000000a000000000000000000000003b0000000e800009a00000022220000111100000000000000000000000000000000000000000000000000
