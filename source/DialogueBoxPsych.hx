package;

import haxe.Json;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.group.FlxSpriteGroup;

using StringTools;

typedef DialogueFile = {
	var dialogue:Array<DialogueLine>;
}

typedef DialogueLine =
{
	var portrait:Null<String>;
	var expression:Null<String>;
	var text:Null<String>;
	var boxState:Null<String>;
	var speed:Null<Float>;
	var sound:Null<String>;
}

class DialogueBoxPsych extends FlxSpriteGroup // TO DO: Clean code? Maybe? idk
{
	public static var DEFAULT_TEXT_X:Float = 175;
	public static var DEFAULT_TEXT_Y:Float = 460;
	public static var LONG_TEXT_ADD:Float = 24;

	var daText:TypedAlphabet;
	var scrollSpeed:Float = 4000;
	var dialogueList:DialogueFile = null;

	public var finishThing:Void->Void;
	public var nextDialogueThing:Void->Void = null;
	public var skipDialogueThing:Void->Void = null;

	var bgFade:Sprite = null;
	var box:Sprite;
	var textToType:String = '';

	var arrayCharacters:Array<DialogueCharacter> = [];

	var currentText:Int = 0;
	var offsetPos:Float = -600;

	var textBoxTypes:Array<String> = ['normal', 'angry'];
	
	var curCharacter:String = '';

	public function new(dialogueList:DialogueFile, ?song:String = null):Void
	{
		super();

		if (song != null && song != '' && song != 'none')
		{
			FlxG.sound.playMusic(Paths.getMusic(song), 0);
			#if FLX_PITCH
			FlxG.sound.music.pitch = PlayState.instance.playbackRate;
			#end
			FlxG.sound.music.fadeIn(2, 0, 1);
		}
		
		bgFade = new Sprite(-500, -500);
		bgFade.makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.WHITE);
		bgFade.scrollFactor.set();
		bgFade.visible = true;
		bgFade.alpha = 0;
		add(bgFade);

		this.dialogueList = dialogueList;
		spawnCharacters();

		box = new Sprite(70, 370);

		if (Paths.fileExists('images/speech_bubble.png', IMAGE)) {
			box.frames = Paths.getSparrowAtlas('speech_bubble');
		}
		else {
			box.frames = Paths.getSparrowAtlas('dialogue/speech_bubble');
		}

		box.scrollFactor.set();
		box.animation.addByPrefix('normal', 'speech bubble normal', 24);
		box.animation.addByPrefix('normalOpen', 'Speech Bubble Normal Open', 24, false);
		box.animation.addByPrefix('angry', 'AHH speech bubble', 24);
		box.animation.addByPrefix('angryOpen', 'speech bubble loud open', 24, false);
		box.animation.addByPrefix('center-normal', 'speech bubble middle', 24);
		box.animation.addByPrefix('center-normalOpen', 'Speech Bubble Middle Open', 24, false);
		box.animation.addByPrefix('center-angry', 'AHH Speech Bubble middle', 24);
		box.animation.addByPrefix('center-angryOpen', 'speech bubble Middle loud open', 24, false);
		box.playAnim('normal', true);
		box.alpha = FlxMath.EPSILON;
		box.setGraphicSize(Std.int(box.width * 0.9));
		box.updateHitbox();
		add(box);

		daText = new TypedAlphabet(DEFAULT_TEXT_X, DEFAULT_TEXT_Y);
		daText.setScale(0.7);
		add(daText);

		startNextDialog();
	}

	var dialogueStarted:Bool = false;
	var dialogueEnded:Bool = false;

	public static var LEFT_CHAR_X:Float = -60;
	public static var RIGHT_CHAR_X:Float = -100;
	public static var DEFAULT_CHAR_Y:Float = 60;

	function spawnCharacters():Void
	{
		var charsArray:Array<String> = [];

		for (i in 0...dialogueList.dialogue.length)
		{
			if (dialogueList.dialogue[i] != null)
			{
				var charToAdd:String = dialogueList.dialogue[i].portrait;

				if (!charsArray.contains(charToAdd)) {
					charsArray.push(charToAdd);
				}
			}
		}

		for (individualChar in charsArray)
		{
			var x:Float = LEFT_CHAR_X;
			var y:Float = DEFAULT_CHAR_Y;

			var char:DialogueCharacter = new DialogueCharacter(x + offsetPos, y, individualChar);
			char.setGraphicSize(Std.int(char.width * DialogueCharacter.DEFAULT_SCALE * char.jsonFile.scale));
			char.updateHitbox();
			char.scrollFactor.set();
			char.alpha = FlxMath.EPSILON;
			add(char);

			var saveY:Bool = false;

			switch (char.jsonFile.dialogue_pos)
			{
				case 'center':
				{
					char.x = FlxG.width / 2;
					char.x -= char.width / 2;

					y = char.y;

					char.y = FlxG.height + 50;
					saveY = true;
				}
				case 'right':
				{
					x = FlxG.width - char.width + RIGHT_CHAR_X;
					char.x = x - offsetPos;
				}
			}

			x += char.jsonFile.position[0];
			y += char.jsonFile.position[1];

			char.x += char.jsonFile.position[0];
			char.y += char.jsonFile.position[1];

			char.startingPos = (saveY ? y : x);
			arrayCharacters.push(char);
		}
	}

	var ignoreThisFrame:Bool = true; //First frame is reserved for loading dialogue images

	public var closeSound:String = 'dialogueClose';
	public var closeVolume:Float = 1;

	override function update(elapsed:Float):Void
	{
		if (ignoreThisFrame)
		{
			ignoreThisFrame = false;

			super.update(elapsed);
			return;
		}

		if (!dialogueEnded)
		{
			bgFade.alpha += 0.5 * elapsed * PlayState.instance.playbackRate;
			if (bgFade.alpha > 0.5) bgFade.alpha = 0.5;

			if (Controls.instance.ACCEPT_P)
			{
				if (!daText.finishedText)
				{
					daText.finishText();

					if (skipDialogueThing != null) {
						skipDialogueThing();
					}
				}
				else if (currentText >= dialogueList.dialogue.length)
				{
					dialogueEnded = true;

					for (i in 0...textBoxTypes.length)
					{
						var checkArray:Array<String> = ['', 'center-'];
						var animName:String = box.animation.curAnim.name;

						for (j in 0...checkArray.length)
						{
							if (animName == checkArray[j] + textBoxTypes[i] || animName == checkArray[j] + textBoxTypes[i] + 'Open') {
								box.playAnim(checkArray[j] + textBoxTypes[i] + 'Open', true);
							}
						}
					}

					box.animation.curAnim.curFrame = box.animation.curAnim.frames.length - 1;
					box.animation.curAnim.reverse();

					if (daText != null)
					{
						daText.kill();
						remove(daText);
						daText.destroy();
					}

					updateBoxOffsets(box);
					FlxG.sound.music.fadeOut(1, 0, (_) -> FlxG.sound.music.stop());
				}
				else {
					startNextDialog();
				}

				FlxG.sound.play(Paths.getSound(closeSound), closeVolume);
			}
			else if (daText.finishedText)
			{
				var char:DialogueCharacter = arrayCharacters[lastCharacter];

				if (char != null && char.animation.curAnim != null && char.animationIsLoop() && char.animation.finished) {
					char.playAnim(char.animation.curAnim.name, true);
				}
			}
			else
			{
				var char:DialogueCharacter = arrayCharacters[lastCharacter];

				if (char != null && char.animation.curAnim != null && char.animation.finished) {
					char.animation.curAnim.restart();
				}
			}

			if (box.animation.curAnim.finished)
			{
				for (i in 0...textBoxTypes.length)
				{
					var checkArray:Array<String> = ['', 'center-'];
					var animName:String = box.animation.curAnim.name;

					for (j in 0...checkArray.length)
					{
						if (animName == checkArray[j] + textBoxTypes[i] || animName == checkArray[j] + textBoxTypes[i] + 'Open') {
							box.playAnim(checkArray[j] + textBoxTypes[i], true);
						}
					}
				}

				updateBoxOffsets(box);
			}

			if (lastCharacter != -1 && arrayCharacters.length > 0)
			{
				for (i in 0...arrayCharacters.length)
				{
					var char:DialogueCharacter = arrayCharacters[i];

					if (char != null)
					{
						if (i != lastCharacter)
						{
							switch (char.jsonFile.dialogue_pos)
							{
								case 'left':
								{
									char.x -= scrollSpeed * elapsed * PlayState.instance.playbackRate;
									if (char.x < char.startingPos + offsetPos) char.x = char.startingPos + offsetPos;
								}
								case 'center':
								{
									char.y += scrollSpeed * elapsed * PlayState.instance.playbackRate;
									if (char.y > char.startingPos + FlxG.height) char.y = char.startingPos + FlxG.height;
								}
								case 'right':
								{
									char.x += scrollSpeed * elapsed * PlayState.instance.playbackRate;
									if (char.x > char.startingPos - offsetPos) char.x = char.startingPos - offsetPos;
								}
							}

							char.alpha -= 3 * elapsed * PlayState.instance.playbackRate;
							if (char.alpha < FlxMath.EPSILON) char.alpha = FlxMath.EPSILON;
						}
						else
						{
							switch (char.jsonFile.dialogue_pos)
							{
								case 'left':
								{
									char.x += scrollSpeed * elapsed * PlayState.instance.playbackRate;
									if (char.x > char.startingPos) char.x = char.startingPos;
								}
								case 'center':
								{
									char.y -= scrollSpeed * elapsed * PlayState.instance.playbackRate;
									if (char.y < char.startingPos) char.y = char.startingPos;
								}
								case 'right':
								{
									char.x -= scrollSpeed * elapsed * PlayState.instance.playbackRate;
									if (char.x < char.startingPos) char.x = char.startingPos;
								}
							}

							char.alpha += 3 * elapsed * PlayState.instance.playbackRate;
							if (char.alpha > 1) char.alpha = 1;
						}
					}
				}
			}
		}
		else //Dialogue ending
		{
			if (box != null && box.animation.curAnim.curFrame <= 0)
			{
				box.kill();
				remove(box);
				box.destroy();

				box = null;
			}

			if (bgFade != null)
			{
				bgFade.alpha -= 0.5 * elapsed * PlayState.instance.playbackRate;

				if (bgFade.alpha <= 0)
				{
					bgFade.kill();
					remove(bgFade);
					bgFade.destroy();

					bgFade = null;
				}
			}

			for (i in 0...arrayCharacters.length)
			{
				var leChar:DialogueCharacter = arrayCharacters[i];

				if (leChar != null)
				{
					switch (arrayCharacters[i].jsonFile.dialogue_pos)
					{
						case 'left': leChar.x -= scrollSpeed * elapsed * PlayState.instance.playbackRate;
						case 'center': leChar.y += scrollSpeed * elapsed * PlayState.instance.playbackRate;
						case 'right': leChar.x += scrollSpeed * elapsed * PlayState.instance.playbackRate;
					}

					leChar.alpha -= elapsed * 10 * PlayState.instance.playbackRate;
				}
			}

			if (box == null && bgFade == null)
			{
				while (arrayCharacters.length > 0)
				{
					var leChar:DialogueCharacter = arrayCharacters[0];

					if (leChar != null)
					{
						arrayCharacters.remove(leChar);

						leChar.kill();
						remove(leChar);
						leChar.destroy();
					}
				}

				finishThing();
				kill();
			}
		}

		super.update(elapsed);
	}

	var lastCharacter:Int = -1;
	var lastBoxType:String = '';

	function startNextDialog():Void
	{
		var curDialogue:DialogueLine = null;

		do {
			curDialogue = dialogueList.dialogue[currentText];
		}
		while (curDialogue == null);

		if (curDialogue.text == null || curDialogue.text.length < 1) curDialogue.text = ' ';
		if (curDialogue.boxState == null) curDialogue.boxState = 'normal';
		if (curDialogue.speed == null || Math.isNaN(curDialogue.speed)) curDialogue.speed = 0.05;

		var animName:String = curDialogue.boxState;
		var boxType:String = textBoxTypes[0];

		for (i in 0...textBoxTypes.length)
		{
			if (textBoxTypes[i] == animName) {
				boxType = animName;
			}
		}

		var character:Int = 0;
		box.alpha = 1;

		for (i in 0...arrayCharacters.length)
		{
			if (arrayCharacters[i].curCharacter == curDialogue.portrait)
			{
				character = i;
				break;
			}
		}

		var centerPrefix:String = '';
		var lePosition:String = arrayCharacters[character].jsonFile.dialogue_pos;

		if (lePosition == 'center') centerPrefix = 'center-';

		if (character != lastCharacter)
		{
			box.playAnim(centerPrefix + boxType + 'Open', true);
			updateBoxOffsets(box);

			box.flipX = (lePosition == 'left');
		}
		else if (boxType != lastBoxType)
		{
			box.playAnim(centerPrefix + boxType, true);
			updateBoxOffsets(box);
		}

		lastCharacter = character;
		lastBoxType = boxType;

		daText.delay = curDialogue.speed / PlayState.instance.playbackRate;

		if (curDialogue.sound != null && curDialogue.sound.length > 0 && curDialogue.sound.trim() != '') {
			daText.sound = curDialogue.sound;
		}
		else {
			daText.sound = 'dialogue';
		}

		daText.text = curDialogue.text;

		daText.y = DEFAULT_TEXT_Y;
		if (daText.rows > 2) daText.y -= LONG_TEXT_ADD;

		var char:DialogueCharacter = arrayCharacters[character];

		if (char != null)
		{
			char.playAnim(curDialogue.expression, daText.finishedText);

			if (char.animation.curAnim != null)
			{
				var rate:Float = 24 - (((curDialogue.speed - 0.05) / 5) * 480);

				if (rate < 12) {
					rate = 12;
				}
				else if (rate > 48) {
					rate = 48;
				}

				char.animation.curAnim.frameRate = rate;
			}
		}

		currentText++;

		if (nextDialogueThing != null) {
			nextDialogueThing();
		}
	}

	public static function parseDialogue(path:String):DialogueFile
	{
		return cast Json.parse(Paths.getTextFromFile(path));
	}

	public static function updateBoxOffsets(box:Sprite):Void //Had to make it static because of the editors
	{
		box.centerOffsets();
		box.updateHitbox();

		if (box.animation.curAnim.name.startsWith('angry')) {
			box.offset.set(50, 65);
		}
		else if (box.animation.curAnim.name.startsWith('center-angry')) {
			box.offset.set(50, 30);
		}
		else {
			box.offset.set(10, 0);
		}
		
		if (!box.flipX) box.offset.y += 10;
	}
}