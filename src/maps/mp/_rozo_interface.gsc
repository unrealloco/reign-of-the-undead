/******************************************************************************
 *    Reign of the Undead, v2.x
 *
 *    Copyright (c) 2010-2013 Reign of the Undead Team.
 *    See AUTHORS.txt for a listing.
 *
 *    Permission is hereby granted, free of charge, to any person obtaining a copy
 *    of this software and associated documentation files (the "Software"), to
 *    deal in the Software without restriction, including without limitation the
 *    rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 *    sell copies of the Software, and to permit persons to whom the Software is
 *    furnished to do so, subject to the following conditions:
 *
 *    The above copyright notice and this permission notice shall be included in
 *    all copies or substantial portions of the Software.
 *
 *    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *    SOFTWARE.
 *
 *    The contents of the end-game credits must be kept, and no modification of its
 *    appearance may have the effect of failing to give credit to the Reign of the
 *    Undead creators.
 *
 *    Some assets in this mod are owned by Activision/Infinity Ward, so any use of
 *    Reign of the Undead must also comply with Activision/Infinity Ward's modtools
 *    EULA.
 ******************************************************************************/
/// @file _rozo_interface.gsc An interface for loading ROZO map files in RotU

#include scripts\include\utility;
#include scripts\include\entities;
#include scripts\include\hud;
#include maps\mp\_zombiescript;
#include scripts\include\matrix;


/**
 * @brief Builds RotU shop and weapon upgrades where the ROZO map specified they should be
 *
 * @returns nothing
 */
placeShops(weapon, shop)
{
    debugPrint("in _rozo_interface::placeShops()", "fn", level.lowVerbosity);

    currentMap = getdvar("mapname");
    noticePrint("Map " + currentMap + " is a ROZO map, using _rozo_interface.gsc.");
    level.isRozoMap = true;

    // We need to force ROZO to waittillStart() or we can't create the usables
    waittillStart();

    weapons = strTok(weapon, " ");
    shops = strTok(shop, " ");

    for (i=0; i<weapons.size; i++) {
        tradespawn = level.tradespawns[int(weapons[i])];
//         noticePrint("weaponupgrade found origin: " + tradespawn.origin + " angles: " + tradespawn.angles);
        weaponupgrade = spawn("script_model", tradespawn.origin);
        if (isDefined(weaponupgrade)) {
            weaponupgrade.angles = tradespawn.angles;
            weaponupgrade setModel("com_plasticcase_green_big");
        }
        level scripts\players\_usables::addUsable(weaponupgrade, "ammobox", "Press [USE] to upgrade your weapon!", 96);
        createTeamObjpoint(tradespawn.origin + (0,0,72), "hud_weapons", 1);

        // spawn a solid trigger_radius to simulate xmodel actually being solid
        level.solid = spawn("trigger_radius", (0, 0, 0), 0, 18, 27 );
        level.solid.origin = tradespawn.origin;
        level.solid.angles = tradespawn.angles;
        level.solid setContents(1);
    }
    for (i=0; i<shops.size; i++) {
        tradespawn = level.tradespawns[int(shops[i])];
//         noticePrint("shop found origin: " + tradespawn.origin + " angles: " + tradespawn.angles);
        shop = spawn("script_model", tradespawn.origin);
        if (isDefined(shop)) {
            shop.angles = tradespawn.angles;
            shop setModel("ad_sodamachine");
        }

        pos = zeros(2,1);
        // 20.2 is approx. x-coord of 2-D centroid of xmodel, i.e. x bar
        setValue(pos,1,1,20.2);
        // 15.8 is approx. y-coord of 2-D centroid of xmodel, i.e. y bar.  Negative
        // sign is needed due to location of origin in the xmodel
        setValue(pos,2,1,-15.8);
        // phi is the angle the xmodel is rotated through
        phi = tradespawn.angles[1];
        // create standard rotation matrix
        A = eye(2);
        setValue(A,1,1,cos(phi));
        setValue(A,1,2,-1*sin(phi));
        setValue(A,2,1,sin(phi));
        setValue(A,2,2,cos(phi));
        // apply the rotation matrix
        R = matrixMultiply(A, pos);
        // now (x,y) hold the proper rotated position offset relative to tradespawn.origin
        x = value(R,1,1);
        y = value(R,2,1);
        level scripts\players\_usables::addUsable(shop, "extras", "Press [USE] to buy upgrades!", 96);
        createTeamObjpoint(tradespawn.origin + (x,y,85), "hud_ammo", 1);

        // spawn a solid trigger_radius to simulate xmodel actually being solid
        level.solid = spawn("trigger_radius", (0, 0, 0), 0, 22, 122 );
        level.solid.origin = tradespawn.origin + (x,y,0);
        level.solid.angles = tradespawn.angles;
        level.solid setContents(1);
    }
}

/**
 * @brief Converts ROZO zombie spawn points into RotU spawn points
 *
 * @returns nothing
 */
addDefaultZombieSpawns()
{
    debugPrint("in _rozo_interface::placeShops()", "fn", level.lowVerbosity);

    ents = getEntArray("mp_dm_spawn", "classname");
    for (i=0; i<ents.size; i++) {
        count = i + 1;
        // set targetname property of the spawnpoints so they work with RotU
        ents[i].targetname = "spawngroup"+count;
        buildSurvSpawn(ents[i].targetname, 1);
    }

    // Assuming addDefaultZombieSpawns() is the last call in the map's main *.gsc file,
    // start the waves
    startSurvWaves();
}

/**
 * @brief Converts ROZO waypoints into RotU waypoints
 *
 * @returns nothing
 */
convertWaypoints()
{
    debugPrint("in _rozo_interface::convertWaypoints()", "fn", level.lowVerbosity);

    level.Wp = [];
    level.WpCount = 0;

    level.WpCount = level.waypoints.size;
    // Add in all of the waypoints
    for (i=0; i<level.WpCount; i++) {
        waypoint = spawnstruct();
        level.Wp[i] = waypoint;

        waypoint.origin = level.waypoints[i].origin;
        waypoint.isLinking = false;
        waypoint.ID = i;
    }
    // Now link the waypoints
    for (i=0; i<level.WpCount; i++) {
        waypoint = level.Wp[i];
        waypoint.linkedCount = level.waypoints[i].childCount;
//         noticePrint("waypoint: " + i + " origin: " + waypoint.origin);
        for (j=0; j<waypoint.linkedCount; j++) {
            waypoint.linked[j] = level.Wp[level.waypoints[i].children[j]];
//             noticePrint("waypoint: " + i + " is linked to waypoint " + level.waypoints[i].children[j]);
        }
        // Error catching
        if (!isdefined(waypoint.linked)) {
            iprintlnbold("^1UNLINKED WAYPOINT: " + waypoint.ID + " AT: " +  waypoint.origin);
        }
    }

    // Now that the ROZO waypoints are in memory in RotU format, we can free the
    // memory used by the ROZO waypoints
    level.waypoints = [];
}
