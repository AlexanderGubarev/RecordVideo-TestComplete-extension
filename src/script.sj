/*
	Constants
*/
var website = "https://www.videolan.org/"
var proc_name = "vlc"
var reg_install_dir = "VideoLAN\\VLC\\InstallDir"

var cursor_size = 12 //in pixels
var cursor_name = "vlc_cursor"
var cursor_extension = "png"
var cursor_color = 0x0000FF //clRed
var cursor_folder = "%temp%"

var video_normal = { "name": "Normal", "fps": 24, "quality": 1000 }
var video_low = { "name": "Low", "fps": 20, "quality": 500 }
var video_high = { "name": "High", "fps": 30, "quality": 1600 }

var vlc_closing_timeout = 1000 * 60 * 10 // wait 10 minutes for player encode the video file
var timeout_minimum = 1000 //1 sec. for waiting loops

/*
	Global variables
*/
var cursor_path = "" //full path to cursor image file
var Quality = video_normal.name //current video quality
var isStarted = false; //current recording state
var video_file_path = "" //full path to output video

var messages = {
  noRecorder: {
    message:   "Unable to record video. Please check that VLC video player is installed.",
    messageEx: "<p>You can download necessary VLC video player here:<br/><a href='%s' target='_blank'>%s</a></p>"
  },
  recStartOk: {
    message:   "The video recording is started. You can find recorded video in Logs folder.",
    messageEx: "The quality is: %s.\r\nYou can change the quality of videos by redefining VideoQuality parameter.\r\n\r\nThe video file will be created:\r\n%s"
  },
  recStartFail: {
    message:   "The video is already in recording state. Please see Additional information.",
    messageEx: "You need to stop previous video recording before starting the new one.\r\nIf you see "+ "%s" + ".exe process, please close it manually."
  },
  recStopOk: {
    message:   "The video recording is stopped.",
    messageEx: "The video file has been created:\r\n%s"
  },
  recStopFail: {
    message:   "The video recording was not even started!",
    messageEx: "Unable to detect working instance of VLC application. Please, check that you start recording in your test."
  },
  recStopFailNotStarted: {
    message:   "The video recording was not even started! Please see Additional information.",
    messageEx: "It seems the previos instance of VLC player was not closed.\r\nIf you see %s.exe process, please close it manually."
  },
  recUnexpectedError: {
    message:   "Something was wrong during the recording process. Please see Additional Information.",
    messageEx: "Please try to launch the player manually with command line:\r\n\r\n\"%s\" %s"
  },

};

/*
	Text constants
*/


var msg_terminated =
  "The player process was terminated forcely because of timeout for video encoding."
var msg_terminated_additional =
  "Please try to record smaller video."

var ind_encoding =
  "Encoding the video file..."

var desc_KDT_start =
  "Start video recording. You can find recorded video in Logs folder."

var desc_KDT_stop =
  "Stop video recording. You can find recorded video in Logs folder."

/*
	Main functions
*/

function Start(VideoQuality) {
  Indicator.Hide()
  var isVLCExists = Sys.WaitProcess(proc_name).Exists
  Indicator.Show()

  if (isVLCExists) {
    Log.Warning(messages.recStartFail.message, aqString.Format(messages.recStartFail.messageEx, proc_name))
    return
  }

  if (VideoQuality == undefined)
    VideoQuality = video_normal.name
  Quality = VideoQuality
  video_file_path = getOutputFileName()
  if (isVLCInstalled()) {
    createCursor()
    isStarted = true;
    LaunchRecording()
    Log.Message(messages.recStartOk.message, aqString.Format(messages.recStartOk.messageEx, Quality, video_file_path));
  }
  else {
    var pmHigher = 300
    var attr = Log.CreateNewAttributes();
    attr.ExtendedMessageAsPlainText = false;
    Log.Warning(messages.noRecorder.message, aqString.Format(messages.noRecorder.messageEx, website, website), pmHigher, attr)
  }
  return video_file_path
}

function yy() {
  // var p = "C:\\temp\\1.txt"
  // Log.Message(aqFile.Exists(p))
  Start()
  Stop()
}


function Stop() {
  Indicator.Hide()
  var isVLCExists = Sys.WaitProcess(proc_name, timeout_minimum).Exists
  Indicator.Show()

  if (!isVLCExists)
    Log.Warning(messages.recStopFail.message, messages.recStopFail.messageEx)
  else if (!isStarted) {
    Log.Warning(messages.recStopFailNotStarted.message, aqString.Format(messages.recStopFailNotStarted.messageEx, proc_name))
  }
  else {
    StopRecording()
    isStarted = false;
    for (var i = 0; i < 20; i++) {
      if (aqFile.Exists(aqString.Unquote(video_file_path)))
        break
      Delay(timeout_minimum, ind_encoding)
    }
    if (aqFile.Exists(aqString.Unquote(video_file_path)))
      Log.Link(video_file_path, messages.recStopOk.message, aqString.Format(messages.recStopOk.messageEx, video_file_path))
    else
      Log.Warning(messages.recUnexpectedError.message, aqString.Format(messages.recUnexpectedError.messageEx, proc_name, getVLCPath(), prepareStartParamsString()))
  }
  return video_file_path
}


/*
  Do on extension load
*/
function Initialize() {
  cursor_path = aqFileSystem.ExpandUNCFileName(cursor_folder + "\\" + cursor_name + "." +
    cursor_extension)
  Quality = video_normal.name
}

/*
  Do on extension unload
*/
function Finalize() {
  if (isStarted)
    runCMD("\"" + getVLCPath() + "\"" + " " + prepareStopParamsString())
}

/*
  Command line for player to record video with certain params
*/
function setParams(codec, _quality, fps, file) {
  return "--one-instance screen:// -I dummy :screen-fps=" +
    fps + " :screen-follow-mouse :screen-mouse-image=" +
    "\"" + cursor_path + "\"" + " :no-sound :sout=#transcode{vcodec=" +
    codec + ",vb=" + _quality + ",fps=" + fps + ",scale=1}:std{access=file,dst=" +
    file + "}"
}

/*
  Choose video params
*/
function prepareStartParamsString() {
  var intQuality = video_normal.quality
  var intFPS = video_normal.fps

  if (Quality.toLowerCase() == video_high.name.toLowerCase()) {
    intQuality = video_high.quality
    intFPS = video_high.fps
  }
  else if (Quality.toLowerCase() == video_low.name.toLowerCase()) {
    intQuality = video_low.quality
    intFPS = video_low.fps
  }
  else {
    Quality = video_normal.name
  }

  return setParams("h264", intQuality, intFPS, video_file_path)
}

/*
  Command line for player closing
*/
function prepareStopParamsString() {
  return "--one-instance vlc://quit"
}


function LaunchRecording() {
  runCMD("\"" + getVLCPath() + "\"" + " " + prepareStartParamsString())
}

function StopRecording() {
  Indicator.Hide()
  Delay(2 * timeout_minimum) // 2 sec. delay to catch the last moments
  runCMD("\"" + getVLCPath() + "\"" + " " + prepareStopParamsString())
  Delay(timeout_minimum) // 1 sec. delay to avoid encoding status in video
  Indicator.Show()
  Indicator.PushText(ind_encoding)

  // forcely close player after timeout of video encoding
  Log.Enabled = false
  var proc = Sys.WaitProcess(proc_name)
  var time = 0; //timer for timeout
  while (proc.Exists) {
    Delay(timeout_minimum, ind_encoding)
    time += timeout_minimum
    if (time >= vlc_closing_timeout) {
      proc.Terminate()
      Log.Warning(msg_terminated, msg_terminated_additional)
    }
  }
  Log.Enabled = true
}

/*
UTILITIES
*/

/*
  Get Log path
*/
function getLogsPath() {
  return Log.Path
}

/*
  Generate short name of video file
*/
function generateFileName() {
  var dtNow = aqDateTime.Now()

  var year = aqDateTime.GetYear(dtNow)
  var month = aqDateTime.GetMonth(dtNow)
  var day = aqDateTime.GetDay(dtNow)
  var hour = aqDateTime.GetHours(dtNow)
  var minute = aqDateTime.GetMinutes(dtNow)
  var sec = aqDateTime.GetSeconds(dtNow)

  var datearray = [year, month, day, hour, minute, sec]

  return "video_" + datearray.join("-") + ".mp4"
}

/*
  Generate full name of video file
*/
function getOutputFileName() {
  return "\"" + getLogsPath() + generateFileName() + "\""
}

/*
  Get Registry value from HKEY_LOCAL_MACHINE
*/
function GetRegistryValue(ValueName) {
  var x64 = Sys.OSInfo.Windows64bit ? "\\Wow6432Node\\" : ""
  var Root = "HKEY_LOCAL_MACHINE"
  var HKLM_Software = "SOFTWARE" + x64

  var ValueFulllName = aqString.Format("%s\\%s%s", Root,
    aqFileSystem.IncludeTrailingBackSlash(HKLM_Software), ValueName);

  try {
    var Result = WshShell.RegRead(ValueFulllName)
  }
  catch (e) {
    return "error";
  }
  return Result;
}

/*
  Check if player installed
*/
function isVLCInstalled() {
  var regVendor = GetRegistryValue(reg_install_dir.split("\\")[0] + "\\")
  return (regVendor != "error")
}

/*
  Get player path
*/
function getVLCPath() {
  if (!isVLCInstalled())
    return ""
  var reg = GetRegistryValue(reg_install_dir)
  return reg + "\\" + proc_name + ".exe"
}

/*
  Run custom command line
*/
function runCMD(cmd) {
  WshShell.Run(cmd, 2, false)
}

/*
  Create cursor in Temp folder
*/
function createCursor() {
  var path = cursor_path;

  if (aqFile.Exists(path))
    return

  var Pict = Sys.Desktop.Picture(0, 0, cursor_size, cursor_size)

  var config = Pict.CreatePictureConfiguration(cursor_extension)
  config.CompressionLevel = 9;

  for (var i = 0; i < cursor_size; i++)
    for (var j = 0; j < cursor_size; j++)
      Pict.Pixels(i, j) = cursor_color //fill with red pixels

  Pict.SaveToFile(path, config)
}

/*
	KDT descriptions
*/

/*
	KDT Start
*/

function StartRecording_OnCreate(Data, Parameters) {

  Parameters.VideoQuality = video_normal.name
}

function StartRecording_GetDescription(Data) {
  return desc_KDT_start
}

function StartRecording_OnExecute(Data, VideoQuality) {
  return Start(VideoQuality)
}

function StartRecording_OnSetup(Data, Parameters) {
  return true
}

/*
	KDT Stop
*/

function StopRecording_OnCreate(Data, Parameters) {
  return true
}

function StopRecording_GetDescription(Data) {
  return desc_KDT_stop
}

function StopRecording_OnExecute(Data, Parameters) {
  return Stop()
}

function StopRecording_OnSetup(Data, Parameters) {
  return true
}
