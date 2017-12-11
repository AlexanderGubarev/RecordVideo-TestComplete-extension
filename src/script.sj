// Log messages
var logMessages = {
  recorderIsNotInstalled: {
    message: "Unable to record video. Please check that VLC video player is installed.",
    messageEx: "<p>You can download necessary VLC video player here:<br/><a href='%s' target='_blank'>%s</a></p>"
  },
  startOk: {
    message: "The video recording is started. You can find recorded video in Logs folder.",
    messageEx: "The quality is: %s.\r\nYou can change the quality of videos by redefining VideoQuality parameter.\r\n\r\nThe video file will be created:\r\n%s"
  },
  startFailAlreadyStarted: {
    message: "The video is already in recording state. Please see Additional information.",
    messageEx: "You need to stop previous video recording before starting the new one.\r\nIf you see " + "%s" + ".exe process, please close it manually."
  },
  stopOk: {
    message: "The video recording is stopped.",
    messageEx: "The video file has been created:\r\n%s"
  },
  stopFailNoRecorderProcess: {
    message: "The video recording was not even started!",
    messageEx: "Unable to detect working instance of VLC application. Please, check that you start recording in your test."
  },
  stopFailRecorderNotStarted: {
    message: "The video recording was not even started! Please see Additional information.",
    messageEx: "It seems the previos instance of VLC player was not closed.\r\nIf you see %s.exe process, please close it manually."
  },
  recorderUnexpectedError: {
    message: "Something was wrong during the recording process. Please see Additional Information.",
    messageEx: "Please try to launch the player manually with command line:\r\n\r\n\"%s\" %s"
  },
  processWasTerminated: {
    message: "The player process was terminated forcely because of timeout for video encoding.",
    messageEx: "Please try to record smaller video."
  }
};

//Other messages
var messages = {
  encodingInProgress: "Encoding the video file..."
};

//Recorder information
function RecorderInfo() {
  this.getHomepage = function () {
    return "https://www.videolan.org/";
  };

  this.getProcessName = function () {
    return "vlc";
  };

  function getRegistryValue(name, defaultValue) {
    var bitPrefix = Sys.OSInfo.Windows64bit ? "Wow6432Node\\" : "";
    var path = aqString.Format("HKEY_LOCAL_MACHINE\\SOFTWARE\\%s%s", bitPrefix, name);
    var result = defaultValue;

    try {
      result = WshShell.RegRead(path);
    }
    catch (ignore) {
    }
    return result;
  }

  this.isInstalled = function () {
    return getRegistryValue("VideoLan\\", "novalue") !== "novalue";
  };

  this.getPath = function () {
    return getRegistryValue("VideoLAN\\VLC\\InstallDir") + "\\" + this.getProcessName() + ".exe";
  };
}

function Presets() {
  var _normal = {
    name: "Normal",
    fps: 24,
    quality: 1000
  };
  var _low = {
    name: "Low",
    fps: 20,
    quality: 500
  };
  var _high = {
    name: "High",
    fps: 30,
    quality: 1600
  };
  var _default = _normal;

  this.getDefault = function () {
    return _default;
  };

  this.get = function (name) {
    var presets = [_normal, _low, _high];
    var i, found = _default;

    for (i = 0; i < presets.lenght; i++) {
      if (presets[i].name.toLowerCase() === name.toLowerCase()) {
        found = presets[i];
        break;
      }
    }

    return found;
  };
}

//Video file information
function VideoFile() {
  var _path = (function generateVideoFilePath() {
    var now = aqDateTime.Now();

    var year = aqDateTime.GetYear(now);
    var month = aqDateTime.GetMonth(now);
    var day = aqDateTime.GetDay(now);
    var hour = aqDateTime.GetHours(now);
    var minute = aqDateTime.GetMinutes(now);
    var sec = aqDateTime.GetSeconds(now);

    return Log.Path + "video_" + [year, month, day, hour, minute, sec].join("-") + ".mp4";
  })();

  this.getPath = function () {
    return _path;
  };
}

//Cursor file information
function CursorFile() {
  var _path = aqFileSystem.ExpandUNCFileName("%temp%\\vlc_cursor.png");

  if (!aqFile.Exists(_path)) {
    (function createCursorFile(size, color, format, path) {
      var picture = Sys.Desktop.Picture(0, 0, size, size);
      var config = picture.CreatePictureConfiguration("png");
      var i, j;

      config.CompressionLevel = 9;
      for (i = 0; i < size; i++) {
        for (j = 0; j < size; j++) {
          picture.Pixels(i, j) = color;
        }
      }

      picture.SaveToFile(path, config);
    })(12, 0x0000FF/*red*/, _path);
  }

  this.getPath = function () {
    return _path;
  };
}

// Engine
function RecorderEngine() {
  var _recorderInfo = new RecorderInfo();
  var _presets = new Presets();

  var _settings = _presets.getDefault();
  var _videoFile;
  var _cursorFile;
  var _isStarted = false;

  function runCommand(args) {
    WshShell.Run(aqString.Format('"%s" %s', _recorderInfo.getPath(), args), 2, false);
  }

  function getStartCommandArgs() {
    return "--one-instance screen:// -I dummy :screen-fps=" + _settings.fps +
      " :screen-follow-mouse :screen-mouse-image=" + "\"" + _cursorFile.getPath() + "\"" +
      " :no-sound :sout=#transcode{vcodec=h264,vb=" + _settings.quality + ",fps=" + _settings.fps + ",scale=1}" +
      ":std{access=file,dst=\"" + _videoFile.getPath() + "\"}";
  }

  function runStartCommand() {
    runCommand(getStartCommandArgs());
  }

  function runStopCommand() {
    runCommand("--one-instance vlc://quit");
  }

  function ensureRecorderProcessIsClosed(timeout) {
    var timeoutPortion = 1000;
    var process = Sys.WaitProcess(_recorderInfo.getProcessName());
    var wastedTime = 0;
    while (process.Exists) {
      Delay(timeoutPortion, messages.encodingInProgress);
      wastedTime += timeoutPortion;
      if (wastedTime >= timeout) {
        process.Terminate();
        Log.Warning(logMessages.processWasTerminated.message, logMessages.processWasTerminated.messageEx);
      }
    }
  }

  this.getPresetName = function () {
    return _settings.name;
  };

  this.start = function (presetName) {
    var recExists;

    Indicator.Hide();
    recExists = Sys.WaitProcess(_recorderInfo.getProcessName()).Exists;
    Indicator.Show();

    if (recExists) {
      Log.Warning(logMessages.startFailAlreadyStarted.message, aqString.Format(logMessages.startFailAlreadyStarted.messageEx, _recorderInfo.getProcessName()));
      return;
    }

    if (!_recorderInfo.isInstalled()) {
      var pmHigher = 300;
      var attr = Log.CreateNewAttributes();
      attr.ExtendedMessageAsPlainText = false;
      Log.Warning(logMessages.recorderIsNotInstalled.message, aqString.Format(logMessages.recorderIsNotInstalled.messageEx, _recorderInfo.homepage, _recorderInfo.homepage), pmHigher, attr);
      return;
    }

    _settings = _presets.get(presetName);
    _videoFile = new VideoFile();
    _cursorFile = new CursorFile();
    _isStarted = true;
    runStartCommand();

    Log.Message(logMessages.startOk.message, aqString.Format(logMessages.startOk.messageEx, _settings.name, _videoFile.getPath()));
    return _videoFile.getPath();
  };

  this.stop = function () {
    var recExists, i;

    Indicator.Hide();
    recExists = Sys.WaitProcess(_recorderInfo.getProcessName(), 1000).Exists;
    Indicator.Show();

    if (!recExists) {
      Log.Warning(logMessages.stopFailNoRecorderProcess.message, logMessages.stopFailNoRecorderProcess.messageEx);
      return;
    }

    if (!_isStarted) {
      Log.Warning(logMessages.stopFailRecorderNotStarted.message, aqString.Format(logMessages.stopFailRecorderNotStarted.messageEx, _recorderInfo.getProcessName()));
      return;
    }

    Indicator.Hide();
    Delay(2000); // 2 sec. delay to catch the last moments
    runStopCommand();
    Delay(1000); // 1 sec. delay to avoid encoding status in video
    Indicator.Show();
    Indicator.PushText(messages.encodingInProgress);

    // forcely close player after timeout of video encoding
    Log.Enabled = false;
    ensureRecorderProcessIsClosed(10 * 60 * 1000 /*wait 10 minutes for player encode the video file*/);
    Log.Enabled = true;

    _isStarted = false;
    for (i = 0; i < 20; i++) {
      if (aqFile.Exists(_videoFile.getPath())) {
        break;
      }
      Delay(1000, messages.encodingInProgress);
    }

    if (aqFile.Exists(_videoFile.getPath())) {
      Log.Link(_videoFile.getPath(), logMessages.stopOk.message, aqString.Format(logMessages.stopOk.messageEx, _videoFile.getPath()));
    }
    else {
      Log.Warning(logMessages.recorderUnexpectedError.message, aqString.Format(logMessages.recorderUnexpectedError.messageEx, _recorderInfo.getProcessName(), _recorderInfo.getPath(), getStartCommandArgs()));
    }
    return _videoFile.getPath();
  };

  this.onInitialize = function () {
  };

  this.onFinalize = function () {
    if (_isStarted) {
      runStopCommand();
    }
  };
}
var recorderEngine = new RecorderEngine();

// Do on extension load
function Initialize() {
  recorderEngine.onInitialize();
}

// Do on extension unload
function Finalize() {
  recorderEngine.onFinalize();
}

//
// Runtime object
//

function RuntimeObject_Start(VideoQuality) {
  recorderEngine.start(VideoQuality);
}

function RuntimeObject_Stop() {
  recorderEngine.stop();
}

//
// KDT Start operation
//
function KDTStartOperation_OnCreate(Data, Parameters) {
  Parameters.VideoQuality = recordingEngine.getPresetName();
}

function KDTStartOperation_OnExecute(Data, VideoQuality) {
  return recorderEngine.start(VideoQuality);
}

function KDTStartOperation_OnSetup(Data, Parameters) {
  return true;
}

//
// KDT Stop operation
//

function KDTStopOperation_OnCreate(Data, Parameters) {
  return true;
}

function KDTStopOperation_OnExecute(Data, Parameters) {
  return recorderEngine.stop();
}

function KDTStopOperation_OnSetup(Data, Parameters) {
  return true;
}