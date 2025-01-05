package;

#if DISCORD_ALLOWED
import Discord.DiscordClient;
#end

import flixel.FlxG;
import flixel.FlxObject;
import flixel.util.FlxAxes;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxTimer;
import flixel.util.FlxColor;

using StringTools;

class GameOverSubState extends MusicBeatSubState
{
	public var boyfriend:Character;

	var camFollow:FlxObject;
	var moveCamera:Bool = false;

	public var camDeath:SwagCamera;

	public static var danceDelay:Int = ClientPrefs.danceOffset;
	public static var cameraSpeed:Float = 1; // Camera Speed after fractures of the boyfriend's skeleton
	public static var bpm:Float = 100; // BPM on game over
	public static var timeToShake:Float = 0; // Time to camera shake
	public static var timeToStartFlashing:Float = 0; // Time to first flashing
	public static var allowFading:Bool = true; // Allows fade in/flashing on game over screen
	public static var allowShaking:Bool = true; // Allows shaking camera on game over screen
	public static var finishFlashingEnabled:Bool = true; // Allows flashing camera then restarting game
	public static var shakeAxe:String = 'y'; // Axe of shaking camera on game over screen
	public static var shakeDuration:Float = 0.3; // Duration of shaking
	public static var fadeDurationStart:Float = 0.85; // Duration of fade in on start of game over screen
	public static var fadeDurationMicDown:Float = 0.85; // Duration of fade in then finished timer with duration from variable `flashStart`
	public static var fadeDurationConfirm:Float = 1.4; // Duration of fade in then on confirm to end game over screen
	public static var confirmFadeOutDuration:Float = 2.3; // Duration of fade out then on finished timer with duration from variable `startConfirmFadeOut`
	public static var colorOnFadeOut:FlxColor = FlxColor.BLACK; // Color of fade out then on confirm to end game over screen
	public static var startConfirmFadeOut:Float = 0.7; // Time of timer then on confirm to end game over screen
	public static var colorStartFlash:FlxColor = FlxColor.RED; // Color of fade in then start of the game over screen
	public static var colorFlash:FlxColor = FlxColor.WHITE; // Color of fade in then finished timer with duration from variable `flashStart`
	public static var colorConfirmFlash:FlxColor = 0x85FFFFFF; // Color of fade in then on confirm to end game over screen
	public static var flashStart:Float = 1; // Time of timer to fade in or stuff, To disable, set the variable's value to -1
	public static var micDownStart:Float = 1; // Time of timer to mic down or stuff, To disable, set the variable's value to -1
	public static var characterName:String = 'bf-dead';
	public static var deathSoundName:String = 'fnf_loss_sfx';
	public static var loopSoundName:String = 'gameOver';
	public static var endSoundName:String = 'gameOverEnd';
	public static var deathDelay:Float = 0;

	public function new(?playStateBoyfriend:Character = null):Void
	{
		if (playStateBoyfriend != null && playStateBoyfriend.curCharacter == characterName) // Avoids spawning a second boyfriend cuz animate atlas is laggy
			this.boyfriend = playStateBoyfriend;

		super();
	}

	public static function resetVariables():Void
	{
		danceDelay = ClientPrefs.danceOffset;
		bpm = 100;
		allowFading = true;
		allowShaking = true;
		shakeAxe = 'y';
		shakeDuration = 0.3;
		fadeDurationStart = 0.85;
		fadeDurationMicDown = 0.85;
		fadeDurationConfirm = 1.4;
		confirmFadeOutDuration = 2;
		colorOnFadeOut = FlxColor.BLACK;
		startConfirmFadeOut = 0.7;
		colorStartFlash = FlxColor.RED;
		colorFlash = FlxColor.WHITE;
		colorConfirmFlash = 0x85FFFFFF;
		flashStart = 1;
		micDownStart = 1;
		characterName = 'bf-dead';
		deathSoundName = 'fnf_loss_sfx';
		loopSoundName = 'gameOver';
		endSoundName = 'gameOverEnd';
		deathDelay = 0;
	}

	public static var instance:GameOverSubState;

	var randomGameover:Int = 1;

	var overlay:Sprite;
	var overlayConfirmOffsets:FlxPoint = FlxPoint.get();

	override function create():Void
	{
		instance = this;

		Conductor.bpm = bpm;
		Conductor.songPosition = 0;

		camDeath = new SwagCamera();
		camDeath.bgColor.alpha = 0;
		camDeath.zoom = FlxG.camera.zoom;
		FlxG.cameras.add(camDeath, false);

		if (boyfriend == null)
		{
			boyfriend = new Character(PlayState.instance.boyfriend.getScreenPosition().x, PlayState.instance.boyfriend.getScreenPosition().y, characterName, true);
			boyfriend.x += boyfriend.positionArray[0] - PlayState.instance.boyfriend.positionArray[0];
			boyfriend.y += boyfriend.positionArray[1] - PlayState.instance.boyfriend.positionArray[1];
		}

		boyfriend.cameras = [camDeath];
		add(boyfriend);

		FlxG.sound.play(Paths.getSound(deathSoundName));

		if (allowShaking)
		{
			if (timeToShake > 0)
			{
				new FlxTimer().start(timeToShake, function(tmr:FlxTimer):Void {
					camDeath.shake(0.02, shakeDuration, null, true, FlxAxes.fromString(shakeAxe));
				});
			}
			else {
				camDeath.shake(0.02, shakeDuration, null, true, FlxAxes.fromString(shakeAxe));
			}
		}

		FlxG.camera.scroll.set();
		FlxG.camera.target = null;

		if (allowFading)
		{
			if (timeToStartFlashing > 0)
			{
				new FlxTimer().start(timeToStartFlashing, function(tmr:FlxTimer):Void
				{
					colorStartFlash.alphaFloat -= (!ClientPrefs.flashingLights ? (colorStartFlash.alphaFloat / 2) : 0);
					FlxG.camera.fade(colorStartFlash, fadeDurationStart, true);
				});
			}
			else
			{
				colorStartFlash.alphaFloat -= (!ClientPrefs.flashingLights ? (colorStartFlash.alphaFloat / 2) : 0);
				FlxG.camera.fade(colorStartFlash, fadeDurationStart, true);
			}
		}

		boyfriend.playAnim('firstDeath');

		camFollow = new FlxObject(0, 0, 1, 1);

		final pos:FlxPoint = boyfriend.getGraphicMidpoint();

		camFollow.setPosition(pos.x + boyfriend.cameraPosition[0], pos.y + boyfriend.cameraPosition[1]);
		pos.put();

		camDeath.focusOn(FlxPoint.get(FlxG.camera.scroll.x + (FlxG.camera.width / 2), FlxG.camera.scroll.y + (FlxG.camera.height / 2)));
		add(camFollow);

		if (micDownStart > 0)
		{
			new FlxTimer().start(micDownStart, function(tmr:FlxTimer):Void {
				micIsDown = true;
			});
		}

		if (flashStart > 0)
		{
			new FlxTimer().start(flashStart, function(tmr:FlxTimer):Void
			{
				if (allowFading)
				{
					colorFlash.alphaFloat -= (!ClientPrefs.flashingLights ? (colorFlash.alphaFloat / 2) : 0);
					FlxG.camera.fade(colorFlash, fadeDurationMicDown, true);
				}
			});
		}

		if (characterName == 'pico-dead')
		{
			overlay = new Sprite(boyfriend.x + 205, boyfriend.y - 80);
			overlay.frames = Paths.getSparrowAtlas('Pico_Death_Retry');
			overlay.animation.addByPrefix('deathLoop', 'Retry Text Loop', 24, true);
			overlay.animation.addByPrefix('deathConfirm', 'Retry Text Confirm', 24, false);
			overlayConfirmOffsets.set(250, 200);
			overlay.visible = false;
			overlay.cameras = [camDeath];
			add(overlay);

			boyfriend.animation.callback = function(name:String, frameNumber:Int, frameIndex:Int):Void
			{
				switch (name)
				{
					case 'firstDeath':
					{
						if (frameNumber >= 36 - 1)
						{
							overlay.visible = true;
							overlay.playAnim('deathLoop');
							boyfriend.animation.callback = null;
						}
					}
					default: boyfriend.animation.callback = null;
				}
			}

			if (PlayState.instance.gf != null && PlayState.instance.gf.curCharacter == 'nene')
			{
				var neneKnife:Sprite = new Sprite(boyfriend.x - 450, boyfriend.y - 250);
				neneKnife.frames = Paths.getSparrowAtlas('NeneKnifeToss');
				neneKnife.animation.addByPrefix('anim', 'knife toss', 24, false);
				neneKnife.cameras = [camDeath];
				neneKnife.animation.finishCallback = function(_):Void
				{
					remove(neneKnife);
					neneKnife.destroy();
				}
				insert(0, neneKnife);

				neneKnife.playAnim('anim', true);
			}
		}

		camDeath.follow(camFollow, LOCKON, 0.6);
		randomGameover = FlxG.random.int(1, 25);

		PlayState.instance.callOnScripts('onGameOverStart', []);
		PlayState.instance.setOnScripts('inGameOver', true);

		super.create();
	}

	public var micIsDown:Bool = false;

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		PlayState.instance.callOnScripts('onUpdate', [elapsed]);

		var justPlayedLoop:Bool = false;

		if (!boyfriend.isAnimationNull() && boyfriend.getAnimationName() == 'firstDeath' && boyfriend.isAnimationFinished())
		{
			boyfriend.playAnim('deathLoop');

			if (overlay != null && overlay.animation.exists('deathLoop'))
			{
				overlay.visible = true;
				overlay.playAnim('deathLoop');
			}

			justPlayedLoop = true;
		}

		if (!isEnding)
		{
			var mousePoint:FlxPoint = FlxG.mouse.getScreenPosition(boyfriend.camera);
			var objPoint:FlxPoint = boyfriend.getScreenPosition(null, boyfriend.camera);

			var bullShit:Bool = mousePoint.x >= objPoint.x && mousePoint.y >= objPoint.y && mousePoint.x < objPoint.x + boyfriend.width && mousePoint.y < objPoint.y + boyfriend.height;

			if (controls.ACCEPT_P || (FlxG.mouse.justPressed && bullShit)) {
				endBullshit();
			}
			else if (controls.BACK_P)
			{
				#if DISCORD_ALLOWED
				DiscordClient.resetClientID(); #end

				FlxG.camera.visible = false;
				PlayState.instance.stopMusic();

				PlayState.deathCounter = 0;
				PlayState.seenCutscene = false;
				PlayState.usedPractice = false;
				PlayState.chartingMode = false;
				PlayState.changedDifficulty = false;

				PlayState.firstSong = null;

				Paths.loadTopMod();

				FlxG.camera.fade(FlxColor.BLACK, FlxMath.EPSILON);

				switch (PlayState.gameMode)
				{
					case 'story':
						FlxG.switchState(new StoryMenuState());
					case 'freeplay':
						FlxG.switchState(new FreeplayMenuState());
					default:
						FlxG.switchState(new MainMenuState());
				}
			}
			else if (justPlayedLoop)
			{
				switch (PlayState.storyWeek)
				{
					case 7:
					{
						coolStartDeath(0.2);

						FlxG.sound.play(Paths.getSound('jeffGameover/jeffGameover-' + randomGameover), 1, false, null, true, function():Void
						{
							if (!isEnding) {
								FlxG.sound.music.fadeIn(4, 0.2, 1);
							}
						});
					}
					default: coolStartDeath();
				}
			}
		}

		PlayState.instance.callOnScripts('onUpdatePost', [elapsed]);
	}

	function coolStartDeath(?vol:Float = 1):Void
	{
		if (!isEnding) {
			FlxG.sound.playMusic(Paths.getMusic(loopSoundName), vol);
		}
	}

	var isEnding:Bool = false;

	function endBullshit():Void
	{
		if (!isEnding)
		{
			isEnding = true;

			if (allowFading && finishFlashingEnabled)
			{
				colorConfirmFlash.alphaFloat -= (!ClientPrefs.flashingLights ? (colorConfirmFlash.alphaFloat / 2) : 0);
				FlxG.camera.fade(colorConfirmFlash, fadeDurationConfirm, true);
			}

			if (boyfriend.hasAnimation('deathConfirm')) {
				boyfriend.playAnim('deathConfirm', true);
			}
			else if (boyfriend.hasAnimation('deathLoop')) {
				boyfriend.playAnim('deathLoop', true);
			}

			if (overlay != null && overlay.animation.exists('deathConfirm'))
			{
				overlay.visible = true;
				overlay.playAnim('deathConfirm');
				overlay.offset.set(overlayConfirmOffsets.x, overlayConfirmOffsets.y);
			}

			PlayState.instance.stopMusic();
			FlxG.sound.play(Paths.getMusic(endSoundName));

			new FlxTimer().start(startConfirmFadeOut, function(tmr:FlxTimer):Void
			{
				camDeath.fade(colorOnFadeOut, confirmFadeOutDuration, false, function():Void
				{
					StageData.loadDirectory(PlayState.SONG);
					LoadingState.loadAndSwitchState(new PlayState(), true);
				});
			});

			PlayState.instance.callOnScripts('onGameOverConfirm', [true]);
		}
	}

	override function destroy():Void
	{
		instance = null;
		super.destroy();
	}
}
