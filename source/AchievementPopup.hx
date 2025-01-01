package;

#if ACHIEVEMENTS_ALLOWED
import Achievements;
#end

import openfl.Lib;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import openfl.geom.Matrix;
import flixel.text.FlxText;
import openfl.events.Event;
import openfl.errors.Error;
import flixel.util.FlxColor;
import openfl.display.Sprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flash.display.BitmapData;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxSpriteGroup;

using StringTools;

#if ACHIEVEMENTS_ALLOWED
class AchievementPopup extends Sprite
{
	public var onFinish:Void->Void = null;

	var alphaTween:FlxTween;
	var lastScale:Float = 1;

	public function new(achievement:Achievement, onFinish:Void->Void):Void
	{
		if (achievement == null) throw new Error('Achievement is null');

		super();

		var col:FlxColor = FlxColor.fromRGB(achievement.color[0], achievement.color[1], achievement.color[2]);
		col.redFloat -= col.redFloat / 1.25;
		col.greenFloat -= col.greenFloat / 1.25;
		col.blueFloat -= col.blueFloat / 1.25;

		graphics.beginFill(col);
		graphics.drawRoundRect(0, 0, 420, 130, 16, 16);

		var graphic:FlxGraphic = null;
		var hasAntialias:Bool = ClientPrefs.globalAntialiasing;
		var image:String = 'achievements/${achievement.save_tag}';

		#if MODS_ALLOWED
		var lastMod:String = Paths.currentModDirectory;
		Paths.currentModDirectory = achievement.folder != null && achievement.folder.trim().length > 0 ? achievement.folder : '';
		#end

		if (Paths.fileExists('images/$image-pixel.png', IMAGE))
		{
			graphic = Paths.getImage('$image-pixel', false);
			hasAntialias = false;
		}
		else if (Paths.fileExists('images/$image.png', IMAGE)) {
			graphic = Paths.getImage(image, false);
		}

		#if MODS_ALLOWED
		Paths.currentModDirectory = lastMod;
		#end

		if (graphic == null) graphic = Paths.getImage('ui/unknownMod', false);

		var sizeX:Float = 100;
		var sizeY:Float = 100;

		var imgX:Float = 15;
		var imgY:Float = 15;
		var image:BitmapData = graphic.bitmap;

		graphics.beginBitmapFill(image, new Matrix(sizeX / image.width, 0, 0, sizeY / image.height, imgX, imgY), false, hasAntialias);
		graphics.drawRect(imgX, imgY, sizeX + 10, sizeY + 10);

		var name:String = 'Unknown';
		var desc:String = 'Description not found';

		if (achievement.name != null) name = achievement.name;
		if (achievement.desc != null)  desc = achievement.desc;

		var textX:Float = sizeX + imgX + 15;
		var textY:Float = imgY + 20;

		var text:FlxText = new FlxText(0, 0, 270, 'TEST!!!', 16);
		text.setFormat(Paths.getFont("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
		drawTextAt(text, name, textX, textY);
		drawTextAt(text, desc, textX, textY + 30);
		graphics.endFill();

		text.graphic.bitmap.dispose();
		text.graphic.bitmap.disposeImage();
		text.destroy();

		FlxG.stage.addEventListener(Event.RESIZE, onResize); // other stuff
		addEventListener(Event.ENTER_FRAME, update);

		FlxG.game.addChild(this); // Don't add it below mouse, or it will disappear once the game changes states

		lastScale = (FlxG.stage.stageHeight / FlxG.height); // fix scale

		this.x = 20 * lastScale;
		this.y = -130 * lastScale;

		this.scaleX = lastScale;
		this.scaleY = lastScale;

		intendedY = 20;
	}

	var bitmaps:Array<BitmapData> = [];

	function drawTextAt(text:FlxText, str:String, textX:Float, textY:Float):Void
	{
		text.text = str;
		text.updateHitbox();

		var clonedBitmap:BitmapData = text.graphic.bitmap.clone();
		bitmaps.push(clonedBitmap);

		graphics.beginBitmapFill(clonedBitmap, new Matrix(1, 0, 0, 1, textX, textY), false, false);
		graphics.drawRect(textX, textY, text.width + textX, text.height + textY);
	}
	
	var lerpTime:Float = 0;
	var countedTime:Float = 0;
	var timePassed:Float = -1;

	public var intendedY:Float = 0;

	function update(e:Event):Void
	{
		if (timePassed < 0) 
		{
			timePassed = Lib.getTimer();
			return;
		}

		var time:Float = Lib.getTimer();

		var elapsed:Float = (time - timePassed) / 1000;
		timePassed = time;

		if (elapsed >= 0.5) return; // most likely passed through a loading
		countedTime += elapsed;

		if (countedTime < 3)
		{
			lerpTime = Math.min(1, lerpTime + elapsed);
			y = ((FlxEase.elasticOut(lerpTime) * (intendedY + 130)) - 130) * lastScale;
		}
		else
		{
			y -= FlxG.height * 2 * elapsed * lastScale;
			if (y <= -130 * lastScale) destroy();
		}
	}

	private function onResize(e:Event):Void
	{
		var mult:Float = (FlxG.stage.stageHeight / FlxG.height);

		scaleX = mult;
		scaleY = mult;

		x = (mult / lastScale) * x;
		y = (mult / lastScale) * y;

		lastScale = mult;
	}

	public function destroy():Void
	{
		Achievements._popups.remove(this);

		if (FlxG.game.contains(this)) {
			FlxG.game.removeChild(this);
		}

		FlxG.stage.removeEventListener(Event.RESIZE, onResize);

		removeEventListener(Event.ENTER_FRAME, update);
		deleteClonedBitmaps();
	}

	function deleteClonedBitmaps():Void
	{
		for (clonedBitmap in bitmaps)
		{
			if (clonedBitmap != null)
			{
				clonedBitmap.dispose();
				clonedBitmap.disposeImage();
			}
		}

		bitmaps = null;
	}
}
#end