package util.tools;

/**
 * A utility extension to help provide functions relating to `Map`
 */
class MapTools
{
	/**
	 * Return the quantity of keys in the map.
	 */
	public static function size<K, T>(map:Null<Map<K, T>>):Int
	{
		if (map == null)
			return 0;
		return map.keys().array().length;
	}

	/**
	 * Return a list of values from the map, as an array.
	 */
	public static function values<K, T>(map:Null<Map<K, T>>):Array<T>
	{
		if (map == null)
			return [];

		return [for (i in map.iterator()) i];
	}
}