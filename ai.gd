extends Node

"""
Perfect choice 👍 Beehave is **very good** for FPS-style enemy AI.

Below is a **clear, step-by-step walkthrough** to build **FPS enemies** in **Godot 4 + Beehave**, covering:

* 👹 **Melee monsters**
* 🔫 **Ranged / shooting enemies**
* Patrol → detect → chase → attack logic

This is written assuming:

* You already know basic Godot scenes/nodes
* You already have a player with a collider
* You are using **Godot 4**

---

# 🧠 PART 1 — Install Beehave

### 1️⃣ Install

1. Open **AssetLib**
2. Search **Beehave**
3. Install → Enable plugin
4. Restart Godot

You’ll now see **Beehave nodes** available.

---

# 👾 PART 2 — Enemy Scene Setup (IMPORTANT)

Create a new enemy scene:

```
Enemy (CharacterBody3D)
├─ MeshInstance3D
├─ CollisionShape3D
├─ NavigationAgent3D
├─ BehaviorTree (Beehave)
├─ VisionRay (RayCast3D)
├─ AttackArea (Area3D)
│   └─ CollisionShape3D
```

### Why these nodes matter

* `CharacterBody3D` → movement
* `NavigationAgent3D` → pathfinding
* `BehaviorTree` → AI logic
* `RayCast3D` → vision / line of sight
* `AttackArea` → melee range detection

---

# 🧠 PART 3 — Blackboard Variables (Beehave Core)

Beehave uses a **blackboard** (shared AI memory).

Create these **Blackboard Keys** inside the BehaviorTree:

| Key Name          | Type    | Purpose          |
| ----------------- | ------- | ---------------- |
| `player`          | Node    | Player reference |
| `can_see_player`  | Bool    | Vision check     |
| `in_attack_range` | Bool    | Melee range      |
| `last_player_pos` | Vector3 | For chasing      |
| `is_ranged`       | Bool    | Melee vs shooter |

---

# 👁️ PART 4 — Vision System (Player Detection)

Attach this script to your enemy:

```gdscript
# Enemy.gd
extends CharacterBody3D

@export var vision_distance := 25.0
@onready var ray = $VisionRay
@onready var tree = $BehaviorTree

func _physics_process(_delta):
	if tree.blackboard.get("player"):
		ray.target_position = ray.to_local(
			tree.blackboard.get("player").global_position
		)
		ray.force_raycast_update()

		var can_see = ray.is_colliding() and ray.get_collider().is_in_group("player")
		tree.blackboard.set("can_see_player", can_see)

		if can_see:
			tree.blackboard.set(
				"last_player_pos",
				tree.blackboard.get("player").global_position
			)
```

Make sure your player is in the **"player" group**.

---

# 🚶 PART 5 — Movement Tasks (Beehave)

## Create a Move Task (Custom)

Create a new script:

```gdscript
extends BeehaveTask

@export var speed := 4.0

func tick(actor, blackboard):
	var agent = actor.get_node("NavigationAgent3D")
	var target = blackboard.get("last_player_pos")

	if target == null:
		return FAILURE

	agent.target_position = target
	var direction = (agent.get_next_path_position() - actor.global_position).normalized()
	actor.velocity = direction * speed
	actor.move_and_slide()

	return RUNNING
```

This task lets the enemy **chase the player**.

---

# 🧠 PART 6 — Behavior Tree Layout (CORE LOGIC)

### Root Tree Structure

```
Selector
├─ Sequence (Attack Player)
│  ├─ Condition: can_see_player == true
│  ├─ Condition: in_attack_range == true
│  ├─ Attack Task
│
├─ Sequence (Chase Player)
│  ├─ Condition: can_see_player == true
│  ├─ Move To Player
│
├─ Sequence (Search)
│  ├─ Move To Last Seen Position
│
└─ Patrol Task
```

This gives:

* Attack if close
* Chase if visible
* Search last position
* Patrol if nothing happens

---

# 👊 PART 7 — Melee Attack Task

Attach `AttackArea` detection:

```gdscript
func _on_attack_area_body_entered(body):
	if body.is_in_group("player"):
		$BehaviorTree.blackboard.set("in_attack_range", true)

func _on_attack_area_body_exited(body):
	if body.is_in_group("player"):
		$BehaviorTree.blackboard.set("in_attack_range", false)
```

### Melee Task Script

```gdscript
extends BeehaveTask

@export var damage := 15

func tick(actor, blackboard):
	var player = blackboard.get("player")
	if player == null:
		return FAILURE

	player.take_damage(damage)
	return SUCCESS
```

💡 Add cooldowns so it doesn’t spam attacks.

---

# 🔫 PART 8 — Ranged Enemy (Shooting)

### Shooting Task

```gdscript
extends BeehaveTask

@export var fire_rate := 1.0
var timer := 0.0

func tick(actor, blackboard):
	timer -= get_process_delta_time()
	if timer > 0:
		return RUNNING

	var player = blackboard.get("player")
	if player == null:
		return FAILURE

	# Raycast hit scan
	var space = actor.get_world_3d().direct_space_state
	var result = space.intersect_ray(
		actor.global_position,
		player.global_position
	)

	if result and result.collider.is_in_group("player"):
		player.take_damage(10)

	timer = fire_rate
	return RUNNING
```

---

# 🧠 PART 9 — Switching Melee vs Ranged

In the tree:

```
Selector
├─ Sequence (Ranged)
│  ├─ Condition: is_ranged == true
│  ├─ Shoot Task
│
├─ Sequence (Melee)
│  ├─ Condition: is_ranged == false
│  ├─ Melee Attack Task
```

Now the **same enemy scene** can be:

* Melee monster
* Shooter monster

Just flip `is_ranged` in the inspector.

---

# 💀 PART 10 — Horror FPS Tips (IMPORTANT)

✔ Slow melee wind-up
✔ Loud footsteps when chasing
✔ Delay before attack
✔ Enemies don’t always sprint
✔ Let enemies *lose sight* and search

Beehave excels at **tension**, not just combat.

---

# 🧩 FINAL RESULT

You now have:

* ✔ FPS-ready enemy AI
* ✔ Melee + ranged enemies
* ✔ Patrol / chase / attack logic
* ✔ Modular Behavior Tree
* ✔ Scales to bosses later

---

## 👉 Want Next?

I can:

* Give a **ready-made Behavior Tree diagram**
* Add **sound-based detection**
* Add **enemy flinching / stagger**
* Show **best horror enemy pacing**
* Help optimize for many enemies

Just tell me what you want next 👹🔦
"""
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
