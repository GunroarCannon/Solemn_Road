extends Node

# Leaderboard IDs from your console
const CLASSIC_ID = "33256"
const HARDCORE_ID = "33257"

# -- 	mstore the ID locally ---
var current_player_id : int = -1

func _ready():
	_authenticate_player()

# 1. AUTHENTICATION (Official SDK handles persistence automatically)
func _authenticate_player():
	var authenticated = false
	while not authenticated:
		var response = await LL_Authentication.GuestSession.new().send()
		if response.success:
			authenticated = true
			current_player_id = response.player_id
			print("LootLocker Connected! ID: ", response.player_id)
		else:
			print("Auth failed. Check Internet/API Key. Retrying in 5s...")
			await get_tree().create_timer(5.0).timeout

	print("Lootlocker Hahahad")
	
# 2. UPLOAD SCORE (Universal for both modes)
# @param is_hardcore: Pass true for Hardcore, false for Classic
# Update your upload_score function in LootLockerManager.gd
func upload_score(score: int, wallet_address: String, is_hardcore: bool):
	var lb_id = HARDCORE_ID if is_hardcore else CLASSIC_ID
	
	# 1. Bundle the name and wallet into a Dictionary
	var metadata_dict = {
		"wallet": wallet_address,
		"name": DataSaver.get_data("name")
	}
	
	# 2. Convert Dictionary to a JSON string
	var metadata_string = JSON.stringify(metadata_dict)
	
	# 3. Send to LootLocker
	var response = await LL_Leaderboards.SubmitScore.new(lb_id, score, metadata_string).send()
	
	if response.success:
		print("Success! Uploaded: ", metadata_string)
	else:
		printerr("Upload Failed: ", response.error_data.message)
	
	# Fetch the current player's personal score and rank
func get_current_player_score(is_hardcore: bool):
	var lb_id = HARDCORE_ID if is_hardcore else CLASSIC_ID
	
	# We use the player's ID which was saved during authentication
	# Note: LL_Authentication.get_player_id() is a built-in SDK helper
	var player_id = current_player_id
	
	var response = await LL_Leaderboards.GetMemberRank.new(lb_id, player_id).send()
	
	if response.success:
		var data = {
			"score": response.score,
			"rank": response.rank,
			"metadata": response.metadata
		}
		print("Player's Best: ", data.score, " Rank: ", data.rank)
		return data
	else:
		printerr("Could not get player score: ", response.error_data.message)
		return null
		
# 3. FETCH TOP 10
func get_leaderboard(is_hardcore: bool):
	var lb_id = HARDCORE_ID if is_hardcore else CLASSIC_ID
	var response = await LL_Leaderboards.GetScoreList.new(lb_id, 10).send()
	
	if response.success:
		print("leader board success", response.items)
		return response.items # Array of leaderboard entries
	else:
		printerr("Fetch Failed: ", response.error_data.message)
		return []
		
func get_leaderboard_data(is_hardcore: bool, itemData = null):
	var items = itemData
	if not items:
		items = await get_leaderboard(is_hardcore) # Using your existing fetch function
	
	var processed_list = []
	
	for item in items:
		var entry = {
			"rank": item.rank,
			"score": item.score,
			"player_name": "Unknown",
			"wallet": "No Wallet"
		}
		
		# Parse the metadata JSON string
		if item.metadata != "":
			var json = JSON.new()
			var error = json.parse(item.metadata)
			if error == OK:
				var data = json.get_data()
				entry.player_name = data.get("name", "Unknown")
				entry.wallet = data.get("wallet", "No Wallet")
		
		processed_list.append(entry)
	
	print(processed_list)
	return processed_list
