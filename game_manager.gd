extends Node3D;

var player : CharacterBody3D;
var starting_point: Vector3

enum PlayType {
	CLASSIC,
	HARDCORE
}

var play_type: PlayType

var wallet_address: String


# Reference to your program node
@onready var anchor = SolanaService.get_node("WalletService/SessionKeyManager/AnchorProgram")
func join_game_on_chain(amount_sol: float):
	var pid = Pubkey.new_from_string(anchor.get_pid())
	print("[JoinGame] 1. Initializing for PID: ", pid.to_string())
	
	# 1. Derive PDAs
	var state_pda = Pubkey.new_pda_bytes(["state".to_utf8_buffer()], pid)
	var vault_pda = Pubkey.new_pda_bytes(["vault".to_utf8_buffer()], pid)
	print("[JoinGame] 2. State PDA: ", state_pda.to_string())
	print("[JoinGame] 3. Vault PDA: ", vault_pda.to_string())
	
	# 2. Setup Accounts Array (Order must match your Rust JoinGame struct)
	var accounts = [
		SolanaService.wallet.get_pubkey(), 
		state_pda, 
		vault_pda, 
		SystemProgram.get_pid()
	]
	print("[JoinGame] 4. Accounts array prepared.")
	
	# 3. Arguments Dictionary
	var lamports = int(amount_sol * 1_000_000_000)
	var args = {
		"amount": AnchorProgram.u64(lamports)
	}
	
	# --- THE FIX STARTS HERE ---
	print("[JoinGame] 5. Building Instruction...")
	var ix: Instruction = anchor.build_instruction("joinGame", accounts, args)
	
	if ix == null:
		printerr("[JoinGame] FATAL: build_instruction returned null. Check your IDL!")
		return null
		
	print("[JoinGame] 6. Creating Transaction...")
	var wallet_kp = SolanaService.wallet.get_kp()
	var instructions: Array[Instruction] = [ix]
	var tx: Transaction = await SolanaService.transaction_manager.create_transaction(instructions, wallet_kp)
	print("[JoinGame] 7. Signing Transaction...")
	await SolanaService.transaction_manager.add_signature(tx, wallet_kp)
	
	print("[JoinGame] 8. Sending to Blockchain...")
	var tx_data = await SolanaService.transaction_manager.send_transaction(tx)
	
	# 4. Handle Result
	if tx_data != null:
		print("[JoinGame] Success Status: ", tx_data.is_successful())
		if not tx_data.is_successful():
			printerr("[JoinGame] Blockchain Error: ", tx_data.get_error_message())
		else:
			print("[JoinGame] Signature: ", tx_data.get_signature())
	else:
		printerr("[JoinGame] FATAL: send_transaction returned null.")
		
	return tx_data
