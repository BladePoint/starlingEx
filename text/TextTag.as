// StarlingEx - https://github.com/BladePoint/StarlingEx
// Copyright Doublehead Games, LLC. All rights reserved.
// This code is open source under the MIT License - https://github.com/BladePoint/StarlingEx/blob/master/docs/LICENSE
// Use in conjunction with Starling - https://gamua.com/starling/

package starlingEx.text {

	import starlingEx.utils.PoolEx;

	/* TextTags are used when parsing format tags in an ApertureTextField. */
	public class TextTag {
		static public const FONT:String = "font",
			SIZE:String = "size",
			OFFSET_Y:String = "offsetY",
			COLOR:String = "color",
			OUTLINE_COLOR:String = "outlineColor",
			OUTLINE_WIDTH:String = "outlineWidth",
			ITALIC:String = "italic",
			UNDERLINE:String = "underline",
			STRIKETHROUGH:String = "strikethrough",
			LINK:String = "link";
		/*  First capture group for end of tag (/)
			Second capture group for tag name
			Third capture group for value		*/
		static public const regExp:RegExp = new RegExp("(?<!\\\\)\\[(\\/?)(" +
				FONT + "|" +
				SIZE + "|" +
				OFFSET_Y + "|" +
				COLOR + "|"+
				OUTLINE_COLOR + "|" +
				OUTLINE_WIDTH + "|" +
				ITALIC + "|" +
				UNDERLINE + "|" +
				STRIKETHROUGH + "|" +
				LINK +
			")=?([a-zA-Z0-9'\"\\.,-]+)?\\]"), //regExp:RegExp = /(?<!\\)\[(\/?)(font|size|offsetY|color|outlineColor|outlineWidth|italic|underline|strikethrough|link)=?([a-zA-Z0-9'"\.,-]+)?\]/;
			apostrapheQuotationPattern:RegExp = /['"]/g;
		static private const textTagV:Vector.<TextTag> = new <TextTag>[];
		static public function getInstance(tagType:String,startIndex:uint,valueString:String):TextTag {
			var returnTag:TextTag;
			if (textTagV.length == 0) returnTag = new TextTag(tagType,startIndex,valueString);
			else {
				returnTag = textTagV.pop();
				returnTag.tagType = tagType;
				returnTag.startIndex = startIndex;
				returnTag.parseValue(valueString);
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
		public function TextTag(tagType:String,startIndex:uint,valueString:String) {
			this.tagType = tagType;
			this.startIndex = startIndex;
			parseValue(valueString);
		}
		private function parseValue(valueString:String):void {
			if (valueString) {
				if (tagType == FONT) setValueFont(valueString);
				else if (tagType == SIZE) setValueNumber(valueString);
				else if (tagType == OFFSET_Y) setValueNumber(valueString);
				else if (tagType == COLOR) setValueColorArray(valueString);
				else if (tagType == OUTLINE_COLOR) setValueUint(valueString);
				else if (tagType == OUTLINE_WIDTH) setValueNumber(valueString);
			}
		}
		private function setValueFont(valueString:String):void {
			const strippedString:String = valueString.replace(apostrapheQuotationPattern,"");
			setValueString(strippedString);
		}
		private function setValueString(valueString:String):void {
			value = valueString;
		}
		private function setValueNumber(valueString:String):void {
			value = Number(valueString);
		}
		private function setValueColorArray(valueString:String):void {
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
		private function setValueUint(valueString:String):void {
			value = uint(valueString);
		}
		public function dispose():void {
			tagType = null;
			startIndex = endIndex = 0;
			if (value is Array) PoolEx.putArray(value);
			value = null;
		}

	}

}
