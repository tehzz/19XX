// Combo.asm (by Fray)
if !{defined __COMBO__} {
define __COMBO__()

// @ Description
// This file contains extensions to Sakurai's combo meter.

include "Menu.asm"
include "OS.asm"

scope Combo {

    // @ Description
    // This function makes the combo meter take grabs and wall bounces into account.
    scope improve_meter_: {
        OS.patch_start(0x0005D1CC, 0x800E19CC)
        j       improve_meter_
        nop
        _improve_meter_return:
        OS.patch_end()

        mtc1    r0, f14                     // original line 1
        andi    t9, t8, 0x0001              // original line 2
        Menu.toggle_guard(Menu.entry_improved_combo_meter, _improve_meter_return)

        // a2 contains the player struct
        // t9 contains the current value of the hitstun flag (doesn't account for wallbounces/grabs)
        // if t9 = 1, the combo meter will not reset
        // if t9 = 0, the combo meter will reset

        addiu   sp, sp,-0x0010              // ~
        sw      t0, 0x0004(sp)              // ~
        sw      t1, 0x0008(sp)              // ~
        sw      t2, 0x000C(sp)              // store t0 - t2

        // the player's current action value is loaded into t1
        // if this action value matches one of the action values defined in the action table, the 
        // hitstun flag will be overwritten with 1
        li      t0, action_table            // t0 = action_table
        lhu     t1, 0x0026(a2)              // t1 = current action value
        lhu     t2, 0x0000(t0)              // t2 = action_table value
        
        _begin_loop:
        // loops until the player's current action value matches an action value from the table
        // or if the end of the table is reached
        addiu   t0, 0x0002                  // increment action table address
        beq     t1, t2, _overwrite_flag     // if action value is in table, overwrite hitstun flag
        lhu     t2, 0x0000(t0)              // t2 = action_table value(updated)
        bnez    t2, _begin_loop             // if t2 != 0, loop (loop until table value 0 reached)
        nop

        _exit_loop:
        // The current knockback value (which is tracked in the player struct) can be used to check 
        // if the player is in hitstun the value will always represent the current knockback value 
        // being applied to the character, even after a wall bounce. This means that if the value is 
        // not equal to 0, the character can be considered as being in hitstun
        lw      t2, 0x07EC(a2)              // t2 = current knockback value
        beq     t2, r0, _skip               // if the knockback value = 0, player is not in hitstun
        nop

        _overwrite_flag:
        //overwrites the hitstun flag with 1 for this frame, causing the combo meter to not reset
        lli     t9, 0x0001                  // overwrite hitstun flag
        
        _skip:
        lw      t0, 0x0004(sp)              // ~
        lw      t1, 0x0008(sp)              // ~
        lw      t2, 0x000C(sp)              // ~
        addiu   sp, sp, 0x0010              // load t0 - t2
        j       _improve_meter_return
        nop
        
        action_table:
        // this table is used to determine which action values will override the combo meter
        dh 0x00AB                           // action value: "grabbed"
        dh 0x00AC                           // action value: "held"
        dh 0x00B3                           // action value: "falcon dive grabbed"
        dh 0x00B5                           // action value: "cargo grabbed"
        dh 0x00B8                           // action value: "cargo held"
        dh 0x00BA                           // action value: "thrown"
        dh 0x003C                           // action value: "tornado"
        dh 0x0000                           // end table    
    }
}

}