module maga::maga {
    use std::signer;
    use std::string::{ utf8};
    use aptos_framework::account;
    use aptos_framework::account::SignerCapability;
    use aptos_framework::coin;
    use aptos_framework::aptos_account::deposit_coins;
    use aptos_framework::coin::{BurnCapability};

    use aptos_std::math64;
    use aptos_framework::reconfiguration::current_epoch;
    use aptos_std::table::Table;
    use aptos_std::table;
    use aptos_std::math128;

    const ERR_NOT_ADMIN: u64 = 1;
    const ERR_COIN_INITIALIZED: u64 = 2;
    const ERR_COIN_NOT_INITIALIZED: u64 = 3;

    // === Errors ===
    const EDirectorIsPaused: u64 = 100;
    const EUserCounterIsRegistered: u64 = 101;
    const EUserCounterIsNotRegistered: u64 = 102;
    const EUserCounterIsClaimed: u64 = 103;

    const ADMIN_ADDR: address = @maga;
    const TREASURE_ADDR: address = @0xf437664dd95cbd131d4726538ac6fe2290d0a6f4beea98f901d5b373282281e1;

    const TOTAL_SUPPLY: u64 = 47000000000 ;
    const TREASURE: u64 = 47000000000 * 10 / 100;
    const LYQUIDITY: u64 = 47000000000 * 40 / 100;
    const BASE_REWARD: u64 = 47000000000 * 1 / 100;

    // 12 epoch ~ 1 day
    const EPOCH_PER_DAY: u64 = 1;
    const HAVING_DAY: u64 = 4;
    const HAVING_EPOCH_MUL: u64 = 2;

    struct MAGA {}

    struct AdminCap has key, store {
        signer_cap: SignerCapability
    }

    struct Director has key {
        epoch_start: u64,
        total_vote: u64,
        total_reward: u64,
        total_reward_minted: u64,
        paused: bool,
        day_counter: Table<u64, DayCounter>,
        burn_cap: BurnCapability<MAGA>,
    }

    struct DayCounter has store {
        total_vote: u64,
        total_register: u64,
        total_reward_minted: u64,
        user_counter: Table<address, UserCounter>
    }

    struct UserCounter has store, copy {
        vote_count: u64,
        registered: bool,
        reward: u64,
        claimed: bool
    }

    struct DirectorView has key {
        epoch_start: u64,
        total_vote: u64,
        total_reward: u64,
        total_reward_minted: u64,
        paused: bool
    }

    struct DayCounterView has store {
        total_vote: u64,
        total_register: u64,
        total_reward_minted: u64
    }

    fun init_module(sender: &signer) {
        let (admin_signer, signer_cap) = account::create_resource_account(sender, x"01");

        move_to(sender, AdminCap {
            signer_cap
        });

        let (burn_cap, freeze_cap, mint_cap) = coin::initialize<MAGA>(
            sender,
            utf8(b"MAGA"),
            utf8(b"MAGA Trump"),
            6,
            true,
        );

        let total_coin = coin::mint(TOTAL_SUPPLY * math64::pow(10, 6), &mint_cap);
        coin::destroy_mint_cap(mint_cap);
        coin::destroy_freeze_cap(freeze_cap);

        deposit_coins(
            ADMIN_ADDR,
            coin::extract(&mut total_coin, (TREASURE + LYQUIDITY) * math64::pow(10, 6))
        );

        let admin_addr: address = signer::address_of(&admin_signer);
        deposit_coins(admin_addr, total_coin);

        move_to(&admin_signer, Director {
            epoch_start: current_epoch(),
            total_vote: 0,
            total_reward: TOTAL_SUPPLY - LYQUIDITY - TREASURE,
            total_reward_minted: 0,
            day_counter: table::new(),
            paused: false,
            burn_cap,
        });
    }

    public entry fun vote_for_trump(
        sender: &signer
    ) acquires AdminCap, Director {
        let sender_addr = signer::address_of(sender);
        let admin_cap = borrow_global<AdminCap>(ADMIN_ADDR);
        let admin_signer = account::create_signer_with_capability(&admin_cap.signer_cap);
        let admin_addr = signer::address_of(&admin_signer);
        let director = borrow_global_mut<Director>(admin_addr);

        assert!(director.paused == false, EDirectorIsPaused);

        let day = (current_epoch() - director.epoch_start) / EPOCH_PER_DAY;

        if (!table::contains<u64, DayCounter>(&director.day_counter, day)) {
            table::add(&mut director.day_counter, day, DayCounter {
                total_vote: 0,
                total_register: 0,
                total_reward_minted: 0,
                user_counter: table::new()
            })
        };

        let day_counter = table::borrow_mut(&mut director.day_counter, day);

        if (!table::contains<address, UserCounter>(&day_counter.user_counter, sender_addr)) {
            table::add(&mut day_counter.user_counter, sender_addr, UserCounter {
                vote_count: 0,
                registered: false,
                reward: 0,
                claimed: false
            })
        };

        let user_counter = table::borrow_mut(&mut day_counter.user_counter, sender_addr);
        user_counter.vote_count = user_counter.vote_count + 1;
        director.total_vote = director.total_vote + 1;
        day_counter.total_vote = day_counter.total_vote + 1;

        let service_fee = 100;
        aptos_account::transfer(sender, TREASURE_ADDR, service_fee);
    }

    public entry fun register_user_counter(sender: &signer) acquires AdminCap, Director {
        let sender_addr = signer::address_of(sender);
        let admin_cap = borrow_global<AdminCap>(ADMIN_ADDR);
        let admin_signer = account::create_signer_with_capability(&admin_cap.signer_cap);
        let admin_addr = signer::address_of(&admin_signer);
        let director = borrow_global_mut<Director>(admin_addr);

        let day = (current_epoch() - director.epoch_start) / EPOCH_PER_DAY - 1;

        let day_counter = table::borrow_mut(&mut director.day_counter, day);
        let user_counter = table::borrow_mut(&mut day_counter.user_counter, sender_addr);

        assert!(user_counter.registered == false, EUserCounterIsRegistered);

        day_counter.total_register = day_counter.total_register + user_counter.vote_count;
        user_counter.registered = true;
    }

    public entry fun claim_user_counter(sender: &signer) acquires AdminCap, Director {
        let sender_addr = signer::address_of(sender);
        let admin_cap = borrow_global<AdminCap>(ADMIN_ADDR);
        let admin_signer = account::create_signer_with_capability(&admin_cap.signer_cap);
        let admin_addr = signer::address_of(&admin_signer);
        let director = borrow_global_mut<Director>(admin_addr);

        let day = (current_epoch() - director.epoch_start) / EPOCH_PER_DAY - 2;

        let day_counter = table::borrow_mut(&mut director.day_counter, day);
        let user_counter = table::borrow_mut(&mut day_counter.user_counter, sender_addr);
        assert!(user_counter.registered, EUserCounterIsNotRegistered);
        assert!(!user_counter.claimed, EUserCounterIsClaimed);

        let mul: u64 = 0;
        let mul_check = day / HAVING_DAY;

        while (mul_check > 0) {
            mul = mul + 1;
            mul_check = mul_check / HAVING_EPOCH_MUL;
        };

        let current_total_reward = BASE_REWARD / (math64::pow(2, mul));
        let user_reward = (math128::mul_div(
            (current_total_reward as u128),
            (day_counter.total_register as u128),
            (user_counter.vote_count as u128)
        ) as u64);

        let coins = coin::withdraw<MAGA>(&admin_signer, math64::pow(10, 6) * user_reward);
        deposit_coins(sender_addr, coins);

        user_counter.claimed = true;
        user_counter.reward = user_reward;

        day_counter.total_reward_minted = day_counter.total_reward_minted + user_reward;
        director.total_reward_minted = director.total_reward_minted + user_reward;
    }

    #[view]
    public fun get_overview(): DirectorView acquires AdminCap, Director {
        let admin_cap = borrow_global<AdminCap>(ADMIN_ADDR);
        let admin_signer = account::create_signer_with_capability(&admin_cap.signer_cap);
        let admin_addr = signer::address_of(&admin_signer);
        let director = borrow_global<Director>(admin_addr);

        DirectorView {
            epoch_start: director.epoch_start,
            total_vote: director.total_vote,
            total_reward: director.total_reward,
            total_reward_minted: director.total_reward_minted,
            paused: director.paused
        }
    }

    #[view]
    public fun get_current_day(): u64 acquires AdminCap, Director {
        let admin_cap = borrow_global<AdminCap>(ADMIN_ADDR);
        let admin_signer = account::create_signer_with_capability(&admin_cap.signer_cap);
        let admin_addr = signer::address_of(&admin_signer);
        let director = borrow_global<Director>(admin_addr);

        (current_epoch() - director.epoch_start) / EPOCH_PER_DAY + 1
    }

    #[view]
    public fun get_day_counter(day: u64): DayCounterView acquires AdminCap, Director {
        let admin_cap = borrow_global<AdminCap>(ADMIN_ADDR);
        let admin_signer = account::create_signer_with_capability(&admin_cap.signer_cap);
        let admin_addr = signer::address_of(&admin_signer);
        let director = borrow_global<Director>(admin_addr);

        let day_counter = table::borrow(&director.day_counter, day - 1);

        DayCounterView {
            total_vote: day_counter.total_vote,
            total_register: day_counter.total_register,
            total_reward_minted: day_counter.total_reward_minted
        }
    }

    #[view]
    public fun get_use_counter(day: u64, user_address: address): UserCounter acquires AdminCap, Director {
        let admin_cap = borrow_global<AdminCap>(ADMIN_ADDR);
        let admin_signer = account::create_signer_with_capability(&admin_cap.signer_cap);
        let admin_addr = signer::address_of(&admin_signer);
        let director = borrow_global<Director>(admin_addr);

        let day_counter = table::borrow(&director.day_counter, day - 1);

        *table::borrow(&day_counter.user_counter, user_address)
    }
}