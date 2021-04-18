/*=======*\
| ENEMIES |
\*=======*/

::Enemy <- class extends PhysAct {
	r = 0
	health = 1
	hspeed = 0
	vspeed = 0

	function run() {
		//Collision with player
		if(gvPlayer != 0) {
			if(distance2(x, y, gvPlayer.x, gvPlayer.y) <= r + 8) { //8 for player radius
				if(y > gvPlayer.y && vspeed < gvPlayer.vspeed) gethurt()
				else hurtplayer()
			}
		}
	}

	function gethurt() {} //Spiked enemies can just call hurtplayer() here
	function hurtplayer() {}
	function _typeof() { return "Enemy" }
}

::Deathcap <- class extends Enemy {
	constructor() {
	}
}
