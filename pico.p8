pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
dt = 1/stat(7)

function _init()
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
-->8
-- settings

cursor_type = {
	block = "block",
	ibeam = "ibeam",
}

settings = {
	bg = 5, bd = 8,
	cs = 8, ct = cursor_type.ibeam,

	lsh = true,
	lcl = 6,
}
-->8
-- editing

editing = {}

function editing:init()
	self.pos = {
		ln = 1, cm = 0,
	}
		
	self.cursor = {
		show = true,
		
		blink_time = 0,
		blink_timeout = 0.25,
	}
end

function editing:update()
	-- position
	if btnp(➡️) then
		self.pos.cm += 1
	elseif btnp(⬅️) then
		if self.pos.cm >= 1 then 
			self.pos.cm -= 1
		end
	end
	
	if btnp(⬆️) then
		if self.pos.ln > 1 then
			self.pos.ln -= 1
		end
	elseif btnp(⬇️) then
		self.pos.ln += 1
	end
	
	-- cursor blinking
	local cur = self.cursor
	cur.blink_time += dt
	if cur.blink_time >= cur.blink_timeout then
		cur.show = not cur.show
		cur.blink_time = 0
	end
end

function editing:draw()
	cls(settings.bg)
	
	local cy = self.pos.ln * 8
	
	-- line background
	rectfill(
		0, cy,
		128, cy + 7, 1
	)
	
	-- draw cursor
	if self.cursor.show then
		local cx = self.pos.cm * 8 
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
end

__gfx__
00000000444444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000444444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700444444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000444444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000444444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700444444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000444444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000444444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
