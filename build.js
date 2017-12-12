var srcDir = "src";
var outDir = "out";
var outFileName = "RecordVideo";

// Evaluate paths
var fso = new ActiveXObject("Scripting.FileSystemObject");
var currDir = fso.GetAbsolutePathName(".");
var srcPath = currDir + "\\" + srcDir;
var zipFileDir = currDir + "\\" + outDir;
var zipFilePath = zipFileDir + "\\" + outFileName + ".zip";
var extFilePath = zipFileDir + "\\" + outFileName + ".tcx";

// Delete existing output directory
if (fso.FolderExists(zipFileDir)) {
    fso.DeleteFolder(zipFileDir);
}

//Create output directory
fso.CreateFolder(zipFileDir);

// Create empty zip file
var zipFile = fso.CreateTextFile(zipFilePath, true, false);
var emptyZipContent = "PK" + String.fromCharCode(5, 6);
for(var i = 0; i < 18; i++) {
    emptyZipContent += String.fromCharCode(0);
}
zipFile.Write(emptyZipContent);
zipFile.Close();

// Copy sources to zip
var shapp = new ActiveXObject("Shell.Application");
var sources = shapp.NameSpace(srcPath).Items();
shapp.NameSpace(zipFilePath).CopyHere(sources);

WScript.Echo("Zipping, please wait...");
WScript.Sleep(3000);

// Rename zip to tcx
fso.MoveFile(zipFilePath, extFilePath);

WScript.Echo("Done.");
WScript.Echo("Script extension file: " + extFilePath);
