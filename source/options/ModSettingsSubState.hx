package options;

import options.Option;

import flixel.FlxG;
import openfl.errors.Error;
import flixel.util.FlxColor;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepadInputID;

using StringTools;

class ModSettingsSubState extends BaseOptionsMenu
{
	var save:Map<String, Dynamic> = new Map<String, Dynamic>();
	var folder:String;

	private var _crashed:Bool = false;

	public function new(options:Array<Dynamic>, folder:String, name:String):Void
	{
		this.folder = folder;

		title = '';
		rpcTitle = 'Mod Settings ($name)'; // for Discord Rich Presence

		if (FlxG.save.data.modSettings == null) {
			FlxG.save.data.modSettings = new Map<String, Dynamic>();
		}
		else
		{
			var saveMap:Map<String, Dynamic> = FlxG.save.data.modSettings;
			save = saveMap.get(folder) != null ? saveMap.get(folder) : [];
		}

		try
		{
			for (option in options)
			{
				var newOption = new Option(
					option.name != null ? option.name : option.save,
					option.description != null ? option.description : 'No description provided.',
					option.save,
					option.type,
					option.options
				);

				switch (newOption.type)
				{
					case 'keybind': // Defaulting and error checking
					{
						var keyboardStr:String = option.keyboard;
						var gamepadStr:String = option.gamepad;

						if (keyboardStr == null) keyboardStr = 'NONE';
						if (gamepadStr == null) gamepadStr = 'NONE';

						newOption.defaultKeys.keyboard = keyboardStr;
						newOption.defaultKeys.gamepad = gamepadStr;

						if (save.get(option.save) == null)
						{
							newOption.keys.keyboard = newOption.defaultKeys.keyboard;
							newOption.keys.gamepad = newOption.defaultKeys.gamepad;

							save.set(option.save, newOption.keys);
						}

						var keyboardKey:FlxKey = cast FlxKey.fromString(keyboardStr);
						var gamepadKey:FlxGamepadInputID = cast FlxGamepadInputID.fromString(gamepadStr);

						@:privateAccess
						{
							newOption.getValue = function():Dynamic
							{
								var data:Dynamic = save.get(newOption.variable);
								if (data == null) return 'NONE';

								return !Controls.instance.controllerMode ? data.keyboard : data.gamepad;
							}

							newOption.setValue = function(value:Dynamic):Dynamic
							{
								var data:Dynamic = save.get(newOption.variable);
								if (data == null) data = {keyboard: 'NONE', gamepad: 'NONE'};

								if (!controls.controllerMode) data.keyboard = value;
								else data.gamepad = value;

								save.set(newOption.variable, data);
								return value;
							}
						}
					}
					default:
					{
						if (option.value != null) newOption.defaultValue = option.value;

						@:privateAccess
						{
							newOption.getValue = function():Dynamic
							{
								return save.get(newOption.variable);
							}

							newOption.setValue = function(value:Dynamic):Dynamic
							{
								save.set(newOption.variable, value);
								return value;
							}
						}
					}
				}

				if (option.type != 'keybind')
				{
					if (option.format != null) newOption.displayFormat = option.format;
					if (option.min != null) newOption.minValue = option.min;
					if (option.max != null) newOption.maxValue = option.max;
					if (option.step != null) newOption.changeValue = option.step;

					if (option.scroll != null) newOption.scrollSpeed = option.scroll;
					if (option.decimals != null) newOption.decimals = option.decimals;

					var myValue:Dynamic = null;

					if (save.get(option.save) != null)
					{
						myValue = save.get(option.save);

						if (newOption.type != 'keybind') {
							newOption.value = myValue;
						}
						else {
							newOption.value = !Controls.instance.controllerMode ? myValue.keyboard : myValue.gamepad;
						}
					}
					else
					{
						myValue = newOption.value;
						if (myValue == null) myValue = newOption.defaultValue;
					}
	
					switch (newOption.type)
					{
						case 'string':
						{
							var num:Int = newOption.options.indexOf(myValue);
							if (num > -1) newOption.curOption = num;
						}
					}
	
					save.set(option.save, myValue);
				}

				addOption(newOption);
			}
		}
		catch (e:Error)
		{
			var errorTitle:String = 'Mod name: ' + folder;
			var errorMsg:String = 'An error occurred: ${e.toString()}';

			#if windows
			Debug.displayAlert(errorTitle, errorMsg);
			#end

			Debug.logError('$errorTitle - $errorMsg');

			_crashed = true;
			close();

			return;
		}

		super();

		bg.alpha = 0.75;
		bg.color = FlxColor.WHITE;

		reloadCheckboxes();
	}

	override public function update(elapsed:Float)
	{
		if (_crashed)
		{
			close();
			return;
		}

		super.update(elapsed);
	}

	override public function close():Void
	{
		FlxG.save.data.modSettings.set(folder, save);
		FlxG.save.flush();

		super.close();
	}
}
