extends GutTest
## Wallet: materials earned and spent during a run.


func test_add_and_spend() -> void:
	var wallet := Wallet.new()
	watch_signals(wallet)
	wallet.add(10)
	assert_eq(wallet.amount, 10)
	assert_true(wallet.spend(4))
	assert_eq(wallet.amount, 6)
	assert_signal_emit_count(wallet, "changed", 2)


func test_spend_more_than_owned_is_refused() -> void:
	var wallet := Wallet.new()
	wallet.add(3)
	assert_false(wallet.can_afford(4))
	assert_false(wallet.spend(4))
	assert_eq(wallet.amount, 3, "nothing spent")


func test_negative_values_are_ignored() -> void:
	var wallet := Wallet.new()
	wallet.add(-5)
	assert_eq(wallet.amount, 0)
	assert_false(wallet.spend(-1))
	assert_eq(wallet.amount, 0)


func test_scaled_amounts_keep_their_fraction() -> void:
	var wallet := Wallet.new()
	for i in 10:
		wallet.add_scaled(1, 0.6)
	assert_eq(wallet.amount, 6, "0.6 x 10 pickups = 6, nothing lost to rounding")
	wallet.add_scaled(5, 1.0)
	assert_eq(wallet.amount, 11)
