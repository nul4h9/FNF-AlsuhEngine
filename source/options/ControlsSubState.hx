package options;

#if DISCORD_ALLOWED
import Discord.DiscordClient;
#end

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.group.FlxGroup;
import flixel.sound.FlxSound;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.effects.FlxFlicker;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.gamepad.FlxGamepadManager;

using StringTools;

class ControlsSubState extends MusicBeatSubState
{
	var curSelected:Int = 0;
	var curAlt:Bool = false;

	var options:Array<Dynamic> = [ // Show on gamepad - Display name - Save file key - Rebind display name
		[true, 'NOTES'],
		[true, 'Left', 'note_left', 'Note Left'],
		[true, 'Down', 'note_down', 'Note Down'],
		[true, 'Up', 'note_up', 'Note Up'],
		[true, 'Right', 'note_right', 'Note Right'],
		[true],
		[true, 'UI'],
		[true, 'Left', 'ui_left', 'UI Left'],
		[true, 'Down', 'ui_down', 'UI Down'],
		[true, 'Up', 'ui_up', 'UI Up'],
		[true, 'Right', 'ui_right', 'UI Right'],
		[true],
		[true, 'Reset', 'reset', 'Reset'],
		[true, 'Accept', 'accept', 'Accept'],
		[true, 'Back', 'back', 'Back'],
		[true, 'Pause', 'pause', 'Pause'],
		[false],
		[false, 'VOLUME'],
		[false, 'Mute', 'volume_mute', 'Volume Mute'],
		[false, 'Up', 'volume_up', 'Volume Up'],
		[false, 'Down', 'volume_down', 'Volume Down'],
		[false],
		[false, 'DEBUG'],
		[false, 'Key 1', 'debug_1', 'Debug Key #1'],
		[false, 'Key 2', 'debug_2', 'Debug Key #2']
	];

	var curOptions:Array<Int>;
	var curOptionsValid:Array<Int>;

	private static var defaultKey:String = 'Reset to Default Keys';

	var grpDisplay:FlxTypedGroup<Alphabet>;
	var grpBlacks:FlxTypedGroup<AttachedSprite>;
	var grpOptions:FlxTypedGroup<Alphabet>;
	var grpBinds:FlxTypedGroup<Alphabet>;
	var selectSpr:AttachedSprite;

	var gamepadColor:FlxColor = 0xfffd7194;
	var keyboardColor:FlxColor = 0xff7192fd;
	var onKeyboardMode:Bool = true;

	var controllerSpr:Sprite;

	public function new():Void
	{
		super();

		options.push([true]);
		options.push([true]);
		options.push([true, defaultKey]);

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("In the Options Menu - Controls");
		#end

		grpDisplay = new FlxTypedGroup<Alphabet>();
		add(grpDisplay);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		grpBlacks = new FlxTypedGroup<AttachedSprite>();
		add(grpBlacks);

		selectSpr = new AttachedSprite();
		selectSpr.makeGraphic(250, 78, FlxColor.WHITE);
		selectSpr.copyAlpha = false;
		selectSpr.alpha = 0.75;
		add(selectSpr);

		grpBinds = new FlxTypedGroup<Alphabet>();
		add(grpBinds);

		controllerSpr = new Sprite(50, 40);

		if (Paths.fileExists('images/controllertype.png', IMAGE)) {
			controllerSpr.loadGraphic(Paths.getImage('controllertype'), true, 82, 60);
		}
		else {
			controllerSpr.loadGraphic(Paths.getImage('ui/controllertype'), true, 82, 60);
		}

		controllerSpr.animation.add('keyboard', [0], 1, false);
		controllerSpr.animation.add('gamepad', [1], 1, false);
		add(controllerSpr);

		var text:Alphabet = new Alphabet(60, 90, 'CTRL', false);
		text.alignment = CENTERED;
		text.setScale(0.4);
		add(text);

		createTexts();
	}

	var lastID:Int = 0;

	function createTexts():Void
	{
		curOptions = [];
		curOptionsValid = [];

		grpDisplay.forEachAlive(function(text:Alphabet):Void text.destroy());
		grpBlacks.forEachAlive(function(black:AttachedSprite):Void black.destroy());
		grpOptions.forEachAlive(function(text:Alphabet):Void text.destroy());
		grpBinds.forEachAlive(function(text:Alphabet):Void text.destroy());

		grpDisplay.clear();
		grpBlacks.clear();

		grpOptions.clear();
		grpBinds.clear();

		var myID:Int = 0;

		for (i in 0...options.length)
		{
			var option:Array<Dynamic> = options[i];

			if (option[0] || onKeyboardMode)
			{
				if (option.length > 1)
				{
					var isCentered:Bool = (option.length < 3);
					var isDefaultKey:Bool = (option[1] == defaultKey);

					var text:Alphabet = new Alphabet(200, 300, option[1], true);
					text.isMenuItem = true;
					text.changeX = false;
					text.distancePerItem.y = 60;
					text.targetY = myID;

					if (isCentered && !isDefaultKey) {
						grpDisplay.add(text);
					}
					else
					{
						grpOptions.add(text);
						curOptions.push(i);
						curOptionsValid.push(myID);
					}

					text.ID = myID;
					lastID = myID;

					if (isCentered) {
						addCenteredText(text, option, myID);
					}
					else addKeyText(text, option, myID);

					text.snapToPosition();
					text.y += FlxG.height * 2;
				}

				myID++;
			}
		}

		updateText();
	}

	function addCenteredText(text:Alphabet, option:Array<Dynamic>, id:Int):Void
	{
		text.screenCenter(X);
		text.y -= 55;
		text.startPosition.y -= 55;
	}

	function addKeyText(text:Alphabet, option:Array<Dynamic>, id:Int):Void
	{
		for (n in 0...2)
		{
			var textX:Float = 350 + n * 300;
			var key:String = null;

			switch (onKeyboardMode)
			{
				case true:
				{
					var savKey:Array<FlxKey> = ClientPrefs.keyBinds.get(option[2]);
					var gottenKey:Null<FlxKey> = savKey[n];
	
					var newKey:FlxKey = (gottenKey != null) ? gottenKey : NONE;
					key = InputFormatter.getKeyName(newKey);
				}
				case false:
				{
					var savKey:Array<FlxGamepadInputID> = ClientPrefs.gamepadBinds.get(option[2]);
					var gottenKey:Null<FlxGamepadInputID> = savKey[n];
	
					var newKey:FlxGamepadInputID = (gottenKey != null) ? gottenKey : NONE;
					key = InputFormatter.getGamepadName(newKey);
				}
			}

			var attach:Alphabet = new Alphabet(textX + 210, 248, key, false);
			attach.isMenuItem = true;
			attach.changeX = false;
			attach.distancePerItem.y = 60;
			attach.targetY = text.targetY;
			attach.ID = Math.floor(grpBinds.length / 2);
			attach.snapToPosition();
			attach.y += FlxG.height * 2;
			grpBinds.add(attach);

			playstationCheck(attach);
			attach.scaleX = Math.min(1, 230 / attach.width);

			var black:AttachedSprite = new AttachedSprite();
			black.makeGraphic(250, 78, FlxColor.BLACK);
			black.alphaMult = 0.4;
			black.sprTracker = text;
			black.yAdd = -6;
			black.xAdd = textX;
			grpBlacks.add(black);
		}
	}

	function playstationCheck(alpha:Alphabet):Void
	{
		if (onKeyboardMode) return;

		var gamepad:FlxGamepad = FlxG.gamepads.firstActive;
		var model:FlxGamepadModel = gamepad != null ? gamepad.detectedModel : UNKNOWN;
		var letter = alpha.letters[0];

		if (model == PS4)
		{
			switch (alpha.text)
			{
				case '[', ']': //Square and Triangle respectively
				{
					var path:String = 'ui/alphabet_playstation';
					if (Paths.fileExists('images/alphabet_playstation.png', IMAGE)) path = 'alphabet_playstation';

					letter.image = path;
					letter.updateHitbox();
					
					letter.offset.x += 4;
					letter.offset.y -= 5;
				}
			}
		}
	}

	function updateBind(num:Int, text:String):Void
	{
		var bind:Alphabet = grpBinds.members[num];

		var attach:Alphabet = new Alphabet(350 + (num % 2) * 300, 248, text, false);
		attach.isMenuItem = true;
		attach.changeX = false;
		attach.distancePerItem.y = 60;
		attach.targetY = bind.targetY;
		attach.ID = bind.ID;
		attach.x = bind.x;
		attach.y = bind.y;

		playstationCheck(attach);
		attach.scaleX = Math.min(1, 230 / attach.width);

		bind.kill();
		grpBinds.remove(bind);
		grpBinds.insert(num, attach);
		bind.destroy();
	}

	var binding:Bool = false;
	var holdingEsc:Float = 0;
	var bindingBlack:Sprite;
	var bindingText:Alphabet;
	var bindingText2:Alphabet;

	var timeForMoving:Float = 0.1;

	override function update(elapsed:Float):Void
	{
		if (timeForMoving > 0) // Fix controller bug
		{
			timeForMoving = Math.max(0, timeForMoving - elapsed);

			super.update(elapsed);
			return;
		}

		if (!binding)
		{
			if (FlxG.keys.justPressed.ESCAPE || FlxG.gamepads.anyJustPressed(B))
			{
				ClientPrefs.saveBinds();
				FlxG.sound.play(Paths.getSound('cancelMenu'));

				close();

				return;
			}

			if (FlxG.keys.justPressed.CONTROL || FlxG.gamepads.anyJustPressed(LEFT_SHOULDER) || FlxG.gamepads.anyJustPressed(RIGHT_SHOULDER)) {
				swapMode();
			}

			if (FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.RIGHT || FlxG.gamepads.anyJustPressed(DPAD_LEFT) || FlxG.gamepads.anyJustPressed(DPAD_RIGHT) ||
				FlxG.gamepads.anyJustPressed(LEFT_STICK_DIGITAL_LEFT) || FlxG.gamepads.anyJustPressed(LEFT_STICK_DIGITAL_RIGHT)) updateAlt(true);

			if (FlxG.keys.justPressed.UP || FlxG.gamepads.anyJustPressed(DPAD_UP) || FlxG.gamepads.anyJustPressed(LEFT_STICK_DIGITAL_UP)) {
				updateText(-1);
			}
			else if (FlxG.keys.justPressed.DOWN || FlxG.gamepads.anyJustPressed(DPAD_DOWN) || FlxG.gamepads.anyJustPressed(LEFT_STICK_DIGITAL_DOWN)) {
				updateText(1);
			}

			if (FlxG.keys.justPressed.ENTER || FlxG.gamepads.anyJustPressed(START) || FlxG.gamepads.anyJustPressed(A))
			{
				var altNum:Int = curAlt ? 1 : 0;

				if (options[curOptions[curSelected]][1] != defaultKey)
				{
					var startRebinding:Void->Void = function():Void
					{
						bindingBlack = new Sprite();
						bindingBlack.makeGraphic(FlxG.width, FlxG.height, FlxColor.WHITE);
						bindingBlack.alpha = 0;
	
						FlxTween.tween(bindingBlack, {alpha: 0.6}, 0.35, {ease: FlxEase.linear});
						add(bindingBlack);
	
						bindingText = new Alphabet(FlxG.width / 2, 160, "Rebinding " + options[curOptions[curSelected]][3], false);
						bindingText.alignment = CENTERED;
						add(bindingText);
						
						bindingText2 = new Alphabet(FlxG.width / 2, 340, "Hold ESC to Cancel\nHold Backspace to Delete", true);
						bindingText2.alignment = CENTERED;
						add(bindingText2);
	
						binding = true;
						holdingEsc = 0;
	
						ClientPrefs.toggleVolumeKeys(false);
	
						FlxG.sound.play(Paths.getSound('scrollMenu'));
					}

					if (ClientPrefs.flashingLights)
					{
						FlxFlicker.flicker(grpBinds.members[Math.floor(curSelected * 2) + altNum], 1, 0.06, true, false, function(flk:FlxFlicker):Void {
							startRebinding();
						});

						FlxG.sound.play(Paths.getSound('confirmMenu'));
					}
					else {
						startRebinding();
					}
				}
				else
				{
					var resetToDefault:Void->Void = function():Void // Reset to Default
					{
						ClientPrefs.resetKeys(onKeyboardMode ? 'key' : 'gamepad');
						ClientPrefs.reloadVolumeKeys();
	
						var lastSel:Int = curSelected;
						createTexts();
	
						curSelected = lastSel;
						updateText();
	
						FlxG.sound.play(Paths.getSound('cancelMenu'));
					}

					if (ClientPrefs.flashingLights)
					{
						FlxFlicker.flicker(grpOptions.members[grpOptions.members.length - 1], 1, 0.06, true, false, function(flk:FlxFlicker):Void {
							resetToDefault();
						});

						FlxG.sound.play(Paths.getSound('confirmMenu'));
					}
					else {
						resetToDefault();
					}
				}
			}
		}
		else
		{
			var altNum:Int = curAlt ? 1 : 0;
			var curOption:Array<Dynamic> = options[curOptions[curSelected]];

			if (FlxG.keys.pressed.ESCAPE || FlxG.gamepads.anyPressed(B))
			{
				holdingEsc += elapsed;

				if (holdingEsc > 0.5)
				{
					FlxG.sound.play(Paths.getSound('cancelMenu'));
					closeBinding();
				}
			}
			else if (FlxG.keys.pressed.BACKSPACE || FlxG.gamepads.anyPressed(BACK))
			{
				holdingEsc += elapsed;

				if (holdingEsc > 0.5)
				{
					ClientPrefs.keyBinds.get(curOption[2])[altNum] = NONE;
					ClientPrefs.clearInvalidKeys(curOption[2]);

					var name:String = switch (onKeyboardMode)
					{
						case true: InputFormatter.getKeyName(NONE);
						case false: InputFormatter.getGamepadName(NONE);
						default: null;
					};

					updateBind(Math.floor(curSelected * 2) + altNum, name);

					FlxG.sound.play(Paths.getSound('cancelMenu'));
					closeBinding();
				}
			}
			else
			{
				holdingEsc = 0;

				var changed:Bool = false;
				var curKeys:Array<FlxKey> = ClientPrefs.keyBinds.get(curOption[2]);
				var curButtons:Array<FlxGamepadInputID> = ClientPrefs.gamepadBinds.get(curOption[2]);

				if (onKeyboardMode)
				{
					if (FlxG.keys.justPressed.ANY || FlxG.keys.justReleased.ANY)
					{
						var keyPressed:Int = FlxG.keys.firstJustPressed();
						var keyReleased:Int = FlxG.keys.firstJustReleased();

						if (keyPressed > -1 && keyPressed != FlxKey.ESCAPE && keyPressed != FlxKey.BACKSPACE)
						{
							curKeys[altNum] = keyPressed;
							changed = true;
						}
						else if (keyReleased > -1 && (keyReleased == FlxKey.ESCAPE || keyReleased == FlxKey.BACKSPACE))
						{
							curKeys[altNum] = keyReleased;
							changed = true;
						}
					}
				}
				else
				{
					if (FlxG.gamepads.anyJustPressed(ANY) || FlxG.gamepads.anyJustPressed(LEFT_TRIGGER) || FlxG.gamepads.anyJustPressed(RIGHT_TRIGGER) || FlxG.gamepads.anyJustReleased(ANY))
					{
						var keyPressed:Null<FlxGamepadInputID> = NONE;
						var keyReleased:Null<FlxGamepadInputID> = NONE;

						if (FlxG.gamepads.anyJustPressed(LEFT_TRIGGER)) {
							keyPressed = LEFT_TRIGGER; //it wasnt working for some reason
						}
						else if (FlxG.gamepads.anyJustPressed(RIGHT_TRIGGER)) {
							keyPressed = RIGHT_TRIGGER; //it wasnt working for some reason
						}
						else
						{
							for (i in 0...FlxG.gamepads.numActiveGamepads)
							{
								var gamepad:FlxGamepad = FlxG.gamepads.getByID(i);

								if (gamepad != null)
								{
									keyPressed = gamepad.firstJustPressedID();
									keyReleased = gamepad.firstJustReleasedID();

									if (keyPressed == null) keyPressed = NONE;
									if (keyReleased == null) keyReleased = NONE;
									if (keyPressed != NONE || keyReleased != NONE) break;
								}
							}
						}

						if (keyPressed != NONE && keyPressed != FlxGamepadInputID.BACK && keyPressed != FlxGamepadInputID.B)
						{
							curButtons[altNum] = keyPressed;
							changed = true;
						}
						else if (keyReleased != NONE && (keyReleased == FlxGamepadInputID.BACK || keyReleased == FlxGamepadInputID.B))
						{
							curButtons[altNum] = keyReleased;
							changed = true;
						}
					}
				}

				if (changed)
				{
					if (onKeyboardMode)
					{
						if (curKeys[altNum] == curKeys[1 - altNum]) {
							curKeys[1 - altNum] = FlxKey.NONE;
						}
					}
					else
					{
						if (curButtons[altNum] == curButtons[1 - altNum]) {
							curButtons[1 - altNum] = FlxGamepadInputID.NONE;
						}
					}

					var option:String = options[curOptions[curSelected]][2];
					ClientPrefs.clearInvalidKeys(option);

					for (n in 0...2)
					{
						var key:String = null;

						if (onKeyboardMode)
						{
							var savKey:Array<FlxKey> = ClientPrefs.keyBinds.get(option);
							var gottenKey:Null<FlxKey> = savKey[n];

							var newKey:FlxKey = (gottenKey != null) ? gottenKey : NONE;
							key = InputFormatter.getKeyName(newKey);
						}
						else
						{
							var savKey:Array<FlxGamepadInputID> = ClientPrefs.gamepadBinds.get(option);
							var gottenKey:Null<FlxGamepadInputID> = savKey[n];

							var newKey:FlxGamepadInputID = (gottenKey != null) ? gottenKey : NONE;
							key = InputFormatter.getGamepadName(newKey);
						}

						updateBind(Math.floor(curSelected * 2) + n, key);
					}

					FlxG.sound.play(Paths.getSound('confirmMenu'));
					closeBinding();
				}
			}
		}

		super.update(elapsed);
	}

	function closeBinding():Void
	{
		binding = false;
		bindingBlack.destroy();
		remove(bindingBlack);

		bindingText.destroy();
		remove(bindingText);

		bindingText2.destroy();
		remove(bindingText2);

		ClientPrefs.reloadVolumeKeys();
	}

	function updateText(?move:Int = 0):Void
	{
		if (move != 0) {
			curSelected = FlxMath.wrap(curSelected + move, 0, curOptions.length - 1);
		}

		var num:Int = curOptionsValid[curSelected];
		var addNum:Int = 0;

		if (num < 3) addNum = 3 - num;
		else if (num > lastID - 4) addNum = (lastID - 4) - num;

		grpDisplay.forEachAlive(function(item:Alphabet):Void {
			item.targetY = item.ID - num - addNum;
		});

		grpOptions.forEachAlive(function(item:Alphabet):Void
		{
			item.targetY = item.ID - num - addNum;
			item.alpha = (item.ID - num == 0) ? 1 : 0.6;
		});

		grpBinds.forEachAlive(function(item:Alphabet):Void
		{
			var parent:Alphabet = grpOptions.members[item.ID];
			item.targetY = parent.targetY;
			item.alpha = parent.alpha;
		});

		updateAlt();
		FlxG.sound.play(Paths.getSound('scrollMenu'));
	}

	function swapMode():Void
	{
		onKeyboardMode = !onKeyboardMode;

		curSelected = 0;
		curAlt = false;
		controllerSpr.animation.play(onKeyboardMode ? 'keyboard' : 'gamepad');

		createTexts();
	}

	function updateAlt(?doSwap:Bool = false):Void
	{
		if (doSwap)
		{
			curAlt = !curAlt;
			FlxG.sound.play(Paths.getSound('scrollMenu'));
		}

		selectSpr.sprTracker = grpBlacks.members[Math.floor(curSelected * 2) + (curAlt ? 1 : 0)];
		selectSpr.visible = (selectSpr.sprTracker != null);
	}
}