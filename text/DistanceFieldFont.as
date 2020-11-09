// StarlingEx - https://github.com/BladePoint/StarlingEx
// Copyright Doublehead Games, LLC. All rights reserved.
// This code is open source under the MIT License - https://github.com/BladePoint/StarlingEx/blob/master/docs/LICENSE
// Use in conjunction with Starling - https://gamua.com/starling/

package starlingEx.text {

	import flash.display.BitmapData;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	import starling.display.DisplayObject;
	import starling.display.Mesh;
	import starling.display.Quad;
	import starling.styles.MeshStyle;
	import starling.text.BitmapChar;
	import starling.text.BitmapFontType;
	import starling.text.TextFormat;
	import starling.text.TextOptions;
	import starling.textures.Texture;
	import starling.textures.TextureSmoothing;
	import starling.utils.Align;
	import starling.utils.deg2rad;
	import starling.utils.Pool;
	import starling.utils.StringUtil;
	import starlingEx.display.ApertureQuad;
	import starlingEx.display.ApertureSprite;
	import starlingEx.styles.ApertureDistanceFieldStyle;
	import starlingEx.text.ApertureTextField;
	import starlingEx.text.ApertureTextFormat;
	import starlingEx.text.CharLocation;
	import starlingEx.text.IDistanceCompositor;
	import starlingEx.text.TagObject;
	import starlingEx.text.TextLink;
	import starlingEx.utils.PoolEx;

	/* A DistanceFieldFont parses a distance field bitmap and corresponding XML font file to create a Texture with which BitmapChar
	   subtextures of letters can be used to display letters. Much of this code is appropriated from starling.text.BitmapFont. */
	public class DistanceFieldFont implements IDistanceCompositor {
		static private const CHAR_MISSING:int = 0, CHAR_TAB:int = 9, CHAR_NEWLINE:int = 10, CHAR_CARRIAGE_RETURN:int = 13, CHAR_SPACE:int = 32, CHAR_NON:int = -1;
		static private const italicRadians:Number = deg2rad(15);
		static private var charQuadV:Vector.<ApertureQuad> = new <ApertureQuad>[];
		static public function getCharQuad():ApertureQuad {
			var charQuad:ApertureQuad;
			if (charQuadV.length == 0) {
				Mesh.defaultStyleFactory = charQuadStyleFactory;
				charQuad = new ApertureQuad();
				Mesh.defaultStyleFactory = null;
			}
			else charQuad = charQuadV.pop();
			charQuad.touchable = false;
			return charQuad;
		}
		static public function putCharQuad(charQuad:ApertureQuad):void {
			if (charQuad) {
				charQuad.alignPivot(Align.LEFT,Align.TOP);
				charQuad.skewX = 0;
				charQuadV[charQuadV.length] = charQuad;
			}
		}
		static private var factorySoftness:Number;
		static private function charQuadStyleFactory():ApertureDistanceFieldStyle {
			return new ApertureDistanceFieldStyle(factorySoftness);
		}
		static private var textLineQuadV:Vector.<ApertureQuad> = new <ApertureQuad>[];
		static public function getTextLineQuad(w:Number,h:Number,multiChannel:Boolean):ApertureQuad {
			var lineQuad:ApertureQuad;
			if (textLineQuadV.length == 0) {
				Mesh.defaultStyle = ApertureDistanceFieldStyle;
				lineQuad = new ApertureQuad(w,h);
				Mesh.defaultStyle = MeshStyle;
				var adfs:ApertureDistanceFieldStyle = lineQuad.style as ApertureDistanceFieldStyle;
				adfs.multiChannel = multiChannel;
				adfs.setupOutline(0,0x000000,1,false);
			}
			else {
				lineQuad = textLineQuadV.pop();
				lineQuad.readjustSize(w,h);
			}
			lineQuad.touchable = false;
			return lineQuad;
		}
		static public function putTextLineQuad(lineQuad:ApertureQuad):void {
			if (lineQuad) textLineQuadV[textLineQuadV.length] = lineQuad;
		}
		static private function testNonChar(current_CL:CharLocation):Boolean {
			var charID:int = current_CL.char.charID;
			if (charID == CHAR_MISSING || charID == CHAR_NON) return true;
			else return false;
		}
		static private function testNonQuad(current_CL:CharLocation):Boolean {
			var charID:int = current_CL.char.charID;
			if (charID == CHAR_MISSING || charID == CHAR_TAB || charID == CHAR_NEWLINE || charID == CHAR_CARRIAGE_RETURN || charID == CHAR_SPACE || charID == CHAR_NON) return true;
			else return false;
		}

		public var underlineHeightPercent:Number = .82;
		private var bitmapData:BitmapData;
		private var _offsetX:Number, _offsetY:Number, _padding:Number, _size:Number, _lineHeight:Number, _baseline:Number, _distanceFieldSpread:Number;
		private var _chars:Dictionary;
		private var _name:String, _type:String, _smoothing:String;
		private var _texture:Texture, _whiteTexture:Texture;
		public function DistanceFieldFont(bitmapData:BitmapData,fontXML:XML) {
			this.bitmapData = bitmapData;
			_offsetX = _offsetY = _padding = 0.0;
			_chars = new Dictionary();
			addMissing();
			addNonChar();
			parseXmlData(fontXML);
			parseXmlChar(fontXML);
		}
		protected function addMissing():void {
			addChar(CHAR_MISSING,new BitmapChar(CHAR_MISSING,null,0,0,0));
		}
		protected function addNonChar():void {
			addChar(CHAR_NON,new BitmapChar(CHAR_NON,null,0,0,0));
		}
		protected function addChar(charID:int,bitmapChar:BitmapChar):void {
			_chars[charID] = bitmapChar;
		}
		protected function getChar(charID:int):BitmapChar {
			return _chars[charID];
		}
		private function parseXmlData(fontXML:XML):void {
			_name = StringUtil.clean(fontXML.info.@face);
			_size = parseFloat(fontXML.info.@size);
			_lineHeight = parseFloat(fontXML.common.@lineHeight);
			_baseline = parseFloat(fontXML.common.@base);
			if (fontXML.info.@smooth.toString() == "0") _smoothing = TextureSmoothing.NONE;
			if (_size <= 0) throw new Error("Warning: invalid font size in '" + _name + "' font.");
			_distanceFieldSpread = parseFloat(fontXML.distanceField.@distanceRange);
			_type = fontXML.distanceField.@fieldType == "msdf" ? BitmapFontType.MULTI_CHANNEL_DISTANCE_FIELD : BitmapFontType.DISTANCE_FIELD;
		}
		protected function parseXmlChar(fontXML:XML):void {
			_texture = Texture.fromBitmapData(bitmapData);
			for each (var charElement:XML in fontXML.chars.char) {
				var id:int = parseInt(charElement.@id);
				var xOffset:Number = parseFloat(charElement.@xoffset);
				var yOffset:Number = parseFloat(charElement.@yoffset);
				var xAdvance:Number = parseFloat(charElement.@xadvance);
				var region:Rectangle = Pool.getRectangle(
					parseFloat(charElement.@x),
					parseFloat(charElement.@y),
					parseFloat(charElement.@width),
					parseFloat(charElement.@height)
				);
				var texture:Texture = Texture.fromTexture(_texture,region);
				Pool.putRectangle(region);
				var bitmapChar:BitmapChar = new BitmapChar(id,texture,xOffset,yOffset,xAdvance); 
				addChar(id,bitmapChar);
			}
			for each (var kerningElement:XML in fontXML.kernings.kerning) {
				var first:int = parseInt(kerningElement.@first);
				var second:int = parseInt(kerningElement.@second);
				var amount:Number = parseFloat(kerningElement.@amount);
				if (second in _chars) getChar(second).addKerning(first,amount);
			}
		}
		/* In order to not require an additional draw call when using strikethroughs or underlines, coordinates for a 1x1 pure white
		   area of the initial bitmap should be assigned. */
		public function setWhiteTexture(x:uint,y:uint):void {
			var whiteRect:Rectangle = Pool.getRectangle(x,y,1,1);
			_whiteTexture = Texture.fromTexture(_texture,whiteRect);
			Pool.putRectangle(whiteRect);
		}
		public function getWhiteTexture():Texture {return _whiteTexture;}
		public function fillContainer(textField:ApertureTextField,width:Number,height:Number):Vector.<CharLocation> {
			var charLocationV:Vector.<CharLocation> = arrangeLocations(width,height,textField);
			var format:ApertureTextFormat = textField.apertureFormat;
			factorySoftness = getDefaultSoftness(format);
			var container_AS:ApertureSprite = textField.container_AS;
			var textLineInnerH:uint = Math.max(1,Math.round(format.size/21)); //default line thickness
			var l:uint = charLocationV.length;
			for (var i:int=0; i<l; i++) {
				var current_CL:CharLocation = charLocationV[i],
					strikethroughStart_CL:CharLocation,
					underlineStart_CL:CharLocation,
					linkStart_CL:CharLocation;
				var strikethroughSplit:Boolean,
					underlineSplit:Boolean,
					linkSplit:Boolean;
				var textLink:TextLink;
				textField.applyFormatTags(i,current_CL);
				var charQuad:ApertureQuad;
				if (!testNonQuad(current_CL)) {
					charQuad = getCharQuad();
					current_CL.setQuad(charQuad as ApertureQuad,multiChannel);
					charQuad.texture = current_CL.char.texture;
					charQuad.readjustSize();
					charQuad.x = current_CL.x;
					charQuad.y = current_CL.y;
					charQuad.scale = current_CL.scale;
					if (current_CL.italic) {
						charQuad.alignPivot(Align.LEFT,Align.BOTTOM);
						charQuad.x -= charQuad.pivotY * Math.sin(italicRadians) / 2;
						charQuad.y += charQuad.pivotY * charQuad.scale;
						charQuad.skewX = italicRadians;
					}
				}
				textField.initCharColorAndOutline(i,current_CL);
				if (current_CL.strikethrough == TagObject.START) {
					if (!strikethroughSplit) strikethroughStart_CL = current_CL;
					current_CL.initStrikethrough(strikethroughStart_CL,getTextLineQuad,multiChannel,getWhiteTexture(),textLineInnerH,_lineHeight,format.leading);
					strikethroughSplit = current_CL.testSplit(TextTag.STRIKETHROUGH,strikethroughStart_CL,container_AS,charLocationV[i+1]);
				} else if (current_CL.strikethrough == TagObject.MIDDLE) strikethroughSplit = current_CL.testSplit(TextTag.STRIKETHROUGH,strikethroughStart_CL,container_AS,charLocationV[i+1]);
				else if (current_CL.strikethrough == TagObject.END) {
					current_CL.finiStrikethrough(strikethroughStart_CL,container_AS);
					strikethroughSplit = false;
				}
				if (current_CL.underline == TagObject.START) {
					if (!underlineSplit) underlineStart_CL = current_CL;
					current_CL.initUnderline(underlineStart_CL,getTextLineQuad,multiChannel,getWhiteTexture(),textLineInnerH,_lineHeight,format.leading,underlineHeightPercent);
					underlineSplit = underlineStart_CL.testSplit(TextTag.UNDERLINE,underlineStart_CL,container_AS,charLocationV[i+1]);
				} else if (current_CL.underline == TagObject.MIDDLE) underlineSplit = current_CL.testSplit(TextTag.UNDERLINE,underlineStart_CL,container_AS,charLocationV[i+1]);
				else if (current_CL.underline == TagObject.END) {
					current_CL.finiUnderline(underlineStart_CL,container_AS);
					underlineSplit = false;
				}
				if (current_CL.link == TagObject.START) {
					if (!linkSplit) {
						linkStart_CL = current_CL;
						textLink = linkStart_CL.initTextLink(_lineHeight,format.leading,underlineHeightPercent);
						textLink.getTextLineQuad = getTextLineQuad;
						textLink.putTextLineQuad = putTextLineQuad;
						textLink.multiChannel = multiChannel;
						textField.addTextLink(textLink);
					}
					current_CL.initLink(linkStart_CL,getTextLineQuad,multiChannel,getWhiteTexture(),textLineInnerH,_lineHeight,format.leading,underlineHeightPercent);
					linkSplit = linkStart_CL.testSplit(TextTag.LINK,linkStart_CL,container_AS,charLocationV[i+1]);
					textLink.addCharLocation(current_CL);
				} else if (current_CL.link == TagObject.MIDDLE) {
					linkSplit = current_CL.testSplit(TextTag.LINK,linkStart_CL,container_AS,charLocationV[i+1]);
					textLink.addCharLocation(current_CL);
				} else if (current_CL.link == TagObject.END) {
					current_CL.finiLink(linkStart_CL,container_AS);
					textLink.addCharLocation(current_CL,true);
					linkSplit = false;
				}
			}
			return charLocationV;
		}
		public function getDefaultSoftness(format:ApertureTextFormat):Number {
			var returnN:Number;
			if (format.softness >= 0) returnN = format.softness;
			else returnN = _size / (format.size * _distanceFieldSpread);
			return returnN;
		}
		public function arrangeLocations(width:Number,height:Number,textField:ApertureTextField):Vector.<CharLocation> {
			var text:String = textField.text;
			if (text == null || text.length == 0) return CharLocation.getVector();
			var format:ApertureTextFormat = textField.apertureFormat;
			var fontSize:Number = format.size,
				leading:Number = format.leading,
				spacing:Number = format.letterSpacing;
			var kerning:Boolean = format.kerning;
			var hAlign:String = format.horizontalAlign,
				vAlign:String = format.verticalAlign;
			var options:TextOptions = textField.options;
			var autoScale:Boolean = options.autoScale,
				wordWrap:Boolean = options.wordWrap;
			var finished:Boolean = false;
			var sLines:Array = PoolEx.getArray();
			var scale:Number, containerWidth:Number, containerHeight:Number;
			var current_CL:CharLocation;
			var numChars:int, i:int, j:int;
			while (!finished) {
				sLines.length = 0;
				scale = fontSize / _size;
				containerWidth  = (width  - 2 * _padding) / scale;
				containerHeight = (height - 2 * _padding) / scale;
				if (_size <= containerHeight) {
					var lastWhiteSpace:int = -1,
						lastCharID:int = -1;
					var currentX:Number = 0,
						currentY:Number = 0;
					var currentLine:Vector.<CharLocation> = CharLocation.getVector();
					numChars = text.length;
					for (i=0; i<numChars; ++i) {
						var lineFull:Boolean = false;
						var charID:int = text.charCodeAt(i);
						var char:BitmapChar;
						if (charID == CHAR_NEWLINE || charID == CHAR_CARRIAGE_RETURN) {
							lineFull = true;
							char = getChar(CHAR_NON);
						} else if (charID == CHAR_SPACE || charID == CHAR_TAB) {
							lastWhiteSpace = i;
							char = testID(charID,text,i);
						} else char = testID(charID,text,i);
						if (kerning) currentX += char.getKerning(lastCharID);
						current_CL = CharLocation.getInstance(char);
						current_CL.x = currentX + char.xOffset;
						current_CL.y = currentY + char.yOffset;
						currentLine[currentLine.length] = current_CL;
						currentX += char.xAdvance;
						if (char.charID != CHAR_NON && char.charID != CHAR_MISSING) currentX += spacing;
						lastCharID = charID;
						if (current_CL.x + char.width > containerWidth) {
							if (wordWrap) {
								if (autoScale && lastWhiteSpace == -1) break; // when autoscaling, we must not split a word in half -> restart
								var numCharsToRemove:int = lastWhiteSpace == -1 ? 1 : i - lastWhiteSpace; // remove characters and add them again to next line
								for (j=0; j<numCharsToRemove; ++j) CharLocation.putInstance(currentLine.pop());
								if (currentLine.length == 0) break;
								i -= numCharsToRemove;
							} else {
								if (autoScale) break;
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
							if (currentY + _lineHeight + leading + _size <= containerHeight) {
								currentLine = CharLocation.getVector();
								currentX = 0;
								currentY += _lineHeight + leading;
								lastWhiteSpace = -1;
								lastCharID = -1;
							} else break;
						}
					} // for each char
				} // if (_lineHeight <= containerHeight)
				if (autoScale && !finished && fontSize > 3) fontSize -= 1;
				else finished = true; 
			} // while (!finished)
			var finalLocations:Vector.<CharLocation> = CharLocation.getVector();
			var numLines:int = sLines.length;
			var bottom:Number = currentY + _lineHeight;
			var yOffset:int = 0;
			if (vAlign == Align.BOTTOM)      yOffset =  containerHeight - bottom;
			else if (vAlign == Align.CENTER) yOffset = (containerHeight - bottom) / 2;
			for (var lineID:int=0; lineID<numLines; ++lineID) {
				var line:Vector.<CharLocation> = sLines[lineID];
				numChars = line.length;
				if (numChars == 0) continue;
				var xOffset:int = 0;
				var lastLocation:CharLocation = line[line.length-1];
				lastLocation.endOfLine = true;
				var right:Number = lastLocation.x - lastLocation.char.xOffset 
												  + lastLocation.char.xAdvance;
				if (hAlign == Align.RIGHT)		 xOffset =  containerWidth - right;
				else if (hAlign == Align.CENTER) xOffset = (containerWidth - right) / 2;
				for (var c:int=0; c<numChars; ++c) {
					current_CL = line[c];
					current_CL.rowNumber = lineID;
					current_CL.x = scale * (current_CL.x + xOffset + _offsetX) + _padding;
					current_CL.y = scale * (current_CL.y + yOffset + _offsetY) + _padding;
					current_CL.scale = scale;
					finalLocations[finalLocations.length] = current_CL;
				}
				CharLocation.putVector(line);
			}
			PoolEx.putArray(sLines);
			return finalLocations;
        }
		private function testID(charID:int,text:String,i:uint):BitmapChar {
			var char:BitmapChar = getChar(charID);
			if (char == null) {
				trace(StringUtil.format("[Starling] Character '{0}' (id: {1}) not found in '{2}'",text.charAt(i),charID,_name));
				char = getChar(CHAR_MISSING);
			}
			return char;
		}
		public function fillShadow(textField:ApertureTextField):void {
			var charLocationV:Vector.<CharLocation> = textField.charLocationV;
			var shadow_AS:ApertureSprite = textField.shadow_AS;
			var l:uint = charLocationV.length;
			for (var i:uint=0; i<l; i++) {
				var current_CL:CharLocation = charLocationV[i];
				if (current_CL.quad) {
					var source_AQ:ApertureQuad = current_CL.quad,
						shadow_AQ:ApertureQuad = getCharQuad();
					var sourceStyle:ApertureDistanceFieldStyle = current_CL.style;
					var shadowStyle:ApertureDistanceFieldStyle = shadow_AQ.style as ApertureDistanceFieldStyle;
					current_CL.setShadowQuad(shadow_AQ,sourceStyle.multiChannel);
					var sourceWidth:Number = sourceStyle.threshold - sourceStyle.outerThreshold;
					shadowStyle.setupOutline(sourceWidth,0xffffff,1,false);
					shadowStyle.softness = sourceStyle.softness;
					shadow_AQ.texture = source_AQ.texture;
					shadow_AQ.readjustSize();
					shadow_AQ.scale = source_AQ.scale;
					shadow_AQ.pivotX = source_AQ.pivotX;
					shadow_AQ.pivotY = source_AQ.pivotY;
					shadow_AQ.skewX = source_AQ.skewX;
					shadow_AQ.x = source_AQ.x;
					shadow_AQ.y = source_AQ.y;
					shadow_AS.addChild(shadow_AQ);
					shadowTextLine(shadow_AS,current_CL.innerStrikethroughA,current_CL.outerStrikethroughA,current_CL.setShadowStrikethrough);
					shadowTextLine(shadow_AS,current_CL.innerUnderlineA,current_CL.outerUnderlineA,current_CL.setShadowUnderline);
					shadowTextLine(shadow_AS,current_CL.innerLinkA,current_CL.outerLinkA,current_CL.setShadowLink);
				}
			}
		}
		private function shadowTextLine(shadow_AS:ApertureSprite,innerA:Array,outerA:Array,shadowFunction:Function):void {
			if (outerA) shadowTextLineA(shadow_AS,outerA,shadowFunction);
			else if (innerA) shadowTextLineA(shadow_AS,innerA,shadowFunction);
		}
		private function shadowTextLineA(shadow_AS:ApertureSprite,textLineA:Array,shadowFunction:Function):void {
			var l:uint = textLineA.length;
			for (var i:uint=0; i<l; i++) {
				var textLine_AQ:ApertureQuad = textLineA[i];
				var shadowLine_AQ:ApertureQuad = getTextLineQuad(textLine_AQ.quadW,textLine_AQ.quadH,multiChannel);
				shadowLine_AQ.texture = getWhiteTexture();
				shadowLine_AQ.x = textLine_AQ.x;
				shadowLine_AQ.y = textLine_AQ.y;
				shadowFunction(shadowLine_AQ);
				shadow_AS.addChild(shadowLine_AQ);
			}
		}
		public function setupOutline(charLocation:CharLocation,outlineColor:uint,outlineWidth:Number):void {
			charLocation.setupOutline(outlineColor,outlineWidth,getTextLineQuad,putTextLineQuad,multiChannel);
		}
		public function updateOutlineWidth(charLocation:CharLocation,outlineWidth:Number):void {
			charLocation.updateOutlineWidth(outlineWidth,getTextLineQuad,putTextLineQuad,multiChannel);
		}
		public function clearSprites(charLocationV:Vector.<CharLocation>):void {
			if (charLocationV) {
				var l:uint = charLocationV.length;
				for (var i:uint=0; i<l; i++) {
					var charLocation:CharLocation = charLocationV[i];
					CharLocation.putInstance(charLocation,putCharQuad,putTextLineQuad);
				}
			}
		}
		public function get name():String {return _name;}
		public function get multiChannel():Boolean {
			if (_type == BitmapFontType.MULTI_CHANNEL_DISTANCE_FIELD) return true;
			else return false;
		}
		public function dispose():void {
			bitmapData.dispose();
			bitmapData = null;
			for (var key:Object in _chars) {
				delete _chars[key];
			}
			_chars = null;
			_texture.dispose();
			_texture = null;
			if (_whiteTexture) {
				_whiteTexture.dispose();
				_whiteTexture = null;
			}
		}

	}

}
