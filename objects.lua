boost_gfx = new_type()
boost_gfx.t = 0
boost_gfx.anchor = nil -- set this to player 
boost_gfx.boost_count = 0
function boost_gfx.update(self)
    if (self.boost_count < 4 and self.t < 3 and self.t % 2 == 0) or (self.boost_count == 4 and self.t < 7 and self.t % 2 ) then
        local ox = flr(rnd(5)) - 2 + (self.anchor.speed_x * _sgn(self.anchor.speed_x))
        local oy = flr(rnd(5)) - 2 + (self.anchor.speed_y * _sgn(self.anchor.speed_y))
        local bc = create(boost_cloud, self.anchor.x - 1 + ox, self.anchor.y - 4 + oy)
        bc.boost_count = self.boost_count
    end
    self.t += 1
    if self.t >= 16 then self.destroyed = true end
end
function boost_gfx.draw(self) end -- drawing is done in boost_gfx.clouds

boost_cloud = new_type()
boost_cloud.boost_count = 0
function boost_cloud.init(self)
    self.t = 0
    self.circles = {}
    self.circles[1] = { x = -1 - flr(rnd(3)), y = -1 - flr(rnd(3)), r = flr(rnd(3)) + 1 } --up left
    self.circles[2] = { x = 1 + flr(rnd(3)), y = -1 - flr(rnd(3)), r = flr(rnd(3)) + 1 } --up right
    self.circles[3] = { x = -1 - flr(rnd(3)), y = 1 + flr(rnd(3)), r = flr(rnd(3)) + 1 } --down left
    self.circles[4] = { x = 1 + flr(rnd(3)), y = 1 + flr(rnd(3)), r = flr(rnd(3)) + 1 } --down right
end
function boost_cloud.update(self)
    if self.t >= 8 then 
        self.destroyed = true
        self.circles = nil 
        return
    end
    for c in all(self.circles) do
        if (self.t - 1) % 2 == 0 then c.r = max(c.r - 1) end
    end
    self.t += 1
end
function boost_cloud.draw(self)
    local fill_color = 7 -- white
    if self.boost_count == 1 then fill_color = 10 -- yellow
    elseif self.boost_count == 2 then fill_color = 9 -- orange
    elseif self.boost_count >= 3 then fill_color = 8 end -- red
    
    for c in all(self.circles) do
        circfill(c.x + self.x, c.y + self.y, c.r + 1, 0)
        circfill(c.x + self.x, c.y + self.y, c.r, fill_color)
    end
end

snowflake = new_type()
function snowflake.init(self)
    self.r = flr(rnd(2))
    self.speed_y = 0.2 + rnd(0.5)
    self.offset = rnd(1)
end
function snowflake.update(self)
    self.y += self.speed_y    
    self.y = self.y > camera_y + 129 and camera_y - 1 or self.y
    if self.x < camera_x - 64 then self.x = camera_x + 128 + 64
    elseif self.x > camera_x + 128 + 64 then self.x = camera_x - 64 end
end
function snowflake.draw(self)
    circfill(self.x+sin(time()+self.offset), self.y, self.r, 6)
end

carrot = new_type(12)
carrot.r = 0
carrot.hit_x = 1
carrot.hit_y = 1
carrot.hit_w = 6
carrot.hit_h = 6
function carrot.update(self)
    if self.collected then
        self.t += 1
        self.y -= self.t % 5 == 0 and 1 or 0
        self.destroyed = self.t > 32
    elseif self.player then
		self.x += (self.player.x - self.x) / 8
		self.y += (self.player.y - 4 - self.y) / 8
		self.flash -= 1

		if self.player.state == 0 then self.ground += 1 else self.ground = 0 end

		if self.ground > 3 or self.player.x > level_ox + 126 or self.player.last_carrot != self then
			collected[self.id] = true
			carrot_count += 1
			self.collected = true
			self.t = 0
		end
	end
    self.r = (self.r + 1) % 100
end
function carrot.collect(self, player)
	if not self.player then
		self.player = player
		player.last_carrot = self
		self.flash = 6
        self.y = self.y + sin(time()) * 2
		self.ground = 0
	end
end
function carrot.draw(self)
    local mag = self.player and self.flash/2 or 3
    if mag > 0 then
        for i=0,3 do
            local uca = i * 0.25
            uca = flr(uca*1000)/1000
            uca = rot(uca, 0.01 * self.r, i * 0.25 - 0.01)
            circfill(self.x + 3 - cos(uca) * mag, self.y + 3 + sin(time()) * 2 - sin(uca) * mag, 2, 7)
        end
    end
    if self.collected and self.t > 3 then 
        if self.t % 8 < 4 or self.t < 10 then pal(8,15) end
        if self.t < 20 then spr(14, self.x, self.y) 
        elseif self.t < 23 then rectfill(self.x+2, self.y+2, self.x+4, self.y+5, 8) 
        elseif self.t < 26 then rectfill(self.x+1, self.y+4, self.x+5, self.y+4, 8) end
        pal(8,8)
        if self.t > 26 then print("+1", self.x, self.y+2, 0) end
    else
        spr(self.spr, self.x, self.y + sin(time()) * 2)
    end
end

-- copies code from boost_cloud -- can any be put in a shared function?
splash = new_type()
function splash.init(self)
    self.t = 0
    self.circles = {}
    self.circles[1] = { x = -1 - flr(rnd(3)), y = -1 - flr(rnd(3)), r = flr(rnd(3)) + 1, speed_x = -flr(rnd(2)) - 1, speed_y = -flr(rnd(2)) - 1} --up left
    self.circles[2] = { x = 1 + flr(rnd(3)), y = -1 - flr(rnd(3)), r = flr(rnd(3)) + 1, speed_x = flr(rnd(2)) + 1, speed_y = -flr(rnd(2)) - 1} --up right
    self.circles[3] = { x = -1 - flr(rnd(3)), y = 1 + flr(rnd(3)), r = flr(rnd(3)) + 1, speed_x = -flr(rnd(2)) - 1, speed_y = -flr(rnd(2)) - 1} --down left
    self.circles[4] = { x = 1 + flr(rnd(3)), y = 1 + flr(rnd(3)), r = flr(rnd(3)) + 1, speed_x = flr(rnd(2)) + 1, speed_y = -flr(rnd(2)) - 1} --down right
end
function splash.update(self)
    if self.t == 8 then 
        self.destroyed = true 
        self.circles = nil
        return
    end
    self.x += self.speed_x
    self.y += self.speed_y
    for c in all(self.circles) do
        if self.t > 0 and self.t % 2 == 0 then c.r = c.r > 0 and c.r - 1 or 0 end
        c.x += c.speed_x
        c.y += c.speed_y
        c.speed_x = abs(c.speed_x) > 0 and c.speed_x - (sgn(c.speed_x)*.5) or 0
        c.speed_y = c.speed_y < 3 and c.speed_y + .5 or 0
    end
    self.t += 1
end
function splash.draw(self)
    for c in all(self.circles) do
        circfill(c.x + self.x, c.y + self.y, c.r + 1, 7)
        circfill(c.x + self.x, c.y + self.y, c.r, 1)
    end
end

cracked_ice = new_type(17)
cracked_ice.sustained_player_weight = false
function cracked_ice.draw(self)
    object.draw(self)
end

moving_ice = new_type()
moving_ice.edge = false
function moving_ice.init(self, spr)
    if spr == 15 then -- up
        self.speed_y = -0.5
    elseif spr == 18 then -- down
        self.speed_y = 0.5
    elseif spr == 30 then -- left
        self.speed_x = -0.5
    elseif spr == 31 then -- right
        self.speed_x = 0.5
    end
end
function moving_ice.update(self)
    if not player_dead then
        self:move_x(self.speed_x, nil, true)
        self:move_y(self.speed_y, nil, true)
        if self.speed_x < 0 and self.x <= level_ox - 8 then
            self.x = level_ox + 128
        elseif self.speed_x > 0 and self.x >= level_ox + 128 and level_index < 19 then
            self.x = level_ox - 8
        elseif self.speed_x > 0 and self.x > 32 and level_index == 19 then
            self.destroyed = true
        end
        if self.speed_y < 0 and self.y <= level_oy - 8 then
            self.y = level_oy + 128
        elseif self.speed_y > 0 and self.y >= level_oy + 128 then
            self.y = level_oy - 8
        end
    end 
end
function moving_ice.draw(self)
    spr(16, self.x, self.y)
    if self.edge then 
        palt(13,true) spr(5, self.x, self.y+8) palt(13,false)
    end
end

hole_in_ice = new_type()
hole_in_ice.has_player = false
hole_in_ice.t = 0
function hole_in_ice.init(self, spr)
    -- spr 5 is water with edge, 4 is without edge
    if spr then 
        self.spr = spr
        return
    end

    local hole_above = fget(mget(self.x/8, self.y/8-1), 2) or self.y == level_oy
    local hole_below = nil
    
    for h in all(non_map_holes) do
        if not hole_above then
            if self:overlaps(h, 0, -1) then
                hole_above = true
            end
        end
        if not hole_below then
            if h.x == self.x and h.y == self.y + 8 then
                hole_below = h
            end
        end
    end

    if hole_above then self.spr = 4 else self.spr = 5 end

    if hole_below then hole_below.spr = 4 end
end
function hole_in_ice.draw(self)
    if self.dont_draw then return end
    if self.draw_edge then self.spr = 5 end
    object.draw(self)
end
function hole_in_ice.dunk_player(self, p)
    self.has_player = true
    for i=1,2 do create(splash, self.x+4, self.y+2) end
    p:die()
end

warning_sign = new_type(40)
warning_sign.t_onscreen_display = 0
warning_sign.hit_x = -16
warning_sign.hit_y = -8
warning_sign.hit_w = 40
warning_sign.hit_h = 32
function warning_sign.draw(self)

    local t = self.t_onscreen_display - 2
    
    if t > 0 then
        local first_line = sub("danger", 0, t > 0 and t/3 or 0) -- done at t = 18
        local second_line = sub("-- thin ice --", 0, t > 18 and (t-18)/3 or 0) -- done at t = 60
        local third_line = sub("keep off", 0, t > 60 and (t-60)/3 or 0)
        
        if #first_line > 0 then
            rectfill(camera_x + 61 - (#first_line * 4 / 2) - 3, camera_y + 51, camera_x + 61 + (#first_line * 4 / 2) + 1, camera_y + 61, 0)
            rectfill(camera_x + 61 - (#first_line * 4 / 2) - 2, camera_y + 52, camera_x + 61 + (#first_line * 4 / 2), camera_y + 60, 10)
            print(first_line, camera_x + 61 - #first_line * 4 / 2, camera_y + 54, 0)
        end

        if #second_line > 0 then
            rectfill(camera_x + 61 - (#second_line * 4 / 2) - 3, camera_y + 66, camera_x + 61 + (#second_line * 4 / 2) + 1, camera_y + 76, 0)
            rectfill(camera_x + 61 - (#second_line * 4 / 2) - 2, camera_y + 67, camera_x + 61 + (#second_line * 4 / 2), camera_y + 75, 10)
            print(second_line, camera_x + 61 - #second_line * 4 / 2, camera_y + 69, 0)
        end

        if #third_line > 0 then
            rectfill(camera_x + 61 - (#third_line * 4 / 2) - 3, camera_y + 81, camera_x + 61 + (#third_line * 4 / 2) + 1, camera_y + 91, 0)
            rectfill(camera_x + 61 - (#third_line * 4 / 2) - 2, camera_y + 82, camera_x + 61 + (#third_line * 4 / 2), camera_y + 90, 10)
            print(third_line, camera_x + 61 - #third_line * 4 / 2, camera_y + 84, 0)
        end
    end
end

tutorial_fish = new_type(8)
tutorial_fish.t_onscreen_display = 0
tutorial_fish.hit_x = -8
tutorial_fish.hit_y = -8
tutorial_fish.hit_w = 24
tutorial_fish.hit_h = 24
function tutorial_fish.draw(self)
    local t = self.t_onscreen_display
    self.spr = 4

    rectfill(self.x, self.y, self.x+7, self.y+7, 13)
    if t > 0 and t <= 2 then
        self.spr = 8
    elseif t > 2 and t <= 6 then
        self.spr = 9
    elseif t > 6 then
        self.spr = (t-7) % 10 < 5 and 10 or 9

        -- word balloon
        circfill(self.x+14, self.y-12, (t-6) < 9 and t-6 or 9, 0)
        circfill(self.x-6, self.y-12, (t-6) < 9 and t-6 or 9, 0)
        rectfill(self.x-4, self.y-12 - ((t-6) < 9 and t-6 or 9), self.x+12, self.y-12 + ((t-6) < 9 and t-6 or 9), 0)
        rectfill(self.x+3, self.y-12, self.x+5, self.y-10+((t-6) < 9 and t-6 or 9), 0)

        circfill(self.x+14, self.y-12, (t-7) < 8 and t-7 or 8, 10)
        circfill(self.x-6, self.y-12, (t-7) < 8 and t-7 or 8, 10)
        rectfill(self.x-4, self.y-12 - ((t-7) < 8 and t-7 or 8), self.x+12, self.y-12 + ((t-7) < 8 and t-7 or 8), 10)
        rectfill(self.x+4, self.y-12, self.x+4, self.y-10+((t-7) < 8 and t-7 or 8), 10)
        
        if t > 15 then
            -- button icon
            rectfill(self.x+9, self.y-16, self.x+15, self.y-9, 5)
            rectfill(self.x+9, self.y-16, self.x+15, self.y-10, 6)

            spr(2, self.x-8, self.y-16)
            print("+", self.x+3, self.y-14, 0)
            print("x", self.x+11, self.y-15, 0)
        end
    end
    object.draw(self)
end

