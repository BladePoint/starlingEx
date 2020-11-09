// StarlingEx - https://github.com/BladePoint/StarlingEx
// Copyright Doublehead Games, LLC. All rights reserved.
// This code is open source under the MIT License - https://github.com/BladePoint/StarlingEx/blob/master/docs/LICENSE
// Use in conjunction with Starling - https://gamua.com/starling/

package starlingEx.text {

	import starling.display.DisplayObjectContainer;
	import starling.text.BitmapChar;
	import starling.textures.Texture;
	import starling.utils.MathUtil;
	import starlingEx.display.ApertureQuad;
	import starlingEx.styles.ApertureDistanceFieldStyle;
	import starlingEx.text.ApertureTextFormat;
	import starlingEx.text.TagObject;
	import starlingEx.text.TextLink;
	import starlingEx.utils.PoolEx;
	import starlingEx.display.ApertureSprite;

	/* A helper class that stores formatting information about a character such as position and scale. */
	public class CharLocation {
		static private var instancePool:Vector.<CharLocation> = new <CharLocation>[];
		static public function getInstance(char:BitmapChar):CharLocation {
			var charLocation:CharLocation;
			if (instancePool.length == 0) charLocation = new CharLocation(char);
			else {
				charLocation = instancePool.pop();
				charLocation.init(char);
			}
			return charLocation;
		}
		static public function putInstance(charLocation:CharLocation,putCharQuad:Function=null,putTextLineQuad:Function=null):void {
			if (charLocation) {
				charLocation.reset();
				charLocation.dispose(putCharQuad,putTextLineQuad);
				instancePool[instancePool.length] = charLocation;
			}
		}
		static private var vectorPool:Array = [];
		static public function getVector():Vector.<CharLocation> {
			var vector:Vector.<CharLocation>;
			if (vectorPool.length == 0) vector = new <CharLocation>[];
			else vector = vectorPool.pop();
			return vector;
		}
		static public function putVector(vector:Vector.<CharLocation>):void {
			if (vector) {
				vector.length = 0;
				vectorPool[vectorPool.length] = vector;
			}
		}
		static private function getBaseY(rowNumber:uint,fontHeight:Number,leading:Number,scale:Number):Number {
			return rowNumber * (fontHeight + leading) * scale;
		}
		static private const defaultThreshold:Number = .5;
		static private function getOuterH(charLocation:CharLocation,innerH:uint):uint {
			var outerH:uint;
			var outlineRatio:Number;
			var style:ApertureDistanceFieldStyle = charLocation.style;
			if (style) outlineRatio = style.outerThreshold / style.threshold;
			else outlineRatio = MathUtil.clamp(defaultThreshold-charLocation.textLineOutlineWidth,0,defaultThreshold) / defaultThreshold;
			var outlineMult:Number = 1 + (1 - outlineRatio)*1;
			if (outlineMult > 1) {
				outerH = Math.ceil(innerH*outlineMult);
				if ((outerH-innerH) % 2 != 0) outerH++;
			}
			return outerH;
		}
		static private function getTextLine(getTextLineQuad:Function,innerH:uint,baseY:Number,multiChannel:Boolean,texture:Texture,charLocation:CharLocation,x:Number):ApertureQuad {
			var inner_AQ:ApertureQuad = getTextLineQuad(1,innerH,multiChannel);
			inner_AQ.texture = texture;
			var charQuad:ApertureQuad = charLocation.quad;
			if (charQuad) inner_AQ.setEachHex(charQuad.getHex(0),charQuad.getHex(1),charQuad.getHex(2),charQuad.getHex(3),false);
			else inner_AQ.setEachHex(charLocation.textLineTopLeftColor,charLocation.textLineTopRightColor,charLocation.textLineBottomLeftColor,charLocation.textLineBottomRightColor,false);
			inner_AQ.x = x;
			inner_AQ.y = baseY;
			return inner_AQ;
		}
		static private function getOuterLine(getTextLineQuad:Function,outerH:Number,multiChannel:Boolean,texture:Texture,charLocation:CharLocation,apply:Boolean=false):ApertureQuad {
			var outer_AQ:ApertureQuad = getTextLineQuad(1,outerH,multiChannel);
			outer_AQ.texture = texture;
			var outerColor:uint;
			var style:ApertureDistanceFieldStyle = charLocation.style;
			if (style) outerColor = style.getHex();
			else outerColor = charLocation.textLineOutlineColor;
			outer_AQ.setHex(outerColor,apply);
			return outer_AQ;
		}
		static private function setOuterLine(inner_AQ:ApertureQuad,outer_AQ:ApertureQuad):void {
			var outerWidthOffset:uint = outer_AQ.quadH - inner_AQ.quadH;
			var outerOffset:uint = outerWidthOffset / 2;
				outer_AQ.x = inner_AQ.x - outerOffset;
				outer_AQ.y = inner_AQ.y - outerOffset;
				outer_AQ.readjustSize(inner_AQ.quadW+outerWidthOffset,outer_AQ.quadH);
		}
		static private function colorInnerArray(innerA:Array,topLeftColor:uint,topRightColor:uint,bottomLeftColor:uint,bottomRightColor:uint):void {
			if (innerA) {
				var l:uint = innerA.length;
				for (var i:uint=0; i<l; i++) {
					var textLine:ApertureQuad = innerA[i];
					textLine.setEachHex(topLeftColor,topRightColor,bottomLeftColor,bottomRightColor,true);
				}
			}
		}
		static private function clearTextLineArray(textLineA:Array,putTextLineQuad:Function):void {
			if (textLineA) {
				var l:uint = textLineA.length;
				for (var i:uint=0; i<l; i++) {
					var textLine_AQ:ApertureQuad = textLineA[i];
					textLine_AQ.removeFromParent();
					putTextLineQuad(textLine_AQ);
				}
			}
		}

		public var char:BitmapChar;
		public var scale:Number, x:Number, y:Number, textLineOutlineWidth:Number;
		public var rowNumber:uint, textLineTopLeftColor:uint, textLineTopRightColor:uint, textLineBottomLeftColor:uint, textLineBottomRightColor:uint, textLineOutlineColor:uint;
		public var endOfLine:Boolean;
		public var italic:String, underline:String, strikethrough:String, link:String;
		internal var outerStrikethroughA:Array, innerStrikethroughA:Array, shadowStrikethroughA:Array,
			outerUnderlineA:Array, innerUnderlineA:Array, shadowUnderlineA:Array,
			outerLinkA:Array, innerLinkA:Array, shadowLinkA:Array;
		internal var textLink:TextLink;
		private var _quad:ApertureQuad, _shadowQuad:ApertureQuad;
		private var _style:ApertureDistanceFieldStyle;
		public function CharLocation(char:BitmapChar) {
			init(char);
		}
		private function init(char:BitmapChar):void {
			this.char = char;
		}
		internal function setQuad(quad:ApertureQuad,multiChannel:Boolean):void {
			_quad = quad;
			_style = quad.style as ApertureDistanceFieldStyle;
			_style.multiChannel = multiChannel;
		}
		public function get quad():ApertureQuad {
			return _quad;
		}
		public function get style():ApertureDistanceFieldStyle {
			return _style;
		}
		internal function setShadowQuad(shadowQuad:ApertureQuad,multiChannel:Boolean):void {
			_shadowQuad = shadowQuad;
			var style:ApertureDistanceFieldStyle = shadowQuad.style as ApertureDistanceFieldStyle;
			style.multiChannel = multiChannel;
		}
		internal function setShadowStrikethrough(shadowStrikethrough_AQ:ApertureQuad):void {
			if (shadowStrikethroughA == null) shadowStrikethroughA = PoolEx.getArray();
			shadowStrikethroughA[shadowStrikethroughA.length] = shadowStrikethrough_AQ;
		}
		internal function setShadowUnderline(shadowUnderline_AQ:ApertureQuad):void {
			if (shadowUnderlineA == null) shadowUnderlineA = PoolEx.getArray();
			shadowUnderlineA[shadowUnderlineA.length] = shadowUnderline_AQ;
		}
		internal function setShadowLink(shadowLink_AQ:ApertureQuad):void {
			if (shadowLinkA == null) shadowLinkA = PoolEx.getArray();
			shadowLinkA[shadowLinkA.length] = shadowLink_AQ;
		}
		public function get shadowQuad():ApertureQuad {
			return _shadowQuad;
		}
		public function initStrikethrough(start_CL:CharLocation,getTextLineQuad:Function,multiChannel:Boolean,texture:Texture,innerH:uint,fontHeight:Number,leading:Number):void {
			var baseY:Number = getBaseY(rowNumber,fontHeight,leading,scale)
				+ (fontHeight*scale - innerH) / 2;
			var outerH:uint = getOuterH(start_CL,innerH);
			if (start_CL == this) {
				innerStrikethroughA = PoolEx.getArray();
				if (outerH > 0) outerStrikethroughA = PoolEx.getArray();
			}
			var innerA:Array = start_CL.innerStrikethroughA,
				outerA:Array = start_CL.outerStrikethroughA;
			innerA[innerA.length] = getTextLine(getTextLineQuad,innerH,baseY,multiChannel,texture,start_CL,x);
			if (outerA) outerA[outerA.length] = getOuterLine(getTextLineQuad,outerH,multiChannel,texture,start_CL);
		}
		public function finiStrikethrough(start_CL:CharLocation,container_AS:ApertureSprite):void {
			finiTextLine(start_CL.innerStrikethroughA,start_CL.outerStrikethroughA,char,scale,x,container_AS);
		}
		private function finiTextLine(innerA:Array,outerA:Array,char:BitmapChar,scale:Number,x:Number,container_AS:ApertureSprite):void {
			var charW:Number;
			if (char.width > 0) charW = char.width * scale;
			else charW = char.xAdvance * scale;
			var inner_AQ:ApertureQuad = innerA[innerA.length-1];
			var innerW:Number = x + charW - inner_AQ.x;
			inner_AQ.readjustSize(innerW,inner_AQ.quadH);
			if (outerA) {
				var outer_AQ:ApertureQuad = outerA[outerA.length-1];
				setOuterLine(inner_AQ,outer_AQ);
				container_AS.addChild(outer_AQ);
			}
			container_AS.addChild(inner_AQ);
		}
		public function testSplit(tagType:String,start_CL:CharLocation,container_AS:ApertureSprite,nextChar:CharLocation):Boolean {
			if (endOfLine) {
				nextChar[tagType] = TagObject.START;
				if (tagType == TextTag.STRIKETHROUGH) finiStrikethrough(start_CL,container_AS);
				else if (tagType == TextTag.UNDERLINE) finiUnderline(start_CL,container_AS);
				else if (tagType == TextTag.LINK) finiLink(start_CL,container_AS);
				return true;
			} else return false;
		}
		public function initUnderline(start_CL:CharLocation,getTextLineQuad:Function,multiChannel:Boolean,texture:Texture,innerH:uint,fontHeight:Number,leading:Number,underlineHeightPercent:Number):void {
			var baseY:Number = getBaseY(rowNumber,fontHeight,leading,scale)
				+ fontHeight * scale * underlineHeightPercent;
			var outerH:uint = getOuterH(start_CL,innerH);
			if (start_CL == this) {
				innerUnderlineA = PoolEx.getArray();
				if (outerH > 0) outerUnderlineA = PoolEx.getArray();
			}
			var innerA:Array = start_CL.innerUnderlineA,
				outerA:Array = start_CL.outerUnderlineA;
			innerA[innerA.length] = getTextLine(getTextLineQuad,innerH,baseY,multiChannel,texture,start_CL,x);
			if (outerA) outerA[outerA.length] = getOuterLine(getTextLineQuad,outerH,multiChannel,texture,start_CL);
		}
		public function finiUnderline(start_CL:CharLocation,container_AS:ApertureSprite):void {
			finiTextLine(start_CL.innerUnderlineA,start_CL.outerUnderlineA,char,scale,x,container_AS);
		}
		public function initTextLink(fontHeight:Number,leading:Number,underlineHeightPercent:Number):TextLink {
			const rowH:Number = (fontHeight + leading) * scale,
				linkH:Number = fontHeight * scale * underlineHeightPercent;
			textLink = TextLink.getInstance(rowH,linkH);
			return textLink;
		}
		public function initLink(start_CL:CharLocation,getTextLineQuad:Function,multiChannel:Boolean,texture:Texture,innerH:uint,fontHeight:Number,leading:Number,underlineHeightPercent:Number):void {
			var baseY:Number = getBaseY(rowNumber,fontHeight,leading,scale)
				+ fontHeight * scale * underlineHeightPercent;
			var outerH:uint = getOuterH(start_CL,innerH);
			if (start_CL == this) {
				innerLinkA = PoolEx.getArray();
				if (outerH > 0) outerLinkA = PoolEx.getArray();
			}
			var innerA:Array = start_CL.innerLinkA,
				outerA:Array = start_CL.outerLinkA;
			innerA[innerA.length] = getTextLine(getTextLineQuad,innerH,baseY,multiChannel,texture,start_CL,x);
			if (outerA) outerA[outerA.length] = getOuterLine(getTextLineQuad,outerH,multiChannel,texture,start_CL);
		}
		public function finiLink(start_CL:CharLocation,container_AS:ApertureSprite):void {
			finiTextLine(start_CL.innerLinkA,start_CL.outerLinkA,char,scale,x,container_AS);
		}
		public function updateColor(topLeftColor:uint,topRightColor:uint,bottomLeftColor:uint,bottomRightColor:uint,apply:Boolean=true):void {
			if (_quad) _quad.setEachHex(topLeftColor,topRightColor,bottomLeftColor,bottomRightColor,apply);
			colorInnerArray(innerStrikethroughA,topLeftColor,topRightColor,bottomLeftColor,bottomRightColor);
			colorInnerArray(innerUnderlineA,topLeftColor,topRightColor,bottomLeftColor,bottomRightColor);
			colorInnerArray(innerLinkA,topLeftColor,topRightColor,bottomLeftColor,bottomRightColor);
		}
		public function setupOutline(outlineColor:uint,newWidth:Number,getTextLineQuad:Function,putTextLineQuad:Function,multiChannel:Boolean):void {
			var previousWidth:Number = getPreviousWidth();
			if (_style) _style.setupOutline(newWidth,outlineColor);
			if (getTextLineQuad != null && putTextLineQuad != null) {
				setOuterArray(getTextLineQuad,putTextLineQuad,multiChannel,previousWidth,newWidth,TextTag.STRIKETHROUGH);
				setOuterArray(getTextLineQuad,putTextLineQuad,multiChannel,previousWidth,newWidth,TextTag.UNDERLINE);
				setOuterArray(getTextLineQuad,putTextLineQuad,multiChannel,previousWidth,newWidth,TextTag.LINK);
			}
			colorOuterArray(outlineColor,outerStrikethroughA);
			colorOuterArray(outlineColor,outerUnderlineA);
			colorOuterArray(outlineColor,outerLinkA);
		}
		private function getPreviousWidth():Number {
			var previousWidth:Number;
			if (_style) previousWidth = _style.threshold - _style.outerThreshold;
			else previousWidth = textLineOutlineWidth;
			return previousWidth;
		}
		public function updateSoftness(softness:Number):void {
			if (_style) _style.softness = softness;
		}
		public function updateOutlineColor(outlineColor:uint,apply:Boolean=true):void {
			if (_style) _style.setHex(outlineColor,apply);
			colorOuterArray(outlineColor,outerStrikethroughA);
			colorOuterArray(outlineColor,outerUnderlineA);
			colorOuterArray(outlineColor,outerLinkA);
		}
		private function colorOuterArray(outlineColor:uint,outerA:Array):void {
			if (outerA) {
				var l:uint = outerA.length;
				for (var i:uint=0; i<l; i++) {
					var outer_AQ:ApertureQuad = outerA[i];
					outer_AQ.setHex(outlineColor,true);
				}
			}
		}
		public function updateOutlineWidth(newWidth:Number,getTextLineQuad:Function,putTextLineQuad:Function,multiChannel:Boolean):void {
			if (_style) _style.outerThreshold = MathUtil.clamp(_style.threshold-newWidth,0,_style.threshold);
			var previousWidth:Number = getPreviousWidth();
			setOuterArray(getTextLineQuad,putTextLineQuad,multiChannel,previousWidth,newWidth,TextTag.STRIKETHROUGH);
			setOuterArray(getTextLineQuad,putTextLineQuad,multiChannel,previousWidth,newWidth,TextTag.UNDERLINE);
			setOuterArray(getTextLineQuad,putTextLineQuad,multiChannel,previousWidth,newWidth,TextTag.LINK);
		}
		private function setOuterArray(getTextLineQuad:Function,putTextLineQuad:Function,multiChannel:Boolean,previousWidth:Number,newWidth:Number,textLineType:String):void {
			var innerA:Array;
			var outerProperty:String;
			if (textLineType == TextTag.STRIKETHROUGH) {
				innerA = innerStrikethroughA;
				outerProperty = "outerStrikethroughA";
			} else if (textLineType == TextTag.UNDERLINE) {
				innerA = innerUnderlineA;
				outerProperty = "outerUnderlineA";
			} else if (textLineType == TextTag.LINK) {
				innerA = innerLinkA;
				outerProperty = "outerLinkA";
			}
			if (innerA) {
				var i:uint, l:uint,
					innerH:uint, outerH:uint;
				if (this[outerProperty] == null) this[outerProperty] = PoolEx.getArray();
				var outerA:Array = this[outerProperty];
				var inner_AQ:ApertureQuad, outer_AQ:ApertureQuad;
				if (previousWidth == 0 && newWidth > 0) {
					l = innerA.length;
					for (i=0; i<l; i++) {
						inner_AQ = innerA[i];
						var innerParent_DOC:DisplayObjectContainer = inner_AQ.parent;
						var innerIndex:uint = innerParent_DOC.getChildIndex(inner_AQ);
						innerH = inner_AQ.quadH;
						outerH = getOuterH(this,innerH);
						outer_AQ = outerA[i] = getOuterLine(getTextLineQuad,outerH,multiChannel,inner_AQ.texture,this,true);
						setOuterLine(inner_AQ,outer_AQ);
						innerParent_DOC.addChildAt(outer_AQ,innerIndex);
					}
				} else if (previousWidth > 0 && newWidth == 0) clearTextLineArray(outerA,putTextLineQuad);
				else {
					l = innerA.length;
					for (i=0; i<l; i++) {
						inner_AQ = innerA[i];
						innerH = inner_AQ.quadH;
						outerH = getOuterH(this,innerH);
						outer_AQ = outerA[i];
						outer_AQ.readjustSize(1,outerH);
						setOuterLine(inner_AQ,outer_AQ);
					}
				}
			}
		}
		public function reset():void {
			scale = x = y = textLineOutlineWidth = NaN;
			rowNumber = 0;
			endOfLine = false;
			italic = underline = strikethrough = link = null;
		}
		public function dispose(putCharQuad:Function,putTextLineQuad:Function):void {
			char = null;
			clearTextLineArray(outerStrikethroughA,putTextLineQuad);
			PoolEx.putArray(outerStrikethroughA);
			clearTextLineArray(innerStrikethroughA,putTextLineQuad);
			PoolEx.putArray(innerStrikethroughA);
			clearTextLineArray(shadowStrikethroughA,putTextLineQuad);
			PoolEx.putArray(shadowStrikethroughA);
			clearTextLineArray(outerUnderlineA,putTextLineQuad);
			PoolEx.putArray(outerUnderlineA);
			clearTextLineArray(innerUnderlineA,putTextLineQuad);
			PoolEx.putArray(innerUnderlineA);
			clearTextLineArray(shadowUnderlineA,putTextLineQuad);
			PoolEx.putArray(shadowUnderlineA);
			clearTextLineArray(outerLinkA,putTextLineQuad);
			PoolEx.putArray(outerLinkA);
			clearTextLineArray(innerLinkA,putTextLineQuad);
			PoolEx.putArray(innerLinkA);
			clearTextLineArray(shadowLinkA,putTextLineQuad);
			PoolEx.putArray(shadowLinkA);
			outerStrikethroughA = innerStrikethroughA = shadowStrikethroughA =
				outerUnderlineA = innerUnderlineA = shadowUnderlineA =
				outerLinkA = innerLinkA = shadowLinkA = null;
			textLink = null;
			if (_quad) {
				_quad.removeFromParent();
				if (putCharQuad != null) putCharQuad(_quad);
			}
			if (_shadowQuad) {
				_shadowQuad.removeFromParent();
				if (putCharQuad != null) putCharQuad(_shadowQuad);
			}
			_quad = _shadowQuad = null;
			if (_style) {
				_style.dispose();
				_style = null;
			}
			
		}

	}

}
