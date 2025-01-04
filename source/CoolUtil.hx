package;

import flixel.FlxG;
import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxSave;
import flixel.util.FlxColor;
import lime.system.Clipboard;

using StringTools;

class CoolUtil
{
	public static var defaultDifficulties(default, never):Array<Array<String>> = // [Difficulty id, Difficulty custom name, Chart file suffix]
	[
		['easy',	'Easy',		'-easy'],
		['normal',	'Normal',	''],
		['hard',	'Hard',		'-hard'],
	];

	public static var difficultyStuff:Array<Array<String>> = [];
	public static var defaultDifficulty(default, never):String = 'Normal';

	public static function resetDifficulties():Void
	{
		return copyDifficultiesFrom(defaultDifficulties);
	}

	public static function copyDifficultiesFrom(diffs:Array<Array<String>>):Void
	{
		difficultyStuff = diffs.copy();
	}

	public static function formatToDifficultyPath(diff:String = null):String
	{
		if (diff == null || diff.length < 1) diff = defaultDifficulty;
		var fileSuffix:String = diff;

		if (fileSuffix != defaultDifficulty) {
			fileSuffix = '-' + fileSuffix;
		}
		else {
			fileSuffix = '';
		}

		return Paths.formatToSongPath(fileSuffix);
	}

	public static function difficultyString(last:Bool = false):String
	{
		return difficultyStuff[last ? PlayState.lastDifficulty : PlayState.storyDifficulty][1].toUpperCase();
	}

	public static function getDifficultyIndex(diff:String):Int
	{
		for (i in 0...difficultyStuff.length)
		{
			if (diff == difficultyStuff[i][0]) {
				return i;
			}
		}

		return -1;
	}

	public static function difficultyExists(diff:String):Bool
	{
		for (i in difficultyStuff) {
			if (diff == i[0]) return true;
		}

		return false;
	}

	public static function boundTo(value:Float, ?min:Null<Float> = null, ?max:Null<Float> = null):Float
	{
		var maxBound:Float = max != null ? Math.min(max, value) : value;
		return min != null ? Math.max(min, maxBound) : maxBound;
	}

	public static function floorDecimal(value:Float, decimals:Int):Float
	{
		if (decimals < 1) return Math.floor(value);

		var tempMult:Float = 1;

		for (i in 0...decimals) {
			tempMult *= 10;
		}

		return Math.floor(value * tempMult) / tempMult;
	}

	public static function quantize(value:Float, snap:Float):Float
	{
		return Math.round(value * snap) / snap;
	}

	public static function formatToName(name:String):String
	{
		return [for (i in [for (i in [for (i in name.split('_')) capitalize(i)].join('-').split('-')) capitalize(i)].join(' ').split(' ')) capitalize(i)].join(' ');
	}

	public static function formatSong(song:String, diff:Int):String
	{
		return Paths.formatToSongPath(song) + CoolUtil.difficultyStuff[diff][2];
	}

	public static function capitalize(text:String):String
	{
		return text.charAt(0).toUpperCase() + text.substr(1).toLowerCase();
	}

	public static function clipboardAdd(prefix:String = ''):String
	{
		if (prefix.toLowerCase().endsWith('v')) { // probably copy paste attempt
			prefix = prefix.substring(0, prefix.length - 1);
		}

		return prefix + Clipboard.text.replace('\n', '');
	}

	public static function dominantColor(sprite:FlxSprite):FlxColor
	{
		final countByColor:Map<Int, Int> = [];

		for (col in 0...sprite.frameWidth)
		{
			for (row in 0...sprite.frameHeight)
			{
				var colorOfThisPixel:FlxColor = sprite.pixels.getPixel32(col, row);

				if (colorOfThisPixel.alphaFloat > 0.05)
				{
					colorOfThisPixel = FlxColor.fromRGB(colorOfThisPixel.red, colorOfThisPixel.green, colorOfThisPixel.blue, 255);
					var count:Int = countByColor.exists(colorOfThisPixel) ? countByColor.get(colorOfThisPixel) : 0;
					countByColor.set(colorOfThisPixel, count + 1);
				}
			}
		}

		var maxCount:Int = 0;
		var maxKey:Int = 0; // after the loop this will store the max color

		countByColor.set(FlxColor.BLACK, 0);

		for (key => count in countByColor)
		{
			if (count >= maxCount)
			{
				maxCount = count;
				maxKey = key;
			}
		}

		countByColor.clear();
		return FlxColor.fromInt(maxKey);
	}

	public static function colorFromString(str:String):FlxColor
	{
		var hideChars:EReg = ~/[\t\n\r]/;

		var color:String = hideChars.split(str).join('').trim();
		if (color.startsWith('0x')) color = color.substring(color.length - 6);

		var colorNum:Null<FlxColor> = FlxColor.fromString(color);
		if (colorNum == null) colorNum = FlxColor.fromString('#$color');

		return colorNum != null ? colorNum : FlxColor.WHITE;
	}

	public static function coolTextFile(path:String, ?ignoreMods:Bool = false):Array<String>
	{
		if (Paths.fileExists(path, TEXT, ignoreMods))
		{
			var text:String = Paths.getTextFromFile(path, ignoreMods);
			return listFromString(text);
		}

		return [];
	}

	public static function listFromString(string:String):Array<String>
	{
		if (string != null && string.trim().length > 0) {
			return [for (i in string.trim().split('\n')) i.trim()];
		}

		return [];
	}

	public static function numberArray(max:Int, ?min:Int = 0):Array<Int>
	{
		return [for (i in min...max) i];
	}

	public static function sortByID(i:Int, basic1:FlxBasic, basic2:FlxBasic):Int
	{
		return basic1.ID > basic2.ID ? -i : basic2.ID > basic1.ID ? i : 0;
	}

	public static function browserLoad(site:String):Void
	{
		#if linux
		Sys.command('/usr/bin/xdg-open', [site]);
		#else
		return FlxG.openURL(site);
		#end
	}

	public static function getBuildTarget():String // clone functions
	{
		#if windows
		return 'windows';
		#elseif linux
		return 'linux';
		#elseif mac
		return 'mac';
		#elseif hl
		return 'hashlink';
		#elseif (html5 || emscripten)
		return 'browser';
		#elseif webos
		return 'webos';
		#elseif android
		return 'android';
		#elseif ios
		return 'ios';
		#elseif iphonesim
		return 'iphonesimulator';
		#elseif switch
		return 'switch';
		#elseif neko
		return 'neko';
		#else
		return 'unknown';
		#end
	}

	public static function openFolder(folder:String, absolute:Bool = false):Void
	{
		#if sys
		if (!absolute) folder =  Sys.getCwd() + '$folder';

		folder = folder.replace('/', '\\');
		if (folder.endsWith('/')) folder.substr(0, folder.length - 1);

		#if linux
		var command:String = '/usr/bin/xdg-open';
		#else
		var command:String = 'explorer.exe';
		#end

		Sys.command(command, [folder]);
		Debug.logInfo('$command $folder');
		#else
		Debug.logError("Platform is not supported for CoolUtil.openFolder");
		#end
	}

	public static function getSavePath():String
	{
		final company:String = FlxG.stage.application.meta.get('company');
		return @:privateAccess '${company}/${FlxSave.validate(FlxG.stage.application.meta.get('file'))}';
	}

	public static function setTextBorderFromString(text:FlxText, border:String):Void
	{
		switch (border.toLowerCase().trim())
		{
			case 'shadow':
				text.borderStyle = SHADOW;
			case 'outline':
				text.borderStyle = OUTLINE;
			case 'outline_fast', 'outlinefast':
				text.borderStyle = OUTLINE_FAST;
			default:
				text.borderStyle = NONE;
		}
	}
}