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

#include common_scripts\rotu;
#include scripts\include\utility;

// GAMETYPES
setGameMode(mode)
{
    debugPrint("in _zombiescript2::setGameMode()", "fn", level.lowVerbosity);

    level.gameMode = mode;
}

setPlayerSpawns(targetname)
{
    debugPrint("in _zombiescript2::setPlayerSpawns()", "fn", level.lowVerbosity);

    level.playerspawns = targetname;
}

// OTHER

setWorldVision(vision, transitiontime)
{
    debugPrint("in _zombiescript2::setWorldVision()", "fn", level.lowVerbosity);

    visionSetNaked( vision, transitiontime );
    level.vision = vision;
}

//SCRIPTED

setZomSpawnInfo(targetname, target, idlebehavior)
{
    debugPrint("in _zombiescript2::setZomSpawnInfo()", "fn", level.lowVerbosity);

    level.zomSpawns = targetname;
    level.zomTarget = target;
    level.zomIdleBehavior = idlebehavior;
}

beginZomSpawning()
{
    debugPrint("in _zombiescript2::beginZomSpawning()", "fn", level.lowVerbosity);

    thread maps\mp\gametypes\_gamemodes::beginZomSpawning();
}

endZomSpawning()
{
    debugPrint("in _zombiescript2::endZomSpawning()", "fn", level.lowVerbosity);

    maps\mp\gametypes\_gamemodes::endZomSpawning();
}

deleteBlocker(targetname)
{
    debugPrint("in _zombiescript2::deleteBlocker()", "fn", level.lowVerbosity);

    blockers = getentarray(targetname, "targetname");
    for (i=0; i<blockers.size; i++) {
        blockers[i] delete();
    }
}

killAllBots()
{
    debugPrint("in _zombiescript2::killAllBots()", "fn", level.lowVerbosity);

    for (i=0; i<level.bots.size; i++) {
        bot = level.bots[i];
        if (isalive(bot)) {bot suicide();}
    }
}

victory()
{
    debugPrint("in _zombiescript2::victory()", "fn", level.lowVerbosity);

    thread maps\mp\gametypes\war::endMap("Victory!");
}

addObjRadio(objectivename, targetname, time)
{
    debugPrint("in _zombiescript2::addObjRadio()", "fn", level.lowVerbosity);

    entity = getentarray(targetname, "targetname")[0];
    myID = level.objectives;
    objective_add(myID, "active", entity.origin);
    objective_icon(myID, "compass_waypoint_bomb");
    level.objectives++;

    entity.myID = myID;
    entity.time = time;
    level addUsable(entity, "obj_radio", "Press [USE] to place the radio", 256);
    entity.shader = create3DShader(entity.origin + (0,0,94), "waypoint_target", 8, 8);
    entity.objectivename = objectivename;
}

addObjIncomming(objectivename, triggername, spawns, zombiespp)
{
    debugPrint("in _zombiescript2::addObjIncomming()", "fn", level.lowVerbosity);

    trigger = getentarray(triggername, "targetname")[0];
    level.objectives++;

    trigger.objectivename = objectivename;
    trigger.spawns = spawns;
    trigger.zombiespp = zombiespp;
    thread maps\mp\gametypes\_gamemodes::objIncomming(trigger);
}

addObjDefend(objectivename, defencename, health, time)
{
    debugPrint("in _zombiescript2::addObjDefend()", "fn", level.lowVerbosity);

    def_objs = getentarray(defencename, "targetname");
    for (i=0; i<def_objs.size; i++) {
        obj = def_objs[i];
        obj.myID = level.objectives;
        obj.health = health;
        objective_add(obj.myID, "active", obj.origin);
        objective_icon(obj.myID, "compass_waypoint_defend");
        level.objectives ++;
        addAttackable(obj);
        obj thread maps\mp\gametypes\_gamemodes::defenceObj();
        obj.enabled = true;
    }
    thread maps\mp\gametypes\_gamemodes::objDefence(objectivename, def_objs.size, time);
}

timeout(text, seconds)
{
    debugPrint("in _zombiescript2::timeout()", "fn", level.lowVerbosity);

    level.prepare_text = NewHudElem();
    level.prepare_text.font = "objective";
    level.prepare_text.fontScale = 1.6;
    level.prepare_text SetText(text);
    level.prepare_text.alignX = "center";
    level.prepare_text.alignY = "top";
    level.prepare_text.horzAlign = "center";
    level.prepare_text.vertAlign = "top";
    level.prepare_text.x = 0;
    level.prepare_text.y = 64;
    level.prepare_text.sort = -3; //-3
    level.prepare_text.alpha = 1;
    level.prepare_text setPulseFX(100, int(2000 + seconds * 1000), 1000);

    wait 2;

    level.prepare_count = NewHudElem(); //newClientHudElem();
    //level.start_countdown.elemType = "timer";
    level.prepare_count.font = "objective";
    level.prepare_count.fontScale = 1.6;
    level.prepare_count SetTimer(seconds);
    level.prepare_count.alignX = "center";
    level.prepare_count.alignY = "top";
    level.prepare_count.horzAlign = "center";
    level.prepare_count.vertAlign = "top";
    level.prepare_count.x = 0;
    level.prepare_count.y = 88;
    level.prepare_count.sort = -3; //-3
    level.prepare_count.alpha = 1;

    wait seconds;

    level.prepare_text destroy();
    level.prepare_count destroy();
}

buildParachutePickup(targetname)
{
    debugPrint("in _zombiescript2::buildParachutePickup()", "fn", level.lowVerbosity);

    ents = getentarray(targetname, "targetname");
    for (i=0; i<ents.size; i++) {
        ents[i] thread parachutePickup();
    }
}

parachutePickup()
{
    debugPrint("in _zombiescript2::parachutePickup()", "fn", level.lowVerbosity);

    while (1) {
        self waittill ("trigger", player);
        if (!player.isBot) {
            if (!player.hasParachute) {
                player.hasParachute = true;
                player giveWeapon( "helicopter_mp" );
                player giveMaxAmmo( "helicopter_mp" );
                player setActionSlot(4, "weapon", "helicopter_mp");
                //wait .05;
                //player maps\mp\gametypes\_players::updateActionSlots();
            }
        }
    }
}

waittillObjEnd(objectivename)
{
    debugPrint("in _zombiescript2::waittillObjEnd()", "fn", level.lowVerbosity);

    level waittill(objectivename + "_end");
}

setZombieSpawns(targetname)
{
    debugPrint("in _zombiescript2::setZombieSpawns()", "fn", level.lowVerbosity);

    level.zombiespawns = targetname;
}

buildWeaponPickup(targetname, itemtext, weapon, type)
{
    debugPrint("in _zombiescript2::buildWeaponPickup()", "fn", level.lowVerbosity);

    ents = getentarray(targetname, "targetname");
    for (i=0; i<ents.size; i++) {
        ent = ents[i];
        ent.myWeapon = weapon;
        ent.wep_type = type;
        addUsable(ent, "weaponpickup", "Press [USE] to pick up " + itemtext, 96);
    }
}

buildAmmoBox(targetname, loadtime)
{
    debugPrint("in _zombiescript2::buildAmmoBox()", "fn", level.lowVerbosity);

    ents = getentarray(targetname, "targetname");
    for (i=0; i<ents.size; i++) {
        ent = ents[i];
        ent.loadtime = loadtime;
        addUsable(ent, "ammobox", "Hold [USE] to restock ammo", 96);
    }
}

precacheObjectives()
{
    debugPrint("in _zombiescript2::precacheObjectives()", "fn", level.lowVerbosity);

    precacheshader("compass_waypoint_bomb");
    precacheshader("waypoint_bomb");
    precacheShader("waypoint_target");
    precacheShader("waypoint_defend");
    precacheShader("compass_waypoint_defend");
    precachemodel("com_transistor_radio");
    level._effect["bombexplosion"] = loadfx("explosions/tanker_explosion");
}

setWeaponHandling(id)
{
    debugPrint("in _zombiescript2::setWeaponHandling()", "fn", level.lowVerbosity);

    level.onGiveWeapons = id;
}

setSpawnWeapons(primary, secondary)
{
    debugPrint("in _zombiescript2::setSpawnWeapons()", "fn", level.lowVerbosity);

    level.spawnPrimary = primary;
    level.spawnSecondary = secondary;
}

//SURVIVAL MODE
// Loading spawns for survival mode (incomming waves)
buildSurvSpawn(targetname, priority)
{
    debugPrint("in _zombiescript2::buildSurvSpawn()", "fn", level.lowVerbosity);

    if (!isDefined(level.survSpawns)) {return -1;}

    if (!isDefined(priority)) {priority = 1;}

    spawns = getentarray(targetname, "targetname");

    if (spawns.size > 0) {
        i = level.survSpawns.size;
        level.survSpawnsPriority[i] = priority;
        level.survSpawnsTotalPriority = level.survSpawnsTotalPriority + priority;
        level.survSpawns[i] = targetname;
    }
}

// Weaponshop actually
/// @deprecated
buildWeaponUpgrade(targetname)
{
    debugPrint("in _zombiescript2::buildWeaponUpgrade()", "fn", level.lowVerbosity);
    errorPrint(getdvar("mapname") + " calling the deprecated function _zombiescript2::buildWeaponUpgrade().\n");

    /*ents = getentarray(targetname, "targetname");
    for (i=0; i<ents.size; i++)
    {
        maps\mp\gametypes\_objpoints::createTeamObjpoint("weaponstock", ents[i].origin + (0,0,72), "allies", "hud_weapons", .8, 4);
        ents[i].hintString = "Press [USE] to upgrade your weapon";
        ents[i].type = "weapon";
        ents[i].enabled = 1;
        ents[i].occupied = false;
        level.usableObj[level.usableObj.size] = ents[i];
    }*/
}

/// @deprecated
startSurvWaves()
{
    debugPrint("in _zombiescript2::startSurvWaves()", "fn", level.lowVerbosity);
    errorPrint(getdvar("mapname") + " calling the deprecated function _zombiescript2::startSurvWaves().\n");

    //maps\mp\gametypes\_gamemodes::beginSurvivalMode();
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
    debugPrint("in _zombiescript2::waittillStart()", "fn", level.lowVerbosity);

    wait 1;

    while (level.activePlayers == 0) {
        wait 0.5;
    }

    maps\mp\gametypes\_gamemodes::initGameMode();

    logPrint("Notice: Zombiescript: " + getdvar("mapname") + " is using _zombiescript2.gsc.\n");
}

buildBarricade(targetname, parts, health, deathFx, buildFx, dropAll)
{
    debugPrint("in _zombiescript2::buildBarricade()", "fn", level.lowVerbosity);

    if (!isDefined(dropAll)) {dropAll = false;}
    ents = getentarray(targetname, "targetname");
    for (i=0; i<ents.size; i++) {
        ent = ents[i];
        level.barricades[level.barricades.size] = ent;
        for (j=0; j<parts; j++) {
            ent.parts[j] =  ent getClosestEntity(ent.target + j);
            ent.parts[j].startPosition = ent.parts[j].origin;
        }
        ent.maxhealth = health;
        ent.health = ent.maxhealth;
        ent.partsSize = parts;
        ent.deathFx = deathFx;
        ent.buildFx = buildFx;
        ent.occupied = false;
        ent.dropAll = dropAll;
        //ent thread zombiesurvival\_main::beBarricade();
    }
}

//Can be used in map gsc
/// @deprecated
buildAmmoStock(targetname, loadTime)
{
    debugPrint("in _zombiescript2::buildAmmoStock()", "fn", level.lowVerbosity);
    errorPrint(getdvar("mapname") + " calling the deprecated function _zombiescript2::buildAmmoStock().\n");

    /*if (!isdefined(loadTime))
    loadTime = 4;
    ents = getentarray(targetname, "targetname");
    for (i=0; i<ents.size; i++)
    {
        ents[i].loadTime = loadTime;
        ents[i].hintString = "Hold [USE] for ammo";
        ents[i].type = "ammo";
        ents[i].enabled = 1;
        ents[i].occupied = false;
        level.usableObj[level.usableObj.size] = ents[i];
        maps\mp\gametypes\_objpoints::createTeamObjpoint("ammostock", ents[i].origin + (0,0,72), "allies", "hud_ammo", .8, 4);
    }*/
}
