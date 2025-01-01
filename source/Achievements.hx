package;

import haxe.io.Path;

#if MODS_ALLOWED
import sys.FileSystem;
#end

import haxe.Json;

import openfl.Lib;
import flixel.FlxG;
import flixel.util.FlxSave;
import openfl.errors.Error;
import flixel.util.FlxColor;

using StringTools;

#if ACHIEVEMENTS_ALLOWED
typedef Achievement =
{
	var name:String;
	var desc:String;
	var save_tag:String;
	var hidden:Bool;
	var ?misses:Int;
	var ?maxScore:Float;
	var ?folder:String;
	var ?song:String;
	var ?week_nomiss:String;
	var ?lua_code:String;
	var ?hx_code:String;
	var ?color:Array<Int>;
	var ?diff:String;
	var ?index:Int;
}

class Achievements
{
	public static var achievementList:Array<String> = [];
	public static var achievements:Map<String, Achievement> = [];

	public static var _save:FlxSave = null;
	public static var achievementsUnlocked:Array<String> = [];
	public static var variables:Map<String, Float> = [];

	private static var _firstLoad:Bool = true;

	public static function get(name:String):Achievement
	{
		return achievements.get(name);
	}

	public static function exists(name:String):Bool
	{
		return achievements.exists(name);
	}

	public static function isUnlocked(name:String):Bool
	{
		return achievementsUnlocked.contains(name);
	}

	public static function getFile(path:String):Achievement
	{
		var rawJson:String = null;

		if (Paths.fileExists(path, TEXT)) {
			rawJson = Paths.getTextFromFile(path);
		}

		if (rawJson != null && rawJson.length > 0) {
			return cast Json.parse(rawJson);
		}

		return null;
	}

	public static function dummy():Achievement
	{
		return {
			misses: 0,
			maxScore: 0,
			diff: 'hard',
			color: [255, 228, 0],
			name: 'Your Achievement',
			desc: 'Your description',
			save_tag: 'your-achievement',
			hidden: false,
			week_nomiss: 'your-week_nomiss',
			lua_code: '',
			hx_code: '',
			index: -1,
			song: 'your-song'
		};
	}

	public static function load():Void
	{
		achievements.clear();
		achievementList = [];

		#if MODS_ALLOWED
		var disabledMods:Array<String> = [];
		var modsListPath:String = 'modsList.txt';
		var directories:Array<String> = [Paths.mods(), Paths.getPreloadPath()];
		var originalLength:Int = directories.length;
	
		if (FileSystem.exists(modsListPath))
		{
			var stuff:Array<String> = CoolUtil.coolTextFile(modsListPath);
	
			for (i in 0...stuff.length)
			{
				var splitName:Array<String> = stuff[i].trim().split('|');
		
				if (splitName[1] == '0') { // Disable mod
					disabledMods.push(splitName[0]);
				}
				else // Sort mod loading order based on modsList.txt file
				{
					var path:String = Path.join([Paths.mods(), splitName[0]]);

					if (FileSystem.isDirectory(path) && !Paths.ignoreModFolders.contains(splitName[0]) && !disabledMods.contains(splitName[0]) && !directories.contains(path + '/')) {
						directories.push(path + '/');
					}
				}
			}
		}

		var modsDirectories:Array<String> = Paths.getModDirectories();
	
		for (folder in modsDirectories)
		{
			var pathThing:String = Path.join([Paths.mods(), folder]) + '/';
		
			if (!disabledMods.contains(folder) && !directories.contains(pathThing)) {
				directories.push(pathThing);
			}
		}
		#else
		var directories:Array<String> = [Paths.getPreloadPath()];
		var originalLength:Int = directories.length;
		#end
		var awardsLoaded:Array<String> = [];
		var sexList:Array<String> = CoolUtil.coolTextFile(Paths.getPreloadPath('achievements/achievementList.txt'));

		for (i in 0...sexList.length) 
		{
			for (j in 0...directories.length)
			{
				var fileToCheck:String = directories[j] + 'achievements/' + sexList[i] + '.json';
			
				if (!awardsLoaded.contains(sexList[i]))
				{
					var award:Achievement = getFile(fileToCheck);

					if (award != null)
					{
						if (award.index < 0) {
							achievementList.push(award.save_tag);
						}
						else {
							achievementList.insert(award.index, award.save_tag);
						}

						achievements.set(award.save_tag, award);
						awardsLoaded.push(sexList[i]);
					}
				}
			}
		}

		#if MODS_ALLOWED
		for (i in 0...directories.length) 
		{
			var directory:String = directories[i] + 'achievements/';

			if (FileSystem.exists(directory))
			{
				var listOfAwards:Array<String> = CoolUtil.coolTextFile(directory + 'achievementList.txt');

				if (listOfAwards != null && listOfAwards.length > 0)
				{
					for (daAward in listOfAwards)
					{
						var path:String = directory + daAward + '.json';

						if (FileSystem.exists(path)) {
							addAchievement(awardsLoaded, daAward, path, directories[i], i, originalLength);
						}
					}
				}

				for (file in FileSystem.readDirectory(directory))
				{
					var path:String = Path.join([directory, file]);

					if (!FileSystem.isDirectory(path) && file.endsWith('.json')) {
						addAchievement(awardsLoaded, file.substr(0, file.length - 5), path, directories[i], i, originalLength);
					}
				}
			}
		}
		#end

		if (!_firstLoad) return;

		if (_save == null) _save = new FlxSave();
		_save.bind('achievements_v2', CoolUtil.getSavePath());

		if (_save != null && _save.data != null)
		{
			if (_save.data.achievementsUnlocked != null) {
				achievementsUnlocked = _save.data.achievementsUnlocked;
			}

			var savedMap:Map<String, Float> = cast _save.data.achievementsVariables;

			if (savedMap != null)
			{
				for (key => value in savedMap) {
					variables.set(key, value);
				}
			}

			_firstLoad = false;
		}
	}

	private static function addAchievement(awardsLoaded:Array<String>, awardToCheck:String, path:String, directory:String, i:Int, originalLength:Int):Void
	{
		if (!awardsLoaded.contains(awardToCheck))
		{
			var award:Achievement = getFile(path);

			if (award != null)
			{
				if (i >= originalLength)
				{
					#if MODS_ALLOWED
					award.folder = directory.substring(Paths.mods().length, directory.length - 1);
					#end
				}

				if (award.index < 0) {
					achievementList.push(award.save_tag);
				}
				else {
					achievementList.insert(award.index, award.save_tag);
				}

				achievements.set(award.save_tag, award);
				awardsLoaded.push(awardToCheck);
			}
		}
	}

	public static function save():Void
	{
		_save.data.achievementsUnlocked = achievementsUnlocked;
		_save.data.achievementsVariables = variables;
	}

	public static function getScore(name:String):Float
	{
		return _scoreFunc(name, 0);
	}

	public static function setScore(name:String, value:Float, saveIfNotUnlocked:Bool = true):Float
	{
		return _scoreFunc(name, 1, value, saveIfNotUnlocked);
	}

	public static function addScore(name:String, value:Float = 1, saveIfNotUnlocked:Bool = true):Float
	{
		return _scoreFunc(name, 2, value, saveIfNotUnlocked);
	}

	private static function _scoreFunc(name:String, mode:Int = 0, addOrSet:Float = 1, saveIfNotUnlocked:Bool = true):Float // mode 0 = get, 1 = set, 2 = add
	{
		if (!variables.exists(name)) {
			variables.set(name, 0);
		}

		if (exists(name))
		{
			var achievement:Achievement = get(name);
			if (achievement.maxScore == null || achievement.maxScore < 1) throw new Error('Achievement has score disabled or is incorrectly configured: $name');

			if (achievementsUnlocked.contains(name)) return achievement.maxScore;

			var val:Float = addOrSet;

			switch (mode)
			{
				case 0: return variables.get(name); // get
				case 2: val += variables.get(name); // add
			}

			if (val >= achievement.maxScore)
			{
				unlock(name);
				val = achievement.maxScore;
			}

			variables.set(name, val);

			save();
			if (saveIfNotUnlocked || val >= achievement.maxScore) _save.flush();

			return val;
		}

		return -1;
	}

	private static var _lastUnlock:Int = -999;

	public static function unlock(name:String, playSound:Bool = true, autoStartPopup:Bool = true):String
	{
		if (!exists(name))
		{
			throw new Error('Achievement "' + name + '" does not exists!');
			return null;
		}

		if (isUnlocked(name)) return null;

		Debug.logInfo('Completed achievement "' + name +'"');
		achievementsUnlocked.push(name);

		var time:Int = Lib.getTimer();

		if (Math.abs(time - _lastUnlock) >= 100 && playSound) // If last unlocked happened in less than 100 ms (0.1s) ago, then don't play sound
		{
			FlxG.sound.play(Paths.getSound('confirmMenu'), 0.5);
			_lastUnlock = time;
		}

		save();
		_save.flush();

		if (autoStartPopup) startPopup(name);
		return name;
	}

	@:allow(AchievementPopup)
	private static var _popups:Array<AchievementPopup> = [];
	public static var showingPopups(get, never):Bool;

	public static function get_showingPopups():Bool
	{
		return _popups.length > 0;
	}

	public static function startPopup(achieve:String, endFunc:Void->Void = null):Void
	{
		for (popup in _popups)
		{
			if (popup == null) continue;
			popup.intendedY += 150;
		}

		var newPop:AchievementPopup = new AchievementPopup(get(achieve), endFunc);
		_popups.push(newPop);
	}

	#if LUA_ALLOWED
	public static function implementForLua(funk:FunkinLua):Void
	{
		funk.set("getAchievementScore", function(name:String):Float
		{
			if (!exists(name))
			{
				PlayState.debugTrace('getAchievementScore: Couldnt find achievement: $name', false, 'error', FlxColor.RED);
				return -1;
			}

			return getScore(name);
		});

		funk.set("setAchievementScore", function(name:String, value:Float = 1, saveIfNotUnlocked:Bool = true):Float
		{
			if (!exists(name))
			{
				PlayState.debugTrace('setAchievementScore: Couldnt find achievement: $name', false, 'error', FlxColor.RED);
				return -1;
			}

			return setScore(name, value, saveIfNotUnlocked);
		});

		funk.set("addAchievementScore", function(name:String, value:Float = 1, saveIfNotUnlocked:Bool = true):Float
		{
			if (!exists(name))
			{
				PlayState.debugTrace('addAchievementScore: Couldnt find achievement: $name', false, 'error', FlxColor.RED);
				return -1;
			}

			return addScore(name, value, saveIfNotUnlocked);
		});

		funk.set("unlockAchievement", function(name:String):String
		{
			if (!exists(name))
			{
				PlayState.debugTrace('unlockAchievement: Couldnt find achievement: $name', false, 'error', FlxColor.RED);
				return null;
			}

			return unlock(name);
		});

		funk.set("isAchievementUnlocked", function(name:String):Null<Bool>
		{
			if (!exists(name))
			{
				PlayState.debugTrace('isAchievementUnlocked: Couldnt find achievement: $name', false, 'error', FlxColor.RED);
				return null;
			}

			return isUnlocked(name);
		});

		funk.set("achievementExists", exists);
	}
	#end
}
#end