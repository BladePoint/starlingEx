// StarlingEx - https://github.com/BladePoint/StarlingEx
// Copyright Doublehead Games, LLC. All rights reserved.
// This code is open source under the MIT License - https://github.com/BladePoint/StarlingEx/blob/master/docs/LICENSE
// Use in conjunction with Starling - https://gamua.com/starling/

package starlingEx.text {

	import flash.utils.Dictionary;
	import starling.core.Starling;
	import starling.errors.AbstractClassError;
	import starling.text.TextOptions;
	import starling.utils.Align;
	import starling.utils.StringUtil;
	import starlingEx.text.BitmapCharEx;
	import starlingEx.text.CharLocation;
	import starlingEx.text.TagObject;
	import starlingEx.text.TextFieldEx;
	import starlingEx.text.TextFormatEx;
	import starlingEx.text.TextLink;
	import starlingEx.text.TextTag;
	import starlingEx.utils.PoolEx;
	import starlingEx.utils.Utils;

	public class Compositor {
		static public const defaultItalicRadians:Number = 0.2617993877991494/*15 degrees*/,
			defaultSinItalicRadians:Number = 0.25881904510252074, 
			defaultThreshold:Number = .5,
			defaultLineThicknessProportion:Number = .044,
			defaultBaselineProportion:Number = .76,
			defaultUnderlineProportion:Number = .88;
		static private const FONT_DATA_NAME:String = "starlingEx.text.Compositor.fonts";
		static private function get fonts():Dictionary {
			var fonts:Dictionary = Starling.painter.sharedData[FONT_DATA_NAME] as Dictionary;
			if (fonts == null) {
				fonts = new Dictionary();
				Starling.painter.sharedData[FONT_DATA_NAME] = fonts;
			}
			return fonts;
		}
		/* Font names may only consist of the following characters: a-z, A-Z, 0-9, comma(,) period(.) hyphen(-). */
		static public function registerFont(iFont:IFont,fontName:String):void {
			if (fontName == null) throw new ArgumentError("fontName must not be null");
			fonts[Utils.convertToLowerCase(fontName)] = iFont;
		}
		static public function unregisterCompositor(fontName:String,dispose:Boolean=true):void {
			fontName = Utils.convertToLowerCase(fontName);
			if (dispose && fonts[fontName] != undefined) fonts[fontName].dispose();
			delete fonts[fontName];
		}
		static public function getFont(fontName:String):IFont {
			const font:IFont = fonts[Utils.convertToLowerCase(fontName)];
			if (font == null) throw new ArgumentError("'" + fontName + "' is not a registered font.");
			return font;
		}
		static public const CHAR_MISSING:int = 0,
			CHAR_TAB:int = 9,
			CHAR_NEWLINE:int = 10,
			CHAR_CARRIAGE_RETURN:int = 13,
			CHAR_SPACE:int = 32,
			CHAR_NON:int = -1;
		static private function testCharQuad(charLocation:CharLocation):Boolean {
			const charID:int = charLocation.char.charID;
			if (charID == CHAR_MISSING || charID == CHAR_TAB || charID == CHAR_NEWLINE || charID == CHAR_CARRIAGE_RETURN || charID == CHAR_SPACE || charID == CHAR_NON) return false;
			else return true;
		}
		static public function getBaselineProportion(iFont:IFont):Number {
			var baselineProportion:Number = iFont.baselineProportion;
			if (isNaN(baselineProportion)) baselineProportion = defaultBaselineProportion;
			return baselineProportion;
		}
		static public function getUnderlineProportion(iFont:IFont):Number {
			var underlineProportion:Number = iFont.underlineProportion;
			if (isNaN(underlineProportion)) underlineProportion = defaultUnderlineProportion;
			return underlineProportion;
		}
		static public function fillContainer(textField:TextFieldEx,width:Number,height:Number):Vector.<CharLocation> {
			const text:String = textField.text;
			const textFormat:TextFormatEx = textField.format;
			const options:TextOptions = textField.options;
			const addToTextSprite:Function = textField.addToTextSprite;
			const charLocationV:Vector.<CharLocation> = arrangeLocations(textField,text,textFormat,options,width,height);
			const fontO:Object = PoolEx.getObject();
			const formatFont:IFont = getFont(textFormat.font);
			var strikethroughPosition:String,
				underlinePosition:String,
				linkPosition:String;
			var strikethroughSplit:Boolean,
				underlineSplit:Boolean,
				linkSplit:Boolean;
			var textLink:TextLink;
			const l:uint = charLocationV.length;
			for (var i:int=0; i<l; i++) {
				const current_CL:CharLocation = charLocationV[i];
				var strikethroughStart_CL:CharLocation,
					underlineStart_CL:CharLocation,
					linkStart_CL:CharLocation;
				const currentFont:IFont = current_CL.char.font;
				if (fontO[currentFont.name] == null) {
					currentFont.initFormat(textFormat);
					fontO[currentFont.name] = currentFont;
				}
				if (testCharQuad(current_CL)) {
					current_CL.initQuad();
					textField.addToTextSprite(current_CL.quad);
				}
				if (current_CL.getItalicPosition(i)) current_CL.initItalic();
				strikethroughPosition = current_CL.getStrikethroughPosition(i);
				if (strikethroughPosition == TagObject.START) {
					strikethroughStart_CL = current_CL;
					current_CL.initStrikethrough(strikethroughStart_CL);
					strikethroughSplit = current_CL.testSplit(TextTag.STRIKETHROUGH,strikethroughStart_CL,addToTextSprite);
				} else if (strikethroughPosition == TagObject.MIDDLE) {
					if (strikethroughSplit) current_CL.initStrikethrough(strikethroughStart_CL);
					strikethroughSplit = current_CL.testSplit(TextTag.STRIKETHROUGH,strikethroughStart_CL,addToTextSprite);
				} else if (strikethroughPosition == TagObject.END) {
					current_CL.finiStrikethrough(strikethroughStart_CL,addToTextSprite);
					strikethroughSplit = false;
				}
				underlinePosition = current_CL.getUnderlinePosition(i);
				if (underlinePosition == TagObject.START) {
					underlineStart_CL = current_CL;
					current_CL.initUnderline(underlineStart_CL);
					underlineSplit = current_CL.testSplit(TextTag.UNDERLINE,underlineStart_CL,addToTextSprite);
				} else if (underlinePosition == TagObject.MIDDLE) {
					if (underlineSplit) current_CL.initUnderline(underlineStart_CL);
					underlineSplit = current_CL.testSplit(TextTag.UNDERLINE,underlineStart_CL,addToTextSprite);
				} else if (underlinePosition == TagObject.END) {
					current_CL.finiUnderline(underlineStart_CL,addToTextSprite);
					underlineSplit = false;
				}
				linkPosition = current_CL.getLinkPosition(i);
				if (linkPosition == TagObject.START) {
					linkStart_CL = current_CL;
					textLink = current_CL.initLink(linkStart_CL);
					textField.addTextLink(textLink);
					linkSplit = current_CL.testSplit(TextTag.LINK,linkStart_CL,addToTextSprite);
					textLink.addCharLocation(current_CL);
				} else if (linkPosition == TagObject.MIDDLE) {
					if (linkSplit) current_CL.initLink(linkStart_CL);
					linkSplit = current_CL.testSplit(TextTag.LINK,linkStart_CL,addToTextSprite);
					textLink.addCharLocation(current_CL);
				} else if (linkPosition == TagObject.END) {
					current_CL.finiLink(linkStart_CL,addToTextSprite);
					linkSplit = false;
					textLink.addCharLocation(current_CL,true);
				}
				current_CL.initOffsetY();
			}
			PoolEx.putObject(fontO);
			return charLocationV;
		}
		static public function arrangeLocations(textField:TextFieldEx,text:String,textFormat:TextFormatEx,options:TextOptions,width:Number,height:Number):Vector.<CharLocation> {
			if (text == null || text.length == 0) return CharLocation.getVector();
			const formatFont:IFont = getFont(textFormat.font);
			const fontSize:Number = formatFont.size,
				padding:Number = formatFont.padding,
				formatSize:Number = textFormat.size,
				leading:Number = textFormat.leading,
				spacing:Number = textFormat.letterSpacing,
				formatFontLineHeight:Number = formatFont.lineHeight,
				formatFontOffsetX:Number = formatFont.offsetX,
				formatFontOffsetY:Number = formatFont.offsetY;
			var scale:Number, containerWidth:Number, containerHeight:Number;
			const kerning:Boolean = textFormat.kerning,
				autoScale:Boolean = options.autoScale;
			var finished:Boolean = false;
			const hAlign:String = textFormat.horizontalAlign,
				vAlign:String = textFormat.verticalAlign;
			const sLines:Array = PoolEx.getArray();
			var current_CL:CharLocation;
			var numChars:int, i:int, j:int;
			var autoScaleSizeReduction:uint;
			while (!finished) {
				sLines.length = 0;
				scale = (formatSize - autoScaleSizeReduction) / fontSize;
				containerWidth  = (width  - 2 * padding) / scale;
				containerHeight = (height - 2 * padding) / scale;
				if (fontSize <= containerHeight) {
					var lastWhiteSpace:int = -1,
						lastCharID:int = -1;
					var currentX:Number = 0,
						currentY:Number = 0;
					var currentLine:Vector.<CharLocation> = CharLocation.getVector();
					numChars = text.length;
					for (i=0; i<numChars; ++i) {
						const tagObject:TagObject = textField.getTagObject(i);
						const tagSize:Number = TagObject.getSize(tagObject,formatSize),
							tagScale:Number = tagSize / formatSize;
						const iFont:IFont = TagObject.getFont(tagObject,formatFont);
						var lineFull:Boolean = false;
						const charID:int = text.charCodeAt(i);
						var bitmapChar:BitmapCharEx;
						if (charID == CHAR_NEWLINE || charID == CHAR_CARRIAGE_RETURN) {
							lineFull = true;
							bitmapChar = iFont.getChar(CHAR_NON);
						} else if (charID == CHAR_SPACE || charID == CHAR_TAB) {
							lastWhiteSpace = i;
							bitmapChar = testID(iFont,charID,text,i);
						} else bitmapChar = testID(iFont,charID,text,i);
						if (kerning) currentX += bitmapChar.getKerning(lastCharID);
						current_CL = CharLocation.getInstance(bitmapChar,textFormat,tagObject);
						current_CL.x = currentX + bitmapChar.xOffset * tagScale;
						current_CL.y = currentY + bitmapChar.yOffset * tagScale + formatFontLineHeight * (1-tagScale) * getBaselineProportion(iFont);
						current_CL.scale = current_CL.tagScale = tagScale;
						currentLine[currentLine.length] = current_CL;
						currentX += bitmapChar.xAdvance * tagScale;
						if (bitmapChar.charID != CHAR_NON && bitmapChar.charID != CHAR_MISSING) currentX += spacing;
						lastCharID = charID;
						if (current_CL.x + bitmapChar.width > containerWidth) {
							if (options.wordWrap) {
								if (autoScale && lastWhiteSpace == -1) {//when autoscaling, we must not split a word in half -> restart
									CharLocation.putVector(currentLine,true);
									break;
								}
								const numCharsToRemove:int = lastWhiteSpace == -1 ? 1 : i - lastWhiteSpace; // remove characters and add them again to next line
								for (j=0; j<numCharsToRemove; ++j) CharLocation.putInstance(currentLine.pop());
								if (currentLine.length == 0) {
									CharLocation.putVector(currentLine,true);
									break;
								}
								i -= numCharsToRemove;
							} else {
								if (autoScale) {
									CharLocation.putVector(currentLine,true);
									break;
								}
								CharLocation.putInstance(currentLine.pop());
								while (i < numChars - 1 && text.charCodeAt(i) != CHAR_NEWLINE) ++i; // continue with next line, if there is one
							}
							lineFull = true;
						}
						if (i == numChars - 1) {
							sLines[sLines.length] = currentLine;
							finished = true;
						} else if (lineFull) {
							sLines[sLines.length] = currentLine;
							if (currentY + formatFontLineHeight + leading + fontSize <= containerHeight) {
								currentLine = CharLocation.getVector();
								currentX = 0;
								currentY += formatFontLineHeight + leading;
								lastWhiteSpace = -1;
								lastCharID = -1;
							} else {
								CharLocation.putVector(currentLine,true);
								break;
							}
						}
					} // for each bitmapChar
				} // if (_lineHeight <= containerHeight)
				if (autoScale && !finished && formatSize - autoScaleSizeReduction > 3) autoScaleSizeReduction += 1;
				else finished = true; 
			} // while (!finished)
			const finalLocations:Vector.<CharLocation> = CharLocation.getVector();
			const numLines:int = sLines.length;
			const bottom:Number = currentY + formatFontLineHeight;
			var yOffset:int = 0;
			if (vAlign == Align.BOTTOM)      yOffset =  containerHeight - bottom;
			else if (vAlign == Align.CENTER) yOffset = (containerHeight - bottom) / 2;
			for (var lineID:int=0; lineID<numLines; ++lineID) {
				const line:Vector.<CharLocation> = sLines[lineID];
				numChars = line.length;
				if (numChars == 0) continue;
				var xOffset:int = 0;
				const lastLocation:CharLocation = line[line.length-1];
				lastLocation.endOfLine = true;
				const right:Number = lastLocation.x - lastLocation.char.xOffset 
					+ lastLocation.char.xAdvance;
				if (hAlign == Align.RIGHT)		 xOffset =  containerWidth - right;
				else if (hAlign == Align.CENTER) xOffset = (containerWidth - right) / 2;
				for (var c:int=0; c<numChars; ++c) {
					current_CL = line[c];
					current_CL.rowNumber = lineID;
					current_CL.x = scale * (current_CL.x + xOffset + formatFontOffsetX) + padding;
					current_CL.y = scale * (current_CL.y + yOffset + formatFontOffsetY) + padding;
					current_CL.scale *= scale;
					finalLocations[finalLocations.length] = current_CL;
				}
				CharLocation.putVector(line);
			}
			PoolEx.putArray(sLines);
			return finalLocations;
		}
		static private function testID(iFont:IFont,charID:int,text:String,i:uint):BitmapCharEx {
			var bitmapChar:BitmapCharEx = iFont.getChar(charID);
			if (bitmapChar == null) {
				trace(StringUtil.format("[Starling] Character '{0}' (id: {1}) not found in '{2}'",text.charAt(i),charID,iFont.name));
				bitmapChar = iFont.getChar(CHAR_MISSING);
			}
			return bitmapChar;
		}
		static public function fillShadow(charLocationV:Vector.<CharLocation>):void {
			const l:uint = charLocationV.length;
			for (var i:uint=0; i<l; i++) {
				const current_CL:CharLocation = charLocationV[i];
				current_CL.initShadow();
			}
		}
		
		public function Compositor() {throw new AbstractClassError();}
	}
}
