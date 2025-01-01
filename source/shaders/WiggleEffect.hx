package shaders;

import flixel.addons.display.FlxRuntimeShader;

enum WiggleEffectType
{
	DREAMY; // 0
	WAVY; // 1
	HEAT_WAVE_HORIZONTAL; // 2
	HEAT_WAVE_VERTICAL; // 3
	FLAG; // 4
}

class WiggleEffect extends FlxRuntimeShader
{
	public static function getEffectTypeId(v:WiggleEffectType):Int
	{
		return WiggleEffectType.getConstructors().indexOf(Std.string(v));
	}

	public var effectType(default, set):WiggleEffectType = DREAMY;

	function set_effectType(v:WiggleEffectType):WiggleEffectType
	{
		this.setInt('effectType', getEffectTypeId(v));
		return effectType = v;
	}

	public var waveSpeed(default, set):Float = 0;

	function set_waveSpeed(v:Float):Float
	{
		this.setFloat('uSpeed', v);
		return waveSpeed = v;
	}

	public var waveFrequency(default, set):Float = 0;

	function set_waveFrequency(v:Float):Float
	{
		this.setFloat('uFrequency', v);
		return waveFrequency = v;
	}

	public var waveAmplitude(default, set):Float = 0;

	function set_waveAmplitude(v:Float):Float
	{
		this.setFloat('uWaveAmplitude', v);
		return waveAmplitude = v;
	}

	var time(default, set):Float = 0;

	function set_time(v:Float):Float
	{
		this.setFloat('uTime', v);
		return time = v;
	}

	public function new(speed:Float, freq:Float, amplitude:Float, ?effect:WiggleEffectType = DREAMY):Void
	{
		super(Paths.getTextFromFile(Paths.getFrag('wiggle')));

		this.waveSpeed = speed;
		this.waveFrequency = freq;
		this.waveAmplitude = amplitude;
		this.effectType = effect;
	}

	public function update(elapsed:Float):Void
	{
		this.time += elapsed;
	}
}