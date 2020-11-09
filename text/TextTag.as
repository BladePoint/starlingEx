// StarlingEx - https://github.com/BladePoint/StarlingEx
// Copyright Doublehead Games, LLC. All rights reserved.
// This code is open source under the MIT License - https://github.com/BladePoint/StarlingEx/blob/master/docs/LICENSE
// Use in conjunction with Starling - https://gamua.com/starling/

package starlingEx.text {

	import starlingEx.utils.PoolEx;

	/* TextTags are used when parsing format tags in an ApertureTextField. */
	public class TextTag {
		static public const COLOR:String = "color",
			OUTLINE_COLOR:String = "outlineColor",
			OUTLINE_WIDTH:String = "outlineWidth",
			ITALIC:String = "italic",
			UNDERLINE:String = "underline",
			STRIKETHROUGH:String = "strikethrough",
			LINK:String = "link";
		/*  First capture group for end of tag (/)
			Second capture group for tag name
			Third capture group for value		*/
		static public const regExp:RegExp = new RegExp("(?<!\\\\)\\[(\\/?)("+ COLOR +"|"+ OUTLINE_COLOR +"|"+ OUTLINE_WIDTH +"|"+ ITALIC +"|"+ UNDERLINE +"|"+ STRIKETHROUGH +"|"+ LINK +")=?([a-zA-Z0-9\\.,]+)?\\]"); //regExp:RegExp = /(?<!\\)\[(\/?)(italic|underline|strikethrough|link|outlineWidth|outlineColor|color)=?([a-zA-Z0-9\.,]+)?\]/;
		static private var textTagV:Vector.<TextTag> = new <TextTag>[];
		static public function getInstance(tagType:String,startIndex:uint):TextTag {
			var returnTag:TextTag;
			if (textTagV.length == 0) returnTag = new TextTag(tagType,startIndex);
			else {
				returnTag = textTagV.pop();
				returnTag.tagType = tagType;
				returnTag.startIndex = startIndex;
			}
			return returnTag;
		}
		static public function putInstance(textTag:TextTag):void {
			if (textTag) {
				textTag.dispose();
				textTagV[textTagV.length] = textTag;
			}
		}

		public var tagType:String;
		public var startIndex:uint, endIndex:uint;
		public var value:*;
		public function TextTag(tagType:String,startIndex:uint) {
			this.tagType = tagType;
			this.startIndex = startIndex;
		}
		public function setColor(valueString:String):void {
			value = PoolEx.getArray();
			if (valueString.length == 8) value[0] = uint(valueString);
			else if (valueString.length == 17) {
				value[0] = uint(valueString.substr(0,8));
				value[1] = uint(valueString.substr(-8,8));
			} else if (valueString.length == 35) {
				value[0] = uint(valueString.substr(0,8));
				value[1] = uint(valueString.substr(9,8));
				value[2] = uint(valueString.substr(18,8));
				value[3] = uint(valueString.substr(27,8));
			}
		}
		public function setOutlineColor(valueString:String):void {
			value = uint(valueString);
		}
		public function setOutlineWidth(valueString:String):void {
			value = Number(valueString);
		}
		public function dispose():void {
			tagType = null;
			endIndex = 0;
			if (value is Array) {
				PoolEx.putArray(value);
				value = null;
			}
		}

	}

}
