extends KinematicBody2D

# Movement
var tween = null # Moves the player from current to next tile smoothly
var is_moving = false # Prevents moving outside of tile positions

# Nodes
onready var ui_node = get_parent().get_node("ui")
onready var anim_node = get_node("animation_player")

# Ready
func _ready():
	update_total_baloneys()
	pass


# Using fixed process so player can hold down buttons for movement
func _fixed_process(delta):
	if(!is_moving):
		if(Input.is_action_pressed("ui_left")):
			move(global.DIRECTION.LEFT)
		elif(Input.is_action_pressed("ui_right")):
			move(global.DIRECTION.RIGHT)
		elif(Input.is_action_pressed("ui_up")):
			move(global.DIRECTION.UP)
		elif(Input.is_action_pressed("ui_down")):
			move(global.DIRECTION.DOWN)

var facing = global.DIRECTION.RIGHT

# Move player with tween
func move(direction):
	# Do pre_move calculations
	if(pre_move(direction)):
		# Toggle to prevent unfinished movement before new movement
		is_moving = true 
		
		# Store facing direction
		facing = direction
		
		# Get current position
		var pos = get_pos()
		
		# Add directional change to position
		if(direction == global.DIRECTION.LEFT):
			if(in_water):
				anim_node.play("walk_left_in_water")
			else:
				anim_node.play("walk_left")
			pos.x -= global.config["tile_size"]
		
		elif(direction == global.DIRECTION.RIGHT):
			if(in_water):
				anim_node.play("walk_right_in_water")
			else:
				anim_node.play("walk_right")
			pos.x += global.config["tile_size"]
		
		elif(direction == global.DIRECTION.UP):
			if(in_water):
				anim_node.play("walk_up_in_water")
			else:
				anim_node.play("walk_up")
			pos.y -= global.config["tile_size"]
		
		elif(direction == global.DIRECTION.DOWN):
			if(in_water):
				anim_node.play("walk_right_in_water")
			else:
				anim_node.play("walk_right")
			pos.y += global.config["tile_size"]
		
		# Tween from original position to new position
		if(tween == null): # Create once
			tween = Tween.new()
			get_parent().add_child(tween)
			tween.connect("tween_complete", self, "_move_complete")
		tween.interpolate_property(self, "transform/pos", get_pos(), pos, global.player_speed, Tween.TRANS_LINEAR, Tween.TRANS_LINEAR)
		tween.start()


# Activated by Tween after movement is complete
func _move_complete(tween, key):
	if(!on_ice):
		is_moving = false
	
	# Stop animation
	anim_node.stop_all()
	
	if(!on_ice):
		if(facing == global.DIRECTION.UP):
			if(in_water):
				anim_node.play("idle_up_in_water")
			else:
				anim_node.play("idle_up")
		if(facing == global.DIRECTION.DOWN):
			if(in_water):
				anim_node.play("idle_right_in_water")
			else:
				anim_node.play("idle_right") # TODO: Replace with idle down
		if(facing == global.DIRECTION.LEFT):
			if(in_water):
				anim_node.play("idle_left_in_water")
			else:
				anim_node.play("idle_left")
		if(facing == global.DIRECTION.RIGHT):
			if(in_water):
				anim_node.play("idle_right_in_water")
			else:
				anim_node.play("idle_right")



# Returns true if player can move in the requested direction
func pre_move(direction):
	if(!is_moving):
	
		var tile_pos = null
		var tilemap_world = get_parent().get_node("world")
		var tilemap_entity = get_parent().get_node("entities")
		
		if(tilemap_world != null):
			# Get tile coordinate of where you currently are
			tile_pos = tilemap_world.world_to_map(get_pos())
		
		# Check if we have a solid block in the next block
		if(direction == global.DIRECTION.LEFT):
			tile_pos.x -= 1
		elif(direction == global.DIRECTION.RIGHT):
			tile_pos.x += 1
		elif(direction == global.DIRECTION.UP):
			tile_pos.y -= 1
		elif(direction == global.DIRECTION.DOWN):
			tile_pos.y += 1
		
		# Check if tile is solid
		for t in global.SOLID_TILES["WORLD"]:
			if(t == tilemap_world.get_cellv(tile_pos)):
				return false
		
		for t in global.SOLID_TILES["ENTITIES"]:
			if(t == tilemap_entity.get_cellv(tile_pos)):
				# If it is a door, and we got the key, destroy door
				if(t == global.ENTITIES.DOOR.SPADE):
					if(global.inventory["KEYS"]["SPADE"] > 0):
						global.inventory["KEYS"]["SPADE"] -= 1 # reduce by one
						tilemap_entity.set_cellv(tile_pos, -1)
						ui_node.update_keys()
					else:
						return false
				elif(t == global.ENTITIES.DOOR.DIAMOND):
					if(global.inventory["KEYS"]["DIAMOND"] > 0):
						global.inventory["KEYS"]["DIAMOND"] -= 1 # reduce by one
						tilemap_entity.set_cellv(tile_pos, -1)
						ui_node.update_keys()
					else:
						return false
				elif(t == global.ENTITIES.DOOR.CLUB):
					if(global.inventory["KEYS"]["CLUB"] > 0):
						global.inventory["KEYS"]["CLUB"] -= 1 # reduce by one
						tilemap_entity.set_cellv(tile_pos, -1)
						ui_node.update_keys()
					else:
						return false
				elif(t == global.ENTITIES.DOOR.HEART):
					if(global.inventory["KEYS"]["HEART"] > 0):
						global.inventory["KEYS"]["HEART"] -= 1 # reduce by one
						tilemap_entity.set_cellv(tile_pos, -1)
						ui_node.update_keys()
					else:
						return false
				
				# We have a pushable block
				elif(t == global.ENTITIES.BLOCK.PUSHABLE_BLOCK):
					# Check if we have a solid block in the next block
					var move_to_pos = tile_pos
					if(direction == global.DIRECTION.LEFT):
						move_to_pos.x -= 1
					elif(direction == global.DIRECTION.RIGHT):
						move_to_pos.x += 1
					elif(direction == global.DIRECTION.UP):
						move_to_pos.y -= 1
					elif(direction == global.DIRECTION.DOWN):
						move_to_pos.y += 1
					
					# Making sure there is nothing else in the position where we want to move the block
					if(tilemap_entity.get_cellv(move_to_pos) == -1):
						# If there is something solid, we dont move
						for c in global.SOLID_TILES["WORLD"]:
							if(tilemap_world.get_cellv(move_to_pos) == c):
								return false # Something is in the way, we cannot move
						
						# Check for water
						if(tilemap_world.get_cellv(move_to_pos) == global.WORLD.WATER):
							# Remove pushing block
							tilemap_entity.set_cellv(tile_pos, -1)
			
							# Remove water instance
							for c in get_parent().get_node("world").get_children():
								# Remove water scene with same pos as the new tile pos
								if(c.get_pos() == tilemap_world.map_to_world(move_to_pos)):
									c.queue_free()
							
							# Add submerged block
							tilemap_world.set_cellv(move_to_pos, global.WORLD.SUBMERGED_BLOCK)
						else:
							# All clear! Moving block
							tilemap_entity.set_cellv(tile_pos, -1)
							tilemap_entity.set_cellv(move_to_pos, 10)
					else:
						# TODO: Play sound to indicate failure to push
						# ..
						return false
				else:
					return false
		
		# Check if there are any items we can pickup
		var tile_id = tilemap_entity.get_cellv(tile_pos)
		
		# Diamond
		if(tile_id == global.ENTITIES.KEY.DIAMOND):
			global.inventory["KEYS"]["DIAMOND"] += 1
			tilemap_entity.set_cellv(tile_pos, -1)
			ui_node.update_keys()
			
		# Spade
		elif(tile_id == global.ENTITIES.KEY.SPADE):
			global.inventory["KEYS"]["SPADE"] += 1
			tilemap_entity.set_cellv(tile_pos, -1)
			ui_node.update_keys()
		
		# Club
		elif(tile_id == global.ENTITIES.KEY.CLUB):
			global.inventory["KEYS"]["CLUB"] += 1
			tilemap_entity.set_cellv(tile_pos, -1)
			ui_node.update_keys()
		
		# Heart
		elif(tile_id == global.ENTITIES.KEY.HEART):
			global.inventory["KEYS"]["HEART"] += 1
			tilemap_entity.set_cellv(tile_pos, -1)
			ui_node.update_keys()
		
		# Baloney
		elif(tile_id == global.ENTITIES.BALONEY):
			# Add to inventory
			global.inventory.BALONEY.CURRENT += 1
			
			# Update baloney in UI
			ui_node.update_baloney()
			
			# Add baloney on the sandwich!
			get_parent().get_parent().add_baloney()
			
			# Remove baloney
			tilemap_entity.set_cellv(tile_pos, -1)
		
		# Anti Water Item
		elif(tile_id == global.ENTITIES.ITEM.ANTI_WATER):
			# Add to inventory
			global.inventory.ITEMS.ANTI_WATER += 1
			
			# Update UI
			ui_node.update_items()
			
			# Remove item
			tilemap_entity.set_cellv(tile_pos, -1)
		
		# Anti Fire Item
		elif(tile_id == global.ENTITIES.ITEM.ANTI_FIRE):
			# Add to inventory
			global.inventory.ITEMS.ANTI_FIRE += 1
			
			# Update UI
			ui_node.update_items()
			
			# Remove item
			tilemap_entity.set_cellv(tile_pos, -1)
		
		# Anti Ice Item
		elif(tile_id == global.ENTITIES.ITEM.ANTI_ICE):
			# Add to inventory
			global.inventory.ITEMS.ANTI_ICE += 1
			
			# Update UI
			ui_node.update_items()
			
			# Remove item
			tilemap_entity.set_cellv(tile_pos, -1)
		
		# Anti Slide item
		elif(tile_id == global.ENTITIES.ITEM.ANTI_SLIDE):
			# Add to inventory
			global.inventory.ITEMS.ANTI_SLIDE += 1
			
			# Update UI
			ui_node.update_items()
			
			# Remove item
			tilemap_entity.set_cellv(tile_pos, -1)
		return true

# Triggered by walking on a sandwich
func walked_on_goal():
	print("Walked on goal")
	# If we have all baloneys # -----------------------------------------------------<_<-<-<-<--<_<->_-><_ REMEMBER TO FIX WHEN DONE DEBUGGING
	if(global.inventory.BALONEY.CURRENT != global.inventory.BALONEY.TOTAL):
		# Inform level manager of victory
		get_parent().get_parent().victory()

# Triggered by walking on water
var in_water = false
func in_water():
	# Player is in water! Check if he has the item needed
	if(global.inventory.ITEMS.ANTI_WATER > 0):
		# TODO: Change to swimming animations
		in_water = true
		pass
	else:
		# Death awaits us!
		get_parent().get_parent().death()
		pass

func out_of_water():
	in_water = false

func death():
	get_parent().get_parent().death()

# Player steps on fire
func in_fire(fire_node):
	# Player is in the fire! Check if he has the item needed to put it out
	if(global.inventory.ITEMS.ANTI_FIRE > 0):
		# TODO: Play some smoke animations (poof! Gone!)
		
		# Remove fire
		fire_node.queue_free()
	else:
		# Death awaits us!
		get_parent().get_parent().death()


# Counts and sets the total number of baloneys there is on the map
func update_total_baloneys():
	var tilemap_entities = get_parent().get_node("entities")
	var used_cells = tilemap_entities.get_used_cells()
	
	# For each baloney we find, increment total until we have counted them all
	for c in used_cells:
		if(tilemap_entities.get_cellv(c) == 9):
			global.inventory["BALONEY"]["TOTAL"] += 1
	
	ui_node.update_baloney()


# Handling ON ICE
var previous_pos = null
var on_ice = false

func set_ice(boolean):
	on_ice = boolean
	
	if(boolean):
		is_moving = true

func on_ice():
	if(global.inventory.ITEMS.ANTI_ICE > 0):
		on_ice = false
		is_moving = false
	else:
		var next_pos = get_pos()
		on_ice = true
		# NORTH
		var north_pos = next_pos
		north_pos.y -= global.config.tile_size
		
		# Is there an ICE tile?
		var cell_pos = get_parent().get_node("world").world_to_map(north_pos)
		var cell_id = get_parent().get_node("world").get_cellv(cell_pos)
		
		if(cell_id == global.WORLD.ICE && previous_pos != north_pos):
			# Move north
			previous_pos = get_pos()
			#set_pos(north_pos)
			
			# Tween from original position to new position
			if(tween == null): # Create once
				tween = Tween.new()
				get_parent().add_child(tween)
				# tween.connect("tween_complete", self, "_move_complete")
			tween.interpolate_property(self, "transform/pos", get_pos(), north_pos, global.player_speed / 1.2, Tween.TRANS_LINEAR, Tween.TRANS_LINEAR)
			tween.start()
			
			
			return
		
		# ------------
		
		# EAST
		var east_pos = next_pos
		east_pos.x += global.config.tile_size
		
		# Is there an ICE tile there?
		var cell_pos = get_parent().get_node("world").world_to_map(east_pos)
		var cell_id = get_parent().get_node("world").get_cellv(cell_pos)
		
		if(cell_id == global.WORLD.ICE && previous_pos != east_pos):
			# Move north
			previous_pos = get_pos()
			
			# set_pos(east_pos)
			# Tween from original position to new position
			if(tween == null): # Create once
				tween = Tween.new()
				get_parent().add_child(tween)
				# tween.connect("tween_complete", self, "_move_complete")
			tween.interpolate_property(self, "transform/pos", get_pos(), east_pos, global.player_speed / 1.2, Tween.TRANS_LINEAR, Tween.TRANS_LINEAR)
			tween.start()
			return
	
		# ------------
		
		# SOUTH
		var south_pos = next_pos
		south_pos.y += global.config.tile_size
		
		# Is there an ICE tile there?
		var cell_pos = get_parent().get_node("world").world_to_map(south_pos)
		var cell_id = get_parent().get_node("world").get_cellv(cell_pos)
		
		if(cell_id == global.WORLD.ICE && previous_pos != south_pos):
			# Move north
			previous_pos = get_pos()
			# set_pos(south_pos)
			
			# Tween from original position to new position
			if(tween == null): # Create once
				tween = Tween.new()
				get_parent().add_child(tween)
				# tween.connect("tween_complete", self, "_move_complete")
			tween.interpolate_property(self, "transform/pos", get_pos(), south_pos, global.player_speed / 1.2, Tween.TRANS_LINEAR, Tween.TRANS_LINEAR)
			tween.start()
			return
	
		# ------------
		
		# WEST
		var west_pos = next_pos
		west_pos.x -= global.config.tile_size
		
		# Is there an ICE tile there?
		var cell_pos = get_parent().get_node("world").world_to_map(west_pos)
		var cell_id = get_parent().get_node("world").get_cellv(cell_pos)
		
		if(cell_id == global.WORLD.ICE && previous_pos != west_pos):
			# Move north
			previous_pos = get_pos()
			# set_pos(west_pos)
			
			# Tween from original position to new position
			if(tween == null): # Create once
				tween = Tween.new()
				get_parent().add_child(tween)
				# tween.connect("tween_complete", self, "_move_complete")
			tween.interpolate_property(self, "transform/pos", get_pos(), west_pos, global.player_speed / 1.2, Tween.TRANS_LINEAR, Tween.TRANS_LINEAR)
			tween.start()
			return
		
		
		# If we got here, it means there are no more ice tiles, which means we have to slide one more
		# time in order to get out of the ice
		var distance_to_move = get_pos() - previous_pos
		# set_pos(distance_to_move + get_pos())
		
		# Tween from original position to new position
		
		last_tween = Tween.new()
		last_tween.set_name("Ice tween")
		get_parent().add_child(last_tween)
		last_tween.connect("tween_complete", self, "_move_on_ice_complete")
		
		last_tween.interpolate_property(self, "transform/pos", get_pos(), distance_to_move + get_pos(), global.player_speed / 1.2, Tween.TRANS_LINEAR, Tween.TRANS_LINEAR)
		print("last tween: " + str(last_tween))
		last_tween.start()
		
		previous_pos = null


var last_tween = null

func _move_on_ice_complete(var1, var2):
	last_tween.queue_free()
	is_moving = false
	on_ice = false
	anim_node.play("idle_right")