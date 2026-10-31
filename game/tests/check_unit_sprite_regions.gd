extends SceneTree
const Art = preload("res://scripts/sky_art.gd")
func _initialize() -> void:
	var art = Art.new()
	art.load_atlases()
	assert(art.region_manifest.size()==64,"Every atlas slot needs measured integer bounds")
	for i in range(61):
		var entry: Dictionary = art.region_manifest[i]
		assert(int(entry["id"])==i)
		assert(int(entry["foreign_pixels"])==0,"A neighbouring silhouette remains in unit %d" % i)
		assert(float(entry["retained_fraction"])>=0.97,"Crop removed too much of unit %d" % i)
		var rect: Array = entry["rect"]
		assert(int(rect[2])>100 and int(rect[3])>100)
		assert(art.regions[i].filter_clip)
		if i<49: assert(art.unit_texture(i)!=null)
	quit()
