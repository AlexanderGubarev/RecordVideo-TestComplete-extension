RecordVideo Extension for TestComplete
=================

# About

This is a extension for <a href="https://smartbear.com/product/testcomplete/overview/">TestComplete</a> or <a href="https://smartbear.com/product/testexecute/overview/">TestExecute</a> product for recording the video during the test run.
It adds KeywordTest operations and script object to manage recording process.
The extension uses very popular and free VLC media player as video recording engine.



# Why do you need it

Sometimes it's realy difficult to understand what happens during the nightly test run. So, with video of your test run you can see when and where something was wrong.



# Installation

1) Download the repository files.
2) Run the build.bat file.
3) Copy the file RecordVideo.tcx from `.\out\` folder to the x86 folder of TestComplete or TestExecute:
`.\Bin\Extensions\ScriptExtensions\`<br/>
TestComplete example:<br/>
`C:\Program Files (x86)\SmartBear\TestComplete 12\Bin\Extensions\ScriptExtensions`
<br/>TestExecute example:<br/>
`C:\Program Files (x86)\SmartBear\TestExecute 12\Bin\Extensions\ScriptExtensions`
4) Install the <a href="https://www.videolan.org/vlc/index.html">VLC media player</a>
5) Launch product and use the extension as you want.

# How to use it
You can use the extension in your KeywordTest or sript. The main concept is to have two points in your test - where you want to start video recording and where you want to finish it. So, you can not only record the whole test run, but also record only specific moments in your test run. You can also record video not only one time for one test run, but as many times as you want. 
Every starting of the video recording process should be finished properly. Please, <b>pay attention</b> to finaliyzing you recording properly by <b>Stop Video Recording</b> operation, VideoRecorder.Stop() or closing the TestComplete/TestExecute product, if you don't do this the video will be corrupted. For example, if you close VLC player manually, you won't be able to play the video.
Also you can use <a href="https://support.smartbear.com/testcomplete/docs/reference/events/onstarttest.html">OnStartTest Event</a> and <a href="https://support.smartbear.com/testcomplete/docs/reference/events/onstoptest.html">OnStopTest Event</a> to manage your recording process. If you use this approach it's garantee that you don't forget to finish the video recording process.

## Using in KeywordTest
When extension will be installed, two new Keyword test operation are available. Both of them are in Logging group and manage the video recording process. To start record video use <b>Start Video Recording</b> operation (<img src="https://github.com/AlexanderGubarev/RecordVideo-TestComplete-extension/blob/master/src/VideoStart-16.png" height="16">). Please, put it in the place of your test where you want to srart record video. When you add this operation, you need to choose the <b>VideoQuality</b> parameter. If you want to record video with `Low` or `High` quality, just put one of this text constant as value of <b>VideoQuality</b> parameter of this operation. Use the <b>Stop Video Recording</b> operation (<img src="https://github.com/AlexanderGubarev/RecordVideo-TestComplete-extension/blob/master/src/VideoStop-16.png" height="16">) in place of your test where you want to stop video recording.
Example of test:
<br/>
<img src="https://github.com/AlexanderGubarev/RecordVideo-TestComplete-extension/blob/master/README.files/KDT_RecordVideo.png" height="300">

## Using in scripts
Use the <b>VideoRecorder</b> object if you prefer to write scripts. This object can be used in any supported script languages. You need to write <b>Start()</b> method to start recording. Please, put it in the place of your code where you want to srart record video. If you want to record video with `Low` or `High` quality, just put this text constant as parameter of this method. If parameter is ommited video will be recorded with <i>Normal</i> quality. Notice that the result video file size depends not only on <b>VideoQuality</b> parameter but also on how long the video is and the screen resolution. Use the <b>Stop()</b> method where you want to stop video recording.
Example of script:
```JavaScript
function NotepadTest()
{
  VideoRecorder.Start("High") //record with High quality
  
  WshShell.Run("notepad");
  
  var pNotepad = Sys.WaitProcess("notepad", 10*1000);
  
  var wMain = pNotepad.Window("Notepad", "*Notepad")
  var wEdit = wMain.Window("Edit")
  wEdit.Keys("TEST")
  wMain.MainMenu.Click("Help|About Notepad");
  
  pNotepad.Window("#32770", "About Notepad").Window("Button", "OK").ClickButton();
  
  pNotepad.Close()
  
  VideoRecorder.Stop() //stop recording
}
```


# Supported versions

We test this extension on
* TestComplete 12.40
* VLC media player 2.2.6
but we quite sure that it can be used on other versions of these products as well.



# Technology used

* JScript
* <a href="https://smartbear.com/product/testcomplete/overview/">TestComplete</a>
* <a href="https://www.videolan.org/vlc/index.html">VLC media player</a>



# Restrictions and known issues

* It supports only recording of main screen now.
* If test is interrupted (for example, the "Stop on Error" setting is on), the Log will be locked, so, the information about recording with link to the video file cannot be posted. In this case the video will be generated just after the product closing and you can find the path to the video in the <i>Additional Information</i> of message about recording start. Also you can use <a href="https://support.smartbear.com/testcomplete/docs/reference/events/onstarttest.html">OnStartTest Event</a> and <a href="https://support.smartbear.com/testcomplete/docs/reference/events/onstoptest.html">OnStopTest Event</a> to manage your recording process. In this case the video will be generated all the times and you don't need to put any othe code or operations in your test.
