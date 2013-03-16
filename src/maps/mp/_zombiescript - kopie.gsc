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

// GENERAL SCRIPTS
setGameMode(mode)
{
    debugPrint("in _zombiescript - kopie::setGameMode()", "fn", level.lowVerbosity);

    level.gameMode = mode;

    waittillframeend;
}

setPlayerSpawns(targetname)
{
    debugPrint("in _zombiescript - kopie::setPlayerSpawns()", "fn", level.lowVerbosity);

    level.playerspawns = targetname;
}

setWorldVision(vision, transitiontime)
{
    debugPrint("in _zombiescript - kopie::setWorldVision()", "fn", level.lowVerbosity);

    visionSetNaked(vision, transitiontime);
    level.vision = vision;
}

buildParachutePickup(targetname)
{
    debugPrint("in _zombiescript - kopie::buildParachutePickup()", "fn", level.lowVerbosity);

    ents = getentarray(targetname, "targetname");
    for (i=0; i<ents.size; i++) {
        ents[i] thread scripts\players\_parachute::parachutePickup();
    }
}

// SCRIPTED MODE

setZomSpawnInfo(targetname, target, idlebehavior)
{
    debugPrint("in _zombiescript - kopie::setZomSpawnInfo()", "fn", level.lowVerbosity);

    level.zomSpawns = targetname;
    level.zomTarget = target;
    level.zomIdleBehavior = idlebehavior;
}

beginZomSpawning()
{
    debugPrint("in _zombiescript - kopie::beginZomSpawning()", "fn", level.lowVerbosity);

    thread scripts\gamemodes\_scripted::beginZomSpawning();
}

endZomSpawning()
{
    debugPrint("in _zombiescript - kopie::endZomSpawning()", "fn", level.lowVerbosity);

    scripts\gamemodes\_scripted::endZomSpawning();
}

deleteBlocker(targetname)
{
    debugPrint("in _zombiescript - kopie::deleteBlocker()", "fn", level.lowVerbosity);

    blockers = getentarray(targetname, "targetname");
    for (i=0; i<blockers.size; i++) {
        blockers[i] delete();
    }
}

killAllBots()
{
    debugPrint("in _zombiescript - kopie::killAllBots()", "fn", level.lowVerbosity);

    for (i=0; i<level.bots.size; i++) {
        bot = level.bots[i];
        if (isalive(bot)) {bot suicide();}
    }
}

/// @deprecated
victory()
{
    debugPrint("in _zombiescript - kopie::victory()", "fn", level.lowVerbosity);
    errorPrint(getdvar("mapname") + " calling the deprecated function _zombiescript-kopie::victory().\n");
}

startObjective(argument, missiontext, icon2d, icon3d)
{
    debugPrint("in _zombiescript - kopie::startObjective()", "fn", level.lowVerbosity);

    if (!isString(argument)) {
        id = scripts\gamemodes\_objectives::addObjective("scripted", missiontext, argument);
    } else {
        obj = getentarray(argument, "targetname")[0];
        id = scripts\gamemodes\_objectives::addObjective("scripted", missiontext, obj.origin);
        scripts\gamemodes\_objectives::setTarget(id, argument);
        obj.obj_id = id;
    }

    if (icon2d) {
        scripts\gamemodes\_objectives::setCompassIcon(id, "compass_waypoint_bomb");
    }
    if (icon3d) {
        scripts\gamemodes\_objectives::setWorldIcon(id, "waypoint_bomb");
    }

    scripts\gamemodes\_objectives::activateObjective(id);

    return id;
}

objMakeUsable(index, hintstring, range)
{
    debugPrint("in _zombiescript - kopie::objMakeUsable()", "fn", level.lowVerbosity);

    scripts\gamemodes\_objectives::makeUseObj(index, hintstring, range);
}

objWaitForUsable(index)
{
    debugPrint("in _zombiescript - kopie::objWaitForUsable()", "fn", level.lowVerbosity);

    scripts\gamemodes\_objectives::waitForObjUsed(index);
}

/// @deprecated
addObjRadio(objectivename, targetname, time)
{
    debugPrint("in _zombiescript - kopie::addObjRadio()", "fn", level.lowVerbosity);
    errorPrint(getdvar("mapname") + " calling the deprecated function _zombiescript-kopie::addObjRadio().\n");
}

/// @deprecated
addObjIncomming(objectivename, triggername, spawns, zombiespp)
{
    debugPrint("in _zombiescript - kopie::addObjIncomming()", "fn", level.lowVerbosity);
    errorPrint(getdvar("mapname") + " calling the deprecated function _zombiescript-kopie::addObjIncomming().\n");
}

/// @deprecated
addObjDefend(objectivename, defencename, health, time)
{
    debugPrint("in _zombiescript - kopie::addObjDefend()", "fn", level.lowVerbosity);
    errorPrint(getdvar("mapname") + " calling the deprecated function _zombiescript-kopie::addObjDefend().\n");
}

/// @deprecated
timeout(text, seconds)
{
    debugPrint("in _zombiescript - kopie::timeout()", "fn", level.lowVerbosity);
    errorPrint(getdvar("mapname") + " calling the deprecated function _zombiescript-kopie::timeout().\n");
}

waittillObjEnd(objectivename)
{
    debugPrint("in _zombiescript - kopie::waittillObjEnd()", "fn", level.lowVerbosity);

    level waittill(objectivename + "_end");
}

setZombieSpawns(targetname)
{
    debugPrint("in _zombiescript - kopie::setZombieSpawns()", "fn", level.lowVerbosity);

    level.zombiespawns = targetname;
}

buildWeaponPickup(targetname, itemtext, weapon, type)
{
    debugPrint("in _zombiescript - kopie::buildWeaponPickup()", "fn", level.lowVerbosity);

    ents = getentarray(targetname, "targetname");
    for (i=0; i<ents.size; i++) {
        ent = ents[i];
        ent.myWeapon = weapon;
        ent.wep_type = type;
        level scripts\players\_usables::addUsable(ent, "weaponpickup", "Press [USE] to pick up " + itemtext, 96);
    }
}

buildAmmoStock(targetname, loadtime)
{
    debugPrint("in _zombiescript - kopie::buildAmmoStock()", "fn", level.lowVerbosity);

    ents = getentarray(targetname, "targetname");
    for (i=0; i<ents.size; i++) {
        ent = ents[i];
        ent.loadtime = loadtime;
        if (level.ammoStockType == "weapon") {
            level scripts\players\_usables::addUsable(ent, "ammobox", "Press [USE] for a weapon!", 96);
        }
        if (level.ammoStockType == "ammo") {
            level scripts\players\_usables::addUsable(ent, "ammobox", "Hold [USE] to restock ammo", 96);
        }
    }
}

setWeaponHandling(id)
{
    debugPrint("in _zombiescript - kopie::setWeaponHandling()", "fn", level.lowVerbosity);

    level.onGiveWeapons = id;
}

setSpawnWeapons(primary, setSpawnWeapons)
{
    debugPrint("in _zombiescript - kopie::setSpawnWeapons()", "fn", level.lowVerbosity);

    level.spawnPrimary = primary;
    level.spawnSecondary = secondary;
}

//SURVIVAL MODE
buildSurvSpawn(targetname, priority) // Loading spawns for survival mode (incomming waves)
{
    debugPrint("in _zombiescript - kopie::buildSurvSpawn()", "fn", level.lowVerbosity);

    scripts\gamemodes\_survival::addSpawn(targetname, priority);
}

buildWeaponUpgrade(targetname) // Weaponshop actually
{
    debugPrint("in _zombiescript - kopie::buildWeaponUpgrade()", "fn", level.lowVerbosity);

    ents = getentarray(targetname, "targetname");
    for (i=0; i<ents.size; i++) {
        ent = ents[i];
        level scripts\players\_usables::addUsable(ent, "extras", "Press [USE] to buy upgrades!", 96);
    }
}

startSurvWaves()
{
    debugPrint("in _zombiescript - kopie::startSurvWaves()", "fn", level.lowVerbosity);

    scripts\gamemodes\_survival::beginGame();
}

//GENERAL SCRIPTS
/**
 * @brief Waits until players are in the game before starting the game
 * N.B. Map makers: You *must* precache your resources before you call this function!
 * You can not precache anything after a call to wait().
 *
 * @returns nothing
 */
waittillStart()
{
    debugPrint("in _zombiescript - kopie::waittillStart()", "fn", level.lowVerbosity);

    wait .5;
    scripts\gamemodes\_gamemodes::initGameMode();

    while (level.activePlayers == 0) {
        wait .5;
    }

    logPrint("Notice: Zombiescript: " + getdvar("mapname") + " is using _zombiescript - kopie.gsc.\n");
}

/// @deprecated
buildBarricade(targetname, parts, health, deathFx, buildFx, dropAll)
{
    debugPrint("in _zombiescript - kopie::buildBarricade()", "fn", level.lowVerbosity);
    errorPrint(getdvar("mapname") + " calling the deprecated function _zombiescript-kopie::buildBarricade().\n");

    /*if (!isdefined(dropAll))
    dropAll = false;
    ents = getentarray(targetname, "targetname");
    for (i=0; i<ents.size; i++)
    {
        ent = ents[i];
        level.barricades[level.barricades.size] = ent;
        for (ii=0; ii<parts; ii++)
        {
            ent.parts[ii] =  ent getClosestEntity(ent.target + ii);
            ent.parts[ii].startPosition = ent.parts[ii].origin;
        }
        ent.maxhealth = health;
        ent.health = ent.maxhealth;
        ent.partsSize = parts;
        ent.deathFx = deathFx;
        ent.buildFx = buildFx;
        ent.occupied = false;
        ent.dropAll = dropAll;
        //ent thread zombiesurvival\_main::beBarricade();
    }*/
}
