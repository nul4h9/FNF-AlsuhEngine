package options;

#if DISCORD_ALLOWED
import Discord.DiscordClient;
#end

import options.Option;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.math.FlxPoint;
import flixel.sound.FlxSound;
import flixel.group.FlxGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.effects.FlxFlicker;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepadInputID;

using StringTools;

class BaseOptionsMenu extends MusicBeatSubState
{
	private var curSelected:Int = -1;

	private var optionsArray:Array<Option>;
	private var curOption:Option = null;

	private var grpOptions:FlxTypedGroup<Alphabet>;
	private var checkboxGroup:FlxTypedGroup<CheckboxThingie>;
	private var grpTexts:FlxTypedGroup<AttachedText>;

	private var descBox:Sprite;
	private var descText:FlxText;

	public var title:String;
	public var rpcTitle:String;

	public var bg:FlxSprite;

	public function new():Void
	{
		super();

		if (title == null) title = 'Options';
		if (rpcTitle == null) rpcTitle = 'Options Menu';
		
		#if DISCORD_ALLOWED
		DiscordClient.changePresence(rpcTitle, null);
		#end

		bg = new FlxSprite();

		if (Paths.fileExists('images/menuDesat.png', IMAGE)) {
			bg.loadGraphic(Paths.getImage('menuDesat'));
		}
		else {
			bg.loadGraphic(Paths.getImage('bg/menuDesat'));
		}

		bg.color = 0xFFea71fd;
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		checkboxGroup = new FlxTypedGroup<CheckboxThingie>();
		add(checkboxGroup);

		grpTexts = new FlxTypedGroup<AttachedText>();
		add(grpTexts);

		for (i in 0...optionsArray.length)
		{
			if (curSelected < 0) curSelected = i;
			var leOption:Option = optionsArray[i];

			var optionText:Alphabet = new Alphabet(290, 260, leOption.name, false);
			optionText.isMenuItem = true;
			optionText.targetY = i - curSelected;
			grpOptions.add(optionText);

			switch (leOption.type)
			{
				case 'bool':
				{
					var checkbox:CheckboxThingie = new CheckboxThingie(optionText.x - 105, optionText.y, leOption.value == true);
					checkbox.sprTracker = optionText;
					checkbox.ID = i;
					optionText.hasIcon = true;
					checkboxGroup.add(checkbox);
				}
				default:
				{
					optionText.x -= 80;
					optionText.startPosition.x -= 80;

					var valueText:AttachedText = new AttachedText('' + leOption.value, optionText.width + 80);
					valueText.sprTracker = optionText;
					grpTexts.add(valueText);
	
					leOption.child = valueText;
				}
			}

			updateTextFrom(leOption);
			optionText.snapToPosition();
		}

		descBox = new Sprite();
		descBox.makeGraphic(1, 1, FlxColor.BLACK);
		descBox.alpha = 0.6;
		add(descBox);

		descText = new FlxText(50, 600, 1180, '', 32);
		descText.setFormat(Paths.getFont('vcr.ttf'), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		descText.scrollFactor.set();
		descText.borderSize = 2.4;
		add(descText);

		var titleText:Alphabet = new Alphabet(75, 45, title, true);
		titleText.setScale(0.6);
		titleText.alpha = 0.4;
		add(titleText);

		changeSelection();
		reloadCheckboxes();
	}

	public function addOption(option:Option):Option
	{
		if (optionsArray == null || optionsArray.length < 1) optionsArray = [];
		optionsArray.push(option);
		return option;
	}

	var nextAccept:Int = 5;

	var holdTime:Float = 0;
	var holdValue:Float = 0;
	var holdTimeVal:Float = 0;

	var flickering:Bool = false;

	var bindingKey:Bool = false;
	var holdingEsc:Float = 0;
	var bindingBlack:FlxSprite;
	var bindingText:Alphabet;
	var bindingText2:Alphabet;

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (bindingKey)
		{
			bindingKeyUpdate(elapsed);
			return;
		}

		if (controls.BACK_P)
		{
			FlxG.sound.play(Paths.getSound('cancelMenu'));
			close();
		}

		if (!flickering)
		{
			if (optionsArray.length > 1)
			{
				if (controls.UI_UP_P)
				{
					changeSelection(-1);
					holdTime = 0;
				}

				if (controls.UI_DOWN_P)
				{
					changeSelection(1);
					holdTime = 0;
				}

				if (controls.UI_DOWN || controls.UI_UP)
				{
					var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

					if (holdTime > 0.5 && checkNewHold - checkLastHold > 0) {
						changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -1 : 1));
					}
				}

				if (FlxG.mouse.wheel != 0 && !FlxG.mouse.pressedMiddle) {
					changeSelection(-1 * FlxG.mouse.wheel);
				}
			}

			var usesCheckbox:Bool = curOption.type == 'bool';
			var alphabet:Alphabet = grpOptions.members[curSelected];

			if ((controls.ACCEPT_P || (FlxG.mouse.justPressed && FlxG.mouse.overlaps(alphabet))) && nextAccept <= 0)
			{
				if (usesCheckbox && curOption.canChange)
				{
					var finishThing:Void->Void = function():Void
					{
						FlxG.sound.play(Paths.getSound('scrollMenu'));
	
						curOption.value = (curOption.value == true) ? false : true;
						curOption.change();

						reloadCheckboxes();
						flickering = false;
					}

					if (ClientPrefs.flashingLights)
					{
						flickering = true;

						FlxFlicker.flicker(alphabet, 1, 0.06, true, false, function(flk:FlxFlicker):Void {
							finishThing();
						});

						FlxG.sound.play(Paths.getSound('confirmMenu'));
					}
					else {
						finishThing();
					}
				}
			}

			if (curOption.canChange)
			{
				if (!usesCheckbox)
				{
					if (curOption.type == 'keybind')
					{
						if ((controls.ACCEPT_P || (FlxG.mouse.justPressed && FlxG.mouse.overlaps(alphabet))) && nextAccept <= 0)
						{
							var startRebinding:Void->Void = function():Void
							{
								bindingBlack = new FlxSprite();
								bindingBlack.makeGraphic(1, 1, FlxColor.WHITE);
								bindingBlack.scale.set(FlxG.width, FlxG.height);
								bindingBlack.updateHitbox();
								bindingBlack.alpha = 0;
	
								FlxTween.tween(bindingBlack, {alpha: 0.6}, 0.35, {ease: FlxEase.linear});
	
								add(bindingBlack);
			
								bindingText = new Alphabet(FlxG.width / 2, 160, "Rebinding " + curOption.name, false);
								bindingText.alignment = CENTERED;
								add(bindingText);
								
								bindingText2 = new Alphabet(FlxG.width / 2, 340, "Hold ESC to Cancel\nHold Backspace to Delete", true);
								bindingText2.alignment = CENTERED;
								add(bindingText2);
			
								bindingKey = true;
								holdingEsc = 0;
	
								ClientPrefs.toggleVolumeKeys(false);
	
								FlxG.sound.play(Paths.getSound('scrollMenu'));
							}

							if (ClientPrefs.flashingLights)
							{
								FlxFlicker.flicker(alphabet, 1, 0.06, true, false, function(flk:FlxFlicker):Void {
									startRebinding();
								});

								FlxG.sound.play(Paths.getSound('confirmMenu'));
							}
							else {
								startRebinding();
							}
						}
					}
					else if (controls.UI_LEFT || controls.UI_RIGHT)
					{
						var pressed:Bool = (controls.UI_LEFT_P || controls.UI_RIGHT_P);

						if (holdTimeVal > 0.5 || pressed)
						{
							if (pressed)
							{
								var add:Dynamic = null;

								if (curOption.type != 'string') {
									add = controls.UI_LEFT ? -curOption.changeValue : curOption.changeValue;
								}

								switch (curOption.type)
								{
									case 'int' | 'float' | 'percent':
									{
										holdValue = CoolUtil.boundTo(curOption.value + add, curOption.minValue, curOption.maxValue);

										switch (curOption.type)
										{
											case 'int':
											{
												holdValue = Math.round(holdValue);
												curOption.value = holdValue;
											}
											case 'float' | 'percent':
											{
												holdValue = FlxMath.roundDecimal(holdValue, curOption.decimals);
												curOption.value = holdValue;
											}
										}
									}
									case 'string':
									{
										curOption.curOption = FlxMath.wrap(curOption.curOption + (controls.UI_LEFT_P ? -1 : 1), 0, curOption.options.length - 1);
										curOption.value = curOption.options[curOption.curOption]; // lol
									}
								}

								updateTextFrom(curOption);

								curOption.change();
								FlxG.sound.play(Paths.getSound('scrollMenu'));
							}
							else if (curOption.type != 'string')
							{
								var add:Float = curOption.scrollSpeed * elapsed * (controls.UI_LEFT ? -1 : 1);
								holdValue = CoolUtil.boundTo(holdValue + add, curOption.minValue, curOption.maxValue);

								switch (curOption.type)
								{
									case 'int': curOption.value = Math.round(holdValue);
									case 'float' | 'percent':
									{
										var blah:Float = CoolUtil.boundTo(holdValue + curOption.changeValue - (holdValue % curOption.changeValue), curOption.minValue, curOption.maxValue);
										curOption.value = FlxMath.roundDecimal(blah, curOption.decimals);
									}
								}

								updateTextFrom(curOption);
								curOption.change();
							}
						}

						if (curOption.type != 'string') {
							holdTimeVal += elapsed;
						}
					}
					else if (controls.UI_LEFT_R || controls.UI_RIGHT_R) {
						clearHold();
					}

					if (FlxG.mouse.wheel != 0 && FlxG.mouse.pressedMiddle)
					{
						if (curOption.type != 'string')
						{
							holdValue = CoolUtil.boundTo(holdValue + (curOption.scrollSpeed / 50) * (-1 * FlxG.mouse.wheel), curOption.minValue, curOption.maxValue);

							switch (curOption.type)
							{
								case 'int': curOption.value = Math.round(holdValue);
								case 'float' | 'percent':
								{
									var blah:Float = CoolUtil.boundTo(holdValue + curOption.changeValue - (holdValue % curOption.changeValue), curOption.minValue, curOption.maxValue);
									curOption.value = FlxMath.roundDecimal(blah, curOption.decimals);
								}
							}
			
							updateTextFrom(curOption);
							curOption.change();

							FlxG.sound.play(Paths.getSound('scrollMenu'));
						}
						else if (curOption.type == 'string')
						{
							var num:Int = FlxMath.wrap(curOption.options.indexOf(curOption.value) + (-1 * FlxG.mouse.wheel), 0, curOption.options.length - 1);

							curOption.curOption = num;
							curOption.value = curOption.options[num]; // lol

							updateTextFrom(curOption);
							curOption.change();

							FlxG.sound.play(Paths.getSound('scrollMenu'));
						}
					}
				}

				if (controls.RESET_P)
				{
					if (curOption.type == 'keybind')
					{
						curOption.value = !Controls.instance.controllerMode ? curOption.defaultKeys.keyboard : curOption.defaultKeys.gamepad;
						updateBind(curOption);
					}
					else
					{
						curOption.value = curOption.defaultValue;

						if (curOption.type != 'bool')
						{
							if (curOption.type == 'string') {
								curOption.curOption = curOption.options.indexOf(curOption.value);
							}

							updateTextFrom(curOption);
						}
					}

					curOption.change();

					FlxG.sound.play(Paths.getSound('cancelMenu'));
					reloadCheckboxes();
				}
			}
		}

		if (nextAccept > 0) {
			nextAccept -= 1;
		}
	}

	function bindingKeyUpdate(elapsed:Float):Void
	{
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
				if (!controls.controllerMode) curOption.keys.keyboard = NONE;
				else curOption.keys.gamepad = NONE;

				updateBind(!controls.controllerMode ? InputFormatter.getKeyName(NONE) : InputFormatter.getGamepadName(NONE));

				FlxG.sound.play(Paths.getSound('cancelMenu'));
				closeBinding();
			}
		}
		else
		{
			holdingEsc = 0;

			var changed:Bool = false;

			if (!controls.controllerMode)
			{
				if (FlxG.keys.justPressed.ANY || FlxG.keys.justReleased.ANY)
				{
					var keyPressed:FlxKey = cast (FlxG.keys.firstJustPressed(), FlxKey);
					var keyReleased:FlxKey = cast (FlxG.keys.firstJustReleased(), FlxKey);

					if (keyPressed != NONE && keyPressed != ESCAPE && keyPressed != BACKSPACE)
					{
						changed = true;
						curOption.keys.keyboard = keyPressed;
					}
					else if (keyReleased != NONE && (keyReleased == ESCAPE || keyReleased == BACKSPACE))
					{
						changed = true;
						curOption.keys.keyboard = keyReleased;
					}
				}
			}
			else if (FlxG.gamepads.anyJustPressed(ANY) || FlxG.gamepads.anyJustPressed(LEFT_TRIGGER) || FlxG.gamepads.anyJustPressed(RIGHT_TRIGGER) || FlxG.gamepads.anyJustReleased(ANY))
			{
				var keyPressed:FlxGamepadInputID = NONE;
				var keyReleased:FlxGamepadInputID = NONE;

				if (FlxG.gamepads.anyJustPressed(LEFT_TRIGGER)) {
					keyPressed = LEFT_TRIGGER; // it wasnt working for some reason
				}
				else if (FlxG.gamepads.anyJustPressed(RIGHT_TRIGGER)) {
					keyPressed = RIGHT_TRIGGER; // it wasnt working for some reason
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

							if (keyPressed != NONE || keyReleased != NONE) break;
						}
					}
				}

				if (keyPressed != NONE && keyPressed != FlxGamepadInputID.BACK && keyPressed != FlxGamepadInputID.B)
				{
					changed = true;
					curOption.keys.gamepad = keyPressed;
				}
				else if (keyReleased != NONE && (keyReleased == FlxGamepadInputID.BACK || keyReleased == FlxGamepadInputID.B))
				{
					changed = true;
					curOption.keys.gamepad = keyReleased;
				}
			}

			if (changed)
			{
				var key:String = null;

				if (!controls.controllerMode)
				{
					if (curOption.keys.keyboard == null) curOption.keys.keyboard = 'NONE';

					curOption.value = curOption.keys.keyboard;
					key = InputFormatter.getKeyName(FlxKey.fromString(curOption.keys.keyboard));
				}
				else
				{
					if (curOption.keys.gamepad == null) curOption.keys.gamepad = 'NONE';

					curOption.value = curOption.keys.gamepad;
					key = InputFormatter.getGamepadName(FlxGamepadInputID.fromString(curOption.keys.gamepad));
				}

				updateBind(key);

				FlxG.sound.play(Paths.getSound('confirmMenu'));
				closeBinding();
			}
		}
	}

	final MAX_KEYBIND_WIDTH:Float = 320;

	function updateBind(?text:String = null, ?option:Option = null):Void
	{
		if (option == null) option = curOption;

		if (text == null)
		{
			text = option.value;
			if (text == null) text = 'NONE';

			if (!controls.controllerMode)
				text = InputFormatter.getKeyName(FlxKey.fromString(text));
			else
				text = InputFormatter.getGamepadName(FlxGamepadInputID.fromString(text));
		}

		var bind:AttachedText = cast option.child;

		var attach:AttachedText = new AttachedText(text, bind.offsetX);
		attach.sprTracker = bind.sprTracker;
		attach.copyAlpha = true;
		attach.ID = bind.ID;

		playstationCheck(attach);

		attach.scaleX = Math.min(1, MAX_KEYBIND_WIDTH / attach.width);
		attach.x = bind.x;
		attach.y = bind.y;

		option.child = attach;
		grpTexts.insert(grpTexts.members.indexOf(bind), attach);
		grpTexts.remove(bind);
		bind.destroy();
	}

	function playstationCheck(alpha:Alphabet):Void
	{
		if (!controls.controllerMode) return;

		var gamepad:FlxGamepad = FlxG.gamepads.firstActive;
		var model:FlxGamepadModel = gamepad != null ? gamepad.detectedModel : UNKNOWN;
		var letter = alpha.letters[0];

		if (model == PS4)
		{
			switch (alpha.text)
			{
				case '[', ']': //Square and Triangle respectively
				{
					letter.image = 'alphabet_playstation';
					letter.updateHitbox();
					
					letter.offset.x += 4;
					letter.offset.y -= 5;
				}
			}
		}
	}

	function closeBinding():Void
	{
		bindingKey = false;
		bindingBlack.destroy();
		remove(bindingBlack);

		bindingText.destroy();
		remove(bindingText);

		bindingText2.destroy();
		remove(bindingText2);

		ClientPrefs.toggleVolumeKeys(true);
	}

	function updateTextFrom(option:Option):Void
	{
		if (option.type == 'keybind')
		{
			updateBind(option);
			return;
		}

		var text:String = option.displayFormat;
		var val:Dynamic = option.value;

		if (option.type == 'percent') val *= 100;

		var def:Dynamic = option.defaultValue;
		option.text = text.replace('%v', Std.string(val)).replace('%d', Std.string(def));
	}

	function clearHold():Void
	{
		if (holdTimeVal > 0.5) {
			FlxG.sound.play(Paths.getSound('scrollMenu'));
		}

		holdTimeVal = 0;
	}

	function changeSelection(change:Int = 0):Void
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, optionsArray.length - 1);

		var bullShit:Int = 0;

		for (item in grpOptions.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;

			if (item.targetY == 0)
			{
				item.alpha = 1;

				for (i in 0...checkboxGroup.members.length)
				{
					var checkbox:CheckboxThingie = checkboxGroup.members[i];
					checkbox.alpha = 0.6;

					if (checkbox.sprTracker == item) {
						checkbox.alpha = 1;
					}
				}

				for (i in 0...grpTexts.members.length)
				{
					var checkbox:AttachedText = grpTexts.members[i];
					checkbox.alpha = 0.6;

					if (checkbox.sprTracker == item) {
						checkbox.alpha = 1;
					}
				}
			}
		}

		curOption = optionsArray[curSelected]; // shorter lol

		descText.text = curOption.description;
		descText.screenCenter(Y);
		descText.y += 270;
		descText.visible = curOption.description.length > 0;

		descBox.setPosition(descText.x - 10, descText.y - 10);
		descBox.setGraphicSize(Std.int(descText.width + 20), Std.int(descText.height + 25));
		descBox.updateHitbox();
		descBox.visible = curOption.description.length > 0;

		FlxG.sound.play(Paths.getSound('scrollMenu'));
	}

	function reloadCheckboxes():Void
	{
		for (checkbox in checkboxGroup) {
			checkbox.daValue = (optionsArray[checkbox.ID].value == true);
		}
	}
}