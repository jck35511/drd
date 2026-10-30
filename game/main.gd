extends Control
const SkyArt = preload("res://scripts/sky_art.gd")
const RunStorage = preload("res://scripts/run_storage.gd")
const SIM_STEP: float = 1.0 / 60.0
var simulation_accumulator: float = 0.0
var presentation_clock: float = 0.0
var ui_clock: float = 0.0
var save_clock: float = 0.0
var paused: bool = false
var persistence_enabled: bool = true
var _in_simulation: bool = false
var pause_button: Button
var sky_art = SkyArt.new()
var attack_flashes: Dictionary = {}
var unit_gallery: PanelContainer
var _aura_signature: String = ""
var _cached_auras: Array[Dictionary] = []
var combat_fx: Array[Dictionary] = []
var visual_effects_enabled: bool = true
# Dog random defense. Step23-polished UI uses one bundled background PNG; no external plugins.
const COST: int = 20
const KILL_REWARD: int = 5
# Step8 reward draw: each of six exclusive items is exactly 3%.
# Gold rewards occupy the remaining 82%; weights halve for each multiplier.
const DRAW_COST: int = 50
const DRAW_ITEM_TICKETS: int = 3000  # out of 100000, per item
const DRAW_TICKET_TOTAL: int = 100000
const DRAW_GOLD_WEIGHTS := [1024, 512, 256, 128, 64, 32, 16, 8, 4, 2, 1] # 0x..10x; sum=2047
const DRAW_GOLD_WEIGHT_TOTAL: int = 2047
const DRAW_ITEM_IDS := [36, 37, 38, 39, 40, 41]
# Step11: independent mythic gacha (4 x 1% items, 96% gold); beast gacha remains 6 x 3%.
const MYTHIC_DRAW_ITEM_IDS := [42, 43, 44, 45]
const MYTHIC_DRAW_ITEM_TICKETS: int = 1000
# Step13: dedicated transcendent draw, three 0.1% item outcomes; 99.7% gold.
const TRANSCENDENT_DRAW_ITEM_IDS := [46, 47, 48]
const TRANSCENDENT_DRAW_ITEM_TICKETS: int = 100
const COLS: int = 6
const ROWS: int = 6
const CELL: float = 77.0
const GRID_ORIGIN := Vector2(127, 197)
const DOGS := ["말티즈", "푸들", "치와와", "비글", "시바견", "코기", "허스키", "골든리트리버", "도베르만", "사모예드", "포메라니안", "요크셔테리어", "시츄", "닥스훈트", "파피용", "비숑프리제", "미니어처핀셔", "보더콜리", "진돗개", "불독", "스피츠", "슈나우저", "웰시테리어", "바센지", "휘핏", "보스턴테리어", "셸티", "저먼셰퍼드", "래브라도리트리버", "로트와일러", "그레이트데인", "말라뮤트", "세인트버나드", "아키타", "복서", "뉴펀들랜드", "사자", "호랑이", "늑대", "재규어", "표범", "여우", "빙결의 펜리르", "태양의 레오", "뇌신의 백호", "생명의 구미호", "심연의 아몬", "천공의 라", "명계의 케르베로스"]
const GRADES := ["소형견", "소형견", "소형견", "중형견", "중형견", "중형견", "대형견", "대형견", "대형견", "대형견", "소형견", "소형견", "소형견", "소형견", "소형견", "소형견", "소형견", "중형견", "중형견", "중형견", "중형견", "중형견", "중형견", "중형견", "중형견", "중형견", "중형견", "대형견", "대형견", "대형견", "대형견", "대형견", "대형견", "대형견", "대형견", "대형견", "맹수", "맹수", "맹수", "맹수", "맹수", "맹수", "신화", "신화", "신화", "신화", "초월", "초월", "초월"]
const RECIPES := [
	{"result": 3, "materials": [0, 1, 2]},
	{"result": 4, "materials": [0, 0, 1]},
	{"result": 5, "materials": [0, 2, 10]},
	{"result": 17, "materials": [1, 2, 11]},
	{"result": 18, "materials": [0, 12, 13]},
	{"result": 19, "materials": [1, 10, 14]},
	{"result": 20, "materials": [2, 11, 15]},
	{"result": 21, "materials": [10, 12, 16]},
	{"result": 22, "materials": [11, 13, 14]},
	{"result": 23, "materials": [12, 14, 15]},
	{"result": 24, "materials": [13, 15, 16]},
	{"result": 25, "materials": [0, 14, 16]},
	{"result": 26, "materials": [1, 15, 16]},
	{"result": 6, "materials": [3, 4, 5]},
	{"result": 7, "materials": [3, 3, 17]},
	{"result": 8, "materials": [4, 5, 18]},
	{"result": 9, "materials": [3, 19, 20]},
	{"result": 27, "materials": [4, 17, 21]},
	{"result": 28, "materials": [5, 18, 22]},
	{"result": 29, "materials": [17, 19, 23]},
	{"result": 30, "materials": [18, 20, 24]},
	{"result": 31, "materials": [19, 21, 25]},
	{"result": 32, "materials": [20, 22, 26]},
	{"result": 33, "materials": [21, 23, 24]},
	{"result": 34, "materials": [22, 24, 25]},
	{"result": 35, "materials": [23, 25, 26]},
	{"result": 36, "materials": [6, 7, 27], "item": 36},
	{"result": 37, "materials": [8, 29, 33], "item": 37},
	{"result": 38, "materials": [6, 31, 34], "item": 38},
	{"result": 39, "materials": [29, 30, 32], "item": 39},
	{"result": 40, "materials": [8, 33, 34], "item": 40},
	{"result": 41, "materials": [7, 28, 35], "item": 41},
	{"result": 42, "materials": [36, 38, 39], "item": 42},
	{"result": 43, "materials": [36, 37, 40], "item": 43},
	{"result": 44, "materials": [37, 39, 41], "item": 44},
	{"result": 45, "materials": [38, 40, 41], "item": 45},
	{"result": 46, "materials": [42, 43, 39], "item": 46},
	{"result": 47, "materials": [43, 44, 36], "item": 47},
	{"result": 48, "materials": [42, 45, 38], "item": 48}
]

# Beast-exclusive item requirements. A future draw system will grant these items.
const BEAST_ITEMS := {36: "황금 사자의 문장", 37: "맹호의 송곳니", 38: "달빛 늑대의 인장", 39: "그림자 재규어의 발톱", 40: "질풍 표범의 휘장", 41: "신비한 여우 구슬", 42: "빙결의 룬", 43: "태양의 성배", 44: "뇌신의 번개석", 45: "생명의 여우옥", 46: "심연의 핵", 47: "천공의 성유물", 48: "명계의 봉인석"}
# Ordinary-dog fusion preserves the ingredients' combined base DPS; high-tier stats stay unchanged.
const ATTACK := [8,12,6,32,42,27,110,88,146,104,9,8,11,13,7,10,12,33,42,52,32,44,35,30,32,39,37,124,109,167,193,141,191,150,127,159,110,140,90,105,125,95,185,210,175,165,285,260,245]
const RANGE := [120.0, 150.0, 100.0, 160.0, 140.0, 150.0, 180.0, 200.0, 150.0, 190.0, 125.0, 110.0, 135.0, 135.0, 125.0, 140.0, 115.0, 165.0, 155.0, 130.0, 160.0, 155.0, 145.0, 150.0, 155.0, 140.0, 165.0, 185.0, 195.0, 150.0, 175.0, 180.0, 185.0, 165.0, 160.0, 190.0, 185.0, 160.0, 170.0, 160.0, 180.0, 200.0, 210.0, 185.0, 220.0, 205.0, 210.0, 230.0, 205.0]
const COOLDOWN := [0.7, 1.0, 0.5, 0.9, 1.2, 0.7, 1.0, 0.8, 1.3, 0.9, 0.65, 0.55, 0.9, 0.9, 0.5, 0.75, 0.7, 0.85, 1.1, 1.3, 0.8, 1.0, 0.8, 0.75, 0.7, 0.9, 0.85, 1.05, 0.9, 1.4, 1.55, 1.1, 1.5, 1.15, 0.95, 1.25, 1.40, 1.55, 0.95, 1.35, 1.00, 1.25, 1.50, 1.55, 1.30, 1.15, 1.55, 1.40, 1.25]
const DOG_COLORS := [Color("#f9e1a8"), Color("#e7c6fa"), Color("#f7b3a8"), Color("#cfa777"), Color("#c0e6d1"), Color("#f4d394"), Color("#a4c9f3"), Color("#f6e8bc"), Color("#d5a8a0"), Color("#f1f1e6"), Color("#a7d2f0"), Color("#f0b3c7"), Color("#d4e9a9"), Color("#f0c9a0"), Color("#f5d8a0"), Color("#d1d1d1"), Color("#c6d2e0"), Color("#a8d3b7"), Color("#c4b0d0"), Color("#e0a0a0"), Color("#d9c5a0"), Color("#d0c0d0"), Color("#c0d0d0"), Color("#d8c0a0"), Color("#d0c0b0"), Color("#c0c0d0"), Color("#d0d0a0"), Color("#e0c0a0"), Color("#d0d0c0"), Color("#e0a0c0"), Color("#d0a0e0"), Color("#e0c0d0"), Color("#d0e0a0"), Color("#e0d0a0"), Color("#d0a0d0"), Color("#9db6bf"), Color("#e6b44e"), Color("#e47c42"), Color("#a0b0bc"), Color("#906bb3"), Color("#df8bba"), Color("#8fcfdc"), Color("#94d8ff"), Color("#f5c45c"), Color("#c4dcff"), Color("#f3addb"), Color("#7943bb"), Color("#ffe18a"), Color("#9e535d")]
# Skill balance v1: independently tuned for MeongRandy, informed by genre mechanics.
# Per-attack chances are lower for stun than for damage effects to avoid stun-lock.
# Tier order: small / medium / large. These are editable balance inputs.
const SKILL_CHANCE := {"소형견": {"crit": 0.12, "bleed": 0.12, "stun": 0.05, "slow": 0.15, "multi": 0.10, "armor": 0.12, "splash": 0.10}, "중형견": {"crit": 0.18, "bleed": 0.18, "stun": 0.08, "slow": 0.22, "multi": 0.16, "armor": 0.18, "splash": 0.16}, "대형견": {"crit": 0.24, "bleed": 0.24, "stun": 0.11, "slow": 0.30, "multi": 0.22, "armor": 0.24, "splash": 0.22}}
const SKILL_POWER := {"소형견": {"crit": 1.50, "bleed": 0.08, "stun": 0.30, "slow": 0.20, "multi": 0.40, "armor": 0.08, "splash": 0.35, "aura": 0.06}, "중형견": {"crit": 1.75, "bleed": 0.12, "stun": 0.45, "slow": 0.30, "multi": 0.55, "armor": 0.12, "splash": 0.45, "aura": 0.10}, "대형견": {"crit": 2.00, "bleed": 0.16, "stun": 0.60, "slow": 0.40, "multi": 0.70, "armor": 0.16, "splash": 0.55, "aura": 0.15}}
const SKILL_NAMES := {"crit": "치명타", "bleed": "출혈", "stun": "기절", "slow": "둔화", "multi": "연속타격", "armor": "방어 약화", "splash": "범위 공격", "attack_aura": "공격력 오라", "speed_aura": "공격속도 오라", "heavy": "강력한 일격", "area_stun": "범위 기절", "hp_percent": "최대 체력 비례 피해", "magic_splash": "마법 범위 공격", "magic_res": "마법 저항 약화", "freeze": "빙결", "chain": "연쇄 번개", "burn": "지속 피해", "vulnerable": "받는 피해 증가", "magic_aura": "마법 공격력 오라", "poison": "중독", "cooldown_aura": "재사용 대기시간 감소"}
# Existing ten original dogs deliberately have no unapproved skills.
# Indices correspond to DOGS (0..35). The skill set does not change base stats.
const DOG_SKILLS := {11: ["crit"], 13: ["bleed"], 16: ["speed_aura"], 17: ["speed_aura"], 18: ["crit"], 19: ["stun"], 20: ["slow"], 21: ["bleed"], 22: ["crit"], 23: ["multi"], 24: ["slow"], 25: ["armor"], 26: ["speed_aura"], 27: ["armor"], 28: ["attack_aura"], 29: ["stun", "armor"], 30: ["splash"], 31: ["slow"], 32: ["splash", "slow"], 33: ["crit"], 34: ["multi"], 35: ["attack_aura"], 36: ["splash", "armor"], 37: ["heavy", "bleed"], 38: ["multi", "speed_aura"], 39: ["area_stun", "hp_percent"], 40: ["crit", "slow"], 41: ["magic_splash", "magic_res"], 42: ["magic_splash", "slow", "freeze"], 43: ["splash", "armor", "attack_aura"], 44: ["chain", "stun", "magic_res"], 45: ["burn", "speed_aura", "vulnerable"], 46: ["heavy", "armor", "poison", "hp_percent"], 47: ["magic_splash", "burn", "magic_res", "magic_aura"], 48: ["area_stun", "slow", "speed_aura", "cooldown_aura"]}
# Beast tier (indices 36..41): initial balance, separate from the existing 36 dogs.
# These values are design defaults and can be tuned after actual gameplay.
const BEAST_CHANCE := {"splash": 0.30, "armor": 0.28, "heavy": 0.25, "bleed": 0.30, "multi": 0.30, "area_stun": 0.12, "hp_percent": 0.16, "crit": 0.30, "slow": 0.32, "magic_splash": 0.30, "magic_res": 0.28}
const BEAST_POWER := {"splash": 0.65, "armor": 0.20, "heavy": 1.65, "bleed": 0.22, "multi": 0.75, "area_stun": 0.55, "hp_percent": 0.035, "crit": 2.20, "slow": 0.40, "magic_splash": 0.60, "magic_res": 0.20, "aura": 0.18}
# Mythic tier v1: three distinct effects per unit, 42..45.
# Values are provisional tuning defaults; no crafting or normal-summon access in Step10.
const MYTHIC_CHANCE := {"magic_splash": 0.42, "slow": 0.40, "freeze": 0.16, "splash": 0.42, "armor": 0.36, "chain": 0.40, "stun": 0.17, "magic_res": 0.36, "burn": 0.40, "vulnerable": 0.33}
const MYTHIC_POWER := {"magic_splash": 0.78, "slow": 0.48, "freeze": 0.75, "splash": 0.78, "armor": 0.27, "chain": 0.65, "stun": 0.65, "magic_res": 0.27, "burn": 0.28, "vulnerable": 0.22, "aura": 0.24}
const MYTHIC_SPLASH_RADIUS: float = 100.0
const MYTHIC_CHAIN_TARGETS: int = 3
const MYTHIC_BURN_DURATION: float = 3.0
const MYTHIC_VULNERABLE_DURATION: float = 3.0
# Step12 transcendent balance: four skills per unit, independent of earlier tiers.
# These are provisional values to refine after real-world gameplay testing.
const TRANSCENDENT_CHANCE := {"heavy": 0.35, "armor": 0.44, "poison": 0.42, "hp_percent": 0.24, "magic_splash": 0.48, "burn": 0.44, "magic_res": 0.42, "area_stun": 0.18, "slow": 0.44}
const TRANSCENDENT_POWER := {"heavy": 1.95, "armor": 0.34, "poison": 0.34, "hp_percent": 0.055, "magic_splash": 0.95, "burn": 0.35, "magic_res": 0.34, "area_stun": 0.85, "slow": 0.52, "aura": 0.32, "cooldown": 0.18}
const TRANSCENDENT_AOE_RADIUS: float = 125.0
const TRANSCENDENT_DOT_DURATION: float = 3.5
const TRANSCENDENT_HP_BONUS_CAP: float = 320.0
const BEAST_SPLASH_RADIUS: float = 85.0
const BEAST_HP_BONUS_CAP: float = 200.0
# Beast IDs cannot be summoned; crafting requires three large dogs plus one exclusive item.
const AURA_RANGE: float = 145.0
const BLEED_DURATION: float = 2.0
const SLOW_DURATION: float = 2.0
const ARMOR_DURATION: float = 3.0
const ROUTE := [Vector2(93, 149), Vector2(627, 149), Vector2(627, 700), Vector2(93, 700)]
var beast_items: Dictionary = {} # item ID (beast result kind) -> owned quantity; initially empty
# Step15: four difficulty multipliers and regular-wave stat progression.
const DIFFICULTY_STATS := {
	"쉬움": {"hp": 0.70, "armor": 0.70, "magic_res_bonus": -0.10},
	"보통": {"hp": 1.00, "armor": 1.00, "magic_res_bonus": 0.00},
	"어려움": {"hp": 1.50, "armor": 1.40, "magic_res_bonus": 0.05},
	"지옥": {"hp": 2.20, "armor": 1.80, "magic_res_bonus": 0.10},
}
const BASE_ENEMY_ARMOR: float = 3.0
const BASE_ENEMY_MAGIC_RES: float = 0.10
const BASE_ENEMY_MOVE_SPEED: float = 0.105
# Step15: base values are calculated for normal difficulty before difficulty modifiers.
const MAX_REGULAR_WAVE: int = 80
const BOSS_INTERVAL: int = 10
const MAX_BOSS_ROUNDS: int = 8
const BOSS_DURATION: float = 60.0
const BOSS_HP_MULTIPLIER: float = 20.0 # Legacy reference; actual Step20 boss HP varies by difficulty.
# Step20: realistic late-wave attack scaling with fixed original unit stats and gacha odds.
# These are tuning targets, not measured mobile clear rates. At wave 1 every tier is 1x.
const ENDGAME_TIER_DAMAGE := {"소형견": 1.05, "중형견": 1.30, "대형견": 1.80, "맹수": 3.00, "신화": 6.00, "초월": 11.00}
# Boss HP is 8/11/15/20 times the corresponding difficulty-scaled regular enemy.
const BOSS_HP_BY_DIFFICULTY := {"쉬움": 8.0, "보통": 11.0, "어려움": 15.0, "지옥": 20.0}
const BOSS_ARMOR_MULTIPLIER: float = 1.5
const BOSS_MOVE_SPEED: float = 0.05
const BOSS_KILL_REWARD: int = 100 # Fallback legacy constant for external checks.
# Step21: 80 regular-wave completion awards and 8 boss kill awards.
const WAVE_COMPLETION_REWARDS := [10, 15, 20, 25, 30, 35, 40, 50]
const BOSS_REWARDS := [150, 250, 400, 600, 900, 1200, 1600, 2000]
const FIRST_BEAST_REWARD: int = 400
const FIRST_MYTHIC_REWARD: int = 1000
const FIRST_TRANSCENDENT_REWARD: int = 2000
const REGULAR_WAVE_DURATION: float = 40.0
const REGULAR_WAVE_ENEMY_COUNT: int = 18
const REGULAR_SPAWN_INTERVAL: float = 2.0
const REGULAR_ENEMY_TYPES := ["소형견", "중형견", "대형견", "맹수"]
# Step19: balanced cyclic matchups, attacker grade -> enemy category.
const MATCHUP_BONUS: float = 1.20
const MATCHUP_PENALTY: float = 0.90
const MATCHUP_ADVANTAGE := {"소형견": "대형견", "중형견": "소형견", "대형견": "중형견"}
const MATCHUP_DISADVANTAGE := {"소형견": "중형견", "중형견": "대형견", "대형견": "소형견"}
const WAVE_HP_START: float = 100.0
const WAVE_HP_MULTIPLIER: float = 1.055
const WAVE_ARMOR_START: float = 3.0
const WAVE_ARMOR_LINEAR: float = 0.42
const WAVE_ARMOR_QUADRATIC: float = 0.012
const WAVE_MAGIC_RES_CAP: float = 0.25
var difficulty: String = "보통"
var difficulty_confirmed: bool = false
var difficulty_panel: PanelContainer
var difficulty_description: Label
var gold: int = 100
# Persistent only for the current run. Never awarded by spawning or test setup.
var first_beast_claimed: bool = false
var first_mythic_claimed: bool = false
var first_transcendent_claimed: Dictionary = {}
var last_economy_notice: String = ""
var wave: int = 0
const FIELD_LIMITS := {"쉬움": 100, "보통": 90, "어려움": 80, "지옥": 70}
var lives: int = 10
var dogs: Array[Dictionary] = []
var enemies: Array[Dictionary] = []
var selected: int = -1
var spawn_left: int = 0
var spawn_clock: float = 0.0
var wave_time_left: float = 0.0
const GAME_SPEEDS: Array[int] = [1, 2, 3]
var game_speed: int = 1
var speed_button: Button
var wave_enemy_type: String = ""
var boss_round: int = 0
var boss_pending: bool = false
var boss_running: bool = false
var victory: bool = false
var last_completed_wave: int = 0
var wave_running: bool = false
var auto_advance_pending: bool = false
var game_over: bool = false
var gold_hud_label: Label
var status_label: Label
var info_label: Label
var summon_button: Button
var wave_button: Button
var sell_button: Button
var selected_context_panel: Panel
var selected_context_label: Label
var reset_button: Button
var settings_button: Button
var settings_panel: PanelContainer
var restart_confirmation: ConfirmationDialog
var wave_hud_label: Label
var forest_background: TextureRect
var ui_theme: Theme
var fusion_button: Button
var recipe_button: Button
var recipe_panel: PanelContainer
var recipe_list: VBoxContainer
var recipe_feedback: Label
var recipe_filter: String = "전체"
var recipe_last_signature: String = ""
var draw_button: Button
var mythic_draw_button: Button
var transcendent_draw_button: Button
var draw_info_category: String = "맹수"
var draw_feedback: Label
var draw_info_button: Button
var draw_info_panel: PanelContainer
var draw_info_list: VBoxContainer
var draw_info_tab: String = "보유 아이템"
var draw_info_signature: String = ""
var draw_history: Array[Dictionary] = []
const DRAW_HISTORY_MAX: int = 20
var mission_button: Button
var mission_panel: PanelContainer
var mission_details: Label
var board: Control
var rng := RandomNumberGenerator.new()

var _dog_portraits: Array[Texture2D] = []
var _enemy_portraits: Array[Texture2D] = []

# Load PNG files directly so headless tests work even before Godot's editor import.
# ResourceLoader.load() requires .godot import metadata for imported textures.
func _load_png_texture(path: String) -> Texture2D:
	var img := Image.new()
	var err := img.load(path)
	if err != OK:
		push_error("PNG load failed: %s (code %d)" % [path, err])
		return null
	return ImageTexture.create_from_image(img)

func _load_portraits() -> void:
	_dog_portraits.clear()
	_enemy_portraits.clear()
	sky_art.load_atlases()
	for i in range(49):
		_dog_portraits.append(sky_art.unit_texture(i))
	for i in range(12):
		_enemy_portraits.append(sky_art.enemy_texture(i))

func _dog_portrait(index: int) -> Texture2D:
	return _dog_portraits[index] if index >= 0 and index < _dog_portraits.size() else null

func _enemy_portrait(index: int) -> Texture2D:
	return _enemy_portraits[index] if index >= 0 and index < _enemy_portraits.size() else null

func _ready() -> void:
	rng.randomize()
	_load_portraits()
	_build_ui()
	if persistence_enabled and not OS.has_feature("editor") and not DisplayServer.get_name() == "headless":
		RunStorage.restore(self)
	_refresh()

func _difficulty_stats(key: String = "") -> Dictionary:
	var name: String = difficulty if key.is_empty() else key
	return DIFFICULTY_STATS.get(name, DIFFICULTY_STATS["보통"])

func _enemy_stats_for_difficulty(base_hp: float, base_armor: float = BASE_ENEMY_ARMOR, base_magic_res: float = BASE_ENEMY_MAGIC_RES) -> Dictionary:
	var settings: Dictionary = _difficulty_stats()
	return {
		"hp": maxf(1.0, base_hp * float(settings["hp"])),
		"armor": maxf(0.0, base_armor * float(settings["armor"])),
		"magic_res": clampf(base_magic_res + float(settings["magic_res_bonus"]), 0.0, 0.50),
		"move_speed": BASE_ENEMY_MOVE_SPEED,
	}

func _regular_wave_base_stats(wave_number: int) -> Dictionary:
	# Numeric growth stops at wave 80 until a future boss-wave scaling system is added.
	var w: int = clampi(wave_number, 1, MAX_REGULAR_WAVE)
	var step: float = float(w - 1)
	return {
		"hp": WAVE_HP_START * pow(WAVE_HP_MULTIPLIER, step),
		"armor": WAVE_ARMOR_START + WAVE_ARMOR_LINEAR * step + WAVE_ARMOR_QUADRATIC * step * step,
		"magic_res": minf(WAVE_MAGIC_RES_CAP, BASE_ENEMY_MAGIC_RES + float((w - 1) / 4) * 0.01),
		"move_speed": BASE_ENEMY_MOVE_SPEED,
	}

func _regular_wave_stats(wave_number: int) -> Dictionary:
	var base: Dictionary = _regular_wave_base_stats(wave_number)
	return _enemy_stats_for_difficulty(float(base["hp"]), float(base["armor"]), float(base["magic_res"]))

func _select_difficulty(name: String) -> void:
	if not DIFFICULTY_STATS.has(name) or difficulty_confirmed:
		return
	difficulty = name
	difficulty_confirmed = true
	if difficulty_panel != null:
		difficulty_panel.visible = false
	_refresh()

func _build_difficulty_panel() -> void:
	difficulty_panel = PanelContainer.new()
	difficulty_panel.position = Vector2(72, 258)
	difficulty_panel.size = Vector2(575, 610)
	difficulty_panel.z_index = 40
	add_child(difficulty_panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 13)
	difficulty_panel.add_child(content)
	_apply_popup_text_theme(content)
	var heading := Label.new()
	heading.text = "난이도를 선택하세요"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 29)
	content.add_child(heading)
	difficulty_description = Label.new()
	difficulty_description.text = "지옥은 숙련된 운영과 행운이 모두 필요합니다.\n운이 나쁘면 숙련자도 실패할 수 있습니다."
	difficulty_description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	difficulty_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	difficulty_description.add_theme_font_size_override("font_size", 17)
	content.add_child(difficulty_description)
	for tier in ["쉬움", "보통", "어려움", "지옥"]:
		var stats: Dictionary = _difficulty_stats(tier)
		var b := Button.new()
		b.custom_minimum_size = Vector2(530, 86)
		b.add_theme_font_size_override("font_size", 21)
		b.text = "%s   |   체력 %d%% · 방어력 %d%%" % [tier, roundi(float(stats["hp"]) * 100.0), roundi(float(stats["armor"]) * 100.0)]
		b.pressed.connect(_select_difficulty.bind(tier))
		content.add_child(b)

func _build_ui() -> void:
	_apply_forest_theme()
	forest_background = TextureRect.new()
	forest_background.texture = load("res://assets/sky_background.png") as Texture2D
	forest_background.position = Vector2.ZERO
	forest_background.size = Vector2(720, 1280)
	forest_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	forest_background.stretch_mode = TextureRect.STRETCH_SCALE
	forest_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(forest_background)
	# Step23 compact HUD: life / gold / wave+detail / speed / settings.
	# Board and game logic remain separate; these cards never intercept input.
	# HUD responsive text fit: more space for field enemy counter, compact wave card.
	_add_decorative_panel(Vector2(10, 10), Vector2(118, 59), Color("#17284c"))
	_add_decorative_panel(Vector2(134, 10), Vector2(110, 59), Color("#17284c"))
	_add_decorative_panel(Vector2(250, 10), Vector2(258, 59), Color("#17284c"))
	status_label = Label.new()
	status_label.position = Vector2(17, 23)
	status_label.size = Vector2(104, 34)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.clip_text = true
	status_label.add_theme_font_size_override("font_size", 17)
	add_child(status_label)
	gold_hud_label = Label.new()
	gold_hud_label.position = Vector2(140, 23)
	gold_hud_label.size = Vector2(98, 34)
	gold_hud_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gold_hud_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	gold_hud_label.clip_text = true
	gold_hud_label.add_theme_font_size_override("font_size", 18)
	add_child(gold_hud_label)
	wave_hud_label = Label.new()
	wave_hud_label.position = Vector2(257, 16)
	wave_hud_label.size = Vector2(244, 46)
	wave_hud_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wave_hud_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	wave_hud_label.clip_text = true
	wave_hud_label.add_theme_font_size_override("font_size", 15)
	add_child(wave_hud_label)
	info_label = Label.new()
	info_label.z_index = 1
	info_label.position = Vector2(28, 889)
	info_label.size = Vector2(664, 44)
	info_label.clip_text = false
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_label.add_theme_color_override("font_color", Color("#fff5dc"))
	info_label.add_theme_font_size_override("font_size", 17)
	add_child(info_label)
	board = Control.new()
	board.position = Vector2(0, 0)
	board.size = Vector2(720, 731)
	board.mouse_filter = Control.MOUSE_FILTER_STOP
	board.set_script(null)
	add_child(board)
	board.draw.connect(_draw_board)
	board.gui_input.connect(_board_input)
	# Dedicated readable log area; never render instructions directly on scenery.
	_add_decorative_panel(Vector2(14, 855), Vector2(692, 130), Color("#17284c"))
	var chat_heading := Label.new()
	chat_heading.text = "천공 성채 · 전투 안내"
	chat_heading.position = Vector2(28, 860)
	chat_heading.size = Vector2(650, 26)
	chat_heading.add_theme_font_size_override("font_size", 17)
	chat_heading.add_theme_color_override("font_color", Color("#f7d9a8"))
	add_child(chat_heading)
	# Contextual selected-unit strip occupies the space between field and log.
	selected_context_panel = Panel.new()
	selected_context_panel.position = Vector2(14, 738)
	selected_context_panel.size = Vector2(692, 109)
	selected_context_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	selected_context_panel.add_theme_stylebox_override("panel", _panel_box(Color("#20335e"), Color("#dfb979"), 3, 11))
	selected_context_panel.visible = false
	add_child(selected_context_panel)
	selected_context_label = Label.new()
	selected_context_label.position = Vector2(28, 746)
	selected_context_label.size = Vector2(470, 99)
	selected_context_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	selected_context_label.add_theme_font_size_override("font_size", 17)
	selected_context_label.add_theme_color_override("font_color", Color("#fff2d3"))
	selected_context_label.visible = false
	add_child(selected_context_label)
	# Ornate action dock under interactive controls.
	_add_decorative_panel(Vector2(8, 992), Vector2(704, 272), Color("#14213e"))
	# Keep buttons above the board; the board only covers the battlefield.
	summon_button = _make_button("🐾 소환하기  20G", Vector2(22, 1003), Vector2(216, 74), _summon)
	wave_button = _make_button("웨이브 시작", Vector2(250, 1003), Vector2(216, 74), _start_wave)
	# Selected-unit context action. No permanent extra row in the bottom dock.
	sell_button = _make_button("판매", Vector2(510, 747), Vector2(183, 53), _sell_selected)
	sell_button.visible = false
	sell_button.add_theme_font_size_override("font_size", 19)
	# Restart remains exclusively inside Settings; do not alter reset behavior.
	reset_button = null
	settings_button = _make_button("⚙", Vector2(641, 10), Vector2(69, 59), _toggle_settings)
	settings_button.add_theme_font_size_override("font_size", 26)
	_build_settings_panel()
	fusion_button = _make_button("✦ 선택 유닛 조합", Vector2(22, 1083), Vector2(320, 57), _fuse_selected)
	recipe_button = _make_button("📖 조합 도감", Vector2(360, 1083), Vector2(335, 57), _toggle_recipes)
	_build_recipe_panel()
	draw_button = _make_button("🐾 맹수 뽑기 50G", Vector2(22, 1147), Vector2(216, 52), _draw_gacha)
	mythic_draw_button = _make_button("💠 신화 뽑기 50G", Vector2(250, 1147), Vector2(216, 52), _draw_mythic_gacha)
	transcendent_draw_button = _make_button("✦ 초월 뽑기 50G", Vector2(478, 1147), Vector2(219, 52), _draw_transcendent_gacha)
	for b in [draw_button, mythic_draw_button, transcendent_draw_button]:
		b.add_theme_font_size_override("font_size", 19)
	draw_feedback = Label.new()
	draw_feedback.position = Vector2(28, 957)
	draw_feedback.size = Vector2(664, 24)
	draw_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	draw_feedback.add_theme_font_size_override("font_size", 15)
	draw_feedback.text = "맹수 각 3% · 신화 각 1% · 초월 각 0.1% · 골드 0~10배"
	add_child(draw_feedback)
	draw_info_button = _make_button("🎁 뽑기 정보  ·  보유 아이템", Vector2(22, 1205), Vector2(675, 47), _toggle_draw_info)
	draw_info_button.add_theme_font_size_override("font_size", 16)
	_build_draw_info_panel()
	var help := Label.new()
	help.text = "유닛 → 빈 칸: 이동 · 중앙: 지원/조합 · 적 처치 +5G"
	help.position = Vector2(28, 933)
	help.size = Vector2(664, 22)
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.add_theme_font_size_override("font_size", 15)
	help.add_theme_color_override("font_color", Color("#fff3cd"))
	add_child(help)
	_build_difficulty_panel()
	speed_button = _make_button("1x", Vector2(514, 10), Vector2(62, 59), _cycle_game_speed)
	speed_button.add_theme_font_size_override("font_size", 20)
	pause_button = _make_button("Ⅱ", Vector2(581, 10), Vector2(54, 59), _toggle_pause)
	pause_button.add_theme_font_size_override("font_size", 24)
	mission_button = _make_button("조합 미션", Vector2(478, 1003), Vector2(219, 74), _toggle_missions)
	mission_button.add_theme_font_size_override("font_size", 21)
	_build_mission_panel()

# Economy rewards are earned only upon completing a wave / actually killing a boss.
func _wave_completion_reward(wave_number: int) -> int:
	if wave_number < 1 or wave_number > MAX_REGULAR_WAVE:
		return 0
	return WAVE_COMPLETION_REWARDS[int((wave_number - 1) / 10)]

func _boss_kill_reward(round_number: int) -> int:
	if round_number < 1 or round_number > MAX_BOSS_ROUNDS:
		return 0
	return BOSS_REWARDS[round_number - 1]

func _on_successful_fusion(result_kind: int) -> int:
	# Call after consuming all materials/items, in BOTH crafting entry points.
	# Never grant money to unit summons, debug creation, failed crafting, or repeats.
	if result_kind < 0 or result_kind >= DOGS.size():
		return 0
	var reward: int = 0
	match GRADES[result_kind]:
		"맹수":
			if not first_beast_claimed:
				first_beast_claimed = true
				reward = FIRST_BEAST_REWARD
		"신화":
			if not first_mythic_claimed:
				first_mythic_claimed = true
				reward = FIRST_MYTHIC_REWARD
		"초월":
			if not first_transcendent_claimed.has(result_kind):
				first_transcendent_claimed[result_kind] = true
				reward = FIRST_TRANSCENDENT_REWARD
	if reward > 0:
		gold += reward
		last_economy_notice = "%s 최초 조합! +%dG" % [DOGS[result_kind], reward]
		if draw_feedback != null:
			draw_feedback.text = last_economy_notice
		_refresh_missions()
	return reward

func _mission_status_text() -> String:
	var lines: Array[String] = ["최초 조합 미션 (한 판 기준)", ""]
	lines.append("%s  맹수 등급 최초 조합    +400G" % ("[완료]" if first_beast_claimed else "[미달성]"))
	lines.append("%s  신화 등급 최초 조합    +1,000G" % ("[완료]" if first_mythic_claimed else "[미달성]"))
	for kind in TRANSCENDENT_DRAW_ITEM_IDS:
		lines.append("%s  %s 최초 조합    +2,000G" % ["[완료]" if first_transcendent_claimed.has(kind) else "[미달성]", DOGS[kind]])
	var claimed: int = (FIRST_BEAST_REWARD if first_beast_claimed else 0) + (FIRST_MYTHIC_REWARD if first_mythic_claimed else 0) + FIRST_TRANSCENDENT_REWARD * first_transcendent_claimed.size()
	lines.append("\n달성 골드: %d / 7,400G" % claimed)
	lines.append("실제 조합 성공 시 자동 지급 · 중복 불가")
	return "\n".join(PackedStringArray(lines))

func _build_mission_panel() -> void:
	mission_panel = PanelContainer.new()
	mission_panel.position = Vector2(24, 335)
	mission_panel.size = Vector2(672, 550)
	mission_panel.z_index = 210
	mission_panel.visible = false
	mission_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(mission_panel)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 16)
	mission_panel.add_child(layout)
	_apply_popup_text_theme(layout)
	var title := Label.new()
	title.text = "조합 미션 진행 상황"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	layout.add_child(title)
	mission_details = Label.new()
	mission_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mission_details.add_theme_font_size_override("font_size", 19)
	mission_details.custom_minimum_size = Vector2(635, 385)
	layout.add_child(mission_details)
	var close := Button.new()
	close.text = "닫기"
	close.pressed.connect(_toggle_missions)
	layout.add_child(close)
	_refresh_missions()

func _toggle_missions() -> void:
	if mission_panel == null:
		return
	mission_panel.visible = not mission_panel.visible
	if mission_panel.visible:
		if recipe_panel != null: recipe_panel.visible = false
		if draw_info_panel != null: draw_info_panel.visible = false
		_refresh_missions()

func _refresh_missions() -> void:
	if mission_details != null:
		mission_details.text = _mission_status_text()

func _cycle_game_speed() -> void:
	if not difficulty_confirmed or game_over or victory:
		return
	game_speed = GAME_SPEEDS[(GAME_SPEEDS.find(game_speed) + 1) % GAME_SPEEDS.size()]
	_refresh()

func _make_button(label_text: String, pos: Vector2, dimensions: Vector2, callback: Callable) -> Button:
	var b := Button.new()
	b.text = label_text
	b.position = pos
	b.size = dimensions
	b.add_theme_font_size_override("font_size", 24)
	b.pressed.connect(callback)
	add_child(b)
	var color := Color("#245799")
	var rim := Color("#ffe2a4")
	if label_text.begins_with("🐾 소환하기") or label_text.begins_with("랜덤 소환"):
		color = Color("#c58a22")
	elif label_text == "웨이브 시작":
		color = Color("#247b99")
	elif ("초월" in label_text):
		color = Color("#8a35c6")
		rim = Color("#f2baff")
	elif ("신화" in label_text):
		color = Color("#187bc9")
		rim = Color("#bce3ff")
	elif ("맹수" in label_text):
		color = Color("#4a62ac")
	elif label_text.begins_with("⚙"):
		color = Color("#253456")
	elif label_text.begins_with("조합 미션"):
		color = Color("#406aa8")
	b.add_theme_stylebox_override("normal", _panel_box(color, rim, 4, 15))
	b.add_theme_stylebox_override("hover", _panel_box(color.lightened(0.17), Color("#fff2be"), 4, 15))
	b.add_theme_stylebox_override("pressed", _panel_box(color.darkened(0.22), rim, 4, 15))
	return b

# Step23 presentation-only helpers. Gameplay stats and crafting rules unchanged.
func _panel_box(fill: Color, outline: Color = Color("#f5bf65"), border_size: int = 4, radius: int = 18) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = outline
	style.set_border_width_all(border_size)
	style.set_corner_radius_all(radius)
	style.anti_aliasing = true
	style.anti_aliasing_size = 1.0
	style.shadow_color = Color(0.11, 0.07, 0.035, 0.65)
	style.shadow_size = 9
	style.shadow_offset = Vector2i(0, 6)
	style.content_margin_left = 14.0
	style.content_margin_top = 12.0
	style.content_margin_right = 14.0
	style.content_margin_bottom = 12.0
	return style

func _apply_forest_theme() -> void:
	ui_theme = Theme.new()
	if ResourceLoader.exists("res://assets/kr.ttf"):
		ui_theme.default_font = load("res://assets/kr.ttf")
	ui_theme.set_stylebox("normal", "Button", _panel_box(Color("#245799"), Color("#e9b86a"), 4, 16))
	ui_theme.set_stylebox("hover", "Button", _panel_box(Color("#427ed0"), Color("#ffe09a"), 4, 16))
	ui_theme.set_stylebox("pressed", "Button", _panel_box(Color("#213e6d"), Color("#f9db8d"), 4, 16))
	ui_theme.set_stylebox("disabled", "Button", _panel_box(Color("#424e65"), Color("#70829e"), 3, 16))
	ui_theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	ui_theme.set_color("font_color", "Button", Color("#fff9df"))
	ui_theme.set_color("font_hover_color", "Button", Color("#ffffff"))
	ui_theme.set_color("font_pressed_color", "Button", Color("#fff8dc"))
	ui_theme.set_color("font_disabled_color", "Button", Color("#d5c7b4"))
	ui_theme.set_stylebox("panel", "PanelContainer", _panel_box(Color("#edf1fc"), Color("#7a90bb"), 6, 20))
	ui_theme.set_color("font_color", "Label", Color("#fff1d1"))
	theme = ui_theme

func _apply_popup_text_theme(target: Control) -> void:
	var local_theme := Theme.new()
	local_theme.set_color("font_color", "Label", Color("#17284c"))
	target.theme = local_theme

func _add_decorative_panel(pos: Vector2, dimensions: Vector2, fill: Color) -> void:
	var backdrop := Panel.new()
	backdrop.position = pos
	backdrop.size = dimensions
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.add_theme_stylebox_override("panel", _panel_box(fill, Color("#d9a65d"), 5, 19))
	add_child(backdrop)

func _build_settings_panel() -> void:
	settings_panel = PanelContainer.new()
	settings_panel.position = Vector2(95, 304)
	settings_panel.size = Vector2(530, 442)
	settings_panel.z_index = 210
	settings_panel.visible = false
	settings_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(settings_panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 18)
	settings_panel.add_child(content)
	_apply_popup_text_theme(content)
	var header := Label.new()
	header.text = "⚙  게임 설정"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 32)
	header.add_theme_color_override("font_color", Color("#17284c"))
	content.add_child(header)
	var description := Label.new()
	description.text = "설정을 여는 동안 전투가 일시정지됩니다."
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.add_theme_font_size_override("font_size", 19)
	description.add_theme_color_override("font_color", Color("#344f7b"))
	content.add_child(description)
	var speed_note := Label.new()
	speed_note.text = "전투 배속은 상단의 속도 버튼에서 변경하세요."
	speed_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	speed_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	speed_note.add_theme_color_override("font_color", Color("#344f7b"))
	content.add_child(speed_note)
	var restart := Button.new()
	restart.text = "↻  다시하기 · 난이도 재선택"
	restart.custom_minimum_size = Vector2(480, 80)
	restart.add_theme_font_size_override("font_size", 24)
	restart.pressed.connect(_ask_restart)
	content.add_child(restart)
	var close := Button.new()
	close.text = "게임으로 돌아가기"
	close.custom_minimum_size = Vector2(480, 69)
	close.pressed.connect(_toggle_settings)
	content.add_child(close)
	restart_confirmation = ConfirmationDialog.new()
	restart_confirmation.title = "멍랜디 · 다시하기"
	restart_confirmation.dialog_text = "현재 게임 진행 상황을 초기화하고 난이도를 다시 선택할까요?\n보유 골드·유닛·아이템·미션 기록이 초기화됩니다."
	restart_confirmation.ok_button_text = "초기화하기"
	restart_confirmation.cancel_button_text = "취소"
	restart_confirmation.confirmed.connect(_restart)
	add_child(restart_confirmation)

func _toggle_settings() -> void:
	if settings_panel == null:
		return
	settings_panel.visible = not settings_panel.visible
	paused = settings_panel.visible
	if paused and persistence_enabled:
		RunStorage.save(self)
	_refresh()
	if settings_panel.visible:
		if recipe_panel != null: recipe_panel.visible = false
		if draw_info_panel != null: draw_info_panel.visible = false
		if mission_panel != null: mission_panel.visible = false

func _ask_restart() -> void:
	if restart_confirmation != null:
		restart_confirmation.popup_centered()

func _draw_board() -> void:
	if board != null:
		sky_art.draw_battle(self, board)

func _cell_center(cell: int) -> Vector2:
	return GRID_ORIGIN + Vector2(float(cell % COLS) * CELL + (CELL - 5.0) / 2.0, float(floori(float(cell) / float(COLS))) * CELL + (CELL - 5.0) / 2.0)

func _route_point(progress: float) -> Vector2:
	var segment := int(floor(progress)) % ROUTE.size()
	return ROUTE[segment].lerp(ROUTE[(segment + 1) % ROUTE.size()], fposmod(progress, 1.0))

func _board_input(event: InputEvent) -> void:
	var point := Vector2(-999, -999)
	if event is InputEventScreenTouch:
		if not event.pressed:
			return
		point = event.position
	elif event is InputEventMouseButton:
		if not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
			return
		point = event.position
	else:
		return
	var relative := point - GRID_ORIGIN
	var col := int(floor(relative.x / CELL))
	var row := int(floor(relative.y / CELL))
	if col < 0 or col >= COLS or row < 0 or row >= ROWS:
		return
	var cell := row * COLS + col
	for i in range(dogs.size()):
		if int(dogs[i]["cell"]) == cell:
			selected = i
			_refresh()
			return
	if selected >= 0 and selected < dogs.size():
		dogs[selected]["cell"] = cell
		selected = -1
		_refresh()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_S:
			_summon()
		elif event.keycode == KEY_W:
			_start_wave()
		elif event.keycode == KEY_R:
			_ask_restart()

# Selling is restricted to ordinary dog tiers; advanced crafted units remain protected.
# A sale must free exactly one occupied cell and award the advertised gold once.
func _sell_value(kind: int) -> int:
	if kind < 0 or kind >= GRADES.size():
		return 0
	match GRADES[kind]:
		"소형견": return 10
		"중형견": return 40
		"대형견": return 100
	return 0

func _sell_selected() -> void:
	if game_over or not difficulty_confirmed or selected < 0 or selected >= dogs.size():
		return
	var kind: int = int(dogs[selected]["kind"])
	var sale_price: int = _sell_value(kind)
	if sale_price <= 0:
		return
	dogs.remove_at(selected)
	selected = -1
	gold += sale_price
	_refresh()

func _summon() -> void:
	if game_over or gold < COST or dogs.size() >= COLS * ROWS:
		return
	var used: Dictionary = {}
	for dog in dogs:
		used[int(dog["cell"])] = true
	var free: Array[int] = []
	for cell in range(COLS * ROWS):
		if not used.has(cell):
			free.append(cell)
	if free.is_empty():
		return
	gold -= COST
	var kind: int = [0, 1, 2, 10, 11, 12, 13, 14, 15, 16][rng.randi_range(0, 9)]
	var attack_cells: Array[int] = []
	for candidate in free:
		if _cell_reaches_path(candidate, float(RANGE[kind])):
			attack_cells.append(candidate)
	var candidates: Array[int] = attack_cells if not attack_cells.is_empty() else free
	dogs.append({"cell": candidates[rng.randi_range(0, candidates.size() - 1)], "kind": kind, "cooldown": 0.0})
	_refresh()


# A deterministic reward mapper makes the exact probability boundaries testable.
# ticket: 0..99999. Each beast item occupies 3000 tickets (3%).
# gold_ticket: 1..2047. Multipliers 0..10 use descending 1024..1 weights.
func _draw_reward_for_roll(ticket: int, gold_ticket: int) -> Dictionary:
	if ticket < 0 or ticket >= DRAW_TICKET_TOTAL:
		return {}
	var item_ticket_total: int = DRAW_ITEM_IDS.size() * DRAW_ITEM_TICKETS
	if ticket < item_ticket_total:
		var item_slot: int = ticket / DRAW_ITEM_TICKETS
		return {"type": "item", "item": DRAW_ITEM_IDS[item_slot]}
	if gold_ticket < 1 or gold_ticket > DRAW_GOLD_WEIGHT_TOTAL:
		return {}
	var cumulative: int = 0
	for multiplier in range(DRAW_GOLD_WEIGHTS.size()):
		cumulative += DRAW_GOLD_WEIGHTS[multiplier]
		if gold_ticket <= cumulative:
			return {"type": "gold", "multiplier": multiplier, "gold": multiplier * DRAW_COST}
	return {}

# Dedicated mythic draw: four 1% item slots, then 96% gold with the same
# strictly decreasing 0x..10x conditional weighting as the beast draw.
func _mythic_reward_for_roll(ticket: int, gold_ticket: int) -> Dictionary:
	if ticket < 0 or ticket >= DRAW_TICKET_TOTAL:
		return {}
	var item_total: int = MYTHIC_DRAW_ITEM_IDS.size() * MYTHIC_DRAW_ITEM_TICKETS
	if ticket < item_total:
		var slot: int = int(ticket / MYTHIC_DRAW_ITEM_TICKETS)
		return {"type": "item", "item": MYTHIC_DRAW_ITEM_IDS[slot]}
	if gold_ticket < 1 or gold_ticket > DRAW_GOLD_WEIGHT_TOTAL:
		return {}
	var cumulative: int = 0
	for multiplier in range(DRAW_GOLD_WEIGHTS.size()):
		cumulative += int(DRAW_GOLD_WEIGHTS[multiplier])
		if gold_ticket <= cumulative:
			return {"type": "gold", "multiplier": multiplier, "gold": multiplier * DRAW_COST}
	return {}

# Independent transcendent reward mapping. Each item uses 100 of 100,000
# tickets (exactly 0.1%). Remaining 99,700 tickets enter gold 0..10x.
func _transcendent_reward_for_roll(ticket: int, gold_ticket: int) -> Dictionary:
	if ticket < 0 or ticket >= DRAW_TICKET_TOTAL:
		return {}
	var item_total: int = TRANSCENDENT_DRAW_ITEM_IDS.size() * TRANSCENDENT_DRAW_ITEM_TICKETS
	if ticket < item_total:
		var slot: int = int(ticket / TRANSCENDENT_DRAW_ITEM_TICKETS)
		return {"type": "item", "item": TRANSCENDENT_DRAW_ITEM_IDS[slot]}
	if gold_ticket < 1 or gold_ticket > DRAW_GOLD_WEIGHT_TOTAL:
		return {}
	var cumulative: int = 0
	for multiplier in range(DRAW_GOLD_WEIGHTS.size()):
		cumulative += int(DRAW_GOLD_WEIGHTS[multiplier])
		if gold_ticket <= cumulative:
			return {"type": "gold", "multiplier": multiplier, "gold": multiplier * DRAW_COST}
	return {}

func _draw_transcendent_gacha() -> void:
	if game_over:
		if draw_feedback != null:
			draw_feedback.text = "게임 종료: 초월 뽑기를 할 수 없습니다."
		return
	if gold < DRAW_COST:
		if draw_feedback != null:
			draw_feedback.text = "초월 뽑기 골드 부족! 50G 필요"
		return
	var reward: Dictionary = _transcendent_reward_for_roll(rng.randi_range(0, DRAW_TICKET_TOTAL - 1), rng.randi_range(1, DRAW_GOLD_WEIGHT_TOTAL))
	if reward.is_empty():
		return
	gold -= DRAW_COST
	if reward["type"] == "item":
		var item_id: int = int(reward["item"])
		beast_items[item_id] = int(beast_items.get(item_id, 0)) + 1
		if draw_feedback != null:
			draw_feedback.text = "초월 획득! %s (%d개)" % [BEAST_ITEMS[item_id], int(beast_items[item_id])]
	else:
		var payout: int = int(reward["gold"])
		gold += payout
		if draw_feedback != null:
			draw_feedback.text = "초월 뽑기: 골드 %d배 +%dG" % [int(reward["multiplier"]), payout]
	_record_draw(reward, "초월")
	_refresh()

func _draw_mythic_gacha() -> void:
	if game_over:
		if draw_feedback != null:
			draw_feedback.text = "게임 종료: 신화 뽑기를 할 수 없습니다."
		return
	if gold < DRAW_COST:
		if draw_feedback != null:
			draw_feedback.text = "신화 뽑기 골드 부족! 50G 필요"
		return
	var reward: Dictionary = _mythic_reward_for_roll(rng.randi_range(0, DRAW_TICKET_TOTAL - 1), rng.randi_range(1, DRAW_GOLD_WEIGHT_TOTAL))
	if reward.is_empty():
		return
	gold -= DRAW_COST
	if reward["type"] == "item":
		var item_id: int = int(reward["item"])
		beast_items[item_id] = int(beast_items.get(item_id, 0)) + 1
		if draw_feedback != null:
			draw_feedback.text = "신화 획득! %s (%d개)" % [BEAST_ITEMS[item_id], int(beast_items[item_id])]
	else:
		var payout: int = int(reward["gold"])
		gold += payout
		if draw_feedback != null:
			draw_feedback.text = "신화 뽑기: 골드 %d배 +%dG" % [int(reward["multiplier"]), payout]
	_record_draw(reward, "신화")
	_refresh()

func _draw_gacha() -> void:
	if game_over:
		if draw_feedback != null:
			draw_feedback.text = "게임 종료: 뽑기를 할 수 없습니다."
		return
	if gold < DRAW_COST:
		if draw_feedback != null:
			draw_feedback.text = "골드 부족! 50G가 필요합니다."
		return
	var reward: Dictionary = _draw_reward_for_roll(rng.randi_range(0, DRAW_TICKET_TOTAL - 1), rng.randi_range(1, DRAW_GOLD_WEIGHT_TOTAL))
	if reward.is_empty():
		return # Never deduct gold if reward resolution fails.
	gold -= DRAW_COST
	if reward["type"] == "item":
		var item_id: int = int(reward["item"])
		beast_items[item_id] = int(beast_items.get(item_id, 0)) + 1
		if draw_feedback != null:
			draw_feedback.text = "획득! %s (총 %d개)" % [BEAST_ITEMS[item_id], int(beast_items[item_id])]
	else:
		var payout: int = int(reward["gold"])
		gold += payout
		if draw_feedback != null:
			draw_feedback.text = "골드 %d배! +%dG (뽑기 비용 50G)" % [int(reward["multiplier"]), payout]
	_record_draw(reward, "맹수")
	_refresh()

func _pick_regular_enemy_type() -> String:
	# Each category has an equal 25% chance; only one category per wave.
	return str(REGULAR_ENEMY_TYPES[rng.randi_range(0, REGULAR_ENEMY_TYPES.size() - 1)])

# Transparent static throughput estimate (single target, before proc effects and
# positioning). NOT a simulated win-rate or a guarantee of acquiring rare items.
func _estimated_single_target_dps(kinds: Array, wave_number: int, difficulty_name: String = "보통") -> float:
	var stats: Dictionary = _regular_wave_base_stats(wave_number)
	var settings: Dictionary = _difficulty_stats(difficulty_name)
	var armor: float = float(stats["armor"]) * float(settings["armor"])
	var physical_factor: float = 100.0 / (100.0 + armor)
	var result: float = 0.0
	for kind_value in kinds:
		var kind: int = int(kind_value)
		if kind >= 0 and kind < ATTACK.size():
			result += float(ATTACK[kind]) / float(COOLDOWN[kind]) * _tier_damage_scale(kind, wave_number) * physical_factor
	return result

func _boss_stats(boss_number: int) -> Dictionary:
	var basis: Dictionary = _regular_wave_stats(clampi(boss_number * BOSS_INTERVAL, 1, MAX_REGULAR_WAVE))
	return {
		"hp": float(basis["hp"]) * float(BOSS_HP_BY_DIFFICULTY.get(difficulty, BOSS_HP_MULTIPLIER)),
		"armor": float(basis["armor"]) * BOSS_ARMOR_MULTIPLIER,
		"magic_res": float(basis["magic_res"]),
		"move_speed": BOSS_MOVE_SPEED,
	}

func _start_boss_round() -> void:
	if not boss_pending or boss_running or game_over or victory or not difficulty_confirmed:
		return
	boss_round = int(wave / BOSS_INTERVAL)
	boss_pending = false
	boss_running = true
	wave_running = true
	wave_time_left = BOSS_DURATION
	spawn_clock = 0.0
	spawn_left = 0
	wave_enemy_type = "보스"
	# Boss-only round: remove regular enemies when entering the separate boss phase.
	enemies.clear()
	var stats: Dictionary = _boss_stats(boss_round)
	enemies.append({"progress": 0.0, "hp": stats["hp"], "max_hp": stats["hp"], "armor": stats["armor"], "magic_res": stats["magic_res"], "move_speed": stats["move_speed"], "enemy_type": "보스", "is_boss": true, "boss_round": boss_round, "effects": {}})
	_refresh()

func _complete_boss_round(defeated: bool) -> void:
	if not boss_running:
		return
	boss_running = false
	wave_running = false
	wave_time_left = 0.0
	spawn_left = 0
	spawn_clock = 0.0
	if defeated:
		if boss_round >= MAX_BOSS_ROUNDS and wave >= MAX_REGULAR_WAVE:
			victory = true
		else:
			auto_advance_pending = true
	else:
		game_over = true
	_refresh()

func _start_wave() -> void:
	if game_over or victory or wave_running or not difficulty_confirmed:
		return
	auto_advance_pending = false
	if boss_pending:
		_start_boss_round()
		return
	if wave >= MAX_REGULAR_WAVE:
		return
	wave += 1
	wave_enemy_type = _pick_regular_enemy_type()
	wave_time_left = REGULAR_WAVE_DURATION
	spawn_left = REGULAR_WAVE_ENEMY_COUNT
	spawn_clock = 0.0
	wave_running = true
	_refresh()

func _complete_regular_wave() -> void:
	if not wave_running:
		return
	# Keep surviving normal enemies on the field between regular rounds.
	spawn_left = 0
	spawn_clock = 0.0
	wave_time_left = 0.0
	wave_running = false
	last_completed_wave = wave
	if wave % BOSS_INTERVAL == 0:
		boss_pending = true
	auto_advance_pending = true
	var earned: int = _wave_completion_reward(wave)
	gold += earned
	last_economy_notice = "일반 %d웨이브 클리어 +%dG" % [wave, earned]
	_refresh()

# Effect timers and damage-over-time run independently of attack intervals.
func _tick_enemy_effects(delta: float) -> void:
	for i in range(enemies.size()):
		var enemy: Dictionary = enemies[i]
		var effects: Dictionary = enemy.get("effects", {})
		for effect_name in effects.keys():
			var state: Dictionary = effects[effect_name]
			var active_time: float = minf(delta, float(state.get("time", 0.0)))
			if (effect_name == "bleed" or effect_name == "burn" or effect_name == "poison") and active_time > 0.0:
				enemy["hp"] = float(enemy["hp"]) - maxf(0.0, float(state.get("dps", 0.0))) * active_time * _damage_multiplier(enemy, effect_name == "burn")
			state["time"] = maxf(0.0, float(state.get("time", 0.0)) - delta)
			if float(state["time"]) <= 0.0:
				effects.erase(effect_name)
			else:
				effects[effect_name] = state
		enemy["effects"] = effects
		enemies[i] = enemy

# Reapplying a status refreshes duration. Same-type damage/slow debuffs use the
# strongest active instance rather than stacking without a bound.
func _apply_status(enemy_index: int, effect_name: String, duration: float, power: float = 0.0) -> void:
	if enemy_index < 0 or enemy_index >= enemies.size():
		return
	var enemy: Dictionary = enemies[enemy_index]
	var effects: Dictionary = enemy.get("effects", {})
	# Boss control durations are reduced; damage and gacha values are unaffected.
	if bool(enemy.get("is_boss", false)) and effect_name in ["stun", "freeze"]:
		duration *= 0.5
	var old: Dictionary = effects.get(effect_name, {})
	var next_state: Dictionary = {"time": maxf(duration, float(old.get("time", 0.0)))}
	if effect_name == "bleed" or effect_name == "burn" or effect_name == "poison":
		next_state["dps"] = maxf(power, float(old.get("dps", 0.0)))
	elif effect_name in ["slow", "armor", "magic_res", "vulnerable"]:
		next_state["power"] = maxf(power, float(old.get("power", 0.0)))
	effects[effect_name] = next_state
	enemy["effects"] = effects
	enemies[enemy_index] = enemy

func _effective_auras(dog_index: int) -> Dictionary:
	var damage_bonus: float = 0.0
	var speed_bonus: float = 0.0
	var magic_bonus: float = 0.0
	var cooldown_bonus: float = 0.0
	var position: Vector2 = _cell_center(int(dogs[dog_index]["cell"]))
	for other in dogs:
		var other_kind: int = int(other["kind"])
		if position.distance_to(_cell_center(int(other["cell"]))) > AURA_RANGE:
			continue
		var skills: Array = DOG_SKILLS.get(other_kind, [])
		var aura_power: float = 0.0
		if GRADES[other_kind] == "초월":
			aura_power = float(TRANSCENDENT_POWER["aura"])
		elif GRADES[other_kind] == "신화":
			aura_power = float(MYTHIC_POWER["aura"])
		elif GRADES[other_kind] == "맹수":
			aura_power = float(BEAST_POWER["aura"])
		else:
			aura_power = float(SKILL_POWER[GRADES[other_kind]]["aura"])
		if skills.has("attack_aura"):
			damage_bonus = maxf(damage_bonus, aura_power)
		if skills.has("speed_aura"):
			speed_bonus = maxf(speed_bonus, aura_power)
		if skills.has("magic_aura"):
			magic_bonus = maxf(magic_bonus, aura_power)
		if skills.has("cooldown_aura"):
			cooldown_bonus = maxf(cooldown_bonus, float(TRANSCENDENT_POWER["cooldown"]))
	return {"damage": damage_bonus, "speed": speed_bonus, "magic": magic_bonus, "cooldown": cooldown_bonus}

func _damage_multiplier(enemy: Dictionary, is_magic: bool = false) -> float:
	var effects: Dictionary = enemy.get("effects", {})
	var weakness_key: String = "magic_res" if is_magic else "armor"
	var weakness: float = clampf(float(effects.get(weakness_key, {}).get("power", 0.0)), 0.0, 1.0)
	var vulnerability: float = clampf(float(effects.get("vulnerable", {}).get("power", 0.0)), 0.0, 1.0)
	var armor_value: float = maxf(0.0, float(enemy.get("armor", 0.0)))
	var magic_res_value: float = clampf(float(enemy.get("magic_res", 0.0)), 0.0, 0.95)
	var resistance_multiplier: float = (1.0 - magic_res_value * (1.0 - weakness)) if is_magic else 100.0 / (100.0 + armor_value * (1.0 - weakness))
	return resistance_multiplier * (1.0 + vulnerability)

func _hit_enemy(enemy_index: int, damage: float, is_magic: bool = false) -> void:
	if enemy_index < 0 or enemy_index >= enemies.size():
		return
	var enemy: Dictionary = enemies[enemy_index]
	if float(enemy["hp"]) <= 0.0:
		return
	enemy["hp"] = float(enemy["hp"]) - maxf(0.0, damage) * _damage_multiplier(enemy, is_magic)
	enemies[enemy_index] = enemy

func _matchup_multiplier(attacker_kind: int, enemy_index: int) -> float:
	if attacker_kind < 0 or attacker_kind >= GRADES.size():
		return 1.0
	if enemy_index < 0 or enemy_index >= enemies.size():
		return 1.0
	var grade: String = GRADES[attacker_kind]
	if not MATCHUP_ADVANTAGE.has(grade):
		return 1.0
	var enemy: Dictionary = enemies[enemy_index]
	if bool(enemy.get("is_boss", false)) or String(enemy.get("enemy_type", "")) == "보스":
		return 1.0
	var enemy_type: String = String(enemy.get("enemy_type", ""))
	if enemy_type == String(MATCHUP_ADVANTAGE[grade]):
		return MATCHUP_BONUS
	if enemy_type == String(MATCHUP_DISADVANTAGE[grade]):
		return MATCHUP_PENALTY
	return 1.0

func _hit_basic_dog_enemy(attacker_kind: int, enemy_index: int, damage: float) -> void:
	_hit_enemy(enemy_index, damage * _matchup_multiplier(attacker_kind, enemy_index))

# Beast skills use their own chances and powers; original dogs remain unaffected.
# Base stats, recipes, probabilities and enemy growth remain unchanged.
# This progression raises damage at the later waves, when 18 enemies/40s require
# considerably higher throughput. All damage and DOT effects use this factor.
func _tier_damage_scale(kind: int, wave_number: int = -1) -> float:
	if kind < 0 or kind >= GRADES.size():
		return 1.0
	var w: int = wave if wave_number < 0 else wave_number
	var progress: float = clampf(float(clampi(w, 1, MAX_REGULAR_WAVE) - 1) / float(MAX_REGULAR_WAVE - 1), 0.0, 1.0)
	var endgame: float = float(ENDGAME_TIER_DAMAGE.get(GRADES[kind], 1.0))
	return 1.0 + (endgame - 1.0) * pow(progress, 1.25)

func _attack_beast(dog_index: int, target: int, auras: Dictionary) -> void:
	if target < 0 or target >= enemies.size():
		return
	var kind: int = int(dogs[dog_index]["kind"])
	var skills: Array = DOG_SKILLS.get(kind, [])
	var damage: float = float(ATTACK[kind]) * _tier_damage_scale(kind) * (1.0 + float(auras["damage"]))
	if skills.has("heavy") and rng.randf() < float(BEAST_CHANCE["heavy"]):
		damage *= float(BEAST_POWER["heavy"])
	if skills.has("crit") and rng.randf() < float(BEAST_CHANCE["crit"]):
		damage *= float(BEAST_POWER["crit"])
	var magic_attack: bool = skills.has("magic_splash")
	if magic_attack:
		damage *= 1.0 + float(auras.get("magic", 0.0))
	_hit_enemy(target, damage, magic_attack)
	if skills.has("multi") and rng.randf() < float(BEAST_CHANCE["multi"]):
		_hit_enemy(target, damage * float(BEAST_POWER["multi"]))
	if skills.has("bleed") and rng.randf() < float(BEAST_CHANCE["bleed"]):
		_apply_status(target, "bleed", BLEED_DURATION, float(ATTACK[kind]) * _tier_damage_scale(kind) * float(BEAST_POWER["bleed"]))
	if skills.has("armor") and rng.randf() < float(BEAST_CHANCE["armor"]):
		_apply_status(target, "armor", ARMOR_DURATION, float(BEAST_POWER["armor"]))
	if skills.has("slow") and rng.randf() < float(BEAST_CHANCE["slow"]):
		_apply_status(target, "slow", SLOW_DURATION, float(BEAST_POWER["slow"]))
	if skills.has("magic_res") and rng.randf() < float(BEAST_CHANCE["magic_res"]):
		_apply_status(target, "magic_res", ARMOR_DURATION, float(BEAST_POWER["magic_res"]))
	if skills.has("hp_percent") and rng.randf() < float(BEAST_CHANCE["hp_percent"]):
		var max_hp: float = float(enemies[target]["max_hp"])
		_hit_enemy(target, minf(max_hp * float(BEAST_POWER["hp_percent"]), BEAST_HP_BONUS_CAP))
	if skills.has("splash") or skills.has("magic_splash") or skills.has("area_stun"):
		var impact: Vector2 = _route_point(float(enemies[target]["progress"]))
		var splash_proc: bool = skills.has("splash") and rng.randf() < float(BEAST_CHANCE["splash"])
		var magic_proc: bool = skills.has("magic_splash") and rng.randf() < float(BEAST_CHANCE["magic_splash"])
		var stun_proc: bool = skills.has("area_stun") and rng.randf() < float(BEAST_CHANCE["area_stun"])
		for i in range(enemies.size()):
			if float(enemies[i]["hp"]) <= 0.0:
				continue
			if impact.distance_to(_route_point(float(enemies[i]["progress"]))) > BEAST_SPLASH_RADIUS:
				continue
			if i != target and splash_proc:
				_hit_enemy(i, damage * float(BEAST_POWER["splash"]))
			if i != target and magic_proc:
				_hit_enemy(i, damage * float(BEAST_POWER["magic_splash"]), true)
			if stun_proc:
				_apply_status(i, "stun", float(BEAST_POWER["area_stun"]))

# Mythic combat. Each unit has exactly three designed effects.
# Damage procs are independent; debuff refresh uses the existing strongest-wins rules.
func _attack_mythic(dog_index: int, target: int, auras: Dictionary) -> void:
	if target < 0 or target >= enemies.size():
		return
	var kind: int = int(dogs[dog_index]["kind"])
	var skills: Array = DOG_SKILLS.get(kind, [])
	var damage: float = float(ATTACK[kind]) * _tier_damage_scale(kind) * (1.0 + float(auras["damage"]))
	var is_magic: bool = skills.has("magic_splash") or skills.has("chain") or skills.has("burn")
	if is_magic:
		damage *= 1.0 + float(auras.get("magic", 0.0))
	_hit_enemy(target, damage, is_magic)
	if skills.has("armor") and rng.randf() < float(MYTHIC_CHANCE["armor"]):
		_apply_status(target, "armor", ARMOR_DURATION, float(MYTHIC_POWER["armor"]))
	if skills.has("magic_res") and rng.randf() < float(MYTHIC_CHANCE["magic_res"]):
		_apply_status(target, "magic_res", ARMOR_DURATION, float(MYTHIC_POWER["magic_res"]))
	if skills.has("slow") and rng.randf() < float(MYTHIC_CHANCE["slow"]):
		_apply_status(target, "slow", SLOW_DURATION, float(MYTHIC_POWER["slow"]))
	if skills.has("freeze") and rng.randf() < float(MYTHIC_CHANCE["freeze"]):
		_apply_status(target, "freeze", float(MYTHIC_POWER["freeze"]))
	if skills.has("stun") and rng.randf() < float(MYTHIC_CHANCE["stun"]):
		_apply_status(target, "stun", float(MYTHIC_POWER["stun"]))
	if skills.has("burn") and rng.randf() < float(MYTHIC_CHANCE["burn"]):
		_apply_status(target, "burn", MYTHIC_BURN_DURATION, damage * float(MYTHIC_POWER["burn"]))
	if skills.has("vulnerable") and rng.randf() < float(MYTHIC_CHANCE["vulnerable"]):
		_apply_status(target, "vulnerable", MYTHIC_VULNERABLE_DURATION, float(MYTHIC_POWER["vulnerable"]))
	if skills.has("splash") or skills.has("magic_splash"):
		var proc: bool = (skills.has("splash") and rng.randf() < float(MYTHIC_CHANCE["splash"])) or (skills.has("magic_splash") and rng.randf() < float(MYTHIC_CHANCE["magic_splash"]))
		if proc:
			var impact: Vector2 = _route_point(float(enemies[target]["progress"]))
			for other_idx in range(enemies.size()):
				if other_idx == target or float(enemies[other_idx]["hp"]) <= 0.0:
					continue
				if impact.distance_to(_route_point(float(enemies[other_idx]["progress"]))) <= MYTHIC_SPLASH_RADIUS:
					_hit_enemy(other_idx, damage * float(MYTHIC_POWER["magic_splash"] if skills.has("magic_splash") else MYTHIC_POWER["splash"]), skills.has("magic_splash"))
	if skills.has("chain") and rng.randf() < float(MYTHIC_CHANCE["chain"]):
		var impact: Vector2 = _route_point(float(enemies[target]["progress"]))
		var nearby: Array[Dictionary] = []
		for i in range(enemies.size()):
			if i == target or float(enemies[i]["hp"]) <= 0.0:
				continue
			var distance: float = impact.distance_to(_route_point(float(enemies[i]["progress"])))
			if distance <= 160.0:
				nearby.append({"index": i, "distance": distance})
		nearby.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["distance"]) < float(b["distance"]))
		for i in range(mini(nearby.size(), MYTHIC_CHAIN_TARGETS)):
			_hit_enemy(int(nearby[i]["index"]), damage * float(MYTHIC_POWER["chain"]), true)

# Step12: true transcendent combat, four independent effects per unit.
func _attack_transcendent(dog_index: int, target: int, auras: Dictionary) -> void:
	if target < 0 or target >= enemies.size():
		return
	var kind: int = int(dogs[dog_index]["kind"])
	var skills: Array = DOG_SKILLS.get(kind, [])
	var is_magic: bool = skills.has("magic_splash")
	var damage: float = float(ATTACK[kind]) * _tier_damage_scale(kind) * (1.0 + float(auras["damage"]))
	if is_magic:
		damage *= 1.0 + float(auras.get("magic", 0.0))
	if skills.has("heavy") and rng.randf() < float(TRANSCENDENT_CHANCE["heavy"]):
		damage *= float(TRANSCENDENT_POWER["heavy"])
	_hit_enemy(target, damage, is_magic)
	if skills.has("armor") and rng.randf() < float(TRANSCENDENT_CHANCE["armor"]):
		_apply_status(target, "armor", ARMOR_DURATION, float(TRANSCENDENT_POWER["armor"]))
	if skills.has("poison") and rng.randf() < float(TRANSCENDENT_CHANCE["poison"]):
		_apply_status(target, "poison", TRANSCENDENT_DOT_DURATION, float(ATTACK[kind]) * _tier_damage_scale(kind) * float(TRANSCENDENT_POWER["poison"]))
	if skills.has("hp_percent") and rng.randf() < float(TRANSCENDENT_CHANCE["hp_percent"]):
		var bonus: float = minf(float(enemies[target]["max_hp"]) * float(TRANSCENDENT_POWER["hp_percent"]), TRANSCENDENT_HP_BONUS_CAP)
		_hit_enemy(target, bonus)
	if skills.has("burn") and rng.randf() < float(TRANSCENDENT_CHANCE["burn"]):
		_apply_status(target, "burn", TRANSCENDENT_DOT_DURATION, damage * float(TRANSCENDENT_POWER["burn"]))
	if skills.has("magic_res") and rng.randf() < float(TRANSCENDENT_CHANCE["magic_res"]):
		_apply_status(target, "magic_res", ARMOR_DURATION, float(TRANSCENDENT_POWER["magic_res"]))
	if skills.has("slow") and rng.randf() < float(TRANSCENDENT_CHANCE["slow"]):
		_apply_status(target, "slow", SLOW_DURATION, float(TRANSCENDENT_POWER["slow"]))
	var splash_proc: bool = skills.has("magic_splash") and rng.randf() < float(TRANSCENDENT_CHANCE["magic_splash"])
	var stun_proc: bool = skills.has("area_stun") and rng.randf() < float(TRANSCENDENT_CHANCE["area_stun"])
	if splash_proc or stun_proc:
		var impact: Vector2 = _route_point(float(enemies[target]["progress"]))
		for i in range(enemies.size()):
			if float(enemies[i]["hp"]) <= 0.0:
				continue
			if impact.distance_to(_route_point(float(enemies[i]["progress"]))) > TRANSCENDENT_AOE_RADIUS:
				continue
			if splash_proc and i != target:
				_hit_enemy(i, damage * float(TRANSCENDENT_POWER["magic_splash"]), true)
			if stun_proc:
				_apply_status(i, "stun", float(TRANSCENDENT_POWER["area_stun"]))

func _attack_with_skills(dog_index: int, target: int, auras: Dictionary) -> void:
	var kind: int = int(dogs[dog_index]["kind"])
	_emit_attack_visual(dog_index, target)
	var tier: String = GRADES[kind]
	if tier == "초월":
		_attack_transcendent(dog_index, target, auras)
		return
	if tier == "신화":
		_attack_mythic(dog_index, target, auras)
		return
	if tier == "맹수":
		_attack_beast(dog_index, target, auras)
		return
	var skills: Array = DOG_SKILLS.get(kind, [])
	var chance: Dictionary = SKILL_CHANCE[tier]
	var power: Dictionary = SKILL_POWER[tier]
	var damage: float = float(ATTACK[kind]) * _tier_damage_scale(kind) * (1.0 + float(auras["damage"]))
	if skills.has("crit") and rng.randf() < float(chance["crit"]):
		damage *= float(power["crit"])
	_hit_basic_dog_enemy(kind, target, damage)
	if skills.has("multi") and rng.randf() < float(chance["multi"]):
		_hit_basic_dog_enemy(kind, target, damage * float(power["multi"]))
	if skills.has("bleed") and rng.randf() < float(chance["bleed"]):
		_apply_status(target, "bleed", BLEED_DURATION, float(ATTACK[kind]) * _tier_damage_scale(kind) * float(power["bleed"]) * _matchup_multiplier(kind, target))
	if skills.has("stun") and rng.randf() < float(chance["stun"]):
		_apply_status(target, "stun", float(power["stun"]))
	if skills.has("slow") and rng.randf() < float(chance["slow"]):
		_apply_status(target, "slow", SLOW_DURATION, float(power["slow"]))
	if skills.has("armor") and rng.randf() < float(chance["armor"]):
		_apply_status(target, "armor", ARMOR_DURATION, float(power["armor"]))
	if skills.has("splash") and rng.randf() < float(chance["splash"]):
		var impact: Vector2 = _route_point(float(enemies[target]["progress"]))
		for other_idx in range(enemies.size()):
			if other_idx == target or float(enemies[other_idx]["hp"]) <= 0.0:
				continue
			if impact.distance_to(_route_point(float(enemies[other_idx]["progress"]))) <= 75.0:
				_hit_basic_dog_enemy(kind, other_idx, damage * float(power["splash"]))

func _clear_defeated() -> void:
	var boss_was_killed: bool = false
	for i in range(enemies.size() - 1, -1, -1):
		if float(enemies[i]["hp"]) <= 0.0:
			var was_boss: bool = bool(enemies[i].get("is_boss", false))
			enemies.remove_at(i)
			var earned: int = _boss_kill_reward(boss_round) if was_boss else KILL_REWARD
			gold += earned
			if was_boss:
				last_economy_notice = "보스 %d 처치 +%dG" % [boss_round, earned]
				if draw_feedback != null:
					draw_feedback.text = last_economy_notice
			if was_boss and boss_running:
				boss_was_killed = true
	if boss_was_killed:
		_complete_boss_round(true)

func _field_limit() -> int:
	return int(FIELD_LIMITS.get(difficulty, 90))

func _simulation_step(delta: float) -> void:
	# Start the next wave on the frame AFTER completion, preserving completion UI.
	if auto_advance_pending and not wave_running and not game_over and not victory and difficulty_confirmed:
		auto_advance_pending = false
		_start_wave()
	if not wave_running or game_over:
		return
	# All combat clocks use the same scaled game time; no global Engine.time_scale changes.
	var game_delta: float = delta
	var active_delta: float = minf(game_delta, wave_time_left)
	wave_time_left = maxf(0.0, wave_time_left - game_delta)
	spawn_clock -= active_delta
	# Step22: process every spawn interval elapsed in this frame. The older
	# single-spawn branch silently lost enemies on lag spikes and at 2x/3x.
	# Spawn count is bounded by spawn_left (18 max), so the loop is safe.
	while not boss_running and spawn_left > 0 and spawn_clock <= 0.0 and active_delta > 0.0:
		var stats: Dictionary = _regular_wave_stats(wave)
		enemies.append({"progress": 0.0, "hp": stats["hp"], "max_hp": stats["hp"], "armor": stats["armor"], "magic_res": stats["magic_res"], "move_speed": stats["move_speed"], "enemy_type": wave_enemy_type, "effects": {}})
		spawn_left -= 1
		spawn_clock += REGULAR_SPAWN_INTERVAL
		if enemies.size() >= _field_limit():
			game_over = true
			wave_running = false
			break
	if game_over:
		_refresh()
		return
	_tick_enemy_effects(game_delta)
	_clear_defeated()
	for idx in range(enemies.size() - 1, -1, -1):
		var effects: Dictionary = enemies[idx].get("effects", {})
		var stunned: bool = effects.has("stun") or effects.has("freeze")
		var slow_power: float = float(effects.get("slow", {}).get("power", 0.0))
		var speed_factor: float = 0.0 if stunned else 1.0 - slow_power
		enemies[idx]["progress"] = float(enemies[idx]["progress"]) + game_delta * float(enemies[idx].get("move_speed", BASE_ENEMY_MOVE_SPEED)) * speed_factor
		if float(enemies[idx]["progress"]) >= 4.0:
			# Completing the route is not a leak: monsters circle the board.
			enemies[idx]["progress"] = fposmod(float(enemies[idx]["progress"]), 4.0)
	if not game_over:
		_ensure_aura_cache()
		var enemy_positions: Array[Vector2] = []
		for enemy in enemies:
			enemy_positions.append(_route_point(float(enemy["progress"])))
		for d in range(dogs.size()):
			var dog_kind: int = int(dogs[d]["kind"])
			var auras: Dictionary = _cached_auras[d]
			dogs[d]["cooldown"] = maxf(0.0, float(dogs[d]["cooldown"]) - game_delta)
			if float(dogs[d]["cooldown"]) > 0.0:
				continue
			var dog_position: Vector2 = _cell_center(int(dogs[d]["cell"]))
			var target: int = -1
			var furthest: float = -1.0
			for e in range(enemies.size()):
				if float(enemies[e]["hp"]) <= 0.0:
					continue
				if dog_position.distance_to(enemy_positions[e]) <= float(RANGE[dog_kind]) and float(enemies[e]["progress"]) > furthest:
					target = e
					furthest = float(enemies[e]["progress"])
			if target >= 0:
				dogs[d]["cooldown"] = float(COOLDOWN[dog_kind]) * (1.0 - clampf(float(auras.get("cooldown", 0.0)), 0.0, 0.5)) / (1.0 + float(auras["speed"]))
				_attack_with_skills(d, target, auras)
		_clear_defeated()
	if wave_running and wave_time_left <= 0.0:
		if boss_running:
			_complete_boss_round(false)
		else:
			_complete_regular_wave()
	_refresh()

func _restart() -> void:
	paused = false
	simulation_accumulator = 0.0
	combat_fx.clear()
	attack_flashes.clear()
	if persistence_enabled:
		RunStorage.clear_save()
	game_speed = 1
	gold = 100
	first_beast_claimed = false
	first_mythic_claimed = false
	first_transcendent_claimed.clear()
	last_economy_notice = ""
	_refresh_missions()
	if mission_panel != null:
		mission_panel.visible = false
	if settings_panel != null:
		settings_panel.visible = false
	if restart_confirmation != null:
		restart_confirmation.hide()
	beast_items.clear()
	draw_history.clear()
	draw_info_signature = ""
	if draw_info_panel != null:
		draw_info_panel.visible = false
	if draw_feedback != null:
		draw_feedback.text = "맹수 3% · 신화 1% · 초월 0.1% · 골드 0~10배"
	wave = 0
	difficulty = "보통"
	difficulty_confirmed = false
	if difficulty_panel != null:
		difficulty_panel.visible = true
	lives = 10
	dogs.clear()
	enemies.clear()
	selected = -1
	spawn_left = 0
	spawn_clock = 0.0
	wave_time_left = 0.0
	wave_enemy_type = ""
	last_completed_wave = 0
	boss_round = 0
	boss_pending = false
	boss_running = false
	victory = false
	wave_running = false
	auto_advance_pending = false
	game_over = false
	if recipe_panel != null:
		recipe_panel.visible = false
	_refresh()

func _refresh() -> void:
	if _in_simulation:
		return
	if pause_button != null:
		pause_button.text = "▶" if paused else "Ⅱ"
	if mission_button != null:
		mission_button.disabled = not difficulty_confirmed
	if sell_button != null:
		var selected_kind: int = int(dogs[selected]["kind"]) if selected >= 0 and selected < dogs.size() else -1
		var sale_price: int = _sell_value(selected_kind)
		sell_button.visible = selected_kind >= 0 and not game_over and difficulty_confirmed
		sell_button.disabled = sale_price == 0
		sell_button.text = "판매 +%dG" % sale_price if sale_price > 0 else "판매 불가"
		if selected_context_panel != null and selected_context_label != null:
			selected_context_panel.visible = sell_button.visible
			selected_context_label.visible = sell_button.visible
			if selected_kind >= 0:
				var effects: Array[String] = []
				for skill in DOG_SKILLS.get(selected_kind, []):
					effects.append(str(SKILL_NAMES.get(skill, skill)))
				var effect_summary: String = ", ".join(PackedStringArray(effects)) if not effects.is_empty() else "없음"
				var auras: Dictionary = _effective_auras(selected)
				var current_attack: float = float(ATTACK[selected_kind]) * _tier_damage_scale(selected_kind) * (1.0 + float(auras["damage"]))
				if _unit_is_magic(selected_kind):
					current_attack *= 1.0 + float(auras["magic"])
				var reach_note: String = "" if _cell_reaches_path(int(dogs[selected]["cell"]), float(RANGE[selected_kind])) else " · 공격 불가/지원"
				selected_context_label.text = "%s [%s]%s\n공격 %.0f (기본 %.0f) · 사거리 %.0f\n%s" % [DOGS[selected_kind], GRADES[selected_kind], reach_note, current_attack, ATTACK[selected_kind], RANGE[selected_kind], effect_summary]
	if speed_button != null:
		speed_button.text = "%dx" % game_speed
		speed_button.disabled = not difficulty_confirmed or game_over or victory
	if status_label == null:
		return
	status_label.text = "적 %d/%d" % [enemies.size(), _field_limit()]
	gold_hud_label.text = "🪙 %dG" % gold
	if wave_hud_label != null:
		wave_hud_label.text = "WAVE %d/88\n%s · %s" % [wave + boss_round, "보스 웨이브" if boss_running or boss_pending else "일반 웨이브", difficulty]
	if not difficulty_confirmed:
		info_label.text = "난이도 선택 후 게임을 시작하세요."
	elif victory:
		info_label.text = "최종 보스 격파! 80 일반 + 8 보스 라운드 승리!"
	elif game_over:
		info_label.text = "게임 오버! 설정 → 다시하기로 재도전하세요."
	elif selected >= 0 and selected < dogs.size():
		var kind: int = int(dogs[selected]["kind"])
		var skill_labels: Array[String] = []
		for skill in DOG_SKILLS.get(kind, []):
			skill_labels.append(str(SKILL_NAMES.get(skill, skill)))
		var skill_text: String = " / ".join(PackedStringArray(skill_labels)) if not skill_labels.is_empty() else "없음"
		info_label.text = "선택: %s (%s) | 공격 %.0f | 특수: %s" % [DOGS[kind], GRADES[kind], ATTACK[kind], skill_text]
	elif boss_running:
		info_label.text = "보스 %d/%d · 남은 시간 %.1f초 · 보스 HP %.0f" % [boss_round, MAX_BOSS_ROUNDS, wave_time_left, float(enemies[0]["hp"]) if not enemies.is_empty() else 0.0]
	elif wave_running:
		info_label.text = "%s 유형 · 남은 시간 %.1f초 · 필드 %d/%d · 대기 %d" % [wave_enemy_type, wave_time_left, enemies.size(), _field_limit(), spawn_left]
	elif boss_pending:
		info_label.text = "일반 %d웨이브 완료! 보스 %d 출현 준비" % [wave, int(wave / BOSS_INTERVAL)]
	elif wave >= MAX_REGULAR_WAVE:
		info_label.text = "모든 일반 웨이브 완료!"
	else:
		info_label.text = "소형견 소환 → 재료 모으기 → 도감 확인 → 상위견 조합!"
	summon_button.disabled = not difficulty_confirmed or game_over or gold < COST or dogs.size() >= COLS * ROWS
	wave_button.text = "보스 %d 시작" % int(wave / BOSS_INTERVAL) if boss_pending else "웨이브 시작"
	wave_button.disabled = not difficulty_confirmed or game_over or victory or wave_running or (wave >= MAX_REGULAR_WAVE and not boss_pending)
	if draw_button != null:
		draw_button.disabled = game_over or gold < DRAW_COST
	if mythic_draw_button != null:
		mythic_draw_button.disabled = game_over or gold < DRAW_COST
	if transcendent_draw_button != null:
		transcendent_draw_button.disabled = game_over or gold < DRAW_COST
	if fusion_button != null:
		fusion_button.disabled = game_over or selected < 0 or not _has_recipe_for_selected()
	if recipe_panel != null and recipe_panel.visible:
		_refresh_recipes()
	if draw_info_panel != null and draw_info_panel.visible:
		_refresh_draw_info()
	board.queue_redraw()

# Fusion consumes one matching material per recipe entry. The selected unit must
# be one of the ingredients, and the result occupies its board cell.
func _recipe_item_ready(recipe: Dictionary) -> bool:
	if not recipe.has("item"):
		return true
	var item_id: int = int(recipe["item"])
	return int(beast_items.get(item_id, 0)) >= 1

func _consume_recipe_item(recipe: Dictionary) -> void:
	if recipe.has("item"):
		var item_id: int = int(recipe["item"])
		beast_items[item_id] = int(beast_items.get(item_id, 0)) - 1
		draw_info_signature = ""

func _find_recipe_materials(recipe: Dictionary, required_selected: bool) -> Array[int]:
	var chosen: Array[int] = []
	var ingredients: Array = recipe["materials"]
	if required_selected:
		if selected < 0 or selected >= dogs.size():
			return []
		var selected_kind: int = int(dogs[selected]["kind"])
		if not ingredients.has(selected_kind):
			return []
		chosen.append(selected)
	var remaining: Array = ingredients.duplicate()
	if required_selected:
		remaining.erase(int(dogs[selected]["kind"]))
	for material in remaining:
		var found: int = -1
		for i in range(dogs.size()):
			if chosen.has(i):
				continue
			if int(dogs[i]["kind"]) == int(material):
				found = i
				break
		if found == -1:
			return []
		chosen.append(found)
	return chosen

func _has_recipe_for_selected() -> bool:
	for recipe in RECIPES:
		if _recipe_item_ready(recipe) and _find_recipe_materials(recipe, true).size() == recipe["materials"].size():
			return true
	return false

func _fuse_selected() -> void:
	if game_over or selected < 0 or selected >= dogs.size():
		return
	for recipe in RECIPES:
		var ingredients: Array = recipe["materials"]
		if not _recipe_item_ready(recipe):
			continue
		if ingredients.size() != 3:
			continue
		var materials: Array[int] = _find_recipe_materials(recipe, true)
		if materials.size() != 3:
			continue
		# Verify distinct dog instances and the whole recipe before modifying the board.
		var unique_indices: Dictionary = {}
		var remaining: Array = ingredients.duplicate()
		var valid: bool = true
		for index in materials:
			if index < 0 or index >= dogs.size() or unique_indices.has(index):
				valid = false
				break
			unique_indices[index] = true
			var kind: int = int(dogs[index]["kind"])
			if not remaining.has(kind):
				valid = false
				break
			remaining.erase(kind)
		if not valid or not remaining.is_empty() or not unique_indices.has(selected):
			continue
		var result_kind: int = int(recipe["result"])
		if result_kind < 0 or result_kind >= DOGS.size():
			continue
		var target_cell: int = int(dogs[selected]["cell"])
		if target_cell < 0 or target_cell >= COLS * ROWS:
			continue
		# Only after every check passes, consume three distinct ingredients.
		materials.sort()
		materials.reverse()
		for index in materials:
			dogs.remove_at(index)
		_consume_recipe_item(recipe)
		dogs.append({"cell": target_cell, "kind": result_kind, "cooldown": 0.0})
		_on_successful_fusion(result_kind)
		selected = dogs.size() - 1
		_refresh()
		return

# Direct crafting from the recipe catalog. Existing selected-unit fusion is untouched.
# This duplicates neither a material instance nor any gold cost; all checks precede mutations.
func _craft_recipe_from_catalog(result_kind: int) -> void:
	if game_over:
		_set_recipe_feedback("게임 오버 상태에서는 조합할 수 없습니다.", false)
		return
	var target_recipe: Dictionary = {}
	for recipe in RECIPES:
		if int(recipe["result"]) == result_kind:
			target_recipe = recipe
			break
	if target_recipe.is_empty():
		_set_recipe_feedback("조합식을 찾을 수 없습니다.", false)
		return
	if not _recipe_item_ready(target_recipe):
		_set_recipe_feedback("전용 아이템 부족: " + str(BEAST_ITEMS.get(result_kind, "필요")), false)
		return
	var materials: Array[int] = _find_recipe_materials(target_recipe, false)
	if materials.size() != 3:
		_set_recipe_feedback("재료가 부족합니다: " + DOGS[result_kind], false)
		return
	# Revalidate all three separate indices and kinds before removing anything.
	var required: Array = target_recipe["materials"].duplicate()
	var unique: Dictionary = {}
	for index in materials:
		if index < 0 or index >= dogs.size() or unique.has(index):
			_set_recipe_feedback("조합 재료 검증 실패", false)
			return
		unique[index] = true
		var kind: int = int(dogs[index]["kind"])
		if not required.has(kind):
			_set_recipe_feedback("조합 재료 종류 불일치", false)
			return
		required.erase(kind)
	if not required.is_empty() or result_kind < 0 or result_kind >= DOGS.size():
		_set_recipe_feedback("조합 데이터 오류", false)
		return
	# Retain the chosen unit's cell if it is an ingredient, otherwise use the first ingredient.
	var target_index: int = selected if unique.has(selected) else materials[0]
	var target_cell: int = int(dogs[target_index]["cell"])
	if target_cell < 0 or target_cell >= COLS * ROWS:
		_set_recipe_feedback("잘못된 배치 위치", false)
		return
	materials.sort()
	materials.reverse()
	for index in materials:
		dogs.remove_at(index)
	_consume_recipe_item(target_recipe)
	dogs.append({"cell": target_cell, "kind": result_kind, "cooldown": 0.0})
	var mission_gold: int = _on_successful_fusion(result_kind)
	selected = dogs.size() - 1
	recipe_last_signature = ""
	_refresh()
	_set_recipe_feedback("조합 성공! " + DOGS[result_kind] + " 획득" + (" · 미션 +%dG" % mission_gold if mission_gold > 0 else ""), true)

func _set_recipe_feedback(message: String, success: bool) -> void:
	if recipe_feedback == null:
		return
	recipe_feedback.text = message
	recipe_feedback.add_theme_color_override("font_color", Color("#a9f3ba") if success else Color("#ffd0a6"))

func _set_recipe_filter(value: String) -> void:
	recipe_filter = value
	recipe_last_signature = ""
	_refresh_recipes()

func _build_recipe_panel() -> void:
	recipe_panel = PanelContainer.new()
	recipe_panel.position = Vector2(14, 82)
	recipe_panel.size = Vector2(692, 893)
	recipe_panel.z_index = 210
	recipe_panel.visible = false
	recipe_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(recipe_panel)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 7)
	recipe_panel.add_child(outer)
	_apply_popup_text_theme(outer)
	var header := HBoxContainer.new()
	outer.add_child(header)
	var title := Label.new()
	title.text = "조합 · 39종"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 22)
	header.add_child(title)
	var gallery_button := Button.new()
	gallery_button.text = "49종 유닛 보기"
	gallery_button.custom_minimum_size = Vector2(180, 46)
	gallery_button.pressed.connect(_open_unit_gallery)
	header.add_child(gallery_button)
	var close := Button.new()
	close.text = "닫기 ✕"
	close.custom_minimum_size = Vector2(105, 46)
	close.pressed.connect(_toggle_recipes)
	header.add_child(close)
	var filters := GridContainer.new()
	filters.name = "RecipeFilterGrid"
	filters.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	filters.columns = 3
	filters.add_theme_constant_override("h_separation", 8)
	filters.add_theme_constant_override("v_separation", 8)
	outer.add_child(filters)
	for pair in [["전체", "전체 39종"], ["중형견", "중형견 13종"], ["대형견", "대형견 13종"], ["맹수", "맹수 6종"], ["신화", "신화 4종"], ["초월", "초월 3종"]]:
		var filter_button := Button.new()
		filter_button.text = str(pair[1])
		filter_button.custom_minimum_size = Vector2(0, 43)
		filter_button.add_theme_font_size_override("font_size", 15)
		filter_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		filter_button.size_flags_stretch_ratio = 1.0
		filter_button.pressed.connect(_set_recipe_filter.bind(str(pair[0])))
		filters.add_child(filter_button)
	# Visually separate the recipe tabs from their explanation and recipe list.
	var recipe_content_gap := Control.new()
	recipe_content_gap.name = "RecipeContentGap"
	recipe_content_gap.custom_minimum_size = Vector2(0, 12)
	recipe_content_gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outer.add_child(recipe_content_gap)
	recipe_feedback = Label.new()
	recipe_feedback.text = "재료가 충분하면 제작 버튼을 누르세요."
	recipe_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	recipe_feedback.custom_minimum_size = Vector2(0, 32)
	recipe_feedback.add_theme_font_size_override("font_size", 18)
	outer.add_child(recipe_feedback)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(610, 600)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(scroll)
	recipe_list = VBoxContainer.new()
	recipe_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	recipe_list.add_theme_constant_override("separation", 8)
	scroll.add_child(recipe_list)

func _toggle_recipes() -> void:
	if draw_info_panel != null:
		draw_info_panel.visible = false
	recipe_panel.visible = not recipe_panel.visible
	if recipe_panel.visible:
		recipe_last_signature = ""
		_refresh_recipes()

func _refresh_recipes() -> void:
	if recipe_list == null:
		return
	var owned: Dictionary = {}
	for dog in dogs:
		var kind: int = int(dog["kind"])
		owned[kind] = int(owned.get(kind, 0)) + 1
	# _refresh is called every frame. Rebuild the list only on inventory/filter changes.
	var signature: String = recipe_filter + ":" + str(game_over)
	for kind in range(DOGS.size()):
		signature += "," + str(int(owned.get(kind, 0)))
	for item_id in BEAST_ITEMS.keys():
		signature += ",item" + str(item_id) + ":" + str(int(beast_items.get(item_id, 0)))
	if signature == recipe_last_signature:
		return
	recipe_last_signature = signature
	for child in recipe_list.get_children():
		recipe_list.remove_child(child)
		child.queue_free()
	for recipe in RECIPES:
		var result_kind: int = int(recipe["result"])
		if recipe_filter != "전체" and GRADES[result_kind] != recipe_filter:
			continue
		var needed: Dictionary = {}
		for material in recipe["materials"]:
			var material_kind: int = int(material)
			needed[material_kind] = int(needed.get(material_kind, 0)) + 1
		var parts: Array[String] = []
		var ready: bool = true
		for kind in needed.keys():
			var have: int = int(owned.get(kind, 0))
			var count: int = int(needed[kind])
			parts.append("%s %d/%d" % [DOGS[int(kind)], have, count])
			if have < count:
				ready = false
		if recipe.has("item"):
			var item_id: int = int(recipe["item"])
			var item_count: int = int(beast_items.get(item_id, 0))
			parts.append("%s %d/1" % [str(BEAST_ITEMS[item_id]), item_count])
			if item_count < 1:
				ready = false
		var entry := VBoxContainer.new()
		entry.add_theme_constant_override("separation", 3)
		recipe_list.add_child(entry)
		var name_label := Label.new()
		name_label.text = "%s  [%s]" % [DOGS[result_kind], GRADES[result_kind]]
		name_label.add_theme_font_size_override("font_size", 21)
		entry.add_child(name_label)
		var material_label := Label.new()
		material_label.text = "재료: " + " + ".join(PackedStringArray(parts))
		material_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		material_label.custom_minimum_size = Vector2(450, 38)
		material_label.add_theme_font_size_override("font_size", 17)
		entry.add_child(material_label)
		var craft_button := Button.new()
		craft_button.text = "제작하기" if ready and not game_over else "재료 부족" if not ready else "게임 종료"
		craft_button.disabled = not ready or game_over
		craft_button.custom_minimum_size = Vector2(535, 62)
		craft_button.pressed.connect(_craft_recipe_from_catalog.bind(result_kind))
		entry.add_child(craft_button)
		var separator := HSeparator.new()
		entry.add_child(separator)

# Step9: presentation-only draw inventory, recent results and exact odds.
# Stored in memory for the current run; no changes to Step8 reward distribution.
func _record_draw(reward: Dictionary, category: String = "맹수") -> void:
	var entry: Dictionary = reward.duplicate(true)
	entry["category"] = category
	if reward.get("type", "") == "item":
		entry["label"] = category + " 전용 아이템 · " + str(BEAST_ITEMS.get(int(reward["item"]), "알 수 없음"))
	else:
		entry["label"] = category + " 골드 %d배 · +%dG" % [int(reward.get("multiplier", 0)), int(reward.get("gold", 0))]
	draw_history.push_front(entry)
	if draw_history.size() > DRAW_HISTORY_MAX:
		draw_history.resize(DRAW_HISTORY_MAX)
	draw_info_signature = ""

func _build_draw_info_panel() -> void:
	draw_info_panel = PanelContainer.new()
	draw_info_panel.position = Vector2(14, 82)
	draw_info_panel.size = Vector2(692, 893)
	draw_info_panel.z_index = 210
	draw_info_panel.visible = false
	draw_info_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(draw_info_panel)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 7)
	draw_info_panel.add_child(outer)
	_apply_popup_text_theme(outer)
	var header := HBoxContainer.new()
	outer.add_child(header)
	var title := Label.new()
	title.text = "뽑기 정보 · 50G"
	title.add_theme_font_size_override("font_size", 22)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close := Button.new()
	close.text = "닫기 ✕"
	close.custom_minimum_size = Vector2(105, 46)
	close.pressed.connect(_toggle_draw_info)
	header.add_child(close)
	# Both selection rows occupy the same full available width as the scroll area.
	# Equal expand ratios keep three buttons aligned on narrow portrait screens.
	var categories := HBoxContainer.new()
	categories.name = "DrawCategoryRow"
	categories.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	categories.add_theme_constant_override("separation", 6)
	outer.add_child(categories)
	for category in ["맹수", "신화", "초월"]:
		var category_button := Button.new()
		category_button.text = category + " 뽑기"
		category_button.custom_minimum_size = Vector2(0, 43)
		category_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		category_button.size_flags_stretch_ratio = 1.0
		category_button.pressed.connect(_set_draw_info_category.bind(category))
		categories.add_child(category_button)
	var tabs := HBoxContainer.new()
	tabs.name = "DrawInfoTabRow"
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.add_theme_constant_override("separation", 6)
	outer.add_child(tabs)
	for tab_name in ["보유 아이템", "최근 결과", "확률표"]:
		var tab := Button.new()
		tab.text = tab_name
		tab.custom_minimum_size = Vector2(0, 45)
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.size_flags_stretch_ratio = 1.0
		tab.pressed.connect(_set_draw_info_tab.bind(tab_name))
		tabs.add_child(tab)
	# Keep the first content line away from the bottom row of selection tabs.
	var draw_content_gap := Control.new()
	draw_content_gap.name = "DrawContentGap"
	draw_content_gap.custom_minimum_size = Vector2(0, 14)
	draw_content_gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outer.add_child(draw_content_gap)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(610, 620)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(scroll)
	draw_info_list = VBoxContainer.new()
	draw_info_list.custom_minimum_size = Vector2(570, 0)
	draw_info_list.add_theme_constant_override("separation", 13)
	scroll.add_child(draw_info_list)

func _toggle_draw_info() -> void:
	if draw_info_panel == null:
		return
	if recipe_panel != null:
		recipe_panel.visible = false
	draw_info_panel.visible = not draw_info_panel.visible
	if draw_info_panel.visible:
		draw_info_signature = ""
		_refresh_draw_info()

func _set_draw_info_category(category: String) -> void:
	if category not in ["맹수", "신화", "초월"]:
		return
	draw_info_category = category
	draw_info_signature = ""
	_refresh_draw_info()

func _set_draw_info_tab(tab_name: String) -> void:
	draw_info_tab = tab_name
	draw_info_signature = ""
	_refresh_draw_info()

func _draw_info_line(message: String, size: int = 19) -> void:
	var label := Label.new()
	label.text = message
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(530, 37)
	label.add_theme_font_size_override("font_size", size)
	draw_info_list.add_child(label)

func _refresh_draw_info() -> void:
	if draw_info_list == null:
		return
	var signature: String = draw_info_category + ":" + draw_info_tab + ":" + str(draw_history.size()) + ":" + str(game_over)
	for item_id in DRAW_ITEM_IDS + MYTHIC_DRAW_ITEM_IDS + TRANSCENDENT_DRAW_ITEM_IDS:
		signature += ":" + str(int(beast_items.get(item_id, 0)))
	if signature == draw_info_signature:
		return
	draw_info_signature = signature
	for child in draw_info_list.get_children():
		draw_info_list.remove_child(child)
		child.queue_free()
	var active_ids: Array = TRANSCENDENT_DRAW_ITEM_IDS if draw_info_category == "초월" else MYTHIC_DRAW_ITEM_IDS if draw_info_category == "신화" else DRAW_ITEM_IDS
	if draw_info_tab == "보유 아이템":
		_draw_info_line(draw_info_category + " 전용 아이템 보유 현황", 23)
		for item_id in active_ids:
			var owned: int = int(beast_items.get(item_id, 0))
			_draw_info_line("%s · %s: %d개" % [DOGS[item_id], str(BEAST_ITEMS[item_id]), owned])
		_draw_info_line("초월 제작: 신화 2마리 + 맹수 1마리 + 해당 아이템 1개" if draw_info_category == "초월" else "신화 제작: 맹수 3마리 + 해당 아이템 1개" if draw_info_category == "신화" else "맹수 제작: 대형견 3마리 + 해당 아이템 1개", 17)
		_draw_info_line("재료별 제작 가능 여부는 조합 도감에서 확인", 17)
	elif draw_info_tab == "최근 결과":
		_draw_info_line("최근 뽑기 결과 (최대 20회)", 23)
		if draw_history.is_empty():
			_draw_info_line("아직 뽑기 기록이 없습니다.")
		var shown: int = 0
		for entry in draw_history:
			if str(entry.get("category", "맹수")) != draw_info_category:
				continue
			shown += 1
			_draw_info_line("%d. %s" % [shown, str(entry["label"])])
		if shown == 0 and not draw_history.is_empty():
			_draw_info_line("이 뽑기 유형의 기록이 없습니다.")
	else:
		_draw_info_line("확률 안내 · 1회 50G", 23)
		var item_percent: float = 0.1 if draw_info_category == "초월" else 1.0 if draw_info_category == "신화" else 3.0
		var gold_percent: float = 99.7 if draw_info_category == "초월" else 96.0 if draw_info_category == "신화" else 82.0
		_draw_info_line("%s 전용 아이템 총 %.1f%% (%d종 각 %.1f%%)" % [draw_info_category, 100.0 - gold_percent, active_ids.size(), item_percent])
		for item_id in active_ids:
			_draw_info_line("%s · %.3f%%" % [str(BEAST_ITEMS[item_id]), float(item_percent)], 17)
		_draw_info_line("골드 보상 총 %.1f%%" % gold_percent, 21)
		for multiplier in range(DRAW_GOLD_WEIGHTS.size()):
			var chance: float = float(gold_percent) * float(DRAW_GOLD_WEIGHTS[multiplier]) / float(DRAW_GOLD_WEIGHT_TOTAL)
			_draw_info_line("%d배 · %dG  |  %.3f%%" % [multiplier, multiplier * DRAW_COST, chance], 18)
		_draw_info_line("골드는 뽑기 비용 50G를 먼저 차감한 뒤 지급", 17)

func _cell_reaches_path(cell: int, attack_range: float) -> bool:
	var center: Vector2 = _cell_center(cell)
	for i in range(ROUTE.size()):
		var nearest: Vector2 = Geometry2D.get_closest_point_to_segment(center, ROUTE[i], ROUTE[(i + 1) % ROUTE.size()])
		if center.distance_to(nearest) <= attack_range:
			return true
	return false

func _unit_is_magic(kind: int) -> bool:
	var skills: Array = DOG_SKILLS.get(kind, [])
	if kind >= 42 and kind <= 45:
		return skills.has("magic_splash") or skills.has("chain") or skills.has("burn")
	return skills.has("magic_splash")

func _toggle_pause() -> void:
	if not difficulty_confirmed or game_over or victory:
		return
	paused = not paused
	if paused and persistence_enabled:
		RunStorage.save(self)
	_refresh()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if difficulty_confirmed and not game_over and not victory:
			paused = true
			if persistence_enabled:
				RunStorage.save(self)
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_toggle_settings()

func _process(delta: float) -> void:
	if not paused:
		simulation_accumulator += maxf(0.0, delta) * float(game_speed)
		var steps: int = 0
		_in_simulation = true
		while simulation_accumulator + 0.0000001 >= SIM_STEP and steps < 6000:
			_simulation_step(SIM_STEP)
			simulation_accumulator = maxf(0.0, simulation_accumulator - SIM_STEP)
			steps += 1
			if game_over or victory:
				if persistence_enabled: RunStorage.clear_save()
				simulation_accumulator = 0.0
				break
		_in_simulation = false
		presentation_clock += delta * float(game_speed)
		for fx in combat_fx:
			fx["age"] = float(fx["age"]) + delta * float(game_speed)
		for i in range(combat_fx.size() - 1, -1, -1):
			if float(combat_fx[i]["age"]) > float(combat_fx[i]["duration"]):
				combat_fx.remove_at(i)
	ui_clock += delta
	save_clock += delta
	if ui_clock >= 0.1:
		ui_clock = 0.0
		_refresh()
	if board != null:
		board.queue_redraw()
	if persistence_enabled and save_clock >= 10.0 and difficulty_confirmed:
		save_clock = 0.0
		RunStorage.save(self)

func _emit_attack_visual(dog_index: int, target: int) -> void:
	if not visual_effects_enabled or target < 0 or target >= enemies.size():
		return
	var dog: Dictionary = dogs[dog_index]
	var kind: int = int(dog["kind"])
	var style: String = "bolt"
	if kind == 42: style = "ice"
	elif kind == 44: style = "lightning"
	elif kind == 47: style = "sun"
	elif kind == 48: style = "hell"
	elif kind == 46: style = "poison"
	elif _unit_is_magic(kind): style = "magic"
	attack_flashes[int(dog["cell"])] = presentation_clock
	if combat_fx.size() >= 96:
		combat_fx.pop_front()
	combat_fx.append({"from": _cell_center(int(dog["cell"])), "to": _route_point(float(enemies[target]["progress"])), "style": style, "age": 0.0, "duration": 0.3})

func _ensure_aura_cache() -> void:
	var signature: String = ""
	for dog in dogs:
		signature += "%d:%d;" % [int(dog["kind"]), int(dog["cell"])]
	if signature == _aura_signature and _cached_auras.size() == dogs.size():
		return
	_aura_signature = signature
	_cached_auras.clear()
	for i in range(dogs.size()):
		_cached_auras.append(_effective_auras(i))

func _open_unit_gallery() -> void:
	if unit_gallery != null:
		unit_gallery.visible = true
		return
	unit_gallery = PanelContainer.new()
	unit_gallery.position = Vector2(14, 82)
	unit_gallery.size = Vector2(692, 1090)
	unit_gallery.z_index = 230
	add_child(unit_gallery)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 12)
	unit_gallery.add_child(outer)
	_apply_popup_text_theme(outer)
	var header := HBoxContainer.new()
	outer.add_child(header)
	var title := Label.new()
	title.text = "천공 성채 · 49종 유닛 도감"
	title.add_theme_font_size_override("font_size", 23)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close := Button.new()
	close.text = "닫기"
	close.custom_minimum_size = Vector2(100, 52)
	close.pressed.connect(func() -> void: unit_gallery.visible = false)
	header.add_child(close)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(620, 950)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(grid)
	for kind in range(49):
		var card := VBoxContainer.new()
		card.custom_minimum_size = Vector2(300, 260)
		grid.add_child(card)
		var portrait := TextureRect.new()
		portrait.texture = _dog_portrait(kind)
		portrait.custom_minimum_size = Vector2(290, 160)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		card.add_child(portrait)
		var label := Label.new()
		label.text = "%s · %s\n공격 %.0f · 사거리 %.0f\n공격 주기 %.2f초" % [DOGS[kind], GRADES[kind], ATTACK[kind], RANGE[kind], COOLDOWN[kind]]
		label.add_theme_font_size_override("font_size", 17)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_child(label)
