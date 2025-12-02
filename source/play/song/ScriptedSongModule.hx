package play.song;

/**
 * A `SongModule` that's attached through a script.
 * Create a script and extend by `SongModule` to use.
 */
@:hscriptClass
class ScriptedSongModule extends play.song.SongModule implements polymod.hscript.HScriptedClass {}