package options;

using StringTools;

typedef Keybind =
{
	keyboard:String,
	gamepad:String
}

class Option
{
	public var value(get, set):Dynamic;

	public var child:Alphabet;
	public var canChange:Bool = true;
	public var selectable:Bool = true;
	public var text(get, set):String;
	//public var disableChangeOnReset:Bool = false;
	public var onChange:Void->Void = null; //Pressed enter (on Bool type options) or pressed/held left/right (on other types)

	public var type(get, default):String = 'bool'; //bool, int (or integer), float (or fl), percent, string (or str), keybind (or key)
	// Bool will use checkboxes
	// Everything else will use a text

	public var scrollSpeed:Float = 50; //Only works on int/float, defines how fast it scrolls per second while holding left/right
	private var variable:String = null; //Variable from ClientPrefs.hx
	public var defaultValue:Dynamic = null;

	public var curOption:Int = 0; //Don't change this
	public var options:Array<String> = null; //Only used in string type
	public var changeValue:Dynamic = 1; //Only used in int/float/percent type, how much is changed when you PRESS
	public var minValue:Dynamic = null; //Only used in int/float/percent type
	public var maxValue:Dynamic = null; //Only used in int/float/percent type
	public var decimals:Int = 1; //Only used in float/percent type

	public var displayFormat:String = '%v'; //How String/Float/Percent/Int values are shown, %v = Current value, %d = Default value
	public var description:String = '';
	public var name:String = 'Unknown';

	public var defaultKeys:Keybind = null; //Only used in keybind type
	public var keys:Keybind = null; //Only used in keybind type

	public function new(name:String, description:String = '', variable:String, type:String = 'bool', ?options:Array<String> = null):Void
	{
		this.name = name;
		this.description = description;
		this.variable = variable;
		this.type = type;
		this.options = options;

		if (variable != null && variable.length > 0) {
			defaultValue = Reflect.getProperty(ClientPrefs.defaultData, variable);
		}

		switch (type)
		{
			case 'bool': if (defaultValue == null) defaultValue = false;
			case 'int' | 'float': if (defaultValue == null) defaultValue = 0;
			case 'percent':
			{
				if (defaultValue == null) defaultValue = 1;

				displayFormat = '%v%';
				changeValue = 0.01;
				minValue = 0;
				maxValue = 1;
				scrollSpeed = 0.5;
				decimals = 2;
			}
			case 'string':
			{
				if (options.length > 0 && defaultValue == null) {
					defaultValue = options[0];
				}

				if (defaultValue == null) defaultValue = '';
			}
			case 'keybind':
			{
				defaultValue = '';

				defaultKeys = {gamepad: 'NONE', keyboard: 'NONE'};
				keys = {gamepad: 'NONE', keyboard: 'NONE'};
			}
		}

		try
		{
			if (variable != null && variable.length > 0)
			{
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
				}
			}
		}
		catch (_:Dynamic) {}
	}

	public function change():Void
	{
		if (onChange != null) { //nothing lol
			onChange();
		}
	}

	public var getValue:Void->Dynamic = null;

	private dynamic function get_value():Dynamic
	{
		if (variable == null || variable.length < 1) return null;
		if (getValue != null) return getValue();

		var value:Dynamic = Reflect.getProperty(ClientPrefs, variable);

		if (type == 'keybind') {
			return !Controls.instance.controllerMode ? value.keyboard : value.gamepad;
		}

		return value;
	}

	public var setValue:Dynamic->Dynamic = null;

	private dynamic function set_value(value:Dynamic):Dynamic
	{
		if (variable == null || variable.length < 1) return null;
		if (setValue != null) return setValue(value);

		if (type == 'keybind')
		{
			var keys:Dynamic = Reflect.getProperty(ClientPrefs, variable);

			if (!Controls.instance.controllerMode) {
				keys.keyboard = value;
			}
			else {
				keys.gamepad = value;
			}

			return value;
		}

		Reflect.setProperty(ClientPrefs, variable, value);
		return value;
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
			case 'key', 'keybind': newValue = 'keybind';
			case 'int' | 'float' | 'percent' | 'string': newValue = type;
			case 'integer': newValue = 'int';
			case 'str': newValue = 'string';
			case 'fl': newValue = 'float';
		}

		type = newValue;
		return type;
	}
}