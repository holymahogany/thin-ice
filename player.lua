player = new_type(1)
player.t_walk = 0
player.t_skate = 0
player.t_motionless_on_ice = 0
player.t_since_boost = 0
player.boost_count = 0
player.current_boost_gfx = nil
player.prev_boost = { ucx=0, ucy=0 }
player.finished = false
player.t_level_wipe = 0
player.last_carrot = nil
player_dead = false
player.t_bob = 0

player.state = 0

function player.start_skate(self)
    self.state = 1
    self.t_skate = 0
    self.t_since_boost = 0
    self.boost_count = -1 -- initial boost doesn't count toward the boost count
    self:boost(self.speed_x, self.speed_y)
end

-- while skating, player gets a little more speed every time they turn 90 degrees (relative to current direction of movement)
-- if player boosts 3 times in quick succession, they can press 'x' to perform a faster 'super boost'
-- while in super boost, player won't fall down and can thus cross over water without falling into it
function player.boost(self, x_dir, y_dir, super_boost)
    if super_boost then
        self.boost_count = 4
        shake = 5
    elseif not super_boost and self.boost_count == 4 then -- boost while super boosting
        self.boost_count = 1
    elseif self.boost_count < 4 then
        -- increase boost count for 90-degree turns
        -- 180-degree turns are allowed but they don't increase boost count
        local turned_90 = true
        if input_x == 0 and self.prev_boost.ucx == 0 and input_y != 0 and input_y * -1 == self.prev_boost.ucy then turned_90 = false end
        if input_y == 0 and self.prev_boost.ucy == 0 and input_x != 0 and input_x * -1 == self.prev_boost.ucx then turned_90 = false end

        self.boost_count = (self.t_since_boost < 8 and turned_90) and min(self.boost_count + 1, 3) or 0
    end

    if self.current_boost_gfx then self.current_boost_gfx.destroyed = true end
    self.current_boost_gfx = create(boost_gfx, 0, 0)
    self.current_boost_gfx.anchor = self
    self.current_boost_gfx.boost_count = self.boost_count

    local boost_speed = self.boost_count < 4 and 2.2 or 3.2
    
    local ucx, ucy = normalize(x_dir, y_dir)
    self.speed_x, self.speed_y = denormalize(ucx, ucy, boost_speed)

    self.t_since_boost = 0
    self.prev_boost.ucx, self.prev_boost.ucy = ucx, ucy

    sfx(self.boost_count == 4 and 60 or 63, 3)
end

-- these are calculated twice, before and after movement is applied
function player.calculate_ground_collisions(self)
    self.on_ground = self:check_flag(0, 0, 7)
    self.over_water = self:check_flag(0, 0, 2)
    for o in all(non_map_holes) do
        if self:overlaps(o, 0, -1) then 
            self.over_water = true
            break
        end
    end
    self.on_ice, self.on_this_ice = self:check_flag(0, 0, 0) 
    self.on_moving_ice = false
    self.on_this_moving_ice = nil
    for o in all(all_moving_ice) do
        if self:overlaps(o, 0, -1) then 
            self.on_ice = true 
            self.on_moving_ice = true
            self.on_this_moving_ice = o
            break
        end
    end
end

function player.die(self)
    self.speed_x = 0
    self.speed_y = 0
	self.state = 99
    self.t_bob = 0
    self.draw_death_animation = true
    player_dead = true
	shake = 5
	death_count += 1
end

function player.init(self)
	self.x += 4 -- subtracted for player.draw()
	self.y += 6 -- subtracted for player.draw()
	self.hit_x = -2
	self.hit_y = -4
	self.hit_w = 4
	self.hit_h = 4

    player_inst = self
    player_dead = false

	-- camera
    lock_camera = false
	camera_x = level_ox
	camera_y = level_oy
	camera(camera_x, camera_y)

    snowflakes = {}
    for i=0,80 do
        local flake = create(snowflake, camera_x-64+rnd(256), camera_y+rnd(128))
        add(snowflakes, flake)
    end
end

function player.update(self)
	--[[
		player states:
			0 	- walking on solid ground
            1   - ice skating
			99 	- dead
			100 - finished level
	--]]

    if titlescreen_state < 2 then return end

    -- 1st call (before movement)
    self:calculate_ground_collisions()

    if self.on_ice and self.state == 0 then 
        self:start_skate()
    elseif not self.on_ice and self.on_ground and self.state == 1 then 
        self.state = 0 
        self.t_walk = 0
        self.boost_count = 0
    end
    
    if self.state == 0 then
        -- walking state

        -- set speed to zero if no input or input reverses
        if input_x == 0 or (input_x == 1 and self.speed_x < 0) or (input_x == -1 and self.speed_x > 0) then self.speed_x = 0 end
        if input_y == 0 or (input_y == 1 and self.speed_y < 0) or (input_y == -1 and self.speed_y > 0) then self.speed_y = 0 end

        -- walking x-axis
        local target_x, accel_x = 0, 0.2
        if abs(self.speed_x) > 1.8 and input_x == sgn(self.speed_x) then  
            target_x, accel_x = 1.8, 0.1
        elseif input_x != 0 then
            target_x, accel_x = 1.8, 0.4
        end

        -- walking y-axis
        local target_y, accel_y = 0, 0.2
        if abs(self.speed_y) > 1.8 and input_y == sgn(self.speed_y) then  
            target_y, accel_y = 1.8, 0.1
        elseif input_y != 0 then
            target_y, accel_y = 1.8, 0.4
        end

        -- normalize for diagonal movement
        if input_x * input_y != 0 then
            target_x, target_y = target_x * (sqrt(2)/2), target_y * (sqrt(2)/2)
        end

        self.speed_x = approach(self.speed_x, input_x * target_x, accel_x)
        self.speed_y = approach(self.speed_y, input_y * target_y, accel_y)
    
    elseif self.state == 1 then
        --ice-skating state

        -- boost
        local same_dir = input_x == self.prev_boost.ucx and input_y == self.prev_boost.ucy
        
        if consume_left_press() and not same_dir then
            self:boost(-1, 0)
        elseif consume_right_press() and not same_dir then
            self:boost(1, 0)
        elseif consume_up_press() and not same_dir then
            self:boost(0, -1)
        elseif consume_down_press() and not same_dir then
            self:boost(0, 1)
        elseif consume_sb_press() and self.boost_count == 3 then
            self:boost(self.prev_boost.ucx, self.prev_boost.ucy, true)
        else
            -- no boost
            self.t_since_boost += 1
            if (self.boost_count <= 2 and self.t_since_boost > 8) or (self.boost_count >= 3 and self.t_since_boost > 12) then 
                self.boost_count = 0 
            end

            -- apply drag, approaching zero
            local ucx, ucy, mag = normalize(self.speed_x, self.speed_y)
            if self.t_since_boost > 2 then mag = approach(mag, 0, 0.2) end
            self.speed_x, self.speed_y = denormalize(ucx, ucy, mag)
        end

        --dunk player if player is motionless and hasn't recently boosted
        if self.speed_x == 0 and self.speed_y == 0 and self.t_since_boost > 8 then
            if self.t_motionless_on_ice >= 20 then
                local new_hole_in_ice = nil
                if self.on_this_ice then 
                    new_hole_in_ice = create(hole_in_ice, self.on_this_ice.x*8, self.on_this_ice.y*8) 
                    if mget(new_hole_in_ice.x/8, new_hole_in_ice.y/8+1) == 5 then
                        local new_hole = create(hole_in_ice, new_hole_in_ice.x, new_hole_in_ice.y+8, 4)
                        add(non_map_holes, new_hole)
                    end
                else
                    local placeholder_hole = create(hole_in_ice, self.on_this_moving_ice.x, self.on_this_moving_ice.y)
                    if placeholder_hole:check_solid(0,0) then 
                        placeholder_hole.x, placeholder_hole.y = self.x - 4, self.y - 6
                        placeholder_hole:find_nearest_8x8_water(true)
                    end
                    new_hole_in_ice = create(hole_in_ice, placeholder_hole.x, placeholder_hole.y) 
                    new_hole_in_ice.draw_on_top = true
                    self.on_this_moving_ice.edge = false
                    for o in all(all_moving_ice) do
                        if o != self.on_this_moving_ice and o.x >= self.on_this_moving_ice.x and o.x < self.on_this_moving_ice.x + 8 and o.y >= self.on_this_moving_ice.y - 8 and o.y < self.on_this_moving_ice.y and o.y > level_oy - 8 then
                            new_hole_in_ice.draw_edge = true
                        end
                    end
                    placeholder_hole.destroyed = true
                end
                new_hole_in_ice:dunk_player(self)
                self.x = new_hole_in_ice.x + 4
                self.y = new_hole_in_ice.y + 6
                sfx(58, 3)
                return
            end
            self.t_motionless_on_ice += 1
        else
            self.t_motionless_on_ice = 0
        end

        self.t_skate += 1
    elseif self.state == 99 or self.state == 100 then
        -- dead / finished state
        if self.state == 100 then self.x += 1 end

        self.t_level_wipe += 1

        if self.t_level_wipe > 25 then
            if self.state == 99 then restart_level() else next_level() end
        end
        return
    end

	-- apply
	self:move_x(self.speed_x + (self.on_moving_ice and self.on_this_moving_ice.speed_x or 0), self.on_collide_x)
	self:move_y(self.speed_y + (self.on_moving_ice and self.on_this_moving_ice.speed_y or 0), self.on_collide_y)
    
    -- correct for "staircasing"
    if abs(self.speed_x) > abs(self.speed_y) - 0.1 and abs(self.speed_x) < abs(self.speed_y) + 0.1 and abs(self.speed_x) > 1 and abs(self.speed_y) > 1 then
        self:diagonal_correct()
    end

	-- facing
    if self.speed_x != 0 then self.facing_x = sgn(self.speed_x) end

    -- sprite
    if self.boost_count <= 2 then self.spr = 1
    elseif self.boost_count == 3 then self.spr = 2
    else self.spr = 3 end

    -- 2nd call (after movement)
    self:calculate_ground_collisions()

	-- object interactions
	for o in all(objects) do
        if o.base == warning_sign then
            if self:overlaps(o) then
                o.t_onscreen_display += 1
            else
                o.t_onscreen_display = 0
            end
        elseif o.base == tutorial_fish then
            if self:overlaps(o) then
                o.t_onscreen_display += 1
            else
                o.t_onscreen_display = o.t_onscreen_display > 6 and 6 or max(o.t_onscreen_display - 1)
            end 
        elseif o.base == cracked_ice then
            if self:overlaps(o, 0, 0) then
                o.sustained_player_weight = true
            else
                if o.sustained_player_weight == true then
                    o.destroyed = true
                    mset(o.x/8, o.y/8, 4)
                    local new_hole = create(hole_in_ice, o.x, o.y)
                    add(non_map_holes, new_hole)
                    new_hole.formerly_cracked_ice = true
                    if mget(new_hole.x/8, new_hole.y/8+1) == 5 then
                        local new_hole_below = create(hole_in_ice, new_hole.x, new_hole.y+8, 4)
                        add(non_map_holes, new_hole_below)
                    end
                end
            end
        elseif o.base == carrot and self:overlaps(o, 0, 0) then
            o:collect(self)
        end       
	end

	-- death (falling in water)
	if self.state < 99 then
        if self.over_water and not self.on_ice and not self.on_ground and not self.on_moving_ice and self.boost_count < 4 then
            -- find an 8x8 space over water to place the player bobbing animation
            local placeholder_hole = create(hole_in_ice, self.x - 4, self.y - 6)
            self.draw_death_animation = placeholder_hole:find_nearest_8x8_water()
            local new_hole = create(hole_in_ice, placeholder_hole.x, placeholder_hole.y)
            placeholder_hole.destroyed = true
            new_hole:dunk_player(self)
            new_hole.dont_draw = true
            self.x, self.y = new_hole.x + 4, new_hole.y + 6
            add(non_map_holes, new_hole)
            sfx(58, 3)
            return
        end
	end

	-- bounds
    if self.x < level_ox + 2 then 
        self.x = level_ox + 2 
    elseif self.x > level_ox + 126 and level_index < 19 then
		self.state = 100
        --if level_index == 2 then music(-1) end
    end
    -- special camera code for last level
    if level_index == 19 then
        if not lock_camera then
            if self.x < camera_x + 48 and self.x < 106 then
                camera_x = approach(camera_x, max(self.x - 48), 2)
            elseif self.x > camera_x + 88 and self.x < 106 then 
                camera_x = approach(camera_x, self.x - 88, 2)
            elseif self.x >= 130 then
                camera_x = approach(camera_x, 128, 3)
            end
        end
        if camera_x >= 128 and not lock_camera then 
            lock_camera = true 
        end
        if self.x < 130 and lock_camera then self.x = 130 end
        if self.x > 254 then self.x = 254 end
    end

    if self.x > 176 and self.x < 200 and self.y < 488 and self.y > 480 and not game_finished then 
        game_finished = true 
        music(24)
    end
    if game_finished and stat(46) == -1 then music(2) end

    if self.y < level_oy + 4 then
        self.y = level_oy + 4
    elseif self.y > level_oy + 128 then
        self.y = level_oy + 128
    end

	camera(camera_x, camera_y)
end

function player.on_collide_x(self, moved, target)
	if self.state == 0 or self.state == 1 then
		if sgn(target) == sgn(self.speed_x) and self:corner_correct(sgn(self.speed_x), 0, 2, 2, _sgn(self.speed_y)) then
            return false
		end
	end
	return object.on_collide_x(self, moved, target)
end

function player.on_collide_y(self, moved, target)
    if self.state == 0 or self.state == 1 then
        if sgn(target) == sgn(self.speed_y) and self:corner_correct(0, sgn(self.speed_y), 2, 1, _sgn(self.speed_x)) then
            return false
        end
    end
	return object.on_collide_y(self, moved, target)
end

function player.draw(self)
    if titlescreen_state < 2 then return end

	-- death gfx
    if self.state == 99 then
        if self.draw_death_animation then
            spr(self.t_bob % 16 < 8 and 34 or 50, self.x-4, self.y-6)
            self.t_bob += 1
        end
        return
    end

    if self.t_motionless_on_ice >= 8 then
        spr(self.spr, self.x - 5 + rnd(2), self.y - 7 + rnd(2), 1, 1, self.facing_x != 1)
    else
	    spr(self.spr, self.x - 4, self.y - 6, 1, 1, self.facing_x != 1)
    end
end