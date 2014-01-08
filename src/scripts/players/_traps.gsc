/******************************************************************************
    Reign of the Undead, v2.x

    Copyright (c) 2010-2014 Reign of the Undead Team.
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

init()
{
    debugPrint("in _traps::init()", "fn", level.nonVerbose);

    if (isDefined(level.mapTraps)) {
        for (i=0; i<level.mapTraps.size; i++) {
            trap = level.mapTraps[i];
            hintString = "Press [USE] to activate the " + trap.text + " trap! (^1" + trap.cost + "^7)";
            level scripts\players\_usables::addUsable(trap.trigger, "trap", hintString, 96);
            if (trap.type == "central") {scripts\players\_traps::centralTrapBat();}
        }
        noticePrint("level.mapTraps.size: " + level.mapTraps.size);
    }
}

/**
 * @brief Starts a trap
 *
 * @param trap struct The trap to start
 *
 * @returns nothing
 * @since RotU 2.2.3
 */
startTrap(trap)
{
    debugPrint("in _traps::startTrap()", "fn", level.nonVerbose);

    // self is activating player

    trap.isBeingUsed = true;
    switch (trap.type) {
        case "central":
            self centralTrap(trap);
            break;
        case "rotating":
            self rotatingTrap(trap);
            break;
        case "spike":
            self spikeTrap(trap);
            break;
        case "fire":
            self fireTrap(trap);
            break;
        case "electric":
            self electricTrap(trap);
            break;
    }
    trap.isBeingUsed = false;
}

/**
 * @brief Kills zombies when they trigger an active trap
 *
 * @param activatingPlayer entity The player that activated the trap
 *
 * @returns nothing
 * @since RotU 2.2.3
 */
watchTrap(activatingPlayer)
{
    debugPrint("in _traps::watchTrap()", "fn", level.nonVerbose);

    // self is the trap
    activatingPlayer endon("disconnect");

    doDamage = false;

    while (isDefined(self.killTrigger)) {
        self.killTrigger waittill("trigger", triggeringEntity);

        if (!triggeringEntity.isBot) {
            if (triggeringEntity.isZombie) {
                // traps kill player-zombies
                doDamage = true;
            } else {
                wait 0.05;
                continue;
            }
        } else if ((triggeringEntity.type != "boss") &&
                   (triggeringEntity.type != "many_bosses") &&
                   (triggeringEntity.type != "cyclops"))
        {
            // traps damage all bots except bosses and cyclops
            doDamage = true;
        }

        if (doDamage) {
            if (triggeringEntity.isBot) {
                // suicide() sets the parameters to _bot::killed() wrong, so we just
                // ensure we do enough damage to kill the bot
                iDamage = triggeringEntity.maxHealth + 200;
                triggeringEntity thread scripts\bots\_bots::Callback_BotDamage(self.trigger, activatingPlayer, iDamage, 0, "MOD_MELEE", self.type, (0,0,0), (0,0,0), "head", 0);
            } else {
                iDamage = triggeringEntity.maxHealth + 200;
                triggeringEntity thread scripts\players\_players::onPlayerDamage(self.trigger, activatingPlayer, iDamage, 0, "MOD_MELEE", self.type, (0,0,0), (0,0,0), "head", 0);
            }
            doDamage = false;
        }
    }
}

/**
 * @brief Better compile reflections for central type trap
 *
 * @returns nothing
 * @since RotU 2.2.3
 */
centralTrapBat()
{
    debugPrint("in _traps::centralTrapBat()", "fn", level.nonVerbose);

    brush1 = getEnt("bat", "targetname");
    brush1 moveZ(-80, 1);
}

/**
 * @brief Controller for a central trap
 *
 * @param trap struct The central trap to run
 *
 * @returns nothing
 * @since RotU 2.2.3
 */
centralTrap(trap)
{
    debugPrint("in _traps::centralTrap()", "fn", level.nonVerbose);

    // self is activating player
    brush1 = getEnt("bat", "targetname");
    brush2 = getEnt("prsten", "targetname");
    brush3 = getEnt("aktiv", "targetname");

    brush3 PlaySound("shild_on");
    brush3 moveZ(-10, 1);
    brush1 moveZ(72, 1);
    wait 5;
    brush1 rotateYaw(10800, 30);
    brush2 rotateYaw(10800, 30);
    brush2 playLoopSound("rot_efekt");
    trap.killTrigger = spawn("trigger_radius", brush1.origin, 0, 172, 172);
    trap thread watchTrap(self);
    wait 25;
    brush2 StopLoopSound();
    wait 10;

    trap.killTrigger = undefined;
    brush3 moveZ(10, 1);
    brush1 moveZ(-72, 1);
    brush3 PlaySound("shild_off");
    wait 2;
}

/**
 * @brief Controller for a rotating trap
 *
 * @param trap struct The central trap to run
 *
 * @returns nothing
 * @since RotU 2.2.3
 */
rotatingTrap(trap)
{
    debugPrint("in _traps::rotatingTrap()", "fn", level.nonVerbose);

    brush1 = getEnt("rot_dio", "targetname");
    brush2 = getEnt("aktiv2", "targetname");

    brush2 PlaySound("shild_on");

    brush2 moveZ(-12, 1);
    wait 1;
    brush1 playLoopSound("rattle");
    wait 0.1;
    trap.killTrigger = spawn("trigger_radius", brush1.origin, 0, 250, 128);
    trap thread watchTrap(self);
    brush1 rotatePitch(7200, 20);

    wait 20;

    brush1 StopLoopSound();
    wait 0.1;
    trap.killTrigger = undefined;
    brush2 PlaySound("shild_off");
    brush2 moveZ(12, 1);
    wait 1;
}

/**
 * @brief Controller for a spike trap
 *
 * @param trap struct The central trap to run
 *
 * @returns nothing
 * @since RotU 2.2.3
 */
spikeTrap(trap)
{
    debugPrint("in _traps::spikeTrap()", "fn", level.nonVerbose);

    brush1 = getEnt("trap3", "targetname");
    brush2 = getEnt("aktiv3", "targetname");

    brush2 PlaySound("shild_on");

    brush2 moveZ(-12, 1);
    wait 1;

    for (i=0; i<10; i++) {
        brush1 PlaySound("pneumatic");
        brush1 moveZ(32, 1);
        trap.killTrigger = spawn("trigger_radius", brush1.origin, 0, 70, 70);
        trap thread watchTrap(self);
        wait 2;
        brush1 moveZ(-32, 1);
        trap.killTrigger = undefined;
        wait 2;
    }

    brush2 PlaySound("shild_off");
    brush2 moveZ(12, 1);
    wait 1;
}

/**
 * @brief Controller for a fire trap
 *
 * @param trap struct The central trap to run
 *
 * @returns nothing
 * @since RotU 2.2.3
 */
fireTrap(trap)
{
    debugPrint("in _traps::fireTrap()", "fn", level.nonVerbose);

    fire1 = getent ("vatra1" ,"targetname"); //origin1
    fire2 = getent ("vatra2" ,"targetname"); //origin2
    fire3 = getent ("vatra3" ,"targetname"); //origin3
    fire4 = getent ("vatra4" ,"targetname"); //origin4
    brush1 = getEnt( "brush_death", "targetname" );
    brush2 = getEnt( "aktiv_trap4", "targetname" );

    brush2 PlaySound("shild_on");

    brush2 rotateYaw(360, 1);
    wait 1;

    trap.killTrigger = spawn("trigger_radius", brush1.origin, 0, 32, 32);
    trap thread watchTrap(self);

    fx1 = PlayLoopedFX(level._effect["firelp_med_pm_nodistort"], 1, fire1.origin);
    fx2 = PlayLoopedFX(level._effect["firelp_med_pm_nodistort"], 1, fire2.origin);
    fx3 = PlayLoopedFX(level._effect["firelp_med_pm_nodistort"], 1, fire3.origin);
    fx4 = PlayLoopedFX(level._effect["firelp_med_pm_nodistort"], 1, fire4.origin);
    fire1 PlayLoopSound("fire_metal_large");
    brush1 moveZ(48, 1);
    brush2 rotateYaw(360, 1);

    wait 15;
    trap.killTrigger = undefined;
    brush1 moveZ(-48, 1);
    brush2 rotateYaw(-360, 1);

    fx1 delete();
    fx2 delete();
    fx3 delete();
    fx4 delete();
    fire1 StopLoopSound();
    brush2 PlaySound("shild_off");
    wait 1;
}

/**
 * @brief Controller for an electric trap
 *
 * @param trap struct The central trap to run
 *
 * @returns nothing
 * @since RotU 2.2.3
 */
electricTrap(trap)
{
    debugPrint("in _traps::electricTrap()", "fn", level.nonVerbose);

    elec1 = getent("electric1" ,"targetname"); //origin
    elec2 = getent("electric2" ,"targetname"); //origin
    elec3 = getent("electric3" ,"targetname"); //origin
    elec4 = getent("electric4" ,"targetname"); //origin
    elec5 = getent("electric5" ,"targetname"); //origin
    elec6 = getent("electric6" ,"targetname"); //origin
    brush1 = getEnt( "brush_death5", "targetname" );
    brush2 = getEnt( "aktiv_trap5", "targetname" );

    brush2 PlaySound("shild_on");
    brush2 moveZ(-2.5, 1);
    brush1 movez(64, 1);
    trap.killTrigger = spawn("trigger_radius", brush1.origin, 0, 16, 16);
    trap thread watchTrap(self);

    for (i=0; i<10; i++) {
        fx1 = PlayLoopedFX(level._effect["sparks_d"], 1, elec1.origin);
        fx2 = PlayLoopedFX(level._effect["sparks_d"], 1, elec2.origin);
        elec1 PlaySound("electric");
        wait 1;
        fx1 delete();
        fx2 delete();

        fx3 = PlayLoopedFX(level._effect["sparks_d"], 1, elec3.origin);
        fx4 = PlayLoopedFX(level._effect["sparks_d"], 1, elec4.origin);
        elec3 PlaySound("electric");
        wait 1;
        fx3 delete();
        fx4 delete();

        fx5 = PlayLoopedFX(level._effect["sparks_d"], 1, elec5.origin);
        fx6 = PlayLoopedFX(level._effect["sparks_d"], 1, elec6.origin);
        elec5 PlaySound("electric");
        wait 1;
        fx5 delete();
        fx6 delete();
    }

    trap.killTrigger = undefined;
    brush2 movez(2.5, 1);
    brush1 movez(-64, 1);
    brush2 PlaySound("shild_off");
    wait 1;
}
