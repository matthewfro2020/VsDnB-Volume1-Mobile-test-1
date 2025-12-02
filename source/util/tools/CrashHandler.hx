package util.tools;

import sys.io.File;
import lime.app.Application;
import haxe.Exception;
import haxe.CallStack;
import openfl.Lib;
import openfl.events.UncaughtErrorEvent;
import flixel.FlxG;

/**
 * A core handler that's used whenever the program crashes. 
 * This overrides the default crasher to give more debugging information related to the crash. 
 */
class CrashHandler
{
    static var LINE_SEPERATOR = '<----------------------------------------->';

    public static function initalize()
    {
        Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onError);
    }

    static function onError(e:UncaughtErrorEvent)
    {
        try
        {
            var crashMessage:String = buildCrashLog(e);

            displayErrorMessage(e);

            buildCrashFile(crashMessage);

			Sys.sleep(1);
			FlxG.stage.application.window.close();
        }
        catch (e:Exception) {
            trace("Crash occured during crash handler. Message: " + e.message);
        }
    }

    /**
     * Displays an error message to the Lime Window before the application closes.
     * @param errorMessage The error messasge to display.
     */
    static function displayErrorMessage(e:UncaughtErrorEvent)
    {
        var messageToDisplay:String = "";

        var errorMessage:String = e.error;
        var callStackInfo:Array<String> = generateCallstackInfo();

        messageToDisplay += "A Fatal Error has occured causing the game to crash.\n\n";

        messageToDisplay += 'Error Message: ${errorMessage}\n\n';
        messageToDisplay += "Callstack:\n";

        for (callStack in callStackInfo) {
            messageToDisplay += '${callStack}\n';
        }
        messageToDisplay += '\n';

        messageToDisplay += '${LINE_SEPERATOR}\n\n';
        messageToDisplay += 'A crash log has been generated in the ".crashes" folder that contains more details to help with reporting.';
        
        FlxG.stage.application.window.alert(messageToDisplay, "A Fatal Error has occured.");
    }

    /**
     * Creates a message that provides details of the error message, and current state of the game during the crash.
     * @param e The uncaught error that's being reported.
     * @return A String containing the crash message. 
     */
    static function buildCrashLog(e:UncaughtErrorEvent):String
    {
        // SYSTEM INFORMATION // 
        var systemName:String = Sys.systemName();
        var driverInfo:String = Lib.current.stage.context3D?.driverInfo ?? "N/A";
        var date:String = Date.now().toString();
		
        // GAME INFORMATION //
        var modVersion = Application.current.meta.get("version");

		var buildType:String = "";
		#if debug
        buildType = "Debug";
		#elseif 32
		buildType = "32 Bit";
        #elseif release
        buildType = "Release";
		#end
        
        var buildNumber:String = Application.current.meta.get("build");

        var haxeLibs:Array<String> = [];  // TODO: Find a way to get the project's haxelibs & versions.

        var currentStateName:String = Type.getClassName(Type.getClass(FlxG.state));

        // ERROR INFORMATION //
        var errorMessage:String = e.error;
        var callStackInfo:Array<String> = generateCallstackInfo();

        // GENERATING THE MESSAGE //
        
        var message:String = "";
        
        message += '${LINE_SEPERATOR}\n';

        message += "SYSTEM/GAME INFO:\n";
        
        message += 'System Name: ${systemName}\n';
        message += 'Driver Info: ${driverInfo}\n\n';
        message += 'Crash Timestamp: ${date}\n\n';

        message += 'Mod Information: Version ${modVersion}\n';
        message += 'Build Information: ${buildType} Build (Build #${buildNumber})\n\n';

        message += 'Current Flixel State: ${currentStateName}\n\n';

        message += "\n";
        
        message += '${LINE_SEPERATOR}\n';
        message += "ERROR INFORMATION:\n";
        message += 'Error Message: ${errorMessage}\n\n';

        message += 'Error Callstack:\n';
        for (callStack in callStackInfo) {
            message += '${callStack}\n';
        }

        return message;
    }

    /**
     * Generates a crash file to insert into the game's crash folder.
     * @param message The message to be in the file's content
     */
    static function buildCrashFile(crashMessage:String)
    {
        var messageToSave = "";

        messageToSave += '${LINE_SEPERATOR}\n';

        messageToSave += 'Vs. Dave & Bambi Crash Reporter - ${Date.now().toString()}\n';

        messageToSave += crashMessage;

        
        // TODO: does this work for all platforms?
        var crashFolder:String = Sys.getCwd() + "/.crashes";
        var crashFileName:String = 'crash-${Date.now().toString().replace(":", "-")}.log';

        // Save the file into the crash folder.
        FileUtil.createDirectory(crashFolder);
        File.saveContent('${crashFolder}/${crashFileName}', messageToSave);
    }

    /**
     * Generates a list of messages for the crash log message to use based on the error callstack.
     * @return A list of stack messages to be used by the crash message.
     */
    static function generateCallstackInfo():Array<String>
    {
        var stackList:Array<StackItem> = CallStack.exceptionStack(true);
        var callStackMessages:Array<String> = [];

        for (stack in stackList)
        {
            var stackItemMessage = "At ";
            switch (stack)
            {
                case CFunction:
                    stackItemMessage += "(Function) ";
                case Module(m):
                    stackItemMessage += "Module " + m;
                case FilePos(s, file, line, column):
                    stackItemMessage += '${file} -> Line ${line}';
                    if (column != null) {
                        stackItemMessage += ':${column}';
                    }
                case Method(className, method):
                    stackItemMessage += 'Class: ${className}, Function: ${method}';
                case LocalFunction(v):
                    stackItemMessage += '(Local Function): ${v}';
            }
            callStackMessages.push(stackItemMessage);
        }
        return callStackMessages;
    }
}