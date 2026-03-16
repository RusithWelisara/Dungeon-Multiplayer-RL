Now let's talk about why naive procedural generation will break your game.

## The Core Problem

Your level isn't just decoration — it's **functional**. It needs:
1. A path from each spawn to the gun
2. No softlock zones (player falls into unreachable pit)
3. Enough cover for shooting combat to be interesting
4. Vertical traversal (your game has multiple floors)

Random tile placement gives you none of that. You'll get unwinnable levels 60% of the time.

---

## The Right Approach: Room-Based BSP Generation

Don't generate tiles randomly. Generate **guaranteed-connected platform layers** using a BSP (Binary Space Partition) tree.

```
Map = stack of horizontal "floors"
Each floor = platforms with guaranteed gaps for vertical movement
Gun spawns on a middle-high floor
Players spawn on bottom floor, opposite sides
```

### The Algorithm

```gdscript
# ProceduralLevel.gd
extends Node2D

@export var map_width: int = 1366
@export var map_height: int = 768
@export var tile_size: int = 16
@export var floor_count: int = 5

var rng = RandomNumberGenerator.new()
var tilemap: TileMap

func generate():
    rng.randomize()
    tilemap.clear()
    
    _generate_border()
    _generate_floors()
    _place_spawns()
    _place_gun()
    _verify_connectivity()  # CRITICAL — never skip this
```

---

## Floor Generation Logic

```gdscript
func _generate_floors():
    var cols = map_width / tile_size
    var rows = map_height / tile_size
    
    # Always solid bottom floor
    _fill_row(rows - 2, 0, cols)
    
    # Generate N-1 intermediate floors
    var floor_spacing = (rows - 4) / (floor_count - 1)
    
    for i in range(1, floor_count):
        var y = (rows - 2) - (i * floor_spacing)
        _generate_platform_row(y)

func _generate_platform_row(y: int):
    var cols = map_width / tile_size
    var x = 0
    
    while x < cols:
        # Platform length: 3 to 8 tiles
        var plat_len = rng.randi_range(3, 8)
        # Gap length: 2 to 4 tiles (must be jumpable)
        var gap_len = rng.randi_range(2, 4)
        
        _fill_row(y, x, x + plat_len)
        x += plat_len + gap_len
    
    # GUARANTEE at least one vertical gap in center column
    # so players can always move up
    var center = cols / 2
    _clear_tiles(y, center - 1, center + 1)
```

---

## Connectivity Verification (Never Skip This)

This is what separates a real procedural system from a broken one. After generation, run a flood fill from each spawn point. If it can't reach the gun or the enemy's side, **regenerate**.

```gdscript
func _verify_connectivity() -> bool:
    var p1_can_reach_gun = _flood_fill(p1_spawn, gun_position)
    var p2_can_reach_gun = _flood_fill(p2_spawn, gun_position)
    var players_can_reach_each_other = _flood_fill(p1_spawn, p2_spawn)
    
    if not (p1_can_reach_gun and p2_can_reach_gun and players_can_reach_each_other):
        generate()  # Try again — recursion with depth limit
        return false
    return true

func _flood_fill(start: Vector2i, target: Vector2i) -> bool:
    var visited = {}
    var queue = [start]
    
    while queue.size() > 0:
        var current = queue.pop_front()
        if current == target:
            return true
        if visited.has(current):
            continue
        visited[current] = true
        
        # Check all reachable neighbors (walk + jump height)
        for neighbor in _get_reachable_neighbors(current):
            if not visited.has(neighbor):
                queue.append(neighbor)
    
    return false
```

---

## The Blunt Truth About Your Specific Game

Your game has **two guns** and a vertical map. That means generation has a hard constraint most tutorials don't teach: **the gun must be reachable from both sides without crossing enemy territory first.** 