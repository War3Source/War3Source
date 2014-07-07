# General Skill Guidelines (WIP) #
Skills included with the War3Source core should all adhere to these guidelines to keep consistent with each other.

* Passive skills should also be in effect when the player is dead. For example a damage increase, a chance or bash or similiar.
* Passive skills that are simply *benefical* should also work on friendly fire. For example a evasion skill should also be able to evade friendly fire damage. A damage increase skill should not work on teammates.
* Skills that deal damage in any sort should be capped at 40 damage.

## Coding Tips ##
The victim/attacker parameters of the damage forwards (OnW3TakeDmgAllPre, OnW3TakeDmgBulletPre, OnW3TakeDmgAll, OnW3TakeDmgBullet) don't necessarily have to be a client. In Left4Dead they can also be Zombie entitys, so if you want to remain compatible with Left4Dead use ValidPlayer only if needed.