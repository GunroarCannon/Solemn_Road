extends Node

var solana_client: SolanaClient

func _ready():
	solana_client = $SolanaClient  # Assuming added as child node
	solana_client.connect_wallet()  # Prompts mobile wallet (e.g., Phantom or Solana Mobile's)
	
	# Callback for connection
	solana_client.wallet_connected.connect(_on_wallet_connected)

func _on_wallet_connected(pubkey: String):
	print("Wallet connected: " + pubkey)
	# Now fetch balance or NFTs
	var balance = solana_client.get_balance(pubkey)
