package;

import flixel.FlxG;
import flixel.group.FlxSpriteGroup;

import Character;

class DarnellBlazinHandler
{
	public function new():Void {}

	var cantUppercut:Bool = false;

	public function noteHit(note:Note):Void
	{
		// SPECIAL CASE: If Pico hits a poor note at low health (at 30% chance),
		// Darnell may duck below Pico's punch to attempt an uppercut.
		// TODO: Maybe add a cooldown to this?
		if (wasNoteHitPoorly(note.rating) && isPlayerLowHealth() && FlxG.random.bool(30))
		{
			playUppercutPrepAnim();
			return;
		}

		if (cantUppercut)
		{
			playPunchHighAnim();
			return;
		}

		// Override the hit note animation.
		switch (note.noteType)
		{
			case "weekend-1-punchlow":
				playHitLowAnim();
			case "weekend-1-punchlowblocked":
				playBlockAnim();
			case "weekend-1-punchlowdodged":
				playDodgeAnim();
			case "weekend-1-punchlowspin":
				playSpinAnim();

			case "weekend-1-punchhigh":
				playHitHighAnim();
			case "weekend-1-punchhighblocked":
				playBlockAnim();
			case "weekend-1-punchhighdodged":
				playDodgeAnim();
			case "weekend-1-punchhighspin":
				playSpinAnim();

			// Attempt to punch, Pico dodges or gets hit.
			case "weekend-1-blockhigh":
				playPunchHighAnim();
			case "weekend-1-blocklow":
				playPunchLowAnim();
			case "weekend-1-blockspin":
				playPunchHighAnim();

			// Attempt to punch, Pico dodges or gets hit.
			case "weekend-1-dodgehigh":
				playPunchHighAnim();
			case "weekend-1-dodgelow":
				playPunchLowAnim();
			case "weekend-1-dodgespin":
				playPunchHighAnim();

			// Attempt to punch, Pico ALWAYS gets hit.
			case "weekend-1-hithigh":
				playPunchHighAnim();
			case "weekend-1-hitlow":
				playPunchLowAnim();
			case "weekend-1-hitspin":
				playPunchHighAnim();

			// Fail to dodge the uppercut.
			case "weekend-1-picouppercutprep":
				// Continue whatever animation was playing before
				// playIdleAnim();
			case "weekend-1-picouppercut":
				playUppercutHitAnim();

			// Attempt to punch, Pico dodges or gets hit.
			case "weekend-1-darnelluppercutprep":
				playUppercutPrepAnim();
			case "weekend-1-darnelluppercut":
				playUppercutAnim();

			case "weekend-1-idle":
				playIdleAnim();
			case "weekend-1-fakeout":
				playCringeAnim();
			case "weekend-1-taunt":
				playPissedConditionalAnim();
			case "weekend-1-tauntforce":
				playPissedAnim();
			case "weekend-1-reversefakeout":
				playFakeoutAnim();
		}

		cantUppercut = false;
	}
	
	public function noteMiss(note:Note):Void
	{
		// SPECIAL CASE: Darnell prepared to uppercut last time and Pico missed! FINISH HIM!
		if (dad.getAnimationName() == 'uppercutPrep')
		{
			playUppercutAnim();
			return;
		}

		if (willMissBeLethal())
		{
			playPunchLowAnim();
			return;
		}

		if (cantUppercut)
		{
			playPunchHighAnim();
			return;
		}

		// Override the hit note animation.
		switch (note.noteType)
		{
			// Pico tried and failed to punch, punch back!
			case "weekend-1-punchlow":
				playPunchLowAnim();
			case "weekend-1-punchlowblocked":
				playPunchLowAnim();
			case "weekend-1-punchlowdodged":
				playPunchLowAnim();
			case "weekend-1-punchlowspin":
				playPunchLowAnim();

			// Pico tried and failed to punch, punch back!
			case "weekend-1-punchhigh":
				playPunchHighAnim();
			case "weekend-1-punchhighblocked":
				playPunchHighAnim();
			case "weekend-1-punchhighdodged":
				playPunchHighAnim();
			case "weekend-1-punchhighspin":
				playPunchHighAnim();

			// Attempt to punch, Pico dodges or gets hit.
			case "weekend-1-blockhigh":
				playPunchHighAnim();
			case "weekend-1-blocklow":
				playPunchLowAnim();
			case "weekend-1-blockspin":
				playPunchHighAnim();

			// Attempt to punch, Pico dodges or gets hit.
			case "weekend-1-dodgehigh":
				playPunchHighAnim();
			case "weekend-1-dodgelow":
				playPunchLowAnim();
			case "weekend-1-dodgespin":
				playPunchHighAnim();

			// Attempt to punch, Pico ALWAYS gets hit.
			case "weekend-1-hithigh":
				playPunchHighAnim();
			case "weekend-1-hitlow":
				playPunchLowAnim();
			case "weekend-1-hitspin":
				playPunchHighAnim();

			// Successfully dodge the uppercut.
			case "weekend-1-picouppercutprep":
				playHitHighAnim();
				cantUppercut = true;
			case "weekend-1-picouppercut":
				playDodgeAnim();

			// Attempt to punch, Pico dodges or gets hit.
			case "weekend-1-darnelluppercutprep":
				playUppercutPrepAnim();
			case "weekend-1-darnelluppercut":
				playUppercutAnim();

			case "weekend-1-idle":
				playIdleAnim();
			case "weekend-1-fakeout":
				playCringeAnim(); // TODO: Which anim?
			case "weekend-1-taunt":
				playPissedConditionalAnim();
			case "weekend-1-tauntforce":
				playPissedAnim();
			case "weekend-1-reversefakeout":
				playFakeoutAnim(); // TODO: Which anim?
		}
		cantUppercut = false;
	}

	public function noteMissPress(direction:Int):Void
	{
		if (willMissBeLethal())
			playPunchLowAnim(); // Darnell alternates a punch so that Pico dies.
		else
		{
			// Pico wildly throws punches but Darnell alternates between dodges and blocks.
			var shouldDodge = FlxG.random.bool(50); // 50/50.
			if (shouldDodge)
				playDodgeAnim();
			else
				playBlockAnim();
		}
	}
	
	var alternate:Bool = false;

	function doAlternate():String
	{
		alternate = !alternate;
		return alternate ? '1' : '2';
	}

	function playBlockAnim():Void
	{
		dad.playAnim('block', true);
		PlayState.instance.camGame.shake(0.002, 0.1);
		moveToBack();
	}

	function playCringeAnim():Void
	{
		dad.playAnim('cringe', true);
		moveToBack();
	}

	function playDodgeAnim():Void
	{
		dad.playAnim('dodge', true, false);
		moveToBack();
	}

	function playIdleAnim():Void
	{
		dad.playAnim('idle', false);
		moveToBack();
	}

	function playFakeoutAnim():Void
	{
		dad.playAnim('fakeout', true);
		moveToBack();
	}

	function playPissedConditionalAnim():Void
	{
		if (dad.getAnimationName() == "cringe")
			playPissedAnim();
		else
			playIdleAnim();
	}

	function playPissedAnim():Void
	{
		dad.playAnim('pissed', true);
		moveToBack();
	}

	function playUppercutPrepAnim():Void
	{
		dad.playAnim('uppercutPrep', true);
		moveToFront();
	}

	function playUppercutAnim():Void
	{
		dad.playAnim('uppercut', true);
		moveToFront();
	}

	function playUppercutHitAnim():Void
	{
		dad.playAnim('uppercutHit', true);
		moveToBack();
	}

	function playHitHighAnim():Void
	{
		dad.playAnim('hitHigh', true);
		PlayState.instance.camGame.shake(0.0025, 0.15);
		moveToBack();
	}

	function playHitLowAnim():Void
	{
		dad.playAnim('hitLow', true);
		PlayState.instance.camGame.shake(0.0025, 0.15);
		moveToBack();
	}

	function playPunchHighAnim():Void
	{
		dad.playAnim('punchHigh' + doAlternate(), true);
		moveToFront();
	}

	function playPunchLowAnim():Void
	{
		dad.playAnim('punchLow' + doAlternate(), true);
		moveToFront();
	}

	function playSpinAnim():Void
	{
		dad.playAnim('hitSpin', true);
		PlayState.instance.camGame.shake(0.0025, 0.15);
		moveToBack();
	}
	
	function willMissBeLethal():Bool
	{
		return PlayState.instance.health <= 0.0 && !PlayState.instance.practiceMode;
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
		var dadPos:Int = FlxG.state.members.indexOf(dadGroup);
		var bfPos:Int = FlxG.state.members.indexOf(boyfriendGroup);
		if (dadPos < bfPos) return;

		FlxG.state.members[bfPos] = dadGroup;
		FlxG.state.members[dadPos] = boyfriendGroup;
	}

	function moveToFront():Void
	{
		var dadPos:Int = FlxG.state.members.indexOf(dadGroup);
		var bfPos:Int = FlxG.state.members.indexOf(boyfriendGroup);
		if (dadPos > bfPos) return;

		FlxG.state.members[bfPos] = dadGroup;
		FlxG.state.members[dadPos] = boyfriendGroup;
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