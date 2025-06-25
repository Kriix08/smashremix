// This file contains this characters AI attacks

// Create new cpu attack behaviours
OS.align(4)
CPU_ATTACKS:
// grounded attacks
// add_attack_behaviour(table, attack, hitbox_start_frame, min_x, max_x, min_y, max_y)
AI.add_attack_behaviour(JAB,    2, 118, 353, 120, 264)
AI.add_attack_behaviour(FTILT,  7, 123, 437, 77, 217)
AI.add_attack_behaviour(UTILT,  5, -197, 197, 118, 723)
AI.add_attack_behaviour(DTILT,  4, 92, 410, -18, 96)
AI.add_attack_behaviour(FSMASH, 12, 125, 541, 10, 237)
AI.add_attack_behaviour(USMASH, 18, -108, 108, 296, 887)
AI.add_attack_behaviour(DSMASH, 20, 194, 344, -23, 127)
AI.add_attack_behaviour(NSPG,   25, 400, 1000, 10, 300)
// AI.add_attack_behaviour(USPG,   15, 157, 531, 253, 2134-1000) // decreasing upwards range so he does it less often
// AI.add_attack_behaviour(DSPG,   16, 31, 2701, 27, 291)
AI.add_attack_behaviour(GRAB,   15, 47, 645, 79, 235)
// we can add new grounded attacks here

AI.END_ATTACKS() // end of grounded attacks

// aerial attacks
// add_attack_behaviour(table, attack, hitbox_start_frame, min_x, max_x, min_y, max_y)
AI.add_attack_behaviour(NAIR,   3, -100, 100, 58, 258)
AI.add_attack_behaviour(FAIR,   7, -6, 433, 37, 221)
AI.add_attack_behaviour(UAIR,   8, -388, 357, 199, 627)
AI.add_attack_behaviour(DAIR,   5, -56, 119, -228, 112)
AI.add_attack_behaviour(NSPA,   25, 400, 1000, 10, 300)
// AI.add_attack_behaviour(USPA,   16, 159, 539, 227, 377)
// AI.add_attack_behaviour(DSPA,   12+20, -128+300, 249+300, -1000+500, 300-400) // added delay to compensate movement and make him do it less often
// we can add new aerial attacks here

AI.END_ATTACKS() // end of aerial attacks
OS.align(16)

// Set CPU behaviour
Character.table_patch_start(ai_behaviour, Character.id.LUCAS, 0x4)
dw      CPU_ATTACKS
OS.patch_end()

// Set CPU NSP long range behaviour
Character.table_patch_start(ai_long_range, Character.id.LUCAS, 0x4)
dw    	AI.LONG_RANGE.ROUTINE.NSP_SHOOT
OS.patch_end()