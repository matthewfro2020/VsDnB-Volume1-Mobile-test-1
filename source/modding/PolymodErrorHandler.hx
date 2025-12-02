package modding;

import polymod.Polymod.PolymodErrorType;
import flixel.FlxG;
import polymod.Polymod.PolymodError;

class PolymodErrorHandler
{
    public static function printError(error:PolymodError):Void
    {
        switch (error.code)
        {
            case SCRIPT_PARSE_ERROR:
                // Print the parsing error in the console.
                log(ERROR, error.message);

                // Show a popup.
                showErrorAlert(error.message, 'There was an error while parsing a script.');

            case SCRIPT_CLASS_MODULE_BLACKLISTED:
                // Show a pop-up for a blacklist error.
                showErrorAlert(error.message, 'Polymod Script Blacklist Error');

            case SCRIPT_RUNTIME_EXCEPTION:
                // Log the runtime error in the console.
                log(ERROR, 'SCRIPT RUNTIME ERROR - ${error.message}');

                showErrorAlert(error.message, 'There was an error while the script was running.');
            case PARSE_MOD_META, PARSE_MOD_VERSION, PARSE_MOD_API_VERSION, PARSE_API_VERSION:
                trace('[POLYMOD] MOD PARSING ERROR - ${error.message}');

                showErrorAlert(error.message, 'There was an error while parsing a mod.');
                
            case SCRIPT_CLASS_NOT_REGISTERED, SCRIPT_CLASS_MODULE_NOT_FOUND:
                log(NOTICE, 'SCRIPT WARNING - ${error.message}');
                
                showErrorAlert(error.message, 'Polymod Script Error Notice');
                
            case MOD_LOAD_FAILED:
                trace('[POLYMOD] MOD FAILED TO LOAD - ${error.message}');
            case MOD_LOAD_PREPARE:
                trace('[POLYMOD] LOADING MOD - ${error.message}');
            case MOD_LOAD_DONE:
                trace('[POLYMOD] MOD FINISHED LOADING: ${error.message}');

            case SCRIPT_NOT_FOUND:
                trace('[POLYMOD] SCRIPT NOT FOUND - ${error.message}');
            case SCRIPT_CLASS_ALREADY_REGISTERED, SCRIPT_CLASS_MODULE_ALREADY_IMPORTED:
                trace('[POLYMOD] SCRIPT NOTICE - ${error.message}');

            case POLYMOD_NOT_LOADED:
                trace('[POLYMOD] NOT LOADED - ${error.message}');
            case MISSING_MOD:
                trace('[POLYMOD] MISSING MOD - ${error.message}');
            default:
                log(error.severity, error.message);
        }
    }

    /**
     * Displays a window pop-up message to give an error message.
     * @param message The message to show.
     * @param title The title of the window.
     */
    public static function showErrorAlert(errorMessage:String, title:String)
    {
        FlxG.stage.application.window.alert(errorMessage, title);
    }

    /**
     * Logs a Polymod error into the console.
     * @param type The severity of the Polymod error.
     * @param message The message to display.
     */
    public static function log(type:PolymodErrorType, message:String)
    {
        switch (type)
        {
            case NOTICE:
                trace('[POLYMOD: NOTICE] ${message}');
            case WARNING:
                trace('[POLYMOD: WARNING] ${message}');
            case ERROR:
                trace('[POLYMOD: ERROR] ${message}');
        }
    }
}