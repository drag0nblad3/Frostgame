extends TestCase


func test_every_named_palette_has_a_distinct_exterior() -> void:
	var palettes:=JsonFile.read("res://data/visual_palettes.json")
	var seen: Dictionary={}
	for id: String in palettes:
		if id.begins_with("_"):
			continue
		check(ExteriorProfile.all().has(id),id)
		var p:=ExteriorProfile.get_profile(id)
		var key:=str([p.get("ground"),p.get("near"),p.get("far"),p.get("landmark")])
		check(not seen.has(key),id)
		seen[key]=true
		for quality in 3:
			for side in 4:
				var plan:=ExteriorProfile.plan(Vector2(24,36),id,quality,quality+1,side)
				check(not plan.is_empty(),id)
				check_eq(plan,ExteriorProfile.plan(Vector2(24,36),id,quality,quality+1,side))
				for entry in plan:
					check(ExteriorProfile.KINDS.has(entry["kind"]),id)
					var at: Vector2=entry["at"]
					check(not Rect2(-4,-4,32,44).has_point(at),id)
	check_eq(ExteriorProfile.get_profile("frozen_ruins"),ExteriorProfile.get_profile("treasure_skirmish"))


func test_open_escape_and_invasion_sides_differ() -> void:
	for id in ["red_king_veil","red_king_herded"]:
		var a:=ExteriorProfile.plan(Vector2(24,36),id,1,1,0)
		var b:=ExteriorProfile.plan(Vector2(24,36),id,1,1,2)
		check(a[0]["kind"]!=b[0]["kind"],id)


func test_pursuit_horizons_have_different_landmarks() -> void:
	for id in ["red_king_veil","red_king_herded"]:
		var p:=ExteriorProfile.get_profile(id)
		var landmarks: Dictionary=p["landmark_sides"]
		check(landmarks["0"]!=landmarks["2"],id)
		for side in [0,2]:
			var plan:=ExteriorProfile.plan(Vector2(24,36),id,1,1,side)
			var found:=false
			for entry in plan:
				if entry["row"]==1 and entry["kind"]==landmarks[str(side)]:
					found=true
			check(found,id)
