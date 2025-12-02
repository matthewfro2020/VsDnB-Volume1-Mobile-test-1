package polymod;

#if ios
@:keep
@:structAccess
#end
import haxe.Json;
import haxe.io.Bytes;
import polymod.backends.IBackend;
import polymod.backends.PolymodAssetLibrary;
import polymod.backends.PolymodAssets;
import polymod.format.JsonHelp;
import polymod.format.ParseRules;
import polymod.fs.PolymodFileSystem;
#if hscript
import polymod.hscript._internal.PolymodScriptClass;
#end
import polymod.util.DependencyUtil;
import polymod.util.VersionUtil;
import thx.semver.Version;
import thx.semver.VersionRule;

using StringTools;

#if firetongue
import firetongue.FireTongue;
#end

// ----------------------------------------------------------
//  iOS FIX: Remove ThxNil and curExpr
// ----------------------------------------------------------
#if ios
private typedef SafeDynamic = Null<Dynamic>;
#else
private typedef SafeDynamic = Dynamic;
#end

/**
 * Any framework-specific settings
 * Right now this is only used to specify asset library paths for the Lime/OpenFL framework but we'll add more framework-specific settings here as neeeded
 */
typedef FrameworkParams =
{
	/**
	 * (optional) if you're using Lime/OpenFL AND you're using custom or non-default asset libraries, then you must provide a key=>value store mapping the name of each asset library to a path prefix in your mod structure
	 */
	?assetLibraryPaths:Map<String, String>,

	/**
	 * (optional) specify this path to redirect core asset loading to a different path
	 * you can set this up to load core assets from a parent directory!
	 * Not applicable for file systems which don't use a directory obvs.
	 */
	 ?coreAssetRedirect:String
}

typedef ScanParams =
{
	?modRoot:String,
	?apiVersionRule:VersionRule,
	?errorCallback:PolymodError->Void,
	?fileSystem:IFileSystem
}

/**
 * The framework which your Haxe project is using to manage assets
 */
enum Framework
{
	CASTLE;
	NME;
	LIME;
	OPENFL;
	OPENFL_WITH_NODE;
	FLIXEL;
	HEAPS;
	KHA;
	CERAMIC;
	CUSTOM;
	UNKNOWN;
}


typedef ModDependencies = Map<String, VersionRule>;

/**
 * A type representing data about a mod, as retrieved from its metadata file.
 */
class ModMetadata
{
	/**
	 * The internal ID of the mod.
	 */
	public var id:String;

	/**
	 * The human-readable name of the mod.
	 */
	public var title:String;

	/**
	 * A short description of the mod.
	 */
	public var description:String;

	/**
	 * A link to the homepage for a mod.
	 * Should provide a URL where the mod can be downloaded from.
	 */
	public var homepage:String;

	/**
	 * A version number for the API used by the mod.
	 * Used to prevent compatibility issues with mods when the application changes.
	 */
	public var apiVersion:Version;

	/**
	 * A version number for the mod itself.
	 * Should be provided in the Semantic Versioning format.
	 */
	public var modVersion:Version;

	/**
	 * The name of a license determining the terms of use for the mod.
	 */
	public var license:String;

	/**
	 * Binary data containing information on the mod's icon file, if it exists.
	 * This is useful when you want to display the mod's icon in your application's mod menu.
	 */
	public var icon:Bytes = null;

	/**
	 * The path on the filesystem to the mod's icon file.
	 */
	public var iconPath:String;

	/**
	 * The path where this mod's files are stored, on the IFileSystem.
	 */
	public var modPath:String;

	/**
	 * `metadata` provides an optional list of keys.
	 * These can provide additional information about the mod, specific to your application.
	 */
	public var metadata:Map<String, String>;

	/**
	 * A list of dependencies.
	 * These other mods must be also be loaded in order for this mod to load,
	 * and this mod must be loaded after the dependencies.
	 */
	public var dependencies:ModDependencies;

	/**
	 * A list of dependencies.
	 * This mod must be loaded after the optional dependencies,
	 * but those mods do not necessarily need to be loaded.
	 */
	public var optionalDependencies:ModDependencies;

	/**
	 * A deprecated field representing the mod's author.
	 * Please use the `contributors` field instead.
	 */
	@:deprecated
	public var author(get, set):String;

	// author has been made a property so setting it internally doesn't throw deprecation warnings
	var _author:String;

	function get_author()
	{
		if (contributors.length > 0)
		{
			return contributors[0].name;
		}
		return _author;
	}

	function set_author(v):String
	{
		if (contributors.length == 0)
		{
			contributors.push({name: v});
		}
		else
		{
			contributors[0].name = v;
		}
		return v;
	}

	/**
	 * A list of contributors to the mod.
	 * Provides data about their roles as well as optional contact information.
	 */
	public var contributors:Array<ModContributor>;

	public function new()
	{
		// No-op constructor.
	}

	public function toJsonStr():String
	{
		var json = {};
		Reflect.setField(json, 'title', title);
		Reflect.setField(json, 'description', description);
		// Reflect.setField(json, 'author', _author);
		Reflect.setField(json, 'contributors', contributors);
		Reflect.setField(json, 'homepage', homepage);
		Reflect.setField(json, 'api_version', apiVersion.toString());
		Reflect.setField(json, 'mod_version', modVersion.toString());
		Reflect.setField(json, 'license', license);
		var meta = {};
		for (key in metadata.keys())
		{
			Reflect.setField(meta, key, metadata.get(key));
		}
		Reflect.setField(json, 'metadata', meta);
		return Json.stringify(json, null, '    ');
	}

	public static function fromJsonStr(str:String)
	{
		if (str == null || str == '')
		{
			Polymod.error(PARSE_MOD_META, 'Error parsing mod metadata file, was null or empty.');
			return null;
		}

		var json = null;
		try
		{
			json = haxe.Json.parse(str);
		}
		catch (msg:Dynamic)
		{
			Polymod.error(PARSE_MOD_META, 'Error parsing mod metadata file: (${msg})');
			return null;
		}

		var m = new ModMetadata();
		m.title = JsonHelp.str(json, 'title');
		m.description = JsonHelp.str(json, 'description');
		m._author = JsonHelp.str(json, 'author');
		m.contributors = JsonHelp.arrType(json, 'contributors');
		m.homepage = JsonHelp.str(json, 'homepage');
		var apiVersionStr = JsonHelp.str(json, 'api_version');
		var modVersionStr = JsonHelp.str(json, 'mod_version');
		try
		{
			m.apiVersion = apiVersionStr;
		}
		catch (msg:Dynamic)
		{
			Polymod.error(PARSE_MOD_API_VERSION, 'Error parsing API version: (${msg}) ${PolymodConfig.modMetadataFile} was ${str}');
			return null;
		}
		try
		{
			m.modVersion = modVersionStr;
		}
		catch (msg:Dynamic)
		{
			Polymod.error(PARSE_MOD_VERSION, 'Error parsing mod version: (${msg}) ${PolymodConfig.modMetadataFile} was ${str}');
			return null;
		}
		m.license = JsonHelp.str(json, 'license');
		m.metadata = JsonHelp.mapStr(json, 'metadata');

		m.dependencies = JsonHelp.mapVersionRule(json, 'dependencies');
		m.optionalDependencies = JsonHelp.mapVersionRule(json, 'optionalDependencies');

		return m;
	}
}

class Polymod
{
    public static var onError:PolymodError->Void = null;
    private static var assetLibrary:PolymodAssetLibrary = null;

    #if firetongue
    private static var tongue:FireTongue = null;
    #end

    private static var prevParams:PolymodParams = null;

    // ------------------------------------------------------
    // INIT
    // ------------------------------------------------------
    public static function init(params:PolymodParams):Array<ModMetadata>
    {
        if (params.errorCallback != null)
            onError = params.errorCallback;

        var modRoot = params.modRoot;
        if (modRoot == null)
        {
            if (params.fileSystemParams.modRoot != null)
                modRoot = params.fileSystemParams.modRoot;
            else
                modRoot = "./mods";
        }

        if (params.fileSystemParams == null)
            params.fileSystemParams = { modRoot: modRoot };
        if (params.fileSystemParams.modRoot == null)
            params.fileSystemParams.modRoot = modRoot;

        var fileSystem = PolymodFileSystem.makeFileSystem(params.customFilesystem, params.fileSystemParams);

        // Load metadata safely
        var mods = [];
        for (dir in (params.dirs == null ? [] : params.dirs))
        {
            var meta = fileSystem.getMetadata(dir);
            if (meta != null)
                mods.push(meta);
        }

        // Sort by dependencies
        var sorted = (params.skipDependencyChecks)
            ? mods
            : DependencyUtil.sortByDependencies(mods, params.skipDependencyErrors);

        var paths = sorted.map(m -> m.modPath);

        // Initialize library
        assetLibrary = PolymodAssets.init({
            framework: params.framework,
            dirs: paths,
            parseRules: params.parseRules,
            ignoredFiles: params.ignoredFiles,
            customBackend: params.customBackend,
            extensionMap: params.extensionMap,
            frameworkParams: params.frameworkParams,
            fileSystem: fileSystem,
            assetPrefix: params.assetPrefix,
            #if firetongue
            firetongue: params.firetongue,
            #end
        });

        prevParams = params;
        return sorted;
    }

    // ------------------------------------------------------
    // SAFE HScript Registration for iOS
    // ------------------------------------------------------
    public static function registerAllScriptClasses():Void
    {
        #if hscript
        var list = Polymod.assetLibrary.list(TEXT);
        for (p in list)
        {
            if (p.endsWith(".hxc"))
            {
                try {
                    PolymodScriptClass.registerScriptClassByPath(p);
                } catch (e) {
                    Polymod.error(SCRIPT_PARSE_ERROR, 'Failed to parse script: $p ($e)');
                }
            }
        }
        #end
    }

    // ------------------------------------------------------
    // Error helpers
    // ------------------------------------------------------
    public static function error(code:PolymodErrorCode, msg:String, ?o:PolymodErrorOrigin = UNKNOWN)
        if (onError != null) onError(new PolymodError(ERROR, code, msg, o));

    public static function warning(code:PolymodErrorCode, msg:String, ?o:PolymodErrorOrigin = UNKNOWN)
        if (onError != null) onError(new PolymodError(WARNING, code, msg, o));

    public static function notice(code:PolymodErrorCode, msg:String, ?o:PolymodErrorOrigin = UNKNOWN)
        if (onError != null) onError(new PolymodError(NOTICE, code, msg, o));
}

/**
 * Structured data on an error that occurred during Polymod's operation.
 */
class PolymodError
{
	/**
	 * Indicates the severity of the issue.
	 * See `PolymodErrorType` for more information.
	 */
	public var severity:PolymodErrorType;

	/**
	 * A particular error which occurred during Polymod's operation.
	 * You can use this with a switch statement to automatically resolve specific errors,
	 * or provide special messages for others.
	 */
	public var code:PolymodErrorCode;

	/**
	 * A human-readable message providing more context for the error which occurred.
	 */
	public var message:String;

	/**
	 * Some brief context on where the error occurred.
	 */
	public var origin:PolymodErrorOrigin;

	public function new(severity:PolymodErrorType, code:PolymodErrorCode, message:String, ?origin:PolymodErrorOrigin = UNKNOWN)
	{
		this.severity = severity;
		this.code = code;
		this.message = message;
		this.origin = origin;
	}
}

/**
 * Indicates where the error occurred.
 */
enum abstract PolymodErrorOrigin(String) from String to String
{
	/**
	 * This error occurred while scanning for mods.
	 */
	var SCAN:String = 'scan';

	/**
	 * This error occurred while initializing Polymod.
	 */
	var INIT:String = 'init';

	/**
	 * This error occurred in an undefined location.
	 */
	var UNKNOWN:String = 'unknown';
}

/**
 * Represents the severity level of a given error.
 */
enum PolymodErrorType
{
	/**
	 * This message is merely an informational notice.
	 * You can handle it with a popup, log it, or simply ignore it.
	 */
	NOTICE;

	/**
	 * This message is a warning.
	 * Either the application developer, the mod developer, or the user did something wrong.
	 */
	WARNING;

	/**
	 * This message indicates a severe error occurred.
	 * This almost certainly will cause unintended behavior. A certain mod may not load or may even cause crashes.
	 */
	ERROR;
}

/**
 * Represents the particular type of error that occurred.
 * Great to use as the condition of a switch statement to provide special handling for specific errors.
 */
enum abstract PolymodErrorCode(String) from String to String
{
	/**
	 * The mod's metadata file could not be parsed.
	 * - Make sure the file contains valid JSON.
	 */
	var PARSE_MOD_META:String = 'parse_mod_meta';

	/**
	 * The mod's version string could not be parsed.
	 * - Make sure the metadata JSON contains a valid Semantic Version string.
	 */
	var PARSE_MOD_VERSION:String = 'parse_mod_version';

	/**
	 * The mod's API version string could not be parsed.
	 * - Make sure the metadata JSON contains a valid Semantic Version string.
	 */
	var PARSE_MOD_API_VERSION:String = 'parse_mod_api_version';

	/**
	 * The app's API version string (passed to Polymod.init) could not be parsed.
	 * - Make sure the string is a valid Semantic Version string.
	 */
	var PARSE_API_VERSION:String = 'parse_api_version';

	/**
	 * Polymod attempted to load a mod, but one or more of its dependencies were missing.
	 * - This is a warning if `skipDependencyErrors` is true, the problematic mod will be skipped.
	 * - This is an error if `skipDependencyErrors` is false, no mods will be loaded.
	 * - Make sure to inform the user that the required mods are missing.
	 */
	var DEPENDENCY_UNMET:String = 'dependency_unmet';

	/**
	 * Polymod attempted to load a mod, and its dependency was found,
	 * but the version number of the dependency did not match that required by the mod.
	 * - This is a warning if `skipDependencyErrors` is true, the problematic mod will be skipped.
	 * - This is an error if `skipDependencyErrors` is false, no mods will be loaded.
	 * - Make sure to inform the user that the required mods have a mismatched version.
	 */
	var DEPENDENCY_VERSION_MISMATCH:String = 'dependency_version_mismatch';

	/**
	 * Polymod attempted to load a mod, but one of its dependencies created a loop.
	 * For example, Mod A requires Mod B, which requires Mod C, which requires Mod A.
	 * - This is a warning if `skipDependencyErrors` is true, the problematic mods will be skipped.
	 * - This is an error if `skipDependencyErrors` is false, no mods will be loaded.
	 * - Inform the mod authors that the dependency issue exists and must be resolved.
	 */
	var DEPENDENCY_CYCLICAL:String = 'dependency_cyclical';

	/**
	 * Polymod was configured to skip dependency checks when loading mods, and that mod order should not be checked.
	 * - Make sure you are certain this behavior is correct and that you have properly configured Polymod.
	 * - This is a warning and can be ignored.
	 */
	var DEPENDENCY_CHECK_SKIPPED:String = 'dependency_check_skipped';

	/**
	 * Polymod tried to access a file that was not found.
	 * - Make sure the file exists before attempting to access it.
	 */
	var FILE_MISSING:String = "file_missing";

	/**
	 * Polymod tried to access a directory that was not found.
	 * - Make sure the directory exists before attempting to access it.
	 */
	var DIRECTORY_MISSING:String = "directory_missing";

	/**
	 * You requested a mod to be loaded but that mod was not installed.
	 * - Make sure a mod with that ID is installed.
	 * - Make sure to run Polymod.scan to get the list of valid mod IDs.
	 */
	var MISSING_MOD:String = 'missing_mod';

	/**
	 * You requested a mod to be loaded but its mod folder is missing a metadata file.
	 * - Make sure the mod folder contains a metadata JSON file. Polymod won't recognize the mod without it.
	 */
	var MISSING_META:String = 'missing_meta';

	/**
	 * A mod with the given ID is missing an icon file.
	 * - This is a warning and can be ignored. Polymod will still load your mod, but it looks better if you add an icon.
	 * - The default location for icons is `_polymod_icon.png`.
	 */
	var MISSING_ICON:String = 'missing_icon';

	/**
	 * We are preparing to load a particular mod.
	 * - This is an info message. You can log it or ignore it if you like.
	 */
	var MOD_LOAD_PREPARE:String = 'mod_load_prepare';

	/**
	 * We couldn't load a particular mod.
	 * - There will generally be a warning or error before this indicating the reason for the error.
	 */
	var MOD_LOAD_FAILED:String = 'mod_load_failed';

	/**
	 * We have successfully completed loading a particular mod.
	 * - This is an info message. You can log it or ignore it if you like.
	 * - This is also a good trigger for a UI indicator like a toast notification.
	 */
	var MOD_LOAD_DONE:String = 'mod_load_done';

	/**
	 * You passed a bad argument to Polymod.init({customFilesystem}).
	 * - Ensure the input is either an IFileSystem or a Class<IFileSystem>.
	 */
	var BAD_CUSTOM_FILESYSTEM:String = 'bad_custom_filesystem';

	/**
	 * You attempted to perform an operation that requires Polymod to be initialized.
	 * - Make sure you call Polymod.init before attempting to call this function.
	 */
	var POLYMOD_NOT_LOADED:String = 'polymod_not_loaded';

	/**
	 * Script classes are currently disabled because the `hscript` library is not available.
	 * - Make sure you have the `hscript` Haxelib installed if you want to use scripts.
	 */
	var SCRIPT_HSCRIPT_NOT_INSTALLED:String = 'script_hscript_not_installed';

	/**
	 * A script file of the given name could not be found.
	 * - This happens when calling annotated functions in an HScriptable class when no script file exists.
	 * - Make sure the script file exists in the proper location in your assets folder.
	 * - Alternatively, you can expand your annotation to `@:hscript({optional: true})` to disable the error message,
	 *     if your function can resolve properly without a script.
	 */
	var SCRIPT_NOT_FOUND:String = 'script_not_found';

	/**
	 * The scripted class does not import an `Assets` class to handle script loading.
	 * - When loading scripts, the target of the HScriptable interface will call `Assets.getText` to read the relevant script file.
	 * - You will need to import `openfl.util.Assets` on the HScriptable class, even if you don't otherwise use it.
	 */
	 var SCRIPT_NO_ASSET_HANDLER:String = 'script_no_asset_handler';

	/**
	 * You attempted to instantiate a scripted class that was not registered.
	 * - Make sure your script is in the assets folder.
	 * - Make sure that `useScriptedClasses` in your Polymod.init parameters is set to true.
	 * - If your scripted class extends another class, make sure that class exists as well.
	 */
	var SCRIPT_CLASS_NOT_REGISTERED:String = 'script_class_not_registered';

	/**
	 * You attempted to register a new scripted class with a name that is already in use.
	 * - Rename the scripted class to one that is unique and will not conflict with other scripted classes.
	 * - If you need to clear the class descriptor, call `PolymodScriptClass.clearClasses()`.
	 */
	var SCRIPT_CLASS_ALREADY_REGISTERED:String = 'script_class_already_registered';

	/**
	 * Your script file attempted to import a class that was already imported.
	 * - This is a warning and can be ignored.
	 * - Remove the duplicate import statement to remove the warning.
	 */
	var SCRIPT_CLASS_MODULE_ALREADY_IMPORTED:String = 'script_class_module_already_imported';

	/**
	 * Your script file attempted to import a class that could not be resolved.
	 * - Check the syntax of the import statement, and check for any typos.
	 */
	var SCRIPT_CLASS_MODULE_NOT_FOUND:String = 'script_class_module_not_found';

	/**
	 * Your script file attempted to import a blacklisted class.
	 * - This is a security measure to prevent malicious scripts from accessing sensitive classes.
	 * - Remove the import statement to remove the error.
	 */
	var SCRIPT_CLASS_MODULE_BLACKLISTED:String = 'script_class_module_blacklisted';

	/**
	 * One or more scripts are about to be parsed.
	 * - This is an info message. You can log it or ignore it if you like.
	 */
	var SCRIPT_PARSING:String = 'script_parsing';

	/**
	 * One or more scripts have been successfully parsed.
	 * - This is an info message. You can log it or ignore it if you like.
	 */
	var SCRIPT_PARSED:String = 'script_parsed';

	/**
	 * A script file could not be parsed for some unknown reason.
	 * - Check the syntax of the script file is proper Haxe.
	 * - Read the error message for more information.
	 */
	var SCRIPT_PARSE_ERROR:String = 'script_parse_error';

	/**
	 * While running a script, an exception was thrown.
	 * - Read the error message for more information.
	 * - Scripted functions will have the local variable `script_error` assigned, allowing you to handle the error gracefully.
	 */
	var SCRIPT_RUNTIME_EXCEPTION:String = 'script_runtime_exception';

	/**
	 * An installed mod is looking for another mod with a specific version, but the mod is not of that version.
	 * - The mod may be a modpack that includes that mod, or it may be a mod that has the other mod as a dependency.
	 * - Inform your users to install the proper mod version.
	 */
	var VERSION_CONFLICT_MOD:String = 'version_conflict_mod';

	/**
	 * The mod has an API version that conflicts with the application's API version.
	 * - This means that the mod needs to be updated, checking for compatibility issues with any changes to API version.
	 * - If you're getting this error even for patch versions, be sure to tweak the `POLYMOD_API_VERSION_MATCH` config option.
	 */
	var VERSION_CONFLICT_API:String = 'version_conflict_api';

	/**
	 * One of the version strings you provided to Polymod.init is invalid.
	 * - Make sure you're using a valid Semantic Version string.
	 */
	var PARAM_MOD_VERSION:String = 'param_mod_version';

	/**
	 * Indicates what asset framework Polymod has automatically detected for use.
	 * - This is an info message, and can either be logged or ignored.
	 */
	var FRAMEWORK_AUTODETECT:String = 'framework_autodetect';

	/**
	 * Indicates what asset framework Polymod has been manually configured to use.
	 * - This is an info message, and can either be logged or ignored.
	 */
	var FRAMEWORK_INIT:String = 'framework_init';

	/**
	 * You configured Polymod to use the `CUSTOM` asset framework, then didn't provide a value for `params.customBackend`.
	 * - Define a class which extends IBackend, and provide it to Polymod.
	 */
	var UNDEFINED_CUSTOM_BACKEND:String = 'undefined_custom_backend';

	/**
	 * Polymod could not create an instance of the class you provided for `params.customBackend`.
	 * - Check that the class extends IBackend, and can be instantiated properly.
	 */
	var FAILED_CREATE_BACKEND:String = 'failed_create_backend';

	/**
	 * You attempted to use a functionality of Polymod that is not fully implemented, or not implemented for the current framework.
	 * - Report the issue here, and describe your setup and provide the error message:
	 *   https://github.com/larsiusprime/polymod/issues
	 */
	var FUNCTIONALITY_NOT_IMPLEMENTED:String = 'functionality_not_implemented';

	/**
	 * You attempted to use a functionality of Polymod that has been deprecated and has/will be significantly reworked or altered.
	 * - New features and their associated documentation will be provided in future updates.
	 */
	var FUNCTIONALITY_DEPRECATED:String = 'functionality_deprecated';

	/**
	 * There was a warning or error attempting to perform a merge operation on a file.
	 * - Check the source and target files are correctly formatted and try again.
	 */
	var MERGE:String = 'merge_error';

	/**
	 * There was a warning or error attempting to perform an append operation on a file.
	 * - Check the source and target files are correctly formatted and try again.
	 */
	var APPEND:String = 'append_error';

	/**
	 * On the Lime and OpenFL platforms, if the base app defines multiple asset libraries,
	 * each asset library must be assigned a path to allow mods to override their files.
	 * - Provide a `frameworkParams.assetLibraryPaths` object to Polymod.init().
	 */
	var LIME_MISSING_ASSET_LIBRARY_INFO = 'lime_missing_asset_library_info';

	/**
	 * On the Lime and OpenFL platforms, if the base app defines multiple asset libraries,
	 * each asset library must be assigned a path to allow mods to override their files.
	 * - All libraries must have a value under `frameworkParams.assetLibraryPaths`.
	 * - Set the value to `./` to fetch assets from the root of the mod folder.
	 */
	var LIME_MISSING_ASSET_LIBRARY_REFERENCE = 'lime_missing_asset_library_reference';
}
