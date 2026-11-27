extends TestCase


func test_new_campaign_does_not_overwrite_existing_save() -> void:
	var path := "user://campaign_creation_test.json"
	DirAccess.remove_absolute(path)
	var profile := ContentProfile.new()
	check_eq(CampaignCreation.create({},profile,false,true,false,path),"")
	var progress := CampaignProgress.new()
	check(progress.load_save(path))
	check_eq(progress.data["games"],0)
	var original := FileAccess.get_file_as_string(path)
	check(not CampaignCreation.create({},profile,false,true,false,path).is_empty())
	check_eq(FileAccess.get_file_as_string(path),original)
	DirAccess.remove_absolute(path)


func test_disabled_story_does_not_write_partial_campaign() -> void:
	var path := "user://campaign_creation_story_test.json"
	DirAccess.remove_absolute(path)
	check(not CampaignCreation.create({},ContentProfile.new(),true,true,false,path).is_empty())
	check(not FileAccess.file_exists(path))
