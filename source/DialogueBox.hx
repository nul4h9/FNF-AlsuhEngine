package;

import flixel.FlxG;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.group.FlxSpriteGroup;
import flixel.addons.text.FlxTypeText;

using StringTools;

class DialogueBox extends FlxSpriteGroup
{
	var box:Sprite;

	var curCharacter:String = '';
	var dialogueList:Array<String> = [];
	var swagDialogue:FlxTypeText;
	var dropText:FlxText;

	public var finishThing:Void->Void = null;
	public var typeThing:Void->Void = null;
	public var nextDialogueThing:Void->Void = null;
	public var skipDialogueThing:Void->Void = null;

	var portraitLeft:Sprite;
	var portraitRight:Sprite;

	var handSelect:Sprite;
	var bgFade:Sprite;

	public function new(talkingRight:Bool = true, ?dialogueList:Array<String>):Void
	{
		super();

		Paths.getSound('pixelText');

		switch (PlayState.SONG.songID)
		{
			case 'senpai':
			{
				FlxG.sound.playMusic(Paths.getMusic('Lunchbox'), 0);
				#if FLX_PITCH
				FlxG.sound.music.pitch = PlayState.instance.playbackRate;
				#end
				FlxG.sound.music.fadeIn(1, 0, 0.8);
			}
			case 'thorns':
			{
				FlxG.sound.playMusic(Paths.getMusic('LunchboxScary'), 0);
				#if FLX_PITCH
				FlxG.sound.music.pitch = PlayState.instance.playbackRate;
				#end
				FlxG.sound.music.fadeIn(1, 0, 0.8);
			}
		}

		bgFade = new Sprite(-200, -200);
		bgFade.makeGraphic(Std.int(FlxG.width * 1.3), Std.int(FlxG.height * 1.3), 0xFFB3DFd8);
		bgFade.scrollFactor.set();
		bgFade.alpha = 0;
		add(bgFade);

		new FlxTimer().start(0.83 / PlayState.instance.playbackRate, function(tmr:FlxTimer):Void
		{
			bgFade.alpha += (1 / 5) * 0.7;

			if (bgFade.alpha > 0.7) {
				bgFade.alpha = 0.7;
			}
		}, 5);
		
		portraitLeft = new Sprite(-20, 40);
		portraitLeft.frames = Paths.getSparrowAtlas('weeb/senpaiPortrait');
		portraitLeft.animation.addByPrefix('enter', 'Senpai Portrait Enter', 24, false);
		portraitLeft.setGraphicSize(Std.int(portraitLeft.width * PlayState.daPixelZoom * 0.9));
		portraitLeft.updateHitbox();
		portraitLeft.scrollFactor.set();
		portraitLeft.antialiasing = false;
		portraitLeft.visible = false;
		add(portraitLeft);

		portraitRight = new Sprite(0, 40);
		portraitRight.frames = Paths.getSparrowAtlas('weeb/bfPortrait');
		portraitRight.animation.addByPrefix('enter', 'Boyfriend portrait enter', 24, false);
		portraitRight.setGraphicSize(Std.int(portraitRight.width * PlayState.daPixelZoom * 0.9));
		portraitRight.updateHitbox();
		portraitRight.scrollFactor.set();
		portraitRight.antialiasing = false;
		portraitRight.visible = false;
		add(portraitRight);

		box = new Sprite(-20, 45);
		
		var hasDialog:Bool = false;

		switch (PlayState.SONG.songID)
		{
			case 'senpai':
			{
				hasDialog = true;

				box.frames = Paths.getSparrowAtlas('weeb/pixelUI/dialogueBox-pixel');
				box.animation.addByPrefix('normalOpen', 'Text Box Appear', 24, false);
				box.animation.addByIndices('normal', 'Text Box Appear', [4], "", 24);
			}
			case 'roses':
			{
				hasDialog = true;

				FlxG.sound.play(Paths.getSound('ANGRY_TEXT_BOX'));

				box.frames = Paths.getSparrowAtlas('weeb/pixelUI/dialogueBox-senpaiMad');
				box.animation.addByPrefix('normalOpen', 'SENPAI ANGRY IMPACT SPEECH', 24, false);
				box.animation.addByIndices('normal', 'SENPAI ANGRY IMPACT SPEECH', [4], "", 24);
			}
			case 'thorns':
			{
				hasDialog = true;

				box.frames = Paths.getSparrowAtlas('weeb/pixelUI/dialogueBox-evil');
				box.animation.addByPrefix('normalOpen', 'Spirit Textbox spawn', 24, false);
				box.animation.addByIndices('normal', 'Spirit Textbox spawn', [11], "", 24);

				var face:Sprite = new Sprite(320, 170);
				face.loadGraphic(Paths.getImage('weeb/spiritFaceForward'));
				face.setGraphicSize(Std.int(face.width * 6));
				face.antialiasing = false;
				add(face);
			}
		}

		this.dialogueList = dialogueList;
		
		if (!hasDialog) return;
		
		box.playAnim('normalOpen');
		box.setGraphicSize(Std.int(box.width * PlayState.daPixelZoom * 0.9));
		box.updateHitbox();
		box.antialiasing = false;
		add(box);

		box.screenCenter(X);
		portraitLeft.screenCenter(X);

		handSelect = new Sprite(1042, 590);
		handSelect.loadGraphic(Paths.getImage('weeb/pixelUI/hand_textbox'));
		handSelect.setGraphicSize(Std.int(handSelect.width * PlayState.daPixelZoom * 0.9));
		handSelect.updateHitbox();
		handSelect.visible = false;
		handSelect.antialiasing = false;
		add(handSelect);

		dropText = new FlxText(242, 502, Std.int(FlxG.width * 0.6), "", 32);
		dropText.font = Paths.getFont('pixel.otf');
		dropText.color = 0xFFD89494;
		add(dropText);

		swagDialogue = new FlxTypeText(240, 500, Std.int(FlxG.width * 0.6), "", 32);
		swagDialogue.font = Paths.getFont('pixel.otf');
		swagDialogue.color = 0xFF3F2021;
		swagDialogue.typingCallback = function():Void
		{
			FlxG.sound.play(Paths.getSound('pixelText'), 0.6) #if FLX_PITCH .pitch = PlayState.instance.playbackRate #end;

			if (typeThing != null) {
				typeThing();
			}
		}

		add(swagDialogue);
	}

	var dialogueOpened:Bool = false;
	var dialogueStarted:Bool = false;
	var dialogueEnded:Bool = false;

	override function update(elapsed:Float)
	{
		switch (PlayState.SONG.songID)
		{
			case 'roses': portraitLeft.visible = false;
			case 'thorns':
			{
				portraitLeft.visible = false;
				swagDialogue.color = FlxColor.WHITE;
				dropText.color = FlxColor.BLACK;
			}
		}

		dropText.text = swagDialogue.text;

		if (box.animation.curAnim != null)
		{
			if (box.animation.curAnim.name == 'normalOpen' && box.animation.curAnim.finished)
			{
				if (box.animation.getByName('normal') != null) {
					box.playAnim('normal');
				}

				dialogueOpened = true;
			}
		}

		if (dialogueOpened && !dialogueStarted)
		{
			startDialogue();
			dialogueStarted = true;
		}

		var controls:Controls = Controls.instance;

		if (controls.ACCEPT_P)
		{
			if (dialogueEnded)
			{
				if (dialogueList[1] == null && dialogueList[0] != null)
				{
					if (!isEnding)
					{
						isEnding = true;
						FlxG.sound.play(Paths.getSound('clickText'), 0.8) #if FLX_PITCH .pitch = PlayState.instance.playbackRate #end;

						switch (PlayState.SONG.songID)
						{
							case 'senpai' | 'thorns':
								FlxG.sound.music.fadeOut(2.2, 0);
						}

						new FlxTimer().start(0.2 / PlayState.instance.playbackRate, function(tmr:FlxTimer):Void
						{
							box.alpha -= 1 / 5;
							bgFade.alpha -= 1 / 5 * 0.7;
							portraitLeft.visible = false;
							portraitRight.visible = false;
							swagDialogue.alpha -= 1 / 5;
							handSelect.alpha -= 1 / 5;
							dropText.alpha = swagDialogue.alpha;
						}, 5);

						new FlxTimer().start(1.2 / PlayState.instance.playbackRate, function(tmr:FlxTimer):Void
						{
							if (finishThing != null) {
								finishThing();
							}

							kill();
						});
					}
				}
				else
				{
					FlxG.sound.play(Paths.getSound('clickText'), 0.8) #if FLX_PITCH .pitch = PlayState.instance.playbackRate #end;

					dialogueList.remove(dialogueList[0]);
					startDialogue();
				}
			}
			else if (dialogueStarted)
			{
				FlxG.sound.play(Paths.getSound('clickText'), 0.8) #if FLX_PITCH .pitch = PlayState.instance.playbackRate #end;
				swagDialogue.skip();

				if (skipDialogueThing != null) {
					skipDialogueThing();
				}
			}
		}

		super.update(elapsed);
	}

	var isEnding:Bool = false;

	function startDialogue():Void
	{
		cleanDialog();

		swagDialogue.resetText(dialogueList[0]);
		swagDialogue.start(0.04 / PlayState.instance.playbackRate, true);
		swagDialogue.completeCallback = function():Void
		{
			handSelect.visible = true;
			dialogueEnded = true;
		};

		handSelect.visible = false;
		dialogueEnded = false;

		switch (curCharacter)
		{
			case 'dad':
			{
				portraitRight.visible = false;

				if (!portraitLeft.visible)
				{
					if (PlayState.SONG.songID == 'senpai') portraitLeft.visible = true;
					portraitLeft.playAnim('enter');
				}
			}
			case 'bf':
			{
				portraitLeft.visible = false;

				if (!portraitRight.visible)
				{
					portraitRight.visible = true;
					portraitRight.playAnim('enter');
				}
			}
		}

		if (nextDialogueThing != null) {
			nextDialogueThing();
		}
	}

	function cleanDialog():Void
	{
		var splitName:Array<String> = dialogueList[0].split(':');
		curCharacter = splitName[1];
		dialogueList[0] = dialogueList[0].substr(splitName[1].length + 2).trim();
	}
}