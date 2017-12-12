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
You can use the extension in your KeywordTest or sript. In both ways there is only one parameter for video recording, <b>VideoQuality</b> - and it can be `Low`,`Normal`, `High`. If parameter is ommited video will be recorded with <i>Normal</i> quality. Notice that the result video file size depends not only on <b>VideoQuality</b> parameter but also on how long the video is and the screen resolution.

## Using in KeywordTest
When extension will be installed, two new Keyword test operation are available. Both of them are in Logging group and manage the video recording process. To start record video use <b>Start Video Recording</b> operation (<img src="https://github.com/AlexanderGubarev/RecordVideo-TestComplete-extension/blob/master/src/VideoStart-16.png" height="16">). Please, put it in the place of your test where you want to srart record video. When you add this operation, you need to choose the <b>VideoQuality</b> parameter. If you want to record video with `Low` or `High` quality, just put one of this text constant as value of <b>VideoQuality</b> parameter of this operation. Use the <b>Stop Video Recording</b> operation (<img src="https://github.com/AlexanderGubarev/RecordVideo-TestComplete-extension/blob/master/src/VideoStop-16.png" height="16">) in place of your test where you want to stop video recording.
Example of test:
<br/>
<img src="https://github.com/AlexanderGubarev/RecordVideo-TestComplete-extension/blob/master/README.files/KDT_RecordVideo.png" height="300">

## Using in scripts
Use the <b>VideoRecorder</b> object if you prefer to write scripts. This object can be used in any supported script languages. You need to write <b>Start()</b> method to start recording. Please, put it in the place of your code where you want to srart record video. If you want to record video with `Low` or `High` quality, just put this text constant as parameter of this method. Use the <b>Stop()</b> method where you want to stop video recording.
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
* If test is interrupted, the Log will be locked, so, the information about recording with link to the video file cannot be posted. In this case the video will be generated just after the product closing and you can find the path to the video in the <i>Additional Information</i> of message about recording start.
