// WallTeching.asm

scope WallTeching {

    // @ Description
    // Patch which adds wall teching.
    scope patch: {
        OS.patch_start(0xBC644, 0x80141C04)
        j       patch
        addiu   a1, r0, 0x0038          // original line 2
        _return:
        OS.patch_end()
        
        Toggles.read(entry_wall_teching, at) // at = toggle
        beqz    at, _end
        lw      t6, 0x0160(s0)          // t6 = frames since z pressed
        slti    t6, t6, 0x0014          // t6 = 0 if frames since z pressed > 0x14(20)
        beq     t6, r0, _fail           // end if frames sinze z pressed > 20
        nop

        // if we're here, start a wall tech
        mfc1    t5, f6                  // ~
        sw      t5, 0x0B18(s0)          // original logic
        sw      r0, 0x0054(s0)          // ~
        sw      r0, 0x0058(s0)          // ~
        lw      a0, 0x0048(sp)          // a0 = player object
        Action.change(Action.Tech, 0x4000)

        // set routines
        // sw      r0, 0x086C(s0)          // update moveset pointer
        // sw      r0, 0x08AC(s0)          // update moveset pointer
        li      at, 0x800D94E8
        sw      at, 0x09D4(s0)          // update main routine
        sw      r0, 0x09E0(s0)          // remove movement routine
        li      at, 0x800DE99C
        sw      at, 0x09E4(s0)          // update collision pointer
        sw      r0, 0x09DC(s0)          // remove interrupt routine

        li      at, WallTeching.successful_techs
        lbu     t6, 0x000D(s0)          // t6 = player index (0 - 3)
        sll     t6, t6, 0x0002          // t6 = player index * 4
        addu    at, at, t6              // at = address of successful techs for this player
        lw      t6, 0x0000(at)          // t6 = successful tech count
        addiu   t6, t6, 0x0001          // increment
        j       0x80141C28              // return
        sw      t6, 0x0000(at)          // store updated tech count

        _fail:
        li      at, WallTeching.missed_techs
        lbu     t6, 0x000D(s0)          // t6 = player index (0 - 3)
        sll     t6, t6, 0x0002          // t6 = player index * 4
        addu    at, at, t6              // at = address of missed techs for this player
        lw      t6, 0x0000(at)          // t6 = missed tech count
        addiu   t6, t6, 0x0001          // increment
        sw      t6, 0x0000(at)          // store updated tech count

        _end:
        j       _return                 // return
        addiu   t6, r0, 0x1100          // original line 1
    }

    scope track_successful_tech: {
        OS.patch_start(0xBF0B0, 0x80144670)
        jal     track_successful_tech
        sw      t7, 0x0024(sp)              // original line 2
        _return:
        OS.patch_end()

        li      at, WallTeching.successful_techs
        lbu     t8, 0x000D(t7)              // t8 = player index (0 - 3)
        sll     t8, t8, 0x0002              // t8 = player index * 4
        addu    at, at, t8                  // at = address of successful techs for this player
        lw      t8, 0x0000(at)              // t8 = successful tech count
        addiu   t8, t8, 0x0001              // increment
        sw      t8, 0x0000(at)              // store updated tech count

        _end:
        j       _return
        addiu   at, r0, 0x0001
    }

    scope track_successful_roll: {
        OS.patch_start(0xBF154, 0x80144714)
        jal     track_successful_roll
        sw      t7, 0x0024(sp)              // original line 2
        _return:
        OS.patch_end()

        li      at, WallTeching.successful_techs
        lbu     t8, 0x000D(t7)              // t8 = player index (0 - 3)
        sll     t8, t8, 0x0002              // t8 = player index * 4
        addu    at, at, t8                  // at = address of successful techs for this player
        lw      t8, 0x0000(at)              // t8 = successful tech count
        addiu   t8, t8, 0x0001              // increment
        sw      t8, 0x0000(at)              // store updated tech count

        _end:
        j       _return
        addiu   at, r0, 0x0001
    }

    scope track_failed_tech: {
        OS.patch_start(0xBF114, 0x801446D4)
        jal     track_failed_tech
        nop
        _return:
        OS.patch_end()

        beqz    at, _branch                 // original line 1, modified
        nop

        _end:
        j       _return
        nop

        _branch:
        li      at, WallTeching.missed_techs
        lw      t8, 0x0084(a0)              // t8 = player struct
        lbu     t8, 0x000D(t8)              // t8 = player index (0 - 3)
        sll     t8, t8, 0x0002              // t8 = player index * 4
        addu    at, at, t8                  // at = address of missed techs for this player
        lw      t8, 0x0000(at)              // t8 = missed tech count
        addiu   t8, t8, 0x0001              // increment
        j       0x801446EC                  // jump to end of routine
        sw      t8, 0x0000(at)              // store updated tech count
    }

    successful_techs:
    dw  0x00    // p1
    dw  0x00    // p2
    dw  0x00    // p3
    dw  0x00    // p4

    missed_techs:
    dw  0x00    // p1
    dw  0x00    // p2
    dw  0x00    // p3
    dw  0x00    // p4

}
