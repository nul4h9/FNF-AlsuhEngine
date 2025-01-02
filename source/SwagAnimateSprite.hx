package;

import SwagFlxAnimate as FlxAnimate;

class SwagAnimateSprite extends FlxAnimate
{
	public var destroyed:Bool = false;
	public var animOffsets:Map<String, Array<Float>> = new Map<String, Array<Float>>();

	public function new(?x:Float = 0, ?y:Float = 0):Void
	{
		super(x, y);

		antialiasing = ClientPrefs.globalAntialiasing;
	}

	public function playAnim(name:String, forced:Bool = false, ?reverse:Bool = false, ?startFrame:Int = 0):Void
	{
		anim.play(name, forced, reverse, startFrame);
		
		var daOffset:Array<Float> = animOffsets.get(name);
		if (animOffsets.exists(name)) offset.set(daOffset[0], daOffset[1]);
	}

	public function addOffset(name:String, x:Float, y:Float):Void
	{
		animOffsets.set(name, [x, y]);
	}

	override function destroy():Void
	{
		destroyed = true;

		super.destroy();
	}
}