package util;

#if android
import lime.system.JNI;
import lime.app.Application;
#end

import haxe.CallStack;
import haxe.io.Path;
import lime.system.System as LimeSystem;
import lime.utils.Assets as LimeAssets;
import lime.utils.Log as LimeLogger;
import openfl.Lib;
import openfl.events.UncaughtErrorEvent;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;

enum StorageType {
    DATA;
    EXTERNAL;
    EXTERNAL_DATA;
    MEDIA;
}

class SUtil
{
    // -------- ANDROID PATH HELPERS (Safe replacements) --------

    #if android
    private static var getExternalFilesDir = JNI.createStaticMethod(
        "org/haxe/lime/LimeActivity",
        "getExternalFilesDir",
        "(Ljava/lang/String;)Ljava/lang/String;"
    );

    private static var getFilesDir = JNI.createStaticMethod(
        "org/haxe/lime/LimeActivity",
        "getFilesDir",
        "()Ljava/lang/String;"
    );

    private static var getExternalStorageDirectory = JNI.createStaticMethod(
        "android/os/Environment",
        "getExternalStorageDirectory",
        "()Ljava/io/File;"
    );
    #end


    // -------- STORAGE DIRECTORY HANDLER --------

    public static function getStorageDirectory(type:StorageType = MEDIA):String
    {
        var daPath:String = "";

        #if android
        switch (type)
        {
            case DATA:
                daPath = getFilesDir() + "/";
            case EXTERNAL_DATA:
                daPath = getExternalFilesDir(null) + "/";
            case EXTERNAL:
                daPath = getExternalStorageDirectory().toString() + "/." + Application.current.meta.get("file") + "/";
            case MEDIA:
                daPath = getExternalStorageDirectory().toString() + "/Android/media/" + Application.current.meta.get("packageName") + "/";
        }
        #elseif ios
        daPath = LimeSystem.applicationStorageDirectory;
        #end

        return daPath;
    }


    // -------- FILE CHECKER --------

    public static function checkFiles():Void
    {
        #if mobile
        if (!FileSystem.exists(SUtil.getStorageDirectory()))
        {
            try {
                FileSystem.createDirectory(SUtil.getStorageDirectory());
            }
            catch (e) {
                Lib.application.window.alert('Please create folder:\n' + SUtil.getStorageDirectory() + '\nPress OK to exit.', 'Error!');
                LimeSystem.exit(1);
            }
        }

        if (!FileSystem.exists(SUtil.getStorageDirectory() + 'assets') && !FileSystem.exists(SUtil.getStorageDirectory() + 'mods'))
        {
            Lib.application.window.alert(
                "You didn’t extract assets/mods from the APK!\nCopy them into:\n" + SUtil.getStorageDirectory(),
                "Error!"
            );
            LimeSystem.exit(1);
        }
        #end
    }


    // -------- ERROR HANDLER --------

    public static function uncaughtErrorHandler():Void
    {
        Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onError);
        Lib.application.onExit.add(function(exitCode:Int)
        {
            if (Lib.current.loaderInfo.uncaughtErrorEvents.hasEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR))
                Lib.current.loaderInfo.uncaughtErrorEvents.removeEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onError);
        });
    }


    private static function onError(e:UncaughtErrorEvent):Void
    {
        var stack:Array<String> = [];
        stack.push(e.error);

        for (stackItem in CallStack.exceptionStack(true))
        {
            switch (stackItem)
            {
                case CFunction: stack.push("C Function");
                case Module(m): stack.push("Module ($m)");
                case FilePos(s, file, line, col): stack.push("$file (line $line)");
                case Method(classname, method): stack.push("$classname::$method()");
                case LocalFunction(name): stack.push("Local Function ($name)");
            }
        }

        e.preventDefault();
        e.stopImmediatePropagation();

        var msg = stack.join("\n");

        #if sys
        try {
            if (!FileSystem.exists(SUtil.getStorageDirectory() + "logs"))
                FileSystem.createDirectory(SUtil.getStorageDirectory() + "logs");

            File.saveContent(
                SUtil.getStorageDirectory() + "logs/" +
                Lib.application.meta.get("file") + "-" +
                Date.now().toString().replace(" ", "-").replace(":", "'") +
                ".txt",
                msg + "\n"
            );
        }
        catch (ex) {
            LimeLogger.println("Couldn't save crash log:\n" + ex);
        }
        #end

        LimeLogger.println(msg);
        Lib.application.window.alert(msg, "Error!");
        LimeSystem.exit(1);
    }


    // -------- DIRECTORY CREATION (safe) --------

    #if sys
    public static function mkDirs(directory:String):Void
    {
        var total = "";
        if (directory.startsWith("/"))
            total = "/";

        var parts = directory.split("/");

        if (parts.length > 0 && parts[0].indexOf(":") > -1)
            parts.shift();

        for (p in parts)
        {
            if (p != "." && p != "")
            {
                if (total != "" && total != "/")
                    total += "/";
                total += p;

                if (!FileSystem.exists(total))
                    FileSystem.createDirectory(total);
            }
        }
    }


    public static function saveContent(fileName:String = "file", ext:String = ".json", data:String = "empty"):Void
    {
        try {
            if (!FileSystem.exists(SUtil.getStorageDirectory() + "saves"))
                FileSystem.createDirectory(SUtil.getStorageDirectory() + "saves");

            File.saveContent(SUtil.getStorageDirectory() + "saves/" + fileName + ext, data);
        }
        catch (e) {
            LimeLogger.println("Couldn't save file:\n" + e);
        }
    }


    public static function copyContent(copyPath:String, savePath:String):Void
    {
        try {
            if (!FileSystem.exists(savePath) && LimeAssets.exists(copyPath))
            {
                if (!FileSystem.exists(Path.directory(savePath)))
                    SUtil.mkDirs(Path.directory(savePath));

                File.saveBytes(savePath, LimeAssets.getBytes(copyPath));
            }
        }
        catch (e) {
            LimeLogger.println("Couldn't copy $copyPath:\n" + e);
        }
    }
    #end
}
