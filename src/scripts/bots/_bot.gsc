/******************************************************************************
    Reign of the Undead, v2.x

    Copyright (c) 2010-2013 Reign of the Undead Team.
    See AUTHORS.txt for a listing.

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to
    deal in the Software without restriction, including without limitation the
    rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
    sell copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.

    The contents of the end-game credits must be kept, and no modification of its
    appearance may have the effect of failing to give credit to the Reign of the
    Undead creators.

    Some assets in this mod are owned by Activision/Infinity Ward, so any use of
    Reign of the Undead must also comply with Activision/Infinity Ward's modtools
    EULA.
******************************************************************************/

#include scripts\include\utility;


/**
 * @brief Creates a bot
 *
 * @returns boolean Whether the bot was instantiated
 */
instantiate()
{
    debugPrint("in _bot::instantiate()", "fn", level.nonVerbose);

    bot = addTestClient();

    if (!isDefined(bot)) {
        warnPrint("Failed to instantiate a bot!");
        wait 0.5;
        return false;
    }

    return initialize(bot);
}

/**
 * @brief Initializes a bot so it can be used for zombies
 *
 * @param bot The bot to initialize
 *
 * @return boolean assumes the bot was properly initialized
 */
initialize(bot)
{
    debugPrint("in _bot::initialize()", "fn", level.nonVerbose);

    bot.isBot = true;
    bot.hasSpawned = false;
    bot.readyToBeKilled = false;
    bot.spawnPoint = undefined;

    // Wait until the bot is properly connected
    while(!isDefined(bot.pers["team"])) {wait .05;}

    bot.sessionteam = "axis";
    bot.pers["team"] = "axis";
    wait 0.1;

    bot setStat(512, 100); // Yes we are indeed a bot
    bot setrank(255, 0);

    // when we want to move the bot, we link it to this entity, then move the
    // entity, and the bot gets taken along for the ride.
    bot.mover = spawn("script_model", (0,0,0));
//     // [un]filled circular queue of movement orders, i.e. params for the moveTo() function
//     bot.movement = spawnStruct();
//     bot.movement.first = 0;
//     bot.movement.next = 0;
//     bot.movement.last = 0;
//     bot.movement.orders = [];
//     // we assume one order every 0.05s, for 0.2s until we reevaluate movement
//     for (i=0; i<5; i++) {
    //         order = spawnStruct();
//         order.origin = (0,0,0);
//         order.time = 0; //s
//         order.angles = (0,0,0);
//         bot.movement.orders[i] = order;
//     }
//     bot.isFollowingWapypoints = false;

    bot.index = level.bots.size;

    makeBotAvailable(bot);

    level.bots[bot.index] = bot;
    return true;
}

/**
 * @brief Reconnects a bot when the map is restarted without a server restart
 *
 * @returns nothing
 */
reconnect()
{
    debugPrint("in _bot::reconnect()", "fn", level.nonVerbose);

    initialize(self);
}

/**
 * @brief Removes bots from the game
 *
 * @param botsToRemove array Indices of bots to remove from the game
 *
 * @returns nothing
 */
remove(botsToRemove)
{
    debugPrint("in _bot::remove()", "fn", level.nonVerbose);

    // move the bots to be removed to the end of the array
    for (i=0; i<botsToRemove.size; i++) {
        if (botsToRemove[i] == level.bots.size - 1) {
            // bot is already the last element, just undefine it
            bot = level.bots[level.bots.size - 1];
            level.bots[level.bots.size - 1] = undefined;
            kick(bot getEntityNumber());  // cheating bots! :-) really a temp ban
            continue;
        } else {
            // copy last bot into botToBeRemoved's index, then undefine the last element
            level.bots[botsToRemove[i]] = level.bots[level.bots.size - 1];
            level.bots[botsToRemove[i]].index = botsToRemove[i]; // update the bot's index
            bot = level.bots[level.bots.size - 1];
            level.bots[level.bots.size - 1] = undefined;
            kick(bot getEntityNumber()); // cheating bots! :-)
        }
    }
    // now update availableBots to ensure their indices are correct
    for (i=0; i<level.availableBots.size; i++) {
        level.availableBots[i] = level.bots[level.availableBots[i]].index;
    }
}

/**
 * @brief Makes a bot available for use as a zombie
 *
 * @param bot struct The bot to make available for use
 *
 * @returns nothing
 */
makeBotAvailable(bot)
{
    debugPrint("in _bot::makeBotAvailable()", "fn", level.fullVerbosity);

    // push the bot's index onto the availableBots stack
    level.availableBots[level.availableBots.size] = bot.index;
}

/**
 * @brief Plays a sound on a bot, such as death and attack sounds
 *
 * @param delay float The time, in seconds, to wait before playing the sound
 * @param sound string The base name of the sound, xom_death, zom_attack, etc
 * @param random integer The integer to concatenate with \c sound to determine the sound to play
 *
 * @returns nothing
 */
playSoundOnBot(delay, sound, random)
{
    debugPrint("in _bot::playSoundOnBot()", "fn", level.fullVerbosity);

    if (delay > 0) {
        self endon("death");
        wait delay;
    }
    // concatenate sound name: zom_death1, zom_attack6, etc
    sound = sound + random;
    if (isAlive(self)) {self playSound(sound);}
}

/**
 * @brief Give rank and upgrade points to players that damaged a zombie but didn't kill it
 *
 * @param killer entity The player that finally killed the zombie
 *
 * @returns nothing
 */
giveAssists(killer)
{
    debugPrint("in _bot::giveAssists()", "fn", level.highVerbosity);

    for (i=0; i<self.damagedBy.size; i++) {
        struct = self.damagedBy[i];
        if (isdefined(struct.player)) {
            if (struct.player.isActive && struct.player != killer) {
                struct.player.assists ++;
                if (struct.damage > 400) {
                    struct.player thread scripts\players\_rank::giveRankXP("assist5");
                    struct.player thread scripts\players\_players::incUpgradePoints(10*level.rewardScale);
                } else if (struct.damage > 200) {
                    struct.player thread scripts\players\_rank::giveRankXP("assist4");
                    struct.player thread scripts\players\_players::incUpgradePoints(7*level.rewardScale);
                } else if (struct.damage > 100) {
                    struct.player thread scripts\players\_rank::giveRankXP("assist3");
                    struct.player thread scripts\players\_players::incUpgradePoints(5*level.rewardScale);
                } else if (struct.damage > 50) {
                    struct.player thread scripts\players\_rank::giveRankXP("assist2");
                    struct.player thread scripts\players\_players::incUpgradePoints(3*level.rewardScale);
                } else if (struct.damage > 25) {
                    struct.player thread scripts\players\_rank::giveRankXP("assist1");
                    struct.player thread scripts\players\_players::incUpgradePoints(3*level.rewardScale);
                } else if (struct.damage > 0) {
                    struct.player thread scripts\players\_rank::giveRankXP("assist0");
                    struct.player thread scripts\players\_players::incUpgradePoints(2*level.rewardScale);
                }
            }
        }
    }
    self.damagedBy = undefined;
}

/**
 * @brief Sets the animation for a zombie by changing the zombie's weapon
 *
 * @param type string The name of the animation type
 *
 * @returns nothing
 */
setAnimation(type)
{
    // 6th most-called function (2% of all function calls).
    // Do *not* put a function entrance debugPrint statement here!

    if (isDefined(self.animation[type])) {
        self.animWeapon = self.animation[type];
        self TakeAllWeapons();
        self.pers["weapon"] = self.animWeapon;
        self giveweapon(self.pers["weapon"]);
        self givemaxammo(self.pers["weapon"]);
        self setspawnweapon(self.pers["weapon"]);
        self switchtoweapon(self.pers["weapon"]);
    }
}

/**
 * @brief Puts a zombie in idle mode, i.e. just standing there
 *
 * @returns nothing
 */
idle()
{
    debugPrint("in _bot::idle()", "fn", level.fullVerbosity);

    self setAnimation("stand");
    self.cur_speed = 0;
    self.alertLevel = 0;
    self.status = "idle";
    //iprintlnbold("IDLE!");
}

search()
{
    debugPrint("in _bot::search()", "fn", level.fullVerbosity);

    self.status = "searching";
    //iprintlnbold("SEARCHING!");
}

run()
{
    // Do *not* put a function entrance debugPrint statement here!

    self setAnimation("sprint");
    self.cur_speed = self.runSpeed;
    if (self.quake) {
        Earthquake( 0.25, .3, self.origin, 380);
    }
}

walk()
{
    // Do *not* put a function entrance debugPrint statement here!

    self setAnimation("walk");
    self.cur_speed = self.walkSpeed;
    if (self.quake) {
        Earthquake( 0.17, .3, self.origin, 320);
    }
}

/// climbing up a ladder.  bipeds only
ladder()
{
    // Do *not* put a function entrance debugPrint statement here!

    self setAnimation("walk");
    self.cur_speed = self.walkSpeed;
    if (self.quake) {
        Earthquake( 0.17, .3, self.origin, 320);
    }
}

/// climbing up a short wall or crate.  bipeds only
mantle()
{
    // Do *not* put a function entrance debugPrint statement here!

    self setAnimation("walk");
    self.cur_speed = self.walkSpeed;
    if (self.quake) {
        Earthquake( 0.17, .3, self.origin, 320);
    }
}

pathType(fromWp, toWp)
{
    if (level.Wp[fromWp].type == "mantle") {
        deltaZ = level.Wp[toWp].origin[2] - level.Wp[fromWp].origin[2];
        distance = distance2D(level.Wp[fromWp].origin, level.Wp[toWp].origin);
        if ((deltaZ >= 15) && (deltaZ <= 50) && (distance < 25)) {
            // we only mantle up, never down
            return "mantle";
        } else {return "normal";}
    } else if ((level.Wp[fromWp].type == "ladder") && (level.Wp[toWp].type == "ladder")) {
        return "ladder";
    } else if ((level.Wp[fromWp].type == "clamped") && (level.Wp[toWp].type == "clamped")) {
        return "clamped";
    }

    return "normal";
}

/**
 * @brief Stuns a zombie
 *
 * An effect of the thundergun
 *
 * @returns nothing
 */
stun()
{
    debugPrint("in _bot::stun()", "fn", level.fullVerbosity);

    // no stunning in final wave!
    if (level.currentWave < level.totalWaves) {
        self setAnimation("stand");
        self.cur_speed = 0;
        self.alertLevel = 0;
        self.status = "stunned";
        //iprintlnbold("STUNNED!");
    }
}

groan()
{
    debugPrint("in _bot::groan()", "fn", level.veryHighVerbosity);

    self endon("death");
    self endon("disconnect");

    if (self.soundType == "dog") {return;}

    while (1) {
        if (self.isDoingMelee == false) {
            if (self.alertLevel == 0) {
                // Do nothing
            } else if (self.alertLevel < 200) {
                self playSoundOnBot(randomfloat(.5), "zom_walk", randomint(7));
            } else {
                self playSoundOnBot(randomfloat(.5), "zom_run", randomint(6));
            }
        }
        wait 3 + randomfloat(3);
    }
}

canSeeTarget(target)
{
    // 4th most-called function (6% of all function calls).
    // Do *not* put a function entrance debugPrint statement here!

    if (!isDefined(target)) {return false;}
    if (!target.isObj) {
        if (!target.isAlive) {return false;}
        if (!target.isTargetable) {return false;}
    }

    if (!target.visible) {return false;}

    distance = distance(self.origin, target.origin);
    if (distance > level.zombieSightDistance) {return false;}

    // unit vectors
    forwardVector = anglesToForward(self getplayerangles());
    targetVector = vectorNormalize(target.origin-self.origin);
    dot = vectorDot(forwardVector, targetVector);

    // target is in the area we can see by turning our head
    if(dot > -0.5) {
        // do a trace to see if we can see the target
        if (!target.isObj) {
            // player
            trace = bullettrace(self getEye(), target getEye(), false, self);
        } else {
            trace = bullettrace(self getEye(), target.origin + (0,0,20), false, self);
        }
        if (trace["fraction"] == 1) {
            // no obstructions
            return true;
        } else {
            if (isDefined(trace["entity"])) {
                if (trace["entity"] == target) {
                    // we hit something, but it was our target, so no problem
                    return true;
                }
            }
            //line(self.origin + (0,0,68), trace["position"], (1,0,0));
            return false;
        }
    }
    return false;
}

findPathToTarget()
{
    debugPrint("in _bot::bestTarget()", "fn", level.highVerbosity);

    if (self.isFollowingWapypoints) {
    } else {
        speed = self.cur_speed * 5; // assume spec'd speeds are per 0.2s, not per second, so scale them
        maxDistance = speed * 0.2;
        maxStepDistance = maxDistance / 4;
        noticePrint("speed: " + speed + " maxDistance: " + maxDistance + " maxStepDistance: " + maxStepDistance);
        distance = distance(self.origin, self.targetedPlayer.origin);
        trace = bulletTrace(self.origin + (0,0,20), self.targetedPlayer.origin + (0,0,20), false, self.targetedPlayer);
        if ((trace["fraction"] == 1) ||
            ((isDefined(trace["entity"])) && (trace["entity"] == self.targetedPlayer)))
        {
            // we generally have a straight path to the target
            facingVector = anglesToForward(self getPlayerAngles());
            targetVector = vectorNormalize(self.targetedPlayer.origin - self.origin);
            origin = self.origin;
            for (i=0; i<4; i++) {
                position = origin + (targetVector * maxStepDistance);
                position = self findLinearPath(origin, position, maxStepDistance);
                if (self.isBipedal) {
                    // bipeds should always be vertical
                    facing = vectorToAngles(targetVector * (1,1,0)); // zero out the z-component
                } else {
                    // non-bipeds should always be parallel to the ground surface
                    facing = vectorToAngles(targetVector);
                }
//                 iPrintLnBold("enqueueing movement: " + position);
                self enqueueMovement(position, 0.05, facing);
                origin = position;
            }
        } else {
            // no straight path to target
        }
    }
}

findLinearPath(origin, destination, distance)
{
    debugPrint("in _bot::findLinearPath()", "fn", level.highVerbosity);

    position = self findGround(destination);
    if (isPathNavigable(origin, position)) {
        // really requires system of two equations in 2 variables, maxStepDistance and findGround
        positionVector = vectorNormalize(position - origin);
        position = origin + (positionVector * distance);
        position = self findGround(position);
        return position;
    } else {
        iPrintLnBold("Path not navigable!");
    }
    /// hack
    return position;
}

isPathNavigable(origin, destination)
{
    debugPrint("in _bot::isPathNavigable()", "fn", level.highVerbosity);

    // assume the mapmaker didn't put a waypoint link through a solid object
    if (self.isFollowingWapypoints) {return true;}

    from = (destination[0], destination[1], origin[2]);
    levelVector = vectorNormalize(from - origin);
    targetVector = vectorNormalize(destination - origin);
    dot = vectorDot(levelVector, targetVector);
    if (dot >= 0.5) {
        // path from origin to destination is +/- 45 degrees
        return true;
    } else {
        // maybe we need to jump, climb, or find an alternate route
        iPrintLnBold("dot: " + dot);
        red = decimalRgbToColor(255,0,0);
        blue = decimalRgbToColor(0,0,255);
        /// probably a step up or a step down, cliff, low wall
        while (1) {
            line(from + (0,0,30), origin + (0,0,30), red, false, 25); // levelVector
            line(destination + (0,0,30), origin + (0,0,30), blue, false, 25); // targetVector
            wait 0.5;
        }
        return false;
    }

    /// @todo implement rest of isPathNavigable()
    return true;
}

enqueueMovement(origin, time, facing)
{
    debugPrint("in _bot::enqueueMovement()", "fn", level.highVerbosity);

    self.movement.orders[self.movement.last].origin = origin;
    self.movement.orders[self.movement.last].time = time;
    self.movement.orders[self.movement.last].angles = facing;
    self.movement.last++;
    if (self.movement.last == self.movement.orders.size) {self.movement.last = 0;}
}

findGround(position)
{
    debugPrint("in _bot::findGround()", "fn", level.highVerbosity);

    top = position + (0,0,50);
    bottom = position + (0,0,-100);
    trace = bulletTrace(top, bottom, false, self);
    return trace["position"];
}

bestTarget()
{
    debugPrint("in _bot::bestTarget()", "fn", level.highVerbosity);

    // the best target is the closest player the bot can see
    targets = self sortTargetsByDistance();
    if (!isDefined(targets[0])) {return undefined;}

    for (i=0; i<targets.size; i++) {
        if (self canSeeTarget(targets[i].player)) {
            return targets[i].player;
        }
    }
    // if the bot can't see any of the players, just use the closest player
    return targets[0].player;
}

closestTarget()
{
    debugPrint("in _bot::closestTarget()", "fn", level.highVerbosity);

    targets = self sortTargetsByDistance();
    if (!isDefined(targets[0])) {return undefined;}

    return targets[0].player;
}

sortTargetsByDistance()
{
    debugPrint("in _bot::sortTargetsByDistance()", "fn", level.highVerbosity);

    players = level.players;
    data = [];
    for (i=0; i<players.size; i++) {
        player = players[i];
        if (!isDefined(player)) {continue;}
        if ((isDefined(player.isTargetable)) && (!player.isTargetable)) {continue;}
        if (player.isAlive) {
            temp = spawnStruct();
            temp.player = player;
            temp.distance = distanceSquared(self.origin, player.origin);
            // ordered insert by distance
            first = 0;
            j = data.size;
            while ((j > first) && (temp.distance < data[j-1].distance)) {
                data[j] = data[j-1];
                j--;
            }
            data[j] = temp;
        }
    }
    return data;
}

main()
{
    debugPrint("in _bot::main()", "fn", level.highVerbosity);

    wait 1.2; // wait until bot is standing up before he starts to move
    target = bestTarget();
    self.targetedPlayer = target;
    self watchTargetedPlayer();
    iPrintLnBold("Targeting " + self.targetedPlayer.name);
    self.cur_speed = self.walkSpeed;
    self thread move();
}

move()
{
    debugPrint("in _bot::move()", "fn", level.highVerbosity);

    self endon("disconnect");
    self endon("death");
    self endon("movement_invalidated");

    i = 0;
    while (i < 100) {
        self findPathToTarget();
        noticePrint("target position: " + self.targetedPlayer.origin);
        self walk();
        while (self.movement.first != self.movement.last) {
            position = self.movement.orders[self.movement.first].origin;
            time = self.movement.orders[self.movement.first].time;
            angles = self.movement.orders[self.movement.first].angles;
            noticePrint("moving:" + position + ", " + time);
            self setPlayerAngles(angles);
            self.mover moveTo(position, time);
            wait time;
            self.movement.first++;
            if (self.movement.first == self.movement.orders.size) {self.movement.first = 0;}
        }
        i++;
        //wait 0.5;
    }
    self idle();
    iPrintLnBold("Done moving!");
}

/**
 * @brief Watch targeted player for events that should make us find a new target
 *
 * @returns nothing
 */
watchTargetedPlayer()
{
    debugPrint("in _bot::watchTargetedPlayer()", "fn", level.highVerbosity);

    self endon("disconnect");
    self endon("death");

    self thread onTargetedPlayerDeath();
    /// @todo also on disconnect, change class, death (boom), join spectator

}

/**
 * @brief When a targeted player goes down, invalidate the target so we can get a new one
 *
 * @returns nothing
 */
onTargetedPlayerDeath()
{
    debugPrint("in _bot::onTargetedPlayerDeath()", "fn", level.highVerbosity);

    self endon("disconnect");
    self endon("death");
    self endon("target_invalidated");

    self.targetedPlayer waittill("downed");
    self notify("target_invalidated");
}

/**
 * @brief When a targeted player is invalidated, find a new target
 *
 * @returns nothing
 */
newTarget()
{
    debugPrint("in _bot::newTarget()", "fn", level.highVerbosity);

    self endon("disconnect");
    self endon("death");

    while (1) {
        self waittill("target_invalidated");

        target = bestTarget();
        self.targetedPlayer = target;
        self watchTargetedPlayer();
    }
}

/**
 * @brief Performs a melee attack on a player
 *
 * @returns nothing
 */
melee()
{
    debugPrint("in _bot::melee()", "fn", level.veryHighVerbosity);

    self endon("disconnect");
    self endon("death");
    self endon("target_invalidated");

    self.movementType = "melee";
    self setAnimation("melee");
    wait .6;

    if (self.quake) {Earthquake( 0.25, .2, self.origin, 380);}

    if (isAlive(self)) {
        self damage(70);
        self playSoundOnBot(0, "zom_attack", randomint(8));
    }
    wait .6;

    self setAnimation("stand");
}

/**
 * @brief Decides whether to infect a player or not
 *
 * @param chance float The percentage chance of this type of zombie infecting a player
 *
 * @returns nothing
 */
infect(chance)
{
    debugPrint("in _bot::infect()", "fn", level.medVerbosity);

    if (self.infected) {return;}

    chance = self.infectionMP * chance;
    if (randomfloat(1) < chance) {
        self thread scripts\players\_infection::goInfected();
    }
}

damage(meleeRange)
{
    debugPrint("in _bot::damage()", "fn", level.highVerbosity);

    meleeRangeSquared = meleeRange * meleeRange;
    damage = int(self.damage * level.dif_zomDamMod);

    // damage player
    targets = self sortTargetsByDistance();
    if (targets.size == 0) {
        // all players are down, or not targetable (like in admin menu)
    }
    for (i=0; i<targets.size; i++) {
        target = targets[i].player;
        distance = targets[i].distance; // a squared distance
        if (distance < meleeRangeSquared) {
            fwdDir = anglesToForward(self getPlayerAngles());
            dirToTarget = vectorNormalize(target.origin - self.origin);
            dot = vectorDot(fwdDir, dirToTarget);
            if (dot > .5) {
                target.isPlayer = true;
                target.entity = target;
                target scripts\include\entities::damageEnt(self, self, damage,
                                 "MOD_MELEE", self.pers["weapon"], self.origin, dirToTarget);
                self scripts\bots\_types::onAttack(self.type, target);
                if (level.dvar["zom_infection"]) {target infect(self.infectionChance);}
                // only damage the first suitable player we find
                break;
            }
        } else {
            // no other player targets within range
            break;
        }
    }

    // damage a barricade
    for (i=0; i<level.barricades.size; i++) {
        barricade = level.barricades[i];
        distance = distance2d(self.origin, barricade.origin);
        range = meleeRange * 2;
        if (distance < range) {
            barricade thread scripts\players\_barricades::doBarricadeDamage(damage);
            break;
        }
    }

    // damage a dynamic barricade
    for (i=0; i<level.dynamic_barricades.size; i++) {
        barricade = level.dynamic_barricades[i];
        distance = distance2d(self.origin, barricade.origin);
        if (distance < meleeRange) {
            barricade thread scripts\players\_barricades::doBarricadeDamage(damage);
            break;
        }
    }
}

killed(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration)
{
    debugPrint("in _bot::killed()", "fn", level.veryHighVerbosity);

    //self unlink();
    self notify("dying");

    if(self.sessionteam == "spectator") {return;}

    if(sHitLoc == "head" && sMeansOfDeath != "MOD_MELEE") {
        sMeansOfDeath = "MOD_HEAD_SHOT";
    }

    if (level.dvar["zom_orbituary"]) {
        obituary(self, attacker, sWeapon, sMeansOfDeath);
    }

    self.sessionstate = "dead";

    isBadKill = false;

    if (isplayer(attacker) && attacker != self) {
        if ((self.type == "burning") ||
            (self.type == "burning_dog") ||
            (self.type == "burning_tank"))
        {
            // No demerits if weapon is claymore or defense turrets, since player
            // has no control over when it detonates/fires
            switch (sWeapon) {
                case "claymore_mp":     // Fall through
                case "turret_mp":
                case "none":            // minigun and grenade turrets are "none"
                    // Do nothing
                break;
                default:
                    players = level.players;
                    for (i=0; i<players.size; i++) {
                        if (!isDefined(players[i])) {continue;}
                        if (attacker != players[i]) {
                            if ((!players[i].isDown) &&
                                (distance(self.origin, players[i].origin) < 150)) {
                                attacker thread scripts\players\_rank::increaseDemerits(level.burningZombieDemeritSize, "burning");
                                isBadKill = true;
                            }
                        }
                    }
                    break;
            }
        }
        if (!isBadKill) {
            // No credit for kills that hurt teammates
            attacker.kills++;

            attacker thread scripts\players\_rank::giveRankXP("kill");
            attacker thread scripts\players\_spree::checkSpree();

            if (attacker.curClass=="stealth") {
                attacker scripts\players\_abilities::rechargeSpecial(10);
            }
            attacker scripts\players\_players::incUpgradePoints(10*level.rewardScale);
            giveAssists(attacker);
        }
    }

    corpse = self scripts\bots\_types::onCorpse(self.type);
    if (self.soundType == "zombie") {
        self playSoundOnBot(0, "zom_death", randomint(6));
    }

    if (corpse > 0) {
        if (self.type=="toxic") {
            deathAnimDuration = 20;
        }

        body = self clonePlayer(deathAnimDuration);
        body.isCorpse = true;

        if (corpse > 1) {
            thread scripts\include\physics::delayStartRagdoll( body, sHitLoc, vDir, sWeapon, eInflictor, sMeansOfDeath );
        }
    } else {
//         self setOrigin((0,0,-10000));
    }
    self setOrigin((0,0,-10000));
    self unlink();

    level.dif_killedLast5Sec++;

    wait 1;
    self.hasSpawned = false;
    level.botsAlive -= 1;

    makeBotAvailable(self);
//     noticePrint("zombie killed, making bot available");
    level notify("bot_killed");
}
