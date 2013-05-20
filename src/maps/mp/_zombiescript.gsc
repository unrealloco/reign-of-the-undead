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

#include scripts\include\hud;
#include scripts\include\entities;
#include scripts\include\utility;
#include maps\mp\_rozo_interface;

// GENERAL SCRIPTS
setGameMode(mode)
{
    debugPrint("in _zombiescript::setGameMode()", "fn", level.lowVerbosity);

    level.gameMode = mode;

    waittillframeend;
}

setPlayerSpawns(targetname)
{
    debugPrint("in _zombiescript::setPlayerSpawns()", "fn", level.lowVerbosity);

    level.playerspawns = targetname;
}

setWorldVision(vision, transitiontime)
{
    debugPrint("in _zombiescript::setWorldVision()", "fn", level.lowVerbosity);

    visionSetNaked(vision, transitiontime);
    level.vision = vision;
}

buildParachutePickup(targetname)
{
    debugPrint("in _zombiescript::buildParachutePickup()", "fn", level.lowVerbosity);

    ents = getentarray(targetname, "targetname");
    //for (i=0; i<ents.size; i++)
    //ents[i] thread scripts\players\_parachute::parachutePickup();
}

buildWeaponPickup(targetname, itemtext, weapon, type)
{
    debugPrint("in _zombiescript::buildWeaponPickup()", "fn", level.lowVerbosity);

    LogPrint("In _zombiescript.gsc\n");
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
    debugPrint("in _zombiescript::buildAmmoStock()", "fn", level.nonVerbose);

    ents = getentarray(targetname, "targetname");
    noticePrint("Found " + ents.size + " of type 'ammostock', i.e. weapon upgrade");
    for (i=0; i<ents.size; i++) {
        ent = ents[i];
        ent.loadtime = loadtime;
        if (level.ammoStockType == "weapon") {
            level scripts\players\_usables::addUsable(ent, "ammobox", "Press [USE] for a weapon! (^1"+level.dvar["surv_waw_costs"]+"^7)", 96);
            createTeamObjpoint(ent.origin+(0,0,72), "hud_weapons", 1);
        }
        if (level.ammoStockType == "upgrade") {
            level scripts\players\_usables::addUsable(ent, "ammobox", "Press [USE] to upgrade your weapon!", 96);
            createTeamObjpoint(ent.origin+(0,0,72), "hud_weapons", 1);
        }
        if (level.ammoStockType == "ammo") {
            level scripts\players\_usables::addUsable(ent, "ammobox", "Hold [USE] to restock ammo", 96);
        }
    }
}

setWeaponHandling(id)
{
    debugPrint("in _zombiescript::setWeaponHandling()", "fn", level.lowVerbosity);

    level.onGiveWeapons = id;
}

setSpawnWeapons(primary, secondary)
{
    debugPrint("in _zombiescript::setSpawnWeapons()", "fn", level.lowVerbosity);

    level.spawnPrimary = primary;
    level.spawnSecondary = secondary;
}

// ONSLAUGHT MODE
/// @deprecated
beginZomSpawning()
{
    debugPrint("in _zombiescript::beginZomSpawning()", "fn", level.lowVerbosity);
    errorPrint(getdvar("mapname") + " calling the deprecated function _zombiescript::beginZomSpawning().\n");
    //scripts\gamemodes\_onslaught::startSpawning();
}

//SURVIVAL MODE
// Loading spawns for survival mode (incomming waves)
buildSurvSpawn(targetname, priority)
{
    debugPrint("in _zombiescript::buildSurvSpawn()", "fn", level.nonVerbose);

    scripts\gamemodes\_survival::addSpawn(targetname, priority);

}

// Weaponshop actually
buildWeaponUpgrade(targetname)
{
    debugPrint("in _zombiescript::buildWeaponUpgrade()", "fn", level.nonVerbose);

    ents = getentarray(targetname, "targetname");
    noticePrint("Found " + ents.size + " of type 'weaponupgrade', i.e. shop");
    for (i=0; i<ents.size; i++) {
        ent = ents[i];
        level scripts\players\_usables::addUsable(ent, "extras", "Press [USE] to buy upgrades!", 96);
        createTeamObjpoint(ent.origin+(0,0,72), "hud_ammo", 1);
    }
}

startSurvWaves()
{
    debugPrint("in _zombiescript::startSurvWaves()", "fn", level.nonVerbose);

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
    debugPrint("in _zombiescript::waittillStart()", "fn", level.nonVerbose);

    wait .5;

    scripts\gamemodes\_gamemodes::initGameMode();

    while (level.activePlayers == 0) {
        wait .5;
    }

    logPrint("Notice: Zombiescript: " + getdvar("mapname") + " is using _zombiescript.gsc.\n");
}

buildBarricade(targetname, parts, health, deathFx, buildFx, dropAll)
{
    debugPrint("in _zombiescript::buildBarricade()", "fn", level.lowVerbosity);

    if (!isdefined(dropAll)) {dropAll = false;}

    ents = getentarray(targetname, "targetname");
    for (i=0; i<ents.size; i++) {
        ent = ents[i];
        level.barricades[level.barricades.size] = ent;
        for (j=0; j<parts; j++) {
            ent.parts[j] = ent getClosestEntity(ent.target + j);
            /// @bug if the part isn't defined, try skipping this part
            if (!isDefined(ent.parts[j])) {
                logPrint("j: " + j + " jth part is not defined.\n");
            }
            ent.parts[j].startPosition = ent.parts[j].origin;
//             buildBarricade("staticbarricade", 4, 400, level.barricadefx,level.barricadefx);
        }
        ent.hp = int(health);
        ent.maxhp = int(health);;
        ent.partsSize = parts;
        ent.deathFx = deathFx;
        ent.buildFx = buildFx;
        ent.occupied = false;
        ent.dropAll = dropAll;
        ent thread scripts\players\_barricades::makeBarricade();
    }
}
