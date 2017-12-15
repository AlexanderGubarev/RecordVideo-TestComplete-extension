VideoRecorder Extension for TestComplete
=================

This extension enables you to record videos for your automated tests running with SmartBear [TestComplete](https://smartbear.com/product/testcomplete/overview/) or [TestExecute](https://smartbear.com/product/testexecute/overview/").
The extensions adds a `VideoRecorder` script object for starting and stopping video recording from your script tests, and the **Start** and **Stop Video Recording** keyword-test operations for doing this from keyword tests.
The extension uses JScript sources, but is suitable for any supported scripting language.

# Why VideoRecorder?

It records a video for your test runs, helping you to check the test execution and to understand what happened in your system and tested application during the test run.

VideoRecorder is similar to the Test Visualizer of TestComplete, but it provides more convenient results. While Test Visualizer captures images for test commands that simulate user actions, the VideoRecorder creates a movie reflecting all the events, including those that occur between two commands. Also, it is easier to analyze a seamless video clip than a series of screenshots.

# When to Use
Use VideoRecorder when it is difficult to understand the cause of the issue during automated test runs. For example, in some cases it is really difficult to find the cause of issues that occur during nightly test runs. Videos can help you with this.

Note that videos can occupy lots of space on your hard drive. Also, long videos may be not convenient for analysis in comparison with short videoclips. That is why we would not recommend that you record a video for the entire nightly test run. Do this for problematic areas only. You can easily achieve this by adding the "Start" and "Stop Video Recording" commands into the appropriate places in your tests (see below).

# Video Recorder Engine
The extension uses the recording functionality of the free open-source VLC media player by VideoLAN.
Download it from **[https://www.videolan.org/](https://www.videolan.org/)**.

# Installation

### 1. Install the VLC Media Player
1. Download the VLC installer from **[https://www.videolan.org/](https://www.videolan.org/)**.
2. Install the VLC media player on your computer. The installation is straight-forward. Just follow instructions of the installation wizard.

### 2. Get the Extension
1. Clone the repository to your computer.
2. Open the command-line window, and run the _`build.bat`_ file that is located  the repository root folder. 
It will pack the extension sources to the _`VideoRecorder.tcx`_ achrive, and copy that archive to the _`out`_ subfolder of your repo.

### 3. Install the Extension
Copy the file VideoRecorder.tcx from the _`out`_ subfolder to the _`Bin\Extensions\ScriptExtensions\`_ folder of your TestComplete or TestExecute installation, for example:
  - TestComplete:
        `C:\Program Files (x86)\SmartBear\TestComplete 12\Bin\Extensions\ScriptExtensions`
  - TestExecute:
        `C:\Program Files (x86)\SmartBear\TestExecute 12\Bin\Extensions\ScriptExtensions`

Now you can launch product and use the extension as you want.

# Using Video Recorder

You can start and stop recording from your script or keyword tests.

### In Keyword Tests

1. To start and stop recording, you use the **Start Video Recording** and **Stop Video Recording** operations that the VideoRecorder adds to TestComplete. You can find these operations in the Logging operation category. Simply drag these operations to your test:
  ![]()

2. If needed, use the "Start" operation parameters to set the desired video quality: _Low_, _Normal_ or _High_. The default is _Normal_.

  ![]()

That's all. Now you can run your test. 


### In Scripts
To work with the recorder from scripts, the extension adds the `VideoRecorder` object to TestComplete. The object is available in all the supported scripting languages. 

Use `VideoRecorder.Start()` method to start recording, and `VideoRecorder.Stop()` to stop it. The `Start()` method has a _VideoQuality_ string parameter (`Start(VideoQuality)`) that specifies the quality of the recorded video. Possible values include "_Low_", "_Normal_" (default) and "_High_". 

```JavaScript
// JavaScript Example

function foo() {
  // Start recording with High quality
  VideoRecorder.Start("High")
  
  // Do some test actions
  WshShell.Run("notepad");
  var pNotepad = Sys.WaitProcess("notepad", 10*1000);
  var wMain = pNotepad.Window("Notepad", "*Notepad")
  var wEdit = wMain.Window("Edit")
  wEdit.Keys("Test")
  wMain.MainMenu.Click("Help|About Notepad");
  pNotepad.Window("#32770", "About Notepad").Window("Button", "OK").ClickButton();
  pNotepad.Close()
  
  // Stop recording
  VideoRecorder.Stop()
}
```

# Results
During its work, the recorder posts informative, warning and error messages to the test log.
Information on the recorded file name is available in the test log in both the "start" and "stop" messages. You can find the file name in the Additional Info tab:

![Additional Info tab]()

The link to the recorded video is posted along with the "stop" message. The "start" message cannot do this, because the file does not exist at the moment of the start.

The recorder generates the video file when the recording stops, or when TestComplete exits. If your test stops on error, then it is possible the execution flow does not reach the "stop" command and it is not executed. For more information on this issue and possible workarounds, see [below](#if-stop-on-error).

# Notes
- The recorder always captures the entire screen.
- On systems with multiple display devices, it records the main display only.
- The size of the resulting movie depends on how long the video was recorded, on its quality (low, normal, or high) and on your screen resolution.
- The video file name includes the date and time of the video start, so you can record several videos during one test run.
- If generation of the resulting video file takes longer than 10 minutes, the extension cancels this process, stops the recording engine and reports an error.
- **IMPORTANT:** it is important to start and stop the recording from within your test. The extension cannot use the recorder instance started outside TestComplete (or outside TestExecute). 
  Also, it is **_very important_** to stop the recorder when the testing is over. The extension cannot start recording, if you have a working recorder instance in the system. In this case, you have to close the recorder process (or processes) manually. 
- Both keyword-test operations, and both the `Start` and `Stop` script methods returns the fully-qualified name of the recorded video file.
  
<a name="if-stop-on-error"></a>
# If Your Test Stops on Error

This can happen rather frequent. For example, if the _[Stop on Error](https://support.smartbear.com/testcomplete/docs/working-with/managing-projects/properties/playback.html)_ property of your project is enabled, the test engine stops the test run once an error is posted to the log. In this case, it is possible that the recorder is not stopped, simply because the test does not reach the "Stop" command.

Possible workarounds:
- Consider adding the _`/exit`_ argument to the TestComplete (or TestExecute) command line. In this case, when the test stops on an error, the test engine will close TestComplete (TestExecute). The extension will detect this and will generate the video file. To find the file name, check the Additional Info posted to the log along with the "start" log message.
- Consider disabling the _Stop on Error_ project property. See [Project Properties - Playback Options](https://support.smartbear.com/testcomplete/docs/working-with/managing-projects/properties/playback.html) in TestComplete documentation. 
- Consider calling the Start and Stop Video Recording commands from within the [OnStartTest](https://support.smartbear.com/testcomplete/docs/reference/events/onstarttest.html) and [OnStopTest](https://support.smartbear.com/testcomplete/docs/reference/events/onstoptest.html) event handlers. The `OnStopTest` event is raised whenever the test execution stops, so placing the "Stop" command there can be a good idea.


# Supported Versions
We tested the extension on -- 
 * TestComplete 12.40
 * VLC media player 2.2.6

Most likely, the extension will work with other TestComplete and VLC versions.

# Contacts and Feedback
The SmartBear Community has ... 
Send your questions, comments and suggestions to ..... We would appreciate your bug reports, ideas and any other feedback.
Also, if you want to improve or change some code, feel free to send your contribution requests to .... 

