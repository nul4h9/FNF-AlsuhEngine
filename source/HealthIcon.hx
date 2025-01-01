package;

import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;

using StringTools;

class HealthIcon extends Sprite
{
	public static var DEFAULT_WIDTH:Int = 150;

	public var sprTracker:FlxSprite;

	public var isPlayer:Bool = false;
	public var character:String = '';

	public function new(char:String = 'bf', isPlayer:Bool = false, ?allowGPU:Bool = true):Void
	{
		super();

		this.isPlayer = isPlayer;

		changeIcon(char, allowGPU);
		scrollFactor.set();
	}

	public var iconOffsets:Array<Float> = [0, 0, 0];

	public function changeIcon(char:String = 'face', ?allowGPU:Bool = true):Void
	{
		if (character != char)
		{
			var name:String = 'icons/icon-' + char;

			if (Paths.fileExists('images/icons/' + char + '.png', IMAGE)) {
				name = 'icons/' + char;
			}

			if (Paths.fileExists('images/' + name + '.png', IMAGE))
			{
				var file:FlxGraphic = Paths.getImage(name, allowGPU);
				loadGraphic(file); // Load stupidly first for getting the file size

				var ken:Int = 3; // 3 - these alive, dead and win icons

				if (width < DEFAULT_WIDTH * ken) {
					ken = 2; // 2 - these alive and dead icons
				}

				loadGraphic(file, true, Math.floor(width / ken), Math.floor(height)); // Then load it fr

				var pos:Float = (width - DEFAULT_WIDTH) / ken;
				for (i in 0...ken) iconOffsets[i] = pos;

				animation.add(char, [for (i in 0...ken) i], 0, false, isPlayer);

				playAnim(char);
				antialiasing = ClientPrefs.globalAntialiasing && !char.endsWith('-pixel');

				character = char;
			}
			else {
				changeIcon();
			}
		}
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (sprTracker != null) {
			setPosition(sprTracker.x + sprTracker.width + 12, sprTracker.y - 30);
		}
	}

	public var usePsych:Bool = false; // for lua

	override function updateHitbox():Void
	{
		super.updateHitbox();

		if (usePsych)
		{
			offset.x = iconOffsets[0];
			offset.y = iconOffsets[1];
		}
	}
}