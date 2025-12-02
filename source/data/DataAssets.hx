package data;

import openfl.utils.Assets;

class DataAssets
{
    /**
     * Retrieves a list of data files from a data folder.
     * @param path The name of the data folder to retrieve the assets from.
     * @param suffix The suffix, or the file extension of the data.
     * @return A list of all of the data files from the given folder.
     */
    public static function listAssetsFromPath(path:String, suffix:String = '.json'):Array<String>
    {
        var dataFolder:String = Paths.data(path) + '/';

        return Assets.list(TEXT).filter((s:String) ->
        {
            // Filter out data files to only have the necessary conditions.
            return s.startsWith(dataFolder) && s.endsWith(suffix);
        }).map((dataPath:String) -> 
        {
            var noSuffix:String = dataPath.substring(0, dataPath.length - suffix.length);            
            var pathNoPrefix:String = noSuffix.substring(dataFolder.length);

            var splitNoPrefixPath = pathNoPrefix.split('/');
            return splitNoPrefixPath[splitNoPrefixPath.length - 1];
        });
    }
}