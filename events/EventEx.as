// StarlingEx - https://github.com/BladePoint/StarlingEx
// Copyright Doublehead Games, LLC. All rights reserved.
// This code is open source under the MIT License - https://github.com/BladePoint/StarlingEx/blob/master/docs/LICENSE
// Use in conjunction with Starling - https://gamua.com/starling/

package starlingEx.events {

	import starling.errors.AbstractClassError;

	public class EventEx {
		static public const SUCCESS:String = "success",
			FAILURE:String = "failure";

		public function EventEx() {throw new AbstractClassError();}
	}

}
