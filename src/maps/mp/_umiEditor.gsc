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
/**
 * @file _umiEditor.gsc This file runs the development menu and contains the UMI editing features
 */

#include scripts\include\array;
#include scripts\include\data;
#include scripts\include\entities;
#include scripts\include\hud;
#include scripts\include\matrix;
#include scripts\include\utility;

init()
{
    precacheMenu("development");

    // Used as default weapon/shop models when running ROZO maps
    precacheModel("ad_sodamachine");
    precacheModel("com_plasticcase_green_big");
    precacheModel("prop_flag_american"); // used for linked waypoints
    precacheModel("prop_flag_russian");  // used for unlinked waypoints
}

/**
 * @brief Initializes this use of the development menu
 *
 * @returns nothing
 */
onOpenDevMenu()
{
    debugPrint("in _umiEditor::onOpenDevMenu()", "fn", level.nonVerbose);

    if (scripts\server\_adminInterface::isAdmin(self)) {
//         self.admin.adminMenuOpen = true;
//         debugPrint("Enabling god mode for admin: " + self.admin.playerName, "val");
//         self.isGod = true;
//         self.god = true;
//         self.isTargetable = false;
//         showPlayerInfo();
    } else {
//         self closeMenu();
//         self closeInGameMenu();
//         warnPrint(self.name + " opened the admin menu, but we forced it closed.");
//         self thread ACPNotify( "You don't have permission to access this menu.", 3 );
//         return;
    }
}

/**
 * @brief Opens the in-game development menu if the player is recognized as an admin
 *
 * @returns nothing
 */
onOpenDevMenuRequest()
{
    debugPrint("in _umiEditor::onOpenDevMenuRequest()", "fn", level.nonVerbose);

    if (scripts\server\_adminInterface::isAdmin(self)) {
        self onOpenDevMenu();
        self openMenu(game["menu_development"]);
    }
}

/**
 * @brief Watches the development menu for commands, then processes them
 *
 * @returns nothing
 */
watchDevelopmentMenuResponses()
{
    debugPrint("in _umiEditor::watchDevelopmentMenuResponses()", "fn", level.nonVerbose);

    self endon( "disconnect" );
    // threaded on each admin player

    while (1) {
        self waittill( "menuresponse", menu, response );
        //         debugPrint("menu: " + menu + " response: " + response, "val");

        // menu "-1" is the main in-game popup menu bound to the 'b' key
        if ((menu == "-1") && (response == "dev_menu_open_request")) {
            self onOpenDevMenuRequest();
            continue;
        }

        // If menu isn't an admin menu, then bail
        if (menu != "development") {
            debugPrint("Menu is not the development menu.", "val"); // <debug />
            continue;
        }

        //         debugPrint("menu repsonse is: " + response, "val");
        switch(response)
        {
        /** Development */
        case "dev_give_equipment_shop":
            devGiveEquipmentShop();
            break;
        case "dev_give_weapon_shop":
            devGiveWeaponsShop();
            break;
        case "dev_delete_closest_tradespawn":
            devDeleteClosestShop();
            break;
        case "dev_save_tradespawns":
            devSaveTradespawns();
            break;
        case "dev_give_waypoints":
            devGiveWaypoint();
            break;
        case "dev_save_waypointss":
            devSaveWaypoints();
            break;
        default:
            // Do nothing
            break;
        } // end switch(response)
    } // End while(1)
}


/**
 * @brief UMI draws the waypoints on the map
 * @threaded
 *
 * works with playMod.bat with:
 * +set developer 1 +set developer_script 1 +set dedicated 0
 *
 * @returns nothing
 * @since RotU 2.2.1
 */
devDrawWaypoints()
{
    debugPrint("in _umiEditor::devDrawWaypoints()", "fn", level.nonVerbose);

    noticePrint("Map: Drawing waypoints requires +set developer 1 +set developer_script 1");

    // wait until someone is in the game to see the waypoints before we draw them
    while (level.activePlayers == 0) {
        wait 0.5;
    }

    devInitWaypointFlags();
    devFindUnlinkedWaypoints();
    thread devDrawWaypointLinks();
    thread devDrawWaypointHud();
}

devGiveWaypoint()
{
    debugPrint("in _umiEditor::devGiveWaypoint()", "fn", level.nonVerbose);

    flag = spawn("script_model", (0,0,0));
    flag setModel("prop_flag_russian");

    self.carryObj = flag;
    self.carryObj.origin = self.origin + AnglesToForward(self.angles)*40;

    self.carryObj.master = self;
    self.carryObj linkto(self);
    self.carryObj setcontents(2);

    level scripts\players\_usables::addUsable(flag, "waypoint", "Press [use] to pickup waypoint", 70);
    self.canUse = false;
    self disableweapons();
    self thread devEmplaceWaypoint();
}

devEmplaceWaypoint()
{
    debugPrint("in _umiEditor::devEmplaceWaypoint()", "fn", level.nonVerbose);

    while (1) {
        if (self attackbuttonpressed()) {
            // ensure flagpole bottom is on the ground
            a = self.carryObj.origin;
            result = bulletTrace(a + (0,0,50), a - (0,0,50), false, self.carryObj);
            self.carryObj.origin = result["position"];

            self.carryObj unlink();
            wait .05;
            self.canUse = true;
            self enableweapons();
            return;
        }
        wait 0.1;
    }
}

devMoveWaypoint(flag)
{
    debugPrint("in _umiEditor::devMoveWaypoint()", "fn", level.nonVerbose);

    self scripts\players\_usables::removeUsable(flag);

    self.carryObj = flag;
    self.carryObj.origin = self.origin + AnglesToForward(self.angles)*40;

    self.carryObj.master = self;
    self.carryObj linkto(self);
    self.carryObj setcontents(2);

    level scripts\players\_usables::addUsable(flag, "waypoint", "Press [use] to pickup waypoint", 70);
    self.canUse = false;
    self disableweapons();
    self thread devEmplaceWaypoint();
}

devSaveWaypoints()
{
    debugPrint("in _umiEditor::devSaveWaypoints()", "fn", level.nonVerbose);

}

devFindUnlinkedWaypoints()
{
    debugPrint("in _umiEditor::devFindUnlinkedWaypoints()", "fn", level.nonVerbose);

    level.unlinkedWaypoints = [];
    for (i=0; i<level.Wp.size; i++) {
        if (!isDefined(level.Wp[i].linked)) {
            level.unlinkedWaypoints[level.unlinkedWaypoints.size] = i;
        }
    }
    // If there are 20 or less unlinked waypoints, just flag them all
    if (level.unlinkedWaypoints.size <= 20) {
        for (i=0; i<level.unlinkedWaypoints.size; i++) {
            devUnflagWaypoint(level.unlinkedWaypoints[i]);
            devFlagWaypoint(level.unlinkedWaypoints[i]);
        }
    }
}

devDrawWaypointHud()
{
    debugPrint("in _umiEditor::devDrawWaypointHud()", "fn", level.nonVerbose);

    player = scripts\include\adminCommon::getPlayerByShortGuid(getDvar("admin_forced_guid"));

    // Set up HUD elements
    verticalOffset = 80;

    waypointIdHud = newClientHudElem(player);
    waypointIdHud.elemType = "font";
    waypointIdHud.font = "default";
    waypointIdHud.fontscale = 1.4;
    waypointIdHud.x = -16;
    waypointIdHud.y = verticalOffset;
    waypointIdHud.glowAlpha = 1;
    waypointIdHud.hideWhenInMenu = true;
    waypointIdHud.archived = false;
    waypointIdHud.alignX = "right";
    waypointIdHud.alignY = "middle";
    waypointIdHud.horzAlign = "right";
    waypointIdHud.vertAlign = "top";
    waypointIdHud.alpha = 1;
    waypointIdHud.glowColor = (0,0,1);
    waypointIdHud.label = &"ZOMBIE_WAYPOINT_ID";
    waypointIdHud setValue(0);

    playerXHud = newClientHudElem(player);
    playerXHud.elemType = "font";
    playerXHud.font = "default";
    playerXHud.fontscale = 1.4;
    playerXHud.x = -16;
    playerXHud.y = verticalOffset + 18*1;
    playerXHud.glowAlpha = 1;
    playerXHud.hideWhenInMenu = true;
    playerXHud.archived = false;
    playerXHud.alignX = "right";
    playerXHud.alignY = "middle";
    playerXHud.horzAlign = "right";
    playerXHud.vertAlign = "top";
    playerXHud.alpha = 1;
    playerXHud.glowColor = (0,0,1);
    playerXHud.label = &"ZOMBIE_PLAYER_X";
    playerXHud setValue(player.origin[0]);

    playerYHud = newClientHudElem(player);
    playerYHud.elemType = "font";
    playerYHud.font = "default";
    playerYHud.fontscale = 1.4;
    playerYHud.x = -16;
    playerYHud.y = verticalOffset + 18*2;
    playerYHud.glowAlpha = 1;
    playerYHud.hideWhenInMenu = true;
    playerYHud.archived = false;
    playerYHud.alignX = "right";
    playerYHud.alignY = "middle";
    playerYHud.horzAlign = "right";
    playerYHud.vertAlign = "top";
    playerYHud.alpha = 1;
    playerYHud.glowColor = (0,0,1);
    playerYHud.label = &"ZOMBIE_PLAYER_Y";
    playerYHud setValue(player.origin[1]);

    playerZHud = newClientHudElem(player);
    playerZHud.elemType = "font";
    playerZHud.font = "default";
    playerZHud.fontscale = 1.4;
    playerZHud.x = -16;
    playerZHud.y = verticalOffset + 18*3;
    playerZHud.glowAlpha = 1;
    playerZHud.hideWhenInMenu = true;
    playerZHud.archived = false;
    playerZHud.alignX = "right";
    playerZHud.alignY = "middle";
    playerZHud.horzAlign = "right";
    playerZHud.vertAlign = "top";
    playerZHud.alpha = 1;
    playerZHud.glowColor = (0,0,1);
    playerZHud.label = &"ZOMBIE_PLAYER_Z";
    playerZHud setValue(player.origin[2]);

    oldNearestWp = 0;
    while (1) {
        nearestWp = 0;
        closestWp = -1;
        nearestDistance = 9999999999;
        for (i=0; i<level.WpCount; i++) {
            distance = distancesquared(player.origin, level.Wp[i].origin);
            if(distance < nearestDistance) {
                nearestDistance = distance;
                nearestWp = i;
            }
            if (i == (level.WpCount - 1)) {
                closestWp = nearestWp;
            }
            //             location = player.origin + (vectorNormalize(anglesToForward(player.angles)) * 2000) - (0,0,20);
        }
        if (nearestWp != oldNearestWp) {
            player setClientDvar("dev_waypoint", nearestWp);
            player setClientDvar("dev_waypoint_link", "implement me");
            devUpdateWaypointMarkers(nearestWp, oldNearestWp);
            oldNearestWp = nearestWp;
            waypointIdHud setValue(nearestWp);
        }
        playerXHud setValue(player.origin[0]);
        playerYHud setValue(player.origin[1]);
        playerZHud setValue(player.origin[2]);
        wait 0.05;
    }
}

devUpdateWaypointMarkers(currentWaypointId, formerWaypointId)
{
    debugPrint("in _umiEditor::devUpdateWaypointMarkers()", "fn", level.nonVerbose);

    devUnflagWaypoint(formerWaypointId);
    for (i=0; i<level.Wp[formerWaypointId].linkedCount; i++) {
        devUnflagWaypoint(level.Wp[formerWaypointId].linked[i].ID);
    }

    devFlagWaypoint(currentWaypointId);
    for (i=0; i<level.Wp[currentWaypointId].linkedCount; i++) {
        devFlagWaypoint(level.Wp[currentWaypointId].linked[i].ID);
    }
}

devFlagWaypoint(waypointId)
{
    debugPrint("in _umiEditor::devFlagWaypoint()", "fn", level.nonVerbose);

    if (!isDefined(level.Wp[waypointId].linked)) {
        for (i=0; i<level.unlinkedWaypointFlags.size; i++) {
            if (level.unlinkedWaypointFlags[i].waypointId == -1) {
                level.unlinkedWaypointFlags[i].waypointId = waypointId;
                level.unlinkedWaypointFlags[i].origin = level.Wp[waypointId].origin;
                level.unlinkedWaypointFlags[i] show();
                return;
            }
        }
    } else {
        for (i=0; i<level.linkedWaypointFlags.size; i++) {
            flag = level.linkedWaypointFlags[i];
            if (flag.waypointId == -1) {
                flag.waypointId = waypointId;
                flag.origin = level.Wp[waypointId].origin;
                flag show();
                level scripts\players\_usables::addUsable(flag, "waypoint", "Press [use] to pickup waypoint", 70);
                return;
            }
        }
    }
}

devUnflagWaypoint(waypointId)
{
    debugPrint("in _umiEditor::devUnflagWaypoint()", "fn", level.nonVerbose);

    if (!isDefined(level.Wp[waypointId].linked)) {
        for (i=0; i<level.unlinkedWaypointFlags.size; i++) {
            if (level.unlinkedWaypointFlags[i].waypointId == waypointId) {
                level.unlinkedWaypointFlags[i].waypointId = -1;
                level.unlinkedWaypointFlags[i].origin = (0,0,-9999);
                level.unlinkedWaypointFlags[i] hide();
                return;
            }
        }
    } else {
        for (i=0; i<level.linkedWaypointFlags.size; i++) {
            flag = level.linkedWaypointFlags[i];
            if (flag.waypointId == waypointId) {
                flag.waypointId = -1;
                flag.origin = (0,0,-9999);
                flag hide();
                self scripts\players\_usables::removeUsable(flag);
                return;
            }
        }
    }
}

devInitWaypointFlags()
{
    debugPrint("in _umiEditor::devInitWaypointFlags()", "fn", level.nonVerbose);

    level.linkedWaypointFlags = [];
    for (i=0; i<10; i++) {
        flag = spawn("script_model", (0,0,-9999));
        flag.waypointId = -1;
        flag setModel("prop_flag_american");
        flag hide();
        level.linkedWaypointFlags[i] = flag;
    }
    level.unlinkedWaypointFlags = [];
    for (i=0; i<20; i++) {
        flag = spawn("script_model", (0,0,-9999));
        flag.waypointId = -1;
        flag setModel("prop_flag_russian");
        flag hide();
        level.unlinkedWaypointFlags[i] = flag;
    }
}

devDrawWaypointLinks()
{
    debugPrint("in _umiEditor::devDrawWaypointLinks()", "fn", level.nonVerbose);

    iPrintLnBold("Waypoint links are drawn 10 units above their origin for better visibility");

    // There aren't enough usable colors to ensure that every connected link is
    // a different color, so we just cycle through the colors--this seems to work
    // better than picking colors pseudo-randomly
    colors = [];
    colors[0] = decimalRgbToColor(255,0,0); // red
    colors[1] = decimalRgbToColor(255,128,0); // orange
    colors[2] = decimalRgbToColor(255,255,0); // yellow
    colors[3] = decimalRgbToColor(0,102,0); // forest green
    colors[4] = decimalRgbToColor(0,255,255); // cyan
    colors[5] = decimalRgbToColor(0,0,255); // blue
    colors[6] = decimalRgbToColor(128,0,255); // purple
    colors[7] = decimalRgbToColor(255,0,255); // fuschia
    colors[8] = decimalRgbToColor(255,0,128); // hot pink
    colors[9] = decimalRgbToColor(128,128,128); // grey
    colors[10] = decimalRgbToColor(102,51,0); // brown
    colors[11] = decimalRgbToColor(255,255,255); // white
    colors[12] = decimalRgbToColor(0,0,0); // black
    colors[13] = decimalRgbToColor(229,255,204); // pale green
    colors[14] = decimalRgbToColor(128,255,0); // bright green
    colors[15] = decimalRgbToColor(0,255,128); // aquamarine

    // Waypoints are doubly-linked; we only need to draw each link once, so build
    // an array of unique links
    level.waypointLinks = [];
    linkIndex = 0;
    for (i=0; i<level.WpCount; i++) {
        for (j=0; j<level.Wp[i].linkedCount; j++) {
            if (level.Wp[i].linked[j].ID > i) {
                // we need to link this waypoint
                link = spawnstruct();
                level.waypointLinks[linkIndex] = link;
                link.fromId = level.Wp[i].ID;
                link.toId = level.Wp[i].linked[j].ID;
                link.color = colors[linkIndex % colors.size];
                linkIndex++;
            }
        }
    }
    iPrintLnBold("Found " + level.waypointLinks.size + " unique waypoint links");

    while (1) {
        for (i=0; i<level.waypointLinks.size; i++) {
            //                 Line( <start>, <end>, <color>, <depthTest>, <duration> )
            from = level.Wp[level.waypointLinks[i].fromId].origin + (0,0,10);
            to = level.Wp[level.waypointLinks[i].toId].origin + (0,0,10);
            color = level.waypointLinks[i].color;
            line(from, to, color, false, 25);
        }
        wait 0.05;
    }
}

/**
* @brief UMI writes the player's current position to the server log
* Intended to help add/edit waypoints to maps lacking them.  Should be called
* from an admin command, or perhaps from a keybinding.
*
* @returns nothing
* @since RotU 2.2.1
*/
devRecordWaypoint()
{
    debugPrint("in _umiEditor::devRecordWaypoint()", "fn", level.nonVerbose);

    x = self.origin[0];
    y = self.origin[1];
    z = self.origin[2];

    msg = "Recorded waypoint: origin: ("+x+","+y+","+z+")";
    noticePrint(msg);
    iPrintLnBold(msg);
}

/**
* @brief UMI gives a player a weapons shop that they can emplace
*
* @returns nothing
* @since RotU 2.2.1
*/
devGiveEquipmentShop()
{
    debugPrint("in _umiEditor::devGiveEquipmentShop()", "fn", level.nonVerbose);

    if (!isDefined(level.devEquipmentShops)) {level.devEquipmentShops = [];}

    shop = spawn("script_model", (0,0,0));
    shop setModel("ad_sodamachine");
    level.devEquipmentShops[level.devEquipmentShops.size] = shop;

    self.carryObj = shop;
    // we intentionally pick it up off-center so the player can see where they
    // are going
    self.carryObj.origin = self.origin + AnglesToForward(self.angles)*80;

    self.carryObj.angles = self.angles + (0,-90,0);
    self.carryObj.master = self;
    self.carryObj linkto(self);
    self.carryObj setcontents(2);

    level scripts\players\_usables::addUsable(shop, "equipmentShop", "Press [use] to pickup equipment shop", 80);
    self.canUse = false;
    self disableweapons();
    self thread devEmplaceEquipmentShop();
}

/**
* @brief UMI emplaces an equipment shop a player is carrying
*
* @returns nothing
* @since RotU 2.2.1
*/
devEmplaceEquipmentShop()
{
    debugPrint("in _umiEditor::devEmplaceEquipmentShop()", "fn", level.nonVerbose);

    while (1) {
        if (self attackbuttonpressed()) {
            // self.carryObj.origin is the origin of xmodel's coord system, which
            // is the left rear base corner of the soda machine, which is about
            // 40.4 units wide and 31.6 units deep.

            // a, b, and c lie in the base plane of the model, b and c the front
            // left and right corners, respectively, and a bisects the rear face
            a = zeros(2,1);
            setValue(a,1,1,20.2);  // x
            setValue(a,2,1,0);     // y
            b = zeros(2,1);
            setValue(b,1,1,0);     // x
            setValue(b,2,1,-31.6); // y
            c = zeros(2,1);
            setValue(c,1,1,40.4);  // x
            setValue(c,2,1,-31.6); // y

            // d, e, and f are a, b, and c, repspectively, translated into world coordinates
            phi = self.carryObj.angles[1]; // phi is the angle the xmodel is rotated through

            R = eye(2);
            setValue(R,1,1,cos(phi));
            setValue(R,1,2,-1*sin(phi));
            setValue(R,2,1,sin(phi));
            setValue(R,2,2,cos(phi));

            // apply the rotation matrix
            dM = matrixMultiply(R, a);
            eM = matrixMultiply(R, b);
            fM = matrixMultiply(R, c);
            d = self.carryObj.origin + (value(dM,1,1),value(dM,2,1),0);
            e = self.carryObj.origin + (value(eM,1,1),value(eM,2,1),0);
            f = self.carryObj.origin + (value(fM,1,1),value(fM,2,1),0);

            // we trace 50 units above to 50 units below d, e, and f, and the trace
            // position will give us the points, g,h, and l above/below d,e, and f
            // that intersect the world surface
            result = bulletTrace(d + (0,0,100), d - (0,0,100), false, self.carryObj);
            g = result["position"];
            result = bulletTrace(e + (0,0,100), e - (0,0,100), false, self.carryObj);
            h = result["position"];
            result = bulletTrace(f + (0,0,100), f - (0,0,100), false, self.carryObj);
            l = result["position"];

            // now g, h, and l define a plane that approximates the local world surface,
            // so we find the surface normal
            hg = h - g; // h relative to g
            lg = l - g; // l relative to g

            s = zeros(3,1);
            setValue(s,1,1,hg[0]);  // x
            setValue(s,2,1,hg[1]);  // y
            setValue(s,3,1,hg[2]);  // z
            t = zeros(3,1);
            setValue(t,1,1,lg[0]);  // x
            setValue(t,2,1,lg[1]);  // y
            setValue(t,3,1,lg[2]);  // z
            normalM = matrixCross(s, t);

            // standard basis vectors in world coordinate system
            i = (1,0,0);
            j = (0,1,0);
            k = (0,0,1);

            // [i|j|k]Prime are the basis vectors for the rotated coordinate system
            kPrime = vectorNormalize((value(normalM,1,1), value(normalM,2,1), value(normalM,3,1)));
            iPrime = vectorNormalize(l-h);
            u = zeros(3,1);
            setValue(u,1,1,iPrime[0]);  // x
            setValue(u,2,1,iPrime[1]);  // y
            setValue(u,3,1,iPrime[2]);  // z
            jPrimeM = matrixCross(u, normalM);
            jPrime = vectorNormalize((value(jPrimeM,1,1), value(jPrimeM,2,1), value(jPrimeM,3,1)));

            // calculate the new origin (the left-rear corner of the re-positioned soda machine)
            newOrigin = h + (jPrime*-31.6);
            self.carryObj.origin = newOrigin;

            // align the soda machine's x-axis with the computed x-axis
            phi = scripts\players\_turrets::angleBetweenTwoVectors(k, kPrime*(0,1,1));
            self.carryObj.angles = vectorToAngles(iPrime);

            // now align the crate's y-axis with the computed y-axis
            z = anglesToUp(self.carryObj.angles);
            phi = scripts\players\_turrets::angleBetweenTwoVectors(z, kPrime);
            self.carryObj.angles = self.carryObj.angles + (0,0,phi); // phi rotates about x-axis

            // ensure we rotated the crate properly to align the y-axis
            y = anglesToRight(self.carryObj.angles);
            beta = scripts\players\_turrets::angleBetweenTwoVectors(y, jPrime);
            if (beta > phi) {
                // phi should have been negated!
                self.carryObj.angles = self.carryObj.angles + (0,0,-2*phi); // phi rotates about x-axis
            }

            self.carryObj unlink();
            wait .05;
            self.canUse = true;
            self enableweapons();
            return;
        }
        wait 0.1;
    }
}

/**
* @brief UMI draws a colored laser  at the location and direction specified
*
* @param color string The color of the laser: red, green, blue, white, yellow, magenta, cyan
* @param origin vector The location to place the laser
* @param direction vector the direction to shine the laser
*
* @returns nothing
* @since RotU 2.2.1
*/
devDrawLaser(color, origin, direction)
{
    debugPrint("in _umiEditor::devDrawLaser()", "fn", level.lowVerbosity);

    if (color == "red") {
        playFx(level.redLaserSight, origin, direction);
    } else if (color == "green") {
        playFx(level.greenLaserSight, origin, direction);
    } else if (color == "blue") {
        playFx(level.blueLaserSight, origin, direction);
    } else if (color == "white") {
        playFx(level.redLaserSight, origin, direction);
        playFx(level.greenLaserSight, origin, direction);
        playFx(level.blueLaserSight, origin, direction);
    } else if (color == "yellow") {
        playFx(level.redLaserSight, origin, direction);
        playFx(level.greenLaserSight, origin, direction);
    } else if (color == "magenta") {
        playFx(level.redLaserSight, origin, direction);
        playFx(level.blueLaserSight, origin, direction);
    } else if (color == "cyan") {
        playFx(level.greenLaserSight, origin, direction);
        playFx(level.blueLaserSight, origin, direction);
    }
}

/**
* @brief UMI emplaces a weapon shop a player is carrying
*
* @returns nothing
* @since RotU 2.2.1
*/
devEmplaceWeaponShop()
{
    debugPrint("in _umiEditor::devEmplaceWeaponShop()", "fn", level.nonVerbose);

    while (1) {
        if (self attackbuttonpressed()) {
            // a, b, and c lie in the base plane of the model, b and c the front
            // left and right corners, respectively, and a bisects the rear face
            a = zeros(2,1);
            setValue(a,1,1,0);   // x
            setValue(a,2,1,16);  // y
            b = zeros(2,1);
            setValue(b,1,1,-20); // x
            setValue(b,2,1,-16); // y
            c = zeros(2,1);
            setValue(c,1,1,20);  // x
            setValue(c,2,1,-16); // y

            // d, e, and f are a, b, and c, repspectively, translated into world coordinates
            phi = self.carryObj.angles[1]; // phi is the angle the xmodel is rotated through

            R = eye(2);
            setValue(R,1,1,cos(phi));
            setValue(R,1,2,-1*sin(phi));
            setValue(R,2,1,sin(phi));
            setValue(R,2,2,cos(phi));

            // apply the rotation matrix
            dM = matrixMultiply(R, a);
            eM = matrixMultiply(R, b);
            fM = matrixMultiply(R, c);
            d = self.carryObj.origin + (value(dM,1,1),value(dM,2,1),0);
            e = self.carryObj.origin + (value(eM,1,1),value(eM,2,1),0);
            f = self.carryObj.origin + (value(fM,1,1),value(fM,2,1),0);

            // we trace 50 units above to 100 units below d, e, and f, and the trace
            // position will give us the points, g, h, and l above/below d, e, and f
            // that intersect the world surface
            result = bulletTrace(d + (0,0,50), d - (0,0,100), false, self.carryObj);
            g = result["position"];
            result = bulletTrace(e + (0,0,50), e - (0,0,100), false, self.carryObj);
            h = result["position"];
            result = bulletTrace(f + (0,0,50), f - (0,0,100), false, self.carryObj);
            l = result["position"];

            // now g, h, and l define a plane that approximates the local world surface,
            // so we find the surface normal
            hg = h - g; // h relative to g
            lg = l - g; // l relative to g

            s = zeros(3,1);
            setValue(s,1,1,hg[0]);  // x
            setValue(s,2,1,hg[1]);  // y
            setValue(s,3,1,hg[2]);  // z
            t = zeros(3,1);
            setValue(t,1,1,lg[0]);  // x
            setValue(t,2,1,lg[1]);  // y
            setValue(t,3,1,lg[2]);  // z
            normalM = matrixCross(s, t);

            // standard basis vectors in world coordinate system
            i = (1,0,0);
            j = (0,1,0);
            k = (0,0,1);

            // [i|j|k]Prime are the basis vectors for the rotated coordinate system
            kPrime = vectorNormalize((value(normalM,1,1), value(normalM,2,1), value(normalM,3,1)));
            iPrime = vectorNormalize(l-h);
            u = zeros(3,1);
            setValue(u,1,1,iPrime[0]);  // x
            setValue(u,2,1,iPrime[1]);  // y
            setValue(u,3,1,iPrime[2]);  // z
            jPrimeM = matrixCross(u, normalM);
            jPrime = vectorNormalize((value(jPrimeM,1,1), value(jPrimeM,2,1), value(jPrimeM,3,1)));

            // calculate the new origin (the center of the re-positioned crate)
            newOrigin = h + (jPrime*-31.6);
            midpoint = h + ((l-h) * 0.5);
            newOrigin = midpoint + ((g-midpoint) * 0.5);
            self.carryObj.origin = newOrigin;

            // align the crate's x-axis with the computed x-axis
            phi = scripts\players\_turrets::angleBetweenTwoVectors(k, kPrime*(0,1,1));
            self.carryObj.angles = vectorToAngles(iPrime);

            // now align the crate's y-axis with the computed y-axis
            z = anglesToUp(self.carryObj.angles);
            phi = scripts\players\_turrets::angleBetweenTwoVectors(z, kPrime);
            self.carryObj.angles = self.carryObj.angles + (0,0,phi); // phi rotates about x-axis

            // ensure we rotated the crate properly to align the y-axis
            y = anglesToRight(self.carryObj.angles);
            beta = scripts\players\_turrets::angleBetweenTwoVectors(y, jPrime);
            if (beta > phi) {
                // phi should have been negated!
                self.carryObj.angles = self.carryObj.angles + (0,0,-2*phi); // phi rotates about x-axis
            }

            self.carryObj unlink();
            wait .05;
            self.canUse = true;
            self enableweapons();
            return;
        }
        wait 0.1;
    }
}


/**
* @brief UMI permits a player pick up and move am equipment shop
*
* @param shop entity The shop to pick up
*
* @returns nothing
* @since RotU 2.2.1
*/
devMoveEquipmentShop(shop)
{
    debugPrint("in _umiEditor::devMoveEquipmentShop()", "fn", level.nonVerbose);

    self scripts\players\_usables::removeUsable(shop);

    self.carryObj = shop;
    self.carryObj.origin = self.origin + AnglesToForward(self.angles)*80;
    self.carryObj.angles = self.angles + (0,-90,0);
    self.carryObj.master = self;
    self.carryObj linkto(self);
    self.carryObj setcontents(2);

    level scripts\players\_usables::addUsable(shop, "equipmentShop", "Press [use] to pickup equipment shop", 80);
    self.canUse = false;
    self disableweapons();
    self thread devEmplaceEquipmentShop();
}

/**
* @brief UIM permits a player pick up and move a weapon shop
*
* @param shop entity The shop to pick up
*
* @returns nothing
* @since RotU 2.2.1
*/
devMoveWeaponShop(shop)
{
    debugPrint("in _umiEditor::devMoveWeaponShop()", "fn", level.nonVerbose);

    self scripts\players\_usables::removeUsable(shop);

    self.carryObj = shop;
    self.carryObj.origin = self.origin + AnglesToForward(self.angles)*80;
    self.carryObj.angles = self.angles + (0,-90,0);
    self.carryObj.master = self;
    self.carryObj linkto(self);
    self.carryObj setcontents(2);

    level scripts\players\_usables::addUsable(shop, "weaponsShop", "Press [use] to pickup weapon shop", 80);
    self.canUse = false;
    self disableweapons();
    self thread devEmplaceWeaponShop();
}

/**
* @brief UMI gives a player a weapons shop that they can emplace
*
* @returns nothing
* @since RotU 2.2.1
*/
devGiveWeaponsShop()
{
    debugPrint("in _umiEditor::devGiveWeaponsShop()", "fn", level.nonVerbose);

    if (!isDefined(level.devWeaponShops)) {level.devWeaponShops = [];}

    shop = spawn("script_model", (0,0,0));
    shop setModel("com_plasticcase_green_big");
    level.devWeaponShops[level.devWeaponShops.size] = shop;

    self.carryObj = shop;
    self.carryObj.origin = self.origin + AnglesToForward(self.angles)*80;

    self.carryObj.angles = self.angles + (0,-90,0);
    self.carryObj.master = self;
    self.carryObj linkto(self);
    self.carryObj setcontents(2);

    level scripts\players\_usables::addUsable(shop, "weaponsShop", "Press [use] to pickup weapon shop", 80);
    self.canUse = false;
    self disableweapons();
    self thread devEmplaceWeaponShop();
}

/**
* @brief UMI deletes the shop closest to the player
*
* @returns nothing
* @since RotU 2.2.1
*/
devDeleteClosestShop()
{
    debugPrint("in _umiEditor::devDeleteClosestShop()", "fn", level.nonVerbose);

    // Find closest equipment shop
    closestEquipmentDistance = 999999;
    closestEquipmentShopIndex = -1;
    if (isDefined(level.devEquipmentShops)) {
        noticePrint("Pre level.devEquipmentShops.size: " + level.devEquipmentShops.size);
        for (i=0; i<level.devEquipmentShops.size; i++) {
            distanceProxy = distanceSquared(self.origin, level.devEquipmentShops[i].origin);
            if (distanceProxy < closestEquipmentDistance) {
                closestEquipmentDistance = distanceProxy;
                closestEquipmentShopIndex = i;
            }
        }
    }

    // Find closest weapon shop
    closestWeaponDistance = 999999;
    closestWeaponShopIndex = -1;
    if (isDefined(level.devWeaponShops)) {
        noticePrint("Pre level.devWeaponShops.size: " + level.devWeaponShops.size);
        for (i=0; i<level.devWeaponShops.size; i++) {
            distanceProxy = distanceSquared(self.origin, level.devWeaponShops[i].origin);
            if (distanceProxy < closestWeaponDistance) {
                closestWeaponDistance = distanceProxy;
                closestWeaponShopIndex = i;
            }
        }
    }

    // Delete the closest shop
    if (closestEquipmentDistance < closestWeaponDistance) {
        // delete equipment shop
        level scripts\players\_usables::removeUsable(level.devEquipmentShops[closestEquipmentShopIndex]);
        level.devEquipmentShops[closestEquipmentShopIndex] delete();
        level.devEquipmentShops = removeElementByIndex(level.devEquipmentShops, closestEquipmentShopIndex);
        noticePrint("Post level.devEquipmentShops.size: " + level.devEquipmentShops.size);
    } else {
        // delete weapon shop
        level scripts\players\_usables::removeUsable(level.devWeaponShops[closestWeaponShopIndex]);
        level.devWeaponShops[closestWeaponShopIndex] delete();
        level.devWeaponShops = removeElementByIndex(level.devWeaponShops, closestWeaponShopIndex);
        noticePrint("Post level.devWeaponShops.size: " + level.devWeaponShops.size);
    }

}

/**
* @brief UMI writes a tradespawn file to the server log
*
* @returns nothing
* @since RotU 2.2.1
*/
devSaveTradespawns()
{
    debugPrint("in _umiEditor::devSaveTradespawns()", "fn", level.nonVerbose);

    if (level.devWeaponShops.size != level.devEquipmentShops.size) {
        msg = "Map: You must have an equal number of weapon and equipment shops!";
        errorPrint(msg);
        iPrintLnBold(msg);
        return;
    }

    mapName =  tolower(getdvar("mapname"));
    logPrint("// =============================================================================\n");
    logPrint("// File Name = '"+mapname+"_tradespawns.gsc'\n");
    logPrint("// Map Name = '"+mapname+"'\n");
    logPrint("// =============================================================================\n");
    logPrint("//\n");
    logPrint("// This file was generated by the RotU admin development command 'Save Tradespawns'\n");
    logPrint("//\n");
    logPrint("// =============================================================================\n");
    logPrint("//\n");
    logPrint("// This file contains the tradespawns (equipment & weapon shop locations) for\n");
    logPrint("// the map '" + mapName + "'\n");
    logPrint("//\n");
    logPrint("// N.B. You will need to delete the timecodes at the beginning of these lines!\n");
    logPrint("//\n");

    logPrint("load_tradespawns()\n");
    logPrint("{\n");
    logPrint("    level.tradespawns = [];\n");
    logPrint("    \n");

    count = level.devWeaponShops.size + level.devEquipmentShops.size;
    shop = "";
    type = "";
    for (i=0; i<count; i++) {
        modulo = i % 2;
        if (modulo == 0) {
            // even-numbered index, traditionally used for weapon shops
            shop = level.devWeaponShops[int(i / 2)];
            type = "weapon";
        } else {
            // odd-numbered index, traditionally used for equipment shops
            shop = level.devEquipmentShops[int((i - 1) / 2)];
            type = "equipment";
        }

        x = shop.origin[0];
        y = shop.origin[1];
        z = shop.origin[2];
        rho = shop.angles[0];
        phi = shop.angles[1];

        logPrint("    level.tradespawns["+i+"] = spawnstruct();  // spec'd for "+type+" shop\n");
        logPrint("    level.tradespawns["+i+"].origin = ("+x+","+y+","+z+");\n");
        logPrint("    level.tradespawns["+i+"].angles = ("+rho+","+phi+",0);\n");
    }

    logPrint("    \n");
    logPrint("    level.tradeSpawnCount = level.tradespawns.size;\n");
    logPrint("}\n");

    iPrintLnBold("Tradespawn data written to the server log.");
}

/**
* @brief UMI writes entities with defined classname and/or targetname properties to the server log
*
* @returns nothing
* @since RotU 2.2.1
*/
devDumpEntities()
{
    debugPrint("in _umiEditor::devDumpEntities()", "fn", level.nonVerbose);

    ents = getentarray();
    for (i=0; i<ents.size; i++) {
        classname = "";
        targetname = "";
        origin = "";
        if (isDefined(ents[i].classname)) {classname = ents[i].classname;}
        if (isDefined(ents[i].targetname)) {targetname = ents[i].targetname;}
        if (isDefined(ents[i].origin)) {origin = ents[i].origin;}
        noticePrint("Entity: "+i+" classname: "+classname+" targetname: "+targetname+" origin: "+origin);
    }
}
