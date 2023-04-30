/////////////////
// NEW WEAPONS //
/////////////////

//All weapons will use the same return type
//Different weapons will have different stats for enemies to react to

::fireWeapon <- function(weapon, x, y, alignment, owner) {
	local c = actor[newActor(weapon, x, y, [alignment, owner])]
	c.alignment = alignment
	c.owner = owner
	return c
}

::WeaponEffect <- class extends PhysAct {
	power = 1
	element = "normal"
	cut = false
	blast = false
	piercing = 0
	owner = 0
	alignment = 0 //0 is neutral, 1 is player, 2 is enemy
	box = false //If the attack comes from a box

	constructor(_x, _y, _arr = null){
		base.constructor(_x, _y, _arr)
		if(typeof _arr == "array") {
			if(canint(_arr[0])) alignment = _arr[0].tointeger()
			if(canint(_arr[1])) owner = _arr[1].tointeger()
		}
	}

	function _typeof() { return "WeaponEffect" }
}

////////////////////
// NORMAL ATTACKS //
////////////////////

::MeleeHit <- class extends WeaponEffect {
	element = "normal"
	timer = 4

	constructor(_x, _y, _arr = null) {
		base.constructor(_x, _y, _arr)
		shape = Rec(x, y, 4, 4, 0)
	}

	function run() {
		timer--
		if(timer == 0) deleteActor(id)
	}
}

::BoxHit <- class extends WeaponEffect {
	element = "normal"
	timer = 4
	box = true
	piercing = -1

	constructor(_x, _y, _arr = null) {
		base.constructor(_x, _y, _arr)
		shape = Rec(x, y, 4, 4, 0)
	}

	function run() {
		timer--
		if(timer == 0) deleteActor(id)
	}

	function draw() { if(debug) drawSprite(sprPoof, 0, x - camx, y - camy - 8) }
}

::StompPoof <- class extends WeaponEffect{
	power = 1
	piercing = -1
	frame = 0.0
	shape = 0
	blast = true

	constructor(_x, _y, _arr = null) {
		base.constructor(_x, _y, _arr)
		shape = Rec(x, y, 8, 8, 0)
	}

	function run() {
		frame += 0.2
		if(frame >= 2) power = 0
		if(frame >= 4) deleteActor(id)
	}

	function draw() { drawSpriteEx(sprPoof, frame, x - camx, y - camy, randInt(360), 0, 1, 1, 1) }
}

::ExplodeN <- class extends WeaponEffect{
	power = 1
	frame = 0.0
	shape = 0
	piercing = -1

	constructor(_x, _y, _arr = null) {
		base.constructor(_x, _y, _arr)

		stopSound(sndBump)
		playSound(sndBump, 0)

		shape = Rec(x, y, 16, 16, 0)
	}

	function run() {
		frame += 0.2

		if(frame >= 5) deleteActor(id)

		if(gvPlayer) {
			if(owner != gvPlayer.id) if(floor(frame) <= 1 && distance2(x, y, gvPlayer.x, gvPlayer.y) < 64) {
				if(x < gvPlayer.x) gvPlayer.hspeed += 0.5
				if(x > gvPlayer.x) gvPlayer.hspeed -= 0.5
				if(y >= gvPlayer.y) gvPlayer.vspeed -= 0.8
			}
		}

		if(gvPlayer2) {
			if(owner != gvPlayer2.id) if(floor(frame) <= 1 && distance2(x, y, gvPlayer2.x, gvPlayer2.y) < 64) {
				if(x < gvPlayer2.x) gvPlayer2.hspeed += 0.5
				if(x > gvPlayer2.x) gvPlayer2.hspeed -= 0.5
				if(y >= gvPlayer2.y) gvPlayer2.vspeed -= 0.8
			}
		}
	}

	function draw() {
		drawSpriteEx(sprExplodeN, frame, x - camx, y - camy, randInt(360), 0, 1, 1, 1)
		drawLightEx(sprLightFire, 0, x - camx, y - camy, 0, 0, 0.75 - (frame / 10.0), 0.75 - (frame / 10.0))
	}
}

//////////////////
// FIRE ATTACKS //
//////////////////

::Fireball <- class extends WeaponEffect {
	element = "fire"
	timer = 90
	piercing = 1

	constructor(_x, _y, _arr = null) {
		base.constructor(_x, _y, _arr)

		shape = Rec(x, y, 3, 3, 0)
	}

	function physics() {
		//Shrink hitbox
		timer--
		if(timer == 0) deleteActor(id)

		if(!placeFree(x, y + 1)) vspeed = -1.2
		if(!placeFree(x, y - 1)) vspeed = 1
		if(!placeFree(x + 1, y) || !placeFree(x - 1, y)) {
			if(placeFree(x + 1, y) || placeFree(x - 1, y)) vspeed = -1
			else deleteActor(id)
		}
		if(!inWater(x, y)) vspeed += 0.1
		else {
			hspeed *= 0.99
			vspeed *= 0.99
		}

		if(placeFree(x + hspeed, y)) x += hspeed
		else if(placeFree(x + hspeed, y - 2)) {
			x += hspeed
			y += -2
			vspeed = -1
		} else if(inWater(x, y)) hspeed = -hspeed
		else deleteActor(id)

		if(placeFree(x, y + vspeed)) y += vspeed
		else vspeed /= 2

		if(y > gvMap.h || piercing == 0) deleteActor(id)

		shape.setPos(x, y)
	}

	function draw()  {
		drawSpriteEx(sprFireball, getFrames() / 2, x - camx, y - camy, 0, int(hspeed > 0), 1, 1, 1)
		drawLightEx(sprLightFire, 0, x - camx, y - camy, 0, 0, 1.0 / 8.0, 1.0 / 8.0)
	}

	function animation() {
		if(getFrames() % 3 == 0) {
			local c = actor[newActor(FlameTiny, x, y)]
			c.frame = 4
		}
	}

	function destructor() {
		fireWeapon(AfterFlame, x, y, alignment, owner)
	}
}

::AfterFlame <- class extends WeaponEffect {
	element = "fire"
	timer = 2

	constructor(_x, _y, _arr = null) {
		base.constructor(_x, _y, _arr)
		shape = Rec(x, y, 4, 4, 0)
	}

	function run() {
		timer--
		if(timer == 0) deleteActor(id)
	}
}

::FlameBreath <- class extends WeaponEffect {
	element = "fire"
	frame = 0.0
	angle = 0
	power = 1.0
	piercing = 0

	constructor(_x, _y, _arr = null) {
		shape = Rec(x, y, 4, 4, 0)
		base.constructor(_x, _y, _arr)
		vspeed = 0.5 - randFloat(1.0)
		fireWeapon(AfterFlame, x, y, alignment, owner)
	}

	function run() {
		angle = pointAngle(0, 0, hspeed, vspeed) - 90
		frame += 0.2
		x += hspeed
		y += vspeed
		if(checkActor(owner)) {
			x += actor[owner].hspeed
			y += actor[owner].vspeed / 2
		}
		shape.setPos(x, y)
		if(!placeFree(x, y)) deleteActor(id)
		if(frame >= 6) deleteActor(id)
	}

	function draw() {
		drawSpriteEx(sprFlameTiny, floor(frame), x - camx, y - camy, angle, 0, 1, 1, 1)
		drawLightEx(sprLightFire, 0, x - camx, y - camy, 0, 0, 1.0 / 8.0, 1.0 / 8.0)
	}
}

::FireballK <- class extends WeaponEffect {
	timer = 90
	angle = 0
	element = "fire"
	power = 1
	blast = true

	constructor(_x, _y, _arr = null) {
		base.constructor(_x, _y, _arr)

		shape = Cir(x, y, 4)
	}

	function run() {
		timer--
		if(timer == 0) deleteActor(id)

		if(!inWater(x, y)) vspeed += 0.1

		x += hspeed
		y += vspeed
		if(!placeFree(x, y)) {
			deleteActor(id)
		}

		if(y > gvMap.h) {
			deleteActor(id)
			newActor(Poof, x, y)
		}

		angle = pointAngle(0, 0, hspeed, vspeed) - 90

		shape.setPos(x, y)
	}

	function draw() {
		drawSpriteEx(sprFlame, (getFrames() / 8) % 4, x - camx, y - camy, angle, 1, 1, 1, 1)
		drawLightEx(sprLightFire, 0, x - camx, y - camy, 0, 0, 1.0 / 4.0, 1.0 / 4.0)
	}

	function destructor() {
		fireWeapon(ExplodeF, x, y, alignment, owner)
	}
}

::ExplodeF <- class extends WeaponEffect{
	frame = 0.0
	shape = 0
	piercing = -1
	element = "fire"
	power = 2
	blast = true

	constructor(_x, _y, _arr = null) {
		base.constructor(_x, _y, _arr)

		stopSound(sndExplodeF)
		playSound(sndExplodeF, 0)

		shape = Cir(x, y, 12.0)
	}

	function run() {
		frame += 0.2

		if(frame >= 5) deleteActor(id)

		if(gvPlayer) {
			if(owner != gvPlayer.id) if(floor(frame) <= 1 && distance2(x, y, gvPlayer.x, gvPlayer.y) < 64) {
				if(x < gvPlayer.x) gvPlayer.hspeed += 0.5
				if(x > gvPlayer.x) gvPlayer.hspeed -= 0.5
				if(y >= gvPlayer.y) gvPlayer.vspeed -= 0.8
			}
		}

		if(gvPlayer2) {
			if(owner != gvPlayer2.id) if(floor(frame) <= 1 && distance2(x, y, gvPlayer2.x, gvPlayer2.y) < 64) {
				if(x < gvPlayer2.x) gvPlayer2.hspeed += 0.5
				if(x > gvPlayer2.x) gvPlayer2.hspeed -= 0.5
				if(y >= gvPlayer2.y) gvPlayer2.vspeed -= 0.8
			}
		}
	}

	function draw() {
		drawSpriteEx(sprExplodeF, frame, x - camx, y - camy, randInt(360), 0, 1, 1, 1)
		drawLightEx(sprLightFire, 0, x - camx, y - camy, 0, 0, 0.75 - (frame / 10.0), 0.75 - (frame / 10.0))
	}
}

::ExplodeHiddenF <- class extends WeaponEffect{
	frame = 0.0
	shape = 0
	piercing = -1
	element = "fire"
	power = 2
	blast = true

	constructor(_x, _y, _arr = null) {
		base.constructor(_x, _y, _arr)

		stopSound(sndExplodeF)
		playSound(sndExplodeF, 0)

		shape = Cir(x, y, 12.0)
	}

	function run() {
		frame += 0.2

		if(frame >= 5) deleteActor(id)

		if(gvPlayer) {
			if(owner != gvPlayer.id) if(floor(frame) <= 1 && distance2(x, y, gvPlayer.x, gvPlayer.y) < 64) {
				if(x < gvPlayer.x) gvPlayer.hspeed += 0.5
				if(x > gvPlayer.x) gvPlayer.hspeed -= 0.5
				if(y >= gvPlayer.y) gvPlayer.vspeed -= 0.8
			}
		}

		if(gvPlayer2) {
			if(owner != gvPlayer2.id) if(floor(frame) <= 1 && distance2(x, y, gvPlayer2.x, gvPlayer2.y) < 64) {
				if(x < gvPlayer2.x) gvPlayer2.hspeed += 0.5
				if(x > gvPlayer2.x) gvPlayer2.hspeed -= 0.5
				if(y >= gvPlayer2.y) gvPlayer2.vspeed -= 0.8
			}
		}
	}
}

::FuseSpark <- class extends WeaponEffect {
	element = "fire"
	power = 0
	piercing = -1

	constructor(_x, _y, _arr = null){
		base.constructor(_x, _y, _arr)
		shape = Cir(x, y, 2)
	}

	function run() {
		shape.setPos(x, y)
		if(getFrames() % 4 == 0) newActor(FlameTiny, x - 1 + randInt(3), y - 1 + randInt(3))
	}

	function draw() { drawSprite(sprFireball, getFrames(), x - camx, y - camy) }
}

::FuseLine <- class extends PathCrawler {
	speed = 0
	obj = 0

	constructor(_x, _y, _arr = null) {
		base.constructor(_x, _y, _arr)
		shape = Cir(x, y, 8)
	}

	function run() {
		base.run()

		if(speed == 0 && "WeaponEffect" in actor && actor["WeaponEffect"].len() > 0) foreach(i in actor["WeaponEffect"]) {
			if(hitTest(shape, i.shape) && i.element == "fire") {
				speed = 2
				obj = fireWeapon(FuseSpark, x, y, 0, id)
				i.piercing--
			}
		}

		if(obj != 0) {
			obj.x = x
			obj.y = y
		}
	}

	function draw() { if(speed == 0) drawSprite(sprSteelBall, 0, x - camx, y - camy) }

	function pathEnd() {
		deleteActor(obj.id)
		deleteActor(id)
	}
}

/////////////////
// ICE ATTACKS //
/////////////////

::Iceball <- class extends WeaponEffect {
	element = "ice"
	timer = 90

	constructor(_x, _y, _arr = null) {
		base.constructor(_x, _y, _arr)

		shape = Rec(x, y, 3, 3, 0)
	}

	function physics() {
		timer--
		if(timer == 0) deleteActor(id)

		if(!placeFree(x, y + 1)) vspeed = -1.2
		if(!placeFree(x, y - 1)) vspeed = 1
		if(!placeFree(x + 1, y) || !placeFree(x - 1, y)) {
			if(placeFree(x + 1, y) || placeFree(x - 1, y)) vspeed = -1
			else deleteActor(id)
		}
		if(!inWater(x, y)) vspeed += 0.1
		else {
			hspeed *= 0.99
			vspeed *= 0.99
		}

		if(placeFree(x + hspeed, y)) x += hspeed
		else if(placeFree(x + hspeed, y - 2)) {
			x += hspeed
			y += -2
			vspeed = -1
		} else if(inWater(x, y)) hspeed = -hspeed
		else deleteActor(id)

		if(placeFree(x, y + vspeed)) y += vspeed
		else vspeed /= 2

		if(y > gvMap.h) {
			deleteActor(id)
			newActor(Poof, x, y)
		}

		shape.setPos(x, y)
	}

	function animation() {
		if(getFrames() % 5 == 0) newActor(Glimmer, x - 4 + randInt(8), y - 4 + randInt(8))
	}

	function draw() {
		drawSpriteEx(sprIceball, getFrames() / 2, x - camx, y - camy, 0, 0, 1, 1, 1)
		drawLightEx(sprLightIce, 0, x - camx, y - camy, 0, 0, 1.0 / 8.0, 1.0 / 8.0)
	}

	function destructor() {
		fireWeapon(AfterIce, x, y, alignment, owner)
	}
}

::AfterIce <- class extends WeaponEffect {
	element = "ice"
	timer = 2

	constructor(_x, _y, _arr = null) {
		base.constructor(_x, _y, _arr)
		shape = Rec(x, y, 4, 4, 0)
	}

	function run() {
		timer--
		if(timer == 0) deleteActor(id)
	}
}

::ExplodeI <- class extends WeaponEffect{
	power = 2
	frame = 0.0
	shape = 0
	piercing = -1
	element = "ice"
	blast = true
	angle = 0

	constructor(_x, _y, _arr = null) {
		base.constructor(_x, _y, _arr)

		popSound(sndBump, 0)

		shape = Rec(x, y, 16, 16, 0)
		angle = randInt(360)
	}

	function run() {
		frame += 0.2

		if(frame >= 5) deleteActor(id)

		if(gvPlayer) {
			if(owner != gvPlayer.id) if(floor(frame) <= 1 && distance2(x, y, gvPlayer.x, gvPlayer.y) < 64) {
				if(x < gvPlayer.x) gvPlayer.hspeed += 0.5
				if(x > gvPlayer.x) gvPlayer.hspeed -= 0.5
				if(y >= gvPlayer.y) gvPlayer.vspeed -= 0.8
			}
		}

		if(gvPlayer2) {
			if(owner != gvPlayer2.id) if(floor(frame) <= 1 && distance2(x, y, gvPlayer2.x, gvPlayer2.y) < 64) {
				if(x < gvPlayer2.x) gvPlayer2.hspeed += 0.5
				if(x > gvPlayer2.x) gvPlayer2.hspeed -= 0.5
				if(y >= gvPlayer2.y) gvPlayer2.vspeed -= 0.8
			}
		}
	}

	function draw() {
		drawSpriteEx(sprExplodeI, frame, x - camx, y - camy, angle, 0, 1, 1, 1)
		drawLightEx(sprLightIce, 0, x - camx, y - camy, 0, 0, 0.75 - (frame / 10.0), 0.75 - (frame / 10.0))
	}
}

::IceBreath <- class extends WeaponEffect {
	element = "ice"
	frame = 0.0
	angle = 0
	power = 1.0
	piercing = 0

	constructor(_x, _y, _arr = null) {
		shape = Rec(x, y, 4, 4, 0)
		base.constructor(_x, _y, _arr)
		vspeed = 0.5 - randFloat(1.0)
	}
	function run() {
		angle = pointAngle(0, 0, hspeed, vspeed) - 90
		frame += 0.2
		x += hspeed
		y += vspeed
		if(gvPlayer) x += gvPlayer.hspeed
		shape.setPos(x, y)
		if(!placeFree(x, y)) deleteActor(id)
		if(frame >= 6) deleteActor(id)
	}

	function draw() {
		drawSpriteEx(sprGlimmer, floor(frame), x - camx, y - camy, angle, 0, 1, 1, 1)
		drawLightEx(sprLightIce, 0, x - camx, y - camy, 0, 0, 1.0 / 8.0, 1.0 / 8.0)
	}
}

///////////////////
// SHOCK ATTACKS //
///////////////////

::ExplodeT <- class extends WeaponEffect{
	frame = 0.0
	shape = 0
	piercing = -1
	element = "shock"
	power = 2
	blast = true

	constructor(_x, _y, _arr = null) {
		base.constructor(_x, _y, _arr)

		stopSound(sndExplodeF)
		playSound(sndExplodeF, 0)

		shape = Cir(x, y, 12.0)
	}

	function run() {
		frame += 0.2

		if(frame >= 5) deleteActor(id)

		if(gvPlayer) {
			if(owner != gvPlayer.id) if(floor(frame) <= 1 && distance2(x, y, gvPlayer.x, gvPlayer.y) < 64) {
				if(x < gvPlayer.x) gvPlayer.hspeed += 0.25
				if(x > gvPlayer.x) gvPlayer.hspeed -= 0.25
				if(y >= gvPlayer.y) gvPlayer.vspeed -= 0.4
			}
		}

		if(gvPlayer2) {
			if(owner != gvPlayer2.id) if(floor(frame) <= 1 && distance2(x, y, gvPlayer2.x, gvPlayer2.y) < 64) {
				if(x < gvPlayer2.x) gvPlayer2.hspeed += 0.25
				if(x > gvPlayer2.x) gvPlayer2.hspeed -= 0.25
				if(y >= gvPlayer2.y) gvPlayer2.vspeed -= 0.4
			}
		}
	}

	function draw() {
		drawSpriteEx(sprExplodeT, frame, x - camx, y - camy, randInt(360), 0, 1, 1, 1)
		drawLightEx(sprLightFire, 0, x - camx, y - camy, 0, 0, 0.75 - (frame / 10.0), 0.75 - (frame / 10.0))
	}
}

///////////////////
// EARTH ATTACKS //
///////////////////

::EarthballK <- class extends WeaponEffect {
	timer = 90
	angle = 0
	element = "earth"
	power = 1
	blast = true
	piercing = 0

	constructor(_x, _y, _arr = null) {
		base.constructor(_x, _y, _arr)

		shape = Cir(x, y, 4)
	}

	function physics() {}

	function run() {
		base.run()
		timer--
		if(timer == 0) deleteActor(id)

		vspeed += 0.1

		x += hspeed
		y += vspeed
		if(!placeFree(x, y)) {
			deleteActor(id)
		}

		if(y > gvMap.h) {
			deleteActor(id)
			newActor(Poof, x, y)
		}

		angle = pointAngle(0, 0, hspeed, vspeed) - 90

		shape.setPos(x, y)
	}

	function draw() {
		drawSpriteEx(sprRock, 0, x - camx, y - camy, angle, 1, 1, 1, 1)
		drawLightEx(sprLightFire, 0, x - camx, y - camy, 0, 0, 1.0 / 4.0, 1.0 / 4.0)
	}

	function destructor() {
		fireWeapon(AfterEarth, x + hspeed / 2, y + vspeed / 2, alignment, owner)
		newActor(RockChunks, x, y)
		popSound(sndBump, 0)
	}
}

::AfterEarth <- class extends WeaponEffect {
	element = "earth"
	timer = 2

	constructor(_x, _y, _arr = null) {
		base.constructor(_x, _y, _arr)
		shape = Rec(x, y, 4, 4, 0)
	}

	function run() {
		timer--
		if(timer == 0) deleteActor(id)
	}
}

::NutBomb <- class extends WeaponEffect {
	timer = 90
	element = "normal"
	power = 0
	blast = false
	piercing = 0

	constructor(_x, _y, _arr = null) {
		base.constructor(_x, _y, _arr)

		shape = Cir(x, y, 4)
	}

	function run() {
		timer--
		if(timer == 0) deleteActor(id)

		if(!inWater(x, y)) vspeed += 0.1
		else {
			hspeed *= 0.9
			vspeed *= 0.9
		}

		x += hspeed
		y += vspeed
		if(!placeFree(x, y)) {
			deleteActor(id)
		}

		if(y > gvMap.h) {
			deleteActor(id)
			newActor(Poof, x, y)
		}

		angle = pointAngle(0, 0, hspeed, vspeed) - 90

		shape.setPos(x, y)
	}

	function draw() {
		drawSprite(sprNutBomb, (getFrames() / 8) % 4, x - camx, y - camy)
		drawLight(sprLightFire, 0, x - camx - 4, y - camy, 0, 0, 1.0 / 8.0, 1.0 / 8.0)
	}

	function destructor() {
		switch(element) {
			case "normal":
				fireWeapon(ExplodeN, x, y, alignment, owner)
				break
			case "fire":
				fireWeapon(ExplodeF, x, y, alignment, owner)
				break
			case "ice":
				fireWeapon(ExplodeI, x, y, alignment, owner)
				break
			case "shock":
				fireWeapon(ExplodeT, x, y, alignment, owner)
				break
		}
	}
}