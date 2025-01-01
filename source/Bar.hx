package;

import flixel.FlxSprite;
import flixel.math.FlxRect;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.group.FlxSpriteGroup;
import flixel.util.helpers.FlxBounds;

using StringTools;

class Bar extends FlxSpriteGroup
{
	public var leftBar:FlxSprite;
	public var rightBar:FlxSprite;

	public var bg:FlxSprite;

	public var valueFunction:Void->Float = function():Float return 0;

	public var percent(default, set):Float = 0;
	public var bounds:FlxBounds<Float> = new FlxBounds<Float>(0, 1);

	public var leftToRight(default, set):Bool = true;
	public var barCenter(default, null):Float = 0;

	// you might need to change this if you want to use a custom bar
	public var barWidth(default, set):Int = 1;
	public var barHeight(default, set):Int = 1;
	public var barOffset:FlxPoint = FlxPoint.get(3, 3);

	public function new(x:Float, y:Float, image:String = 'ui/healthBar', ?valueFunction:Void->Float, minBound:Float = 0, maxBound:Float = 1):Void
	{
		super(x, y);

		if (valueFunction != null) this.valueFunction = valueFunction;
		setBounds(minBound, maxBound);

		bg = new FlxSprite();
		bg.loadGraphic(Paths.getImage(image));
		bg.antialiasing = ClientPrefs.globalAntialiasing;

		barWidth = Std.int(bg.width - 6);
		barHeight = Std.int(bg.height - 6);

		leftBar = new FlxSprite();
		leftBar.makeGraphic(Std.int(bg.width), Std.int(bg.height), FlxColor.WHITE);
		leftBar.antialiasing = antialiasing = ClientPrefs.globalAntialiasing;
		add(leftBar);

		rightBar = new FlxSprite();
		rightBar.makeGraphic(Std.int(bg.width), Std.int(bg.height), FlxColor.WHITE);
		rightBar.color = FlxColor.BLACK;
		rightBar.antialiasing = ClientPrefs.globalAntialiasing;
		add(rightBar);

		add(bg);

		regenerateClips();
	}

	public var enabled:Bool = true;

	override function update(elapsed:Float):Void
	{
		if (enabled)
		{
			if (valueFunction != null)
			{
				var value:Null<Float> = FlxMath.remapToRange(CoolUtil.boundTo(valueFunction(), bounds.min, bounds.max), bounds.min, bounds.max, 0, 100);
				percent = (value != null ? value : 0);
			}
			else percent = 0;
		}

		super.update(elapsed);
	}

	override public function destroy():Void
	{
		bounds = null;
		barOffset = FlxDestroyUtil.put(barOffset);

		if (leftBar.clipRect != null) leftBar.clipRect = FlxDestroyUtil.put(leftBar.clipRect);
		if (rightBar.clipRect != null) rightBar.clipRect = FlxDestroyUtil.put(rightBar.clipRect);

		super.destroy();
	}

	public function setBounds(min:Float, max:Float):FlxBounds<Float>
	{
		return bounds.set(min, max);
	}

	public function setColors(?left:FlxColor, ?right:FlxColor):Void
	{
		leftBar.color = left;
		rightBar.color = right;
	}

	public function updateBar():Void
	{
		if (leftBar == null || rightBar == null) return;

		leftBar.setPosition(bg.x, bg.y);
		rightBar.setPosition(bg.x, bg.y);

		final leftSize:Float = FlxMath.lerp(0, barWidth, (leftToRight ? percent / 100 : 1 - percent / 100));

		leftBar.clipRect.width = leftSize;
		leftBar.clipRect.height = barHeight;
		leftBar.clipRect.x = barOffset.x;
		leftBar.clipRect.y = barOffset.y;

		rightBar.clipRect.width = barWidth - leftSize;
		rightBar.clipRect.height = barHeight;
		rightBar.clipRect.x = barOffset.x + leftSize;
		rightBar.clipRect.y = barOffset.y;

		barCenter = leftBar.x + leftSize + barOffset.x;

		leftBar.clipRect = leftBar.clipRect;
		rightBar.clipRect = rightBar.clipRect;
	}

	public function regenerateClips():Void
	{
		if (leftBar == null && rightBar == null) return;

		final width:Float = Std.int(bg.width);
		final height:Float = Std.int(bg.height);

		if (leftBar != null)
		{
			leftBar.setGraphicSize(width, height);
			leftBar.updateHitbox();

			if (leftBar.clipRect == null)
				leftBar.clipRect = FlxRect.get(0, 0, width, height);
			else
				leftBar.clipRect.set(0, 0, width, height);
		}

		if (rightBar != null)
		{
			rightBar.setGraphicSize(width, height);
			rightBar.updateHitbox();

			if (rightBar.clipRect == null)
				rightBar.clipRect = FlxRect.get(0, 0, width, height);
			else
				rightBar.clipRect.set(0, 0, width, height);
		}

		updateBar();
	}

	private function set_percent(value:Float):Float
	{
		final doUpdate:Bool = (value != percent);
		percent = value;

		if (doUpdate) updateBar();
		return value;
	}

	private function set_leftToRight(value:Bool):Bool
	{
		leftToRight = value;
		updateBar();

		return value;
	}

	private function set_barWidth(value:Int):Int
	{
		barWidth = value;
		regenerateClips();

		return value;
	}

	private function set_barHeight(value:Int):Int
	{
		barHeight = value;
		regenerateClips();

		return value;
	}

	override function set_x(value:Float):Float
	{
		final prevX:Float = x;
		super.set_x(value);

		barCenter += value - prevX;
		return value;
	}

	override function set_antialiasing(value:Bool):Bool
	{
		for (member in members) member.antialiasing = value;
		return antialiasing = value;
	}
}