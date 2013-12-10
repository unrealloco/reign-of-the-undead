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

// WAYPOINTS AND PATHFINDING
#include scripts\include\data;
#include scripts\include\utility;

/**
 * @brief Loads internal or external waypoints
 *
 * @returns nothing
 */
loadWaypoints()
{
    debugPrint("in waypoints::loadWaypoints()", "fn", level.nonVerbose);

    level.useKdWaypointTree = false;
    initStatic(); // initialize my hack to enable static member variables

    if ((isDefined(level.Wp)) && (level.Wp.size > 0)) {
        // waypoints were already loaded externally, so don't look for internal ones

        // intialize the k-dimensional waypoint tree
        initKdWaypointTree();
        return;
    }

    level.Wp = [];
    level.WpCount = 0;

    fileName =  "waypoints/"+ tolower(getdvar("mapname")) + "_wp.csv";
    level.WpCount = int(TableLookup(fileName, 0, 0, 1));
    for (i=0; i<level.WpCount; i++) {
        waypoint = spawnstruct();
        level.Wp[i] = waypoint;
        strOrg = TableLookup(fileName, 0, i+1, 1);
        tokens = strtok(strOrg, " ");

        waypoint.origin = (atof(tokens[0]), atof(tokens[1]), atof(tokens[2]));
        waypoint.isLinking = false;
        waypoint.ID = i;
    }
    for (iii=0; iii<level.WpCount; iii++) {
        waypoint = level.Wp[iii];
        strLnk = TableLookup(fileName, 0, iii+1, 2);
        tokens = strtok(strLnk, " ");
        waypoint.linkedCount = tokens.size;
        for (ii=0; ii<tokens.size; ii++) {
            waypoint.linked[ii] = level.Wp[atoi(tokens[ii])];
        }

        // Error catching
        if (!isdefined(waypoint.linked)) {
            iprintlnbold("^1UNLINKED WAYPOINT: " + waypoint.ID + " AT: " +  waypoint.origin);
        }
    }
    // intialize the k-dimensional waypoint tree
    initKdWaypointTree();

}

/**
 * @brief Creates pseudo-static members, since QuakeC doens't include them
 *
 * Tsk, tsk, Mr. Carmack.
 *
 * @returns nothing
 */
initStatic()
{
    debugPrint("in waypoints::initStatic()", "fn", level.nonVerbose);

    // an array and stack of variables so we can fake static member variables.  Needed
    // for kdWaypointNearestNeighbor()
    size = int(getDvarInt("bot_count") * 2);
    level.static = [];
    level.staticStack = [];

    // init the variables and push them onto the stack
    for (i=0; i<size; i++) {
        level.static[i] = "";
        level.staticStack[level.staticStack.size] = i;
    }
}

/**
 * @brief Get the index of an available static variable
 *
 * @returns integer the index of an available variable in level.static
 */
availableStatic()
{
    // 10th most-called function (2% of all function calls).
    // Do *not* put a function entrance debugPrint statement here!

    // ensure our stack is big enough
    if (level.staticStack.size < 3) {
        for (i=level.static.size; i<level.static.size + 10; i++) {
            level.static[i] = "";
            level.staticStack[level.staticStack.size] = i;
        }
    }

    // pop an index off the stack and return it
    index = level.staticStack[level.staticStack.size - 1];
    level.staticStack[level.staticStack.size - 1] = undefined;
    return index;
}

/**
 * @brief Initializes a k-dimensional waypoint tree so we can efficiently find the nearest neighbor
 *
 * @returns nothing
 */
initKdWaypointTree()
{
    debugPrint("in waypoints::initKdWaypointTree()", "fn", level.nonVerbose);

    level.right = 0;
    level.wrong = 0;
    level.treeCalls = 0;
    level.sortCalls = 0;
    level.kdTreeDistanceCount = 0;

    if (level.Wp.size >= 10) {
        // In order for a kd-tree to be efficient, n >> 2^k.  In our case,
        // n = level.Wp.size, and k is 3 as our waypoints are in R^3.  So
        // to use the kd-tree, we prefer the number of waypoints to be much larger
        // than 8.  Even in high-dimensionality, the kd-tree should be slightly
        // faster than a linear search of all the waypoints.
        level.useKdWaypointTree = true;
        findWaypointExtents();
        waypointList = kdWaypointList();
        level.nodes = 0;
        level.visitedNodes = 0;
        level.kdWpTree = kdWaypointTree(waypointList, 0);

        if (false) {
            // perform tests
            kdNearestWpTest(100000, true);
            kdNearestWpTest(100000, false);

            // print kd-tree
            level.kdText = [];
            for (i=0; i<11; i++) {
                level.kdText[i] = "";
            }
            kdPrintNode(level.kdWpTree, 0);
            for (i=0; i<9; i++) {
                noticePrint("depth: " + i + "  " + level.kdText[i]);
            }

            // validate tree
            level.maxDepth = 0;
            kdValidateNode(level.kdWpTree, 0);
            noticePrint("maxDepth: " + level.maxDepth);
        }
    }
}

/**
 * @brief Creates a trimmed down copy of the level.Wp array for use in building the kd-tree
 *
 * The trimmed structs only contain the waypoint id and origin.  We don't just use
 * the real level.Wp, as we don't want heapsort to change it in the process of
 * building the kd-tree.
 *
 * @returns array of trimmed down waypoint structs
 */
kdWaypointList()
{
    debugPrint("in waypoints::kdWaypointList()", "fn", level.nonVerbose);

    waypointList = [];

    for (i=0; i<level.Wp.size; i++) {
        wp = spawnStruct();
        wp.id = level.Wp[i].ID;
        wp.origin = level.Wp[i].origin;
        waypointList[waypointList.size] = wp;
    }

    return waypointList;
}

/**
 * @brief Absolute value
 *
 * @param a numeric The number to find the absolute value of
 *
 * @returns numeric the absolute value of \c a
 */
abs(a)
{
    debugPrint("in waypoints::abs()", "fn", level.nonVerbose);

    if (a < 0) {return a * -1;}
    return a;
}

/**
 * @brief Builds the k-dimensional waypoint tree
 *
 * ***Recursive***
 *
 * @param waypointList array waypoint structs to build the tree with
 * @param depth integer the current depth of the tree
 *
 * @returns node the root node of the tree
 */
kdWaypointTree(waypointList, depth)
{
    debugPrint("in waypoints::kdWaypointTree()", "fn", level.nonVerbose);

    level.treeCalls++;
    if (!isDefined(depth)) {depth = 0;}

    k = 3;              // our waypoints are in R^3
    axis = depth % k;   // cycle the posssible axis each recursion

    waypointList = kdWaypointHeapsort(waypointList, waypointList.size, axis);

    median = int(waypointList.size / 2);   // find the middle element in the sorted waypointList

    // ensure the element just before median is smaller than median, so that the
    // right subarray will be composed of all elements greater than or equal to median.origin[axis]
    splittingValue = waypointList[median].origin[axis];
    while ((isDefined(waypointList[median + 1])) &&
        (waypointList[median + 1].origin[axis] == splittingValue))
    {
        median++;
    }

    // grab all the elements less than the median element
    leftPointList = [];
    for (i=0; i<median; i++) {
        leftPointList[i] = waypointList[i];
    }
    // grab all the elements greater than the median element
    rightPointList = [];
    for (i=median + 1; i<waypointList.size; i++) {
        rightPointList[rightPointList.size] = waypointList[i];
    }

    node = spawnStruct();
    level.nodes++;

    node.id = waypointList[median].id;
    if (leftPointList.size == 0) {
        node.leftChild = undefined;
    } else {
        node.leftChild = kdWaypointTree(leftPointList, depth+1);
    }
    if (rightPointList.size == 0) {
        node.rightChild = undefined;
    } else {
        node.rightChild = kdWaypointTree(rightPointList, depth+1);
    }

    return node;
}

/**
 * @brief Sorts an array of waypoint structs by axis using heapsort
 *
 * @param array the array to sort
 * @param count integer the size of the array
 * @param axis integer the index of the dimension in the origin to sort by.  For 3D, [0|1|2]
 *
 * @returns array the sorted array
 */
kdWaypointHeapsort(array, count, axis)
{
    debugPrint("in waypoints::kdWaypointHeapsort()", "fn", level.medVerbosity);

    // first place a in max-heap order
    array = kdWaypointHeapify(array, count, axis);

    end = count - 1; // in languages with zero-based arrays the children are 2*i+1 and 2*i+2
    while (end > 0) {
        // swap the root(maximum value) of the heap with the last element of the heap
        temp = array[end];
        array[end] = array[0];
        array[0] = temp;

        // decrease the size of the heap by one so that the previous max value will
        // stay in its proper placement
        end--;
        // put the heap back in max-heap order
        array = kdWaypointSiftDown(array, 0, end, axis);
    }
    return array;
}

/**
 * @brief Heapify an arry of waypoint structs by axis
 *
 * @param array the array to heapify
 * @param count integer the size of the array
 * @param axis integer the index of the dimension in the origin to heapify by.  For 3D, [0|1|2]
 *
 * @returns array the sorted array as a heap
 */
kdWaypointHeapify(array, count, axis)
{
    debugPrint("in waypoints::kdWaypointHeapify()", "fn", level.medVerbosity);

    // start is assigned the index in array of the last parent node
    start = int((count - 2) / 2);

    while (start >= 0) {
        // sift down the node at index start to the proper place such that all
        // nodes below the start index are in heap order
        array = kdWaypointSiftDown(array, start, count - 1, axis);
        start--;
        // after sifting down the root all nodes/elements are in heap order
    }
    return array;
}

/**
 * @brief Move an element down to its correct position in the heap
 *
 * A helper function for kdWaypointHeapsort() and kdWaypointHeapify()
 *
 * @param array the array as a heap to reorder
 * @param start integer the starting position in the array
 * @param end integer the end position in the array
 * @param axis integer the index of the dimension in the origin to reorder by.  For 3D, [0|1|2]
 *
 * @returns array the sorted array as a heap
 */
kdWaypointSiftDown(array, start, end, axis)
{
    debugPrint("in waypoints::kdWaypointSiftDown()", "fn", level.highVerbosity);

    // end represents the limit of how far down the heap to sift.
    root = start;

    while (root * 2 + 1 <= end) {       // while the root has at least one child
        child = root * 2 + 1;           // root*2 + 1 points to the left child
        swap = root;                    // keeps track of child to swap with

        // check if root is smaller than left child
        if (array[swap].origin[axis] < array[child].origin[axis]) {
            swap = child;
        }
        // check if right child exists, and if it's bigger than what we're currently swapping with
        if ((child + 1 <= end) && (array[swap].origin[axis] < array[child + 1].origin[axis])) {
            swap = child + 1;
        }
        // check if we need to swap at all
        if (swap != root) {
            temp = array[root];
            array[root] = array[swap];
            array[swap] = temp;
            root = swap;                // repeat to continue sifting the child down
        } else {
            return array;
        }
    }
    return array;
}

/// just for verifying that heapsort works properly
printArray(array, axis, pivotIndex)
{
    debugPrint("in waypoints::printArray()", "fn", level.nonVerbose);

    data = "";
    if (!isDefined(pivotIndex)) {pivotIndex = 0;}

    if (axis == 0) {data = "[x-axis]";}
    else if (axis == 1) {data = "[y-axis]";}
    else if (axis == 2) {data = "[z-axis]";}

    for (i=0; i<array.size; i++) {
        if (i == pivotIndex) {
            data = data + " **[" + array[i].origin[axis] + "]**";
        } else {
            data = data + " [" + array[i].origin[axis] + "]";
        }
    }
    return data;
}

/**
 * @brief Performs a Nearest Neighbor search on the k-dimensional waypoint tree
 *
 * ***Recursive***
 *
 * @param root node The node to begin the search at
 * @param origin the point we want to find the closest waypoint to
 * @param staticIndex integer the index in level.static that will hold the bestDistance
 * @param parent node the parent of the current node
 * @param depth integer the current depth of the tree
 * @param bestNode node the node that corresponds to the bestDistance
 *
 * @returns node the node representing the nearest waypoint
 */
kdWaypointNearestNeighbor(root, origin, staticIndex, parent, depth, bestNode)
{
    // 10th most-called function (2% of all function calls).
    // Do *not* put a function entrance debugPrint statement here!

    if (!isDefined(root)) {
        return bestNode;
    }

    if ((root.id == level.Wp.size) || (root.id == level.Wp.size + 1)) {
        // ignore the two fake waypoints that define the hypercube
        return bestNode;
    }

    if (!isDefined(depth)) {depth = 0;}

    k = 3;              // our waypoints are in R^3
    axis = depth % k;   // cycle the axis each recursion

    // instrumentation
    dim = "";
    if (axis == 0) {dim = "x";}
    else if (axis == 1) {dim = "y";}
    else if (axis == 2) {dim = "z";}
    id = root.id;
    originDim = origin[axis];
    nodeDim = level.Wp[root.id].origin[axis];
    dimDelta = nodeDim - originDim;

    // distance from current node to the search point
    distance = distanceSquared(level.Wp[root.id].origin, origin);
    level.kdTreeDistanceCount++;

    if (distance < level.static[staticIndex]) { // level.static[staticIndex] holds bestDistance
        level.static[staticIndex] = distance;
        bestNode = root;
    }

    // walk the tree until we get to the correct leaf node. If the dimensional coordinate
    // of the search point is less than the dimensional coordinate of the current node,
    // corresponding to a positive dimDelta, then we proceed to the left child,
    // otherwise we proceed to the right child.
    if (dimDelta > 0) {
        bestNode = kdWaypointNearestNeighbor(root.leftChild, origin, staticIndex, root, depth+1, bestNode);
    } else {
        bestNode = kdWaypointNearestNeighbor(root.rightChild, origin, staticIndex, root, depth+1, bestNode);
    }
    // At this point, we have the closest waypoint to the search point that we found
    // in our walk to the leaf node

    // Make sure dimDistance is positive, as distances must be, but preserve sign
    // of dimDelta so we can decide which child to visit if the hypersphere intersects
    // the hyperplane.
    if (dimDelta < 0) {dimDistance = dimDelta * -1;}
    else {dimDistance = dimDelta;}
    dimDistance = dimDistance * dimDistance;    // squared, as we compare with a distanceSquared()

    // level.static[staticIndex] holds bestDistance
    if (dimDistance >= level.static[staticIndex]) {return bestNode;}

    // As we unwind the recursion back to the root node, we need to examine each node
    // to see if the actual closest waypoint may be in the current node's other branch,
    // i.e. does the hypersphere of bestDistance radius cross the node's splitting plane?
    // If it doesn't cross it, then we can rule out this node's other child as potentially
    // containing a closer waypoint--otherwise we need to check the other branch
    if (level.static[staticIndex] > dimDistance) { // level.static[staticIndex] holds bestDistance
        // hypersphere crosses hyperplane, so recurse into other branch to search for
        // a potentially closer node
        if (dimDelta > 0) {
            bestNode = kdWaypointNearestNeighbor(root.rightChild, origin, staticIndex, root, depth+1, bestNode);
        } else {
            bestNode = kdWaypointNearestNeighbor(root.leftChild, origin, staticIndex, root, depth+1, bestNode);
        }
    } else {
        // hypersphere doesn't intersect hyperplane, so we can rule out this node's
        // other branch as potentially containing a closer waypoint
        return bestNode;
    }
    return bestNode;
}

/**
 * @brief Prints the k-dimensional tree to the server log
 *
 * ***Recursive***
 * Due to severe string limitations, we can't print 'large' trees, nor even include
 * anything other that the waypoint id in the printout.
 *
 * @param node the node to print
 * @param depth integer the depth of \c node in the tree
 *
 * @returns nothing
 */
kdPrintNode(node, depth)
{
    debugPrint("in waypoints::kdPrintNode()", "fn", level.medVerbosity);

    // pre-order traversal
    if(!isDefined(node)) {return;}

    k = 3;              // our waypoints are in R^3
    axis = depth % k;   // cycle the posssible axis each recursion
    dim = 0;
    if (axis == 0) {dim = "x";}
    else if (axis == 1) {dim = "y";}
    else if (axis == 2) {dim = "z";}

    padding = "  ";
    level.kdText[depth] += padding + node.id;

    kdPrintNode(node.leftChild, depth+1);
    kdPrintNode(node.rightChild, depth+1);
}

/**
 * @brief Validates the structure of the k-dimensional tree
 *
 * ***Recursive***
 *
 * @param node the node to validate
 * @param depth integer the depth of \c node in the tree
 *
 * @returns nothing
 */
kdValidateNode(node, depth)
{
    debugPrint("in waypoints::kdValidateNode()", "fn", level.medVerbosity);

    // pre-order traversal
    if(!isDefined(node)) {return;}

    k = 3;              // our waypoints are in R^3
    axis = depth % k;   // cycle the possible axis each recursion
    dim = "";
    if (axis == 0) {dim = "x";}
    else if (axis == 1) {dim = "y";}
    else if (axis == 2) {dim = "z";}

    if (depth > level.maxDepth) {level.maxDepth = depth;}

    // for each node, inspect the current axis dimension and compare it to the same
    // axis of its children. The leftChild's axis dimension must be smaller than or equal to the
    // parent's, and the rightChild's axis dimension must be greater than the parent's.
    if (isDefined(node.leftChild)) {
        if (level.Wp[node.leftChild.id].origin[axis] > level.Wp[node.id].origin[axis]) {
            noticePrint("Node " + node.id + "'s .leftChild " + dim + "-axis is > the node's " + dim + "-axis, but it should be smaller or equal!");
        }
    }
    if (isDefined(node.rightChild)) {
        if (level.Wp[node.rightChild.id].origin[axis] <= level.Wp[node.id].origin[axis]) {
            noticePrint("Node " + node.id + "'s .rightChild " + dim + "-axis is <= the node's " + dim + "-axis, but it should be larger!");
        }
    }
    kdValidateNode(node.leftChild, depth+1);
    kdValidateNode(node.rightChild, depth+1);
}

/**
 * @brief Tests the validity and compares the results from NN search and brute-force
 *
 * @param n integer the number of random 3D points fo find the nearest waypoint for
 * @param useMapExtents boolean limit search points to points *within* the 3D volume subtended by the waypoints?
 *
 * @returns nothing
 */
kdNearestWpTest(n, useMapExtents)
{
    debugPrint("in waypoints::kdNearestWpTest()", "fn", level.nonVerbose);

    // n == 100,000 takes a few seconds, but works
    // n == 500,000 takes about 37 seconds, but works
    right = 0;
    wrong = 0;
    percentageRight = 0;
    iterativeDistanceCount = 0;
    level.kdTreeDistanceCount = 0;
    treeSize = level.nodes;
    maxDistError = 0;
    minDistError = 9999999999;
    meanDistError = 0;
    totalDistError = 0;

    for (i=0; i<n; i++) {
        origin = random3dPoint(useMapExtents);   // if true, generate points within 3D volume covered by waypoints

        // iterative method
        nearestWp = -1;
        nearestDistance = 9999999999;
        for(j=0; j < level.WpCount; j++) {
            distance = distanceSquared(origin, level.Wp[j].origin);
            iterativeDistanceCount++;
            if(distance < nearestDistance) {
                nearestDistance = distance;
                nearestWp = j;
            }
        }

        // kd-tree method
        // get an available static member
        index = availableStatic();
        level.static[index] = 9999999999;

        bestNode = kdWaypointNearestNeighbor(level.kdWpTree, origin, index);

        // recycle the static member
        level.static[index] = 0;
        level.staticStack[level.staticStack.size] = index;

        kdNearestWp = bestNode.id;
        if (kdNearestWp == nearestWp) {right++;}
        else {
            wrong++;
            correctDistance = distance(origin, level.Wp[nearestWp].origin);
            wrongDistance = distance(origin, level.Wp[kdNearestWp].origin);
            error = wrongDistance - correctDistance;
            if (error < 0) {error = error * -1;}
            if (error > maxDistError) {maxDistError = error;}
            if (error < minDistError) {minDistError = error;}
            if (n < 5001) { // don't overflow integer
                totalDistError += error;
            }
        }
    }
    if (wrong == 0) {minDistError = 0;}
    else {meanDistError = totalDistError / wrong;}

    // results
    percentageRight = (right / n) * 100;

    noticePrint("-------------------------------------------------------------------------------");
    noticePrint("Waypoint Count: " + level.Wp.size + " Tree Size: " + treeSize);
    if (useMapExtents) {
        noticePrint("Tested " + n + " random 3D points within the map extents.");
    } else {
        noticePrint("Tested " + n + " random 3D points.");
    }
    noticePrint("Accuracy (right, wrong): (" + right + ", " + wrong + ") " + percentageRight + " percent correct.");
    noticePrint("Total distance() calls (iterative, kdtree): (" + iterativeDistanceCount + ", " + level.kdTreeDistanceCount + ")");
    noticePrint("Average distance() calls (iterative, kdtree): (" + iterativeDistanceCount / n + ", " + level.kdTreeDistanceCount / n + ")");
    noticePrint("Distance Errors (min, max, mean): (" + minDistError + ", " + maxDistError + ", " + meanDistError + ")");
    noticePrint("-------------------------------------------------------------------------------");
}

/**
 * @brief Generates a pseudo-random 3D point
 *
 * @param useMapExtents boolean limit points to points *within* the 3D volume subtended by the waypoints?
 *
 * @returns tuple representing a random 3D point
 */
random3dPoint(useMapExtents)
{
    debugPrint("in waypoints::random3dPoint()", "fn", level.fullVerbosity);

    if (!isDefined(useMapExtents)) {useMapExtents = false;}

    if (useMapExtents) {
        x = randomFloatRange(level.waypointMinX, level.waypointMaxX);
        y = randomFloatRange(level.waypointMinY, level.waypointMaxY);
        z = randomFloatRange(level.waypointMinZ, level.waypointMaxZ);
    } else {
        factor = 1.50;
        x = randomFloatRange(level.waypointMinX * factor, level.waypointMaxX * factor);
        y = randomFloatRange(level.waypointMinY * factor, level.waypointMaxY * factor);
        z = randomFloatRange(level.waypointMinZ * factor, level.waypointMaxZ * factor);
    }

    return (x, y, z);
}

/**
 * @brief Finds the extents of the waypoints in the map
 *
 * @returns nothing
 */
findWaypointExtents()
{
    debugPrint("in waypoints::findWaypointExtents()", "fn", level.nonVerbose);

    level.waypointMinX = 0;
    level.waypointMaxX = 0;
    level.waypointMinY = 0;
    level.waypointMaxY = 0;
    level.waypointMinZ = 0;
    level.waypointMaxZ = 0;

    for (i=0; i<level.WpCount; i++) {
        if (level.Wp[i].origin[0] < level.waypointMinX) {level.waypointMinX = level.Wp[i].origin[0];}
        if (level.Wp[i].origin[0] > level.waypointMaxX) {level.waypointMaxX = level.Wp[i].origin[0];}
        if (level.Wp[i].origin[1] < level.waypointMinY) {level.waypointMinY = level.Wp[i].origin[1];}
        if (level.Wp[i].origin[1] > level.waypointMaxY) {level.waypointMaxY = level.Wp[i].origin[1];}
        if (level.Wp[i].origin[2] < level.waypointMinZ) {level.waypointMinZ = level.Wp[i].origin[2];}
        if (level.Wp[i].origin[2] > level.waypointMaxZ) {level.waypointMaxZ = level.Wp[i].origin[2];}
    }
}

/**
 * @brief Finds the nearest waypoint to an arbitrary point
 *
 * Uses the k-dimensional waypoint tree when it exists, otherwise falls back to using brute-force
 *
 * @param origin tuple representing the 3D point to find the nearest waypoint to
 *
 * @returns integer the index of the nearest waypoint
 */
nearestWaypoint(origin)
{
    // 10th most-called function (2% of all function calls).
    // Do *not* put a function entrance debugPrint statement here!

    nearestWp = -1; // not sure why Bipo inits this to -1, will investigate in the new AI

    if (level.useKdWaypointTree) { // be intelligent :-)
        // get an available static member
        index = availableStatic();
        level.static[index] = 9999999999;

        bestNode = kdWaypointNearestNeighbor(level.kdWpTree, origin, index);
        nearestWp = bestNode.id;

        // recycle the static member
        level.static[index] = 0;
        level.staticStack[level.staticStack.size] = index;
    } else {    // use brute-force
        nearestDistance = 9999999999;
        for(i = 0; i < level.WpCount; i++) {
            distance = distancesquared(origin, level.Wp[i].origin);
            if(distance < nearestDistance) {
                nearestDistance = distance;
                nearestWp = i;
            }
        }
    }

    return nearestWp;
}

// A* PATHFINDING ALGORITHM: CREDITS GO TO PEZBOTS!
AStarSearch(startWp, goalWp)
{
    // 20th most-called function (0.4% of all function calls).
    // Do *not* put a function entrance debugPrint statement here!

    pQOpen = [];
    pQSize = 0;
    closedList = [];
    listSize = 0;
    s = spawnstruct();
    s.g = 0; //start node
    s.h = distance(level.Wp[startWp].origin, level.Wp[goalWp].origin);
    s.f = s.g + s.h;
    s.wpIdx = startWp;
    s.parent = spawnstruct();
    s.parent.wpIdx = -1;

    //push s on Open
    pQOpen[pQSize] = spawnstruct();
    pQOpen[pQSize] = s; //push s on Open
    pQSize++;

    //while Open is not empty
    while (!PQIsEmpty(pQOpen, pQSize))
    {
        //pop node n from Open  // n has the lowest f
        n = pQOpen[0];
        highestPriority = 9999999999;
        bestNode = -1;
        for (i=0; i<pQSize; i++) {
            if (pQOpen[i].f < highestPriority) {
                bestNode = i;
                highestPriority = pQOpen[i].f;
            }
        }

        if (bestNode != -1) {
            n = pQOpen[bestNode];
            //remove node from queue
            for (i=bestNode; i<pQSize-1; i++) {
                pQOpen[i] = pQOpen[i+1];
            }
            pQSize--;
        } else {
            return -1;
        }

        //if n is a goal node; construct path, return success
        if (n.wpIdx == goalWp) {
            x = n;
            for (z = 0; z < 1000; z++) {
                parent = x.parent;
                if(parent.parent.wpIdx == -1) {return x.wpIdx;}
//                 line(level.Wp[x.wpIdx].origin, level.Wp[parent.wpIdx].origin, (0,1,0));
                x = parent;
            }
            return -1;
        }

        //for each successor nc of n
        for (i=0; i<level.Wp[n.wpIdx].linkedCount; i++) {
            //newg = n.g + cost(n,nc)
            newg = n.g + distance(level.Wp[n.wpIdx].origin, level.Wp[level.Wp[n.wpIdx].linked[i].ID].origin);

            //if nc is in Open or Closed, and nc.g <= newg then skip
            if (PQExists(pQOpen, level.Wp[n.wpIdx].linked[i].ID, pQSize)) {
                //find nc in open
                nc = spawnstruct();
                for(p = 0; p < pQSize; p++) {
                    if (pQOpen[p].wpIdx == level.Wp[n.wpIdx].linked[i].ID) {
                        nc = pQOpen[p];
                        break;
                    }
                }
                if (nc.g <= newg) {continue;}
            } else {
                if (ListExists(closedList, level.Wp[n.wpIdx].linked[i].ID, listSize)) {
                    //find nc in closed list
                    nc = spawnstruct();
                    for (p=0; p<listSize; p++) {
                        if (closedList[p].wpIdx == level.Wp[n.wpIdx].linked[i].ID) {
                            nc = closedList[p];
                            break;
                        }
                    }

                    if(nc.g <= newg) {continue;}
                }
            }
//             nc.parent = n
//             nc.g = newg
//             nc.h = GoalDistEstimate( nc )
//             nc.f = nc.g + nc.h

            nc = spawnstruct();
            nc.parent = spawnstruct();
            nc.parent = n;
            nc.g = newg;
            nc.h = distance(level.Wp[level.Wp[n.wpIdx].linked[i].ID].origin, level.Wp[goalWp].origin);
            nc.f = nc.g + nc.h;
            nc.wpIdx = level.Wp[n.wpIdx].linked[i].ID;

            //if nc is in Closed,
            if (ListExists(closedList, nc.wpIdx, listSize)) {
                //remove it from Closed
                deleted = false;
                for (p=0; p<listSize; p++) {
                    if(closedList[p].wpIdx == nc.wpIdx) {
                        for(x = p; x < listSize-1; x++) {
                            closedList[x] = closedList[x+1];
                        }
                        deleted = true;
                        break;
                    }
                    if (deleted) {break;}
                }
                listSize--;
            }

            //if nc is not yet in Open,
            if (!PQExists(pQOpen, nc.wpIdx, pQSize)) {
                //push nc on Open
                pQOpen[pQSize] = spawnstruct();
                pQOpen[pQSize] = nc;
                pQSize++;
            }
        }

        //Done with children, push n onto Closed
        if (!ListExists(closedList, n.wpIdx, listSize)) {
            closedList[listSize] = spawnstruct();
            closedList[listSize] = n;
            listSize++;
        }
    }
}



////////////////////////////////////////////////////////////
// PQIsEmpty, returns true if empty
////////////////////////////////////////////////////////////
PQIsEmpty(Q, QSize)
{
    // 5th most-called function (5% of all function calls).
    // Do *not* put a function entrance debugPrint statement here!

    if (QSize <= 0) {return true;}

    return false;
}


////////////////////////////////////////////////////////////
// returns true if n exists in the pQ
////////////////////////////////////////////////////////////
PQExists(Q, n, QSize)
{
    // 2nd most-called function (22% of all function calls).
    // Do *not* put a function entrance debugPrint statement here!

    for (i=0; i<QSize; i++) {
        if(Q[i].wpIdx == n) {return true;}
    }

    return false;
}

////////////////////////////////////////////////////////////
// returns true if n exists in the list
////////////////////////////////////////////////////////////
ListExists(list, n, listSize)
{
    // 1st most-called function (26% of all function calls).
    // Do *not* put a function entrance debugPrint statement here!

    for (i=0; i<listSize; i++) {
        if (list[i].wpIdx == n) {return true;}
    }

    return false;
}

