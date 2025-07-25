// KirbyHats.asm

// This file allows for adding Kirby "hats" without needing to modify Kirby's original files.
// (We do have to add a req file and pointer to the Kirby Character file, but that's it.)

scope KirbyHats {
    // @ Description
    // Number of new "hats" added
    variable new_hats(33)
    constant total_hats(41)         // new_hats - 3 extra (DDD/Bowser/Kazooie) + 11 Original

    // @ Description
    // Used in add_hat to adjust offset
    variable current_custom_hat_id(0)

    scope file_index {
        constant KIRBY_CUSTOM_HATS(0)
        constant KIRBY_CUSTOM_HATS_2(1)
    }

    // @ Description
    // Adds a special part for use as a Kirby "hat"
    macro add_hat(base_hat_id, dl_hi, images_hi, tracks_hi, dl_lo, images_lo, tracks_lo, file_index) {
        if (current_custom_hat_id + 1 > new_hats) {
            print "ERROR CREATING KIRBY HAT: You forgot to increase new_hats! \n"
        } else {
            pushvar base, origin
            origin EXTENDED_SPECIAL_PARTS_ORIGIN + (current_custom_hat_id * 0x20)
            dw     {base_hat_id}
            dw     {dl_hi}
            dw     {images_hi}
            dw     {tracks_hi}
            dw     {dl_lo}
            dw     {images_lo}
            dw     {tracks_lo}
            dw     {file_index}             // 0 = KIRBY_CUSTOM_HATS, 1 = KIRBY_CUSTOM_HATS_2
            pullvar origin, base

            global variable current_custom_hat_id(current_custom_hat_id + 1)
        }
    }

    // defaults to KIRBY_CUSTOM_HATS file
    macro add_hat(base_hat_id, dl_hi, images_hi, tracks_hi, dl_lo, images_lo, tracks_lo) {
        add_hat({base_hat_id}, {dl_hi}, {images_hi}, {tracks_hi}, {dl_lo}, {images_lo}, {tracks_lo}, file_index.KIRBY_CUSTOM_HATS)
    }

    // @ Description
    // Holds info for new special parts, which will override base special part if specified.
    // Offsets are relative to the file KIRBY_CUSTOM_HATS.
    // Size = 0x20:
    //   0x0000 - base special part (or -1 if not based on an existing one) - allows reuse of existing data
    //   0x0004 - offset to display list of part, high poly (or -1 if not overridden)
    //   0x0008 - offset to special images, high poly (or -1 if not overridden)
    //   0x000C - offset to special tracks 1, high poly (or -1 if not overridden)
    //   0x0010 - offset to display list of part, low poly (or -1 if not overridden)
    //   0x0014 - offset to special images, low poly (or -1 if not overridden)
    //   0x0018 - offset to special tracks 1, low poly (or -1 if not overridden)
    //   0x001C - spacer
    // Note: special tracks 2 is not supported as it is not necessary for Kirby
    extended_special_parts:
    constant EXTENDED_SPECIAL_PARTS_ORIGIN(origin())
    fill new_hats * 0x20

    // @ Description
    // This is what we'll use as a temporary array when switching parts
    temp_special_parts:
    fill 0x14

    // @ Description
    // This catches when Kirby copies a power and allows us to use custom "hats"
    scope use_extended_special_parts_copy_: {
        OS.patch_start(0x64774, 0x800E8F74)
        jal     use_extended_special_parts_copy_
        lw      s5, 0x0084(s1)              // original line 1
        OS.patch_end()

        // First check the special part index
        lli     t4, 0x0002                  // t4 = 2, the special part index for hats
        bne     s3, t4, _end                // if not the special part index for hats, exit
        nop

        addiu   sp, sp,-0x0010              // allocate stack space
        sw      t0, 0x0004(sp)              // store registers
        sw      ra, 0x0008(sp)              // ~

        li      t0, _custom
        jal     use_extended_special_parts_
        nop

        lw      t0, 0x0004(sp)              // restore registers
        lw      ra, 0x0008(sp)              // ~
        addiu   sp, sp, 0x0010              // deallocate stack space

        _end:
        jr      ra
        sll     t2, v1, 0x0002              // original line 2

        _custom:
        lw      t0, 0x0004(sp)              // restore registers
        lw      ra, 0x0008(sp)              // ~
        addiu   sp, sp, 0x0010              // deallocate stack space

        j       0x800E8FAC                  // return to routine after s0 is set
        nop
    }

    // @ Description
    // This catches when the Kirby hat switches to high poly from low poly during a pause and allows us to use custom "hats".
    // Also runs when Kirby does Yoshi's NSP.
    scope use_extended_special_parts_pause_: {
        OS.patch_start(0x64504, 0x800E8D04)
        jal     use_extended_special_parts_pause_
        addu    t5, t4, a3                  // original line 1
        OS.patch_end()

        lw      v1, 0xFFF0(t5)              // original line 2

        // First check the special part index
        lli     t8, 0x0006                  // t8 = 6, the special part index for hats (not sure why this is different than when inhaling)
        beq     a1, t8, _swap               // if the special part index for hats proceed to swap code
        lli     t8, 0x0011                  // t8 = 11, the special part index for guns
        bne     a1, t8, _end                // if not the special part index for hats or guns, exit
        nop

        addiu   sp, sp,-0x0020              // allocate stack space
        sw      t0, 0x0004(sp)              // store registers
        sw      t2, 0x0008(sp)              // ~
        sw      t6, 0x000C(sp)              // ~
        sw      t7, 0x0010(sp)              // ~

        lw      t2, 0x0008(t0)              // Load Character ID
        lli     t6, Character.id.KIRBY      // t6 = Character.id.KIRBY
        beq     t2, t6, _check_hat_id       // if Kirby, then check hat ID
        lli     t6, Character.id.JKIRBY     // t6 = Character.id.JKIRBY
        bne     t2, t6, _gun_end            // if not Kirby or J Kirby, exit
        nop

        _check_hat_id:
        lb      t2, 0x0980(t0)              // load hat ID into t2
        addiu   t6, r0, 0x001C              // put Marth Hat ID into t6
        li      t7, 0x1D890                 // offset of special part struct for Marth's Sword [UPDATE IF SWORD MODEL CHANGED]
        beq     t2, t6, _get_offset
        addiu   t6, r0, 0x002C              // put Roy Hat ID into t6
        li      t7, 0x1D980                 // offset of special part struct for Roy's Sword [UPDATE IF SWORD MODEL CHANGED]
        beq     t2, t6, _get_offset
        addiu   t6, r0, 0x001A              // put Wolf Hat ID into t6
        li      t7, 0x1D830                 // offset of special part struct for Wolf's Gun [UPDATE IF GUN MODEL CHANGED]
        beq     t2, t6, _get_offset
        addiu   t6, r0, 0x0023              // put Slippy Hat ID into t6
        li      t7, 0x1D8C0                 // offset of special part struct for Slippy's Gun [UPDATE IF GUN MODEL CHANGED]
        beq     t2, t6, _get_offset
        addiu   t6, r0, 0x0024              // put Peppy Hat ID into t6
        li      t7, 0x1D8F0                 // offset of special part struct for Peppy's Gun [UPDATE IF GUN MODEL CHANGED]
        beq     t2, t6, _get_offset
        addiu   t6, r0, 0x0022              // put Goemon Hat ID into t6
        li      t7, 0x1D920                 // offset of special part struct for Goemon's Ryo[UPDATE IF RYO MODEL CHANGED]
        beq     t2, t6, _get_offset
        addiu   t6, r0, 0x0028              // put Ebisumaru Hat ID into t6
        li      t7, 0x1D950                 // offset of special part struct for Ebisumaru's Meat[UPDATE IF MEAT MODEL CHANGED]
        beq     t2, t6, _get_offset
        addiu   t6, r0, 0x002E              // put Lanky Hat ID into t6
        li      t7, 0x1D9B0                 // offset of special part struct for Lanky's Gun[UPDATE IF GUN MODEL CHANGED]
        beq     t2, t6, _get_offset
        addiu   t6, r0, 0x0019              // put Conker Hat ID into t6
        li      t7, 0x1D860                 // offset of special part struct for Conker's Catapult [UPDATE IF CATAPULT MODEL CHANGED]
        bne     t2, t6, _gun_end            // if not Conker Hat ID, exit
        nop

        _get_offset:
        li      v1, 0x80131078              // v1 = Kirby's File pointer to model file
        lw      t2, 0x0008(t0)              // t0 = Character ID
        lli     t6, Character.id.JKIRBY     // t6 = JKirby ID
        bne     t2, t6, pc() + 16           // use Kirby if not JKirby, otherwise use JKirby pointer
        nop
        li      v1, Character.JKIRBY_file_4_ptr // v1 = J Kirby's File pointer to model file
        lw      v1, 0x0000(v1)              // v1 = address of model file for kirby
        addu    v1, v1, t7                  // v1 = special struct address address

        _gun_end:
        lw      t0, 0x0004(sp)              // restore registers
        lw      t2, 0x0008(sp)              // ~
        lw      t6, 0x000C(sp)              // ~
        lw      t7, 0x0010(sp)              // ~
        addiu   sp, sp, 0x0020              // deallocate stack space

        jr      ra
        nop

        _swap:
        addiu   sp, sp,-0x0030              // allocate stack space
        sw      t0, 0x0004(sp)              // store registers
        sw      ra, 0x0008(sp)              // ~
        sw      v0, 0x000C(sp)              // ~
        sw      v1, 0x0010(sp)              // ~
        sw      t2, 0x0014(sp)              // ~
        sw      s2, 0x0018(sp)              // ~
        sw      t6, 0x001C(sp)              // ~
        sw      s0, 0x0020(sp)              // ~

        or      v0, v1, r0                  // v0 = special part table
        or      v1, t2, r0                  // v1 = hat_id
        or      s2, t0, r0                  // s2 = player struct

        li      t0, _custom
        jal     use_extended_special_parts_
        nop

        lw      t0, 0x0004(sp)              // restore registers
        lw      ra, 0x0008(sp)              // ~
        lw      v0, 0x000C(sp)              // ~
        lw      v1, 0x0010(sp)              // ~
        lw      t2, 0x0014(sp)              // ~
        lw      s2, 0x0018(sp)              // ~
        lw      t6, 0x001C(sp)              // ~
        lw      s0, 0x0020(sp)              // ~
        addiu   sp, sp, 0x0030              // deallocate stack space

        _end:
        jr      ra
        nop

        _custom:
        or      t3, t6, r0                  // t3 = display list pointer
        or      v0, s0, r0                  // v0 = special part array

        lw      t0, 0x0004(sp)              // restore registers
        lw      ra, 0x0008(sp)              // ~
        // don't restore v0
        lw      v1, 0x0010(sp)              // ~
        lw      t2, 0x0014(sp)              // ~
        lw      s2, 0x0018(sp)              // ~
        lw      t6, 0x001C(sp)              // ~
        lw      s0, 0x0020(sp)              // ~
        addiu   sp, sp, 0x0030              // deallocate stack space

        j       0x800E8D38                  // return to routine after s0 is set
        nop
    }

    // @ Description
    // This seems to be related to costume loading and initializing things to use the right special images/tracks.
    scope use_extended_special_parts_costume_init_: {
        OS.patch_start(0x64AFC, 0x800E92FC)
        jal     use_extended_special_parts_costume_init_
        lbu     t7, 0x000E(s5)              // original line 1
        OS.patch_end()

        or      a0, s1, r0                  // original line 2

        // First check the special part index
        lli     t8, 0x0002                  // t8 = 2, the special part index for hats
        bne     s2, t8, _end                // if not the special part index for hats, exit
        nop

        addiu   sp, sp,-0x0030              // allocate stack space
        sw      t4, 0x0004(sp)              // store registers
        sw      ra, 0x0008(sp)              // ~
        sw      v1, 0x000C(sp)              // ~
        sw      t7, 0x0010(sp)              // ~
        sw      s2, 0x0014(sp)              // ~
        sw      s0, 0x0018(sp)              // ~

        or      v0, v1, r0                  // v0 = special part table
        or      v1, t4, r0                  // v1 = hat_id
        or      s2, s5, r0                  // s2 = player struct

        li      t0, _custom
        jal     use_extended_special_parts_
        nop

        lw      t4, 0x0004(sp)              // restore registers
        lw      ra, 0x0008(sp)              // ~
        lw      v1, 0x000C(sp)              // ~
        lw      t7, 0x0010(sp)              // ~
        lw      s2, 0x0014(sp)              // ~
        lw      s0, 0x0018(sp)              // ~
        addiu   sp, sp, 0x0030              // deallocate stack space

        _end:
        jr      ra
        nop

        _custom:
        or      v0, s0, r0                  // v0 = special part array
        lw      a1, 0x0004(v0)              // a1 = special images
        lw      a2, 0x0008(v0)              // a2 = special tracks 1
        lw      a3, 0x000C(v0)              // a3 = special tracks 2

        lw      ra, 0x0008(sp)              // restore registers
        lw      s2, 0x0014(sp)              // ~
        lw      s0, 0x0018(sp)              // ~
        addiu   sp, sp, 0x0030              // deallocate stack space

        j       0x800E9334                  // return to routine after v0 is set
        nop
    }

    // @ Description
    // This allows us to use custom hats for Kirby.
    // It expects the following:
    //  v0 - special part table
    //  v1 - hat_id
    //  s2 - player struct
    //  t0 - address to jump to if custom hat is used
    // It spits out the following:
    //  t6 - display list pointer
    //  s0 - special index array
    scope use_extended_special_parts_: {
        lw      t2, 0x0008(s2)                 // t2 = character_id

        // If v0 is 0, we can skip... may not be necessary but doesn't hurt
        beqz    v0, _end                       // if v0 = 0, exit
        nop

        // Next, ensure we are doing a Kirby hat swap
        lli     t4, Character.id.KIRBY         // t4 = Character.id.KIRBY
        beq     t2, t4, _check_hat_id          // if Kirby, then check hat ID
        lli     t4, Character.id.JKIRBY        // t4 = Character.id.JKIRBY
        bne     t2, t4, _end                   // if not Kirby or J Kirby, exit
        nop

        _check_hat_id:
        sltiu   t2, v1, 0x000F                 // t2 = 1 if an original hat_id, 0 if an added hat_id
        bnez    t2, _end                       // if an original hat_id, exit
        nop                                    // otherwise we need to use our custom table

        // We'll set s0 to temp_special_parts and populate it with the correct values
        li      s0, temp_special_parts
        addiu   v1, v1, -0x000F                // v1 = custom_hat_id
        li      t4, extended_special_parts     // t4 = extended_special_parts
        sll     v1, v1, 0x0005                 // v1 = custom_hat_id * 0x20 (offset to special part)
        addu    t4, t4, v1                     // t4 = special part
        lbu     t5, 0x000E(s2)                 // t5 = 1 if high poly, 2 if low poly
        addiu   t5, t5, -0x0001                // t5 = hi/lo poly index
        lw      v1, 0x0000(t4)                 // v1 = base hat_id
        bltz    v1, _set_overrides             // if base hat_id = -1, then skip setting values
        lli     t2, 0x28                       // t2 = 0x28 (size of special part array)
        multu   t2, v1                         // t2 = offset in special part table
        mflo    t2                             // ~
        addu    t3, v0, t2                     // t3 = special part array (hi)
        bnezl   t5, pc() + 8                   // if lo poly, add offset
        addiu   t3, t3, 0x0014                 // t3 = special part array (lo)

        lw      t7, 0x0000(t3)                 // t7 = display list pointer
        sw      t7, 0x0000(s0)                 // set display list pointer
        lw      t7, 0x0004(t3)                 // t7 = special images pointer
        sw      t7, 0x0004(s0)                 // set special images pointer
        lw      t7, 0x0008(t3)                 // t7 = special tracks 1 pointer
        sw      t7, 0x0008(s0)                 // set special tracks 1
        lw      t7, 0x000C(t3)                 // t7 = special tracks 2
        sw      t7, 0x000C(s0)                 // set special tracks 2

        _set_overrides:
        lw      t7, 0x001C(t4)                 // t7 = file index
        addiu   t4, t4, 0x0004                 // t4 = hi poly array of custom special part overrides
        bnezl   t5, pc() + 8                   // if lo poly, add offset
        addiu   t4, t4, 0x000C                 // t4 = lo poly array of custom special part overrides
        li      t3, 0x80116E10                 // t3 = main character struct table
        lw      t5, 0x0008(s2)                 // t5 = character_id
        sll     t5, t5, 0x0002                 // t5 = a5 * 4 (offset in struct table)
        addu    t3, t3, t5                     // t3 = pointer to character struct
        lw      t3, 0x0000(t3)                 // t3 = character struct
        lw      t3, 0x0034(t3)                 // t3 = character file address pointer
        lw      t3, 0x0000(t3)                 // t3 = character file address
        li      t5, 0x0001D810                 // t5 = offset to custom hat file pointer
        bnezl   t7, pc() + 8                   // if KIRBY_CUSTOM_HATS_2 file, adjust pointer
        addiu   t5, t5, 0x0004                 // t5 = offset to custom hat file 2 pointer
        addu    t3, t3, t5                     // t3 = address for custom hat file pointer
        lw      t3, 0x0000(t3)                 // t3 = base address of custom hat file

        addiu   t5, r0, -0x0001                // t5 = -1

        lw      t7, 0x0000(t4)                 // t7 = display list offset
        beq     t7, t5, pc() + 12              // if display list offset not defined, skip overriding
        addu    t6, t3, t7                     // t6 = ponter to display list
        sw      t6, 0x0000(s0)                 // override display list pointer

        lw      t7, 0x0004(t4)                 // t7 = special images offset
        beq     t7, t5, pc() + 12              // if special images offset not defined, skip overriding
        addu    t7, t3, t7                     // t7 = ponter to special images
        sw      t7, 0x0004(s0)                 // override special images pointer

        lw      t7, 0x0008(t4)                 // t7 = special tracks 1 offset
        beq     t7, t5, pc() + 12              // if special tracks 1 offset not defined, skip overriding
        addu    t7, t3, t7                     // t7 = ponter to special tracks 1
        sw      t7, 0x0008(s0)                 // override special tracks 1 pointer

        jr      t0                             // return to routine after s0 is set
        nop

        _end:
        jr      ra
        nop
    }

    // Wario hat_id: 0x0F
    add_hat(Character.kirby_hat_id.MARIO, 0x900, -1, -1, 0x1360, -1, -1)
    // Dr. Mario hat_id: 0x10
    add_hat(Character.kirby_hat_id.MARIO, 0x2080, -1, -1, 0x2B68, -1, -1)
    // Ganondorf hat_id: 0x11
    add_hat(Character.kirby_hat_id.FALCON, 0x3AA0, -1, -1, 0x4BA0, -1, -1)
    // Falco hat_id: 0x12
    add_hat(Character.kirby_hat_id.FOX, 0x6030, -1, -1, 0x6B28, -1, -1)
    // Dark Samus hat_id: 0x13
    add_hat(Character.kirby_hat_id.SAMUS, 0x7760, -1, -1, 0x7760, -1, -1)
    // Lucas hat_id: 0x14
    add_hat(Character.kirby_hat_id.NESS, 0x8580, -1, -1, 0x9088, -1, -1)
    // Bowser hat_id: 0x15
    add_hat(Character.kirby_hat_id.YOSHI, 0x9F20, -1, -1, 0xAFD0, -1, -1)
    // Bowser (mouth open) hat_id: 0x16
    add_hat(Character.kirby_hat_id.YOSHI_SWALLOW, 0xC1B8, -1, -1, 0xCF80, -1, -1)
    // Mad Piano hat_id: 0x17
    add_hat(Character.kirby_hat_id.MARIO, 0xE540, -1, -1, 0xF560, -1, -1)
    // Mad Piano hat_id: 0x18
    add_hat(Character.kirby_hat_id.YOSHI_SWALLOW, 0x10EC0, -1, -1, 0x11B20, -1, -1)
    // Conker hat_id: 0x19
    add_hat(Character.kirby_hat_id.FOX, 0x13600, -1, -1, 0x14640, -1, -1)
    // Wolf hat_id: 0x1A
    add_hat(Character.kirby_hat_id.FOX, 0x16010, -1, -1, 0x16E20, -1, -1)
    // Mewtwo hat_id: 0x1B
    add_hat(Character.kirby_hat_id.PIKACHU, 0x17DE8, -1, -1, 0x188B0, -1, -1)
    // Marth hat_id: 0x1C
    add_hat(Character.kirby_hat_id.FOX, 0x199A8, -1, -1, 0x1A858, -1, -1)
    // Sonic hat_id: 0x1D
    add_hat(Character.kirby_hat_id.FOX, 0x1BD18, -1, -1, 0x1CD18, -1, -1)
    // Sheik hat_id: 0x1E
    add_hat(Character.kirby_hat_id.FALCON, 0x1E2C0, -1, -1, 0x1F5B8, -1, -1)
    // Marina hat_id: 0x1F
    add_hat(Character.kirby_hat_id.FALCON, 0x20D60, -1, -1, 0x21C08, -1, -1)
    // Dedede hat_id: 0x20
    add_hat(Character.kirby_hat_id.YOSHI, 0x22CF0, -1, -1, 0x23B98, -1, -1)
    // Dedede (mouth open) hat_id: 0x21
    add_hat(Character.kirby_hat_id.YOSHI_SWALLOW, 0x24840, -1, -1, 0x25238, -1, -1)
    // Goemon hat_id: 0x22
    add_hat(Character.kirby_hat_id.MARIO, 0x26638, -1, -1, 0x27CC0, -1, -1)
    // Slippy hat_id: 0x23
    add_hat(Character.kirby_hat_id.FOX, 0x28BE8, -1, -1, 0x29A40, -1, -1)
    // Peppy hat_id: 0x24
    add_hat(Character.kirby_hat_id.FOX, 0x2A9A0, -1, -1, 0x2B6D0, -1, -1)
    // Magic hat_id: 0x25
    add_hat(Character.kirby_hat_id.YOSHI, 0x2C6E8, -1, -1, 0x2D7B0, -1, -1)
    // Kazooie hat_id: 0x26
    add_hat(Character.kirby_hat_id.FALCON, 0x2EA88, -1, -1, 0x2FA68, -1, -1)
    // Kazooie (mouth open) hat_id: 0x27
    add_hat(Character.kirby_hat_id.LINK, 0x30C40, -1, -1, 0x31C20, -1, -1)
    // Ebisumaru hat_id: 0x28
    add_hat(Character.kirby_hat_id.FOX, 0x32D30, -1, -1, 0x33EF0, -1, -1)
    // Dragon King hat_id: 0x29
    add_hat(Character.kirby_hat_id.FALCON, 0x34F00, -1, -1, 0x35C08, -1, -1)
    // Crash hat_id: 0x2A
    add_hat(Character.kirby_hat_id.MARIO, 0x36D48, -1, -1, 0x37FF0, -1, -1)
    // Peach hat_id: 0x2B
    add_hat(Character.kirby_hat_id.FOX, 0x396A0, -1, -1, 0x3AA20, -1, -1)
    // Roy hat_id: 0x2C
    add_hat(Character.kirby_hat_id.FOX, 0x3BF60, -1, -1, 0x3D140, -1, -1)
    // Dr. Luigi hat_id: 0x2D
    add_hat(Character.kirby_hat_id.MARIO, 0x2080, -1, -1, 0x2B68, -1, -1)
    // Lanky Kong hat_id: 0x2E
    add_hat(Character.kirby_hat_id.DK, 0x3E490, -1, -1, 0x3F280, -1, -1)
    // Super Sonic hat_id: 0x2F
    add_hat(Character.kirby_hat_id.FOX, 0xCC8, -1, -1, 0x2978, -1, -1, file_index.KIRBY_CUSTOM_HATS_2)

    spawn_with_table_:
    db 0x08                                   // NA = no hat
    db 0x00                                   // 0x00 = mario
    db 0x01                                   // 0x01 = fox
    db 0x02                                   // 0x02 = dk
    db 0x03                                   // 0x03 = samus
    db 0x04                                   // 0x04 = luigi
    db 0x05                                   // 0x05 = link
    db 0x06                                   // 0x06 = yoshi
    db 0x07                                   // 0x07 = captain falcon
    db 0x09                                   // 0x09 = pikachu
    db 0x0A                                   // 0x0A = jigglypuff
    db 0x0B                                   // 0x0B = ness
    db 0x1D                                   // 0x0C = falco
    db 0x1E                                   // 0x0D = ganondorf
    db 0x1F                                   // 0x0E = young link
    db 0x20                                   // 0x0F = dr. mario
    db 0x21                                   // 0x10 = Wario
    db 0x34                                   // 0x11 = Bowser
    db 0x37                                   // 0x12 = Wolf
    db 0x38                                   // 0x13 = Conker
    db 0x39                                   // 0x14 = Mewtwo
    db 0x3A                                   // 0x15 = Marth
    db 0x3B                                   // 0x16 = Sonic
    db 0x3E                                   // 0x17 = Sheik
    db Character.id.MARINA                    // 0x18 = Marina
    db Character.id.DEDEDE                    // 0x19 = Dedede
    db Character.id.GOEMON                    // 0x1A = Goemon
    db Character.id.BANJO                     // 0x1B = Kazooie
    db Character.id.CRASH                     // 0x1C = Crash
    db Character.id.PEACH                     // 0x1D = Peach
    db 0x22                                   // 0x1E = Dark Samus
    db 0x26                                   // 0x1F = Lucas
    db Character.id.PEPPY                     // 0x20 = Peppy
    db Character.id.SLIPPY                    // 0x21 = Slippy
    db Character.id.ROY                       // 0x22 = Roy
    db Character.id.DRL                       // 0x23 = Dr Luigi
    db Character.id.LANKY                     // 0x24 = Lanky
    db Character.id.DRAGONKING                // 0x25 = Dragon King
    db Character.id.EBI                       // 0x26 = Ebisumaru
    db 0x36                                   // 0x27 = Mad Piano
    db Character.id.SSONIC                    // 0x28 = Super Sonic
    db Character.id.NONE                      // 0x29 = Magic
    db Character.id.KIRBY                     // 0x2A = Random
    OS.align(4)

    spawn_with_hat:
    dw 0x00000000, 0x00000000, 0x00000000, 0x00000000

    magic_hat_on:
    dw OS.FALSE, OS.FALSE, OS.FALSE, OS.FALSE

    taunt_loses_power:
    dw OS.TRUE, OS.TRUE, OS.TRUE, OS.TRUE

    // Set Kirby hat_id for magic hat
    // Use NONE slot
    Character.table_patch_start(kirby_inhale_struct, 0x2, Character.id.NONE, 0xC)
    dh 0x25
    OS.patch_end()

    scope set_absorbed_hat_: {
        OS.patch_start(0xDCB50, 0x80162110)
        jal     set_absorbed_hat_
        lw      t1, 0x0ADC(v0)              // original line 1 - t1 = hat id of sucked in opponent
        OS.patch_end()
        OS.patch_start(0xDC97C, 0x80161F3C)
        jal     set_absorbed_hat_._update_magic_hat_on
        lh      t0, 0x0B18(s0)              // original line 1 - t0 = hat id of sucked in opponent
        OS.patch_end()

        // check magic_hat_on to see if absorbed opponent has the magic hat
        lw      t4, 0x0008(v0)              // t4 = character id of absorbed opponent
        lli     t3, Character.id.KIRBY      // t3 = KIRBY character id
        beq     t3, t4, _kirby              // if Kirby, check spawn hat
        lli     t3, Character.id.JKIRBY     // t3 = JKIRBY character id
        bne     t3, t4, _end                // if not a Kirby, skip
        nop

        _kirby:
        lbu     t3, 0x000D(v0)              // t3 = port of absorbed opponent
        li      t4, magic_hat_on            // t4 = magic_hat_on
        sll     t3, t3, 0x0002              // t3 = offset in table
        addu    t3, t4, t3                  // t3 = address of magic_hat_on
        lw      t3, 0x0000(t3)              // t3 = 0 if magic hat off, 1 if on
        bnezl   t3, _end                    // if magic hat on, set power id
        lli     t1, Character.id.NONE       // t1 = NONE = magic hat's power id

        _end:
        jr      ra
        sh      t1, 0x0B18(s0)              // set hat id to temp variable

        _update_magic_hat_on:
        lli     t1, Character.id.NONE       // t1 = NONE = magic hat's power id
        bne     t0, t1, _end_magic_hat_on   // if not magic hat, skip
        lbu     t3, 0x000D(s0)              // t3 = port of absorber

        li      t4, magic_hat_on            // t4 = magic_hat_on
        sll     t3, t3, 0x0002              // t3 = offset in table
        addu    t4, t4, t3                  // t4 = address of magic_hat_on
        lli     t3, OS.TRUE                 // t3 = TRUE
        sw      t3, 0x000(t4)               // set magic_hat_on

        _end_magic_hat_on:
        jr      ra
        lw      t1, 0x0ADC(s0)              // original line 2 - t1 = hat id of player
    }

    // @ Description
    // This hooks into a kirby spawning routine which loads his hat, we substitute the desired hat here
    scope kirby_hat_select_: {
        OS.patch_start(0x53608, 0x800D7E08)
        j       kirby_hat_select_
        lbu     t8, 0x000D(v1)              // t8 = port
        _return:
        OS.patch_end()

        // v1 = player struct
        li      t5, spawn_with_hat
        sll     t8, t8, 0x0002              // t8 = offset to port
        addu    t5, t5, t8                  // t5 = address of spawn with hat id
        lw      t8, 0x0000(t5)              // t8 = hat_id
        lli     t5, CharacterSelectDebugMenu.KirbyHat.MAX_VALUE  // t5 = last kirby hat entry ('Random')
        beq     t5, t8, _handle_random_hat  // branch accordingly
        nop
        lli     t5, CharacterSelectDebugMenu.KirbyHat.MAX_VALUE - 1  // t5 = second-to-last kirby hat entry ('???')
        bne     t5, t8, _get_character_id
        nop
        // if we're here, Magic Kirby '???' is spawning, and we need to clear that port's charge table
        j       Kirby.clear_magic_hat_charge
        nop

        _handle_random_hat:
        // don't actually randomize hat on CSS (show Vanilla Kirby)
        li      v0, Global.current_screen   // v0 = address of current screen
        lbu     v0, 0x0000(v0)              // v0 = current screen
        lli     t5, Global.screen.TITLE_AND_1P // t5 = 1 if Title, 1p game over screen, 1p battle, remix 1p battle
        beq     t5, v0, _handle_random_hat_1p  // branch if 1p
        sltiu   t5, v0, 0x0015              // t5 = 1 if CSS
        bnezl   t5, _normal                 // branch if (screen_id = css)
        addiu   t8, r0, 0x0008              // kirby character ID
        lli     t5, Global.screen.RESULTS   // t5 = results screen
        beql    t5, v0, _normal             // branch if on results screen
        addiu   t8, r0, 0x0008              // kirby character ID
        b       _pick_random_hat            // if we're here, pick a random hat
        nop

        _handle_random_hat_1p:
        li      v0, Global.match_info       // v0 = pointer to match info
        lw      v0, 0x0000(v0)              // load address of match info
        lb      t5, 0x002B(v0)              // t5 = stocks remaining (-1 if game over)
        bltzl   t5, _normal                 // branch if game over
        addiu   t8, r0, 0x0008              // kirby character ID

        _pick_random_hat:
        addiu   sp, sp,-0x0014              // allocate stack space
        sw      a0, 0x0004(sp)              // store registers
        sw      ra, 0x0008(sp)              // ~
        sw      v1, 0x000C(sp)              // ~
        sw      v0, 0x0010(sp)              // ~
        addiu   a0, r0, total_hats - 1      // a0 = total hat count (minus Magic Kirby)
        jal     Global.get_random_int_      // v0 = (0, N-1)
        nop
        addiu   t8, v0, 0x0001              // v0++ (so we don't pick 'NA = no hat')
        lw      a0, 0x0004(sp)              // restore registers
        lw      ra, 0x0008(sp)              // ~
        lw      v1, 0x000C(sp)              // v1 = player struct
        lw      v0, 0x0010(sp)              // ~
        addiu   sp, sp, 0x0014              // deallocate stack space

        _get_character_id:
        li      v0, spawn_with_table_
        addu    v0, t8, v0                  // add to table address to get character ID
        lbu     t8, 0x0000(v0)              // load character ID

        addiu   t5, r0, 0x0008              // kirby character ID
        beql    t5, t8, _end                // if the ID is kirby's, do normal
        _normal:
        lw      t8, 0x0020(t2)              // original line 1, loads hat

        _end:
        j       _return
        sw      r0, 0x0AE0(v1)              // original line 2
    }

    // @ Description
    // Loads kirby files when needed for debug options in training mode
    scope kirby_hat_files_training_: {
        OS.patch_start(0x116B60, 0x80190340)
        j       kirby_hat_files_training_
        addiu   t7, r0, 0x0003              // amount of port loops
        _return:
        OS.patch_end()

        li      s4, spawn_with_hat          // pointer to kirby hat settings

        _loop:
        lw      t1, 0x0000(s4)              // hat setting for that port
        bnez    t1, _kirbyhat_selected      // if not default, load files
        addiu   s4, s4, 0x0004              // move to next port

        bnez    t7, _loop                   // if not all ports, loop
        addiu   t7, t7, 0xFFFF              // subtract 1 from loop counter

        beq     r0, r0, _end                // to end/default hat situation
        nop

        _kirbyhat_selected:
        Render.load_file(0xE6, Render.file_pointer_1)              // load kirby hats classic
        Render.load_file(0xC1B, Render.file_pointer_2)             // load kirby hats remix

        _end:
        or      s1, r0, r0                  // original line 1
        j       _return
        addiu   s4, sp, 0x005C              // original line 2
    }

    // @ Description
    // Loads kirby files when needed for debug options in vs mode
    scope kirby_hat_files_vs_: {
        // Normal VS
        OS.patch_start(0x10A29C, 0x8018D3AC)
        jal     kirby_hat_files_vs_
        addiu   s4, sp, 0x005C              // original line 2
        OS.patch_end()
        // Sudden Death
        OS.patch_start(0x10ADE8, 0x8018DEF8)
        jal     kirby_hat_files_vs_
        addiu   s4, sp, 0x0054              // original line 2
        OS.patch_end()

        addiu   t7, r0, 0x0003              // amount of port loops
        li      t1, spawn_with_hat          // pointer to kirby hat settings

        _loop:
        lw      t5, 0x0000(t1)              // hat setting for that port
        bnez    t5, _kirbyhat_selected      // if not default, load files
        addiu   t1, t1, 0x0004              // move to next port

        bnez    t7, _loop                   // if not all ports, loop
        addiu   t7, t7, 0xFFFF              // subtract 1 from loop counter

        beq     r0, r0, _end                // to end/default hat situation
        nop

        _kirbyhat_selected:
        addiu   sp, sp, -0x0010             // allocate stack space
        sw      ra, 0x0004(sp)              // save ra
        Render.load_file(0xE6, Render.file_pointer_1)              // load kirby hats classic
        Render.load_file(0xC1B, Render.file_pointer_2)             // load kirby hats remix
        lw      ra, 0x0004(sp)              // restore ra
        addiu   sp, sp, 0x0010              // deallocate stack space

        _end:
        jr      ra
        or      s1, r0, r0                  // original line 1
    }

    // @ Description
    // Loads kirby files when needed for debug options in Bonus mode
    // Should only really check the player's port but I'm too lazy!
    scope kirby_hat_files_bonus_: {
        OS.patch_start(0x112DFC, 0x8018E6BC)
        j       kirby_hat_files_bonus_
        addiu   t7, r0, 0x0003              // amount of port loops
        _return:
        OS.patch_end()

        li      s4, spawn_with_hat          // pointer to kirby hat settings

        _loop:
        lw      t5, 0x0000(s4)              // hat setting for that port
        bnez    t5, _kirbyhat_selected      // if not default, load files
        addiu   s4, s4, 0x0004              // move to next port

        bnez    t7, _loop                   // if not all ports, loop
        addiu   t7, t7, 0xFFFF              // subtract 1 from loop counter

        beq     r0, r0, _end                // to end/default hat situation
        nop

        _kirbyhat_selected:
        Render.load_file(0xE6, Render.file_pointer_1)              // load kirby hats classic
        Render.load_file(0xC1B, Render.file_pointer_2)             // load kirby hats remix

        _end:
        lui     t8, 0x8011                  // original line 1
        j       _return
        addiu   t8, t8, 0x6DD0              // original line 2
    }

    // @ Description
    // Loads kirby files when needed for debug options in 1p
    // Should only really check the player's port but I'm too lazy!
    scope kirby_hat_files_1p_: {
        OS.patch_start(0x10E2D4, 0x8018FA74)
        j       kirby_hat_files_1p_
        addiu   t7, r0, 0x0003              // amount of port loops
        _return:
        OS.patch_end()

        li      s2, spawn_with_hat          // pointer to kirby hat settings

        _loop:
        lw      t1, 0x0000(s2)              // hat setting for that port
        bnez    t1, _kirbyhat_selected      // if not default, load files
        addiu   s2, s2, 0x0004              // move to next port

        bnez    t7, _loop                   // if not all ports, loop
        addiu   t7, t7, 0xFFFF              // subtract 1 from loop counter

        beq     r0, r0, _end                // to end/default hat situation
        nop

        _kirbyhat_selected:
        Render.load_file(0xE6, Render.file_pointer_1)              // load kirby hats classic
        Render.load_file(0xC1B, Render.file_pointer_2)             // load kirby hats remix

        _end:
        or      s1, r0, r0                  // original line 1
        j       _return
        or      s2, r0, r0                  // original line 2
    }

    // @ Description
    // Prevents kirby from losing hat via hit or taunt when hat set
    scope hat_loss_prevent_: {
        OS.patch_start(0xDE034, 0x801635F4)
        j       hat_loss_prevent_
        sw      a0, 0x0020(sp)              // original line 1
        _return:
        OS.patch_end()

        lw      at, 0x0084(a0)
        lbu     at, 0x000D(at)              // at = port
        li      v0, spawn_with_table_
        li      a0, taunt_loses_power
        sll     at, at, 0x0002              // at = offset to port
        addu    a0, a0, at                  // a0 = address of taunt_loses_power
        lw      at, 0x0000(a0)              // at = taunt_loses_power
        bnezl   at, _end                    // if taunt loses power, skip
        lw      a0, 0x0020(sp)              // original line 1

        j       0x80163638                  // skip removal procedures
        lw      a0, 0x0084(a0)              // original line 2

        _end:
        lw      at, 0x0084(a0)              // at = player struct
        lbu     at, 0x000D(at)              // at = port
        li      v0, magic_hat_on
        sll     at, at, 0x0002              // at = offset to port
        addu    at, v0, at                  // a0 = address of magic_hat_on
        sw      r0, 0x0000(at)              // clear out magic_hat_on

        j       _return
        lw      a0, 0x0084(a0)              // original line 2
    }

    // @ Description
    // Prevents kirby from having his power ID set to 0
    scope kirby_power_loss_prevent_: {
        OS.patch_start(0xDE060, 0x80163620)
        j       kirby_power_loss_prevent_
        addiu   a0, r0, Character.id.KIRBY
        _return:
        OS.patch_end()

        lw      a2, 0x0008(t8)              // load character ID
        beq     a0, a2, _check              // check if kirby
        addiu   a0, r0, Character.id.JKIRBY // JKIRBY ID
        bnel    a0, a2, _no_kirbyhat_selected   // check if jkirby
        sw      t7, 0x0ADC(t8)              // original line 2, remove power

        _check:
        li      a2, taunt_loses_power       // a2 = taunt_loses_power
        lbu     a0, 0x000D(t8)              // a0 = port
        sll     a0, a0, 0x0002              // a1 = offset to port
        addu    a0, a2, a0                  // a0 = address of taunt_loses_power
        lw      a2, 0x0000(a0)              // at = taunt_loses_power

        bnezl   a2, _no_kirbyhat_selected   // if taunt_loses_power is true, remove power, if false, do not
        sw      t7, 0x0ADC(t8)              // original line 1, remove power

        _no_kirbyhat_selected:
        j       _return
        lw      a0, 0x0020(sp)              // original line 2
    }

    // @ Description
    // Set magic_hat_on flag to false when absorbed
    scope set_absorbed_: {
        OS.patch_start(0xC6A74, 0x8014C034)
        jal     set_absorbed_
        addiu   t5, r0, 0x0008              // original line 1 = t5 = Character.id.KIRBY
        OS.patch_end()

        li      a0, magic_hat_on
        lbu     a1, 0x000D(s0)              // a1 = port of absorbed player
        sll     a1, a1, 0x0002              // a1 = offset to magic_hat_on
        addu    a0, a0, a1                  // a0 = address of magic_hat_on
        sw      r0, 0x0000(a0)              // set magic_hat_on to false
        li      a0, taunt_loses_power
        addu    a0, a0, a1                  // a0 = address of taunt_loses_power
        lli     a1, OS.TRUE                 // a1 = TRUE
        sw      a1, 0x0000(a0)              // set taunt_loses_power to true when absorbed

        jr      ra
        sw      t5, 0x0ADC(s0)              // original line 2 - set power to suck
    }
}
