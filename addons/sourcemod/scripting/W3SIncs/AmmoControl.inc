/**
 * File: AmmoControl.inc
 * Description: Native Interface to Ammo Control Addon.
 * Author(s): Frenzzy
 * 
 *
 * THIS FILE MUST BE MANUALLY INCLUDED   
 */

/**
 * Give ammo and/or clip for player's weapon.
 *
 * @param client: Client Index. Must be valid.
 * @param weapon: Weapon Index. Must be valid.
 * @param ammo: Amount of Ammo. Optional value. Use -1 to leave as it is.
 * @param clip: Amount of Clip. Optional value. Use -1 to leave as it is.
 * @noreturn
 */
native War3_GiveWeaponAmmo(client, weapon, ammo = -1, clip = -1);

/**
 * Set Ammo Control for player.
 * Auto control for the specified amount of ammo and the ammo in the clip after a buy (rebuy and autobuy) or reload.
 * Does not set an ammo and a clip, when GivePlayerItem used. Changes an ammo and/or a clip with a War3_GiveWeaponAmmo after a GivePlayerItem.
 * Also it does not give ammo, when player picks-up and gets the specified weapon from another player.
 *
 * @param client: Client Index. Use only this parameter to reset the ammo and the clip to deafult.
 * @param weapon: Weapon Name. Optional value. You can use these values instead of weapon names: weapon_primary, weapon_secondary, weapon_grenade or weapon_all.
 * @param ammo: Amount of Ammo. Optional value. Use -1 to leave as it is.
 * @param clip: Amount of Clip. Optional value. Use -1 to leave as it is.
 * @param update: Immediately Update. Optional value. Immediately ammo and/or clip update, if player is alive and has specified weapon(s).
 * @noreturn
 */
native War3_SetAmmoControl(client, String:weapon[], ammo = -1, clip = -1, bool:update = false);
