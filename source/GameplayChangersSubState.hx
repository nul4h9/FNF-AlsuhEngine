package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.group.FlxGroup;
import flixel.effects.FlxFlicker;

using StringTools;

class GameplayChangersSubState extends MusicBeatSubState
{
	private var curOption:GameplayOption = null;
	private var curSelected:Int = 0;
	private var optionsArray:Array<GameplayOption> = [];
	private var defaultValue:GameplayOption = new GameplayOption('Reset To Default Values', 'idk');

	private var grpOptions:FlxTypedGroup<Alphabet>;
	private var checkboxGroup:FlxTypedGroup<CheckboxThingie>;
	private var grpTexts:FlxTypedGroup<AttachedText>;

	function getOptions():Void
	{
		var goption:GameplayOption = new GameplayOption('Scroll Type', 'scrolltype', 'string', ["multiplicative", "constant"]);
		optionsArray.push(goption);

		var option:GameplayOption = new GameplayOption('Scroll Speed', 'scrollspeed', 'float');
		option.scrollSpeed = 2.0;
		option.minValue = 0.35;
		option.changeValue = 0.05;
		option.decimals = 2;

		if (goption.value != "constant")
		{
			option.displayFormat = '%vX';
			option.maxValue = 3;
		}
		else
		{
			option.displayFormat = "%v";
			option.maxValue = 6;
		}

		optionsArray.push(option);

		var option:GameplayOption = new GameplayOption('Playback Rate', 'songspeed', 'float');
		option.scrollSpeed = 1;
		option.minValue = 0.5;
		option.maxValue = 3.0;
		option.changeValue = 0.05;
		option.displayFormat = '%vX';
		option.decimals = 2;
		optionsArray.push(option);

		var option:GameplayOption = new GameplayOption('Health Gain Multiplier', 'healthgain', 'float');
		option.scrollSpeed = 2.5;
		option.minValue = 0;
		option.maxValue = 5;
		option.changeValue = 0.1;
		option.displayFormat = '%vX';
		optionsArray.push(option);

		var option:GameplayOption = new GameplayOption('Health Loss Multiplier', 'healthloss', 'float');
		option.scrollSpeed = 2.5;
		option.minValue = 0.5;
		option.maxValue = 5;
		option.changeValue = 0.1;
		option.displayFormat = '%vX';
		optionsArray.push(option);

		var option:GameplayOption = new GameplayOption('Instakill on Miss', 'instakill', 'bool');
		optionsArray.push(option);

		var option:GameplayOption = new GameplayOption('Practice Mode', 'practice', 'bool');
		optionsArray.push(option);

		var option:GameplayOption = new GameplayOption('Botplay', 'botplay', 'bool');
		optionsArray.push(option);

		defaultValue.type = 'default_value';
		optionsArray.push(defaultValue);
	}

	public function getOptionByName(name:String):GameplayOption
	{
		for (i in optionsArray)
		{
			var opt:GameplayOption = i;

			if (opt.name == name) {
				return opt;
			}
		}

		return null;
	}

	public function new():Void
	{
		super();
		
		var bg:Sprite = new Sprite();
		bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0.6;
		add(bg);

		grpOptions = new FlxTypedGroup<Alphabet>(); // avoids lagspikes while scrolling through menus!
		add(grpOptions);

		grpTexts = new FlxTypedGroup<AttachedText>();
		add(grpTexts);

		checkboxGroup = new FlxTypedGroup<CheckboxThingie>();
		add(checkboxGroup);
		
		getOptions();

		for (i in 0...optionsArray.length)
		{
			var leOption:GameplayOption = optionsArray[i];

			var optionText:Alphabet = new Alphabet(150, 300, leOption.name, true);
			optionText.isMenuItem = true;
			optionText.setScale(0.8);
			optionText.targetY = i;
			grpOptions.add(optionText);

			switch (leOption.type)
			{
				case 'bool':
				{
					optionText.x += 90;
					optionText.startPosition.x += 90;
					optionText.hasIcon = true;

					var checkbox:CheckboxThingie = new CheckboxThingie(optionText.x - 105, optionText.y, leOption.value == true);
					checkbox.sprTracker = optionText;
					checkbox.offsetX -= 20;
					checkbox.offsetY = -52;
					checkbox.ID = i;
					checkboxGroup.add(checkbox);
				}
				case 'int' | 'float' | 'percent' | 'string':
				{
					var valueText:AttachedText = new AttachedText(Std.string(leOption.value), optionText.width + 40, 0, true, 0.8);
					valueText.sprTracker = optionText;
					valueText.copyAlpha = true;
					valueText.ID = i;
					grpTexts.add(valueText);

					leOption.setChild(valueText);
				}
			}

			optionText.snapToPosition();
			updateTextFrom(leOption);
		}

		changeSelection();
		reloadCheckboxes();
	}

	var flickering:Bool = false;
	var nextAccept:Int = 5;
	var holdTime:Float = 0;
	var holdTimeVal:Float = 0;
	var holdValue:Float = 0;

	override function update(elapsed:Float):Void
	{
		if (controls.BACK_P)
		{
			ClientPrefs.saveGameplaySettings();

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

				if (FlxG.mouse.wheel != 0 && !FlxG.keys.justPressed.ALT) {
					changeSelection(-1 * FlxG.mouse.wheel);
				}
			}

			if (nextAccept <= 0)
			{
				if (curOption != defaultValue)
				{
					var usesCheckbox:Bool = true;

					if (curOption.type != 'bool') {
						usesCheckbox = false;
					}

					if (usesCheckbox)
					{
						if (controls.ACCEPT_P || (FlxG.mouse.justPressed && FlxG.mouse.overlaps(grpOptions.members[curSelected])))
						{
							var onChangeThing:Void->Void = function():Void
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
	
								FlxFlicker.flicker(grpOptions.members[curSelected], 1, 0.06, true, false, function(flk:FlxFlicker):Void {
									onChangeThing();
								});
	
								FlxG.sound.play(Paths.getSound('confirmMenu'));
							}
							else {
								onChangeThing();
							}
						}
					}
					else
					{
						if (controls.UI_LEFT || controls.UI_RIGHT)
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
											
											if (curOption.name == "Scroll Type")
											{
												var oOption:GameplayOption = getOptionByName("Scroll Speed");

												if (oOption != null)
												{
													if (curOption.value == "constant")
													{
														oOption.displayFormat = "%v";
														oOption.maxValue = 6;
													}
													else
													{
														oOption.displayFormat = "%vX";
														oOption.maxValue = 3;

														if (oOption.value > 3) oOption.value = 3;
													}

													updateTextFrom(oOption);
												}
											}
										}
									}

									updateTextFrom(curOption);
									curOption.change();
									FlxG.sound.play(Paths.getSound('scrollMenu'));
								}
								else if (curOption.type != 'string')
								{
									holdValue = CoolUtil.boundTo(holdValue + (curOption.scrollSpeed * elapsed * (controls.UI_LEFT ? -1 : 1)), curOption.minValue, curOption.maxValue);

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
						curOption.value = curOption.defaultValue;

						if (curOption.type != 'bool')
						{
							if (curOption.type == 'string') {
								curOption.curOption = curOption.options.indexOf(curOption.value);
							}

							updateTextFrom(curOption);
						}

						for (i in 0...optionsArray.length)
						{
							var leOption:GameplayOption = optionsArray[i];

							if (leOption.name == 'Scroll Speed')
							{
								leOption.displayFormat = "%vX";
								leOption.maxValue = 3;
	
								if (leOption.value > leOption.maxValue) {
									leOption.value = leOption.maxValue;
								}
	
								updateTextFrom(leOption);
							}
						}

						curOption.change();
		
						FlxG.sound.play(Paths.getSound('scrollMenu'));
		
						updateTextFrom(curOption);
						reloadCheckboxes();
					}
				}
				else
				{
					if (controls.ACCEPT_P || (FlxG.mouse.justPressed && FlxG.mouse.overlaps(grpOptions.members[curSelected])))
					{
						var onPressedThing:Void->Void = function():Void
						{
							for (i in 0...optionsArray.length)
							{
								var leOption:GameplayOption = optionsArray[i];
								leOption.value = leOption.defaultValue;

								if (leOption.type != 'bool')
								{
									if (leOption.type == 'string') {
										leOption.curOption = leOption.options.indexOf(leOption.value);
									}

									updateTextFrom(leOption);
								}

								if (leOption.name == 'Scroll Speed')
								{
									leOption.displayFormat = "%vX";
									leOption.maxValue = 3;

									if (leOption.value > leOption.maxValue) {
										leOption.value = leOption.maxValue;
									}

									updateTextFrom(leOption);
								}

								leOption.change();
							}

							FlxG.sound.play(Paths.getSound('cancelMenu'));
							reloadCheckboxes();

							flickering = false;
						}

						if (ClientPrefs.flashingLights)
						{
							flickering = true;

							FlxFlicker.flicker(grpOptions.members[curSelected], 1, 0.06, true, false, function(flk:FlxFlicker):Void {
								onPressedThing();
							});
						}
						else {
							onPressedThing();
						}

						FlxG.sound.play(Paths.getSound('confirmMenu'));
					}
				}
			}
		}

		if (nextAccept > 0) {
			nextAccept -= 1;
		}

		super.update(elapsed);
	}

	function updateTextFrom(option:GameplayOption):Void
	{
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

			if (item.targetY == 0) {
				item.alpha = 1;
			}
		}

		for (text in grpTexts)
		{
			text.alpha = 0.6;

			if (text.ID == curSelected) {
				text.alpha = 1;
			}
		}

		curOption = optionsArray[curSelected]; //shorter lol
		FlxG.sound.play(Paths.getSound('scrollMenu'));
	}

	function reloadCheckboxes():Void
	{
		for (checkbox in checkboxGroup) {
			checkbox.daValue = (optionsArray[checkbox.ID].value == true);
		}
	}
}

class GameplayOption
{
	private var child:Alphabet;
	public var text(get, set):String;
	public var onChange:Void->Void = null; //Pressed enter (on Bool type options) or pressed/held left/right (on other types)

	public var value(get, set):Dynamic;
	public var type(get, default):String = 'bool'; //bool, int (or integer), float (or fl), percent, string (or str)
	// Bool will use checkboxes
	// Everything else will use a text

	public var showBoyfriend:Bool = false;
	public var scrollSpeed:Float = 50; //Only works on int/float, defines how fast it scrolls per second while holding left/right

	private var variable:String = null; //Variable from ClientPrefs.hx's gameplaySettings
	public var defaultValue:Dynamic = null;

	public var curOption:Int = 0; //Don't change this
	public var options:Array<String> = null; //Only used in string type
	public var changeValue:Dynamic = 1; //Only used in int/float/percent type, how much is changed when you PRESS
	public var minValue:Dynamic = null; //Only used in int/float/percent type
	public var maxValue:Dynamic = null; //Only used in int/float/percent type
	public var decimals:Int = 1; //Only used in float/percent type

	public var displayFormat:String = '%v'; //How String/Float/Percent/Int values are shown, %v = Current value, %d = Default value
	public var name:String = 'Unknown';

	public function new(name:String, variable:String, type:String = 'bool', ?options:Array<String> = null):Void
	{
		this.name = name;
		this.variable = variable;
		this.type = type;

		defaultValue = ClientPrefs.defaultGameplaySettings.get(this.variable);

		this.options = options;

		if (defaultValue == 'null variable value')
		{
			switch (type)
			{
				case 'bool': defaultValue = false;
				case 'int' | 'float': defaultValue = 0;
				case 'percent': defaultValue = 1;
				case 'string':
				{
					defaultValue = '';

					if (options.length > 0) {
						defaultValue = options[0];
					}
				}
			}
		}

		if (value == null) {
			value = defaultValue;
		}

		switch (type)
		{
			case 'string':
			{
				var num:Int = options.indexOf(value);

				if (num > -1) {
					curOption = num;
				}
			}	
			case 'percent':
			{
				displayFormat = '%v%';
				changeValue = 0.01;
				minValue = 0;
				maxValue = 1;
				scrollSpeed = 0.5;
				decimals = 2;
			}
		}
	}

	public function change():Void
	{
		if (onChange != null) { //nothing lol
			onChange();
		}
	}

	public function get_value():Dynamic
	{
		return ClientPrefs.gameplaySettings.get(variable);
	}

	public function set_value(value:Dynamic):Dynamic
	{
		ClientPrefs.gameplaySettings.set(variable, value);
		return value;
	}

	public function setChild(child:Alphabet):Void
	{
		this.child = child;
	}

	private function get_text():String
	{
		if (child != null) {
			return child.text;
		}

		return null;
	}

	private function set_text(newValue:String = ''):String
	{
		if (child != null) {
			child.text = newValue;
		}

		return null;
	}

	private function get_type():String
	{
		var newValue:String = 'bool';

		switch (type.toLowerCase().trim())
		{
			case 'int' | 'float' | 'percent' | 'string' | 'default_value': newValue = type;
			case 'integer': newValue = 'int';
			case 'str': newValue = 'string';
			case 'fl': newValue = 'float';
		}

		type = newValue;
		return type;
	}
}