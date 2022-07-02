objects = {}
types = {}
lookup = {}
function lookup.__index(self, i) return self.base[i] end

object = {}
object.speed_x = 0
object.speed_y = 0
object.remainder_x = 0
object.remainder_y = 0
object.moved_x = 0
object.moved_y = 0
object.hit_x = 0
object.hit_y = 0
object.hit_w = 8
object.hit_h = 8
object.facing_x = 1
object.facing_y = 1

function object.move_x(self, x, on_collide, ignore_collision)	
    self.moved_x = 0
	self.remainder_x += x
	local mx = flr(self.remainder_x + 0.5)
	self.remainder_x -= mx

	local total = mx
	local mxs = sgn(mx)
	while mx != 0
	do
		if not ignore_collision and self:check_solid(mxs, 0) then
			if on_collide then 
				return on_collide(self, total - mx, total) 
			end
			return true
		else
			self.x += mxs
            self.moved_x += mxs
			mx -= mxs
		end
	end

	return false
end

function object.move_y(self, y, on_collide, ignore_collision)
    self.moved_y = 0
	self.remainder_y += y
	local my = flr(self.remainder_y + 0.5)
	self.remainder_y -= my
	
	local total = my
	local mys = sgn(my)
	while my != 0
	do
		if not ignore_collision and self:check_solid(0, mys) then
			if on_collide then
				return on_collide(self, total - my, total) 
			end
			return true
		else
			self.y += mys
            self.moved_y += mys
			my -= mys
		end
	end

	return false
end

-- fixes uneven diagonal movement
-- (if movement along one axis is greater than movement along the other axis,
-- the greater of the two is reduced and the extra is added to self.remainder_x/y)
function object.diagonal_correct(self)
    if abs(self.moved_x) > abs(self.moved_y) then
        local mx = (abs(self.moved_x) - abs(self.moved_y)) * sgn(self.speed_x)
		local mxs = sgn(mx)
		while mx != 0
		do
			if self:check_solid(-mxs, 0) then
				-- stop this function only. don't change self.speed_x/y
				return
			else
				self.x -= mxs
				mx -= mxs
				self.remainder_x += mxs
			end
		end
    elseif abs(moved_x) < abs(moved_y) then
        local my = (abs(moved_y) - abs(moved_x)) * sgn(self.speed_y)
		local mys = sgn(my)
		while my != 0
		do
			if self:check_solid(0, -mys) then
				-- stop this function only. don't change self.speed_x/y
				return
			else
				self.y -= mys
				my -= mys
				self.remainder_y += mys
			end
		end
        --self.y -= yd 
        --self.remainder_y += yd 
    end
end

function object.on_collide_x(self, moved, target)
	self.remainder_x = 0
	self.speed_x = 0
	return true
end

function object.on_collide_y(self, moved, target)
	self.remainder_y = 0
	self.speed_y = 0
	return true
end

function object.update() end
function object.draw(self)
	spr(self.spr, self.x, self.y, 1, 1, self.flip_x, self.flip_y)
end

--returns true if self and b have overlapping hitboxes
--hitboxes seem off-center; they extend 1 beyond the bottom and right
--but the collisions work the same way on all sides, so...???
function object.overlaps(self, b, ox, oy)
	if self == b then return false end
	ox = ox or 0
	oy = oy or 0
	return
		ox + self.x + self.hit_x + self.hit_w > b.x + b.hit_x and --self's right 1 pixel or more to the right of b's left
		oy + self.y + self.hit_y + self.hit_h > b.y + b.hit_y and --self's bottom 1 pixel or more lower than b's top
		ox + self.x + self.hit_x < b.x + b.hit_x + b.hit_w and --self's left 1 pixel or more to the left of b's right
		oy + self.y + self.hit_y < b.y + b.hit_y + b.hit_h --self's top 1 pixel or more higher than b's bottom
end

function object.contains(self, px, py)
	return
		px >= self.x + self.hit_x and
		px < self.x + self.hit_x + self.hit_w and
		py >= self.y + self.hit_y and
		py < self.y + self.hit_y + self.hit_h
end

function object.check_solid(self, ox, oy)
	return self:check_flag(ox, oy, 1)
end

-- returns true if self collides with any object with flag f
-- if true, returns (x,y) tilemap location of flagged object as 2nd parameter
function object.check_flag(self, ox, oy, f)
	ox = ox or 0
	oy = oy or 0

	--check each pixel in self's hitbox, get the tile at each pixel, return true if tile is flagged as f
	for i = tile_px(ox + self.x + self.hit_x),tile_px(ox + self.x + self.hit_x + self.hit_w - 1) do
		for j = tile_py(oy + self.y + self.hit_y),tile_py(oy + self.y + self.hit_y + self.hit_h - 1) do
			if fget(mget(i, j), f) then
				return true, { x = i, y = j} 
			end
		end
	end

	return false
end

function object.find_nearest_8x8_water(self, okay_to_overlap_moving_ice)
	for ring=0,4 do --start at 0,0 and radiate out
		for ox=-4,4 do
			for oy=-4,4 do
				if abs(ox) <= ring and abs(oy) <= ring then
					if self:check_flag(ox, oy, 7) or self:check_flag(ox, oy, 0) or self:check_flag(ox, oy, 1) then 
						goto next  -- on static ice or ground or intersecting with wall
					end

					if not okay_to_overlap_moving_ice then
						for o in all(all_moving_ice) do
							if self:overlaps(o, ox, oy) then goto next end -- on moving ice
						end
					end

					-- not on ice or solid ground or intersecting with solid
					-- if okay_to_overlap_moving_ice == true, the result may overlap with a moving ice tile
					self.x += ox 
					self.y += oy
					return true
				end

				::next::
			end
		end
	end
	return false
end

function object.corner_correct(self, dir_x, dir_y, side_dist, look_ahead, only_sign)
	look_ahead = look_ahead or 1
	only_sign = only_sign or 1

	if dir_x ~= 0 then
		for i = 1, side_dist do
			for s = 1, -2, -2 do --checks s=1 and s=-1
				if s == -only_sign then 
					goto continue_x
				end

				--only do this if s==only_sign (ie only corner_correct in one direction)
				--not self:check_solid(dir_x, i * s): true if space above/below solid corner isn't solid
				if not self:check_solid(dir_x, i * s) then
					self.x += dir_x
					self.y += i * s
					return true
				end

				::continue_x::
			end
		end
	elseif dir_y ~= 0 then
		for i = 1, side_dist do
			for s = 1, -1, -2 do
				if s == -only_sign then
					goto continue_y
				end

				if not self:check_solid(i * s, dir_y) then
					self.x += i * s
					self.y += dir_y
					return true
				end

				::continue_y::
			end
		end
	end

	return false
end

-- is each id unique?
function id(tx, ty) return level_index * 100 + flr(tx) + flr(ty) * 128 end

function create(type, x, y, custom_spr)
	local obj = {}
	obj.base = type
	obj.x = x
	obj.y = y
	obj.id = id(flr(x/8), flr(y/8))
	setmetatable(obj, lookup)
	add(objects, obj)
	if obj.init then obj.init(obj, custom_spr) end 
	return obj
end

function new_type(spr)
	local obj = {}
	if spr then obj.spr = spr end
	obj.base = object --each type inherits object
	setmetatable(obj, lookup) --enables inheritance
	if spr then types[spr] = obj end --types indexed by sprite
	return obj
end