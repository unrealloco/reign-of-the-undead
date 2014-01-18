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

#include scripts\include\matrix;
#include scripts\include\waypoints;
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
    if (level.zombieAiDevelopment) {
        // [un]filled queue of movement orders, i.e. params for the moveTo() function
        bot.movement = spawnStruct();
        bot.movement.first = 0;
        bot.movement.next = 0;
        bot.movement.last = 0;
        bot.movement.orders = [];
        bot.speed = 0;
        bot.pathNodes = [];
        // we assume one order every 0.05s, for 0.2s until we reevaluate movement,
        // but may need more orders to accomodate falling on maps like farthouse
        for (i=0; i<20; i++) { // 1s
            order = spawnStruct();
            order.origin = (0,0,0);
            order.time = 0; //s
            order.angles = (0,0,0);
            bot.movement.orders[i] = order;
        }
        bot.isFollowingWaypoints = false;
    }

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

    self endon("dying");
    self endon("disconnect");
    self endon("death");
    level endon("game_ended");

    if (level.zombieAiDevelopment) {
        // look for a target, if we find one, head towards it and end function
        // if we don't find one, head towards a random waypoint
        self.status = "searching";
    } else {
        self.status = "searching";
    }
    //iprintlnbold("SEARCHING!");
}

wander()
{
    debugPrint("in _bot::wander()", "fn", level.fullVerbosity);

    self endon("dying");
    self endon("disconnect");
    self endon("death");
    self endon("alerted");
    self endon("found_target");
    level endon("game_ended");

    if (level.waypointsInvalid) {
        // use direct method
    } else {
        noticePrint("Wandering!");
        count = 0;
        // use waypoints
        self.isFollowingWaypoints = true;
        self.status = level.BOT_WANDERING;
        noticePrint("self.origin: " + self.origin + " self.mover.origin: " + self.mover.origin);
        self.myWaypoint = nearestWaypoints(self.origin, 1)[0];
//         self.myWaypoint = 67; /// temp HACK
        /// temp HACK, jump bot to its first waypoint
        wait 3;
        self enqueueMovement(level.Wp[self.myWaypoint].origin, 0.05, self.angles);
        self setSpeed();
        self move();
        self.goalWp = self.myWaypoint;
//         self.goalWp = 114; /// temp HACK

        while (count < 300) {
            count++;
            // get a goal waypoint if required
            if (self.goalWp == self.myWaypoint) {iPrintLnBold("New Goal!");}
            while (self.goalWp == self.myWaypoint) {
                self.goalWp = randomInt(level.Wp.size);
            }
            if (self.pathNodes.size == 0) {
                self.pathNodes = AStarNew(self.myWaypoint, self.goalWp);
                noticePrint("path from: " + self.myWaypoint + " to: " + self.goalWp);
                path = "";
                for (i=self.pathNodes.size - 1; i>=0; i--) {
                    path = path + " " + self.pathNodes[i];
                }
                noticePrint(path);
            }
            // pop the next wp to head towards off the stack
            self.nextWp = self.pathNodes[self.pathNodes.size - 1];
            self.pathNodes[self.pathNodes.size - 1] = undefined;

//             iPrintLnBold("my: " + self.myWaypoint + " next: " + self.nextWp + " goal: " + self.goalWp);
            self.pathType = pathType(self.myWaypoint, self.nextWp);
            noticePrint("self.pathType: " + self.pathType);
            if (self.pathType == level.PATH_CLAMPED) {
                self clamped();
                self move();
                self.myWaypoint = self.nextWp;
            } else if (self.pathType == level.PATH_TELEPORT) {
                self teleport();
                self.myWaypoint = self.nextWp;
            } else if (self.pathType == level.PATH_MANTLE) {
                self mantle();
                self move();
                self.myWaypoint = self.nextWp;
            } else if ((self.pathType == level.PATH_LADDER) && (self.isBipedal)) {
                // if path type is ladder, but not a biped, we need to do something creative
                // so the bots don't congregate at the bottom of the ladder
                self ladder();
                self move();
                self.myWaypoint = self.nextWp;
            } else if (self.pathType == level.PATH_NORMAL) {
                self normal();
                self move();
                self.myWaypoint = self.nextWp;
            } else if (self.pathType == level.PATH_FALL) {
                self fall();
            }
        }
        iPrintLnBold("Done Wandering!");
    }
}

setSpeed()
{
    if ((self.alertLevel >= 200 && (!self.walkOnly || self.quake)) || self.sprintOnly) {
        self run();

//         if (level.dvar["zom_dominoeffect"]) {
//             thread alertZombies(self.origin, 480, 5, self);
//         }
    } else {self walk();}
}

run()
{
    // Do *not* put a function entrance debugPrint statement here!

    self.motionType = level.BOT_RUN;
    self setAnimation("sprint");
    self.cur_speed = self.runSpeed;
    self.speed = self.runSpeed;
    if (self.quake) {Earthquake(0.25, .3, self.origin, 380);}
}

walk()
{
    // Do *not* put a function entrance debugPrint statement here!

    self.motionType = level.BOT_WALK;
    self setAnimation("walk");
    self.cur_speed = self.walkSpeed;
    self.speed = self.walkSpeed;
    if (self.quake) {Earthquake(0.17, .3, self.origin, 320);}
}

teleport()
{
    // Do *not* put a function entrance debugPrint statement here!

    self endon("dying");
    self endon("disconnect");
    self endon("death");
    level endon("game_ended");

    if (self.isFollowingWaypoints) {
        // since we are following waypoints, we assume no solid objects or obstructions
        noticePrint("Teleport!");
        iPrintLnBold("Teleport!");

        direction = vectorNormalize(level.Wp[self.nextWp].origin - level.Wp[self.myWaypoint].origin);
        facing = vectorToAngles(direction);
        self setPlayerAngles(facing);
        self.mover.origin = level.Wp[self.nextWp].origin;
    }
}

/// climbing up a ladder.  bipeds only
ladder()
{
    // Do *not* put a function entrance debugPrint statement here!

    self endon("dying");
    self endon("disconnect");
    self endon("death");
    level endon("game_ended");

    if (self.isFollowingWaypoints) {
        // since we are following waypoints, we assume no solid objects or obstructions
        noticePrint("Ladder!");
        iPrintLnBold("Ladder!");

        self.motionType = level.BOT_CLIMB;
        self.speed = int((self.walkSpeed + self.runSpeed) / 2);
        self setAnimation("sprint");

        facing = undefined;
        if (level.Wp[self.nextWp].origin[2] > level.Wp[self.myWaypoint].origin[2]) {
            // going up
            if (isDefined(level.Wp[self.myWaypoint].upAngles)) {
                facing = level.Wp[self.myWaypoint].upAngles;
//                 iPrintLnBold("Using .upAngles!");
            }
        } else {
            // going down
            if (isDefined(level.Wp[self.myWaypoint].downAngles)) {
                facing = level.Wp[self.myWaypoint].downAngles;
//                 iPrintLnBold("Using .downAngles!");
            }
        }
        if (!isDefined(facing)) {
            direction = vectorNormalize(level.Wp[self.nextWp].origin - level.Wp[self.myWaypoint].origin);
            facing = vectorToAngles(direction);
//             iPrintLnBold("Using computed angles!");
        }

        distance = distance(level.Wp[self.myWaypoint].origin, level.Wp[self.nextWp].origin);
        time = distance / self.speed;

        self setPlayerAngles(facing);
        self.mover moveTo(level.Wp[self.nextWp].origin, time, 0, 0);
        self.mover waittill("movedone");

        self setSpeed();
        /// @todo while devPlayer is on ladder, save getPlayerAngles().  Put this in .angles for both "ladder" waypoints
    } else {
        // not following waypoints
    }
}

/// climbing up a short wall or crate.
mantle()
{
    // Do *not* put a function entrance debugPrint statement here!

    self endon("dying");
    self endon("disconnect");
    self endon("death");
    level endon("game_ended");

    if (self.isFollowingWaypoints) {
        noticePrint("Mantle!");
        iPrintLnBold("Mantle!");
        // since we are following waypoints, we assume no solid objects or obstructions

        direction = vectorNormalize(level.Wp[self.nextWp].origin - level.Wp[self.myWaypoint].origin);
        facing = vectorToAngles(direction); // see note about direction bug in clamped() function

        // enqueue the vertical displacement
        deltaZ = level.Wp[self.nextWp].origin[2] - level.Wp[self.myWaypoint].origin[2];
        position = self.origin + (0,0,deltaZ);
        time = deltaZ / self.speed;
        if (time <= 0) {
            errorPrint("mantle vertical(time, deltaZ, self.speed): (" + time + ", " + deltaZ + ", " + self.speed + ")");
            errorPrint(level.Wp[self.nextWp].origin[2] + ", "+ level.Wp[self.myWaypoint].origin[2]);
        }
        self enqueueMovement(position, time, facing);

        // enqueue the horizontal displacement
        distance = distance(position, level.Wp[self.nextWp].origin);
        time = distance / self.speed;
        // put us at the actual waypoint, in case there were any round-off errors
        if (time <= 0) {
            errorPrint("mantle horizontal(time, distance, self.speed): (" + time + ", " + distance + ", " + self.speed + ")");
        }
        self enqueueMovement(level.Wp[self.nextWp].origin, time, facing);
    } else {
        noticePrint("In Mantle(), but .isFollowingWaypoints is false!");
    }
}

/**
 * @brief Moves a bot along a waypoint link line, regardless of any other factors.
 *
 * Used rarely for edge cases in maps where normal movement, mantling, and climbing
 * ladders isn't enough.
 *
 * @returns nothing
 */
clamped()
{
    debugPrint("in _bot::clamped()", "fn", level.fullVerbosity);

    self endon("dying");
    self endon("disconnect");
    self endon("death");
    level endon("game_ended");

    if (self.isFollowingWaypoints) {
        noticePrint("Clamped!");
        // since we are following waypoints, we assume no solid objects or obstructions

        // make animation frame such that frame distance is about 18 inches.
        frameCount = int(18 / self.speed / 0.05);
        if (frameCount == 0) {frameCount = 1;}
        deltaA = abs(18 - (self.speed * (0.05 * frameCount)));
        deltaB = abs(18 - (self.speed * (0.05 * (frameCount + 1))));
        if (deltaB < deltaA) {
            frameCount++; // this is closer to 18 units than frameCount
        }
        frameDistance = self.speed * (0.05 * frameCount);

        /** This is the code we would like to apply to the bots, but Activision's
         * bug thwarts us.  Internally, setPlayerAngles() treats all players as if
         * they were bipedal and zeros out the z-coordinate of the direction vector.
         * The result is that players are always oriented vertically, regardless of
         * our wishes--we would prefer if quadrapeds followed the ground plane instead
         * of being vertical.
         *
         * Since setPlayerAngles() doesn't work properly, this code is commented
         * out, but left here in the hopes that I can eventually find a work-around.
         *
         * @code
         *  to = level.Wp[self.nextWp].origin;
         *  from = level.Wp[self.myWaypoint].origin;
         *  if (self.isBipedal) {
         *      to = to * (1,1,0);
         *      from = from * (1,1,0);
         *  }
         *  direction = vectorNormalize(to - from);
         *
         * @endcode
         */
        direction = vectorNormalize(level.Wp[self.nextWp].origin - level.Wp[self.myWaypoint].origin);
        facing = vectorToAngles(direction);

        position = level.Wp[self.myWaypoint].origin;
//         noticePrint("clamped from wp " + self.myWaypoint + " at " + level.Wp[self.myWaypoint].origin);
//         noticePrint("clamped to wp " + self.nextWp + " at " + level.Wp[self.nextWp].origin);
        /// @todo for clamped, we can do this in one movement, but we will need this code later, so keep it here for now
        distance = distance(level.Wp[self.myWaypoint].origin, level.Wp[self.nextWp].origin);
        while (distance > frameDistance) {
            distance = distance - frameDistance;
            position = position + (frameDistance * direction);
            time = frameCount * 0.05;
            self enqueueMovement(position, time, facing);
        }
        time = distance / self.speed;
        self enqueueMovement(level.Wp[self.nextWp].origin, time, facing);
    } else {
        noticePrint("In clamped(), but .isFollowingWaypoints is false!");
    }
}

/**
 * @brief Draws a local right-handed coordinate system
 *
 * @param direction vector The unit vector specifing the direction for the x-axis
 * determine the direction with \code
 * direction = vectorNormalize(endPoint - self.origin);
 * \endcode
 *
 * The x-axis is drawn in red, the y-axis in green, and the z-axis in blue.  The
 * origin for the local coordinate system is placed at self.origin.
 * @depends matrix.gsc must be included, and only works in dev mode where the line()
 * function is available.
 *
 * @returns nothing
 */
devDrawLocalCoordinateSystem(direction)
{
    debugPrint("in _bot::devDrawLocalCoordinateSystem()", "fn", level.nonVerbose);

    self endon("hide_coordinate_system");

    // standard basis vectors in world coordinate system
    i = (1,0,0);
    j = (0,1,0);
    k = (0,0,1);

    // [i|j|k]Prime are the basis vectors for the rotated coordinate system
    iPrime = direction;
    kPrime = vectorNormalize((self.origin + (0,0,25)) -  self.origin);
    kPrime = kPrime * -1;
    u = zeros(3,1);
    setValue(u,1,1,iPrime[0]);  // x
    setValue(u,2,1,iPrime[1]);  // y
    setValue(u,3,1,iPrime[2]);  // z
    v = zeros(3,1);
    setValue(v,1,1,kPrime[0]);  // x
    setValue(v,2,1,kPrime[1]);  // y
    setValue(v,3,1,kPrime[2]);  // z
    // i cross -k to get the real j
    jPrimeM = matrixCross(u, v);
    jPrime = vectorNormalize((value(jPrimeM,1,1), value(jPrimeM,2,1), value(jPrimeM,3,1)));
    w = zeros(3,1);
    setValue(w,1,1,jPrime[0]);  // x
    setValue(w,2,1,jPrime[1]);  // y
    setValue(w,3,1,jPrime[2]);  // z
    // now i cross j to get the real k
    kPrimeM = matrixCross(u, w);
    kPrime = vectorNormalize((value(kPrimeM,1,1), value(kPrimeM,2,1), value(kPrimeM,3,1)));

    while (1) {
        line(self.origin, self.origin + (iPrime * 30), decimalRgbToColor(255,0,0), false, 25);
        line(self.origin, self.origin + (jPrime * 30), decimalRgbToColor(0,255,0), false, 25);
        line(self.origin, self.origin + (kPrime * 30), decimalRgbToColor(0,0,255), false, 25);
        wait 0.05;
    }
}

jump()
{

}

fall()
{
    iPrintLnBold("Fall!");

    // compute initial velocity, v_0, for our fall
    lastDirection = vectorNormalize(self.origin - self.lastPosition);
    position = (self.origin[0], self.origin[1], self.lastPosition[2]);
    lastLevelDirection = vectorNormalize(position - self.lastPosition);
    noticePrint("directions: " + lastDirection + lastLevelDirection);
    noticePrint("positions: " + position + self.lastPosition);
    declination = scripts\players\_turrets::angleBetweenTwoVectors(lastDirection, lastLevelDirection);

    newDirection = vectorNormalize(level.Wp[self.nextWp].origin - level.Wp[self.myWaypoint].origin);
    position = (level.Wp[self.nextWp].origin[0], level.Wp[self.nextWp].origin[1], level.Wp[self.myWaypoint].origin[2]);
    newLevelDirection = vectorNormalize(position - level.Wp[self.myWaypoint].origin);
    deltaZ = tan(declination);
    position = position + (0,0,-1 * deltaZ);
    direction = vectorNormalize(position - level.Wp[self.myWaypoint].origin);
    v_0 = direction * self.speed;

    // now we need to find and move to the actual edge of the object we are falling off of
    from = self.origin + (direction * 30);
    from = (position[0], position[1], position[2] - 5);
    to = (self.origin[0], self.origin[1], self.origin[2] - 5);
    trace = bulletTrace(from, to, false, self);
    if (trace["fraction"] == 1) {
        // we couldn't find the edge!
        /// This is probably very bad!
        position = self.origin;
    } else {
        position = trace["position"] + (0,0,5);
    }

    self pathPrint("pre-fall path: ");

    if (self ballistic(v_0, position) == (0,0,0)) {
        // motion is done and we are on the ground.  get us back on track to our goal
        // we are off waypoints here, so we need to get back on them, preferably
        // without backtracking
        self postFall();
    } else {
        // motion is done but we are not on the ground.  we may have hit a wall or
        // other obstacle and be floating in mid-air right now!
        /// @todo implement fall() after initial ballistic motion hits a wall or ceiling
    }
}

postFall()
{
    nearestWp = nearestWaypoints(self.origin, 1)[0];
    if (nearestWp == self.goalWp) {
        // just move to goalWp, and invalidate pathNodes
//         iPrintLnBold("post-fall: moving to goalWp");
        distance = distance(self.origin, level.Wp[self.goalWp].origin);
        direction = vectorNormalize(level.Wp[self.goalWp].origin - self.origin);
        facing = vectorToAngles(direction);
        time = distance / self.speed;
        self enqueueMovement(level.Wp[self.goalWp].origin, time, facing);
        self move();
        self.myWaypoint = self.goalWp;
        self.pathNodes = [];
        return;
    }
    // invalidate any pathNodes up to nearestWp
    for (i=self.pathNodes.size - 1; i>=0; i--) {
        if (self.pathNodes[i] == nearestWp) {
//             iPrintLnBold("post-fall: found nearestWp in pathNodes");
            break;
        } else {
            self.pathNodes[i] = undefined;
        }
    }
    if (self.pathNodes.size == 0) {
        // we need a new path
//         iPrintLnBold("post-fall: getting a new path");
        self.pathNodes = AStarNew(nearestWp, self.goalWp);
    }

    // decide which of the remaining nodes to go to, and how to get there
    // do we go to nearestWp, or to a point on a waypoint link to one of the pathNodes?
    testWp = self.pathNodes[self.pathNodes.size - 1];
    directDistance = distance(self.origin, level.Wp[testWp].origin);
    linkDistance = distance(level.Wp[nearestWp].origin, level.Wp[testWp].origin);
    if (directDistance < linkDistance) {
        // we are already closer to the next pathnode than if we were at nearestWp
        // if we have a clear path to the next pathnode, go there directly
        trace = bulletTrace(self.origin + (0,0,20), level.Wp[testWp].origin + (0,0,20), false, self);
        if (trace["fraction"] == 1) {
            noticePrint("post-fall: moving directly to testWp");
            distance = distance(self.origin, level.Wp[testWp].origin);
            time = distance / self.speed;
            facing = vectorToAngles(level.Wp[testWp].origin - self.origin);
            self enqueueMovement(level.Wp[testWp].origin, time, facing);
            self move();
            self.pathNodes[self.pathNodes.size - 1] = undefined;
            self.nextWp = testWp;
            self.myWaypoint = self.nextWp;
            return;
        } else {
            // else if we have a clear path to the nearest point on the link line, go there
            // and then to the next pathnode
            vectorToLine = vectorFromLineToPoint(level.Wp[self.nextWp].origin, level.Wp[testWp].origin, self.origin) * -1;
            linePosition = self.origin + vectorToLine;
            trace = bulletTrace(self.origin + (0,0,20), linePosition + (0,0,20), false, self);
            if (trace["fraction"] == 1) {
                // we have a clear path
                // move to line
                noticePrint("post-fall: moving testWp via nearest point on link line");
                distance = distance(self.origin, linePosition);
                time = distance / self.speed;
                facing = vectorToAngles(vectorToLine);
                self enqueueMovement(linePosition, time, facing);

                // move to waypoint
                distance = distance(linePosition, level.Wp[testWp].origin);
                time = distance / self.speed;
                facing = vectorToAngles(level.Wp[testWp].origin - level.Wp[self.nextWp].origin);
                self enqueueMovement(level.Wp[testWp].origin, time, facing);
                self move();
                self.pathNodes[self.pathNodes.size - 1] = undefined;
                self.nextWp = testWp;
                self.myWaypoint = self.nextWp;
                return;
            }
        }
    }

    // go to nearestWp
    noticePrint("post-fall: moving directly to nearestWp: " + nearestWp);
    distance = distance(self.origin, level.Wp[nearestWp].origin);
    time = distance / self.speed;
    facing = vectorToAngles(level.Wp[nearestWp].origin - self.origin);
    self enqueueMovement(level.Wp[nearestWp].origin, time, facing);
    self move();
    self.pathNodes[self.pathNodes.size - 1] = undefined;
    self.nextWp = nearestWp;
    self.myWaypoint = self.nextWp;
    self pathPrint("post-fall path: ");
    noticePrint("testWp: " + testWp);
}

pathPrint(message)
{
    path = "[";
    for (i=0; i<self.pathNodes.size; i++) {
        path = path + " " + self.pathNodes[i];
    }
    path = path + " ]";
    noticePrint(message + path);
    noticePrint("(myWaypoint, nextWp, goalWp): (" + self.myWaypoint + ", " + self.nextWp + ", " + self.goalWp + ")");
}

getOnPath()
{
    directDistance = distance(self.origin, level.Wp[self.nextWp].origin);
    testWp = self.pathNodes[self.pathNodes.size - 1];
    pathDistance = distance(level.Wp[self.nextWp].origin, level.Wp[testWp].origin);
    pathQueued = false;
    if (directDistance < pathDistance) {
        // if we went to nextWp, we would actually be getting farther from the subsequent node
        vectorToLine = vectorFromLineToPoint(level.Wp[self.nextWp].origin, level.Wp[testWp].origin, self.origin) * -1;
        linePosition = self.origin + vectorToLine;
        trace = bulletTrace(self.origin + (0,0,20), linePosition + (0,0,20), false, self);
        if (trace["fraction"] == 1) {
            // we have a clear path
            // move to line
            distance = distance(self.origin, linePosition);
            time = distance / self.speed;
            facing = vectorToAngles(vectorToLine);
            self enqueueMovement(linePosition, time, facing);

            // move to waypoint
            distance = distance(linePosition, level.Wp[testWp].origin);
            time = distance / self.speed;
            facing = vectorToAngles(level.Wp[testWp].origin - level.Wp[self.nextWp].origin);
            self enqueueMovement(level.Wp[testWp].origin, time, facing);
            pathQueued = true;
        }
    }
    if (!pathQueued) {
        // move directly to first waypoint
        distance = distance(self.origin, level.Wp[self.myWaypoint].origin);
        time = distance / self.speed;
        facing = vectorToAngles(level.Wp[self.myWaypoint].origin - self.origin);
        enqueueMovement(level.Wp[self.myWaypoint].origin, time, facing);
    }

//     forward = anglesToForward(self getPlayerAngles);
//     directVector = vectorNormalize(level.Wp[self.nextWp].origin - self.origin);
//     testWp = self.pathNodes[self.pathNodes.size - 1];
//     nextVector = vectorNormalize(level.Wp[testWp].origin - level.Wp[self.nextWp].origin);
//     dot = vectorDot(directVector, nextVector);
//
//     if (dot > 0.5) {
//         // the first full leg of the path is generally in front of us, so move to
//         // the first pathNode
//     } else {
//         // the first full leg of the path is left/right or behind us, so we need to
//         // determine if it better to go to another waypoint first
//     }
//     cumulativeDistance = distance(self.origin, level.Wp[self.pathNodes[self.pathNodes.size - 1]].origin);
//     for (i=self.pathNodes.size - 1; i>=0; i--) {
//         fromWp = self.pathNodes[i];
//         toWp = self.pathNodes[i - 1];
//         cumulativeDistance += distance(level.Wp[fromWp].origin, level.Wp[toWp].origin);
//         directDistance = distance(self.origin, level.Wp[testWp].origin);
//     }
}

/// draws a scaled unit vector in the direction of the velocity vector
drawVelocity(v_0, r_0)
{
    from = r_0;
    to = r_0 + (vectorNormalize(v_0) * 30);
    while (1) {
        line(from, to, decimalRgbToColor(255,0,0), false, 25);
        wait 0.05;
    }
}

/**
 * @brief Performs ballistic motion in R^3
 *
 * We assume a point mass, located at self.mover.origin, no resistive forces, and
 * a constant acceleration due to gravity.
 *
 * With a game-standard acceleration due to gravity of (0,0,-800) units * s^(-2),
 * one unit equals 0.4829 inches or 1.227 cm.
 *
 * @param v_0 vector The initial velocity vector
 * @param r_0 vector The inital position vector.  r_0 *must* be at the actual edge
 *              of a surface, or ballistic motion will hit the very spot we are
 *              standing at.
 *
 * @returns vector The final velocity vector. (0,0,0) is we are on the ground
 */
ballistic(v_0, r_0)
{
    noticePrint("Ballistic!");
//     iPrintLnBold("Ballistic!");

    onGround = false;

    r = (0,0,0);                                // position at time t
    v = (0,0,0);                                // velocity at time t
    s = 0;                                      // speed at time t
    g = (0,0,getDvarInt("g_gravity") * -1);     // acceleration due to gravity, assume constant

    if (!isDefined(v_0)) {
        direction = vectorNormalize(self.origin - self.lastPosition); // the direction of the last movement
        v_0 = self.speed * direction;           // initial velocity vector at t == 0
        s_0 = self.speed;
    } else {
        direction = vectorNormalize(v_0);
        s_0 = distance((0,0,0), v_0);           // initial speed
    }

    facing = vectorToAngles(direction);

    // for this motion, find impact time with resolution of +/- 0.05s
    t = 0;
    r_last = r_0;
    v_last = v_0;
    s_last = s_0;
    trace = undefined;
    while (1) {
        t = t + 0.05;
        r = r_0 + (v_0 * t) + (0.5 * g * t * t);
        trace = bulletTrace(r_last, r, false, self);
        if (trace["fraction"] != 1) {
            break; // we would hit the ground if we did this
        }
        r_last = r;
    }
    t = t - 0.05 - 0.005;
    // repeat the last segment with time resolution of +/- 0.005s
    while (1) {
        t = t + 0.005;
        r = r_0 + (v_0 * t) + (0.5 * g * (t * t));
        trace = bulletTrace(r_last, r, false, self);
        if (trace["fraction"] != 1) {
            // we would hit the ground if we did this, so save final speed for last step
            v = v_0 + (g * (t - 0.005));
            s = distance((0,0,0), v);
            s_last = s;
            break;
        }
        r_last = r;
    }
    position = trace["position"];
    distance =  distance(r_last, position);
    t_epsilon = distance / s_last;
    t_0 = t - 0.005 + t_epsilon;
    t = int(t_0 / 0.05) * 0.05;
    finalStepTime = t_0 - t;
    if (finalStepTime <=0) {
        errorPrint("finalStepTime is <= 0!");
        errorPrint("finalStepTime: " + finalStepTime + " t_0: " + t_0 + " t: " + t);
    }

    noticePrint("r_0, v_0: " + r_0 + ", " + v_0);
    noticePrint("distance: " + distance + " t_epsilon: " + t_epsilon + " t: " + t);
    noticePrint("computed final position: " + position);
    noticePrint("final speed: " + s_last);
    noticePrint("g: " + g);
    thread drawVelocity(v_0, r_0);

    // move to edge, r_0
    self setPlayerAngles(facing);
    self.mover moveTo(r_0, 0.05, 0, 0);
    self.mover waittill("movedone");

    // moveGravity() only works in 0.05s increments, so we need to do the last
    // step manually to ensure we don't wind up in the ground!
    self.mover moveGravity(v_0, t);
    self.mover waittill("movedone");

    ground = findGround(position);
    deltaZ = abs(position[2] - ground[2]);
    if (deltaZ <= 0.5) { // close enough!
        position = ground;
        onGround = true;
    }

    // move to final position
    self.mover moveTo(position, finalStepTime, 0, 0);  /// @bug finalStepTime is sometimes not positive
    self.mover waittill("movedone");
    noticePrint("actual final position: " + self.mover.origin);

    // At this point, we have impacted a solid object, hopefully the ground, but
    // perhaps also a wall, in which case we are now hanging in mid-air partially
    // in the wall!
    noticePrint("mover: " + self.mover.origin);
    noticePrint("self: " + self.origin);
    noticePrint("ground: " + position);
    if (onGround) {return (0,0,0);}
    else {return v;}
}

pathType(fromWp, toWp)
{
    if (fromWp == toWp) {
        errorPrint("fromWp equals toWp (" + fromWp + "), there cannot be a path type!");
    }
    if (level.Wp[fromWp].type == "mantle") {
        deltaZ = level.Wp[toWp].origin[2] - level.Wp[fromWp].origin[2];
        distance = distance2D(level.Wp[fromWp].origin, level.Wp[toWp].origin);
        if ((deltaZ >= level.MANTLE_MIN_Z) && (deltaZ <= level.MANTLE_MAX_Z) && (distance < level.MANTLE_MAX_DISTANCE)) {
            // we only mantle up, never down
            return level.PATH_MANTLE;
        }
    } else if ((level.Wp[fromWp].type == "ladder") && (level.Wp[toWp].type == "ladder")) {
        return level.PATH_LADDER;
    } else if ((level.Wp[fromWp].type == "clamped") && (level.Wp[toWp].type == "clamped")) {
        return level.PATH_CLAMPED;
    } else if ((level.Wp[fromWp].type == "clamped") && (level.Wp[toWp].type == "ladder")) {
        return level.PATH_CLAMPED;
    } else if (level.Wp[toWp].type == "mantle") {
        deltaZ = abs(level.Wp[toWp].origin[2] - level.Wp[fromWp].origin[2]);
        distance = distance2D(level.Wp[fromWp].origin, level.Wp[toWp].origin);
        if ((deltaZ >= level.MANTLE_MIN_Z) && (deltaZ <= level.MANTLE_MAX_Z) && (distance < level.MANTLE_MAX_DISTANCE)) {
            // fall off wall/crate towards the mantle waypoint
            return level.PATH_FALL;
        }
    } else if ((level.Wp[fromWp].type == "teleport") && (level.Wp[toWp].type == "teleport")) {
        return level.PATH_TELEPORT;
    } else if ((level.Wp[fromWp].type == "fall") && (level.Wp[toWp].type == "stand")) {
        deltaZ = level.Wp[toWp].origin[2] - level.Wp[fromWp].origin[2];
        if (deltaZ < -50) {
            return level.PATH_FALL;
        }
    } else if ((level.Wp[fromWp].type == "stand") && (level.Wp[toWp].type == "fall")) {
        deltaZ = level.Wp[toWp].origin[2] - level.Wp[fromWp].origin[2];
        if (deltaZ > 50) {
            /// this will be invalid path, as we can't fall up, but I need to fix A*
            /// first so it won't return a solution that includes these links.
            /// For now, just treat it as a clamped path.
            return level.PATH_CLAMPED;
        }
    }

    return level.PATH_NORMAL;
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
        /// @todo do a trace like isPathClear()
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

/// normal walk/run movement
normal()
{
    if (self.isFollowingWaypoints) {
        noticePrint("Normal!");
        // since we are following waypoints, we assume no solid objects or obstructions

        // make animation frame such that frame distance is about 18 inches.
        frameCount = int(level.BOT_MOVE_DISTANCE / self.speed / 0.05);
        if (frameCount == 0) {frameCount = 1;}
        deltaA = abs(level.BOT_MOVE_DISTANCE - (self.speed * (0.05 * frameCount)));
        deltaB = abs(level.BOT_MOVE_DISTANCE - (self.speed * (0.05 * (frameCount + 1))));
        if (deltaB < deltaA) {
            frameCount++; // this is closer to 18 units than frameCount
        }
        frameDistance = self.speed * (0.05 * frameCount);

        direction = vectorNormalize(level.Wp[self.nextWp].origin - level.Wp[self.myWaypoint].origin);
        facing = vectorToAngles(direction);

        position = level.Wp[self.myWaypoint].origin;
        distance = distance(level.Wp[self.myWaypoint].origin, level.Wp[self.nextWp].origin);
        while (distance > frameDistance) {
            distance = distance - frameDistance;
            position = position + (direction * frameDistance);
            position = self findGround(position);
            time = frameCount * 0.05;
            self enqueueMovement(position, time, facing);
        }
        time = distance / self.speed;
        self enqueueMovement(level.Wp[self.nextWp].origin, time, facing);
    } else {
        noticePrint("In normal(), but .isFollowingWaypoints is false!");
    }

//     if (self.isFollowingWaypoints) {
//         // since we are following waypoints, we assume no solid objects or obstructions
//         stepDistance = self.speed * 0.05;
//         goalDirection = vectorNormalize(level.Wp[self.nextWp].origin - self.origin);
//         steps = 0;
//
//         position = self.origin;
//         while ((steps < 4) && (self.origin != level.Wp[self.nextWp].origin)) {
//             steps++;
//             // find the ground 0.05s ahead of us
//             goalPosition = position + (goalDirection * stepDistance);
//             goalPosition = self findGround(goalPosition);
//             stepDirection = vectorNormalize(position - self.origin);
//
//             // we assume this position is still on the ground (or close enough)
//             position = position + (stepDirection * stepDistance);
//             deltaZ = position[2] - self.origin[2];
//             if (deltaZ >= 0) { // going up
//
//             } else { // going down
//                 if (deltaZ > distance * -1) {
//                     // just walk
//                 } else {
//                     // we need to fall!
//                 }
//             }
//         }
//         distance = distance(self.origin, level.Wp[self.nextWp].origin);
//         position = self.origin + (goalDirection * stepDistance);
//         position = self findGround(position);
//         stepDirection = vectorNormalize(position - self.origin);
//         deltaZ = position[2] - self.origin[2];
//         if (deltaZ >= 0) { // going up
//
//         } else { // going down
//             if (deltaZ > distance * -1) {
//                 // just walk
//             } else {
//                 // we need to fall!
//             }
//         }
//     } else {
//     }
}

findPathToTarget()
{
    debugPrint("in _bot::findPathToTarget()", "fn", level.highVerbosity);

    if (self.isFollowingWaypoints) {
        // since we are following waypoints, we assume no solid objects or obstructions
        distance = self.speed * 0.05;
        targetVector = vectorNormalize(level.Wp[self.nextWp].origin - self.origin);
        position = self.origin + (targetVector * distance);
        position = self findGround(position);
        deltaZ = position[2] - self.origin[2];
        if (deltaZ >= 0) { // going up
        } else { // going down
            if (deltaZ > distance * -1) {
                // just walk
            } else {
                // we need to fall!
            }
        }
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
    if (self.isFollowingWaypoints) {return true;}

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

    if (self.movement.last == self.movement.orders.size) {
        // our queue is too small!  Add ten more spots
        for (i=self.movement.last; i<self.movement.last + 10; i++) {
            order = spawnStruct();
            order.origin = (0,0,0);
            order.time = 0; //s
            order.angles = (0,0,0);
            self.movement.orders[i] = order;
        }
    }

    noticePrint("enqueueing movement: (" + origin + ", " + time + ", " + facing + ")");
    noticePrint("size, first, last: (" + self.movement.orders.size + ", " + self.movement.first + ", " + self.movement.last + ")");
    self.movement.orders[self.movement.last].origin = origin;
    self.movement.orders[self.movement.last].time = time;
    self.movement.orders[self.movement.last].angles = facing;
    self.movement.last++;
}

findGround(position)
{
    debugPrint("in _bot::findGround()", "fn", level.highVerbosity);

    top = position + (0,0,50);
    bottom = position + (0,0,-9500); // large value for farthouse and other mouse-scale maps
    count = 0;

    trace = undefined;
    direction = vectorNormalize(bottom - top);
    ignoreEntity = self;

    while ((top != bottom) && (count < 10)) {
        count++;
        trace = bulletTrace(top, bottom, false, ignoreEntity);
        if (trace["fraction"] == 1) {return trace["position"];} // long way down!
        else {
            if (!isDefined(trace["entity"])) { // we hit something we shouldn't ignore
                return trace["position"];
            } else {
                // if we hit something we should ignore, try to get past it
                if (((isDefined(trace["entity"].isCorpse)) && (trace["entity"].isCorpse)) ||        // ignore corpses
                    ((isDefined(trace["entity"].isBot)) && (trace["entity"].isBot)) ||              // ignore other bots
                    ((isDefined(trace["entity"].isBarrel)) && (trace["entity"].isBarrel)) ||        // ignore barrels
                    ((isDefined(trace["entity"].isBarricade)) && (trace["entity"].isBarricade)) ||  // ignore barricades
                    ((isDefined(trace["entity"].isTurret)) && (trace["entity"].isTurret)) ||        // ignore defense turrets
                    ((isDefined(trace["entity"].isTeleporter)) && (trace["entity"].isTeleporter)))  // ignore teleporters
                {
                    if (trace["fraction"] < 0.01) {
                        distance = distanceSquared(trace["position"], bottom);
                        if (distance < 9) {
                            // close enough!
                            return 1;
                        } else if (distance > 225) {
                            // if we are more than 15 units from 'to', add 15 units to try and get past this corpse
                            ignoreEntity = trace["entity"];
                            top = trace["position"] + (15 * direction);
                        } else if (distance > 81) {
                            ignoreEntity = trace["entity"];
                            top = trace["position"] + (9 * direction);
                        } else {
                            ignoreEntity = trace["entity"];
                            top = trace["position"] + (3 * direction);
                        }
                    } else {
                        ignoreEntity = trace["entity"];
                        top = trace["position"];
                    }
                } else {
                    // hit an entity we shouldn't ignore
                    return trace["position"];
                }
            }
        }
    }
    // we somehow failed to find the ground!
    errorPrint("Failed to find the ground!");
    return position;
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

    self endon("disconnect");
    self endon("death");
    level endon("game_ended");

    wait 1.2; // wait until bot is standing up before he starts to move
//     target = bestTarget();
//     self.targetedPlayer = target;
//     self watchTargetedPlayer();
//     iPrintLnBold("Targeting " + self.targetedPlayer.name);
    self.cur_speed = self.walkSpeed;
//     self.speed = self.walkSpeed * 5; // assume current speeds are spec'd per 0.2s
//     self.speed = self.walkSpeed;
    //     self thread move();
    self wander();
}

/// execute the queued movement orders
move()
{
    debugPrint("in _bot::move()", "fn", level.highVerbosity);

    self endon("disconnect");
    self endon("death");
    self endon("movement_invalidated");

//     self findPathToTarget();
//     noticePrint("target position: " + self.targetedPlayer.origin);
//     self walk();
    noticePrint("Moving!");
    while (self.movement.first != self.movement.last) {
        self.lastPosition = self.mover.origin; // needed to compute initial velocity for ballistic()
        position = self.movement.orders[self.movement.first].origin;
        time = self.movement.orders[self.movement.first].time;
        angles = self.movement.orders[self.movement.first].angles;
        noticePrint("moving to:" + position + ", " + time);
        self setPlayerAngles(angles);
        self.mover moveTo(position, time, 0, 0);
        self.mover waittill("movedone");

//         wait time;
//         wait 0.1;
        self.movement.first++;
    }
    // we have executed all the queued movement orders, so reset the queue
    self.movement.first = 0;
    self.movement.last = 0;
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

fixStuck()
{
    debugPrint("in _bot::fixStuck()", "fn", level.highVerbosity);

    self endon("dying");
    self endon("disconnect");
    self endon("death");
    level endon("game_ended");

    lastX = undefined;
    lastY = undefined;
    skipCount = 0;

    while ((!isDefined(self.readyToBeKilled)) || (!self.readyToBeKilled)) {
        wait 0.1;
    }

    while (1) {
        wait 10;
        // stuck bots may be jumping up and down, so ignore z coordinate
        currentX = self.origin[0];
        currentY = self.origin[1];
        if (!isDefined(lastX)) {
            lastX = currentX;
            lastY = currentY;
            continue;
        } else if ((lastX == currentX) && (lastY == currentY)) {
            // If our current target isn't visible (i.e. stealth or admin menu),
            // and is close to us, don't consider ourself to be stuck
            if ((isDefined(self.currentTarget)) && (!self.currentTarget.visible)) {
                distance = distanceSquared(self.origin, self.currentTarget.origin);
                if (distance < 15625) {  // 125 units
                    skipCount++;
                    if (skipCount < 6) {continue;}  // consider us stuck if the target is invisible for too long
                }
            }
            skipCount = 0;
            warnPrint("Fixing potentially stuck bot at " + self.origin + " on map " + getdvar("mapname"));
            // we are stuck!  Move us to a random spawnpoint
            spawnpoint = scripts\gamemodes\_survival::randomSpawnpoint();
            self.mover.origin = spawnpoint.origin;
            self.mover.angles = spawnpoint.angles;
            self.myWaypoint = undefined;
            search();
            // update last
            lastX = spawnpoint.origin[0];
            lastY = spawnpoint.origin[1];
        } else {
            // update last
            lastX = currentX;
            lastY = currentY;
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
