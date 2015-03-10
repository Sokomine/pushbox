
pushbox = {}

pushbox.GOAL_NODE = 'default:mese';

minetest.register_node("pushbox:glass", {
	description = "Glass cover",
	drawtype = "glasslike_framed_optional",
	tiles = {"default_obsidian_glass.png"},
	paramtype = "light",
	is_ground_content = false,
	sunlight_propagates = true,
	sounds = default.node_sound_glass_defaults(),
	groups = {cracky=3,oddly_breakable_by_hand=3},
})

pushbox.push_crate = function( pos, node, puncher, allow_diagonal, allow_pull, dir )
	if( not( pos ) or not( node ) or not( puncher )) then
		return;
	end
	-- only punching with a normal stick is supposed to work
	local wielded = puncher:get_wielded_item();
	if( wielded:get_name() ~= "") then
		minetest.chat_send_player( name, 'You need empty hands in order to handle this crate!');
 		return;
	end
	local name = puncher:get_player_name();
	local ppos = puncher:getpos();

	if( ppos.y ~= pos.y-0.5 ) then
		minetest.chat_send_player( name, 'You need to be on the same ground level as the crate in order to be strong enough to move it.');
 		return;
	end

	local xr = pos.x - ppos.x;
	local zr = pos.z - ppos.z; 

	if( math.abs( xr ) > 1.5 or math.abs( zr ) > 1.5) then
		minetest.chat_send_player( name, 'You are too far away to handle the crate!');
		return;
	end

	if( not( allow_diagonal ) and math.abs( xr ) > 0.5 and math.abs( zr ) > 0.5 ) then
		minetest.chat_send_player( name, 'The crate cannot be moved diagonally.');
		return;
	end

	local tpos = {x=pos.x, y=pos.y, z=pos.z};

	if( math.abs( xr ) > 0.5 ) then
		if( xr < 0 ) then
			tpos.x = tpos.x - (1.0*dir);
		else
			tpos.x = tpos.x + (1.0*dir);
		end
	end
	if( math.abs( zr ) > 0.5 ) then
		if( zr < 0 ) then
			tpos.z = tpos.z - (1.0*dir);
		else
			tpos.z = tpos.z + (1.0*dir);
		end
	end

	local tnode = minetest.get_node( tpos );
	local target_is_liquid = false;
	if( tnode and tnode.name and tnode.name ~= 'air') then
	    	if( tnode and tnode.name
		   and minetest.registered_nodes[ tnode.name ]
	   	   and minetest.registered_nodes[ tnode.name ].groups
		   and minetest.registered_nodes[ tnode.name ].groups.liquid
	    	   and minetest.registered_nodes[ tnode.name ].groups.liquid > 0 ) then
			target_is_liquid = true;
		else
			minetest.chat_send_player( name, 'You push and push, but there is no space for the crate.');
			return;
		end
	end		

	local node_below = minetest.get_node( {x=tpos.x, y=tpos.y-1, z=tpos.z});
	if( not( node_below ) or not( node_below.name ) or node_below.name == 'air') then
		-- TODO: start falling down
		return;
	end

	if(    minetest.registered_nodes[ node_below.name ]
	   and minetest.registered_nodes[ node_below.name ].groups
	   and minetest.registered_nodes[ node_below.name ].groups.liquid
	   and minetest.registered_nodes[ node_below.name ].groups.liquid > 0 ) then

		-- sink one down
		tpos.y = tpos.y - 1;
	end

	-- the goal is marked by mese; indicate if the box is located on a goal marker
	if( node.name == 'pushbox:box_on_goal' or node.name == 'pushbox:box' ) then
		if( node_below.name == pushbox.GOAL_NODE ) then
			node.name = 'pushbox:box_on_goal';
			-- TODO: check if ALL boxes are on their goal marker
		else
			node.name = 'pushbox:box';
		end
	end

	minetest.set_node(  pos, {name='air'});
	-- TODO: update the old position
	minetest.add_node( tpos, node );

	-- let the player follow the chest
	pos.y = pos.y-0.5; 
--	puncher:moveto(  pos, true );
end

-- TODO: use after_place_node to make sure that placed crates light up if needed
-- TODO: add a reset button for the boxes (store where each came from?)
-- TODO: read the game format files

minetest.register_node("pushbox:box", {
	description = "Pushable Crate",
	tiles = {"darkage_box.png"},
	groups = {cracky=2, falling_node=1},
	sounds = default.node_sound_wood_defaults(),
	on_punch = function(pos, node, puncher)
		return pushbox.push_crate( pos, node, puncher, false, false, 1 );
	end,
})

minetest.register_node("pushbox:box_on_goal", {
	description = "Pushable Crate on goal",
	tiles = {"darkage_box.png^default_mese_crystal.png"},
	groups = {cracky=2, falling_node=1},
	sounds = default.node_sound_wood_defaults(),
	on_punch = function(pos, node, puncher)
		return pushbox.push_crate( pos, node, puncher, false, false, 1 );
	end,

	paramtype = "light",
	light_source = 15,
})

minetest.register_node("pushbox:box_small", {
	description = "Moveable Crate",
	tiles = {"darkage_box.png^default_stick.png"},
	groups = {cracky=2, falling_node=1},
	on_punch = function(pos, node, puncher)
		return pushbox.push_crate( pos, node, puncher, true, false, 1 );
	end,
	on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		return pushbox.push_crate( pos, node, clicker, true, true, -1 );
	end,

	drawtype = "nodebox",
	paramtype = "light",
	groups = {cracky=2, falling_node=1},
	sounds = default.node_sound_wood_defaults(),
        -- the bale is slightly smaller than a full node
	node_box = {
		type = "fixed",
		fixed = {
					{-0.45, -0.45,-0.45,  0.45,  0.45, 0.45},
					{-0.40, -0.55,-0.40, -0.35, -0.45,-0.30},
					{ 0.35, -0.55, 0.30,  0.40, -0.45, 0.40},
					{-0.40, -0.55, 0.30, -0.35, -0.45, 0.40},
					{ 0.35, -0.55,-0.40,  0.40, -0.45,-0.30},
			}
	},
	selection_box = {
		type = "fixed",
		fixed = {
					{-0.45, -0.45,-0.45,  0.45,  0.45, 0.45},
			}
	},
	is_ground_content = false,
})
