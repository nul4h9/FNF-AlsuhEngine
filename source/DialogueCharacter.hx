package;

import haxe.Json;

import flixel.FlxG;
import flixel.FlxSprite;

using StringTools;

typedef DialogueAnimArray =
{
	var anim:String;
	var loop_name:String;
	var loop_offsets:Array<Int>;
	var idle_name:String;
	var idle_offsets:Array<Int>;
}

typedef DialogueCharacterFile =
{
	var image:String;
	var dialogue_pos:String;
	var no_antialiasing:Bool;

	var animations:Array<DialogueAnimArray>;
	var position:Array<Float>;
	var scale:Float;
}

class DialogueCharacter extends FlxSprite
{
	private static var IDLE_SUFFIX:String = '-IDLE';

	public static var DEFAULT_CHARACTER:String = 'bf';
	public static var DEFAULT_SCALE:Float = 0.7;

	public var jsonFile:DialogueCharacterFile = null;
	public var dialogueAnimations:Map<String, DialogueAnimArray> = new Map<String, DialogueAnimArray>();

	public var startingPos:Float = 0; //For center characters, it works as the starting Y, for everything else it works as starting X
	public var isGhost:Bool = false; //For the editor
	public var curCharacter:String = 'bf';
	public var skiptimer = 0;
	public var skipping = 0;

	public function new(x:Float = 0, y:Float = 0, character:String = null):Void
	{
		super(x, y);

		if (character == null) character = DEFAULT_CHARACTER;
		curCharacter = character;

		reloadCharacterJson(character);

		var split:Array<String> = [for (i in jsonFile.image.trim().split(',')) 'dialogue/' + i.trim()];
		frames = Paths.getMultiAtlas(split);

		reloadAnimations();

		antialiasing = ClientPrefs.globalAntialiasing;
		if (jsonFile.no_antialiasing == true) antialiasing = false;
	}

	public function reloadCharacterJson(character:String):Void
	{
		var rawJson:String = Paths.getTextFromFile('portraits/$DEFAULT_CHARACTER.json');

		if (Paths.fileExists('images/dialogue/$character.json', TEXT)) {
			rawJson = Paths.getTextFromFile('images/dialogue/$character.json');
		}
		else if (Paths.fileExists('images/dialogue/$character.json', TEXT)) {
			rawJson = Paths.getTextFromFile('images/dialogue/$character.json');
		}
		else if (Paths.fileExists('portraits/$character.json', TEXT)) {
			rawJson = Paths.getTextFromFile('portraits/$character.json');
		}

		jsonFile = cast Json.parse(rawJson);
	}

	public function reloadAnimations():Void
	{
		dialogueAnimations.clear();

		if (jsonFile.animations != null && jsonFile.animations.length > 0)
		{
			for (anim in jsonFile.animations)
			{
				animation.addByPrefix(anim.anim, anim.loop_name, 24, isGhost);
				animation.addByPrefix(anim.anim + IDLE_SUFFIX, anim.idle_name, 24, true);
				dialogueAnimations.set(anim.anim, anim);
			}
		}
	}

	public function playAnim(animName:String = null, playIdle:Bool = false):Void
	{
		var leAnim:String = animName;

		if (animName == null || !dialogueAnimations.exists(animName)) // Anim is null, get a random animation
		{
			var arrayAnims:Array<String> = [];

			for (anim in dialogueAnimations) {
				arrayAnims.push(anim.anim);
			}

			if (arrayAnims.length > 0) {
				leAnim = arrayAnims[FlxG.random.int(0, arrayAnims.length - 1)];
			}
		}

		if (dialogueAnimations.exists(leAnim) && (dialogueAnimations.get(leAnim).loop_name == null ||
			dialogueAnimations.get(leAnim).loop_name.length < 1 ||
			dialogueAnimations.get(leAnim).loop_name == dialogueAnimations.get(leAnim).idle_name)) {
			playIdle = true;
		}

		animation.play(playIdle ? leAnim + IDLE_SUFFIX : leAnim, false);

		if (dialogueAnimations.exists(leAnim))
		{
			var anim:DialogueAnimArray = dialogueAnimations.get(leAnim);

			if (playIdle) {
				offset.set(anim.idle_offsets[0], anim.idle_offsets[1]);
			}
			else {
				offset.set(anim.loop_offsets[0], anim.loop_offsets[1]);
			}
		}
		else
		{
			offset.set(0, 0);
			Debug.logError('Offsets not found! Dialogue character is badly formatted, anim: ' + leAnim + ', ' + (playIdle ? 'idle anim' : 'loop anim'));
		}
	}

	public function animationIsLoop():Bool
	{
		return animation.curAnim != null && !animation.curAnim.name.endsWith(IDLE_SUFFIX);
	}
}