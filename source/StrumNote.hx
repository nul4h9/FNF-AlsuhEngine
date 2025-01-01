package;

import shaders.RGBPalette;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.graphics.FlxGraphic;

class StrumNote extends FlxSprite
{
	public var rgbShader:RGBShaderReference;
	public var resetAnim:Float = 0;

	public var noteData:Int = 0;

	public var direction:Float = 90;//plan on doing scroll directions soon -bb
	public var downScroll:Bool = false;//plan on doing scroll directions soon -bb
	public var sustainReduce:Bool = true;

	public var player:Int = -1;

	public var texture(default, set):String = null;

	private function set_texture(value:String):String
	{
		if (texture != value)
		{
			texture = value;
			reloadNote();
		}

		return value;
	}

	public var useRGBShader:Bool = true;

	public function new(x:Float, y:Float, leData:Int, player:Int):Void
	{
		animation = new SwagAnimationController(this);

		rgbShader = new RGBShaderReference(this, Note.initializeGlobalRGBShader(leData));
		rgbShader.enabled = false;

		if (PlayState.SONG != null && PlayState.SONG.disableNoteRGB) useRGBShader = false;

		var arr:Array<FlxColor> = ClientPrefs.arrowRGB[leData];
		if (PlayState.isPixelStage) arr = ClientPrefs.arrowRGBPixel[leData];

		if (leData <= arr.length)
		{
			@:bypassAccessor
			{
				rgbShader.r = arr[0];
				rgbShader.g = arr[1];
				rgbShader.b = arr[2];
			}
		}

		noteData = leData;

		this.player = player;
		noteData = leData;

		super(x, y);

		var skin:String = null;

		if (PlayState.SONG != null && PlayState.SONG.arrowSkin != null && PlayState.SONG.arrowSkin.length > 1) {
			skin = PlayState.SONG.arrowSkin;
		}
		else {
			skin = Note.defaultNoteSkin;
		}

		var customSkin:String = skin + Note.getNoteSkinPostfix();
		if (Paths.fileExists('images/$customSkin.png', IMAGE)) skin = customSkin;

		texture = skin; // Load texture and anims
		scrollFactor.set();
	}

	public function reloadNote():Void
	{
		var lastAnim:String = null;
		if (animation.curAnim != null) lastAnim = animation.curAnim.name;

		if (PlayState.isPixelStage)
		{
			var path:String = 'noteSkins/' + texture + '-pixel';

			if (Paths.fileExists('images/pixelUI/' + texture + '.png', IMAGE)) {
				path = 'pixelUI/' + texture;
			}

			var graphic:FlxGraphic = Paths.getImage(path);
			loadGraphic(graphic);

			width = width / 4;
			height = height / 5;

			loadGraphic(graphic, true, Math.floor(width), Math.floor(height));

			antialiasing = false;
			setGraphicSize(Std.int(width * PlayState.daPixelZoom));

			loadPixelNoteAnims();
		}
		else
		{
			frames = Paths.getSparrowAtlas(texture);

			loadNoteAnims();

			antialiasing = ClientPrefs.globalAntialiasing;
			setGraphicSize(Std.int(width * 0.7));
		}

		updateHitbox();

		if (lastAnim != null) {
			playAnim(lastAnim, true);
		}
	}

	function loadNoteAnims():Void
	{
		var vanillaInt:Array<Int> = [1, 2, 4, 3];

		var vanillaShit:String = ' static instance ' + vanillaInt[noteData];
		var shitMyPants:String = 'arrow' + vanillaShit + '0000';
		var vanillaAllowed:Bool = frames.getByName(shitMyPants) != null;

		var pointers:Array<String> = [for (i in Note.pointers.copy()) i.toUpperCase()];

		if (vanillaAllowed) {
			pointers[noteData] = vanillaShit;
		}

		animation.addByPrefix(Note.colArray[noteData], 'arrow' + pointers[noteData]);
		animation.addByPrefix('static', 'arrow' + pointers[noteData]);

		var lowCol:String = Note.pointers[noteData];
		animation.addByPrefix('pressed', lowCol + ' press', 24, false);
		animation.addByPrefix('confirm', lowCol + ' confirm', 24, false);
	}

	function loadPixelNoteAnims():Void
	{
		var pixelInt:Int = Note.pixelInt[noteData];
		animation.add(Note.colArray[noteData], [pixelInt + Note.pointers.length]);

		animation.add('static', [pixelInt]);
		animation.add('pressed', [pixelInt + Note.pointers.length, pixelInt + (Note.pointers.length * 2)], 12, false);
		animation.add('confirm', [pixelInt + (Note.pointers.length * 3), pixelInt + (Note.pointers.length * 4)], 24, false);
	}

	public function postAddedToGroup():Void
	{
		playAnim('static');
		playerPosition();

		ID = noteData;
	}

	public function playerPosition():Void
	{
		x += Note.swagWidth * noteData;
		x += 50;
		x += ((FlxG.width / 2) * player);
	}

	override function update(elapsed:Float):Void
	{
		if (resetAnim > 0)
		{
			resetAnim -= elapsed;

			if (resetAnim <= 0)
			{
				playAnim('static');
				resetAnim = 0;
			}
		}

		super.update(elapsed);
	}

	public function playAnim(anim:String, ?force:Bool = false):Void
	{
		animation.play(anim, force);

		if (animation.curAnim != null)
		{
			centerOffsets();
			centerOrigin();
		}

		if (useRGBShader) {
			rgbShader.enabled = (animation.curAnim != null && animation.curAnim.name != 'static');
		}
	}
}