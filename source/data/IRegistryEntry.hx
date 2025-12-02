package data;

/**
 * An interfere used to define the necessary functions and properties for a registry entry.
 */
interface IRegistryEntry<T>
{
    /**
     * The id of the entry.
     */
    final id:String;

    /**
     * Retrieves the data for this entry.
     * @param id The id of the entry.
     * @return The data object for this entry.
     */
    function fetchData(id:String):T;

    /**
     * Destroys this data object.
     */
    function destroy():Void;

    /**
     * Returns a string representation of this entry.
     * @return String
     */
    function toString():String;
}