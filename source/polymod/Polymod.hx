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
