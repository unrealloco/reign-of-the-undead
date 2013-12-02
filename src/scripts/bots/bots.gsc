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

#include scripts\bots\bot;
#include scripts\include\utility;

init()
{
    debugPrint("in bots::init()", "fn", level.nonVerbose);

    precache();

    scripts\include\waypoints::loadWaypoints();

    level.bots = [];
    level.availableBots = []; // stack
    level.botSpawnpointsQueue = []; // filled circular queue
    level.nextBotSpawnpointPointer = 0; // pointer to the 'next' position in botSpawnpointsQueue
    level.botSpawnpoints = [];  // bot spawnpoints. data in botSpawnpointsQueue is index of spawnpoint in this array
    level.botsAlive = 0;
    level.botsLoaded = false;
    level.zombieSightDistance = 2048;
    level.devLoadBots = true; // for development: should we actually load bots?

    wait 1;
    if (level.devLoadBots) {instantiateBots(level.dvar["bot_count"]);}

    scripts\bots\_types::initZomTypes();
    scripts\bots\_types::initZomModels();
    level.botsLoaded = true;
    thread monitorBotSlots();
    thread findAdditionalSpawnpoints();
}


precache()
{
    debugPrint("in bots::precache()", "fn", level.nonVerbose);

    // precache the weapons used for animations
    precacheItem("bot_zombie_walk_mp");
    precacheItem("bot_zombie_stand_mp");
    precacheItem("bot_zombie_run_mp");
    precacheItem("bot_zombie_melee_mp");
    precacheItem("bot_dog_idle_mp");
    precacheItem("bot_dog_run_mp");
    precacheItem("defaultweapon_mp");

    // precache the xmodels we use for zombies
    precacheModel("tag_origin");
    precacheModel("izmb_zombie1_body");
    precacheModel("izmb_zombie2_body");
    precacheModel("izmb_zombie2_head");
    precacheModel("izmb_zombie3");
    precacheModel("body_complete_sp_zakhaevs_son");
    precacheModel("bo_quad");
    precacheModel("cyclops");
    precacheModel("body_complete_sp_vip");
    precacheModel("body_complete_sp_russian_farmer");
    precacheModel("german_sheperd_dog");
    precacheModel("body_hellknight");
    precacheModel("cyclops");

    // precache the shellshocks we use
    precacheShellShock("boss");
    precacheShellShock("toxic_gas_mp");

    // load the fx we use for zombies into memory
    level.explodeFX     = loadFx("explosions/pyromaniac");
    level.burningFX     = loadFx("fire/firelp_med_pm");
    level.burningDogFX  = loadFx("fire/firelp_small_pm_rotu");
    level.toxicFX       = loadFx("misc/toxic_gas");
    level.soulFX        = loadFx("misc/soul");
    level.goundSpawnFX  = loadFx("misc/ground_rising");
    level.soulspawnFX   = loadFx("misc/soulspawn");
}

/**
 * @brief Instantiates the requested number of bots
 *
 * @param botCount integer The number of bots to create
 *
 * @returns nothing
 */
instantiateBots(botCount)
{
    debugPrint("in bots::instantiateBots()", "fn", level.nonVerbose);

    failedCount = 0;    // The number of bots we ultimately failed to create
    attemptCount = 0;
    attemptLimit = 3;   // The maximum number of times to try to create a single bot

    for (i=0; i<botCount; i++) {
        if (!instantiate()) {
            attemptCount++;
            if (attemptCount <= attemptLimit) {
                i--;
                continue;
            } else {
                failedCount++;
                attemptCount = 0;
            }
        } else {attemptCount = 0;}
    }

    if (failedCount != 0) {
        errorPrint("Failed to load " + failedCount + " of " + botCount + " bots.");
    }

    level notify("bots_loaded");
}

/**
 * @brief Finds available bots, then deletes them to free up slots for human players
 *
 * @param botCount integer The number of bots to delete
 *
 * @returns nothing
 */
deleteBots(botCount)
{
    debugPrint("in bots::deleteBots()", "fn", level.fullVerbosity);

    botsToRemove = [];

    // pop the bots we want to remove off the available stack
    while (botsToRemove.size - 1 < botCount) {
        bot = undefined;
        while (!isDefined(bot)) {
            wait 0.1;
            bot = availableBot();
        }
        botsToRemove[botsToRemove.size] = bot.index;
    }

    remove(botsToRemove);
}

/**
 * @brief Finds a bot that is available for spawning
 *
 * @returns struct The bot, or undefined if no bot is available for spawning
 */
availableBot()
{
    debugPrint("in bots::availableBot()", "fn", level.fullVerbosity);

    noticePrint(level.availableBots.size + " bots available.");
    if (level.availableBots.size == 0) {
        errorPrint("No available bots!");
        return undefined;
    } else {
        // pop a bot off the stack and return it
        bot = level.bots[level.availableBots[level.availableBots.size - 1]];
        level.availableBots[level.availableBots.size - 1] = undefined;
        bot.hasSpawned = true;
        return bot;
    }
}

/**
 * @brief Add/Removes bot slots to optimize use of server slots
 *
 * @returns nothing
 */
monitorBotSlots()
{
    debugPrint("in bots::monitorBotSlots()", "fn", level.fullVerbosity);

    level endon("game_ended");

    totalSlots = getDvarInt("ui_maxclients");
    maxBots = getDvarInt("max_bots");                           // never have more bots than this
    maxPlayers = getDvarInt("max_players");                     // never have more than this many slots for players
    minOpenPlayerSlots = getDvarInt("min_open_player_slots");   // try to keep this many open slots for players
    tolerance = getDvarInt("slot_tolerance");                   // Do nothing if botDelta is +/- tolerance

    while (1) {
        level waittill("wave_finished");
        wait 3;

        playersCount = level.players.size;
        botCount = level.bots.size;

        playersGoal = (playersCount + minOpenPlayerSlots);
        // never more player slots than spec'd
        if (playersGoal > maxPlayers) {playersGoal = maxPlayers;}

        botCountGoal = totalSlots - playersGoal;
        // never more bots than spec'd
        if (botCountGoal > maxBots) {botCountGoal = maxBots;}

        botDelta = botCountGoal - botCount;

        if (botDelta >= tolerance) {
            // add bots
            noticePrint("Adaptive Slot System: Adding " + botDelta + " bots.");
            instantiateBots(botDelta);
        } else if (botDelta <= (-1 * tolerance)) {
            // remove bots
            noticePrint("Adaptive Slot System: Removing " + (-1 * botDelta) + " bots.");
            deleteBots(botDelta);
        }
    }
}

/**
 * @brief Loads zombie spawnpoints from a map
 *
 * @param targetname string The targetname of the spawnpoint entity
 * @param priority integer The relative priority of this spawnpoint
 *
 * @returns nothing
 */
addSpawnpoints(targetname, priority)
{
    debugPrint("in bots::addSpawnpoints()", "fn", level.nonVerbose);

    if (!isDefined(priority)) {priority = 1;}

    spawns = getentarray(targetname, "targetname");
    for (i=0; i<spawns.size; i++) {
        spawnpoint = spawnStruct();
        spawnpoint.origin = spawns[i].origin;
        if (isDefined(spawns[i].angles)) {spawnpoint.angles = spawns[i].angles;}
        else {spawnpoint.angles = (0,0,0);}
        noticePrint("spawnpoint.angles: " + spawnpoint.angles);
        spawnpoint.priority = priority;
        spawnpoint.children = 0;

        level.botSpawnpoints[level.botSpawnpoints.size] = spawnpoint;
    }
}

/**
 * @brief Finds and loads additional zombie spawnpoints, and loads the spawnpoint queue
 *
 * @returns nothing
 */
findAdditionalSpawnpoints()
{
    debugPrint("in bots::findAdditionalSpawnpoints()", "fn", level.fullVerbosity);

    potentialSpawnpoints = [];
    wait 3;

    // For each zombie spawnpoint spec'd in the map by the author, we look for
    // additional spawnpoints near it.  We check four positions releative to the spec'd
    // spawnpoint: 40 units in front, 40 units 35 degrees left of front, 40 units
    // 35 degrees right of front, and 40 units behind.
    for (i=0; i<level.botSpawnpoints.size; i++) {
        spawnpoint = level.botSpawnpoints[i];

        // unit vectors
        anglesLeft = spawnpoint.angles + (0,-35,0);
        anglesRight = spawnpoint.angles + (0,35,0);
        anglesForward = anglesToForward(spawnpoint.angles);
        anglesUp = anglesToUp(spawnpoint.angles);

        // the four positions we will check
        leftOrigin = spawnpoint.origin + (anglesToForward(anglesLeft) * 40);
        rightOrigin = spawnpoint.origin + (anglesToForward(anglesRight) * 40);
        forwardOrigin = spawnpoint.origin + (anglesForward * 40);
        backwardOrigin = spawnpoint.origin + (anglesForward * 40) * -1;

        // a laser at the origin and angles of the original spawnpoint
        maps\mp\_umiEditor::devDrawLaser("green", spawnpoint.origin + (0,0,20), anglesForward);
//         maps\mp\_umiEditor::devDrawLaser("red", leftOrigin + (0,0,20), anglesUp);
//         maps\mp\_umiEditor::devDrawLaser("blue", forwardOrigin + (0,0,20), anglesUp);
//         maps\mp\_umiEditor::devDrawLaser("yellow", rightOrigin + (0,0,20), anglesUp);
//         maps\mp\_umiEditor::devDrawLaser("cyan", backwardOrigin + (0,0,20), anglesUp);

        // check the four points, and if OK, consider them to be potential new spawnpoints
        left = isSpawnpointOk(leftOrigin);
        forward = isSpawnpointOk(forwardOrigin);
        right = isSpawnpointOk(rightOrigin);
        backward = isSpawnpointOk(backwardOrigin);
        if (isDefined(left)) {
            potentialSpawnpoint = spawnStruct();
            potentialSpawnpoint.origin = left;
            potentialSpawnpoint.angles = spawnpoint.angles;
            potentialSpawnpoint.parent = i;
            potentialSpawnpoint.priority = 1;
            potentialSpawnpoint.children = 0;
            potentialSpawnpoints[potentialSpawnpoints.size] = potentialSpawnpoint;
        }
        if (isDefined(forward)) {
            potentialSpawnpoint = spawnStruct();
            potentialSpawnpoint.origin = forward;
            potentialSpawnpoint.angles = spawnpoint.angles;
            potentialSpawnpoint.parent = i;
            potentialSpawnpoint.priority = 1;
            potentialSpawnpoint.children = 0;
            potentialSpawnpoints[potentialSpawnpoints.size] = potentialSpawnpoint;
        }
        if (isDefined(right)) {
            potentialSpawnpoint = spawnStruct();
            potentialSpawnpoint.origin = right;
            potentialSpawnpoint.angles = spawnpoint.angles;
            potentialSpawnpoint.parent = i;
            potentialSpawnpoint.priority = 1;
            potentialSpawnpoint.children = 0;
            potentialSpawnpoints[potentialSpawnpoints.size] = potentialSpawnpoint;
        }
        if (isDefined(backward)) {
            potentialSpawnpoint = spawnStruct();
            potentialSpawnpoint.origin = backward;
            potentialSpawnpoint.angles = spawnpoint.angles;
            potentialSpawnpoint.parent = i;
            potentialSpawnpoint.priority = 1;
            potentialSpawnpoint.children = 0;
            potentialSpawnpoints[potentialSpawnpoints.size] = potentialSpawnpoint;
        }
    }

    // test each potential new spawnpoint against all other spawnpoints to ensure
    // they are at least 30 units from each other.  If so, add it as a real spawnpoint.
    added = 0;
    for (i=0; i<potentialSpawnpoints.size; i++) {
        isGood = true;
        for (j=0; j<level.botSpawnpoints.size; j++) {
            dist = distance(potentialSpawnpoints[i].origin, level.botSpawnpoints[j].origin);
            if (dist < 30) {
                // discard this potential spawnpoint
                isGood = false;
                break;
            }
        }
        if (isGood) {
            // add this as a new spawnpoint
            added++;
            level.botSpawnpoints[level.botSpawnpoints.size] = potentialSpawnpoints[i];
            level.botSpawnpoints[potentialSpawnpoints[i].parent].children++;
            anglesUp = anglesToUp(potentialSpawnpoints[i].angles);
            maps\mp\_umiEditor::devDrawLaser("red", potentialSpawnpoints[i].origin + (0,0,20), anglesUp);
        }
    }

    // Now distribute each spawnpoint's priority amongst itself and its children
    // to preserve the overall priority the map author intended.
    // This math is not correct, but it does give us a close enough approximation.
    lowestPriority = 500;
    for (i=0; i<level.botSpawnpoints.size; i++) {
        level.botSpawnpoints[i].priority = int((level.botSpawnpoints[i].priority * 20) / (level.botSpawnpoints[i].children + 1));
        if (level.botSpawnpoints[i].priority < lowestPriority) {
            lowestPriority = level.botSpawnpoints[i].priority;
        }
    }
    // scale lowestPriority to 1
    for (i=0; i<level.botSpawnpoints.size; i++) {
        level.botSpawnpoints[i].priority = int(level.botSpawnpoints[i].priority / lowestPriority);
    }
    // now give children their parent's reduced priority
    for (i=0; i<level.botSpawnpoints.size; i++) {
        if (!isDefined(level.botSpawnpoints[i].parent)) {continue;}
        level.botSpawnpoints[i].priority = level.botSpawnpoints[level.botSpawnpoints[i].parent].priority;
    }
    noticePrint("Added " + added + " extra spawnpoints");

    // build a non-randomized queue with the right priorities
    queue = [];
    for (i=0; i<level.botSpawnpoints.size; i++) {
        for (j=0; j<level.botSpawnpoints[i].priority; j++) {
            queue[queue.size] = i;
        }
    }

    // build a filled randomized circular queue we will use to supply spawnpoints
    // for zombies in the game
    while (queue.size > 0) {
        index = randomInt(queue.size);
        level.botSpawnpointsQueue[level.botSpawnpointsQueue.size] = queue[index];
        if (index == queue.size - 1) {
            // is already last element
            queue[index] = undefined;
        } else {
            // copy last element to index, then undefine last element
            queue[index] = queue[queue.size - 1];
            queue[queue.size - 1] = undefined;
        }
    }

    // rebuild level.botSpawnpoints without the now unneeded information
    spawnpoints = level.botSpawnpoints;
    level.botSpawnpoints = [];
    for (i=0; i<spawnpoints.size; i++) {
        sp = spawnStruct();
        sp.origin = spawnpoints[i].origin;
        sp.angles = spawnpoints[i].angles;
        level.botSpawnpoints[i] = sp;
    }

    noticePrint("level.botSpawnpoints.size: " + level.botSpawnpoints.size);
    noticePrint("level.botSpawnpointsQueue.size: " + level.botSpawnpointsQueue.size);
    // free unused memory
    potentialSpawnpoints = undefined;
}

/**
 * @brief Tests a potential spawnpoint for obstructions
 *
 * @param origin tuple The location to test
 *
 * @returns The possibly adjusted origin if it is OK, otherwise undefined
 */
isSpawnpointOk(origin)
{
    debugPrint("in bots::isSpawnpointOk()", "fn", level.fullVerbosity);

    // the spec'd spawnpoint may be in the air, with overhead cover, such that
    // we will hit the ceiling when we check for obstructions.  So first we try
    // to find the ground
    trace = bulletTrace(origin + (0,0,20), origin + (0,0,-50), false, undefined);
    if (trace["fraction"] != 1) {
        origin = trace["position"];
    }

    spawnpointClear = true;
    length = 15; // radius of the bot cylinder
    for (h = 5; h<85; h = h + 10) {
        for (i=0; i<360; i = i + 15) {
            center = origin + (0, 0, 45);
            end = origin + (length * cos(i), length * sin(i), h);
            if (!sightTracePassed(center, end, false, undefined)) {
                spawnpointClear = false;
                break;
            }
        }
        if(!spawnpointClear) {break;}
    }
    if (spawnpointClear) {
        // no obstructions detected, see if we are in mid-air
        trace = bulletTrace(origin + (0,0,50), origin + (0,0,-50), false, undefined);
        if (trace["fraction"] == 1) {
            // we are in midair!
            return undefined;
        } else {return trace["position"];}
    } else {return undefined;}
}

/**
 * @brief Spawns a zombie into the game
 *
 * @param zombieType string The type of zombie to spawn
 * @param spawnpoint struct A struct containing the position and angles for spawning the zombie
 * @param bot struct The bot to use for this zombie
 *
 * @returns bot The spawned zombie
 */
spawnZombie(zombieType, spawnpoint, bot)
{
    debugPrint("in bots::spawnZombie()", "fn", level.fullVerbosity);

    noticePrint("trying to spawn zombie");

    if (!isDefined(bot)) {
        bot = availableBot();
        if (!isDefined(bot)) {return undefined;}
    }

    bot.readyToBeKilled = false;
    bot.hasSpawned = true;
    bot.currentTarget = undefined;
    bot.targetPosition = undefined;
    bot.type = zombieType;

    bot.team = bot.pers["team"];
    bot.sessionteam = bot.team;
    bot.sessionstate = "playing";
    bot.spectatorclient = -1;
    bot.killcamentity = -1;
    bot.archivetime = 0;
    bot.psoffsettime = 0;
    bot.statusicon = "";

    bot scripts\bots\_types::loadZomStats(bot.type);

    bot.maxHealth = int(bot.maxHealth * level.dif_zomHPMod);
    bot.health = bot.maxHealth;
    bot.isDoingMelee = false;
    bot.damagedBy = [];

    bot.alertLevel = 0; // Has this zombie been alerted?
    bot.myWaypoint = undefined;
    bot.underway = false;
    bot.canTeleport = true;
    bot.quake = false;

    bot scripts\bots\_types::loadAnimTree(bot.type);

    bot.animWeapon = bot.animation["stand"];
    bot TakeAllWeapons();
    bot.pers["weapon"] = bot.animWeapon;
    bot giveweapon(bot.pers["weapon"]);
    bot givemaxammo(bot.pers["weapon"]);
    bot setspawnweapon(bot.pers["weapon"]);
    bot switchtoweapon(bot.pers["weapon"]);

    if (isdefined(spawnpoint.angles)) {
        bot spawn(spawnpoint.origin, spawnpoint.angles);
    } else {
        bot spawn(spawnpoint.origin, (0,0,0));
    }

    level.botsAlive++;
    wait 0.05;

    bot scripts\bots\_types::loadZomModel(bot.type);
    bot freezeControls(true);

    bot.mover.origin = bot.origin;
    bot.mover.angles = bot.angles;

    bot.incdammod = 1;
    if ((bot.type != "tank" && bot.type != "boss") ||
        (level.dvar["zom_spawnprot_tank"]))
    {
        if (level.dvar["zom_spawnprot"]) {
            bot.incdammod = 0;
            bot thread endZombieSpawnProtection(level.dvar["zom_spawnprot_time"], level.dvar["zom_spawnprot_decrease"]);
        }
    }

    wait 0.05;
    bot scripts\bots\_types::onSpawn(bot.type);
    bot linkto(bot.mover);
    bot idle();
    bot thread main();
    bot thread groan();
    bot.readyToBeKilled = true;

    return bot;
}

/**
 * @brief Ends zombie spawn invincibility after a time, or over time
 *
 * @param time integer The time in seconds
 * @param decrease boolean Decrease gradually over time?
 *
 * @returns nothing
 */
endZombieSpawnProtection(time, decrease)
{
    debugPrint("in bots::endZombieSpawnProtection()", "fn", level.highVerbosity);

    self endon("death");

    if (decrease) {
        for (i=0; i<10; i++) {
            wait time/10;
            self.incdammod += .1;
        }
    } else {
        wait time;
        self.incdammod = 1;
    }
}


botKilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration)
{
    debugPrint("in bots::botKilled()", "fn", level.veryHighVerbosity);

    self unlink();

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
                                (distance(self.origin, players[i].origin) < 150))
                            {
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

        if (corpse > 1) {
            thread scripts\include\physics::delayStartRagdoll(body, sHitLoc, vDir, sWeapon, eInflictor, sMeansOfDeath);
        }
    } else {
        self setorigin((0,0,-10000));
    }

    level.dif_killedLast5Sec++;

    wait 1;
    self.hasSpawned = false;
    level.botsAlive -= 1;

    makeBotAvailable(self);
    level notify("bot_killed");
}
