package;

import haxe.Json;

#if FLXANIMATE_ALLOWED
import SwagFlxAnimate as FlxAnimate;
#end

import flixel.FlxG;
import openfl.errors.Error;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.util.FlxDestroyUtil;
import flixel.graphics.frames.FlxAtlasFrames;

using StringTools;

typedef AnimArray =
{
	var anim:String;
	var name:String;
	var fps:Int;
	var loop:Bool;
	var indices:Array<Int>;
	var offsets:Array<Int>;
}

typedef CharacterFile =
{
	var animations:Array<AnimArray>;
	var image:String;
	var scale:Float;
	var skip_dance:Bool;
	var sing_duration:Float;
	var healthicon:String;

	var position:Array<Float>;
	var camera_position:Array<Float>;

	var flip_x:Bool;
	var no_antialiasing:Bool;
	var healthbar_colors:Array<Int>;

	var gameover_properties:Array<String>;
	@:optional var _editor_isPlayer:Null<Bool>;
}

class Character extends Sprite
{
	public var debugMode:Bool = false;

	public var isPlayer:Bool = false;
	public var curCharacter:String = DEFAULT_CHARACTER;

	public var colorTween:FlxTween;
	public var holdTimer:Float = 0;
	public var heyTimer:Float = 0;
	public var specialAnim:Bool = false;
	public var stunned:Bool = false;
	public var singDuration:Float = 4; // Multiplier of how long a character holds the sing pose
	public var idleSuffix(default, set):String = '';
	public var danceIdle:Bool = false; // Character use "danceLeft" and "danceRight" instead of "idle"
	public var skipDance:Bool = false;

	public var healthIcon:String = 'face';
	public var animationsArray:Array<AnimArray> = [];

	public var positionArray:Array<Float> = [0, 0];
	public var cameraPosition:Array<Float> = [0, 0];
	public var healthColorArray:Array<Int> = [255, 0, 0];

	public var hasMissAnimations:Bool = false;

	public var deathChar:String = 'bf-dead';
	public var deathSound:String = 'fnf_loss_sfx';
	public var deathConfirm:String = 'gameOverEnd';
	public var deathMusic:String = 'gameOver';

	public var imageFile:String = ''; // Used on Character Editor
	public var jsonScale:Float = 1;
	public var noAntialiasing:Bool = false;
	public var originalFlipX:Bool = false;
	public var editorIsPlayer:Null<Bool> = null;

	public static inline final DEFAULT_CHARACTER:String = 'bf'; // In case a character is missing, it will use BF on its place

	public function new(x:Float, y:Float, ?character:String = DEFAULT_CHARACTER, ?isPlayer:Bool = false):Void
	{
		super(x, y);

		animation = new SwagAnimationController(this);

		this.isPlayer = isPlayer;
		changeCharacter(character);
	}

	public function changeCharacter(character:String):Void
	{
		animationsArray = [];
		animOffsets = [];
		curCharacter = character;

		var characterPath:String = 'characters/$character.json';

		if (Paths.fileExists(characterPath, TEXT))
		{
			try {
				loadCharacterFile(getCharacterFile(characterPath));
			}
			catch (e:Error) {
				Debug.logError('Error loading character file of "$character":' + e.toString());
			}
		}

		skipDance = false;

		for (name => offset in animOffsets)
		{
			if (name.startsWith('sing') && name.contains('miss')) // includes alt miss animations now
			{
				hasMissAnimations = true;
				break;
			}
		}

		recalculateDanceIdle();
		dance();
	}

	public function loadCharacterFile(json:CharacterFile):Void
	{
		isAnimateAtlas = false;

		#if FLXANIMATE_ALLOWED
		var animToFind:String = 'images/' + json.image + '/Animation.json';
		if (Paths.fileExists(animToFind, TEXT)) isAnimateAtlas = true;
		#end

		scale.set(1, 1);
		updateHitbox();

		if (!isAnimateAtlas)
		{
			var spriteType:String = 'sparrow';

			if (Paths.fileExists('images/' + json.image + '.txt', TEXT)) {
				spriteType = 'packer';
			}
			else if (Paths.fileExists('images/' + json.image + '.json', TEXT)) {
				spriteType = 'aseprite';
			}
	
			switch (spriteType)
			{
				case 'packer': frames = Paths.getPackerAtlas(json.image);
				case 'aseprite': frames = Paths.getAsepriteAtlas(json.image);
				default: frames = Paths.getSparrowAtlas(json.image);
			}
		}
		#if FLXANIMATE_ALLOWED
		else
		{
			atlas = new FlxAnimate();
			atlas.showPivot = false;

			try {
				Paths.loadAnimateAtlas(atlas, json.image);
			}
			catch (e:Error) {
				Debug.logWarn('Could not load atlas ${json.image}:' + e.toString());
			}
		}
		#end

		imageFile = json.image;
		jsonScale = json.scale;

		if (json.scale != 1)
		{
			scale.set(jsonScale, jsonScale);
			updateHitbox();
		}

		positionArray = json.position;
		cameraPosition = json.camera_position;

		healthIcon = json.healthicon;
		singDuration = json.sing_duration;
		flipX = (json.flip_x != isPlayer);
		healthColorArray = (json.healthbar_colors != null && json.healthbar_colors.length > 2) ? json.healthbar_colors : [161, 161, 161];
		originalFlipX = (json.flip_x == true);
		editorIsPlayer = json._editor_isPlayer;
		skipDance = !(json.skip_dance == false); // ????

		noAntialiasing = (json.no_antialiasing == true);
		antialiasing = ClientPrefs.globalAntialiasing && !noAntialiasing;

		animationsArray = json.animations;

		if (json.gameover_properties != null && json.gameover_properties.length > 2) // game over vars
		{
			if (json.gameover_properties[0] != null && json.gameover_properties[0].length > 0) {
				deathChar = json.gameover_properties[0];
			}

			if (json.gameover_properties[1] != null && json.gameover_properties[1].length > 0) {
				deathSound = json.gameover_properties[1];
			}

			if (json.gameover_properties[2] != null && json.gameover_properties[2].length > 0) {
				deathMusic = json.gameover_properties[2];
			}

			if (json.gameover_properties[3] != null && json.gameover_properties[3].length > 0) {
				deathConfirm = json.gameover_properties[3];
			}
		}

		if (animationsArray != null && animationsArray.length > 0)
		{
			for (anim in animationsArray)
			{
				var animAnim:String = '' + anim.anim;
				var animName:String = '' + anim.name;
				var animFps:Int = anim.fps;
				var animLoop:Bool = !(anim.loop == false); //Bruh
				var animIndices:Array<Int> = anim.indices;

				if (!isAnimateAtlas)
				{
					if (animIndices != null && animIndices.length > 0)
						animation.addByIndices(animAnim, animName, animIndices, '', animFps, animLoop);
					else
						animation.addByPrefix(animAnim, animName, animFps, animLoop);
				}
				#if FLXANIMATE_ALLOWED
				else
				{
					if (animIndices != null && animIndices.length > 0)
						atlas.anim.addBySymbolIndices(animAnim, animName, animIndices, animFps, animLoop);
					else
						atlas.anim.addBySymbol(animAnim, animName, animFps, animLoop);
				}
				#end

				if (anim.offsets != null && anim.offsets.length > 1) {
					addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
				}
				else addOffset(anim.anim, 0, 0);
			}
		}

		#if FLXANIMATE_ALLOWED
		if (isAnimateAtlas) copyAtlasValues();
		#end
	}

	override function update(elapsed:Float):Void
	{
		if (isAnimateAtlas) atlas.update(elapsed);

		if (debugMode || (!isAnimateAtlas && animation.curAnim == null) || (isAnimateAtlas && (atlas.anim.curInstance == null || atlas.anim.curSymbol == null)))
		{
			super.update(elapsed);
			return;
		}

		if (heyTimer > 0)
		{
			var rate:Float = (PlayState.instance != null ? PlayState.instance.playbackRate : 1.0);
			heyTimer -= elapsed * rate;

			if (heyTimer <= 0)
			{
				var anim:String = getAnimationName();

				if (specialAnim && (anim == 'hey' || anim == 'cheer'))
				{
					specialAnim = false;
					dance();
				}

				heyTimer = 0;
			}
		}
		else if (specialAnim && isAnimationFinished())
		{
			specialAnim = false;
			dance();
		}
		else if (getAnimationName().endsWith('miss') && isAnimationFinished())
		{
			dance();
			finishAnimation();
		}

		if (getAnimationName().startsWith('sing')) {
			holdTimer += elapsed;
		}
		else if (isPlayer) {
			holdTimer = 0;
		}

		if (!isPlayer && holdTimer >= Conductor.stepCrochet * (0.0011 #if FLX_PITCH / (FlxG.sound.music != null ? FlxG.sound.music.pitch : 1) #end) * singDuration)
		{
			dance();
			holdTimer = 0;
		}

		var name:String = getAnimationName();

		if (isAnimationFinished() && hasAnimation('$name-loop')) {
			playAnim('$name-loop');
		}

		super.update(elapsed);
	}

	inline public function isAnimationNull():Bool
	{
		return !isAnimateAtlas ? (animation.curAnim == null) : (atlas.anim.curInstance == null || atlas.anim.curSymbol == null);
	}

	var _lastPlayedAnimation:String;

	inline public function getAnimationName():String
	{
		return _lastPlayedAnimation;
	}

	public function isAnimationFinished():Bool
	{
		if (isAnimationNull()) return false;
		return !isAnimateAtlas ? animation.curAnim.finished : atlas.anim.finished;
	}

	public function getAnimationFrame():Int
	{
		if (isAnimationNull()) return -1;
		return !isAnimateAtlas ? animation.curAnim.curFrame : atlas.anim.curFrame;
	}

	public function setAnimationFrame(value:Int):Void
	{
		if (isAnimationNull()) return;

		if (!isAnimateAtlas) {
			animation.curAnim.curFrame = value;
		}
		else {
			atlas.anim.curFrame = value;
		}
	}

	public function finishAnimation():Void
	{
		if (isAnimationNull()) return;

		if (!isAnimateAtlas) animation.curAnim.finish();
		else atlas.anim.curFrame = atlas.anim.length - 1;
	}

	public function hasAnimation(anim:String):Bool
	{
		return animOffsets.exists(anim);
	}

	public var animPaused(get, set):Bool;

	private function get_animPaused():Bool
	{
		if (isAnimationNull()) return false;
		return !isAnimateAtlas ? animation.curAnim.paused : atlas.anim.isPlaying;
	}

	private function set_animPaused(value:Bool):Bool
	{
		if (isAnimationNull()) return value;

		if (!isAnimateAtlas) animation.curAnim.paused = value;
		else
		{
			if (value) atlas.pauseAnimation();
			else atlas.resumeAnimation();
		}

		return value;
	}

	public var danced:Bool = false;

	public function dance(force:Bool = false):Void
	{
		if (!debugMode && !skipDance && !specialAnim)
		{
			var danceAnim:String = 'idle$idleSuffix';

			if (danceIdle)
			{
				danced = !danced;
				danceAnim = 'dance' + (danced ? 'Right' : 'Left') + '$idleSuffix';
			}
	
			playAnim(danceAnim, force);
		}
	}

	override public function playAnim(name:String, forced:Bool = false, ?reverse:Bool = false, ?startFrame:Int = 0):Void
	{
		specialAnim = false;

		if (!isAnimateAtlas) {
			animation.play(name, forced, reverse, startFrame);
		}
		else
		{
			atlas.anim.play(name, forced, reverse, startFrame);
			atlas.update(0);
		}

		_lastPlayedAnimation = name;

		var daOffset:Array<Float> = animOffsets.get(name);
		if (hasAnimation(name)) offset.set(daOffset[0], daOffset[1]);

		if (curCharacter.startsWith('gf') || danceIdle) // idk
		{
			switch (name)
			{
				case 'singLEFT': danced = true;
				case 'singRIGHT': danced = false;
				case 'singUP' | 'singDOWN': danced = !danced;
			}
		}
	}

	public var danceEveryNumBeats:Int = ClientPrefs.danceOffset;
	private var settingCharacterUp:Bool = true;

	public function recalculateDanceIdle():Void
	{
		final lastDanceIdle:Bool = danceIdle;
		danceIdle = (hasAnimation('danceLeft' + idleSuffix) && hasAnimation('danceRight' + idleSuffix));

		if (settingCharacterUp) {
			danceEveryNumBeats = (danceIdle ? 1 : ClientPrefs.danceOffset);
		}
		else if (lastDanceIdle != danceIdle)
		{
			var calc:Float = danceEveryNumBeats;

			if (danceIdle) {
				calc /= ClientPrefs.danceOffset;
			}
			else {
				calc *= ClientPrefs.danceOffset;
			}

			danceEveryNumBeats = Math.round(Math.max(calc, 1));
		}

		settingCharacterUp = false;
	}

	function set_idleSuffix(newSuffix:String):String
	{
		if (idleSuffix == newSuffix) return newSuffix;

		idleSuffix = newSuffix;
		recalculateDanceIdle();

		return idleSuffix;
	}

	public static function getCharacterFile(path:String):CharacterFile
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

	public var isAnimateAtlas:Bool = false;

	#if FLXANIMATE_ALLOWED
	public var atlas:FlxAnimate;

	public override function draw():Void
	{
		var lastAlpha:Float = alpha;
		var lastColor:FlxColor = color;

		if (isAnimateAtlas)
		{
			if (atlas.anim.curInstance != null)
			{
				copyAtlasValues();
				atlas.draw();

				alpha = lastAlpha;
				color = lastColor;
			}

			return;
		}

		super.draw();
	}

	public function copyAtlasValues():Void
	{
		@:privateAccess
		{
			atlas.cameras = cameras;
			atlas.scrollFactor = scrollFactor;
			atlas.scale = scale;
			atlas.offset = offset;
			atlas.origin = origin;
			atlas.x = x;
			atlas.y = y;
			atlas.angle = angle;
			atlas.alpha = alpha;
			atlas.visible = visible;
			atlas.flipX = flipX;
			atlas.flipY = flipY;
			atlas.shader = shader;
			atlas.antialiasing = antialiasing;
			atlas.colorTransform = colorTransform;
			atlas.color = color;
		}
	}

	public override function destroy():Void
	{
		super.destroy();

		destroyAtlas();
	}

	public function destroyAtlas():Void
	{
		if (atlas != null) {
			atlas = FlxDestroyUtil.destroy(atlas);
		}
	}
	#end
}