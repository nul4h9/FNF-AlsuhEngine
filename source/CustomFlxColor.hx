package;

import flixel.util.FlxColor;

class CustomFlxColor
{
	private static inline function fromFlxColor(flxColor:FlxColor):Int
	{
		return cast flxColor;
	}

	public static var TRANSPARENT(default, null):Int = fromFlxColor(FlxColor.TRANSPARENT);
	public static var BLACK(default, null):Int = fromFlxColor(FlxColor.BLACK);
	public static var WHITE(default, null):Int = fromFlxColor(FlxColor.WHITE);
	public static var GRAY(default, null):Int = fromFlxColor(FlxColor.GRAY);

	public static var GREEN(default, null):Int = fromFlxColor(FlxColor.GREEN);
	public static var LIME(default, null):Int = fromFlxColor(FlxColor.LIME);
	public static var YELLOW(default, null):Int = fromFlxColor(FlxColor.YELLOW);
	public static var ORANGE(default, null):Int = fromFlxColor(FlxColor.ORANGE);
	public static var RED(default, null):Int = fromFlxColor(FlxColor.RED);
	public static var PURPLE(default, null):Int = fromFlxColor(FlxColor.PURPLE);
	public static var BLUE(default, null):Int = fromFlxColor(FlxColor.BLUE);
	public static var BROWN(default, null):Int = fromFlxColor(FlxColor.BROWN);
	public static var PINK(default, null):Int = fromFlxColor(FlxColor.PINK);
	public static var MAGENTA(default, null):Int = fromFlxColor(FlxColor.MAGENTA);
	public static var CYAN(default, null):Int = fromFlxColor(FlxColor.CYAN);

	public static inline function fromInt(integer:Int):Int
	{
		return fromFlxColor(FlxColor.fromInt(integer));
	}

	public static inline function fromRGB(red:Int, green:Int, blue:Int, alpha:Int = 255):Int
	{
		return fromFlxColor(FlxColor.fromRGB(red, green, blue, alpha));
	}

	public static inline function fromRGBFloat(red:Int, green:Int, blue:Int, alpha:Int = 1):Int
	{	
		return fromFlxColor(FlxColor.fromRGBFloat(red, green, blue, alpha));
	}

	public static inline function fromCMYK(cyan:Float, magenta:Float, yellow:Float, black:Float, alpha:Float = 1):Int
	{
		return fromFlxColor(FlxColor.fromCMYK(cyan, magenta, yellow, black, alpha));
	}

	public static inline function fromHSB(hue:Float, sat:Float, brt:Float, alpha:Float = 1):Int
	{	
		return fromFlxColor(FlxColor.fromHSB(hue, sat, brt, alpha));
	}

	public static inline function fromHSL(hue:Float, sat:Float, light:Float, alpha:Float = 1):Int
	{
		return fromFlxColor(FlxColor.fromHSL(hue, sat, light, alpha));
	}

	public static inline function fromString(str:String):Null<Int>
	{
		return fromFlxColor(FlxColor.fromString(str));
	}
}