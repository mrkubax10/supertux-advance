::Enemy <- class extends PhysAct {
	health = 1.0
	active = false
	frozen = 0
	freezeTime = 600
	freezeSprite = -1
	icebox = -1
	nocount = false
	damageMult = {
		normal = 1.0
		fire = 1.0
		ice = 1.0
		earth = 1.0
		air = 1.0
		toxic = 1.0
		shock = 1.0
		water = 1.0
		light = 1.0
		dark = 1.0
		cut = 1.0
		blast = 1.0
	}
	blinking = 0
	blinkMax = 10
	touchDamage = 0.0
	element = "normal"
	stompDamage = 1.0
	thorny = false

	constructor(_x, _y, _arr = null) {
		base.constructor(_x, _y)
	}

	function run() {
		if(active) {
			base.run()
			if(frozen > 0) {
				frozen--
				if(floor(frozen / 4) % 2 == 0 && frozen < 60) drawSpriteZ(4, freezeSprite, 0, x - camx - 1 + ((floor(frozen / 4) % 4 == 0).tointeger() * 2), y - camy - 1)
				else drawSpriteZ(4, freezeSprite, 0, x - camx, y - camy - 1)
			}
		}
		else {
			if(inDistance2(x, y, camx + (screenW() / 2), camy + (screenH() / 2), 240)) active = true
		}

		if(blinking > 0) blinking--

		//Check for weapon effects
		if(actor.rawin("WeaponEffect")) foreach(i in actor["WeaponEffect"]) {
			//Skip weapons that don't hurt this enemy
			if(i.alignment == 2) continue
			if(i.owner == id) continue

			if(hitTest(shape, i.shape)) {
				getHurt(i.power, i.element, i.cut, i.blast)
				if(i.piercing == 0) deleteActor(i.id)
				else i.piercing--
			}
		}

		if(gvPlayer) {
			if(hitTest(shape, gvPlayer.shape) && !frozen) { //8 for player radius
				if(gvPlayer.invincible > 0) hurtInvinc()
				else if(y > gvPlayer.y && vspeed < gvPlayer.vspeed && gvPlayer.canStomp && gvPlayer.placeFree(gvPlayer.x, gvPlayer.y + 2) && blinking == 0 && !thorny && !gvPlayer.swimming) {
					getHurt(stompDamage, "normal", false, false)
					if(getcon("jump", "hold")) gvPlayer.vspeed = -8.0
					else gvPlayer.vspeed = -4.0
				}
				else if(gvPlayer.rawin("anSlide") && blinking == 0 && !thorny) {
					if(gvPlayer.anim == gvPlayer.anSlide) getHurt(1, "normal", false, false)
					else hurtPlayer()
				}
				else hurtPlayer()
			}
		}
	}

	function hurtInvinc() {
		newActor(Poof, x, ystart - 6)
		newActor(Poof, x, ystart + 8)
		die()
		playSound(sndFlame, 0)
	}

	function die() {
		deleteActor(id)

		if(icebox != -1) {
			mapDeleteSolid(icebox)
			newActor(IceChunks, x, ystart - 6)
			icebox = -1
		}

		if(!nocount) game.enemies--
	}

	function getHurt(_mag = 1, _element = "normal", _cut = false, _blast = false) {
		if(blinking > 0) return

		local damage = _mag * damageMult[_element]
		if(_cut) damage *= damageMult["cut"]
		if(_blast) damage *= damageMult["blast"]

		health -= damage
		if(damage > 0) blinking = blinkMax

		if(health <= 0) {
			die()
			return
		}
		if(_element == "ice") frozen = freezeTime * damageMult["ice"]
		if(_element == "fire") {
			newActor(Flame, x, y)
			stopSound(sndFlame)
			playSound(sndFlame, 0)
		}
		blinking = blinkMax
	}

	function hurtPlayer() {
		gvPlayer.hurt = touchDamage * gvPlayer.damageMult[element]
	}

	function destructor() {
		if(icebox != -1) mapDeleteSolid(icebox)
	}
}

::DeadNME <- class extends Actor {
	sprite = 0
	frame = 0
	hspeed = 0.0
	vspeed = 0.0
	angle = 0.0
	spin = 0
	flip = 0
	gravity = 0.2

	constructor(_x, _y, _arr = null) {
		base.constructor(_x, _y)
		vspeed = -3.0
	}

	function run() {
		vspeed += gravity
		x += hspeed
		y += vspeed
		angle += spin
		if(y > gvMap.h + 32) deleteActor(id)
		drawSpriteEx(sprite, frame, floor(x - camx), floor(y - camy), angle, flip, 1, 1, 1)
	}
}

//////////////////////
// SPECIFIC ENEMIES //
//////////////////////

::Deathcap <- class extends Enemy {
	frame = 0.0
	flip = false
	squish = false
	squishTime = 0.0
	smart = false
	moving = false
	touchDamage = 2.0

	constructor(_x, _y, _arr = null) {
		base.constructor(_x.tofloat(), _y.tofloat())
		shape = Rec(x, y, 6, 6, 0)

		smart = _arr
	}

	function routine() {}
	function animation() {}

	function run() {
		base.run()

		if(active) {
			if(!moving) if(gvPlayer) if(x > gvPlayer.x) {
				flip = true
				moving = true
			}

			if(!squish) {
				if(placeFree(x, y + 1)) vspeed += 0.1
				if(placeFree(x, y + vspeed)) y += vspeed
				else vspeed /= 2

				if(y > gvMap.h + 8) die()

				if(!frozen) {
					if(flip) {
						if(placeFree(x - 1, y)) x -= 1.0
						else if(placeFree(x - 2, y - 2)) {
							x -= 1.0
							y -= 1.0
						} else if(placeFree(x - 1, y - 2)) {
							x -= 1.0
							y -= 1.0
						} else flip = false

						if(smart) if(placeFree(x - 6, y + 14)) flip = false

						if(x <= 0) flip = false
					}
					else {
						if(placeFree(x + 1, y)) x += 1.0
						else if(placeFree(x + 1, y - 1)) {
							x += 1.0
							y -= 1.0
						} else if(placeFree(x + 2, y - 2)) {
							x += 1.0
							y -= 1.0
						} else flip = true

						if(smart) if(placeFree(x + 6, y + 14)) flip = true

						if(x >= gvMap.w) flip = true
					}
				}

				if(frozen) {
					//Create ice block
					if(gvPlayer) if(icebox == -1 && !hitTest(shape, gvPlayer.shape)) {
						icebox = mapNewSolid(shape)
					}

					//Draw
					if(smart) drawSpriteEx(sprGradcap, 0, floor(x - camx), floor(y - camy), 0, flip.tointeger(), 1, 1, 1)
					else drawSpriteEx(sprDeathcap, 0, floor(x - camx), floor(y - camy), 0, flip.tointeger(), 1, 1, 1)

					if(frozen <= 120) {
					if(floor(frozen / 4) % 2 == 0) drawSprite(sprIceTrapSmall, 0, x - camx - 1 + ((floor(frozen / 4) % 4 == 0).tointeger() * 2), y - camy - 1)
						else drawSprite(sprIceTrapSmall, 0, x - camx, y - camy - 1)
					}
					else drawSprite(sprIceTrapSmall, 0, x - camx, y - camy - 1)
				}
				else {
					//Delete ice block
					if(icebox != -1) {
						mapDeleteSolid(icebox)
						newActor(IceChunks, x, y)
						icebox = -1
						if(gvPlayer) if(x > gvPlayer.x) flip = true
						else flip = false
					}

					//Draw
					if(smart) drawSpriteEx(sprGradcap, wrap(getFrames() / 8, 0, 3), floor(x - camx), floor(y - camy), 0, flip.tointeger(), 1, 1, 1)
					else drawSpriteEx(sprDeathcap, wrap(getFrames() / 8, 0, 3), floor(x - camx), floor(y - camy), 0, flip.tointeger(), 1, 1, 1)
				}
			}
			else {
				squishTime += 0.025
				if(squishTime >= 1) die()
				if(smart) drawSpriteEx(sprDeathcap, floor(4.8 + squishTime), floor(x - camx), floor(y - camy), 0, flip.tointeger(), 1, 1, 1)
				else drawSpriteEx(sprDeathcap, floor(4.8 + squishTime), floor(x - camx), floor(y - camy), 0, flip.tointeger(), 1, 1, 1)
			}

			shape.setPos(x, y)
			setDrawColor(0xff0000ff)
			if(debug) shape.draw()
		}
	}

	function hurtPlayer() {
		if(squish) return
		base.hurtPlayer()
	}

	function getHurt(_mag = 1, _element = "normal", _cut = false, _blast = false) {
		if(squish) return

		if(_blast) {
			hurtblast()
			return
		}

		if(_element == "fire") {
			newActor(Flame, x, y - 1)
			die()
			playSound(sndFlame, 0)

			if(randInt(20) == 0) {
				local a = actor[newActor(MuffinBlue, x, y)]
				a.vspeed = -2
			}
			return
		}

		if(_element == "ice") {
			frozen = 600
			return
		}

		if(gvPlayer.rawin("anSlide")) {
			if(gvPlayer.anim == gvPlayer.anSlide) {
				local c = newActor(DeadNME, x, y)
				actor[c].sprite = sprDeathcap
				actor[c].vspeed = min(-fabs(gvPlayer.hspeed), -4)
				actor[c].hspeed = (gvPlayer.hspeed / 16)
				actor[c].spin = (gvPlayer.hspeed * 7)
				actor[c].angle = 180
				die()
				playSound(sndKick, 0)
			}
			else if(getcon("jump", "hold")) gvPlayer.vspeed = -8.0
			else {
				gvPlayer.vspeed = -4.0
				playSound(sndSquish, 0)
			}
			if(gvPlayer.anim == gvPlayer.anJumpT || gvPlayer.anim == gvPlayer.anFall) {
				gvPlayer.anim = gvPlayer.anJumpU
				gvPlayer.frame = gvPlayer.anJumpU[0]
			}
		}
		else if(getcon("jump", "hold")) gvPlayer.vspeed = -8.0
		else gvPlayer.vspeed = -4.0
		if(gvPlayer.anim == gvPlayer.anJumpT || gvPlayer.anim == gvPlayer.anFall) {
			gvPlayer.anim = gvPlayer.anJumpU
			gvPlayer.frame = gvPlayer.anJumpU[0]
		}

		squish = true
	}

	function hurtblast() {
		local c = newActor(DeadNME, x, y)
		actor[c].sprite = sprDeathcap
		actor[c].vspeed = -4
		actor[c].hspeed = (4 / 16)
		actor[c].spin = (4 * 7)
		actor[c].angle = 180
		die()
		playSound(sndKick, 0)
		if(icebox != -1) mapDeleteSolid(icebox)
	}

	function hurtFire() {
		newActor(Flame, x, y - 1)
		die()
		stopSound(sndFlame)
		playSound(sndFlame, 0)

		if(randInt(20) == 0) {
			local a = actor[newActor(MuffinBlue, x, y)]
			a.vspeed = -2
		}
	}

	function hurtice() { frozen = 600 }

	function _typeof() { return "Deathcap" }
}

::PipeSnake <- class extends Enemy {
	ystart = 0
	timer = 30
	up = false
	flip = 1
	touchDamage = 2.0
	stompDamage = 0.0

	constructor(_x, _y, _arr = null) {
		base.constructor(_x, _y)
		ystart = y
		shape = Rec(x, y, 8, 12, 0)
		timer = (x * y) % 60
		flip = _arr
	}

	function physics() {}

	function run() {
		base.run()

		if(up && y > ystart - 32 && !frozen) y -= 2
		if(!up && y < ystart && !frozen) y += 2

		timer--
		if(timer <= 0) {
			up = !up
			timer = 60
		}

		shape.setPos(x, y + 16)
		if(frozen) {
			//Create ice block
			if(gvPlayer) if(icebox == -1 && !hitTest(shape, gvPlayer.shape)) {
				icebox = mapNewSolid(shape)
			}

			if(flip == 1) drawSpriteEx(sprSnake, 0, floor(x - camx), floor(y - camy), 0, 0, 1, 1, 1)
			if(flip == -1) drawSpriteEx(sprSnake, 0, floor(x - camx), floor(y - camy) + 32, 0, 2, 1, 1, 1)

			if(flip == 1) drawSpriteEx(sprSnake, 1, floor(x - camx), floor(y - camy), 0, 0, 1, 1, 1)
			if(flip == -1) drawSpriteEx(sprSnake, 1, floor(x - camx), floor(y - camy) - 8, 0, 2, 1, 1, 1)
			if(frozen <= 120) {
				if(floor(frozen / 4) % 2 == 0) drawSprite(sprIceTrapTall, 0, x - camx - 1 + ((floor(frozen / 4) % 4 == 0).tointeger() * 2), y - camy + 16)
				else drawSprite(sprIceTrapTall, 0, x - camx, y - camy + 16)
			}
			else drawSprite(sprIceTrapTall, 0, x - camx, y - camy + 16)
		}
		else {
			//Delete ice block
			if(icebox != -1) {
				mapDeleteSolid(icebox)
				newActor(IceChunks, x, ystart - 6)
				icebox = -1
			}

			if(flip == 1) drawSpriteEx(sprSnake, getFrames() / 8, floor(x - camx), floor(y - camy), 0, 0, 1, 1, 1)
			if(flip == -1) drawSpriteEx(sprSnake, getFrames() / 8, floor(x - camx), floor(y - camy) + 32, 0, 2, 1, 1, 1)
		}

		if(debug) {
			setDrawColor(0x008000ff)
			shape.draw()
		}
	}

	function getHurt(_mag = 1, _element = "normal", _cut = false, _blast = false) {
		if(!gvPlayer) return
		if(_mag == 0) return

		if(hitTest(shape, gvPlayer.shape)) {
			local didhurt = false
			if(gvPlayer.rawin("anSlide")) if(gvPlayer.anim == gvPlayer.anSlide) didhurt = true
			if(gvPlayer.rawin("anStomp")) if(gvPlayer.anim == gvPlayer.anStomp) didhurt = true
			if(!didhurt) hurtPlayer()
		}

		if(_element == "fire") hurtFire()
		else if(_element == "ice") hurtIce()
		else if(_blast) hurtBlast()
		else {
			newActor(Poof, x, ystart - 8)
			newActor(Poof, x, ystart + 8)
			die()
			playSound(sndKick, 0)

			if(icebox != -1) {
				mapDeleteSolid(icebox)
				newActor(IceChunks, x, ystart - 6)
				icebox = -1
			}
		}
	}

	function hurtBlast() { hurtInvinc() }

	function hurtInvinc() {
		newActor(Poof, x, ystart - 6)
		newActor(Poof, x, ystart + 8)
		die()
		playSound(sndFlame, 0)

		if(icebox != -1) {
				mapDeleteSolid(icebox)
				newActor(IceChunks, x, ystart - 6)
				icebox = -1
			}
	}

	function hurtFire() {
		newActor(Flame, x, ystart - 6)
		newActor(Flame, x, ystart + 8)
		die()
		playSound(sndFlame, 0)

		if(icebox != -1) {
				mapDeleteSolid(icebox)
				newActor(IceChunks, x, ystart - 6) // Not resetting icebox here to avoid the ice box solid from remaining in place indefinitely.
			}
	}

	function hurtIce() { frozen = 600 }

	function _typeof() { return "Snake" }
}

::SnowBounce <- class extends Enemy {
	frame = 0.0
	flip = false
	squish = false
	squishTime = 0.0
	smart = false
	touchDamage = 2.0

	constructor(_x, _y, _arr = null) {
		base.constructor(_x.tofloat(), _y.tofloat())
		shape = Rec(x, y, 6, 6, 0)

		vspeed = -3.0
	}

	function physics() {}

	function run() {
		base.run()

		if(active) {
			if(gvPlayer && hspeed == 0) {
				if(x > gvPlayer.x) hspeed = -0.5
				else hspeed = 0.5
			}

			if(!placeFree(x, y + 1)) vspeed = -3.0
			if(!placeFree(x + 2, y - 2) && !placeFree(x + 2, y)) hspeed = -fabs(hspeed)
			if(!placeFree(x - 2, y - 2) && !placeFree(x - 2, y)) hspeed = fabs(hspeed)
			vspeed += 0.1

			if(hspeed > 0) flip = 0
			else flip = 1

			if(!frozen) {
				if(placeFree(x + hspeed, y)) x += hspeed
				if(placeFree(x, y + vspeed)) y += vspeed
				else vspeed /= 2
			}

			shape.setPos(x, y)

			//Draw
			drawSpriteEx(sprSnowBounce, getFrames() / 8, floor(x - camx), floor(y - camy), 0, flip.tointeger(), 1, 1, 1)

			if(frozen) {
				//Create ice block
				if(gvPlayer) if(icebox == -1 && !hitTest(shape, gvPlayer.shape)) {
					icebox = mapNewSolid(shape)
				}

				//Draw
				drawSpriteEx(sprSnowBounce, 0, floor(x - camx), floor(y - camy), 0, flip.tointeger(), 1, 1, 1)

				if(frozen <= 120) {
				if(floor(frozen / 4) % 2 == 0) drawSprite(sprIceTrapSmall, 0, x - camx - 1 + ((floor(frozen / 4) % 4 == 0).tointeger() * 2), y - camy - 1)
					else drawSprite(sprIceTrapSmall, 0, x - camx, y - camy - 1)
				}
				else drawSprite(sprIceTrapSmall, 0, x - camx, y - camy - 1)
			}
			else {
				//Delete ice block
				if(icebox != -1) {
					mapDeleteSolid(icebox)
					newActor(IceChunks, x, y)
					icebox = -1
					if(gvPlayer) if(x > gvPlayer.x) flip = true
					else flip = false
				}
			}
		}

		if(x < 0) hspeed = fabs(hspeed)
		if(x > gvMap.w) hspeed = -fabs(hspeed)
	}

	function getHurt(_mag = 1, _element = "normal", _cut = false, _blast = false) {
		if(_element == "ice") {
			hurtIce()
			return
		}

		if(gvPlayer) if(hitTest(shape, gvPlayer.shape)) {
			newActor(Poof, x, y)
			die()
			playSound(sndSquish, 0)
			if(keyDown(config.key.jump)) gvPlayer.vspeed = -8
			else gvPlayer.vspeed = -4
		}

		if(_element == "fire") hurtFire()
		if(_element == "ice") hurtIce()
		if(_blast) hurtBlast()

		if(icebox != -1) {
			mapDeleteSolid(icebox)
			newActor(IceChunks, x, y)
		}
	}

	hurtFire = Deathcap.hurtFire

	function hurtIce() { frozen = 600 }

	function hurtBlast() { hurtInvinc() }

	function hurtInvinc() {
		newActor(Poof, x, y)
		die()
		playSound(sndFlame, 0)

		if(icebox != -1) {
				mapDeleteSolid(icebox)
				newActor(IceChunks, x, ystart - 6)
				icebox = -1
			}
	}

	function _typeof() { return "SnowBounce" }
}

::CarlBoom <- class extends Enemy {
	burnt = false
	frame = 0.0
	flip = false
	squish = false
	squishTime = 0.0
	hspeed = 0.0
	touchDamage = 2.0

	constructor(_x, _y, _arr = null) {
		base.constructor(_x.tofloat(), _y.tofloat())
		shape = Rec(x, y, 6, 6, 0, 0, 1)
		if(gvPlayer) if(x > gvPlayer.x) flip = true
	}

	function run() {
		base.run()

		if(active) {
			if(placeFree(x, y + 1)) vspeed += 0.1
			if(placeFree(x, y + vspeed)) y += vspeed
			else vspeed /= 2

			if(!squish) {
				if(y > gvMap.h + 8) deleteActor(id)

				if(!frozen) {
					if(flip) {
						if(placeFree(x - 1, y)) x -= 1.0
						else if(placeFree(x - 2, y - 2)) {
							x -= 1.0
							y -= 1.0
						} else if(placeFree(x - 1, y - 2)) {
							x -= 1.0
							y -= 1.0
						} else flip = false

						if(placeFree(x - 6, y + 14)) flip = false

						if(x <= 0) flip = false
					}
					else {
						if(placeFree(x + 1, y)) x += 1.0
						else if(placeFree(x + 1, y - 1)) {
							x += 1.0
							y -= 1.0
						} else if(placeFree(x + 2, y - 2)) {
							x += 1.0
							y -= 1.0
						} else flip = true

						if(placeFree(x + 6, y + 14)) flip = true

						if(x >= gvMap.w) flip = true
					}
				}

				if(frozen) {
					//Create ice block
					if(gvPlayer) if(icebox == -1 && !hitTest(shape, gvPlayer.shape)) {
						icebox = mapNewSolid(shape)
					}

					//Draw
					drawSpriteEx(sprCarlBoom, 0, floor(x - camx), floor(y - camy), 0, flip.tointeger(), 1, 1, 1)

					if(frozen <= 120) {
					if(floor(frozen / 4) % 2 == 0) drawSprite(sprIceTrapSmall, 0, x - camx - 1 + ((floor(frozen / 4) % 4 == 0).tointeger() * 2), y - camy - 1)
						else drawSprite(sprIceTrapSmall, 0, x - camx, y - camy - 1)
					}
					else drawSprite(sprIceTrapSmall, 0, x - camx, y - camy - 1)
				}
				else {
					//Delete ice block
					if(icebox != -1) {
						mapDeleteSolid(icebox)
						newActor(IceChunks, x, y)
						icebox = -1
						if(gvPlayer) if(x > gvPlayer.x) flip = true
						else flip = false
					}

					//Draw
					drawSpriteEx(sprCarlBoom, wrap(getFrames() / 8, 0, 3), floor(x - camx), floor(y - camy), 0, flip.tointeger(), 1, 1, 1)
				}
			}
			else {
				squishTime += 1.5
				frame += 0.002 * squishTime
				drawSpriteEx(sprCarlBoom, wrap(frame, 4, 7), x - camx, y - camy, 0, flip.tointeger(), 1, 1, 1)
				if(getFrames() % 20 == 0) {
					local c
					if(!flip) c = actor[newActor(FlameTiny, x - 6, y - 8)]
					else c = actor[newActor(FlameTiny, x + 6, y - 8)]
					c.vspeed = -0.1
					c.hspeed = randFloat(0.2) - 0.1
				}

				if(frozen) {
					squish = false
					squishTime = 0
				}

				//Get carried
				if(getcon("shoot", "hold") && gvPlayer) {
					if(hitTest(shape, gvPlayer.shape) && (gvPlayer.held == null || gvPlayer.held == id)) {
						if(gvPlayer.flip == 0) x = gvPlayer.x + 8
						else x = gvPlayer.x - 8
						y = gvPlayer.y
						vspeed = 0
						squishTime -= 1.0
						hspeed = gvPlayer.hspeed
						gvPlayer.held = id
						if(squishTime >= 150) gvPlayer.held = null
					}
					else if(gvPlayer.held == id) gvPlayer.held = null
				}

				//Move
				if(placeFree(x + hspeed, y)) x += hspeed
				else if(placeFree(x + hspeed, y - 2)) {
					x += hspeed
					y -= 1.0
				}
				if(!placeFree(x, y + 1)) hspeed *= 0.9
				if(fabs(hspeed) < 0.1) hspeed = 0.0

				//Explode
				if(squishTime >= 150) {
					deleteActor(id)
					fireWeapon(ExplodeF, x, y, 0, id)
					if(gvPlayer) if(gvPlayer.held == id) gvPlayer.held = null
				}
			}

			shape.setPos(x, y)
			setDrawColor(0xff0000ff)
			if(debug) shape.draw()
		}
	}

	function hurtPlayer() {
		if(squish) return
		base.hurtPlayer()
	}

	function hurtBlast() {
		if(squish) return
		if(frozen) frozen = 0
		stopSound(sndFizz)
		playSound(sndFizz, 0)
		if(icebox != -1) {
			mapDeleteSolid(icebox)
			newActor(IceChunks, x, y)
		}
		squish = true

	}

	function getHurt(_mag = 1, _element = "normal", _cut = false, _blast = false) {
		if(_element == "ice") {
			hurtIce()
			return
		}
		else if(_element == "fire") {
			hurtFire()
			return
		}
		else if(squish) return

		stopSound(sndFizz)
		playSound(sndFizz, 0)
		if(getcon("jump", "hold")) gvPlayer.vspeed = -8
		else gvPlayer.vspeed = -4
		if(gvPlayer.anim == gvPlayer.anJumpT || gvPlayer.anim == gvPlayer.anFall) {
			gvPlayer.anim = gvPlayer.anJumpU
			gvPlayer.frame = gvPlayer.anJumpU[0]
		}

		squish = true
	}

	function hurtFire() {
		if(icebox != -1) {
			mapDeleteSolid(icebox)
			newActor(IceChunks, x, y)
		}
		if(!burnt) {
			fireWeapon(ExplodeF, x, y - 1, 2, id)
			die()
			playSound(sndFlame, 0)

			burnt = true
		}
	}

	function hurtIce() { frozen = 600 }

	function _typeof() { return "CarlBoom" }
}

::BlueFish <- class extends Enemy {
	timer = 0
	frame = 0.0
	biting = false
	flip = 0
	touchDamage = 2.0

	constructor(_x, _y, _arr = null) {
		base.constructor(_x, _y)
		shape = Rec(x, y, 8, 6, 0)
		hspeed = 0.5
	}

	function physics() {}
	function animation() {}
	function routine() {}

	function run() {
		base.run()

		if(active) {
			if(!placeFree(x + (hspeed * 2), y)) hspeed = -hspeed
			if(!placeFree(x, y + (vspeed * 2))) vspeed = -vspeed
			flip = (hspeed < 0).tointeger()

			timer--
			if(timer <= 0) {
				timer = 240
				vspeed = -0.5 + randFloat(1)
			}
			if(!inWater(x, y)) vspeed += 0.1
			vspeed *= 0.99

			if(gvPlayer) if(hitTest(shape, gvPlayer.shape)) biting = true
			if(frame >= 4) {
				biting = false
				frame = 0.0
			}

			if(biting) {
				drawSpriteEx(sprBlueFish, 4 + frame, x - camx, y - camy, 0, flip, 1, 1, 1)
				frame += 0.125
			}
			else drawSpriteEx(sprBlueFish, wrap(getFrames() / 16, 0, 3), x - camx, y - camy, 0, flip, 1, 1, 1)

			if(y > gvMap.h) {
				if(vspeed > 0) vspeed = 0
				vspeed -= 0.1
			}

			if(x > gvMap.w) hspeed = -1.0
			if(x < 0) hspeed = 1.0

			if(placeFree(x + hspeed, y)) x += hspeed
			if(placeFree(x, y + vspeed)) y += vspeed
			shape.setPos(x, y)
		}
	}

	function getHurt(_mag = 1, _element = "normal", _cut = false, _blast = false) {
		if(gvPlayer.rawin("anSlide")) if(gvPlayer.anim == gvPlayer.anSlide && game.weapon == 4) hurtFire()
		if(_element == "fire") hurtFire()
	}

	function hurtFire() {
		local c = newActor(DeadNME, x, y)
		actor[c].sprite = sprDeadFish
		actor[c].vspeed = -0.5
		actor[c].flip = flip
		actor[c].hspeed = hspeed
		if(flip == 1) actor[c].spin = -1
		else actor[c].spin = 1
		actor[c].gravity = 0.02
		deleteActor(id)
		playSound(sndKick, 0)
		game.enemies--
		newActor(Poof, x + 8, y)
		newActor(Poof, x - 8, y)
		if(randInt(20) == 0) {
			local a = actor[newActor(MuffinBlue, x, y)]
			a.vspeed = -2
		}
	}

	function _typeof() { return "BlueFish" }
}

::RedFish <- class extends Enemy {
	timer = 0
	frame = 0.0
	biting = false
	flip = 0
	touchDamage = 2.0

	constructor(_x, _y, _arr = null) {
		base.constructor(_x, _y)
		shape = Rec(x, y, 8, 6, 0)
		hspeed = 0.5
	}

	function physics() {}
	function animation() {}
	function routine() {}

	function run() {
		base.run()

		if(active) {
			if(!placeFree(x + (hspeed * 2), y)) hspeed = -hspeed
			if(!placeFree(x, y + (vspeed * 2))) vspeed = -vspeed
			flip = (hspeed < 0).tointeger()

			timer--
			if(timer <= 0) {
				timer = 240
				vspeed = -0.5 + randFloat(1)
				if(hspeed == 0) hspeed = 1
				else hspeed *= 1 / fabs(hspeed)
			}
			if(!inWater(x, y)) vspeed += 0.1
			vspeed *= 0.99

			if(gvPlayer) {
				if(hitTest(shape, gvPlayer.shape)) biting = true
				if(inDistance2(x, y, gvPlayer.x, gvPlayer.y, 128) && inWater(x, y)) {
					biting = true
					timer = 240

					//Chase player
					if(x < gvPlayer.x && hspeed < 2) hspeed += 0.02
					if(x > gvPlayer.x && hspeed > -2) hspeed -= 0.02

					if(y < gvPlayer.y && vspeed < 2) vspeed += 0.02
					if(y > gvPlayer.y && vspeed > -2) vspeed -= 0.02

					//Swim harder if far from the player
					if(inDistance2(x, y, gvPlayer.x, gvPlayer.y, 32)) {
						if(x < gvPlayer.x && hspeed < 2) hspeed += 0.02
						if(x > gvPlayer.x && hspeed > -2) hspeed -= 0.02

						if(y < gvPlayer.y && vspeed < 2) vspeed += 0.02
						if(y > gvPlayer.y && vspeed > -2) vspeed -= 0.02
					}
				}
			}


			if(frame >= 4) {
				biting = false
				frame = 0.0
			}

			if(biting) {
				drawSpriteEx(sprRedFish, 4 + frame, x - camx, y - camy, 0, flip, 1, 1, 1)
				frame += 0.125
			}
			else drawSpriteEx(sprRedFish, wrap(getFrames() / 16, 0, 3), x - camx, y - camy, 0, flip, 1, 1, 1)

			if(y > gvMap.h) {
				if(vspeed > 0) vspeed = 0
				vspeed -= 0.1
			}

			if(x > gvMap.w) hspeed = -1.0
			if(x < 0) hspeed = 1.0

			if(placeFree(x + hspeed, y)) x += hspeed
			if(placeFree(x, y + vspeed)) y += vspeed
			shape.setPos(x, y)
		}
	}

	function getHurt(_mag = 1, _element = "normal", _cut = false, _blast = false) {
		if(gvPlayer.rawin("anSlide")) if(gvPlayer.anim == gvPlayer.anSlide && game.weapon == 4) hurtFire()
		if(_element == "fire") hurtFire()
	}

	function hurtFire() {
		local c = newActor(DeadNME, x, y)
		actor[c].sprite = sprDeadFish
		actor[c].vspeed = -0.5
		actor[c].flip = flip
		actor[c].hspeed = hspeed
		if(flip == 1) actor[c].spin = -1
		else actor[c].spin = 1
		actor[c].gravity = 0.02
		deleteActor(id)
		playSound(sndKick, 0)
		game.enemies--
		newActor(Poof, x + 8, y)
		newActor(Poof, x - 8, y)
		if(randInt(20) == 0) {
			local a = actor[newActor(MuffinBlue, x, y)]
			a.vspeed = -2
		}
	}

	function _typeof() { return "RedFish" }
}

::JellyFish <- class extends Enemy {
	timer = 0
	frame = 0.0
	pump = false
	fliph = 0
	flipv = 0
	touchDamage = 2.0
	element = "shock"

	constructor(_x, _y, _arr = null) {
		base.constructor(_x, _y)
		shape = Rec(x, y, 4, 4, 0)
		hspeed = 0.5
	}

	function physics() {}
	function animation() {}
	function routine() {}

	function run() {
		base.run()

		if(active) {
			if(!placeFree(x + hspeed, y)) hspeed = -hspeed
			if(!placeFree(x, y + vspeed)) vspeed = -vspeed

			if(hspeed > 0) fliph = 0
			if(hspeed < 0) fliph = 1
			if(vspeed > 0) flipv = 1
			if(vspeed < 0) flipv = 0
			if(hspeed )

			timer--
			if(timer <= 0) {
				timer = 30 + randInt(90)
				pump = true
			}

			if(pump) {
				if(frame < 3) frame += 0.1
				else frame += 0.05

				if(frame >= 4) {
					frame = 0.0
					pump = false
				}

				if(frame > 2 && frame < 3) {
					if(fliph == 0) hspeed = 1.0
					else hspeed = -1.0
					if(flipv == 0) vspeed = -1.0
					else vspeed = 1.0
				}
			}

			if(y > gvMap.h) {
				if(vspeed > 0) vspeed = 0
				vspeed -= 0.1
			}

			if(x > gvMap.w) hspeed = -1.0
			if(x < 0) hspeed = 1.0

			if(!inWater(x, y)) vspeed += 0.1
			vspeed *= 0.99
			hspeed *= 0.99

			drawSpriteEx(sprJellyFish, frame, x - camx, y - camy, 0, fliph + (flipv * 2), 1, 1, 1)
			drawLightEx(sprLightIce, 0, x - camx, y - camy, 0, 0, 0.25, 0.25)

			if(placeFree(x + hspeed, y)) x += hspeed
			if(placeFree(x, y + vspeed)) y += vspeed
			shape.setPos(x, y)
		}
	}

	function getHurt(_mag = 1, _element = "normal", _cut = false, _blast = false) {
		if(gvPlayer.rawin("anSlide")) if(gvPlayer.anim == gvPlayer.anSlide && game.weapon == 4) hurtFire()
		if(_element == "fire") hurtFire()
	}

	function hurtFire() {
		if(randInt(20) == 0) {
			local a = actor[newActor(MuffinBlue, x, y)]
			a.vspeed = -2
		}
		local c = newActor(DeadNME, x, y)
		actor[c].sprite = sprJellyFish
		actor[c].vspeed = -0.2
		actor[c].flip = fliph + (flipv * 2)
		actor[c].hspeed = hspeed / 2
		if(fliph == 1) actor[c].spin = -1
		else actor[c].spin = 1
		actor[c].gravity = 0.01
		deleteActor(id)
		playSound(sndKick, 0)
		game.enemies--
		newActor(Poof, x, y)
	}

	function _typeof() { return "BlueFish" }
}

::Clamor <- class extends Enemy {
	huntdir = 0
	timer = 0
	flip = 0

	constructor(_x, _y, _arr = null) {
		base.constructor(_x, _y)

		shape = Rec(x, y, 6, 6, 0)
		if(_arr == "1") flip = 1

		if(flip == 0) huntdir = 1
		else huntdir = -1
	}

	function physics() {}
	function animation() {}
	function routine() {}

	function run() {
		base.run()

		if(gvPlayer) {
			if(inDistance2(x + (huntdir * 48), y - 32, gvPlayer.x, gvPlayer.y, 64) && timer == 0) {
				timer = 240
				newActor(ClamorPearl, x, y, null)
			}
		}

		if(timer > 0) timer--

		drawSpriteEx(sprClamor, (timer < 30).tointeger(), x - camx, y - camy, 0, flip, 1, 1, 1)
	}

	function getHurt(_mag = 1, _element = "normal", _cut = false, _blast = false) {
		if(gvPlayer.rawin("anSlide")) if(gvPlayer.anim == gvPlayer.anSlide && game.weapon == 4) hurtFire()
		if(_element == "fire") hurtFire()
	}

	function hurtFire() {
		if(timer < 30) {
			if(randInt(20) == 0) {
				local a = actor[newActor(MuffinBlue, x, y)]
				a.vspeed = -2
			}
			newActor(Poof, x, y - 1)
			deleteActor(id)
			playSound(sndFlame, 0)

		}
	}

	function hurtBlast() {
		newActor(Poof, x, y - 1)
		deleteActor(id)
	}

	function _typeof() { return "Clamor" }
}

::ClamorPearl <- class extends PhysAct {
	hspeed = 0
	vspeed = 0
	timer = 1200
	shape = null

	constructor(_x, _y, _arr = null) {
		base.constructor(_x, _y)

		if(!gvPlayer) {
			deleteActor(id)
			return
		}

		local aim = pointAngle(x, y, gvPlayer.x, gvPlayer.y)
		hspeed = lendirX(1, aim)
		vspeed = lendirY(1, aim)

		shape = Rec(x, y, 4, 4, 0)
	}

	function run() {
		x += hspeed
		y += vspeed
		shape.setPos(x, y)
		timer--

		if(timer == 0 || !placeFree(x, y)) deleteActor(id)

		if(gvPlayer) if(hitTest(shape, gvPlayer.shape)) gvPlayer.hurt = 2

		drawSprite(sprIceball, 0, x - camx, y - camy)
		if(!inWater(x, y)) vspeed += 0.2
	}
}

::GreenFish <- class extends Enemy {
	timer = 120
	frame = 0.0
	biting = false
	flip = 0
	canjump = false
	touchDamage = 2.0

	constructor(_x, _y, _arr = null) {
		base.constructor(_x, _y)
		shape = Rec(x, y, 8, 6, 0)
		hspeed = 1.0
		if(gvPlayer) if(x > gvPlayer.x) hspeed = -1.0
	}

	function physics() {}
	function animation() {}
	function routine() {}

	function run() {
		base.run()

		if(active) {
			flip = (hspeed < 0).tointeger()

			timer--
			if(timer <= 0) {
				timer = 120
				if(vspeed > -0.5 && inWater(x, y)) vspeed = -0.5
				if(hspeed == 0) hspeed = 1
				else hspeed *= 1 / fabs(hspeed)
				canjump = true
			}
			if(!inWater(x, y)) vspeed += 0.1
			vspeed *= 0.99

			if(gvPlayer) {
				if(hitTest(shape, gvPlayer.shape)) biting = true
				if(inDistance2(x, y, gvPlayer.x, gvPlayer.y, 256) && inWater(x, y)) {
					biting = true

					//Chase player
					if(x < gvPlayer.x && hspeed < 2) hspeed += 0.02
					if(x > gvPlayer.x && hspeed > -2) hspeed -= 0.02

					if(y < gvPlayer.y && vspeed < 2) vspeed += 0.1
					if(y > gvPlayer.y && vspeed > -4) {
						if(canjump && !gvPlayer.inWater(gvPlayer.x, gvPlayer.y) && ((hspeed > 0 && gvPlayer.x > x) || (hspeed < 0 && gvPlayer.x < x))) {
							vspeed = -6
							canjump = false
						}

						vspeed -= 0.2
					}

					//Swim harder if far from the player
					if(!inDistance2(x, y, gvPlayer.x, gvPlayer.y, 64)) {
						if(x < gvPlayer.x && hspeed < 2) hspeed += 0.02
						if(x > gvPlayer.x && hspeed > -2) hspeed -= 0.02

						if(y < gvPlayer.y && vspeed < 2) vspeed += 0.02
						if(y > gvPlayer.y && vspeed > -2) vspeed -= 0.02
					}
				}
			}


			if(frame >= 4) {
				biting = false
				frame = 0.0
			}

			if(biting) {
				drawSpriteEx(sprGreenFish, 4 + frame, x - camx, y - camy, 0, flip, 1, 1, 1)
				frame += 0.125
			}
			else drawSpriteEx(sprGreenFish, wrap(getFrames() / 16, 0, 3), x - camx, y - camy, 0, flip, 1, 1, 1)

			if(y > gvMap.h) {
				if(vspeed > 0) vspeed = 0
				vspeed -= 0.1
			}

			if(x > gvMap.w) hspeed = -1.0
			if(x < 0) hspeed = 1.0


			x += hspeed
			y += vspeed

			shape.setPos(x, y)
		}
	}

	function getHurt(_mag = 1, _element = "normal", _cut = false, _blast = false) {
		if(gvPlayer.rawin("anSlide")) if(gvPlayer.anim == gvPlayer.anSlide && game.weapon == 4) hurtFire()
		if(_element == "fire") hurtFire()
	}

	function hurtFire() {
		local c = newActor(DeadNME, x, y)
		actor[c].sprite = sprDeadFish
		actor[c].vspeed = -0.5
		actor[c].flip = flip
		actor[c].hspeed = hspeed
		if(flip == 1) actor[c].spin = -1
		else actor[c].spin = 1
		actor[c].gravity = 0.02
		deleteActor(id)
		playSound(sndKick, 0)
		game.enemies--
		newActor(Poof, x + 8, y)
		newActor(Poof, x - 8, y)
		if(randInt(20) == 0) {
			local a = actor[newActor(MuffinBlue, x, y)]
			a.vspeed = -2
		}
	}

	function _typeof() { return "GreenFish" }
}

::Ouchin <- class extends Enemy {
	sf = 0.0
	thorny = true

	constructor(_x, _y, _arr = null) {
		base.constructor(_x, _y)
		shape = Rec(x, y, 8, 8, 0)
		sf = randInt(8)
	}

	function run() {
		base.run()

		drawSprite(sprOuchin, sf + (getFrames() / 16), x - camx, y - camy)

		if(gvPlayer) if(hitTest(shape, gvPlayer.shape)) {
			if(x > gvPlayer.x) {
				if(gvPlayer.placeFree(gvPlayer.x - 1, gvPlayer.y)) gvPlayer.x--
				gvPlayer.hspeed -= 0.1
			}

			if(x < gvPlayer.x) {
				if(gvPlayer.placeFree(gvPlayer.x + 1, gvPlayer.y)) gvPlayer.x++
				gvPlayer.hspeed += 0.1
			}

			if(y > gvPlayer.y) {
				if(gvPlayer.placeFree(gvPlayer.x, gvPlayer.y - 1)) gvPlayer.y--
				gvPlayer.vspeed -= 0.1
			}

			if(y < gvPlayer.y) {
				if(gvPlayer.placeFree(gvPlayer.x, gvPlayer.y + 1)) gvPlayer.y++
				gvPlayer.vspeed += 0.1
			}
		}

		if(frozen) {
			//Create ice block
			if(gvPlayer) if(icebox == -1 && !hitTest(shape, gvPlayer.shape)) {
				icebox = mapNewSolid(shape)
			}

			if(frozen <= 120) {
				if(floor(frozen / 4) % 2 == 0) drawSprite(sprIceTrapSmall, 0, x - camx - 1 + ((floor(frozen / 4) % 4 == 0).tointeger() * 2), y - camy - 1)
				else drawSprite(sprIceTrapSmall, 0, x - camx, y - camy - 1)
			}
			else drawSprite(sprIceTrapSmall, 0, x - camx, y - camy - 1)
		}
		else {
			if(icebox != -1) {
				mapDeleteSolid(icebox)
				newActor(IceChunks, x, y)
				icebox = -1
			}
		}
	}

	function hurtPlayer() {
		base.hurtPlayer()
		if(gvPlayer) gvPlayer.hurt = 2
	}

	function getHurt(_mag = 1, _element = "normal", _cut = false, _blast = false) {
		if(_element == "fire") hurtFire()
		if(_element == "ice") hurtIce()
	}

	function hurtFire() {}

	function hurtIce() { frozen = 600 }
}

::BadCannon <- class extends Actor {
	frame = 3.5
	timer = 240

	constructor(_x, _y, _arr = null) {
		base.constructor(_x, _y)
		mapNewSolid(Rec(x, y, 8, 8, 0))
	}

	function run() {
		base.run()

		if(gvPlayer) {
			if(x > gvPlayer.x + 8 && frame > 0.5) frame -= 0.1
			if(x < gvPlayer.x - 8 && frame < 4.5) frame += 0.1

			if(inDistance2(x, y, gvPlayer.x, gvPlayer.y, 160) && timer == 0 && (frame < 1 || frame > 4)) {
				if(frame < 1) {
					local c = actor[newActor(CannonBob, x - 4, y - 4)]
					c.hspeed = ((gvPlayer.x - x) / 48)
					local d = (y - gvPlayer.y) / 64
					if(d > 2) d = 2
					if(y > gvPlayer.y) c.vspeed -= d
					newActor(Poof, x - 4, y - 4)
				}
				if(frame >= 4) {
					local c = actor[newActor(CannonBob, x + 4, y - 4)]
					c.hspeed = ((gvPlayer.x - x) / 48)
					local d = (y - gvPlayer.y) / 64
					if(d > 2) d = 2
					if(y > gvPlayer.y) c.vspeed -= d
					newActor(Poof, x + 4, y - 4)
				}
				if(frame >= 1 && frame <= 4) {
					local c = actor[newActor(CannonBob, x, y - 4)]
					c.hspeed = ((gvPlayer.x - x) / 48)
					local d = (y - gvPlayer.y) / 64
					if(d > 2) d = 2
					if(y > gvPlayer.y) c.vspeed -= d
					newActor(Poof, x, y - 4)
				}
				timer = 240
			}

			if(timer > 0) timer--
		}

		drawSprite(sprCannon, frame, x - camx, y - camy)
	}

	function _typeof() { return "BadCannon" }
}

::CannonBob <- class extends Enemy {
	vspeed = -4
	sprite = 0
	touchDamage = 2.0

	constructor(_x, _y, _arr = null) {
		base.constructor(_x, _y)
		shape = Rec(x, y, 6, 6, 0)

		if(_arr == null) sprite = sprCannonBob
		else sprite = _arr
	}

	function physics() {}
	function animation() {}
	function routine() {}

	function run() {
		base.run()

		if(!frozen) {
			if(hspeed < 0) drawSpriteEx(sprite, getFrames() / 4, x - camx, y - camy, 0, 0, 1, 1, 1)
			else drawSpriteEx(sprite, getFrames() / 4, x - camx, y - camy, 0, 1, 1, 1, 1)

			vspeed += 0.2
			x += hspeed
			y += vspeed
			shape.setPos(x, y)

			if(y > gvMap.h) deleteActor(id)

			if(icebox != -1) {
				mapDeleteSolid(icebox)
				newActor(IceChunks, x, y)
				icebox = -1
				hspeed = 0
				vspeed = -1.0
			}
		}
		else {
			if(hspeed < 0) drawSpriteEx(sprite, 4, x - camx, y - camy, 0, 1, 1, 1, 1)
			else drawSpriteEx(sprite, 4, x - camx, y - camy, 0, 0, 1, 1, 1)

			//Create ice block
			if(gvPlayer) if(icebox == -1 && !hitTest(shape, gvPlayer.shape)) {
				icebox = mapNewSolid(shape)
			}

			if(frozen <= 120) {
				if(floor(frozen / 4) % 2 == 0) drawSprite(sprIceTrapSmall, 0, x - camx - 1 + ((floor(frozen / 4) % 4 == 0).tointeger() * 2), y - camy - 1)
				else drawSprite(sprIceTrapSmall, 0, x - camx, y - camy - 1)
			}
			else drawSprite(sprIceTrapSmall, 0, x - camx, y - camy - 1)
		}
	}

	function getHurt(_mag = 1, _element = "normal", _cut = false, _blast = false) {
		if(_blast || _element == "fire") {
			hurtBlast()
			return
		}
		else if(_element == "ice") {
			hurtIce()
			return
		}
		local c = newActor(DeadNME, x, y)
		actor[c].sprite = sprite
		actor[c].vspeed = -abs(gvPlayer.hspeed * 1.1)
		actor[c].hspeed = (gvPlayer.hspeed / 16)
		deleteActor(id)
		playSound(sndKick, 0)
		if(getcon("jump", "hold")) gvPlayer.vspeed = -5
		else {
			gvPlayer.vspeed = -2
			playSound(sndSquish, 0)
		}
		if(gvPlayer.anim == gvPlayer.anJumpT || gvPlayer.anim == gvPlayer.anFall) {
			gvPlayer.anim = gvPlayer.anJumpU
			gvPlayer.frame = gvPlayer.anJumpU[0]
		}
		if(icebox != -1) {
			mapDeleteSolid(icebox)
			newActor(IceChunks, x, y)
		}
	}

	function hurtBlast() {
		local c = newActor(DeadNME, x, y)
		actor[c].sprite = sprite
		actor[c].vspeed = -abs(gvPlayer.hspeed * 1.1)
		actor[c].hspeed = (gvPlayer.hspeed / 16)
		deleteActor(id)
		playSound(sndKick, 0)
		if(icebox != -1) {
			mapDeleteSolid(icebox)
			newActor(IceChunks, x, y)
		}

	}

	function hurtIce() { frozen = 600 }

	function _typeof() { return "CannonBob" }
}

::Icicle <- class extends Enemy {
	timer = 30
	counting = false
	touchDamage = 2.0

	constructor(_x, _y, _arr = null) {
		base.constructor(_x, _y)
		shape = Rec(x, y, 4, 6, 0)
	}

	function physics() {}
	function animation() {}
	function routine() {}

	function run() {
		base.run()

		if(gvPlayer) if(abs(y - gvPlayer.y) < 128 && y < gvPlayer.y && abs(x - gvPlayer.x) < 8 && !counting) {
			counting = true
			playSound(sndIcicle, 0)
		}

		if(counting && timer > 0) timer--
		if(timer <= 0) {
			if(inWater(x, y) && vspeed < 1.0) vspeed += 0.05
			else vspeed += 0.2
		}
		if(inWater(x, y) && vspeed > 0.5) vspeed = 0.1
		y += vspeed
		shape.setPos(x, y)

		if(!placeFree(x, y)) {
			deleteActor(id)
			newActor(IceChunks, x, y)
		}

		drawSprite(sprIcicle, 0, x + (timer % 2) - camx, y - 8 - camy)
		if(vspeed > 0) fireWeapon(AfterIce, x, y, 0, id)
	}

	function hurtFire() {
		deleteActor(id)
		newActor(Poof, x, y)
	}

	function getHurt(_mag = 1, _element = "normal", _cut = false, _blast = false) {
		if(_element == "fire") {
			hurtFire()
			return
		}
		else if(_element != "ice") {
			base.getHurt()
			newActor(IceChunks, x, y)
		}
	}
}

::FlyAmanita <- class extends Enemy {
	range = 0
	dir = 0.5
	flip = 0

	constructor(_x, _y, _arr = 0) {
		base.constructor(_x, _y)
		if(_arr == "") range = 0
		else if(typeof _arr == "array") range = _arr[0].tointeger()
		else range = _arr.tointeger() * 16
		shape = Rec(x, y, 6, 6, 0)
	}

	function physics() {}
	function animation() {}
	function routine() {}

	function run() {
		base.run()
		if(gvPlayer) gvPlayer.x < x ? flip = 1 : flip = 0

		if(inDistance2(x, y, x, ystart, 16)) vspeed = ((1.0 / 8.0) * distance2(x, y, x, ystart)) * dir
		else if(inDistance2(x, y, x, ystart + range, 16)) vspeed = ((1.0 / 8.0) * distance2(x, y, x, ystart + range)) * dir
		else vspeed = dir * 2.0

		vspeed += dir * 0.2
		if(range == 0) vspeed = 0

		//Change direction
		if(range > 0) {
			if(y > ystart + range) dir = -0.5
			if(y < ystart) dir = 0.5
		}

		if(range < 0) {
			if(y > ystart) dir = -0.5
			if(y < ystart + range) dir = 0.5
		}

		if(!frozen) {
			//Delete ice block
			if(icebox != -1) {
				mapDeleteSolid(icebox)
				newActor(IceChunks, x, y)
				icebox = -1
			}

			y += vspeed
			drawSpriteEx(sprFlyAmanita, getFrames() / 4, x - camx, y - camy, 0, flip, 1, 1, 1)
		} else {
			//Create ice block
			if(gvPlayer) if(icebox == -1 && !hitTest(shape, gvPlayer.shape)) {
				icebox = mapNewSolid(shape)
			}

			drawSpriteEx(sprFlyAmanita, 0, x - camx, y - camy, 0, flip, 1, 1, 1)
			if(frozen <= 120) {
				if(floor(frozen / 4) % 2 == 0) drawSprite(sprIceTrapSmall, 0, x - camx - 1 + ((floor(frozen / 4) % 4 == 0).tointeger() * 2), y - camy - 1)
				else drawSprite(sprIceTrapSmall, 0, x - camx, y - camy - 1)
			}
			else drawSprite(sprIceTrapSmall, 0, x - camx, y - camy - 1)
		}

		shape.setPos(x, y)
	}

	function hurtPlayer() {
		base.hurtPlayer()
	}

	function getHurt(_mag = 1, _element = "normal", _cut = false, _blast = false) {
		if(_element == "fire") {
			hurtFire()
			return
		}
		else if(_element == "ice") {
			hurtIce()
			return
		}

		if(icebox != -1) {
			mapDeleteSolid(icebox)
			newActor(IceChunks, x, y)
		}

		local c = newActor(DeadNME, x, y)
		actor[c].sprite = sprFlyAmanita
		actor[c].vspeed = -abs(gvPlayer.hspeed * 1.1)
		actor[c].hspeed = (gvPlayer.hspeed / 16)
		actor[c].spin = (gvPlayer.hspeed * 6)
		actor[c].angle = 180
		deleteActor(id)
		stopSound(sndKick)
		playSound(sndKick, 0)

		if(getcon("jump", "hold")) {
			gvPlayer.vspeed = -8
			stopSound(sndSquish)
			playSound(sndSquish, 0)
		}
		else {
			gvPlayer.vspeed = -4
			stopSound(sndSquish)
			playSound(sndSquish, 0)
		}

		if(gvPlayer.anim == gvPlayer.anJumpT || gvPlayer.anim == gvPlayer.anFall) {
			gvPlayer.anim = gvPlayer.anJumpU
			gvPlayer.frame = gvPlayer.anJumpU[0]
		}

		else if(keyDown(config.key.jump)) gvPlayer.vspeed = -5
		else gvPlayer.vspeed = -2
		if(gvPlayer.anim == gvPlayer.anJumpT || gvPlayer.anim == gvPlayer.anFall) {
			gvPlayer.anim = gvPlayer.anJumpU
			gvPlayer.frame = gvPlayer.anJumpU[0]
		}
	}

	hurtFire = Deathcap.hurtFire

	function hurtIce() { frozen = 600 }
}

::Jumpy <- class extends Enemy {
	frame = 0.0
	flip = false
	squish = false
	squishTime = 0.0
	smart = false
	jump = -4.0
	touchDamage = 3.0
	thorny = true

	constructor(_x, _y, _arr = null) {
		base.constructor(_x.tofloat(), _y.tofloat())
		shape = Rec(x, y, 6, 6, 0, 0, 2)

		if(_arr != null && _arr != "") jump = abs(_arr.tofloat()) * -1.0
	}

	function physics() {}
	function animation() {}
	function routine() {}

	function run() {
		base.run()

		if(active) {
			if(gvPlayer) {
				if(x > gvPlayer.x) flip = 1
				else flip = 0
			}

			if(!placeFree(x, y + 1)) vspeed = jump
			if(!placeFree(x + 0, y - 2) && !placeFree(x + 2, y)) hspeed = 0
			if(!placeFree(x - 0, y - 2) && !placeFree(x - 2, y)) hspeed = 0
			vspeed += 0.15

			if(!frozen) {
				if(placeFree(x + hspeed, y)) x += hspeed
				if(placeFree(x, y + vspeed)) y += vspeed
				else vspeed /= 2
			}

			shape.setPos(x, y)

			//Draw
			drawSpriteEx(sprJumpy, getFrames() / 8, floor(x - camx), floor(y - camy), 0, flip.tointeger(), 1, 1, 1)

			if(frozen) {
				//Create ice block
				if(gvPlayer) if(icebox == -1 && !hitTest(shape, gvPlayer.shape)) {
					icebox = mapNewSolid(shape)
				}

				//Draw
				drawSpriteEx(sprJumpy, 0, floor(x - camx), floor(y - camy), 0, flip.tointeger(), 1, 1, 1)

				if(frozen <= 120) {
				if(floor(frozen / 4) % 2 == 0) drawSprite(sprIceTrapSmall, 0, x - camx - 1 + ((floor(frozen / 4) % 4 == 0).tointeger() * 2), y - camy - 1)
					else drawSprite(sprIceTrapSmall, 0, x - camx, y - camy - 1)
				}
				else drawSprite(sprIceTrapSmall, 0, x - camx, y - camy - 1)
			}
			else {
				//Delete ice block
				if(icebox != -1) {
					mapDeleteSolid(icebox)
					newActor(IceChunks, x, y)
					icebox = -1
					if(gvPlayer) if(x > gvPlayer.x) flip = true
					else flip = false
				}
			}
		}

		if(x < 0) hspeed = 0.0
		if(x > gvMap.w) hspeed = -0.0
	}

	function getHurt(_mag = 1, _element = "normal", _cut = false, _blast = false) {
		if(_element == "fire") {
			hurtFire()
			return
		}
		else if(_element == "ice") {
			hurtIce()
			return
		}
		else base.getHurt(_mag, _element, _cut, _blast)
	}

	function hurtBlast() {
		if(icebox != -1) {
			mapDeleteSolid(icebox)
			newActor(IceChunks, x, y)
		}
		newActor(Poof, x, y - 1)
		deleteActor(id)
		playSound(sndFlame, 0)
	}

	function hurtFire() {
		newActor(Flame, x, y - 1)
		deleteActor(id)
		playSound(sndFlame, 0)
	}

	function hurtIce() { frozen = 600 }

	function die() {
		stopSound(sndKick)
		playSound(sndKick, 0)
		newActor(Poof, x, y)
	}
}

::Haywire <- class extends Enemy {
	burnt = false
	frame = 0.0
	flip = false
	squish = false
	squishTime = 0.0
	chasing = false
	mspeed = 1.0
	hspeed = 0.0
	touchDamage = 2.0

	constructor(_x, _y, _arr = null) {
		base.constructor(_x.tofloat(), _y.tofloat())
		shape = Rec(x, y, 6, 6, 0, 0, 1)
		if(gvPlayer) if(x > gvPlayer.x) flip = true
	}

	function physics() {}
	function animation() {}
	function routine() {}

	function run() {
		base.run()

		if(active) {
			if(placeFree(x, y + 1)) vspeed += 0.2
			if(placeFree(x, y + vspeed)) y += vspeed
			else vspeed /= 2
			if(!squish || chasing) {

				if(chasing) mspeed = fabs(hspeed)
				else mspeed = 0.75

				if(chasing) squishTime++
				if(squishTime >= 200 && chasing) {
					deleteActor(id)
					fireWeapon(ExplodeF, x, y - 1, 0, id)

				}

				if(y > gvMap.h + 8) deleteActor(id)

				if(!frozen) {
					if(flip) {
						if(placeFree(x - mspeed, y)) x -= mspeed
						else if(placeFree(x - (mspeed * 2), y - (mspeed * 2))) {
							x -= mspeed
							y -= 1.0
						} else if(placeFree(x - mspeed, y - (mspeed * 2))) {
							x -= mspeed
							y -= 1.0
						} else flip = false

						if(placeFree(x - 6, y + 14) && !placeFree(x, y + 2)) {
							if(!chasing) flip = false
							else vspeed = -4
						}

						if(x <= 0) flip = false
						if(hspeed > 0) flip = false
					}
					else {
						if(placeFree(x + mspeed, y)) x += mspeed
						else if(placeFree(x + mspeed, y - mspeed)) {
							x += mspeed
							y -= 1.0
						} else if(placeFree(x + (mspeed * 2), y - (mspeed * 2))) {
							x += mspeed
							y -= 1.0
						} else flip = true

						if(placeFree(x + 6, y + 14) && !placeFree(x, y + 2)) {
							if(!chasing) flip = true
							else vspeed = -4
						}

						if(x >= gvMap.w) flip = true
						if(hspeed < 0) flip = true
					}

					if(gvPlayer) if(inDistance2(x, y, gvPlayer.x, gvPlayer.y, 64 + (16 * game.difficulty))) squish = true
				}

				if(gvPlayer && chasing) {
					if(x < gvPlayer.x - 8) if(hspeed < (2.5 + ((2.0 / 200.0) * squishTime))) {
						hspeed += 0.1
						if(hspeed < 0) hspeed += 0.1
					}
					if(x > gvPlayer.x + 8) if(hspeed > -(2.5 + ((2.0 / 200.0) * squishTime))) {
						hspeed -= 0.1
						if(hspeed > 0) hspeed -= 0.1
					}

					if(!placeFree(x, y + 1) && y > gvPlayer.y + 16) vspeed = -5.0
				}

				if(frozen) {
					//Create ice block
					if(gvPlayer) if(icebox == -1 && !hitTest(shape, gvPlayer.shape)) {
						icebox = mapNewSolid(shape)
					}

					//Draw
					drawSpriteEx(sprHaywire, 0, floor(x - camx), floor(y - camy), 0, flip.tointeger(), 1, 1, 1)

					if(frozen <= 120) {
					if(floor(frozen / 4) % 2 == 0) drawSprite(sprIceTrapSmall, 0, x - camx - 1 + ((floor(frozen / 4) % 4 == 0).tointeger() * 2), y - camy - 1)
						else drawSprite(sprIceTrapSmall, 0, x - camx, y - camy - 1)
					}
					else drawSprite(sprIceTrapSmall, 0, x - camx, y - camy - 1)
					chasing = false
					squishTime = 0.0
				}
				else {
					//Delete ice block
					if(icebox != -1) {
						mapDeleteSolid(icebox)
						newActor(IceChunks, x, y)
						icebox = -1
						if(gvPlayer) if(x > gvPlayer.x) flip = true
						else flip = false
					}

					//Draw
					if(chasing) {
						drawSpriteEx(sprHaywire, wrap(getFrames() / 6, 8, 11), x - camx, y - camy, 0, flip.tointeger(), 1, 1, 1)
						if(getFrames() % 8 == 0) {
							local c
							if(!flip) c = actor[newActor(FlameTiny, x - 6, y - 8)]
							else c = actor[newActor(FlameTiny, x + 6, y - 8)]
							c.vspeed = -0.1
							c.hspeed = randFloat(0.2) - 0.1
						}
					}
					else drawSpriteEx(sprHaywire, wrap(getFrames() / 10, 0, 3), floor(x - camx), floor(y - camy), 0, flip.tointeger(), 1, 1, 1)
				}
			}
			else {
				squishTime += 1.5
				if(chasing) frame += 0.25
				else frame += 0.075
				if(squishTime >= 90 && !chasing) {
					chasing = true
					squishTime = 0
					stopSound(sndFizz)
					playSound(sndFizz, 0)
				}
				if(squishTime >= 300 && chasing) {
					deleteActor(id)
					fireWeapon(ExplodeF, x, y, 0, id)

				}
				if(!chasing) drawSpriteEx(sprHaywire, wrap(frame, 4, 7), x - camx, y - camy, 0, flip.tointeger(), 1, 1, 1)
				else drawSpriteEx(sprHaywire, wrap(frame, 8, 11), x - camx, y - camy, 0, flip.tointeger(), 1, 1, 1)

				if(frozen) {
					squish = false
					squishTime = 0
					chasing = false
				}
			}

			shape.setPos(x, y)
			setDrawColor(0xff0000ff)
			if(debug) shape.draw()
		}
	}

	function hurtPlayer() {
		if(squish && !chasing) return
		base.hurtPlayer()
	}

	function hurtBlast() {
		if(squish) return
		if(frozen) frozen = 0
		if(icebox != -1) {
			mapDeleteSolid(icebox)
			newActor(IceChunks, x, y)
			frozen = 0
			icebox = -1
		}
		squish = true
	}

	function getHurt(_mag = 1, _element = "normal", _cut = false, _blast = false) {
		if(_element == "fire") {
			hurtFire()
			return
		}
		else if(_element == "ice") {
			hurtIce()
			return
		}
		else if(_blast) {
			hurtBlast()
			return
		}
		if(frozen > 0) return
		if(chasing) {
			hurtPlayer()
			return
		}
		if(squish) return

		if(getcon("jump", "hold")) gvPlayer.vspeed = -8
		else gvPlayer.vspeed = -4
		if(gvPlayer.anim == gvPlayer.anJumpT || gvPlayer.anim == gvPlayer.anFall) {
			gvPlayer.anim = gvPlayer.anJumpU
			gvPlayer.frame = gvPlayer.anJumpU[0]
		}
		playSound(sndKick, 0)

		squish = true
	}

	function hurtFire() {
		if(icebox != -1) {
			mapDeleteSolid(icebox)
			newActor(IceChunks, x, y)
		}
		if(!burnt) {
			fireWeapon(ExplodeF, x, y - 1, 0, id)
			deleteActor(id)
			playSound(sndFlame, 0)

			burnt = true
		}
	}

	function hurtIce() { frozen = 600 }

	function _typeof() { return "Haywire" }
}

::Sawblade <- class extends PathCrawler {
	constructor(_x, _y, _arr = null) {
		base.constructor(_x, _y, _arr)
		shape = Rec(x, y, 6, 6, 0)
	}

	function run() {
		base.run()
		drawSprite(sprSawblade, getFrames() / 2, x - camx, y - camy)
		drawLightEx(sprLightIce, 0, x - camx, y - camy, 0, 0, 0.125, 0.125)
		//drawText(font, x - camx + 16, y - camy, dir.tostring())
		shape.setPos(x, y)
		if(gvPlayer) if(hitTest(shape, gvPlayer.shape)) gvPlayer.getHurt(2, "normal", true, false)
	}
}








////////////////////
// V0.2.0 ENEMIES //
////////////////////

::Owl <- class extends Enemy {
	passenger = null
	pyOffset = 0
	pid = 0
	touchDamage = 2.0
	health = 4.0
	flip = 0
	canMoveH = true
	canMoveV = true
	freezeSprite = sprIceTrapLarge
	nocount = true
	blinkMax = 2

	damageMult = {
		normal = 1.0
		fire = 2.0
		ice = 1.0
		earth = 1.0
		air = 1.0
		toxic = 1.0
		shock = 1.0
		water = 1.0
		light = 1.0
		dark = 1.0
		cut = 1.0
		blast = 1.0
	}

	constructor(_x, _y, _arr = null){
		base.constructor(_x, _y)
		hspeed = 0.5

		if(getroottable().rawin(_arr)) {
			if(getroottable()[_arr].rawin("shape")) passenger = actor[newActor(getroottable()[_arr], x, y)]
			else passenger = actor[newActor(MuffinEvil, x, y)]
		}
		else passenger = actor[newActor(MuffinEvil, x, y)]

		pyOffset = passenger.shape.h
		pid = passenger.id

		shape = Rec(x, y, 8, 12, 0)
		routine = ruCarry
	}

	function run() {
		base.run()
		if(!active) if(checkActor(pid)) {
			passenger.x = x
			passenger.y = y + pyOffset + 12
			if(passenger.rawin("flip")) passenger.flip = flip
			passenger.vspeed = 0.0
		}
	}

	function physics() {
		local tempShape = shape
		canMoveH = !(frozen > 0)
		canMoveV = !(frozen > 0)

		//Check if owl can move
		if(!placeFree(x + hspeed, y)) canMoveH = false
		if(!placeFree(x, y + vspeed)) canMoveV = false

		if(checkActor(pid)) {
			shape = passenger.shape
			if(!placeFree(x + hspeed, y + 12 + pyOffset)) canMoveH = false
			if(!placeFree(x, y + 12 + pyOffset + vspeed)) canMoveV = false
			shape = tempShape
		}

		if(canMoveH) x += hspeed
		else hspeed = -hspeed

		if(canMoveV) y += vspeed / 2.0
		else vspeed = -vspeed / 2.0

		//Attach passenger to talons
		if(checkActor(pid)) {
			passenger.x = x
			passenger.y = y + pyOffset + 12
			if(passenger.rawin("flip")) passenger.flip = flip
			passenger.vspeed = 0.0
		}

		shape.setPos(x, y)
	}

	function animation() {
		if(frozen == 0) {
			if(hspeed > 0) flip = 0
			if(hspeed < 0) flip = 1
			if(gvPlayer && !placeFree(x, y)) {
				if(x < gvPlayer.x) flip = 0
				if(x > gvPlayer.x) flip = 1
			}

			drawSpriteExZ(1, sprOwlBrown, wrap(getFrames() / 6, 1, 4), x - camx, y - camy, 0, flip, 1, 1, 1)
		}
		else drawSpriteExZ(1, sprOwlBrown, 0, x - camx, y - camy, 0, flip, 1, 1, 1)
	}

	function ruCarry() {
		if(gvPlayer) {
			if(x > gvPlayer.x && hspeed > -3) hspeed -= 0.05
			if(x < gvPlayer.x && hspeed < 3) hspeed += 0.05
			if(y > gvPlayer.y - 64 && vspeed > -1) vspeed -= 0.05
			if(y < gvPlayer.y - 64 && vspeed < 1) vspeed += 0.05

			if(distance2(x, y, gvPlayer.x, gvPlayer.y) <= 96 && y < gvPlayer.y && abs(x - gvPlayer.x) < 8) pid = -1
		}

		if(!checkActor(pid)) routine = ruFlee
	}

	function ruFlee() {
		if(gvPlayer) {
			if(x < gvPlayer.x && hspeed > -3) hspeed -= 0.05
			if(x > gvPlayer.x && hspeed < 3) hspeed += 0.05
			if(y < gvPlayer.y && vspeed > -1) vspeed -= 0.05
			if(y > gvPlayer.y && vspeed < 1) vspeed += 0.05
		}
	}

	function die() {
		base.die()
		local c = newActor(DeadNME, x, y)
		actor[c].sprite = sprOwlBrown
		actor[c].vspeed = -5.0
		actor[c].spin = 30
		playSound(sndKick, 0)
	}
}