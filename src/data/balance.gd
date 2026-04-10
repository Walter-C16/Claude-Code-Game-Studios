class_name Balance

const POKER_COMBAT := {
	"default_hand_size": 5,
	"default_hands": 4,
	"default_discards": 4,
	"max_play_size": 5,
}

const PROGRESSION := {
	"xp_per_battle": 50,
	"gold_per_combat": 50,
	"gold_scaling": 1.1,
}

const ROMANCE := {
	"heart_per_date": 10,
	"trust_per_good_choice": 5,
	"stage_thresholds": [0, 21, 51, 71, 91],
}

const ABYSS := {
	"max_antes": 8,
	"ante_base_targets": [300, 800, 2000, 5000, 11000, 20000, 35000, 50000],
	"blind_multipliers": { "small": 1.0, "big": 1.5, "boss": 2.0 },
	"endless_scaling": 1.6,
}

const INTIMACY := {
	"momentum_max": 20,
	"momentum_decay_ms": 1500,
	"ecstasy_max": 100,
	"scene_unlock_thresholds": [0, 30, 60],
	"speed_tiers": {
		"slow":   { "min_momentum": 0,  "rate": 0.7, "ecstasy_per_sec": 0.5 },
		"normal": { "min_momentum": 4,  "rate": 1.0, "ecstasy_per_sec": 1.0 },
		"fast":   { "min_momentum": 9,  "rate": 1.3, "ecstasy_per_sec": 2.0 },
		"climax": { "min_momentum": 16, "rate": 1.6, "ecstasy_per_sec": 3.5 },
	},
}

const SOCIAL_BUFFS := {
	"talk_good":  { "mult": 2, "chips": 0 },
	"talk_great": { "mult": 3, "chips": 10 },
	"date_good":  { "mult": 3, "chips": 0 },
	"date_great": { "mult": 5, "chips": 15 },
	"intimate":   { "mult": 5, "chips": 0 },
	"buff_duration": 1,
}

const DATES := {
	"min_relationship": 21,
	"rounds": 4,
	"base_relationship_per_round": 5,
}

# Hand base scores: { rank_enum: { "chips": N, "mult": N } }
const HAND_SCORES := {
	Enums.HandRank.HIGH_CARD:       { "chips": 5,   "mult": 1.0 },
	Enums.HandRank.PAIR:            { "chips": 10,  "mult": 2.0 },
	Enums.HandRank.TWO_PAIR:        { "chips": 20,  "mult": 2.0 },
	Enums.HandRank.THREE_KIND:      { "chips": 30,  "mult": 3.0 },
	Enums.HandRank.STRAIGHT:        { "chips": 30,  "mult": 4.0 },
	Enums.HandRank.FLUSH:           { "chips": 35,  "mult": 4.0 },
	Enums.HandRank.FULL_HOUSE:      { "chips": 40,  "mult": 4.0 },
	Enums.HandRank.FOUR_KIND:       { "chips": 60,  "mult": 7.0 },
	Enums.HandRank.STRAIGHT_FLUSH:  { "chips": 100, "mult": 8.0 },
	Enums.HandRank.ROYAL_FLUSH:     { "chips": 100, "mult": 8.0 },
	Enums.HandRank.ULTIMATE:        { "chips": 0,   "mult": 1.0 },
}
