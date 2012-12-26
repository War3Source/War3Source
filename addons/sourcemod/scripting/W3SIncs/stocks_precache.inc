

// default beamsprite which is often used (moved here to keep compatibilty across diff. games)
stock War3_PrecacheBeamSprite() {
	new w3_spriteindex = -1;
	if(GAMECSGO) {
		w3_spriteindex=PrecacheModel("materials/sprites/laserbeam.vmt");
	}
	else {
		w3_spriteindex=PrecacheModel("materials/sprites/lgtning.vmt");
	}
	if(w3_spriteindex == -1) {
		LogError("Failed to precache BeamSprite material!");
	}
	return w3_spriteindex;
}
// same goes for halosprite
stock War3_PrecacheHaloSprite() {
	new w3_spriteindex = -1;
	if(GAMECSGO) {
		w3_spriteindex=PrecacheModel("materials/sprites/halo.vmt");
	}
	else {
		w3_spriteindex=PrecacheModel("materials/sprites/halo01.vmt");
	}
	if(w3_spriteindex == -1) {
		LogError("Failed to precache HaloSprite material!");
	}
	return w3_spriteindex;
}