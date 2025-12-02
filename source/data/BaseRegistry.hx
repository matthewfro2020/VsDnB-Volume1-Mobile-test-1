package data;


import data.IRegistryEntry;
import flixel.FlxG;
import haxe.Constraints.Constructible;
import openfl.utils.Assets;
import util.VersionUtil;
import thx.semver.Version;
import thx.semver.VersionRule;

typedef EntryConstructor = String->Void;

@:generic
abstract class BaseRegistry<T:(IRegistryEntry<J> & Constructible<EntryConstructor>), J>
{
    /**
     * The id of the registry.
     * Used for debugging purposes.
     */
    final registryId:String;

    /**
     * The data folder that this registry belongs to.
     */
    final dataFolder:String;

    /**
     * The data file extension that entries from this registry use.
     */
    final fileType:String = 'json';

    /**
     * The version rule to use when parsing entry data.
     */
    final versionRule:VersionRule = '>=1.0.0';

    /**
     * A list of all the available entries in this registry.
     * This is where all of the data information is stored, and retrieved from.
     */
    var entries:Map<String, T> = new Map<String, T>();

    /**
     * A list of all of the scripted entries in this registry.
     * Used to help check whether an entry is scripted or not.
     */
    var scriptedEntries:Map<String, T> = new Map<String, T>();

    /**
     * Initalizes a new registry.
     * @param dataFolder The folder in which the data is in.
     * @param fileType The file extension that all of the data uses.
     */
    public function new(registryId:String, dataFolder:String, ?versionRule:VersionRule, fileType:String = '.json')
    {
        this.registryId = registryId;
        this.dataFolder = dataFolder;
        this.fileType = fileType;
        this.versionRule = versionRule;

        // Register the object in the console so it's easily accessible for debugging.
        FlxG.console.registerObject(registryId, this);
    }

    /**
     * Loads all available entries from this registry.
     */
    public function loadEntries():Void
    {
		clearEntries();

		var scriptedClasses:Array<String> = getScriptedClasses();

        // Create entries from all of the scripted classes.
		for (cls in scriptedClasses)
		{            
			var scriptedEntry:T = createScriptedEntry(cls);

			if (scriptedEntry != null)
			{
				entries.set(scriptedEntry.id, scriptedEntry);
				scriptedEntries.set(scriptedEntry.id, scriptedEntry);
			}
            else
            {
                log('Error while creating scripted entry with the class ${cls}');
            }
		}

        // Get a list of all of the entries from this registry's folder.
        var entryIds:Array<String> = DataAssets.listAssetsFromPath(dataFolder, fileType);

        // Filter the entries to make sure no base entries override any scripted entries, or any entries in the list.
        var unscriptedEntries:Array<String> = entryIds.filter((entry:String) -> 
        {
            return !entries.exists(entry) || entries.get(entry) == null;
        });

        // Populate list with the rest of the entries.
        for (entryId in unscriptedEntries)
        {
            var entry:T = createEntry(entryId);
            if (entry != null)
            {
                entries.set(entry.id, entry);
            }
            else
            {
                log('Error while creating entry with the id of ${entryId}');
            }
        }
        log('Parsed ${countEntries()} entries (${scriptedEntries.size()} scripted, ${unscriptedEntries.length} unscripted)');
    }

    /**
     * Completely clears all of the entries in this registry.
     */
    public function clearEntries():Void
    {
        for (entry in entries.keys())
        {
            entries.get(entry).destroy();
        }
        entries.clear();
    }
    
    /**
     * Retrieves an entry from it's ID.
     * @param id The id of the entry to get.
     */
    public function fetchEntry(id:String)
    {
        return entries.get(id);
    }

    public function listEntryIds():Array<String>
    {
        return entries.keys().array();
    }

    /**
     * Returns the number of entries that are in this registry.
     */
    public function countEntries():Int
    {
        return entries.size();
    }

    /**
     * Creates an entry from an id.
     * @param id The id of the entry to create.
     * @return A nullable entry.
     */
    function createEntry(id:String):Null<T>
    {
        return new T(id);
    }

    /**
     * Does the entry with the given id exist within this registry?
     * @param id The id of the entry.
     * @return Whether this entry exists, or not.
     */
    public function hasEntry(id:String):Bool
    {
        return entries.exists(id);
    }
    
    /**
     * Checks whether an entry from this registry is a scripted one.
     * @param id The id to check.
     * @return `true` if this entry is scripted, else `false`
     */
    function isScriptedEntry(id:String):Bool
    {
        return scriptedEntries.exists(id);
    }

    /**
     * Logs a message into the console for debugging.
     * @param message The message to log into the console.
     */
    function log(message:String)
    {
        trace('[$registryId] ${message}');
    }

    /**
     * Given a list of errors from `json2object` print out these errors, and alert the user.
     * @param errors A list of errors to print.
     */
    public function printErrors(errors:Array<json2object.Error>):Void
    {
        var errorString:String = json2object.ErrorUtils.convertErrorArray(errors);

        var errorMessage:String = 'Error while parsing JSON file';
        errorMessage += '\n';
        errorMessage += '\n';
        errorMessage += errorString;
        
        // Log in console.
        trace(errorString);
        
        // Display an alert when an error occurs.
        FlxG.stage.application.window.alert(errorMessage, '[${registryId}] A JSON parsing error occured');
    }
    
    /**
     * Retrieves the semantic version number of the entry from it's id.
     * @param id The id of the entry.
     * @return The entry's version.
     */
    public function fetchEntryVersion(id:String):Version
    {
        var entryContents:String = loadEntryFile(id).contents;
        return VersionUtil.getVersionFromJSON(entryContents);
    }

    /**
     * Loads the contents of the given entry id and stores it inside a json type definition.
     * @param id The id of the entry.
     * @return A `JsonFile`
     */
    function loadEntryFile(id:String):JsonFile
    {
        var fileName:String = Paths.json('${dataFolder}/$id');
        var contents:String = Assets.getText(fileName).trim();

        return {fileName: fileName, contents: contents};
    }

    // FUNCTIONS TO OVERRIDE//

    /**
     * Parses the data of an entry from its given id.
     * @param id The id of the entry.
     * @return The data for the entry.
     */
    public abstract function parseEntryData(id:String):J;
    
    /**
     * Parses the data of an entry with migration accounting for old versions of the data object.
     * @param id The id of the entry to parse.
     * @param version The version to validate and check for migration.
     * @return `J`
     */
    public function parseEntryDataWithMigration(id:String, ?version:Version):Null<J>
    {
        if (version == null || VersionUtil.validateVersion(version, versionRule))
        {
            return parseEntryData(id);
        }
        else
        {
            throw "Migration doesn't exist for version " + version; 
        }
    }

    /**
     * Creates a entry based off a given name of a scripted class.
     * @param clsName The scripted class name to create an entry off of.
     * @return A scripted entry.
     */
    abstract function createScriptedEntry(clsName:String):T;

    /**
     * Retrieves a list of all of the class names of every scripted entry.
     * @return Array<String>
     */
    abstract function getScriptedClasses():Array<String>;
}