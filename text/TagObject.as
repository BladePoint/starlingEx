// StarlingEx - https://github.com/BladePoint/StarlingEx
// Copyright Doublehead Games, LLC. All rights reserved.
// This code is open source under the MIT License - https://github.com/BladePoint/StarlingEx/blob/master/docs/LICENSE
// Use in conjunction with Starling - https://gamua.com/starling/

package starlingEx.text {

	import starlingEx.text.TextTag;

	/* For each character in an ApertureTextField, a TagObject is used to store TextTag formatting information. */
	public class TagObject {
		static public const START:String = "start",
			MIDDLE:String = "middle",
			END:String = "end";
		static private var tagObjectV:Vector.<TagObject> = new <TagObject>[];
		static public function getTagObject():TagObject {
			if (tagObjectV.length == 0) return new TagObject();
			else return tagObjectV.pop();
		}
		static public function putTagObject(tagObject:TagObject):void {
			if (tagObject) {
				tagObject.dispose();
				tagObjectV[tagObjectV.length] = tagObject;
			}
		}

		public var color:TextTag, outlineColor:TextTag, outlineWidth:TextTag, italic:TextTag, underline:TextTag, strikethrough:TextTag, link:TextTag;
		public function TagObject() {}
		public function testFormatTag(tagType:String,index:uint):String {
			var returnString:String;
			var textTag:TextTag = this[tagType];
			if (textTag) {
				if (textTag.startIndex == index) returnString = START;
				else if (textTag.endIndex == index) returnString = END;
				else returnString = MIDDLE;
			}
			return returnString;
		}
		public function testValueTag(tagType:String):* {
			var returnValue:*;
			var textTag:TextTag = this[tagType];
			if (textTag) returnValue = textTag.value;
			return returnValue;
		}
		public function dispose():void {
			color = outlineColor = outlineWidth = italic = underline = strikethrough = link = null;
		}

	}

}
