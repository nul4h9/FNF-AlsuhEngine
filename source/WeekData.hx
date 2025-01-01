package;

import haxe.Json;
import haxe.io.Path;

#if MODS_ALLOWED
import sys.FileSystem;
#end

import flixel.util.FlxColor;

using StringTools;

typedef WeekSong =
{
	var songID:String;
	var songName:String;
	var icon:String;
	var color:Array<Int>;
	var ?difficulties:Array<Array<String>>;
	var ?defaultDifficulty:String;
}

typedef WeekFile = // JSON variables
{
	var weekID:Null<String>;
	var weekName:String;

	var startUnlocked:Bool;
	var hiddenUntilUnlocked:Bool;

	var songs:Array<WeekSong>;

	var ?difficulties:Array<Array<String>>;
	var ?defaultDifficulty:String;

	var freeplayColor:Array<Int>;
	var weekCharacters:Array<String>;
	var weekBackground:String;
	var weekBefore:String;
	var storyName:String;
	var ?itemFile:Null<String>;

	var hideStoryMode:Bool;
	var hideFreeplay:Bool;
	var itemColor:Array<Int>;
}

class WeekData
{
	public static var weeksList:Array<String> = [];

	public static var weeksLoaded:Map<String, WeekData> = new Map<String, WeekData>();
	public static var weekCompleted:Map<String, Bool> = new Map<String, Bool>();

	public var folder:String = '';

	public var weekID:Null<String>;
	public var weekName:String;
	public var startUnlocked:Bool;
	public var hiddenUntilUnlocked:Bool;
	public var songs:Array<WeekSong>;
	public var difficulties:Array<Array<String>>;
	public var defaultDifficulty:String;
	public var freeplayColor:Array<Int>;
	public var weekCharacters:Array<String>;
	public var weekBackground:String;
	public var weekBefore:String;
	public var storyName:String;
	public var itemFile:Null<String>;
	public var hideStoryMode:Bool;
	public var hideFreeplay:Bool;
	public var itemColor:Array<Int>;

	public var fileName:String;

	public function new(weekFile:WeekFile, fileName:String):Void
	{
		weekID = weekFile.weekID;
		weekName = weekFile.weekName;
		startUnlocked = weekFile.startUnlocked;
		hiddenUntilUnlocked = weekFile.hiddenUntilUnlocked;

		songs = [];

		for (i in 0...weekFile.songs.length) {
			songs[i] = weekFile.songs[i];
		}

		difficulties = weekFile.difficulties;
		defaultDifficulty = weekFile.defaultDifficulty;
		freeplayColor = weekFile.freeplayColor;
		weekCharacters = weekFile.weekCharacters;
		weekBackground = weekFile.weekBackground;
		weekBefore = weekFile.weekBefore;
		itemFile = weekFile.itemFile;
		storyName = weekFile.storyName;
		hideStoryMode = weekFile.hideStoryMode;
		hideFreeplay = weekFile.hideFreeplay;
		itemColor = weekFile.itemColor;

		this.fileName = fileName;
	}

	public static function onLoadJson(weekFile:Dynamic, fileName:String):WeekFile
	{
		if (Reflect.hasField(weekFile, 'freeplayColor')) Reflect.deleteField(weekFile, 'freeplayColor');

		if (weekFile.weekID == null) {
			weekFile.weekID = fileName;
		}

		if (weekFile.itemFile == null) {
			weekFile.itemFile = fileName;
		}

		if (weekFile.itemColor == null || weekFile.itemColor.length < 2)
		{
			var col:FlxColor = MenuItem.DEFAULT_COLOR;
			weekFile.itemColor = [col.red, col.green, col.blue];
		}

		if (weekFile.difficulties != null && weekFile.difficulties.length > 0)
		{
			if (Std.isOfType(weekFile.difficulties, String))
			{
				var convertedDiffs:Array<Dynamic> = [];
				var diffStr:String = weekFile.difficulties;

				if (diffStr != null && diffStr.length > 0)
				{
					var diffs:Array<String> = diffStr.trim().split(',');
					var i:Int = diffs.length - 1;

					while (i > 0)
					{
						if (diffs[i] != null)
						{
							diffs[i] = diffs[i].trim();
							if (diffs[i].length < 1) diffs.remove(diffs[i]);
						}

						--i;
					}

					if (diffs.length > 0 && diffs[0].length > 0)
					{
						for (i in diffs)
						{
							convertedDiffs.push([
								Paths.formatToSongPath(i),
								CoolUtil.formatToName(i),
								CoolUtil.formatToDifficultyPath(i)
							]);
						}
					}
				}

				weekFile.difficulties = convertedDiffs.copy();
			}
		}

		var convertedSongs:Array<WeekSong> = [];
		var targetBool:Array<Bool> = [];

		for (i in 0...weekFile.songs.length)
		{
			targetBool[i] = false;

			var song:Dynamic = weekFile.songs[i];

			if (Std.isOfType(song, Array)) // convert from psych to null format
			{
				targetBool[i] = true;

				var diffs:Array<Array<String>> = weekFile.difficulties; // fuck you html5

				convertedSongs[i] = {
					songID: Paths.formatToSongPath(song[0]),
					songName: CoolUtil.formatToName(song[0]),
					icon: song[1],
					color: song[2],
					difficulties: diffs,
					defaultDifficulty: weekFile.defaultDifficulty
				};
			}
		}

		for (i in 0...targetBool.length)
		{
			if (targetBool[i] == true) {
				weekFile.songs[i] = convertedSongs[i];
			}
		}

		return cast weekFile;
	}

	public static final DEFAULT_WEEK:WeekFile = {
		itemColor: [MenuItem.DEFAULT_COLOR.red, MenuItem.DEFAULT_COLOR.green, MenuItem.DEFAULT_COLOR.blue],
		freeplayColor: [146, 113, 253],
		songs: [
			{
				songID: 'bopeebo',
				songName: 'Bopeebo',
				icon: 'dad',
				color: [146, 113, 253],
				difficulties: [],
				defaultDifficulty: null
			},
			{
				songID: 'fresh',
				songName: 'Fresh',
				icon: 'dad',
				color: [146, 113, 253],
				difficulties: [],
				defaultDifficulty: null
			},
			{
				songID: 'dad-battle',
				songName: 'Dad Battle',
				icon: 'dad',
				color: [146, 113, 253],
				difficulties: [],
				defaultDifficulty: null
			}
		],
		weekCharacters: ['dad', 'bf', 'gf'],
		weekBackground: 'stage',
		weekBefore: 'tutorial',
		itemFile: 'week1',
		storyName: 'Your New Week',
		weekName: 'Custom Week',
		weekID: 'custom-week',
		startUnlocked: true,
		hiddenUntilUnlocked: false,
		hideStoryMode: false,
		hideFreeplay: false,
		difficulties: [],
		defaultDifficulty: null
	};

	public static function createWeekFile():WeekFile
	{
		return DEFAULT_WEEK;
	}

	public static function reloadWeekFiles(isStoryMode:Null<Bool> = false):Void
	{
		weeksList = [];
		weeksLoaded.clear();

		#if MODS_ALLOWED
		var directories:Array<String> = [Paths.mods(), Paths.getPreloadPath()];
		var originalLength:Int = directories.length;

		for (mod in Paths.parseModList().enabled) {
			directories.push(Paths.mods(mod + '/'));
		}
		#else
		var directories:Array<String> = [Paths.getPreloadPath()];
		var originalLength:Int = directories.length;
		#end

		var sexList:Array<String> = CoolUtil.coolTextFile(Paths.getPreloadPath('weeks/weekList.txt'));

		for (i in 0...sexList.length)
		{
			for (j in 0...directories.length)
			{
				var fileToCheck:String = directories[j] + 'weeks/' + sexList[i] + '.json';

				if (!weeksLoaded.exists(sexList[i]))
				{
					var week:WeekFile = getWeekFile(fileToCheck, sexList[i]);

					if (week != null)
					{
						var weekFile:WeekData = new WeekData(week, sexList[i]);

						#if MODS_ALLOWED
						if (j >= originalLength) {
							weekFile.folder = directories[j].substring(Paths.mods().length, directories[j].length - 1);
						}
						#end

						if (weekFile != null && (isStoryMode == null || (isStoryMode && !weekFile.hideStoryMode) || (!isStoryMode && !weekFile.hideFreeplay)))
						{
							weeksLoaded.set(sexList[i], weekFile);
							weeksList.push(sexList[i]);
						}
					}
				}
			}
		}

		#if MODS_ALLOWED
		for (i in 0...directories.length)
		{
			var directory:String = directories[i] + 'weeks/';

			if (FileSystem.exists(directory))
			{
				var listOfWeeks:Array<String> = CoolUtil.coolTextFile(directory + 'weekList.txt');

				for (daWeek in listOfWeeks)
				{
					var path:String = directory + daWeek + '.json';

					if (FileSystem.exists(path)) {
						addWeek(daWeek, path, directories[i], i, originalLength, isStoryMode);
					}
				}

				for (file in FileSystem.readDirectory(directory))
				{
					var path:String = Path.join([directory, file]);

					if (!FileSystem.isDirectory(path) && file.endsWith('.json')) {
						addWeek(file.substr(0, file.length - 5), path, directories[i], i, originalLength, isStoryMode);
					}
				}
			}
		}
		#end
	}

	private static function addWeek(weekToCheck:String, path:String, directory:String, i:Int, originalLength:Int, isStoryMode:Null<Bool> = false):Void
	{
		if (!weeksLoaded.exists(weekToCheck))
		{
			var week:WeekFile = getWeekFile(path, weekToCheck);

			if (week != null)
			{
				var weekFile:WeekData = new WeekData(week, weekToCheck);

				if (i >= originalLength)
				{
					#if MODS_ALLOWED
					weekFile.folder = directory.substring(Paths.mods().length, directory.length - 1);
					#end
				}

				if (weekFile != null && (isStoryMode == null || (isStoryMode && !weekFile.hideStoryMode) || (!isStoryMode && !weekFile.hideFreeplay)))
				{
					weeksLoaded.set(weekToCheck, weekFile);
					weeksList.push(weekToCheck);
				}
			}
		}
	}

	private static function getWeekFile(path:String, fileName:String):WeekFile
	{
		var rawJson:String = null;

		if (Paths.fileExists(path, TEXT)) {
			rawJson = Paths.getTextFromFile(path);
		}

		if (rawJson != null && rawJson.length > 0)
		{
			var json:Dynamic = Json.parse(rawJson);
			return onLoadJson(json, fileName);
		}

		return null;
	}

	public static function weekIsLocked(name:String):Bool
	{
		var leWeek:WeekData = getFromFileName(name);
		return !leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!weekCompleted.exists(leWeek.weekBefore) || !weekCompleted.get(leWeek.weekBefore));
	}

	public static function getWeekFileName():String // To use on PlayState.hx or Highscore stuff
	{
		return weeksList[PlayState.storyWeek];
	}

	public static function getCurrentWeek():WeekData // Used on LoadingState, nothing really too relevant
	{
		return getFromFileName(getWeekFileName());
	}

	public static function getFromFileName(name:String):WeekData
	{
		return weeksLoaded.get(name);
	}

	public static function setDirectoryFromWeek(?data:WeekData = null):Void
	{
		Paths.currentModDirectory = '';

		if (data != null && data.folder != null && data.folder.length > 0) {
			Paths.currentModDirectory = data.folder;
		}
	}
}