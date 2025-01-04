package;

import NoteTypesConfig;
import shaders.RGBPalette;

import flixel.FlxSprite;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;

using StringTools;

typedef EventNote =
{
	var strumTime:Float;
	var event:String;
	var value1:String;
	var value2:String;
}

typedef NoteSplashData =
{
	var disabled:Bool;
	var texture:String;
	var useGlobalShader:Bool; //breaks r/g/b/a but makes it copy default colors for your custom note
	var useRGBShader:Bool;
	var antialiasing:Bool;
	var r:FlxColor;
	var g:FlxColor;
	var b:FlxColor;
	var a:Float;
	var opponent:Bool;
	var quick:Bool;
}

class Note extends FlxSprite
{
	public static final defaultNoteTypes:Array<String> =
	[
		'', // Always leave this one empty pls
		'Alt Animation',
		'Hey!',
		'Hurt Note',
		'GF Sing',
		'No Animation'
	];

	public var extraData:Map<String, Dynamic> = new Map<String, Dynamic>();

	public var strumTime:Float = 0;
	public var mustPress:Bool = false;
	public var noteData:Int = 0;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;
	public var ignoreNote:Bool = false;
	public var hitByOpponent:Bool = false;
	public var noteWasHit:Bool = false;
	public var prevNote:Note;
	public var nextNote:Note;

	public var spawned:Bool = false;

	public var tail:Array<Note> = []; // for sustains
	public var parent:Note;
	public var blockHit:Bool = false; // only works for player

	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;
	public var noteType(default, set):String = null;

	public var eventName:String = '';
	public var eventLength:Int = 0;
	public var eventVal1:String = '';
	public var eventVal2:String = '';

	public var disableDefaultRGBShader:Bool = false;
	public var rgbShader:RGBShaderReference;

	public var inEditor:Bool = false;

	public var animSuffix:String = '';
	public var gfNote:Bool = false;
	public var earlyHitMult:Float = 1;
	public var lateHitMult:Float = 1;
	public var lowPriority:Bool = false;

	public static var SUSTAIN_SIZE:Int = 44;
	public static var swagWidth:Float = 160 * 0.7;
	public static var globalRgbShaders:Array<RGBPalette> = [];
	public static var pixelInt:Array<Int> = [0, 1, 2, 3];
	public static var pointers:Array<String> = ['left', 'down', 'up', 'right'];
	public static var colArray:Array<String> = ['purple', 'blue', 'green', 'red'];
	public static var defaultNoteSkin(default, never):String = 'noteSkins/NOTE_assets';

	public var noteSplashData:NoteSplashData = {
		disabled: false,
		texture: null,
		antialiasing: !PlayState.isPixelStage,
		useGlobalShader: false,
		useRGBShader: (PlayState.SONG != null) ? !(PlayState.SONG.disableNoteRGB == true) : true,
		r: -1,
		g: -1,
		b: -1,
		a: ClientPrefs.splashAlpha,
		opponent: false,
		quick: false
	};

	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var offsetAngle:Float = 0;
	public var multAlpha:Float = 1;
	public var multSpeed(default, set):Float = 1;

	public var copyX:Bool = true;
	public var copyY:Bool = true;
	public var copyAngle:Bool = true;
	public var copyAlpha:Bool = true;

	public var comboDisabled:Bool = false;
	public var healthDisabled:Bool = true;
	public var hitHealth:Float = 0.023;
	public var missHealth:Float = 0.0475;
	public var rating:String = 'unknown';
	public var ratingMod:Float = 0; //9 = unknown, 0.25 = shit, 0.5 = bad, 0.75 = good, 1 = sick
	public var ratingDisabled:Bool = false;

	public var texture(default, set):String = null;

	public var noAnimation:Bool = false;
	public var noMissAnimation:Bool = false;
	public var hitCausesMiss:Bool = false;
	public var distance:Float = 2000; //plan on doing scroll directions soon -bb

	public var hitsoundDisabled:Bool = false;
	public var hitsoundChartEditor:Bool = true;
	public var hitsound:String = 'hitsound';

	private function set_multSpeed(value:Float):Float
	{
		resizeByRatio(value / multSpeed);
		multSpeed = value;

		return value;
	}

	public function resizeByRatio(ratio:Float):Void // haha funny twitter shit
	{
		if (isSustainNote && animation.curAnim != null && !animation.curAnim.name.endsWith('end'))
		{
			scale.y *= ratio;
			updateHitbox();
		}
	}

	private function set_texture(value:String):String
	{
		if (texture != value) reloadNote(value);

		texture = value;
		return value;
	}

	public function defaultRGB():Void
	{
		var arr:Array<FlxColor> = ClientPrefs.arrowRGB[noteData];
		if (PlayState.isPixelStage) arr = ClientPrefs.arrowRGBPixel[noteData];

		if (noteData > -1 && noteData <= arr.length)
		{
			rgbShader.r = arr[0];
			rgbShader.g = arr[1];
			rgbShader.b = arr[2];
		}
	}

	private function set_noteType(value:String):String
	{
		noteSplashData.texture = (PlayState.SONG != null) ? PlayState.SONG.splashSkin : 'noteSplashes';
		defaultRGB();

		if (noteData > -1 && noteType != value)
		{
			switch (value)
			{
				case 'Hurt Note':
				{
					ignoreNote = mustPress;

					disableDefaultRGBShader = true;

					rgbShader.r = 0xFF101010;
					rgbShader.g = 0xFFFF0000;
					rgbShader.b = 0xFF990022;

					noteSplashData.r = 0xFFFF0000;
					noteSplashData.g = 0xFF101010;
					noteSplashData.texture = 'noteSplashes/noteSplashes-electric';

					lowPriority = true;
					missHealth = isSustainNote ? 0.25 : 0.1;
					hitCausesMiss = true;
					hitsound = 'cancelMenu';
					hitsoundChartEditor = false;
				}
				case 'Alt Animation': animSuffix = '-alt';
				case 'No Animation':
				{
					noAnimation = true;
					noMissAnimation = true;
				}
				case 'GF Sing': gfNote = true;
			}

			if (value != null && value.length > 1) NoteTypesConfig.applyNoteTypeData(this, value);
			if (hitsound != 'hitsound' && ClientPrefs.hitsoundVolume > 0) Paths.getSound(hitsound); // precache new sound for being idiot-proof

			noteType = value;
		}

		return value;
	}

	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false, ?inEditor:Bool = false, ?createdFrom:Dynamic = null):Void
	{
		super();

		antialiasing = ClientPrefs.globalAntialiasing;
		if (createdFrom == null) createdFrom = PlayState.instance;

		if (prevNote == null) {
			prevNote = this;
		}

		this.prevNote = prevNote;
		isSustainNote = sustainNote;

		this.inEditor = inEditor;
		this.moves = false;

		var middleScroll:Bool = ClientPrefs.middleScroll;

		if (PlayState.instance != null) {
			middleScroll = PlayState.instance.middleScroll;
		}

		x += (middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X) + 50;
		y -= 2000; // MAKE SURE ITS DEFINITELY OFF SCREEN?

		this.strumTime = strumTime + (!inEditor ? ClientPrefs.noteOffset : 0);
		this.noteData = noteData;

		if (noteData > -1)
		{
			texture = '';

			rgbShader = new RGBShaderReference(this, initializeGlobalRGBShader(noteData));

			if (PlayState.SONG != null && PlayState.SONG.disableNoteRGB) {
				rgbShader.enabled = false;
			}

			x += swagWidth * (noteData);

			if (!isSustainNote && noteData < colArray.length) // Doing this 'if' check to fix the warnings on Senpai songs
			{
				var animToPlay:String = '';
				animToPlay = colArray[noteData % colArray.length];
				animation.play(animToPlay + 'Scroll');
			}
		}

		if (prevNote != null) {
			prevNote.nextNote = this;
		}

		if (isSustainNote && prevNote != null)
		{
			alpha = 0.6;
			multAlpha = 0.6;
			hitsoundDisabled = true;

			flipY = ClientPrefs.downScroll;

			offsetX += width / 2;
			copyAngle = false;

			animation.play(colArray[noteData % colArray.length] + 'holdend');

			updateHitbox();

			offsetX -= width / 2;

			if (PlayState.isPixelStage) {
				offsetX += 30;
			}

			if (prevNote.isSustainNote)
			{
				prevNote.animation.play(colArray[prevNote.noteData % colArray.length] + 'hold');

				prevNote.scale.y *= Conductor.stepCrochet / 100 * 1.05;
				if (createdFrom != null && createdFrom.songSpeed != null) prevNote.scale.y *= createdFrom.songSpeed;

				if (PlayState.isPixelStage)
				{
					prevNote.scale.y *= 1.19;
					prevNote.scale.y *= (6 / height); // Auto adjust note size
				}

				prevNote.updateHitbox();
			}

			if (PlayState.isPixelStage)
			{
				scale.y *= PlayState.daPixelZoom;
				updateHitbox();
			}

			earlyHitMult = 0;
		}
		else if (!isSustainNote)
		{
			centerOffsets();
			centerOrigin();
		}

		x += offsetX;
	}

	public static function initializeGlobalRGBShader(noteData:Int):RGBPalette
	{
		if (globalRgbShaders[noteData] == null)
		{
			var newRGB:RGBPalette = new RGBPalette();
			var arr:Array<FlxColor> = (!PlayState.isPixelStage) ? ClientPrefs.arrowRGB[noteData] : ClientPrefs.arrowRGBPixel[noteData];

			if (arr != null && noteData > -1 && noteData <= arr.length)
			{
				newRGB.r = arr[0];
				newRGB.g = arr[1];
				newRGB.b = arr[2];
			}
			else
			{
				newRGB.r = 0xFFFF0000;
				newRGB.g = 0xFF00FF00;
				newRGB.b = 0xFF0000FF;
			}

			globalRgbShaders[noteData] = newRGB;
		}

		return globalRgbShaders[noteData];
	}

	var _lastNoteOffX:Float = 0;
	static var _lastValidChecked:String; // optimization

	public var originalHeight:Float = 6;
	public var correctionOffset:Float = 0; // dont mess with this

	public function reloadNote(texture:String = '', postfix:String = ''):Void
	{
		if (texture == null) texture = '';
		if (postfix == null) postfix = '';

		var skin:String = texture + postfix;

		if (texture.length < 1)
		{
			skin = PlayState.SONG != null ? PlayState.SONG.arrowSkin : null;

			if (skin == null || skin.length < 1) {
				skin = defaultNoteSkin + postfix;
			}
		}

		var animName:String = null;

		if (animation.curAnim != null) {
			animName = animation.curAnim.name;
		}

		var skinPixel:String = skin;
		var lastScaleY:Float = scale.y;
		var skinPostfix:String = getNoteSkinPostfix();
		var customSkin:String = skin + skinPostfix;
		var path:String = PlayState.isPixelStage ? 'pixelUI' : '';

		if (customSkin == _lastValidChecked || Paths.fileExists('images/' + path + customSkin + '.png', IMAGE))
		{
			skin = customSkin;
			_lastValidChecked = customSkin;
		}
		else skinPostfix = '';

		if (PlayState.isPixelStage)
		{
			if (isSustainNote)
			{
				var path:String = skinPixel + 'ENDS' + skinPostfix + '-pixel';

				if (Paths.fileExists('images/pixelUI/' + skinPixel + 'ENDS' + skinPostfix + '.png', IMAGE)) {
					path = 'pixelUI/' + skinPixel + 'ENDS' + skinPostfix;
				}

				var graphic:FlxGraphic = Paths.getImage(path);
				loadGraphic(graphic, true, Math.floor(graphic.width / 4), Math.floor(graphic.height / 2));

				originalHeight = graphic.height / 2;
			}
			else
			{
				var path:String = skinPixel + skinPostfix + '-pixel';

				if (Paths.fileExists('images/pixelUI/' + skinPixel + skinPostfix + '.png', IMAGE)) {
					path = 'pixelUI/' + skinPixel + skinPostfix;
				}

				var graphic:FlxGraphic = Paths.getImage(path);
				loadGraphic(graphic, true, Math.floor(graphic.width / 4), Math.floor(graphic.height / 5));
			}

			setGraphicSize(Std.int(width * PlayState.daPixelZoom));
			loadPixelNoteAnims();
			antialiasing = false;

			if (isSustainNote)
			{
				offsetX += _lastNoteOffX;
				_lastNoteOffX = (width - 7) * (PlayState.daPixelZoom / 2);
				offsetX -= _lastNoteOffX;
			}
		}
		else
		{
			frames = Paths.getSparrowAtlas(skin);
			loadNoteAnims();

			if (!isSustainNote)
			{
				centerOffsets();
				centerOrigin();
			}
		}

		if (isSustainNote) {
			scale.y = lastScaleY;
		}

		updateHitbox();

		if (animName != null) {
			animation.play(animName, true);
		}
	}

	public static function getNoteSkinPostfix():String
	{
		var skin:String = '';

		if (ClientPrefs.noteSkin != ClientPrefs.defaultData.noteSkin) {
			skin = '-' + ClientPrefs.noteSkin.trim().toLowerCase().replace(' ', '_');
		}

		return skin;
	}

	function loadNoteAnims():Void
	{
		if (colArray[noteData] == null) return;

		var ourCol:String = colArray[noteData];
		var blyad:String = ourCol + ' instance 1';
		var isVanilla:Bool = true;

		if (!frames.exists(blyad + '0000'))
		{
			isVanilla = false;
			blyad = ourCol + '0';
		}

		animation.addByPrefix(ourCol + 'Scroll', blyad);

		if (isSustainNote)
		{
			var shitInPants:String = ' instance 1';

			if (frames.exists('pruple end hold0000')) {
				attemptToAddAnimationByPrefix('purpleholdend', 'pruple end hold'); // this fixes some retarded typo from the original note .FLA
			}

			animation.addByPrefix(ourCol + 'holdend', ourCol + ' hold end' + (isVanilla ? shitInPants : ''));
			animation.addByPrefix(ourCol + 'hold', ourCol + ' hold piece' + (isVanilla ? shitInPants : ''));
		}

		setGraphicSize(Std.int(width * 0.7));
		updateHitbox();
	}

	function loadPixelNoteAnims():Void
	{
		if (colArray[noteData] == null) return;

		if (isSustainNote)
		{
			animation.add(colArray[noteData] + 'holdend', [noteData + 4], 24, true);
			animation.add(colArray[noteData] + 'hold', [noteData], 24, true);
		}
		else {
			animation.add(colArray[noteData] + 'Scroll', [noteData + 4], 24, true);
		}
	}

	function attemptToAddAnimationByPrefix(name:String, prefix:String, framerate:Float = 24, doLoop:Bool = true):Void
	{
		var animFrames:Array<FlxFrame> = [];

		@:privateAccess animation.findByPrefix(animFrames, prefix); // adds valid frames to animFrames
		if (animFrames.length < 1) return;

		animation.addByPrefix(name, prefix, framerate, doLoop);
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (mustPress)
		{
			canBeHit = (strumTime > Conductor.songPosition - (Conductor.safeZoneOffset * lateHitMult) &&
				strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult));

			if (strumTime < Conductor.songPosition - Conductor.safeZoneOffset && !wasGoodHit)
				tooLate = true;
		}
		else
		{
			canBeHit = false;

			if (strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult))
			{
				if ((isSustainNote && prevNote.wasGoodHit) || strumTime <= Conductor.songPosition) {
					wasGoodHit = true;
				}
			}
		}

		if (tooLate && !inEditor) {
			if (alpha > 0.3) alpha = 0.3;
		}
	}

	override function destroy():Void
	{
		clipRect = FlxDestroyUtil.put(clipRect);
		_lastValidChecked = '';

		super.destroy();
	}

	public function followStrumNote(myStrum:StrumNote, fakeCrochet:Float, songSpeed:Float = 1):Void
	{
		var strumX:Float = myStrum.x;
		var strumY:Float = myStrum.y;

		var strumAngle:Float = myStrum.angle;
		var strumAlpha:Float = myStrum.alpha;

		var strumDirection:Float = myStrum.direction;

		distance = (0.45 * (Conductor.songPosition - strumTime) * songSpeed * multSpeed);
		if (!myStrum.downScroll) distance *= -1;

		var angleDir:Float = strumDirection * Math.PI / 180;

		if (copyAngle) {
			angle = strumDirection - 90 + strumAngle + offsetAngle;
		}

		if (copyAlpha) {
			alpha = strumAlpha * multAlpha;
		}

		if (copyX) {
			x = strumX + offsetX + Math.cos(angleDir) * distance;
		}

		if (copyY)
		{
			y = strumY + offsetY + correctionOffset + Math.sin(angleDir) * distance;

			if (myStrum.downScroll && isSustainNote)
			{
				if (PlayState.isPixelStage) {
					y -= PlayState.daPixelZoom * 9.5;
				}

				y -= (frameHeight * scale.y) - (Note.swagWidth / 2);
			}
		}
	}

	public function clipToStrumNote(myStrum:StrumNote):Void
	{
		final center:Float = myStrum.y + offsetY + Note.swagWidth / 2;

		if (isSustainNote && (mustPress || !ignoreNote) && (!mustPress || (wasGoodHit || (prevNote.wasGoodHit && !canBeHit))))
		{
			final swagRect:FlxRect = (clipRect == null ? FlxRect.get(0, 0, width / scale.x, height / scale.y) : clipRect);

			if (myStrum.downScroll)
			{
				var result:Int = Std.int((y + height) - center);

				if (result > 0) {
					swagRect.y = result / scale.y;
				}
			}
			else
			{
				var result:Int = Std.int(center - y);

				if (result > 0) {
					swagRect.y = result / scale.y;
				}
			}

			clipRect = swagRect;
		}
	}

	@:noCompletion
	override function set_clipRect(rect:FlxRect):FlxRect
	{
		clipRect = rect;

		if (frames != null)
			frame = frames.frames[animation.frameIndex];

		return rect;
	}
}