var dsiDebug = false;
/*///////////////////////////////////////////////////////////////////////////////////////////////

                          ──────────────────────────────────────────
                          ─████████████───██████████████─██████████─
                          ─██        ████─██          ██─██      ██─
                          ─██  ████    ██─██  ██████████─████  ████─
                          ─██  ██──██  ██─██  ██───────────██  ██───
                          ─██  ██──██  ██─██  ██████████───██  ██───
                          ─██  ██──██  ██─██          ██───██  ██───
                          ─██  ██──██  ██─██████████  ██───██  ██───
                          ─██  ██──██  ██─────────██  ██───██  ██───
                          ─██  ████    ██─██████████  ██─████  ████─
                          ─██        ████─██          ██─██      ██─
                          ─████████████───██████████████─██████████─
                          ──────────────────────────────────────────
///////////////////////////////////////////////////////////////////////////////////////////////*/
// DSI: Post Header

customer = "HYDROSPACE GROUP"; // customer name
oem = "DMS"; // oem name
model = "3B5-5-10-10SCxLxx"; // model number
control = "Fagor 8040"; // control name
vendor = "DSI";
vendorUrl = "http://www.dsi-mfg.com";
legal = "Copyright (C) 2012-2024 by Autodesk, Inc.";
certificationLevel = 2;
minimumRevision = 45917; // Minimum post kernel revision
dsiPostVersion = "1.0"; // DSI post version
//***************************

postDescription = [oem, model].join(" "); // post description
longDescription = [
  postDescription,
  "Post Processor with",
  control,
  "Control",
].join(" "); // long description

///////////////////////////////////////////////////////////////////////////////////////////////

extension = "pim";
programNameIsInteger = false;
setCodePage("ascii");

capabilities = CAPABILITY_MILLING | CAPABILITY_MACHINE_SIMULATION;
tolerance = spatial(0.002, MM);

minimumChordLength = spatial(0.25, MM);
minimumCircularRadius = spatial(0.01, MM);
maximumCircularRadius = spatial(1000, MM);
minimumCircularSweep = toRad(0.01);
maximumCircularSweep = toRad(180);
allowHelicalMoves = true;
allowedCircularPlanes = undefined; // allow any circular motion
highFeedrate = unit == MM ? 5000 : 200;

// user-defined properties
properties = {
  preloadTool: {
    title: "Preload tool",
    description: "Preloads the next tool at a tool change (if any).",
    group: "preferences",
    type: "boolean",
    value: true,
    scope: "post",
  },
  showSequenceNumbers: {
    title: "Use sequence numbers",
    description:
      "'Yes' outputs sequence numbers on each block, 'Only on tool change' outputs sequence numbers on tool change blocks only, and 'No' disables the output of sequence numbers.",
    group: "formats",
    type: "enum",
    values: [
      { title: "Yes", id: "true" },
      { title: "No", id: "false" },
      { title: "Only on tool change", id: "toolChange" },
    ],
    value: "true",
    scope: "post",
  },
  sequenceNumberStart: {
    title: "Start sequence number",
    description: "The number at which to start the sequence numbers.",
    group: "formats",
    type: "integer",
    value: 10,
    scope: "post",
  },
  sequenceNumberIncrement: {
    title: "Sequence number increment",
    description:
      "The amount by which the sequence number is incremented by in each block.",
    group: "formats",
    type: "integer",
    value: 5,
    scope: "post",
  },
  optionalStop: {
    title: "Optional stop",
    description:
      "Outputs optional stop code during when necessary in the code.",
    group: "preferences",
    type: "boolean",
    value: true,
    scope: "post",
  },
  separateWordsWithSpace: {
    title: "Separate words with space",
    description: "Adds spaces between words if 'yes' is selected.",
    group: "formats",
    type: "boolean",
    value: true,
    scope: "post",
  },
  useG16: {
    title: "Use G16",
    description: "If enables, G16 is used instead of G17/G18/G19.",
    group: "preferences",
    type: "boolean",
    value: false,
    scope: "post",
  },
  tappingMode: {
    title: "Tapping mode",
    description: "Select the tapping mode.",
    group: "preferences",
    type: "enum",
    values: [
      { title: "Normal", id: "0" },
      { title: "Rigid orient", id: "1" },
      { title: "Rigid", id: "2" },
    ],
    value: "0",
    scope: "post",
  },
  useSmoothing: {
    title: "Use smoothing",
    description: "Specifies if smoothing (G51) should be used or not.",
    group: "preferences",
    type: "boolean",
    value: false,
    scope: "post",
  },
  contouringAcceleration: {
    title: "Smoothing contouring acceleration",
    description: "Acceleration percentage used for G51 look-ahead smoothing.",
    group: "preferences",
    type: "number",
    value: 60,
    scope: "post",
  },
  contouringError: {
    title: "Smoothing contouring error",
    description: "Error allowed during G51 look-ahead smoothing.",
    group: "preferences",
    type: "number",
    value: 0.001,
    scope: "post",
  },
  rotaryTableAxis: {
    title: "Rotary table axis",
    description:
      "Select rotary table axis. Check the table direction on the machine and use the (Reversed) selection if the table is moving in the opposite direction.",
    group: "configuration",
    type: "enum",
    values: [
      { title: "No rotary", id: "none" },
      { title: "X", id: "x" },
      { title: "Y", id: "y" },
      { title: "Z", id: "z" },
      { title: "X (Reversed)", id: "-x" },
      { title: "Y (Reversed)", id: "-y" },
      { title: "Z (Reversed)", id: "-z" },
    ],
    value: "none",
    scope: "post",
  },
  safePositionMethod: {
    title: "Safe Retracts",
    description:
      "Select your desired retract option. 'Clearance Height' retracts to the operation clearance height.",
    group: "homePositions",
    type: "enum",
    values: [
      // {title:"G28", id: "G28"},
      { title: "G53", id: "G53" },
      { title: "Clearance Height", id: "clearanceHeight" },
    ],
    value: "G53",
    scope: "post",
  },
};

// wcs definiton
wcsDefinitions = {
  useZeroOffset: false,
  wcs: [{ name: "Standard", format: "G", range: [54, 59] }],
};

var gFormat = createFormat({ prefix: "G", decimals: 1 });
var mFormat = createFormat({ prefix: "M", decimals: 0 });
var diameterOffsetFormat = createFormat({ prefix: "D", decimals: 0 });

var xyzFormat = createFormat({ decimals: unit == MM ? 3 : 4 });
var abcFormat = createFormat({ decimals: 3, type: FORMAT_REAL, scale: DEG });
var feedFormat = createFormat({ decimals: unit == MM ? 0 : 1 });
var inverseTimeFormat = createFormat({ decimals: 4, type: FORMAT_REAL });
var toolFormat = createFormat({ decimals: 0 });
var rpmFormat = createFormat({ decimals: 0 });
var kFormat = createFormat({ decimals: 0 }); // centiseconds - range 0-99999
var taperFormat = createFormat({ decimals: 1, scale: DEG });
var eFormat = createFormat({ decimals: 5 });
var accelFormat = createFormat({ decimals: 0 });

var xOutput = createOutputVariable(
  {
    onchange: function () {
      state.retractedX = false;
    },
    prefix: "X",
  },
  xyzFormat
);
var yOutput = createOutputVariable(
  {
    onchange: function () {
      state.retractedY = false;
    },
    prefix: "Y",
  },
  xyzFormat
);
var zOutput = createOutputVariable(
  {
    onchange: function () {
      state.retractedZ = false;
    },
    prefix: "Z",
  },
  xyzFormat
);
var aOutput = createOutputVariable({ prefix: "A" }, abcFormat);
var bOutput = createOutputVariable({ prefix: "B" }, abcFormat);
var cOutput = createOutputVariable({ prefix: "C" }, abcFormat);
var feedOutput = createOutputVariable({ prefix: "F" }, feedFormat);
var inverseTimeOutput = createOutputVariable(
  { prefix: "F", control: CONTROL_FORCE },
  inverseTimeFormat
);
var sOutput = createOutputVariable(
  { prefix: "S", control: CONTROL_FORCE },
  rpmFormat
);

// circular output
var iOutput = createOutputVariable(
  { prefix: "I", control: CONTROL_FORCE },
  xyzFormat
);
var jOutput = createOutputVariable(
  { prefix: "J", control: CONTROL_FORCE },
  xyzFormat
);
var kOutput = createOutputVariable(
  { prefix: "K", control: CONTROL_FORCE },
  xyzFormat
);

var gMotionModal = createOutputVariable({}, gFormat); // modal group 1 // G0-G3, ...
var gPlaneModal = createOutputVariable(
  {
    onchange: function () {
      gMotionModal.reset();
    },
  },
  gFormat
); // modal group 2 // G16-19
var gAbsIncModal = createOutputVariable({}, gFormat); // modal group 3 // G90-91
var gFeedModeModal = createOutputVariable({}, gFormat); // modal group 5 // G94-95
var gUnitModal = createOutputVariable({}, gFormat); // modal group 6 // G70-71
var gCycleModal = createOutputVariable({}, gFormat); // modal group 9 // G81, ...
var gRetractModal = createOutputVariable({}, gFormat); // modal group 10 // G98-99
var fourthAxisClamp = createOutputVariable({}, mFormat);
var fifthAxisClamp = createOutputVariable({}, mFormat);

var settings = {
  coolant: {
    // samples:
    // {id: COOLANT_THROUGH_TOOL, on: 88, off: 89}
    // {id: COOLANT_THROUGH_TOOL, on: [8, 88], off: [9, 89]}
    // {id: COOLANT_THROUGH_TOOL, on: "M88 P3 (myComment)", off: "M89"}
    coolants: [
      { id: COOLANT_FLOOD, on: 8 },
      { id: COOLANT_MIST },
      { id: COOLANT_THROUGH_TOOL, on: 88, off: 89 },
      { id: COOLANT_AIR },
      { id: COOLANT_AIR_THROUGH_TOOL },
      { id: COOLANT_SUCTION },
      { id: COOLANT_FLOOD_MIST },
      { id: COOLANT_FLOOD_THROUGH_TOOL, on: [8, 88], off: [9, 89] },
      { id: COOLANT_OFF, off: 9 },
    ],
    singleLineCoolant: false, // specifies to output multiple coolant codes in one line rather than in separate lines
  },
  retract: {
    cancelRotationOnRetracting: false, // specifies that rotations (G68) need to be canceled prior to retracting
    methodXY: undefined, // special condition, overwrite retract behavior per axis
    methodZ: undefined, // special condition, overwrite retract behavior per axis
    useZeroValues: ["G28", "G30"], // enter property value id(s) for using "0" value instead of machineConfiguration axes home position values (ie G30 Z0)
    homeXY: {
      onIndexing: false,
      onToolChange: false,
      onProgramEnd: { axes: [X, Y] },
    }, // Specifies when the machine should be homed in X/Y. Sample: onIndexing:{axes:[X, Y], singleLine:false}
  },
  machineAngles: {
    // refer to https://cam.autodesk.com/posts/reference/classMachineConfiguration.html#a14bcc7550639c482492b4ad05b1580c8
    controllingAxis: ABC,
    type: PREFER_PREFERENCE,
    options: ENABLE_ALL,
  },
  workPlaneMethod: {
    useTiltedWorkplane: false, // specifies that tilted workplanes should be used (ie. G68.2, G254, PLANE SPATIAL, CYCLE800), can be overwritten by property
    eulerConvention: EULER_ZXZ_R, // specifies the euler convention (ie EULER_XYZ_R), set to undefined to use machine angles for TWP commands ('undefined' requires machine configuration)
    eulerCalculationMethod: "standard", // ('standard' / 'machine') 'machine' adjusts euler angles to match the machines ABC orientation, machine configuration required
    cancelTiltFirst: false, // cancel tilted workplane prior to WCS (G54-G59) blocks
    forceMultiAxisIndexing: false, // force multi-axis indexing for 3D programs
    optimizeType: OPTIMIZE_AXIS, // can be set to OPTIMIZE_NONE, OPTIMIZE_BOTH, OPTIMIZE_TABLES, OPTIMIZE_HEADS, OPTIMIZE_AXIS. 'undefined' uses legacy rotations
  },
  comments: {
    permittedCommentChars: " abcdefghijklmnopqrstuvwxyz0123456789.,=_-", // letters are not case sensitive, use option 'outputFormat' below. Set to 'undefined' to allow any character
    prefix: "; ", // specifies the prefix for the comment
    suffix: "", // specifies the suffix for the comment
    outputFormat: "upperCase", // can be set to "upperCase", "lowerCase" and "ignoreCase". Set to "ignoreCase" to write comments without upper/lower case formattingd "none". Set to "none" to output comments without additional formatting
    maximumLineLength: 80, // the maximum number of characters allowed in a line, set to 0 to disable comment output
  },
  maximumSequenceNumber: undefined, // the maximum sequence number (Nxxx), use 'undefined' for unlimited
  maximumToolNumber: 99, // specifies the maximum allowed tool number
  maximumToolLengthOffset: 99, // specifies the maximum allowed tool length offset number
  maximumToolDiameterOffset: 99, // specifies the maximum allowed tool diameter offset number
  outputToolLengthOffset: false, // specifies if tool length offset code should be output (Hxx)
};

// collected state
var currentPlane;

function getG16(plane) {
  if (currentPlane != plane) {
    currentPlane = plane;
    return formatWords(gFormat.format(16), plane);
  }
  return [];
}

/**
  Compare a text string to acceptable choices.

  Returns -1 if there is no match.
*/
function parseChoice() {
  for (var i = 1; i < arguments.length; ++i) {
    if (
      String(arguments[0]).toUpperCase() == String(arguments[i]).toUpperCase()
    ) {
      return i - 1;
    }
  }
  return -1;
}

function defineMachine() {
  // Defining machine kinematic from post property, legacy definition
  // Define rotary attributes from properties
  var rotary = parseChoice(
    getProperty("rotaryTableAxis"),
    "-Z",
    "-Y",
    "-X",
    "NONE",
    "X",
    "Y",
    "Z"
  );
  if (rotary < 0) {
    error(
      localize("Valid rotaryTableAxis values are: None, X, Y, Z, -X, -Y, -Z")
    );
    return;
  }
  rotary -= 3;

  // Define Master (carrier) axis
  var masterAxis = Math.abs(rotary) - 1;
  if (masterAxis >= 0) {
    var rotaryVector = [0, 0, 0];
    rotaryVector[masterAxis] = rotary / Math.abs(rotary);
    var aAxis = createAxis({
      coordinate: 0,
      table: true,
      axis: rotaryVector,
      cyclic: true,
      preference: 0,
      tcp: false,
    });
    machineConfiguration = new MachineConfiguration(aAxis);

    setMachineConfiguration(machineConfiguration);
    // Single rotary does not use TCP mode
    //optimizeMachineAngles2(1); // 0 = TCP Mode ON, 1 = TCP Mode OFF
  }

  var useTCP = false;
  // machine kinematic may be defined,
  // 1- by the post property 4th axis table only
  // 2- by setting if (true) and defining rotary axis
  // 3- by receiving a machine configuration from the software

  if (false) {
    // note: setup your machine here
    if (rotary != 0) {
      warning(
        "The kinematic defined via the post property will be overwritten by the post defined kinematic."
      );
    }
    var aAxis = createAxis({
      coordinate: 0,
      table: true,
      axis: [1, 0, 0],
      range: [-120, 120],
      preference: 1,
      tcp: useTCP,
    });
    var cAxis = createAxis({
      coordinate: 2,
      table: true,
      axis: [0, 0, 1],
      range: [-360, 360],
      preference: 0,
      tcp: useTCP,
    });
    machineConfiguration = new MachineConfiguration(aAxis, cAxis);

    setMachineConfiguration(machineConfiguration);
    if (receivedMachineConfiguration) {
      warning(
        localize(
          "The provided CAM machine configuration is overwritten by the postprocessor."
        )
      );
      receivedMachineConfiguration = false; // CAM provided machine configuration is overwritten
    }
  }

  if (rotary != 0 && receivedMachineConfiguration) {
    warning(
      localize(
        "The provided CAM machine configuration is overwritten by the postprocessor property."
      )
    );
    receivedMachineConfiguration = false; // CAM provided machine configuration is overwritten
  }

  if (!receivedMachineConfiguration) {
    // multiaxis settings
    if (machineConfiguration.isHeadConfiguration()) {
      machineConfiguration.setVirtualTooltip(false); // translate the pivot point to the virtual tool tip for nonTCP rotary heads
    }

    // retract / reconfigure
    var performRewinds = false; // set to true to enable the rewind/reconfigure logic
    if (performRewinds) {
      machineConfiguration.enableMachineRewinds(); // enables the retract/reconfigure logic
      safeRetractDistance = unit == IN ? 1 : 25; // additional distance to retract out of stock, can be overridden with a property
      safeRetractFeed = unit == IN ? 20 : 500; // retract feed rate
      safePlungeFeed = unit == IN ? 10 : 250; // plunge feed rate
      machineConfiguration.setSafeRetractDistance(safeRetractDistance);
      machineConfiguration.setSafeRetractFeedrate(safeRetractFeed);
      machineConfiguration.setSafePlungeFeedrate(safePlungeFeed);
      var stockExpansion = new Vector(
        toPreciseUnit(0.1, IN),
        toPreciseUnit(0.1, IN),
        toPreciseUnit(0.1, IN)
      ); // expand stock XYZ values
      machineConfiguration.setRewindStockExpansion(stockExpansion);
    }

    // multi-axis feedrates
    if (machineConfiguration.isMultiAxisConfiguration()) {
      machineConfiguration.setMultiAxisFeedrate(
        useTCP
          ? FEED_FPM
          : getProperty("useDPMFeeds")
          ? FEED_DPM
          : FEED_INVERSE_TIME,
        99999.99, // maximum output value for inverse time feed rates
        getProperty("useDPMFeeds") ? DPM_COMBINATION : INVERSE_MINUTES, // INVERSE_MINUTES/INVERSE_SECONDS or DPM_COMBINATION/DPM_STANDARD
        0.5, // tolerance to determine when the DPM feed has changed
        1.0 // ratio of rotary accuracy to linear accuracy for DPM calculations
      );
      setMachineConfiguration(machineConfiguration);
    }

    /* home positions */
    // machineConfiguration.setHomePositionX(toPreciseUnit(0, IN));
    // machineConfiguration.setHomePositionY(toPreciseUnit(0, IN));
    // machineConfiguration.setRetractPlane(toPreciseUnit(0, IN));
  }
}

function onOpen() {
  // define and enable machine configuration
  receivedMachineConfiguration = machineConfiguration.isReceived();
  if (typeof defineMachine == "function") {
    defineMachine(); // hardcoded machine configuration
  }
  activateMachine(); // enable the machine optimizations and settings

  if (!getProperty("separateWordsWithSpace")) {
    setWordSeparator("");
  }

  if (programName) {
    writeln("%" + programName + ",MX--,"); // max 20 chars
  } else {
    error(localize("Program name has not been specified."));
  }
  if (programComment) {
    writeComment(programComment);
  }
  writeHeader();

  // absolute coordinates and feed per min
  writeBlock(
    gAbsIncModal.format(90),
    gFeedModeModal.format(94),
    conditional(!getProperty("useG16"), gPlaneModal.format(17))
  );
  if (getProperty("useG16")) {
    writeBlock(getG16("XY"));
  }
  writeBlock(gUnitModal.format(unit == MM ? 71 : 70));
  validateCommonParameters();
}

var currentSmoothing = undefined;

function setSmoothing(mode) {
  if (mode == currentSmoothing) {
    return false;
  }

  currentSmoothing = mode;
  if (mode) {
    writeBlock(
      gFormat.format(51),
      "A" + accelFormat.format(getProperty("contouringAcceleration")),
      "E" + eFormat.format(getProperty("contouringError"))
    ); // enable look ahead
  } else {
    writeBlock(gFormat.format(7));
  }
  return true;
}

function onParameter(name, value) {}

function onSection() {
  var forceSectionRestart = optionalSection && !currentSection.isOptional();
  optionalSection = currentSection.isOptional();
  var insertToolCall = isToolChangeNeeded("number") || forceSectionRestart;
  var newWorkOffset = isNewWorkOffset() || forceSectionRestart;
  var newWorkPlane = isNewWorkPlane() || forceSectionRestart;
  operationNeedsSafeStart =
    getProperty("safeStartAllOperations") && !isFirstSection();

  var forceSmoothing =
    getProperty("useSmoothing") &&
    ((hasParameter("operation-strategy") &&
      getParameter("operation-strategy") == "drill") ||
      (!isFirstSection() &&
        getPreviousSection().hasParameter("operation-strategy") &&
        getPreviousSection().getParameter("operation-strategy") == "drill")); // force smoothing in case !insertToolCall (2d chamfer)

  if (
    insertToolCall ||
    newWorkOffset ||
    newWorkPlane ||
    forceSmoothing ||
    state.tcpIsActive ||
    currentSection.isMultiAxis()
  ) {
    if (insertToolCall && !isFirstSection()) {
      onCommand(COMMAND_COOLANT_OFF); // turn off coolant before retract during tool change
      onCommand(COMMAND_STOP_SPINDLE); // stop spindle before retract during tool change
    }
    writeRetract(Z); // retract
    if (state.tcpIsActive) {
      writeBlock(toolLengthCompOutput.format(49));
    }
    forceXYZ();
    if (isFirstSection()) {
      cancelWorkPlane(
        machineConfiguration.isMultiAxisConfiguration() &&
          settings.workPlaneMethod.useTiltedWorkplane
      );
      if (machineConfiguration.isMultiAxisConfiguration()) {
        positionABC(new Vector(0, 0, 0));
      }
      forceABC();
    } else {
      if (insertToolCall || isNewWorkPlane) {
        cancelWorkPlane();
      }
    }
    if (getProperty("useSmoothing")) {
      setSmoothing(false);
    }
  }

  writeComment(getParameter("operation-comment", ""));

  // tool change
  writeToolCall(tool, insertToolCall);
  if (
    !isTappingCycle() ||
    (isTappingCycle() && !(getProperty("useRigidTapping") == "without"))
  ) {
    startSpindle(tool, insertToolCall);
  }

  if (getProperty("useSmoothing")) {
    setSmoothing(
      !(
        hasParameter("operation-strategy") &&
        getParameter("operation-strategy") == "drill"
      )
    );
  }

  // Enable smoothing for all non-drilling toolpaths
  if (
    !(
      hasParameter("operation-strategy") &&
      getParameter("operation-strategy") == "drill"
    )
  ) {
    writeBlock("G51 A45 E0.002");
  }

  // Output modal commands here
  writeBlock(
    gPlaneModal.format(17),
    gAbsIncModal.format(90),
    gFeedModeModal.format(94)
  );

  // set wcs
  var wcsIsRequired = true;
  if (insertToolCall || operationNeedsSafeStart) {
    currentWorkOffset = undefined; // force work offset when changing tool
    wcsIsRequired = newWorkOffset || insertToolCall || !operationNeedsSafeStart;
  }
  writeWCS(currentSection, wcsIsRequired);

  forceXYZ();

  var abc = defineWorkPlane(
    currentSection,
    !machineConfiguration.isHeadConfiguration()
  );

  setCoolant(tool.coolant); // writes the required coolant codes

  // prepositioning
  var initialPosition = getFramePosition(currentSection.getInitialPosition());
  var isRequired =
    insertToolCall ||
    state.retractedZ ||
    !state.lengthCompensationActive ||
    (!isFirstSection() && getPreviousSection().isMultiAxis());
  if (isRequired) {
    currentPlane = undefined;
    if (getProperty("useG16")) {
      writeBlock(getG16("XY"));
      gPlaneModal.format(17); // format only
    } else {
      writeBlock(gPlaneModal.format(17));
    }
  }
  writeInitialPositioning(initialPosition, isRequired);

  state.retractedZ = false;
}

function onDwell(seconds) {
  var maxValue = 999.99;
  if (seconds > maxValue) {
    warning(
      subst(
        localize(
          "Dwelling time of '%1' exceeds the maximum value of '%2' in operation '%3'"
        ),
        seconds,
        maxValue,
        getParameter("operation-comment", "")
      )
    );
  }
  time = clamp(1, seconds * 100, 99999);
  writeBlock(gFormat.format(4), "K" + kFormat.format(time));
}

function onSpindleSpeed(spindleSpeed) {
  writeBlock(sOutput.format(spindleSpeed));
}

function onCycle() {
  if (getProperty("useG16")) {
    writeBlock(getG16("XY"), gFeedModeModal.format(94));
  } else {
    writeBlock(gPlaneModal.format(17), gFeedModeModal.format(94));
  }
}

function getCommonCycle(x, y, reference, bottom) {
  forceXYZ();
  return [
    xOutput.format(x),
    yOutput.format(y),
    "Z" + xyzFormat.format(reference),
    "I" + xyzFormat.format(bottom),
  ];
}

function onCyclePoint(x, y, z) {
  if (
    !isSameDirection(
      machineConfiguration.getSpindleAxis(),
      getForwardDirection(currentSection)
    )
  ) {
    expandCyclePoint(x, y, z);
    return;
  }
  if (isFirstCyclePoint()) {
    repositionToCycleClearance(cycle, x, y, z);

    // return to initial Z which is clearance plane and set absolute mode

    var F = cycle.feedrate;
    var K = cycle.dwell == 0 ? 0 : clamp(1, cycle.dwell * 100, 99999);

    switch (cycleType) {
      case "drilling":
        writeBlock(
          gRetractModal.format(98),
          gAbsIncModal.format(90),
          gCycleModal.format(81),
          getCommonCycle(x, y, cycle.retract, cycle.bottom),
          K > 0 ? "K" + kFormat.format(K) : "",
          feedOutput.format(F)
        );
        break;
      case "counter-boring":
        writeBlock(
          gRetractModal.format(98),
          gAbsIncModal.format(90),
          gCycleModal.format(82),
          getCommonCycle(x, y, cycle.retract, cycle.bottom),
          "K" + kFormat.format(K),
          feedOutput.format(F)
        );
        break;
      case "chip-breaking":
        if (cycle.accumulatedDepth < cycle.depth) {
          expandCyclePoint(x, y, z);
        } else {
          writeBlock(
            gRetractModal.format(98),
            gAbsIncModal.format(90),
            gCycleModal.format(69),
            getCommonCycle(x, y, cycle.retract, cycle.bottom),
            "B" + xyzFormat.format(cycle.incrementalDepth),
            // "C" + xyzFormat.format(machineParameters.drillingSafeDistance),
            "D" + xyzFormat.format(cycle.retract - cycle.stock),
            "H" +
              xyzFormat.format(
                cycle.chipBreakDistance != undefined
                  ? cycle.chipBreakDistance
                  : machineParameters.chipBreakingDistance
              ),
            "J" + cycle.plungesPerRetract,
            K > 0 ? "K" + kFormat.format(K) : "",
            cycle.minimumIncrementalDepth > 0
              ? "L" + xyzFormat.format(cycle.minimumIncrementalDepth)
              : "",
            cycle.incrementalDepthReduction > 0
              ? "R" +
                  xyzFormat.format(
                    1 - cycle.incrementalDepthReduction / cycle.incrementalDepth
                  )
              : "",
            feedOutput.format(F)
          );
        }
        break;
      case "deep-drilling":
        if (cycle.incrementalDepthReduction > 0 || K > 0) {
          writeBlock(
            gRetractModal.format(98),
            gAbsIncModal.format(90),
            gCycleModal.format(69),
            getCommonCycle(x, y, cycle.retract, cycle.bottom),
            "B" + xyzFormat.format(cycle.incrementalDepth),
            // "C" + xyzFormat.format(machineParameters.drillingSafeDistance),
            "D" + xyzFormat.format(cycle.retract - cycle.stock),
            "J" + cycle.plungesPerRetract,
            K > 0 ? "K" + kFormat.format(K) : "",
            cycle.minimumIncrementalDepth > 0
              ? "L" + xyzFormat.format(cycle.minimumIncrementalDepth)
              : "",
            cycle.incrementalDepthReduction > 0
              ? "R" +
                  xyzFormat.format(
                    1 - cycle.incrementalDepthReduction / cycle.incrementalDepth
                  )
              : "",
            feedOutput.format(F)
          );
        } else {
          var plunges = Math.max(
            Math.floor((cycle.retract - cycle.bottom) / cycle.incrementalDepth),
            1
          );
          var incrementalDepth = -(cycle.retract - cycle.bottom) / plunges;
          writeBlock(
            gRetractModal.format(98),
            gAbsIncModal.format(90),
            gCycleModal.format(83),
            xOutput.format(x) + yOutput.format(y),
            "Z" + xyzFormat.format(cycle.retract),
            "I" + xyzFormat.format(incrementalDepth),
            "J" + xyzFormat.format(plunges),
            feedOutput.format(F)
          );
        }
        break;
      case "tapping":
        if (tool.type == TOOL_TAP_LEFT_HAND) {
          expandCyclePoint(x, y, z);
        } else {
          if (!F) {
            F = tool.getTappingFeedrate();
          }
          writeBlock(
            gRetractModal.format(98),
            gAbsIncModal.format(90),
            gCycleModal.format(84),
            getCommonCycle(x, y, cycle.retract, cycle.bottom),
            K > 0 ? "K" + kFormat.format(K) : "",
            "R" + getProperty("tappingMode"),
            feedOutput.format(F)
          );
        }
        break;
      case "left-tapping":
        expandCyclePoint(x, y, z);
        break;
      case "right-tapping":
        if (!F) {
          F = tool.getTappingFeedrate();
        }
        writeBlock(
          gRetractModal.format(98),
          gAbsIncModal.format(90),
          gCycleModal.format(84),
          getCommonCycle(x, y, cycle.retract, cycle.bottom),
          K > 0 ? "K" + kFormat.format(K) : "",
          "R" + getProperty("tappingMode"),
          feedOutput.format(F)
        );
        break;
      case "fine-boring":
        expandCyclePoint(x, y, z);
        break;
      case "back-boring":
        expandCyclePoint(x, y, z);
        break;
      case "reaming":
        writeBlock(
          gRetractModal.format(98),
          gAbsIncModal.format(90),
          gCycleModal.format(85),
          getCommonCycle(x, y, cycle.retract, cycle.bottom),
          K > 0 ? "K" + kFormat.format(K) : "",
          feedOutput.format(F)
        );
        break;
      case "stop-boring":
        writeBlock(
          gRetractModal.format(98),
          gAbsIncModal.format(90),
          gCycleModal.format(86),
          getCommonCycle(x, y, cycle.retract, cycle.bottom),
          K > 0 ? "K" + kFormat.format(K) : "",
          feedOutput.format(F)
        );
        break;
      case "manual-boring":
        expandCyclePoint(x, y, z);
        break;
      case "boring":
        writeBlock(
          gRetractModal.format(98),
          gAbsIncModal.format(90),
          gCycleModal.format(89),
          getCommonCycle(x, y, cycle.retract, cycle.bottom),
          K > 0 ? "K" + kFormat.format(K) : "",
          feedOutput.format(F)
        );
        break;
      default:
        expandCyclePoint(x, y, z);
    }
  } else {
    if (cycleExpanded) {
      expandCyclePoint(x, y, z);
    } else {
      writeBlock(xOutput.format(x), yOutput.format(y));
    }
  }
}

function onCycleEnd() {
  if (!cycleExpanded) {
    writeBlock(gCycleModal.format(80));
    zOutput.reset();
  }
}

function onLinear5D(_x, _y, _z, _a, _b, _c, feed, feedMode) {
  if (pendingRadiusCompensation >= 0) {
    error(
      localize(
        "Radius compensation cannot be activated/deactivated for 5-axis move."
      )
    );
    return;
  }
  if (!currentSection.isOptimizedForMachine()) {
    forceXYZ();
  }
  var x = xOutput.format(_x);
  var y = yOutput.format(_y);
  var z = zOutput.format(_z);
  var a = currentSection.isOptimizedForMachine()
    ? aOutput.format(_a)
    : toolVectorOutputI.format(_a);
  var b = currentSection.isOptimizedForMachine()
    ? bOutput.format(_b)
    : toolVectorOutputJ.format(_b);
  var c = currentSection.isOptimizedForMachine()
    ? cOutput.format(_c)
    : toolVectorOutputK.format(_c);
  if (feedMode == FEED_INVERSE_TIME) {
    forceFeed();
  }
  var f =
    feedMode == FEED_INVERSE_TIME
      ? inverseTimeOutput.format(feed)
      : getFeed(feed);
  var fMode = feedMode == FEED_INVERSE_TIME ? 32 : 94;

  if (x || y || z || a || b || c) {
    writeBlock(
      gFeedModeModal.format(fMode),
      gMotionModal.format(1),
      x,
      y,
      z,
      a,
      b,
      c,
      f
    );
  } else if (f) {
    if (getNextRecord().isMotion()) {
      // try not to output feed without motion
      forceFeed(); // force feed on next line
    } else {
      writeBlock(gFeedModeModal.format(fMode), gMotionModal.format(1), f);
    }
  }
}

function onCircular(clockwise, cx, cy, cz, x, y, z, feed) {
  if (pendingRadiusCompensation >= 0) {
    error(
      localize(
        "Radius compensation cannot be activated/deactivated for a circular move."
      )
    );
    return;
  }

  var start = getCurrentPosition();

  if (isFullCircle()) {
    if (isHelical()) {
      linearize(tolerance);
      return;
    }
    switch (getCircularPlane()) {
      case PLANE_XY:
        if (getProperty("useG16")) {
          writeBlock(getG16("XY"));
        }
        writeBlock(
          gAbsIncModal.format(90),
          conditional(!getProperty("useG16"), gPlaneModal.format(17)),
          gFeedModeModal.format(94),
          gMotionModal.format(clockwise ? 2 : 3),
          iOutput.format(cx - start.x),
          jOutput.format(cy - start.y),
          feedOutput.format(feed)
        );
        break;
      case PLANE_ZX:
        if (getProperty("useG16")) {
          writeBlock(getG16("ZX"));
        }
        writeBlock(
          gAbsIncModal.format(90),
          conditional(!getProperty("useG16"), gPlaneModal.format(18)),
          gFeedModeModal.format(94),
          gMotionModal.format(clockwise ? 2 : 3),
          iOutput.format(cx - start.x),
          kOutput.format(cz - start.z),
          feedOutput.format(feed)
        );
        break;
      case PLANE_YZ:
        if (getProperty("useG16")) {
          writeBlock(getG16("YZ"));
        }
        writeBlock(
          gAbsIncModal.format(90),
          conditional(!getProperty("useG16"), gPlaneModal.format(19)),
          gFeedModeModal.format(94),
          gMotionModal.format(clockwise ? 2 : 3),
          jOutput.format(cy - start.y),
          kOutput.format(cz - start.z),
          feedOutput.format(feed)
        );
        break;
      default:
        linearize(tolerance);
    }
  } else {
    switch (getCircularPlane()) {
      case PLANE_XY:
        if (getProperty("useG16")) {
          writeBlock(getG16("XY"));
        }
        writeBlock(
          gAbsIncModal.format(90),
          conditional(!getProperty("useG16"), gPlaneModal.format(17)),
          gFeedModeModal.format(94),
          gMotionModal.format(clockwise ? 2 : 3),
          xOutput.format(x),
          yOutput.format(y),
          iOutput.format(cx - start.x),
          jOutput.format(cy - start.y),
          zOutput.format(z),
          feedOutput.format(feed)
        );
        break;
      case PLANE_ZX:
        if (isHelical()) {
          linearize(tolerance);
          return;
        }
        if (getProperty("useG16")) {
          writeBlock(getG16("ZX"));
        }
        writeBlock(
          gAbsIncModal.format(90),
          conditional(!getProperty("useG16"), gPlaneModal.format(18)),
          gFeedModeModal.format(94),
          gMotionModal.format(clockwise ? 2 : 3),
          xOutput.format(x),
          yOutput.format(y),
          zOutput.format(z),
          iOutput.format(cx - start.x),
          kOutput.format(cz - start.z),
          feedOutput.format(feed)
        );
        break;
      case PLANE_YZ:
        if (isHelical()) {
          linearize(tolerance);
          return;
        }
        if (getProperty("useG16")) {
          writeBlock(getG16("YZ"));
        }
        writeBlock(
          gAbsIncModal.format(90),
          conditional(!getProperty("useG16"), gPlaneModal.format(19)),
          gFeedModeModal.format(94),
          gMotionModal.format(clockwise ? 2 : 3),
          xOutput.format(x),
          yOutput.format(y),
          zOutput.format(z),
          jOutput.format(cy - start.y),
          kOutput.format(cz - start.z),
          feedOutput.format(feed)
        );
        break;
      default:
        linearize(tolerance);
    }
  }
}

var mapCommand = {
  COMMAND_END: 2,
  COMMAND_SPINDLE_CLOCKWISE: 3,
  COMMAND_SPINDLE_COUNTERCLOCKWISE: 4,
  COMMAND_STOP_SPINDLE: 5,
  COMMAND_ORIENTATE_SPINDLE: 19,
  COMMAND_LOAD_TOOL: 6,
};

function onCommand(command) {
  switch (command) {
    case COMMAND_COOLANT_OFF:
      setCoolant(COOLANT_OFF);
      return;
    case COMMAND_COOLANT_ON:
      setCoolant(COOLANT_FLOOD);
      return;
    case COMMAND_STOP:
      writeBlock(mFormat.format(0));
      forceSpindleSpeed = true;
      forceCoolant = true;
      return;
    case COMMAND_OPTIONAL_STOP:
      writeBlock(mFormat.format(1));
      forceSpindleSpeed = true;
      forceCoolant = true;
      return;
    case COMMAND_START_SPINDLE:
      forceSpindleSpeed = false;
      writeBlock(
        sOutput.format(spindleSpeed),
        mFormat.format(tool.clockwise ? 3 : 4)
      );
      return;
    case COMMAND_LOAD_TOOL:
      writeToolBlock("T" + toolFormat.format(tool.number));
      writeBlock(mFormat.format(6));
      writeComment(tool.comment);

      var preloadTool = getNextTool(tool.number != getFirstTool().number);
      if (getProperty("preloadTool") && preloadTool) {
        writeBlock("T" + toolFormat.format(preloadTool.number)); // preload next/first tool
      }
      return;
    case COMMAND_LOCK_MULTI_AXIS:
      if (machineConfiguration.isMultiAxisConfiguration()) {
        // writeBlock(fourthAxisClamp.format(25)); // lock 4th axis
        if (machineConfiguration.getNumberOfAxes() > 4) {
          // writeBlock(fifthAxisClamp.format(35)); // lock 5th axis
        }
      }
      return;
    case COMMAND_UNLOCK_MULTI_AXIS:
      if (machineConfiguration.isMultiAxisConfiguration()) {
        // writeBlock(fourthAxisClamp.format(26)); // unlock 4th axis
        if (machineConfiguration.getNumberOfAxes() > 4) {
          // writeBlock(fifthAxisClamp.format(36)); // unlock 5th axis
        }
      }
      return;
    case COMMAND_START_CHIP_TRANSPORT:
      return;
    case COMMAND_STOP_CHIP_TRANSPORT:
      return;
    case COMMAND_BREAK_CONTROL:
      return;
    case COMMAND_TOOL_MEASURE:
      return;
    case COMMAND_PROBE_ON:
      return;
    case COMMAND_PROBE_OFF:
      return;
  }

  var stringId = getCommandStringId(command);
  var mcode = mapCommand[stringId];
  if (mcode != undefined) {
    writeBlock(mFormat.format(mcode));
  } else {
    onUnsupportedCommand(command);
  }
}

function onSectionEnd() {
  if (!isLastSection()) {
    if (getNextSection().getTool().coolant != tool.coolant) {
      setCoolant(COOLANT_OFF);
    }
    if (
      tool.breakControl &&
      isToolChangeNeeded(
        getNextSection(),
        getProperty("toolAsName") ? "description" : "number"
      )
    ) {
      onCommand(COMMAND_BREAK_CONTROL);
    }
  }
  forceAny();

  operationNeedsSafeStart = false; // reset for next section
}

// Start of onRewindMachine logic
/** Allow user to override the onRewind logic. */
function onRewindMachineEntry(_a, _b, _c) {
  return false;
}

/** Retract to safe position before indexing rotaries. */
function onMoveToSafeRetractPosition() {
  writeRetract(Z);
  // cancel TCP so that tool doesn't follow rotaries
  if (currentSection.isMultiAxis() && tcp.isSupportedByOperation) {
    disableLengthCompensation(false, "TCPC OFF");
  }
}

/** Rotate axes to new position above reentry position */
function onRotateAxes(_x, _y, _z, _a, _b, _c) {
  // position rotary axes
  xOutput.disable();
  yOutput.disable();
  zOutput.disable();
  onRapid5D(_x, _y, _z, _a, _b, _c);
  setCurrentABC(new Vector(_a, _b, _c));
  machineSimulation({ a: _a, b: _b, c: _c, coordinates: MACHINE });
  xOutput.enable();
  yOutput.enable();
  zOutput.enable();
}

/** Return from safe position after indexing rotaries. */
function onReturnFromSafeRetractPosition(_x, _y, _z) {
  // reinstate TCP / tool length compensation
  if (!state.lengthCompensationActive) {
    writeBlock(getOffsetCode(), hFormat.format(tool.lengthOffset));
  }

  // position in XY
  forceXYZ();
  xOutput.reset();
  yOutput.reset();
  zOutput.disable();
  if (highFeedMapping != HIGH_FEED_NO_MAPPING) {
    onLinear(_x, _y, _z, highFeedrate);
  } else {
    onRapid(_x, _y, _z);
  }
  machineSimulation({ x: _x, y: _y });
  // position in Z
  zOutput.enable();
  invokeOnRapid(_x, _y, _z);
}
// End of onRewindMachine logic

function onClose() {
  optionalSection = false;
  onCommand(COMMAND_COOLANT_OFF);
  onCommand(COMMAND_STOP_SPINDLE);
  writeRetract(Z);
  forceWorkPlane();
  setWorkPlane(new Vector(0, 0, 0)); // reset working plane
  if (getSetting("retract.homeXY.onProgramEnd", false)) {
    writeRetract(settings.retract.homeXY.onProgramEnd);
  }
  writeBlock(mFormat.format(30)); // stop program, spindle stop
  writeln("%");
}

// >>>>> INCLUDED FROM include_files/commonFunctions.cpi
// internal variables, do not change
var receivedMachineConfiguration;
var tcp = {
  isSupportedByControl: getSetting("supportsTCP", true),
  isSupportedByMachine: false,
  isSupportedByOperation: false,
};
var state = {
  retractedX: false, // specifies that the machine has been retracted in X
  retractedY: false, // specifies that the machine has been retracted in Y
  retractedZ: false, // specifies that the machine has been retracted in Z
  tcpIsActive: false, // specifies that TCP is currently active
  twpIsActive: false, // specifies that TWP is currently active
  lengthCompensationActive: !getSetting("outputToolLengthCompensation", true), // specifies that tool length compensation is active
  mainState: true, // specifies the current context of the state (true = main, false = optional)
};
var validateLengthCompensation = getSetting(
  "outputToolLengthCompensation",
  true
); // disable validation when outputToolLengthCompensation is disabled
var multiAxisFeedrate;
var sequenceNumber;
var optionalSection = false;
var currentWorkOffset;
var forceSpindleSpeed = false;
var operationNeedsSafeStart = false; // used to convert blocks to optional for safeStartAllOperations

function activateMachine() {
  // disable unsupported rotary axes output
  if (
    !machineConfiguration.isMachineCoordinate(0) &&
    typeof aOutput != "undefined"
  ) {
    aOutput.disable();
  }
  if (
    !machineConfiguration.isMachineCoordinate(1) &&
    typeof bOutput != "undefined"
  ) {
    bOutput.disable();
  }
  if (
    !machineConfiguration.isMachineCoordinate(2) &&
    typeof cOutput != "undefined"
  ) {
    cOutput.disable();
  }

  // setup usage of useTiltedWorkplane
  settings.workPlaneMethod.useTiltedWorkplane =
    getProperty("useTiltedWorkplane") != undefined
      ? getProperty("useTiltedWorkplane")
      : getSetting("workPlaneMethod.useTiltedWorkplane", false);
  settings.workPlaneMethod.useABCPrepositioning = getSetting(
    "workPlaneMethod.useABCPrepositioning",
    true
  );

  if (!machineConfiguration.isMultiAxisConfiguration()) {
    return; // don't need to modify any settings for 3-axis machines
  }

  // identify if any of the rotary axes has TCP enabled
  var axes = [
    machineConfiguration.getAxisU(),
    machineConfiguration.getAxisV(),
    machineConfiguration.getAxisW(),
  ];
  tcp.isSupportedByMachine = axes.some(function (axis) {
    return axis.isEnabled() && axis.isTCPEnabled();
  }); // true if TCP is enabled on any rotary axis

  // save multi-axis feedrate settings from machine configuration
  var mode = machineConfiguration.getMultiAxisFeedrateMode();
  var type =
    mode == FEED_INVERSE_TIME
      ? machineConfiguration.getMultiAxisFeedrateInverseTimeUnits()
      : mode == FEED_DPM
      ? machineConfiguration.getMultiAxisFeedrateDPMType()
      : DPM_STANDARD;
  multiAxisFeedrate = {
    mode: mode,
    maximum: machineConfiguration.getMultiAxisFeedrateMaximum(),
    type: type,
    tolerance:
      mode == FEED_DPM
        ? machineConfiguration.getMultiAxisFeedrateOutputTolerance()
        : 0,
    bpwRatio:
      mode == FEED_DPM
        ? machineConfiguration.getMultiAxisFeedrateBpwRatio()
        : 1,
  };

  // setup of retract/reconfigure  TAG: Only needed until post kernel supports these machine config settings
  if (receivedMachineConfiguration && machineConfiguration.performRewinds()) {
    safeRetractDistance = machineConfiguration.getSafeRetractDistance();
    safePlungeFeed = machineConfiguration.getSafePlungeFeedrate();
    safeRetractFeed = machineConfiguration.getSafeRetractFeedrate();
  }
  if (
    typeof safeRetractDistance == "number" &&
    getProperty("safeRetractDistance") != undefined &&
    getProperty("safeRetractDistance") != 0
  ) {
    safeRetractDistance = getProperty("safeRetractDistance");
  }

  if (revision >= 50294) {
    activateAutoPolarMode({
      tolerance: tolerance / 2,
      optimizeType: OPTIMIZE_AXIS,
      expandCycles: getSetting("polarCycleExpandMode", EXPAND_ALL),
    });
  }

  if (
    machineConfiguration.isHeadConfiguration() &&
    getSetting("workPlaneMethod.compensateToolLength", false)
  ) {
    for (var i = 0; i < getNumberOfSections(); ++i) {
      var section = getSection(i);
      if (section.isMultiAxis()) {
        machineConfiguration.setToolLength(getBodyLength(section.getTool())); // define the tool length for head adjustments
        section.optimizeMachineAnglesByMachine(
          machineConfiguration,
          OPTIMIZE_AXIS
        );
      }
    }
  } else {
    optimizeMachineAngles2(OPTIMIZE_AXIS);
  }
}

function getBodyLength(tool) {
  for (var i = 0; i < getNumberOfSections(); ++i) {
    var section = getSection(i);
    if (tool.number == section.getTool().number) {
      if (section.hasParameter("operation:tool_assemblyGaugeLength")) {
        // For Fusion
        return section.getParameter(
          "operation:tool_assemblyGaugeLength",
          tool.bodyLength + tool.holderLength
        );
      } else {
        // Legacy products
        return section.getParameter(
          "operation:tool_overallLength",
          tool.bodyLength + tool.holderLength
        );
      }
    }
  }
  return tool.bodyLength + tool.holderLength;
}

function getFeed(f) {
  if (getProperty("useG95")) {
    return feedOutput.format(f / spindleSpeed); // use feed value
  }
  if (typeof activeMovements != "undefined" && activeMovements) {
    var feedContext = activeMovements[movement];
    if (feedContext != undefined) {
      if (!feedFormat.areDifferent(feedContext.feed, f)) {
        if (feedContext.id == currentFeedId) {
          return ""; // nothing has changed
        }
        forceFeed();
        currentFeedId = feedContext.id;
        return (
          settings.parametricFeeds.feedOutputVariable +
          (settings.parametricFeeds.firstFeedParameter + feedContext.id)
        );
      }
    }
    currentFeedId = undefined; // force parametric feed next time
  }
  return feedOutput.format(f); // use feed value
}

function validateCommonParameters() {
  validateToolData();
  for (var i = 0; i < getNumberOfSections(); ++i) {
    var section = getSection(i);
    if (getSection(0).workOffset == 0 && section.workOffset > 0) {
      if (
        !(typeof wcsDefinitions != "undefined" && wcsDefinitions.useZeroOffset)
      ) {
        error(
          localize(
            "Using multiple work offsets is not possible if the initial work offset is 0."
          )
        );
      }
    }
    if (section.isMultiAxis()) {
      if (
        !section.isOptimizedForMachine() &&
        (!getSetting("workPlaneMethod.useTiltedWorkplane", false) ||
          !getSetting("supportsToolVectorOutput", false))
      ) {
        error(
          localize(
            "This postprocessor requires a machine configuration for 5-axis simultaneous toolpath."
          )
        );
      }
      if (
        machineConfiguration.getMultiAxisFeedrateMode() == FEED_INVERSE_TIME &&
        !getSetting("supportsInverseTimeFeed", true)
      ) {
        error(
          localize(
            "This postprocessor does not support inverse time feedrates."
          )
        );
      }
      if (
        getSetting("supportsToolVectorOutput", false) &&
        !tcp.isSupportedByControl
      ) {
        error(
          localize(
            "Incompatible postprocessor settings detected." +
              EOL +
              "Setting 'supportsToolVectorOutput' requires setting 'supportsTCP' to be enabled as well."
          )
        );
      }
    }
  }
  if (!tcp.isSupportedByControl && tcp.isSupportedByMachine) {
    error(
      localize(
        "The machine configuration has TCP enabled which is not supported by this postprocessor."
      )
    );
  }
  if (getProperty("safePositionMethod") == "clearanceHeight") {
    var msg =
      "-Attention- Property 'Safe Retracts' is set to 'Clearance Height'." +
      EOL +
      "Ensure the clearance height will clear the part and or fixtures." +
      EOL +
      "Raise the Z-axis to a safe height before starting the program.";
    warning(msg);
    writeComment(msg);
  }
}

function validateToolData() {
  var _default = 99999;
  var _maximumSpindleRPM =
    machineConfiguration.getMaximumSpindleSpeed() > 0
      ? machineConfiguration.getMaximumSpindleSpeed()
      : settings.maximumSpindleRPM == undefined
      ? _default
      : settings.maximumSpindleRPM;
  var _maximumToolNumber =
    machineConfiguration.isReceived() &&
    machineConfiguration.getNumberOfTools() > 0
      ? machineConfiguration.getNumberOfTools()
      : settings.maximumToolNumber == undefined
      ? _default
      : settings.maximumToolNumber;
  var _maximumToolLengthOffset =
    settings.maximumToolLengthOffset == undefined
      ? _default
      : settings.maximumToolLengthOffset;
  var _maximumToolDiameterOffset =
    settings.maximumToolDiameterOffset == undefined
      ? _default
      : settings.maximumToolDiameterOffset;

  var header = ["Detected maximum values are out of range.", "Maximum values:"];
  var warnings = {
    toolNumber: {
      msg: "Tool number value exceeds the maximum value for tool: " + EOL,
      max: " Tool number: " + _maximumToolNumber,
      values: [],
    },
    lengthOffset: {
      msg:
        "Tool length offset value exceeds the maximum value for tool: " + EOL,
      max: " Tool length offset: " + _maximumToolLengthOffset,
      values: [],
    },
    diameterOffset: {
      msg:
        "Tool diameter offset value exceeds the maximum value for tool: " + EOL,
      max: " Tool diameter offset: " + _maximumToolDiameterOffset,
      values: [],
    },
    spindleSpeed: {
      msg: "Spindle speed exceeds the maximum value for operation: " + EOL,
      max: " Spindle speed: " + _maximumSpindleRPM,
      values: [],
    },
  };

  var toolIds = [];
  for (var i = 0; i < getNumberOfSections(); ++i) {
    var section = getSection(i);
    if (toolIds.indexOf(section.getTool().getToolId()) === -1) {
      // loops only through sections which have a different tool ID
      var toolNumber = section.getTool().number;
      var lengthOffset = section.getTool().lengthOffset;
      var diameterOffset = section.getTool().diameterOffset;
      var comment = section.getParameter("operation-comment", "");

      if (toolNumber > _maximumToolNumber && !getProperty("toolAsName")) {
        warnings.toolNumber.values.push(SP + toolNumber + EOL);
      }
      if (lengthOffset > _maximumToolLengthOffset) {
        warnings.lengthOffset.values.push(
          SP +
            "Tool " +
            toolNumber +
            " (" +
            comment +
            "," +
            " Length offset: " +
            lengthOffset +
            ")" +
            EOL
        );
      }
      if (diameterOffset > _maximumToolDiameterOffset) {
        warnings.diameterOffset.values.push(
          SP +
            "Tool " +
            toolNumber +
            " (" +
            comment +
            "," +
            " Diameter offset: " +
            diameterOffset +
            ")" +
            EOL
        );
      }
      toolIds.push(section.getTool().getToolId());
    }
    // loop through all sections regardless of tool id for idenitfying spindle speeds

    // identify if movement ramp is used in current toolpath, use ramp spindle speed for comparisons
    var ramp =
      section.getMovements() &
      ((1 << MOVEMENT_RAMP) |
        (1 << MOVEMENT_RAMP_ZIG_ZAG) |
        (1 << MOVEMENT_RAMP_PROFILE) |
        (1 << MOVEMENT_RAMP_HELIX));
    var _sectionSpindleSpeed = Math.max(
      section.getTool().spindleRPM,
      ramp ? section.getTool().rampingSpindleRPM : 0,
      0
    );
    if (_sectionSpindleSpeed > _maximumSpindleRPM) {
      warnings.spindleSpeed.values.push(
        SP +
          section.getParameter("operation-comment", "") +
          " (" +
          _sectionSpindleSpeed +
          " RPM" +
          ")" +
          EOL
      );
    }
  }

  // sort lists by tool number
  warnings.toolNumber.values.sort(function (a, b) {
    return a - b;
  });
  warnings.lengthOffset.values.sort(function (a, b) {
    return a.localeCompare(b);
  });
  warnings.diameterOffset.values.sort(function (a, b) {
    return a.localeCompare(b);
  });

  var warningMessages = [];
  for (var key in warnings) {
    if (warnings[key].values != "") {
      header.push(warnings[key].max); // add affected max values to the header
      warningMessages.push(warnings[key].msg + warnings[key].values.join(""));
    }
  }
  if (warningMessages.length != 0) {
    warningMessages.unshift(header.join(EOL) + EOL);
    warning(warningMessages.join(EOL));
  }
}

function forceFeed() {
  currentFeedId = undefined;
  feedOutput.reset();
}

/** Force output of X, Y, and Z. */
function forceXYZ() {
  xOutput.reset();
  yOutput.reset();
  zOutput.reset();
}

/** Force output of A, B, and C. */
function forceABC() {
  aOutput.reset();
  bOutput.reset();
  cOutput.reset();
}

/** Force output of X, Y, Z, A, B, C, and F on next output. */
function forceAny() {
  forceXYZ();
  forceABC();
  forceFeed();
}

/**
  Writes the specified block.
*/
function writeBlock() {
  var text = formatWords(arguments);
  if (!text) {
    return;
  }
  var prefix = getSetting("sequenceNumberPrefix", "N");
  var suffix = getSetting("writeBlockSuffix", "");
  if (
    (optionalSection || skipBlocks) &&
    !getSetting("supportsOptionalBlocks", true)
  ) {
    error(localize("Optional blocks are not supported by this post."));
  }
  if (getProperty("showSequenceNumbers") == "true") {
    if (
      sequenceNumber == undefined ||
      sequenceNumber >= settings.maximumSequenceNumber
    ) {
      sequenceNumber = getProperty("sequenceNumberStart");
    }
    if (optionalSection || skipBlocks) {
      writeWords2("/", prefix + sequenceNumber, text + suffix);
    } else {
      writeWords2(prefix + sequenceNumber, text + suffix);
    }
    sequenceNumber += getProperty("sequenceNumberIncrement");
  } else {
    if (optionalSection || skipBlocks) {
      writeWords2("/", text + suffix);
    } else {
      writeWords(text + suffix);
    }
  }
}

validate(settings.comments, "Setting 'comments' is required but not defined.");
function formatComment(text) {
  var prefix = settings.comments.prefix;
  var suffix = settings.comments.suffix;
  var _permittedCommentChars =
    settings.comments.permittedCommentChars == undefined
      ? ""
      : settings.comments.permittedCommentChars;
  switch (settings.comments.outputFormat) {
    case "upperCase":
      text = text.toUpperCase();
      _permittedCommentChars = _permittedCommentChars.toUpperCase();
      break;
    case "lowerCase":
      text = text.toLowerCase();
      _permittedCommentChars = _permittedCommentChars.toLowerCase();
      break;
    case "ignoreCase":
      _permittedCommentChars =
        _permittedCommentChars.toUpperCase() +
        _permittedCommentChars.toLowerCase();
      break;
    default:
      error(
        localize(
          "Unsupported option specified for setting 'comments.outputFormat'."
        )
      );
  }
  if (_permittedCommentChars != "") {
    text = filterText(String(text), _permittedCommentChars);
  }
  text = String(text).substring(
    0,
    settings.comments.maximumLineLength - prefix.length - suffix.length
  );
  return text != "" ? prefix + text + suffix : "";
}

/**
  Output a comment.
*/
function writeComment(text) {
  if (!text) {
    return;
  }
  var comments = String(text).split(EOL);
  for (comment in comments) {
    var _comment = formatComment(comments[comment]);
    if (_comment) {
      if (getSetting("comments.showSequenceNumbers", false)) {
        writeBlock(_comment);
      } else {
        writeln(_comment);
      }
    }
  }
}

function onComment(text) {
  writeComment(text);
}

/**
  Writes the specified block - used for tool changes only.
*/
function writeToolBlock() {
  var show = getProperty("showSequenceNumbers");
  setProperty(
    "showSequenceNumbers",
    show == "true" || show == "toolChange" ? "true" : "false"
  );
  writeBlock(arguments);
  setProperty("showSequenceNumbers", show);
  machineSimulation({
    /*x:toPreciseUnit(200, MM), y:toPreciseUnit(200, MM), coordinates:MACHINE,*/ mode: TOOLCHANGE,
  }); // move machineSimulation to a tool change position
}

var skipBlocks = false;
var initialState = JSON.parse(JSON.stringify(state)); // save initial state
var optionalState = JSON.parse(JSON.stringify(state));
var saveCurrentSectionId = undefined;
function writeStartBlocks(isRequired, code) {
  var saveSkipBlocks = skipBlocks;
  var saveMainState = state; // save main state

  if (!isRequired) {
    if (!getProperty("safeStartAllOperations", false)) {
      return; // when safeStartAllOperations is disabled, dont output code and return
    }
    if (saveCurrentSectionId != getCurrentSectionId()) {
      saveCurrentSectionId = getCurrentSectionId();
      forceModals(); // force all modal variables when entering a new section
      optionalState = Object.create(initialState); // reset optionalState to initialState when entering a new section
    }
    skipBlocks = true; // if values are not required, but safeStartAllOperations is enabled - write following blocks as optional
    state = optionalState; // set state to optionalState if skipBlocks is true
    state.mainState = false;
  }
  code(); // writes out the code which is passed to this function as an argument

  state = saveMainState; // restore main state
  skipBlocks = saveSkipBlocks; // restore skipBlocks value
}

var pendingRadiusCompensation = -1;
function onRadiusCompensation() {
  pendingRadiusCompensation = radiusCompensation;
  if (
    pendingRadiusCompensation >= 0 &&
    !getSetting("supportsRadiusCompensation", true)
  ) {
    error(localize("Radius compensation mode is not supported."));
    return;
  }
}

function onPassThrough(text) {
  var commands = String(text).split(",");
  for (text in commands) {
    writeBlock(commands[text]);
  }
}

function forceModals() {
  if (arguments.length == 0) {
    // reset all modal variables listed below
    if (typeof gMotionModal != "undefined") {
      gMotionModal.reset();
    }
    if (typeof gPlaneModal != "undefined") {
      gPlaneModal.reset();
    }
    if (typeof gAbsIncModal != "undefined") {
      gAbsIncModal.reset();
    }
    if (typeof gFeedModeModal != "undefined") {
      gFeedModeModal.reset();
    }
  } else {
    for (var i in arguments) {
      arguments[i].reset(); // only reset the modal variable passed to this function
    }
  }
}

/** Helper function to be able to use a default value for settings which do not exist. */
function getSetting(setting, defaultValue) {
  var result = defaultValue;
  var keys = setting.split(".");
  var obj = settings;
  for (var i in keys) {
    if (obj[keys[i]] != undefined) {
      // setting does exist
      result = obj[keys[i]];
      if (typeof [keys[i]] === "object") {
        obj = obj[keys[i]];
        continue;
      }
    } else {
      // setting does not exist, use default value
      if (defaultValue != undefined) {
        result = defaultValue;
      } else {
        error(
          "Setting '" +
            keys[i] +
            "' has no default value and/or does not exist."
        );
        return undefined;
      }
    }
  }
  return result;
}

function getForwardDirection(_section) {
  var forward = undefined;
  var _optimizeType =
    settings.workPlaneMethod && settings.workPlaneMethod.optimizeType;
  if (_section.isMultiAxis()) {
    forward = _section.workPlane.forward;
  } else if (
    !getSetting("workPlaneMethod.useTiltedWorkplane", false) &&
    machineConfiguration.isMultiAxisConfiguration()
  ) {
    if (_optimizeType == undefined) {
      var saveRotation = getRotation();
      getWorkPlaneMachineABC(_section, true);
      forward = getRotation().forward;
      setRotation(saveRotation); // reset rotation
    } else {
      var abc = getWorkPlaneMachineABC(_section, false);
      var forceAdjustment =
        settings.workPlaneMethod.optimizeType == OPTIMIZE_TABLES ||
        settings.workPlaneMethod.optimizeType == OPTIMIZE_BOTH;
      forward = machineConfiguration.getOptimizedDirection(
        _section.workPlane.forward,
        abc,
        false,
        forceAdjustment
      );
    }
  } else {
    forward = getRotation().forward;
  }
  return forward;
}

function getRetractParameters() {
  var _arguments =
    typeof arguments[0] === "object" ? arguments[0].axes : arguments;
  var singleLine =
    arguments[0].singleLine == undefined ? true : arguments[0].singleLine;
  var words = []; // store all retracted axes in an array
  var retractAxes = new Array(false, false, false);
  var method = getProperty("safePositionMethod", "undefined");
  if (method == "clearanceHeight") {
    if (!is3D()) {
      error(
        localize(
          "Safe retract option 'Clearance Height' is only supported when all operations are along the setup Z-axis."
        )
      );
    }
    return undefined;
  }
  validate(settings.retract, "Setting 'retract' is required but not defined.");
  validate(
    _arguments.length != 0,
    "No axis specified for getRetractParameters()."
  );
  for (i in _arguments) {
    retractAxes[_arguments[i]] = true;
  }
  if ((retractAxes[0] || retractAxes[1]) && !state.retractedZ) {
    // retract Z first before moving to X/Y home
    error(
      localize(
        "Retracting in X/Y is not possible without being retracted in Z."
      )
    );
    return undefined;
  }
  // special conditions
  if (retractAxes[0] || retractAxes[1]) {
    method = getSetting("retract.methodXY", method);
  }
  if (retractAxes[2]) {
    method = getSetting("retract.methodZ", method);
  }
  // define home positions
  var useZeroValues =
    settings.retract.useZeroValues &&
    settings.retract.useZeroValues.indexOf(method) != -1;
  var _xHome =
    machineConfiguration.hasHomePositionX() && !useZeroValues
      ? machineConfiguration.getHomePositionX()
      : toPreciseUnit(0, MM);
  var _yHome =
    machineConfiguration.hasHomePositionY() && !useZeroValues
      ? machineConfiguration.getHomePositionY()
      : toPreciseUnit(0, MM);
  var _zHome =
    machineConfiguration.getRetractPlane() != 0 && !useZeroValues
      ? machineConfiguration.getRetractPlane()
      : toPreciseUnit(0, MM);
  for (var i = 0; i < _arguments.length; ++i) {
    switch (_arguments[i]) {
      case X:
        if (!state.retractedX) {
          words.push("X" + xyzFormat.format(_xHome));
          xOutput.reset();
          state.retractedX = true;
        }
        break;
      case Y:
        if (!state.retractedY) {
          words.push("Y" + xyzFormat.format(_yHome));
          yOutput.reset();
          state.retractedY = true;
        }
        break;
      case Z:
        if (!state.retractedZ) {
          words.push("Z" + xyzFormat.format(_zHome));
          zOutput.reset();
          state.retractedZ = true;
        }
        break;
      default:
        error(
          localize("Unsupported axis specified for getRetractParameters().")
        );
        return undefined;
    }
  }
  return {
    method: method,
    retractAxes: retractAxes,
    words: words,
    positions: {
      x: retractAxes[0] ? _xHome : undefined,
      y: retractAxes[1] ? _yHome : undefined,
      z: retractAxes[2] ? _zHome : undefined,
    },
    singleLine: singleLine,
  };
}

/** Returns true when subprogram logic does exist into the post. */
function subprogramsAreSupported() {
  return typeof subprogramState != "undefined";
}

// Start of machine simulation connection move support
var debugSimulation = false; // enable to output debug information for connection move support in the NC program
var TCPON = "TCP ON";
var TCPOFF = "TCP OFF";
var TWPON = "TWP ON";
var TWPOFF = "TWP OFF";
var TOOLCHANGE = "TOOL CHANGE";
var RETRACTTOOLAXIS = "RETRACT TOOLAXIS";
var WORK = "WORK CS";
var MACHINE = "MACHINE CS";
var MIN = "MIN";
var MAX = "MAX";
var WARNING_NON_RANGE = [0, 1, 2];
var isTwpOn;
var isTcpOn;
/**
 * Helper function for connection moves in machine simulation.
 * @param {Object} parameters An object containing the desired options for machine simulation.
 * @note Available properties are:
 * @param {Number} x X axis position, alternatively use MIN or MAX to move to the axis limit
 * @param {Number} y Y axis position, alternatively use MIN or MAX to move to the axis limit
 * @param {Number} z Z axis position, alternatively use MIN or MAX to move to the axis limit
 * @param {Number} a A axis position (in radians)
 * @param {Number} b B axis position (in radians)
 * @param {Number} c C axis position (in radians)
 * @param {Number} feed desired feedrate, automatically set to high/current feedrate if not specified
 * @param {String} mode mode TCPON | TCPOFF | TWPON | TWPOFF | TOOLCHANGE | RETRACTTOOLAXIS
 * @param {String} coordinates WORK | MACHINE - if undefined, work coordinates will be used by default
 * @param {Number} eulerAngles the calculated Euler angles for the workplane
 * @example
  machineSimulation({a:abc.x, b:abc.y, c:abc.z, coordinates:MACHINE});
  machineSimulation({x:toPreciseUnit(200, MM), y:toPreciseUnit(200, MM), coordinates:MACHINE, mode:TOOLCHANGE});
*/
function machineSimulation(parameters) {
  if (revision < 50198 || skipBlocks) {
    return; // return when post kernel revision is lower than 50198 or when skipBlocks is enabled
  }
  getAxisLimit = function (axis, limit) {
    validate(
      limit == MIN || limit == MAX,
      subst(
        localize(
          'Invalid argument "%1" passed to the machineSimulation function.'
        ),
        limit
      )
    );
    var range = axis.getRange();
    if (range.isNonRange()) {
      var axisLetters = ["X", "Y", "Z"];
      var warningMessage = subst(
        localize(
          'An attempt was made to move the "%1" axis to its MIN/MAX limits during machine simulation, but its range is set to "unlimited".' +
            EOL +
            'A limited range must be set for the "%1" axis in the machine definition, or these motions will not be shown in machine simulation.'
        ),
        axisLetters[axis.getCoordinate()]
      );
      warningOnce(warningMessage, WARNING_NON_RANGE[axis.getCoordinate()]);
      return undefined;
    }
    return limit == MIN ? range.minimum : range.maximum;
  };
  var x =
    isNaN(parameters.x) && parameters.x
      ? getAxisLimit(machineConfiguration.getAxisX(), parameters.x)
      : parameters.x;
  var y =
    isNaN(parameters.y) && parameters.y
      ? getAxisLimit(machineConfiguration.getAxisY(), parameters.y)
      : parameters.y;
  var z =
    isNaN(parameters.z) && parameters.z
      ? getAxisLimit(machineConfiguration.getAxisZ(), parameters.z)
      : parameters.z;
  var rotaryAxesErrorMessage = localize(
    "Invalid argument for rotary axes passed to the machineSimulation function. Only numerical values are supported."
  );
  var a =
    isNaN(parameters.a) && parameters.a
      ? error(rotaryAxesErrorMessage)
      : parameters.a;
  var b =
    isNaN(parameters.b) && parameters.b
      ? error(rotaryAxesErrorMessage)
      : parameters.b;
  var c =
    isNaN(parameters.c) && parameters.c
      ? error(rotaryAxesErrorMessage)
      : parameters.c;
  var coordinates = parameters.coordinates;
  var eulerAngles = parameters.eulerAngles;
  var feed = parameters.feed;
  if (feed === undefined && typeof gMotionModal !== "undefined") {
    feed = gMotionModal.getCurrent() !== 0;
  }
  var mode = parameters.mode;
  var performToolChange = mode == TOOLCHANGE;
  if (
    mode !== undefined &&
    ![TCPON, TCPOFF, TWPON, TWPOFF, TOOLCHANGE, RETRACTTOOLAXIS].includes(mode)
  ) {
    error(subst("Mode '%1' is not supported.", mode));
  }

  // mode takes precedence over TCP/TWP states
  var enableTCP = isTcpOn;
  var enableTWP = isTwpOn;
  if (mode === TCPON || mode === TCPOFF) {
    enableTCP = mode === TCPON;
  } else if (mode === TWPON || mode === TWPOFF) {
    enableTWP = mode === TWPON;
  } else {
    enableTCP = typeof state !== "undefined" && state.tcpIsActive;
    enableTWP = typeof state !== "undefined" && state.twpIsActive;
  }
  var disableTCP = !enableTCP;
  var disableTWP = !enableTWP;
  if (disableTWP) {
    simulation.setTWPModeOff();
    isTwpOn = false;
  }
  if (disableTCP) {
    simulation.setTCPModeOff();
    isTcpOn = false;
  }
  if (enableTCP) {
    simulation.setTCPModeOn();
    isTcpOn = true;
  }
  if (enableTWP) {
    if (settings.workPlaneMethod.eulerConvention == undefined) {
      simulation.setTWPModeAlignToCurrentPose();
    } else if (eulerAngles) {
      simulation.setTWPModeByEulerAngles(
        settings.workPlaneMethod.eulerConvention,
        eulerAngles.x,
        eulerAngles.y,
        eulerAngles.z
      );
    }
    isTwpOn = true;
  }
  if (mode == RETRACTTOOLAXIS) {
    simulation.retractAlongToolAxisToLimit();
  }

  if (debugSimulation) {
    writeln("  DEBUG" + JSON.stringify(parameters));
    writeln(
      "  DEBUG" +
        JSON.stringify({ isTwpOn: isTwpOn, isTcpOn: isTcpOn, feed: feed })
    );
  }

  if (
    x !== undefined ||
    y !== undefined ||
    z !== undefined ||
    a !== undefined ||
    b !== undefined ||
    c !== undefined
  ) {
    if (x !== undefined) {
      simulation.setTargetX(x);
    }
    if (y !== undefined) {
      simulation.setTargetY(y);
    }
    if (z !== undefined) {
      simulation.setTargetZ(z);
    }
    if (a !== undefined) {
      simulation.setTargetA(a);
    }
    if (b !== undefined) {
      simulation.setTargetB(b);
    }
    if (c !== undefined) {
      simulation.setTargetC(c);
    }

    if (feed != undefined && feed) {
      simulation.setMotionToLinear();
      simulation.setFeedrate(
        typeof feed == "number"
          ? feed
          : feedOutput.getCurrent() == 0
          ? highFeedrate
          : feedOutput.getCurrent()
      );
    } else {
      simulation.setMotionToRapid();
    }

    if (coordinates != undefined && coordinates == MACHINE) {
      simulation.moveToTargetInMachineCoords();
    } else {
      simulation.moveToTargetInWorkCoords();
    }
  }
  if (performToolChange) {
    simulation.performToolChangeCycle();
    simulation.moveToTargetInMachineCoords();
  }
}
// <<<<< INCLUDED FROM include_files/commonFunctions.cpi
// >>>>> INCLUDED FROM include_files/defineWorkPlane.cpi
validate(
  settings.workPlaneMethod,
  "Setting 'workPlaneMethod' is required but not defined."
);
function defineWorkPlane(_section, _setWorkPlane) {
  var abc = new Vector(0, 0, 0);
  if (
    settings.workPlaneMethod.forceMultiAxisIndexing ||
    !is3D() ||
    machineConfiguration.isMultiAxisConfiguration()
  ) {
    if (isPolarModeActive()) {
      abc = getCurrentDirection();
    } else if (_section.isMultiAxis()) {
      forceWorkPlane();
      cancelTransformation();
      abc = _section.isOptimizedForMachine()
        ? _section.getInitialToolAxisABC()
        : _section.getGlobalInitialToolAxis();
    } else if (
      settings.workPlaneMethod.useTiltedWorkplane &&
      settings.workPlaneMethod.eulerConvention != undefined
    ) {
      if (
        settings.workPlaneMethod.eulerCalculationMethod == "machine" &&
        machineConfiguration.isMultiAxisConfiguration()
      ) {
        abc = machineConfiguration
          .getOrientation(getWorkPlaneMachineABC(_section, true))
          .getEuler2(settings.workPlaneMethod.eulerConvention);
      } else {
        abc = _section.workPlane.getEuler2(
          settings.workPlaneMethod.eulerConvention
        );
      }
    } else {
      abc = getWorkPlaneMachineABC(_section, true);
    }

    if (_setWorkPlane) {
      if (_section.isMultiAxis() || isPolarModeActive()) {
        // 4-5x simultaneous operations
        cancelWorkPlane();
        if (_section.isOptimizedForMachine()) {
          positionABC(abc, true);
        } else {
          setCurrentDirection(abc);
        }
      } else {
        // 3x and/or 3+2x operations
        setWorkPlane(abc);
      }
    }
  } else {
    var remaining = _section.workPlane;
    if (!isSameDirection(remaining.forward, new Vector(0, 0, 1))) {
      error(localize("Tool orientation is not supported."));
      return abc;
    }
    setRotation(remaining);
  }
  tcp.isSupportedByOperation = isTCPSupportedByOperation(_section);
  return abc;
}

function isTCPSupportedByOperation(_section) {
  var _tcp = _section.getOptimizedTCPMode() == OPTIMIZE_NONE;
  if (
    !_section.isMultiAxis() &&
    (settings.workPlaneMethod.useTiltedWorkplane ||
      isSameDirection(
        machineConfiguration.getSpindleAxis(),
        getForwardDirection(_section)
      ) ||
      settings.workPlaneMethod.optimizeType == OPTIMIZE_HEADS ||
      settings.workPlaneMethod.optimizeType == OPTIMIZE_TABLES ||
      settings.workPlaneMethod.optimizeType == OPTIMIZE_BOTH)
  ) {
    _tcp = false;
  }
  return _tcp;
}
// <<<<< INCLUDED FROM include_files/defineWorkPlane.cpi
// >>>>> INCLUDED FROM include_files/getWorkPlaneMachineABC.cpi
validate(
  settings.machineAngles,
  "Setting 'machineAngles' is required but not defined."
);
function getWorkPlaneMachineABC(_section, rotate) {
  var currentABC = isFirstSection() ? new Vector(0, 0, 0) : getCurrentABC();
  var abc = _section.getABCByPreference(
    machineConfiguration,
    _section.workPlane,
    currentABC,
    settings.machineAngles.controllingAxis,
    settings.machineAngles.type,
    settings.machineAngles.options
  );
  if (
    !isSameDirection(
      machineConfiguration.getDirection(abc),
      _section.workPlane.forward
    )
  ) {
    error(localize("Orientation not supported."));
  }
  if (rotate) {
    if (
      settings.workPlaneMethod.optimizeType == undefined ||
      settings.workPlaneMethod.useTiltedWorkplane
    ) {
      // legacy
      var useTCP = false;
      var R = machineConfiguration.getRemainingOrientation(
        abc,
        _section.workPlane
      );
      setRotation(useTCP ? _section.workPlane : R);
    } else {
      if (!_section.isOptimizedForMachine()) {
        machineConfiguration.setToolLength(
          getSetting("workPlaneMethod.compensateToolLength", false)
            ? getBodyLength(_section.getTool())
            : 0
        ); // define the tool length for head adjustments
        _section.optimize3DPositionsByMachine(
          machineConfiguration,
          abc,
          settings.workPlaneMethod.optimizeType
        );
      }
    }
  }
  return abc;
}
// <<<<< INCLUDED FROM include_files/getWorkPlaneMachineABC.cpi
// >>>>> INCLUDED FROM include_files/positionABC.cpi
function positionABC(abc, force) {
  if (!machineConfiguration.isMultiAxisConfiguration()) {
    error(
      "Function 'positionABC' can only be used with multi-axis machine configurations."
    );
  }
  if (typeof unwindABC == "function") {
    unwindABC(abc);
  }
  if (force) {
    forceABC();
  }
  var a = aOutput.format(abc.x);
  var b = bOutput.format(abc.y);
  var c = cOutput.format(abc.z);
  if (a || b || c) {
    writeRetract(Z);
    if (getSetting("retract.homeXY.onIndexing", false)) {
      writeRetract(settings.retract.homeXY.onIndexing);
    }
    onCommand(COMMAND_UNLOCK_MULTI_AXIS);
    gMotionModal.reset();
    writeBlock(gMotionModal.format(0), a, b, c);
    setCurrentABC(abc); // required for machine simulation
    machineSimulation({ a: abc.x, b: abc.y, c: abc.z, coordinates: MACHINE });
  }
}
// <<<<< INCLUDED FROM include_files/positionABC.cpi
// >>>>> INCLUDED FROM include_files/writeToolCall.cpi
function writeToolCall(tool, insertToolCall) {
  if (!isFirstSection()) {
    writeStartBlocks(
      !getProperty("safeStartAllOperations") && insertToolCall,
      function () {
        writeRetract(Z); // write optional Z retract before tool change if safeStartAllOperations is enabled
      }
    );
  }
  writeStartBlocks(insertToolCall, function () {
    writeRetract(Z);
    if (getSetting("retract.homeXY.onToolChange", false)) {
      writeRetract(settings.retract.homeXY.onToolChange);
    }
    if (!isFirstSection() && insertToolCall) {
      if (typeof forceWorkPlane == "function") {
        forceWorkPlane();
      }
      onCommand(COMMAND_COOLANT_OFF); // turn off coolant on tool change
      if (typeof disableLengthCompensation == "function") {
        disableLengthCompensation(false);
      }
    }

    if (tool.manualToolChange) {
      onCommand(COMMAND_STOP);
      writeComment("MANUAL TOOL CHANGE TO T" + toolFormat.format(tool.number));
    } else {
      if (!isFirstSection() && getProperty("optionalStop") && insertToolCall) {
        onCommand(COMMAND_OPTIONAL_STOP);
      }
      onCommand(COMMAND_LOAD_TOOL);
    }
  });
  if (
    typeof forceModals == "function" &&
    (insertToolCall || getProperty("safeStartAllOperations"))
  ) {
    forceModals();
  }
}
// <<<<< INCLUDED FROM include_files/writeToolCall.cpi
// >>>>> INCLUDED FROM include_files/startSpindle.cpi

function startSpindle(tool, insertToolCall) {
  if (tool.type != TOOL_PROBE) {
    var spindleSpeedIsRequired =
      insertToolCall ||
      forceSpindleSpeed ||
      isFirstSection() ||
      rpmFormat.areDifferent(spindleSpeed, sOutput.getCurrent()) ||
      tool.clockwise != getPreviousSection().getTool().clockwise;

    writeStartBlocks(spindleSpeedIsRequired, function () {
      if (spindleSpeedIsRequired || operationNeedsSafeStart) {
        onCommand(COMMAND_START_SPINDLE);
      }
    });
  }
}
// <<<<< INCLUDED FROM include_files/startSpindle.cpi
// >>>>> INCLUDED FROM include_files/writeWCS.cpi
function writeWCS(section, wcsIsRequired) {
  if (section.workOffset != currentWorkOffset) {
    if (getSetting("workPlaneMethod.cancelTiltFirst", false) && wcsIsRequired) {
      cancelWorkPlane();
    }
    if (typeof forceWorkPlane == "function" && wcsIsRequired) {
      forceWorkPlane();
    }
    writeStartBlocks(wcsIsRequired, function () {
      writeBlock(section.wcs);
    });
    currentWorkOffset = section.workOffset;
  }
}
// <<<<< INCLUDED FROM include_files/writeWCS.cpi
// >>>>> INCLUDED FROM include_files/coolant.cpi
var currentCoolantMode = COOLANT_OFF;
var coolantOff = undefined;
var isOptionalCoolant = false;
var forceCoolant = false;

function setCoolant(coolant) {
  var coolantCodes = getCoolantCodes(coolant);
  if (Array.isArray(coolantCodes)) {
    writeStartBlocks(!isOptionalCoolant, function () {
      if (settings.coolant.singleLineCoolant) {
        writeBlock(coolantCodes.join(getWordSeparator()));
      } else {
        for (var c in coolantCodes) {
          writeBlock(coolantCodes[c]);
        }
      }
    });
    return undefined;
  }
  return coolantCodes;
}

function getCoolantCodes(coolant, format) {
  if (!getProperty("useCoolant", true)) {
    return undefined; // coolant output is disabled by property if it exists
  }
  isOptionalCoolant = false;
  if (typeof operationNeedsSafeStart == "undefined") {
    operationNeedsSafeStart = false;
  }
  var multipleCoolantBlocks = new Array(); // create a formatted array to be passed into the outputted line
  var coolants = settings.coolant.coolants;
  if (!coolants) {
    error(localize("Coolants have not been defined."));
  }
  if (tool.type && tool.type == TOOL_PROBE) {
    // avoid coolant output for probing
    coolant = COOLANT_OFF;
  }
  if (coolant == currentCoolantMode) {
    if (operationNeedsSafeStart && coolant != COOLANT_OFF) {
      isOptionalCoolant = true;
    } else if (!forceCoolant || coolant == COOLANT_OFF) {
      return undefined; // coolant is already active
    }
  }
  if (
    coolant != COOLANT_OFF &&
    currentCoolantMode != COOLANT_OFF &&
    coolantOff != undefined &&
    !forceCoolant &&
    !isOptionalCoolant
  ) {
    if (Array.isArray(coolantOff)) {
      for (var i in coolantOff) {
        multipleCoolantBlocks.push(coolantOff[i]);
      }
    } else {
      multipleCoolantBlocks.push(coolantOff);
    }
  }
  forceCoolant = false;

  var m;
  var coolantCodes = {};
  for (var c in coolants) {
    // find required coolant codes into the coolants array
    if (coolants[c].id == coolant) {
      coolantCodes.on = coolants[c].on;
      if (coolants[c].off != undefined) {
        coolantCodes.off = coolants[c].off;
        break;
      } else {
        for (var i in coolants) {
          if (coolants[i].id == COOLANT_OFF) {
            coolantCodes.off = coolants[i].off;
            break;
          }
        }
      }
    }
  }
  if (coolant == COOLANT_OFF) {
    m = !coolantOff ? coolantCodes.off : coolantOff; // use the default coolant off command when an 'off' value is not specified
  } else {
    coolantOff = coolantCodes.off;
    m = coolantCodes.on;
  }

  if (!m) {
    onUnsupportedCoolant(coolant);
    m = 9;
  } else {
    if (Array.isArray(m)) {
      for (var i in m) {
        multipleCoolantBlocks.push(m[i]);
      }
    } else {
      multipleCoolantBlocks.push(m);
    }
    currentCoolantMode = coolant;
    for (var i in multipleCoolantBlocks) {
      if (typeof multipleCoolantBlocks[i] == "number") {
        multipleCoolantBlocks[i] = mFormat.format(multipleCoolantBlocks[i]);
      }
    }
    if (format == undefined || format) {
      return multipleCoolantBlocks; // return the single formatted coolant value
    } else {
      return m; // return unformatted coolant value
    }
  }
  return undefined;
}
// <<<<< INCLUDED FROM include_files/coolant.cpi
// >>>>> INCLUDED FROM include_files/writeProgramHeader.cpi
properties.writeMachine = {
  title: "Write machine",
  description: "Output the machine settings in the header of the program.",
  group: "formats",
  type: "boolean",
  value: true,
  scope: "post",
};
properties.writeTools = {
  title: "Write tool list",
  description: "Output a tool list in the header of the program.",
  group: "formats",
  type: "boolean",
  value: true,
  scope: "post",
};
function writeProgramHeader() {
  // dump machine configuration
  var vendor = machineConfiguration.getVendor();
  var model = machineConfiguration.getModel();
  var mDescription = machineConfiguration.getDescription();
  if (getProperty("writeMachine") && (vendor || model || mDescription)) {
    writeComment(localize("Machine"));
    if (vendor) {
      writeComment("  " + localize("vendor") + ": " + vendor);
    }
    if (model) {
      writeComment("  " + localize("model") + ": " + model);
    }
    if (mDescription) {
      writeComment("  " + localize("description") + ": " + mDescription);
    }
  }

  // dump tool information
  if (getProperty("writeTools")) {
    if (false) {
      // set to true to use the post kernel version of the tool list
      writeToolTable(TOOL_NUMBER_COL);
    } else {
      var zRanges = {};
      if (is3D()) {
        var numberOfSections = getNumberOfSections();
        for (var i = 0; i < numberOfSections; ++i) {
          var section = getSection(i);
          var zRange = section.getGlobalZRange();
          var tool = section.getTool();
          if (zRanges[tool.number]) {
            zRanges[tool.number].expandToRange(zRange);
          } else {
            zRanges[tool.number] = zRange;
          }
        }
      }
      var tools = getToolTable();
      if (tools.getNumberOfTools() > 0) {
        for (var i = 0; i < tools.getNumberOfTools(); ++i) {
          var tool = tools.getTool(i);
          var comment =
            (getProperty("toolAsName")
              ? '"' + tool.description.toUpperCase() + '"'
              : "T" + toolFormat.format(tool.number)) +
            " " +
            "D=" +
            xyzFormat.format(tool.diameter) +
            " " +
            localize("CR") +
            "=" +
            xyzFormat.format(tool.cornerRadius);
          if (tool.taperAngle > 0 && tool.taperAngle < Math.PI) {
            comment +=
              " " +
              localize("TAPER") +
              "=" +
              taperFormat.format(tool.taperAngle) +
              localize("deg");
          }
          if (zRanges[tool.number]) {
            comment +=
              " - " +
              localize("ZMIN") +
              "=" +
              xyzFormat.format(zRanges[tool.number].getMinimum());
          }
          comment += " - " + getToolTypeName(tool.type);
          writeComment(comment);
        }
      }
    }
  }
}
// <<<<< INCLUDED FROM include_files/writeProgramHeader.cpi

// >>>>> INCLUDED FROM include_files/workPlaneFunctions_fanuc.cpi
var gRotationModal = createOutputVariable(
  {
    current: 69,
    onchange: function () {
      state.twpIsActive = gRotationModal.getCurrent() != 69;
      if (typeof probeVariables != "undefined") {
        probeVariables.outputRotationCodes =
          probeVariables.probeAngleMethod == "G68";
      }
      machineSimulation({}); // update machine simulation TWP state
    },
  },
  gFormat
);

var currentWorkPlaneABC = undefined;
function forceWorkPlane() {
  currentWorkPlaneABC = undefined;
}

function cancelWCSRotation() {
  if (
    typeof gRotationModal != "undefined" &&
    gRotationModal.getCurrent() == 68
  ) {
    cancelWorkPlane(true);
  }
}

function cancelWorkPlane(force) {
  if (typeof gRotationModal != "undefined") {
    if (force) {
      gRotationModal.reset();
    }
    var command = gRotationModal.format(69);
    if (command) {
      writeBlock(command); // cancel frame
      forceWorkPlane();
    }
  }
}

function setWorkPlane(abc) {
  if (
    !settings.workPlaneMethod.forceMultiAxisIndexing &&
    is3D() &&
    !machineConfiguration.isMultiAxisConfiguration()
  ) {
    return; // ignore
  }
  var workplaneIsRequired =
    currentWorkPlaneABC == undefined ||
    abcFormat.areDifferent(abc.x, currentWorkPlaneABC.x) ||
    abcFormat.areDifferent(abc.y, currentWorkPlaneABC.y) ||
    abcFormat.areDifferent(abc.z, currentWorkPlaneABC.z);

  writeStartBlocks(workplaneIsRequired, function () {
    writeRetract(Z);
    if (getSetting("retract.homeXY.onIndexing", false)) {
      writeRetract(settings.retract.homeXY.onIndexing);
    }
    if (
      (state.lengthCompensationActive || state.tcpIsActive) &&
      typeof disableLengthCompensation == "function"
    ) {
      disableLengthCompensation(); // cancel tool lenght compensation / TCP prior to output TWP
    }
    if (settings.workPlaneMethod.useTiltedWorkplane) {
      onCommand(COMMAND_UNLOCK_MULTI_AXIS);
      cancelWorkPlane();
      if (machineConfiguration.isMultiAxisConfiguration()) {
        var machineABC = abc.isNonZero()
          ? currentSection.isMultiAxis()
            ? getCurrentDirection()
            : getWorkPlaneMachineABC(currentSection, false)
          : abc;
        if (
          settings.workPlaneMethod.useABCPrepositioning ||
          machineABC.isZero()
        ) {
          positionABC(machineABC);
        } else {
          setCurrentABC(machineABC);
        }
      }
      if (abc.isNonZero() || !machineConfiguration.isMultiAxisConfiguration()) {
        gRotationModal.reset();
        writeBlock(
          gRotationModal.format(68.2),
          "X" + xyzFormat.format(currentSection.workOrigin.x),
          "Y" + xyzFormat.format(currentSection.workOrigin.y),
          "Z" + xyzFormat.format(currentSection.workOrigin.z),
          "I" + abcFormat.format(abc.x),
          "J" + abcFormat.format(abc.y),
          "K" + abcFormat.format(abc.z)
        ); // set frame
        writeBlock(gFormat.format(53.1)); // turn machine
        machineSimulation({
          a: getCurrentABC().x,
          b: getCurrentABC().y,
          c: getCurrentABC().z,
          coordinates: MACHINE,
          eulerAngles: abc,
        });
      }
    } else {
      positionABC(abc, true);
    }
    if (!currentSection.isMultiAxis()) {
      onCommand(COMMAND_LOCK_MULTI_AXIS);
    }
    currentWorkPlaneABC = abc;
  });
}
// <<<<< INCLUDED FROM include_files/workPlaneFunctions_fanuc.cpi
// >>>>> INCLUDED FROM include_files/initialPositioning_fanuc.cpi
/**
 * Writes the initial positioning procedure for a section to get to the start position of the toolpath.
 * @param {Vector} position The initial position to move to
 * @param {boolean} isRequired true: Output full positioning, false: Output full positioning in optional state or output simple positioning only
 * @param {String} codes1 Allows to add additional code to the first positioning line
 * @param {String} codes2 Allows to add additional code to the second positioning line (if applicable)
 * @example
  var myVar1 = formatWords("T" + tool.number, currentSection.wcs);
  var myVar2 = getCoolantCodes(tool.coolant);
  writeInitialPositioning(initialPosition, isRequired, myVar1, myVar2);
*/
function writeInitialPositioning(position, isRequired, codes1, codes2) {
  var motionCode = { single: 1, multi: 1 }; // Always use G01 for initial positioning
  var feed = "F500"; // Hard code F500 for initial positioning
  var hOffset = getSetting("outputToolLengthOffset", true)
    ? hFormat.format(tool.lengthOffset)
    : "";
  var additionalCodes = [formatWords(codes1), formatWords(codes2)];

  forceModals(gMotionModal);
  writeStartBlocks(isRequired, function () {
    var modalCodes = formatWords(
      gAbsIncModal.format(90),
      gPlaneModal.format(17)
    );
    if (typeof disableLengthCompensation == "function") {
      disableLengthCompensation(!isRequired); // cancel tool length compensation prior to enabling it, required when switching G43/G43.4 modes
    }

    if (machineConfiguration.isHeadConfiguration()) {
      // head/head head/table kinematics
      var machineABC = currentSection.isMultiAxis()
        ? defineWorkPlane(currentSection, false)
        : getWorkPlaneMachineABC(currentSection, false);
      machineConfiguration.setToolLength(
        getSetting("workPlaneMethod.compensateToolLength", false)
          ? getBodyLength(currentSection.getTool())
          : 0
      ); // define the tool length for head adjustments
      var mode = currentSection.isOptimizedForMachine()
        ? TCP_XYZ_OPTIMIZED
        : TCP_XYZ;
      var globalPosition = getGlobalPosition(
        currentSection.getInitialPosition()
      );
      var machinePosition = machineConfiguration.getOptimizedPosition(
        globalPosition,
        machineABC,
        mode,
        OPTIMIZE_BOTH,
        true
      );
      var prePosition =
        currentSection.isOptimizedForMachine() || currentSection.isMultiAxis()
          ? position
          : settings.workPlaneMethod.useTiltedWorkplane &&
            !tcp.isSupportedByMachine
          ? machinePosition
          : globalPosition;

      cancelWorkPlane();
      positionABC(machineABC);
      if (
        (getSetting("workPlaneMethod.useTiltedWorkplane", false) &&
          tcp.isSupportedByMachine &&
          getCurrentDirection().isNonZero()) ||
        tcp.isSupportedByOperation
      ) {
        writeBlock(getOffsetCode(true), hOffset); // force TCP for prepositioning although the operation may not require it
      }
      writeBlock(
        modalCodes,
        gMotionModal.format(motionCode.multi),
        xOutput.format(prePosition.x),
        yOutput.format(prePosition.y),
        feed,
        additionalCodes[0]
      );
      machineSimulation({ x: prePosition.x, y: prePosition.y });
      if (
        currentSection.isMultiAxis() ||
        getSetting("headPositioningMethod", 0) == 1
      ) {
        var lengthComp = state.lengthCompensationActive
          ? { code: undefined, hOffset: undefined }
          : { code: getOffsetCode(), hOffset: hOffset };
        writeBlock(
          modalCodes,
          gMotionModal.format(motionCode.single),
          lengthComp.code,
          zOutput.format(prePosition.z),
          lengthComp.hOffset,
          additionalCodes[1]
        );
        machineSimulation({ z: prePosition.z });
      }

      if (!currentSection.isMultiAxis()) {
        if (
          state.tcpIsActive &&
          !tcp.isSupportedByOperation &&
          typeof disableLengthCompensation == "function"
        ) {
          disableLengthCompensation();
        }
        if (
          getSetting("workPlaneMethod.useTiltedWorkplane", false) &&
          getCurrentDirection().isNonZero()
        ) {
          var saveRetractedState = [
            state.retractedX,
            state.retractedY,
            state.retractedZ,
          ];
          state.retractedX = state.retractedY = state.retractedZ = true; // set retracted states to true to avoid retraction
          defineWorkPlane(currentSection, true); // apply workplane for the operation if TWP is supported
          [state.retractedX, state.retractedY, state.retractedZ] =
            saveRetractedState; // restore retracted states
        }
        if (!state.lengthCompensationActive) {
          if (state.twpIsActive) {
            forceXYZ();
          }
          if (getSetting("headPositioningMethod", 0) == 1) {
            writeBlock(
              modalCodes,
              gMotionModal.format(motionCode.multi),
              xOutput.format(position.x),
              yOutput.format(position.y)
            );
            machineSimulation({ x: position.x, y: position.y });
            writeBlock(
              modalCodes,
              gMotionModal.format(motionCode.single),
              getOffsetCode(),
              zOutput.format(position.z),
              hOffset
            );
            machineSimulation({ z: position.z });
          } else {
            writeBlock(
              modalCodes,
              getOffsetCode(),
              gMotionModal.format(motionCode.single),
              xOutput.format(position.x),
              yOutput.format(position.y),
              zOutput.format(position.z),
              hOffset
            );
            machineSimulation({ x: position.x, y: position.y, z: position.z });
          }
        }
      }
      forceFeed();
    } else {
      // multi axis prepositioning with TWP
      if (
        currentSection.isMultiAxis() &&
        getSetting("workPlaneMethod.prepositionWithTWP", true) &&
        getSetting("workPlaneMethod.useTiltedWorkplane", false) &&
        tcp.isSupportedByOperation &&
        getCurrentDirection().isNonZero()
      ) {
        var W = machineConfiguration.isMultiAxisConfiguration()
          ? machineConfiguration.getOrientation(getCurrentDirection())
          : Matrix.getOrientationFromDirection(getCurrentDirection());
        var prePosition = W.getTransposed().multiply(position);
        var angles = W.getEuler2(settings.workPlaneMethod.eulerConvention);
        setWorkPlane(angles);
        writeBlock(
          modalCodes,
          gMotionModal.format(motionCode.multi),
          xOutput.format(prePosition.x),
          yOutput.format(prePosition.y),
          feed,
          additionalCodes[0]
        );
        machineSimulation({ x: prePosition.x, y: prePosition.y });
        cancelWorkPlane();
        writeBlock(getOffsetCode(), hOffset, additionalCodes[1]); // omit Z-axis output is desired
        forceAny(); // required to output XYZ coordinates in the following line
      } else {
        writeBlock(
          modalCodes,
          gMotionModal.format(motionCode.multi),
          xOutput.format(position.x),
          yOutput.format(position.y),
          feed,
          additionalCodes[0]
        );
        machineSimulation({ x: position.x, y: position.y });
        writeBlock(
          gMotionModal.format(motionCode.single),
          getOffsetCode(),
          zOutput.format(position.z),
          hOffset,
          additionalCodes[1]
        );
        machineSimulation(
          tcp.isSupportedByOperation
            ? { x: position.x, y: position.y, z: position.z }
            : { z: position.z }
        );
      }
    }
    forceModals(gMotionModal);
    if (isRequired) {
      additionalCodes = []; // clear additionalCodes buffer
    }
  });

  validate(
    !validateLengthCompensation || state.lengthCompensationActive,
    "Tool length compensation is not active."
  ); // make sure that lenght compensation is enabled
  if (!isRequired) {
    // simple positioning
    var modalCodes = formatWords(
      gAbsIncModal.format(90),
      gPlaneModal.format(17)
    );
    forceXYZ();
    if (
      !state.retractedZ &&
      xyzFormat.getResultingValue(getCurrentPosition().z) <
        xyzFormat.getResultingValue(position.z)
    ) {
      writeBlock(
        modalCodes,
        gMotionModal.format(motionCode.single),
        zOutput.format(position.z),
        feed
      );
      machineSimulation({ z: position.z });
    }
    writeBlock(
      modalCodes,
      gMotionModal.format(motionCode.multi),
      xOutput.format(position.x),
      yOutput.format(position.y),
      feed,
      additionalCodes
    );
    machineSimulation({ x: position.x, y: position.y });
  }
  if (
    machineConfiguration.isMultiAxisConfiguration() &&
    !currentSection.isMultiAxis()
  ) {
    onCommand(COMMAND_LOCK_MULTI_AXIS);
  }
}

Matrix.getOrientationFromDirection = function (ijk) {
  var forward = ijk;
  var unitZ = new Vector(0, 0, 1);
  var W;
  if (Math.abs(Vector.dot(forward, unitZ)) < 0.5) {
    var imX = Vector.cross(forward, unitZ).getNormalized();
    W = new Matrix(imX, Vector.cross(forward, imX), forward);
  } else {
    var imX = Vector.cross(new Vector(0, 1, 0), forward).getNormalized();
    W = new Matrix(imX, Vector.cross(forward, imX), forward);
  }
  return W;
};
// <<<<< INCLUDED FROM include_files/initialPositioning_fanuc.cpi
// >>>>> INCLUDED FROM include_files/onRapid_fanuc.cpi
function onRapid(_x, _y, _z) {
  var x = xOutput.format(_x);
  var y = yOutput.format(_y);
  var z = zOutput.format(_z);
  if (x || y || z) {
    if (pendingRadiusCompensation >= 0) {
      error(
        localize(
          "Radius compensation mode cannot be changed at rapid traversal."
        )
      );
      return;
    }
    writeBlock(gMotionModal.format(0), x, y, z);
    forceFeed();
  }
}
// <<<<< INCLUDED FROM include_files/onRapid_fanuc.cpi
// >>>>> INCLUDED FROM include_files/onLinear_fanuc.cpi
function onLinear(_x, _y, _z, feed) {
  if (pendingRadiusCompensation >= 0) {
    xOutput.reset();
    yOutput.reset();
  }
  var x = xOutput.format(_x);
  var y = yOutput.format(_y);
  var z = zOutput.format(_z);
  var f = getFeed(feed);
  if (x || y || z) {
    if (pendingRadiusCompensation >= 0) {
      pendingRadiusCompensation = -1;
      var d = getSetting("outputToolDiameterOffset", true)
        ? diameterOffsetFormat.format(tool.diameterOffset)
        : "";
      writeBlock(gPlaneModal.format(17));
      switch (radiusCompensation) {
        case RADIUS_COMPENSATION_LEFT:
          writeBlock(gMotionModal.format(1), gFormat.format(41), x, y, z, d, f);
          break;
        case RADIUS_COMPENSATION_RIGHT:
          writeBlock(gMotionModal.format(1), gFormat.format(42), x, y, z, d, f);
          break;
        default:
          writeBlock(gMotionModal.format(1), gFormat.format(40), x, y, z, f);
      }
    } else {
      writeBlock(gMotionModal.format(1), x, y, z, f);
    }
  } else if (f) {
    if (getNextRecord().isMotion()) {
      // try not to output feed without motion
      forceFeed(); // force feed on next line
    } else {
      writeBlock(gMotionModal.format(1), f);
    }
  }
}
// <<<<< INCLUDED FROM include_files/onLinear_fanuc.cpi
// >>>>> INCLUDED FROM include_files/onRapid5D_fanuc.cpi
function onRapid5D(_x, _y, _z, _a, _b, _c) {
  if (pendingRadiusCompensation >= 0) {
    error(
      localize("Radius compensation mode cannot be changed at rapid traversal.")
    );
    return;
  }
  if (!currentSection.isOptimizedForMachine()) {
    forceXYZ();
  }
  var x = xOutput.format(_x);
  var y = yOutput.format(_y);
  var z = zOutput.format(_z);
  var a = currentSection.isOptimizedForMachine()
    ? aOutput.format(_a)
    : toolVectorOutputI.format(_a);
  var b = currentSection.isOptimizedForMachine()
    ? bOutput.format(_b)
    : toolVectorOutputJ.format(_b);
  var c = currentSection.isOptimizedForMachine()
    ? cOutput.format(_c)
    : toolVectorOutputK.format(_c);

  if (x || y || z || a || b || c) {
    writeBlock(gMotionModal.format(0), x, y, z, a, b, c);
    forceFeed();
  }
}
// <<<<< INCLUDED FROM include_files/onRapid5D_fanuc.cpi
// >>>>> INCLUDED FROM include_files/writeRetract_fanuc.cpi
function writeRetract() {
  var retract = getRetractParameters.apply(this, arguments);
  if (retract && retract.words.length > 0) {
    if (
      typeof cancelWCSRotation == "function" &&
      getSetting("retract.cancelRotationOnRetracting", false)
    ) {
      // cancel rotation before retracting
      cancelWCSRotation();
    }
    if (
      typeof disableLengthCompensation == "function" &&
      getSetting("allowCancelTCPBeforeRetracting", false) &&
      state.tcpIsActive
    ) {
      disableLengthCompensation(); // cancel TCP before retracting
    }
    for (var i in retract.words) {
      var words = retract.singleLine ? retract.words : retract.words[i];
      switch (retract.method) {
        case "G28":
          forceModals(gMotionModal, gAbsIncModal);
          writeBlock(gFormat.format(28), gAbsIncModal.format(91), words);
          writeBlock(gAbsIncModal.format(90));
          break;
        case "G30":
          forceModals(gMotionModal, gAbsIncModal);
          writeBlock(gFormat.format(30), gAbsIncModal.format(91), words);
          writeBlock(gAbsIncModal.format(90));
          break;
        case "G53":
          forceModals(gMotionModal);
          writeBlock(
            gAbsIncModal.format(90),
            gFormat.format(53),
            gMotionModal.format(0),
            words
          );
          break;
        default:
          if (typeof writeRetractCustom == "function") {
            writeRetractCustom(retract);
            return;
          } else {
            error(
              subst(
                localize("Unsupported safe position method '%1'"),
                retract.method
              )
            );
          }
      }
      machineSimulation({
        x:
          retract.singleLine || words.indexOf("X") != -1
            ? retract.positions.x
            : undefined,
        y:
          retract.singleLine || words.indexOf("Y") != -1
            ? retract.positions.y
            : undefined,
        z:
          retract.singleLine || words.indexOf("Z") != -1
            ? retract.positions.z
            : undefined,
        coordinates: MACHINE,
      });
      if (retract.singleLine) {
        break;
      }
    }
  }
}
// <<<<< INCLUDED FROM include_files/writeRetract_fanuc.cpi
// >>>>> INCLUDED FROM include_files/getOffsetCode_fanuc.cpi
var toolLengthCompOutput = createOutputVariable(
  {
    control: CONTROL_FORCE,
    onchange: function () {
      state.tcpIsActive =
        toolLengthCompOutput.getCurrent() == 43.4 ||
        toolLengthCompOutput.getCurrent() == 43.5;
      state.lengthCompensationActive = toolLengthCompOutput.getCurrent() != 49;
      machineSimulation({}); // update machine simulation TCP state
    },
  },
  gFormat
);

function getOffsetCode(forceTCP) {
  if (
    !getSetting("outputToolLengthCompensation", true) &&
    toolLengthCompOutput.isEnabled()
  ) {
    state.lengthCompensationActive = true; // always assume that length compensation is active
    toolLengthCompOutput.disable();
  }
  var offsetCode = 43;
  if (tcp.isSupportedByOperation || forceTCP) {
    offsetCode = machineConfiguration.isMultiAxisConfiguration() ? 43.4 : 43.5;
  }
  return toolLengthCompOutput.format(offsetCode);
}
// <<<<< INCLUDED FROM include_files/getOffsetCode_fanuc.cpi

///////////////////////////////////////////// DSI UTILS //////////////////////////////////////////////
var headerFormat = createFormat({
  decimals: unit == MM ? 3 : 4,
  forceDecimal: true,
});

const setLengthRight = (string, length) => {
  let _string = string.slice(0, length);
  while (_string.length < length) {
    _string = " " + _string;
  }
  return _string;
};

const setLengthLeft = (string, length) => {
  let _string = string.slice(0, length);
  while (_string.length < length) {
    _string = _string + " ";
  }
  return _string;
};

const getTitleById = (property, valueId) => {
  var propertyValues = property.values;
  if (propertyValues) {
    var selectedValue = _.find(propertyValues, function (value) {
      return value.id === valueId;
    });
    if (selectedValue) {
      return selectedValue.title;
    }
  }
  return null;
};

function customEnumWithTitles(start, end, prefix) {
  prefix = prefix || "R"; // Fallback for undefined prefix
  var arr = [];
  arr.push({ title: "AUTO", id: "AUTO" });
  for (var i = start; i <= end; i++) {
    arr.push({
      title: prefix + i,
      id: String(i),
    });
  }
  return arr;
}

// DSI: Tool Table
function writeToolTable() {
  var numberOfSections = getNumberOfSections();
  var sections = {};
  for (var i = 0; i < numberOfSections; ++i) {
    var section = getSection(i);
    var tool = section.getTool();
    sections[tool.number] = section;
  }

  writeln("");
  writeComment("------TOOL LIST------");
  writeComment(
    "NO.                                      ID    DIAMETER   TIP RAD   STICKOUT "
  );
  writeComment(
    "----------------------------------------------------------------------------"
  );

  // dump tool information
  var tools = getToolTable();
  if (tools.getNumberOfTools() > 0) {
    for (var i = 0; i < tools.getNumberOfTools(); ++i) {
      var tool = tools.getTool(i);
      writeComment(writeToolFormat(tool));
    }
  }
  writeComment(
    "----------------------------------------------------------------------------"
  );

  writeln("");
}

function writeToolFormat(tool) {
  var _no = 5;
  var _id = 37;
  var _diameter = 11;
  var _tipRad = 9;
  var _stickout = 10;
  var toolTable = [];
  var _tool = String(tool.number);
  var description = tool.description;
  var type = getToolTypeName(tool.type);
  var noseRadius = headerFormat.format(tool.cornerRadius);
  var diameter = headerFormat.format(tool.diameter);
  var bodyLength = headerFormat.format(tool.bodyLength);
  var toolVendor = tool.vendor;

  toolTable.push(setLengthLeft(_tool, _no));
  if (description) {
    toolTable.push(setLengthRight(description, _id));
  }

  if (!description) {
    toolTable.push(setLengthRight(type, _id));
  }
  toolTable.push(setLengthRight(diameter, _diameter));
  toolTable.push(setLengthRight(noseRadius, _tipRad));
  toolTable.push(setLengthRight(bodyLength, _stickout));

  return toolTable.join(" ");
}

// DSI: Program Header
function getHeader() {
  const date = new Date();
  const formattedDateTime = (d) => {
    const z = (n) => (n < 10 ? `0${n}` : n);
    const h = d.getHours();
    return `${d.toLocaleDateString()} AT ${h % 12 || 12}:${z(d.getMinutes())} ${
      h < 12 ? "AM" : "PM"
    }`;
  };

  const programHeaderName = getGlobalParameter("job-description");
  const partName = getGlobalParameter("document-path");
  const programDate = formattedDateTime(date);
  const programmedBy = getGlobalParameter("username");

  const header = [
    ["PROGRAM NAME", programHeaderName],
    ["PART NAME", partName],
    ["PROGRAM DATE", programDate],
    ["PROGRAMMED by", programmedBy],
    ["POST VERSION", dsiPostVersion + "." + minimumRevision],
  ];
  return header.forEach((line) => writeComment(line.join(": ")));
}

function writeHeader() {
  getHeader();
  if (getProperty("writeTools")) {
    writeToolTable();
  }
}

var bufferPassThrough = true;
var manualNC = [];
function onManualNC(command, value) {
  if (command == COMMAND_PASS_THROUGH && bufferPassThrough) {
    manualNC.push({ command: command, value: value });
  } else {
    expandManualNC(command, value);
  }
}

function executeManualNC(command) {
  if (manualNC.length > 0) {
    writeln("");
    writeComment("MANUAL NC COMMANDS");
  }
  for (var i = 0; i < manualNC.length; ++i) {
    if (!command || command == manualNC[i].command) {
      expandManualNC(manualNC[i].command, manualNC[i].value);
    }
  }
  for (var i = manualNC.length - 1; i >= 0; --i) {
    if (!command || command == manualNC[i].command) {
      manualNC.splice(i, 1);
    }
  }
}

groupDefinitions = {
  dsi: { title: "POST CREATED BY www.DSI-MFG.com", order: 0 },
  //   _customer: { title: customer, order: 1 },
  postControl: { title: "Post Processor Features", order: 2 },
  preferences: { title: "Control Features", order: 3, collapsed: true },
  documentation: { title: "Documentation", order: 4, collapsed: true },
  formats: { title: "Formatting", order: 5, collapsed: true },
  probing: { title: "Probing", order: 6, collapsed: true },
  multiAxis: { title: "Multi axis", order: 7, collapsed: true },
  homePositions: { title: "Home Positions", order: 8, collapsed: true },
};

// DSI
properties.dsiSupport = {
  title: "For support contact",
  description: "",
  group: "dsi",
  type: "enum",
  values: [{ title: "support@dsi-mfg.com", id: "" }],
  value: "",
  scope: "post",
};
properties.dsiPhone = {
  title: "Phone",
  description: "",
  group: "dsi",
  type: "enum",
  values: [{ title: "1 (833) 374-4634", id: "" }],
  value: "",
  scope: "post",
};
properties.postManual = {
  title: "Post Manual Link",
  description: "Link to the post manual",
  group: "dsi",
  type: "enum",
  values: [{ title: "Post Manual", id: "" }],
  value: "",
  scope: "post",
  visible: false, // Chnage this to true if there is a post manual
};

function writeDebug(_text) {
  if (dsiDebug) {
    writeComment("DEBUG - " + _text);
    log("DEBUG - " + _text);
  }
}
