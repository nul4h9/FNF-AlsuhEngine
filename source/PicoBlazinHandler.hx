package;

import flixel.FlxG;
import flixel.group.FlxSpriteGroup;

import Character;

using StringTools;

class PicoBlazinHandler // Pico Note functions
{
	public function new():Void {}

	var cantUppercut:Bool = false;

	public function noteHit(note:Note):Void
	{
		if (wasNoteHitPoorly(note.rating) && isPlayerLowHealth() && isDarnellPreppingUppercut())
		{
			playPunchHighAnim();
			return;
		}

		if (cantUppercut)
		{
			playBlockAnim();
			cantUppercut = false;
			return;
		}

		switch(note.noteType)
		{
			case "punchlow":
				playPunchLowAnim();
			case "punchlowblocked":
				playPunchLowAnim();
			case "punchlowdodged":
				playPunchLowAnim();
			case "punchlowspin":
				playPunchLowAnim();

			case "punchhigh":
				playPunchHighAnim();
			case "punchhighblocked":
				playPunchHighAnim();
			case "punchhighdodged":
				playPunchHighAnim();
			case "punchhighspin":
				playPunchHighAnim();

			case "blockhigh":
				playBlockAnim();
			case "blocklow":
				playBlockAnim();
			case "blockspin":
				playBlockAnim();

			case "dodgehigh":
				playDodgeAnim();
			case "dodgelow":
				playDodgeAnim();
			case "dodgespin":
				playDodgeAnim();

			// Pico ALWAYS gets punched.
			case "hithigh":
				playHitHighAnim();
			case "hitlow":
				playHitLowAnim();
			case "hitspin":
				playHitSpinAnim();

			case "picouppercutprep":
				playUppercutPrepAnim();
			case "picouppercut" | "picouppercut-final":
				playUppercutAnim(true, note.noteType.endsWith('-final'));

			case "darnelluppercutprep":
				playIdleAnim();
			case "darnelluppercut":
				playUppercutHitAnim();

			case "idle":
				playIdleAnim();
			case "fakeout":
				playFakeoutAnim();
			case "taunt":
				playTauntConditionalAnim();
			case "tauntforce":
				playTauntAnim();
			case "reversefakeout":
				playIdleAnim(); // TODO: Which anim?
		}
	}

	public function noteMiss(note:Note):Void
	{
		if (isDarnellInUppercut())
		{
			playUppercutHitAnim();
			return;
		}

		if (willMissBeLethal())
		{
			playHitLowAnim();
			return;
		}

		if (cantUppercut)
		{
			playHitHighAnim();
			return;
		}

		switch (note.noteType)
		{
			// Pico fails to punch, and instead gets hit!
			case "punchlow":
				playHitLowAnim();
			case "punchlowblocked":
				playHitLowAnim();
			case "punchlowdodged":
				playHitLowAnim();
			case "punchlowspin":
				playHitSpinAnim();

			// Pico fails to punch, and instead gets hit!
			case "punchhigh":
				playHitHighAnim();
			case "punchhighblocked":
				playHitHighAnim();
			case "punchhighdodged":
				playHitHighAnim();
			case "punchhighspin":
				playHitSpinAnim();

			// Pico fails to block, and instead gets hit!
			case "blockhigh":
				playHitHighAnim();
			case "blocklow":
				playHitLowAnim();
			case "blockspin":
				playHitSpinAnim();

			// Pico fails to dodge, and instead gets hit!
			case "dodgehigh":
				playHitHighAnim();
			case "dodgelow":
				playHitLowAnim();
			case "dodgespin":
				playHitSpinAnim();

			// Pico ALWAYS gets punched.
			case "hithigh":
				playHitHighAnim();
			case "hitlow":
				playHitLowAnim();
			case "hitspin":
				playHitSpinAnim();

			// Fail to dodge the uppercut.
			case "picouppercutprep":
				playPunchHighAnim();
				cantUppercut = true;
			case "picouppercut":
				playUppercutAnim(false);

			// Darnell's attempt to uppercut, Pico dodges or gets hit.
			case "darnelluppercutprep":
				playIdleAnim();
			case "darnelluppercut":
				playUppercutHitAnim();

			case "idle":
				playIdleAnim();
			case "fakeout":
				playHitHighAnim();
			case "taunt":
				playTauntConditionalAnim();
			case "tauntforce":
				playTauntAnim();
			case "reversefakeout":
				playIdleAnim();
		}
	}
	
	public function noteMissPress(direction:Int):Void
	{
		if (willMissBeLethal())
			playHitLowAnim(); // Darnell throws a punch so that Pico dies.
		else 
			playPunchHighAnim(); // Pico wildly throws punches but Darnell dodges.
	}

	function movePicoToBack():Void
	{
		var bfPos:Int = FlxG.state.members.indexOf(boyfriendGroup);
		var dadPos:Int = FlxG.state.members.indexOf(dadGroup);
		if (bfPos < dadPos) return;

		FlxG.state.members[dadPos] = boyfriendGroup;
		FlxG.state.members[bfPos] = dadGroup;
	}

	function movePicoToFront():Void
	{
		var bfPos:Int = FlxG.state.members.indexOf(boyfriendGroup);
		var dadPos:Int = FlxG.state.members.indexOf(dadGroup);
		if (bfPos > dadPos) return;

		FlxG.state.members[dadPos] = boyfriendGroup;
		FlxG.state.members[bfPos] = dadGroup;
	}

	var alternate:Bool = false;

	function doAlternate():String
	{
		alternate = !alternate;
		return alternate ? '1' : '2';
	}

	function playBlockAnim():Void
	{
		boyfriend.playAnim('block', true);
		FlxG.camera.shake(0.002, 0.1);
		moveToBack();
	}

	function playCringeAnim():Void
	{
		boyfriend.playAnim('cringe', true);
		moveToBack();
	}

	function playDodgeAnim():Void
	{
		boyfriend.playAnim('dodge', true);
		moveToBack();
	}

	function playIdleAnim():Void
	{
		boyfriend.playAnim('idle', false);
		moveToBack();
	}

	function playFakeoutAnim():Void
	{
		boyfriend.playAnim('fakeout', true);
		moveToBack();
	}

	function playUppercutPrepAnim():Void
	{
		boyfriend.playAnim('uppercutPrep', true);
		moveToFront();
	}

	function playUppercutAnim(hit:Bool, isFinal:Bool = false):Void
	{
		boyfriend.playAnim('uppercut', true);

		if (isFinal) {
			boyfriend.stunned = true;
		}

		if (hit) FlxG.camera.shake(0.005, 0.25);
		moveToFront();
	}

	function playUppercutHitAnim():Void
	{
		boyfriend.playAnim('uppercutHit', true);
		FlxG.camera.shake(0.005, 0.25);
		moveToBack();
	}

	function playHitHighAnim():Void
	{
		boyfriend.playAnim('hitHigh', true);
		FlxG.camera.shake(0.0025, 0.15);
		moveToBack();
	}

	function playHitLowAnim():Void
	{
		boyfriend.playAnim('hitLow', true);
		FlxG.camera.shake(0.0025, 0.15);
		moveToBack();
	}

	function playHitSpinAnim():Void
	{
		boyfriend.playAnim('hitSpin', true);
		FlxG.camera.shake(0.0025, 0.15);
		moveToBack();
	}

	function playPunchHighAnim():Void
	{
		boyfriend.playAnim('punchHigh' + doAlternate(), true);
		moveToFront();
	}

	function playPunchLowAnim():Void
	{
		boyfriend.playAnim('punchLow' + doAlternate(), true);
		moveToFront();
	}

	function playTauntConditionalAnim():Void
	{
		if (boyfriend.getAnimationName() == "fakeout")
			playTauntAnim();
		else
			playIdleAnim();
	}

	function playTauntAnim():Void
	{
		boyfriend.playAnim('taunt', true);
		moveToBack();
	}

	function willMissBeLethal():Bool
	{
		return PlayState.instance.health <= 0.0 && !PlayState.instance.practiceMode;
	}
	
	function isDarnellPreppingUppercut():Bool
	{
		return dad.getAnimationName() == 'uppercutPrep';
	}

	function isDarnellInUppercut():Bool
	{
		return dad.getAnimationName() == 'uppercut' || dad.getAnimationName() == 'uppercut-hold';
	}

	function wasNoteHitPoorly(rating:String):Bool
	{
		return (rating == "bad" || rating == "shit");
	}

	function isPlayerLowHealth():Bool
	{
		return PlayState.instance.health <= 0.3 * 2;
	}
	
	function moveToBack():Void
	{
		var bfPos:Int = FlxG.state.members.indexOf(boyfriendGroup);
		var dadPos:Int = FlxG.state.members.indexOf(dadGroup);
		if (bfPos < dadPos) return;

		FlxG.state.members[dadPos] = boyfriendGroup;
		FlxG.state.members[bfPos] = dadGroup;
	}

	function moveToFront():Void
	{
		var bfPos:Int = FlxG.state.members.indexOf(boyfriendGroup);
		var dadPos:Int = FlxG.state.members.indexOf(dadGroup);
		if (bfPos > dadPos) return;

		FlxG.state.members[dadPos] = boyfriendGroup;
		FlxG.state.members[bfPos] = dadGroup;
	}

	var boyfriend(get, never):Character;
	var dad(get, never):Character;
	var boyfriendGroup(get, never):FlxTypedSpriteGroup<Character>;
	var dadGroup(get, never):FlxTypedSpriteGroup<Character>;

	function get_boyfriend() return PlayState.instance.boyfriend;
	function get_dad() return PlayState.instance.dad;
	function get_boyfriendGroup() return PlayState.instance.boyfriendGroup;
	function get_dadGroup() return PlayState.instance.dadGroup;
}