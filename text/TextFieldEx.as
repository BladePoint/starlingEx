// StarlingEx - https://github.com/BladePoint/StarlingEx
// Copyright Doublehead Games, LLC. All rights reserved.
// This code is open source under the MIT License - https://github.com/BladePoint/StarlingEx/blob/master/docs/LICENSE
// Use in conjunction with Starling - https://gamua.com/starling/

package starlingEx.text {

	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import starling.events.Event;
	import starling.rendering.Painter;
	import starling.text.TextFieldAutoSize;
	import starling.text.TextOptions;
	import starling.utils.Color;
	import starling.utils.Pool;
	import starlingEx.display.ApertureQuad;
	import starlingEx.display.ApertureSprite;
	import starlingEx.text.CharLocation;
	import starlingEx.text.Compositor;
	import starlingEx.text.TextFormatEx;
	import starlingEx.utils.PoolEx;

	/* TextFieldEx supports format tags similar to BBCode. See TextTag for a list of available tags. Much of this code is appropriated from
	   starling.text.Textfield. */
	public class TextFieldEx extends ApertureSprite {
		static private const sMatrix:Matrix = Pool.getMatrix();
		static private const maxUint:uint = uint.MAX_VALUE;
		
		private var _text:String;
		private var _format:TextFormatEx;
		private var _options:TextOptions;
		private var _hitArea:Rectangle, _textBounds:Rectangle;
		private var linkFunctionA:Array, textTagA:Array, tagObjectA:Array;
		private var text_AS:ApertureSprite, shadow_AS:ApertureSprite, _border:ApertureSprite;
		private var requiresRecomposition:Boolean, recomposing:Boolean;
		private var charLocationV:Vector.<CharLocation>;
		private var textLinkV:Vector.<TextLink>;
		/* If your text string includes link tags, be sure to pass an array of the functions to be called when they are clicked on. The first function
		   in the array will be assigned to the first link, the second function will be assigned to the second link, etc... */
		public function TextFieldEx(width:int,height:int,text:String,format:TextFormatEx,options:TextOptions=null,linkFunctionA:Array=null) {
			_text = text;
			_format = format.clone();
			_format.assignTextField(this);
			_format.addEventListener(Event.CHANGE,setRequiresRecomposition);
			_format.addEventListener(TextFormatEx.APERTURE_CHANGE,apertureChange);
			_format.addEventListener(TextFormatEx.SHADOW_CHANGE,shadowChange);
			_options = options ? options.clone() : new TextOptions();
			_options.addEventListener(Event.CHANGE,setRequiresRecomposition);
			this.linkFunctionA = linkFunctionA;
			text_AS = new ApertureSprite();
			addChild(text_AS);
			initHitArea(width,height);
			requiresRecomposition = true;
		}
		private function initHitArea(w:int,h:int):void {
			_hitArea = Pool.getRectangle();
			if (w>0 && h>0) {
				_options.autoSize = TextFieldAutoSize.NONE;
				_hitArea.width = w;
				_hitArea.height = h;
			} else if (w>0 && h<=0) {
				_options.autoSize = TextFieldAutoSize.VERTICAL;
				_hitArea.width = w;
				_hitArea.height = maxUint;
			} else if (w<=0 && h>0) {
				_options.autoSize = TextFieldAutoSize.HORIZONTAL;
				_hitArea.width = maxUint;
				_hitArea.height = h;
			} else if (w<=0 && h<=0) {
				_options.autoSize = TextFieldAutoSize.BOTH_DIRECTIONS;
				_hitArea.width = maxUint;
				_hitArea.height = maxUint;
			}
		}
		private function resetHitArea():void {
			if (_options.autoSize == TextFieldAutoSize.VERTICAL) _hitArea.height = maxUint;
			else if (_options.autoSize == TextFieldAutoSize.HORIZONTAL) _hitArea.width = maxUint;
			else if (_options.autoSize == TextFieldAutoSize.BOTH_DIRECTIONS) {
				_hitArea.width = maxUint;
				_hitArea.height = maxUint;
			}
		}
		public function setRequiresRecomposition():void {
			if (!recomposing) {
				requiresRecomposition = true;
				setRequiresRedraw();
			}
		}
		public override function render(painter:Painter):void {
			if (requiresRecomposition) recompose();
			super.render(painter);
		}
		private function recompose():void {
			if (requiresRecomposition) {
				recomposing = true;
				reset();
				parseText();
				updateText();
				updateTextLink();
				updateShadow();
				updateBorder();
				requiresRecomposition = false;
				recomposing = false;
			}
		}
		private function reset():void {
			disposeTextBounds();
			disposeTags();
			disposeTextLinkV();
			CharLocation.putVector(charLocationV,true);
			if (shadow_AS) {
				removeChild(shadow_AS);
				shadow_AS.dispose();
				shadow_AS = null;
			}
		}
		private function parseText():void {
			while (stripTag()) stripTag();
			initTagObjects();
			/*import flash.utils.describeType;
			if (tagObjectA) {
				const l:uint = tagObjectA.length;
				for (var i:uint=0; i<l; i++) {
					const tagObject:TagObject = tagObjectA[i];
					if (tagObject) {
						var traceString:String = i+": ";
						const XMLlist:XMLList = describeType(tagObject)..variable;
						for each(var variable:XML in XMLlist) {
							const tagType:String = variable.@name;
							const textTag:TextTag = tagObject[tagType];
							if (textTag && textTag.value) traceString += tagType + "=" + textTag.value + ",";
						}
						trace(traceString);
					}
				}
			}*/
		}
		private function stripTag():Boolean {
			var returnB:Boolean;
			const resultO:Object = TextTag.regExp.exec(_text);
			if (resultO == null) returnB = false;
			else {
				/*trace("matched text: " + resultO[0] + " at index " + resultO.index);
				trace("slash capture group: " + resultO[1]);
				trace("tag capture group: " + resultO[2]);
				trace("value capture group: " + resultO[3]);*/
				const tagIndex:uint = resultO.index,
					tagLength:uint = resultO[0].length;
				const endTag:String = resultO[1],
					tagType:String = resultO[2],
					tagValue:String = resultO[3];
				_text = _text.slice(0,tagIndex) + _text.slice(tagIndex+tagLength);
				if (!endTag) newTextTag(tagType,tagIndex,tagValue);
				else endTextTag(tagType,tagIndex);
				returnB = true;
			}
			return returnB;
		}
		private function newTextTag(tagType:String,tagIndex:uint,valueString:String):void {
			if (textTagA == null) textTagA = PoolEx.getArray();
			const textTag:TextTag = TextTag.getInstance(tagType,tagIndex,valueString);
			textTagA[textTagA.length] = textTag;
		}
		private function endTextTag(tagType:String,tagIndex:uint):void {
			for (var i:int=textTagA.length-1; i>=0; i--) {
				const textTag:TextTag = textTagA[i];
				if (textTag.tagType == tagType) {
					textTag.endIndex = tagIndex - 1;
					break;
				}
			}
		}
		private function initTagObjects():void {
			if (textTagA) {
				tagObjectA = PoolEx.getArray()
				tagObjectA.length = _text.length;
				const l:uint = textTagA.length;
				for (var i:uint=0; i<l; i++) {
					const textTag:TextTag = textTagA[i];
					const tagType:String = textTag.tagType;
					for (var j:uint=textTag.startIndex; j<=textTag.endIndex; j++) {
						var tagObject:TagObject = tagObjectA[j];
						if (tagObject == null) tagObject = tagObjectA[j] = TagObject.getInstance();
						tagObject[tagType] = textTag;
					}
				}
			}
		}
		internal function getTagObject(index:uint):TagObject {
			var tagObject:TagObject;
			if (tagObjectA) tagObject = tagObjectA[index];
			return tagObject;
		}
		private function getTagValue(index:uint,tagType:String):* {
			var returnValue:*;
			const tagObject:TagObject = getTagObject(index);
			if (tagObject) returnValue = tagObject.getValue(tagType);
			return returnValue;
		}
		private function updateText():void {
			const width:Number  = _hitArea.width,
				height:Number = _hitArea.height;
			text_AS.x = text_AS.y = 0;
			charLocationV = Compositor.fillContainer(this,width,height);
			if (_options.autoSize != TextFieldAutoSize.NONE) {
				_textBounds = Pool.getRectangle();
				_textBounds = text_AS.getBounds(text_AS,_textBounds);
				if (isHorizontalAutoSize) {
					text_AS.x = _textBounds.x = -_textBounds.x;
					_hitArea.width = _textBounds.width;
					_textBounds.x = 0;
				}
				if (isVerticalAutoSize) {
					text_AS.y = _textBounds.y = -_textBounds.y;
					_hitArea.height = _textBounds.height;
					_textBounds.y = 0;
				}
			} else disposeTextBounds();
		}
		internal function addToTextSprite(apertureQuad:ApertureQuad):void {
			text_AS.addChild(apertureQuad);
		}
		internal function addTextLink(textLink:TextLink):void {
			if (textLink) {
				if (textLinkV == null) textLinkV = TextLink.getVector();
				textLinkV[textLinkV.length] = textLink;
			}
		}
		private function updateTextLink():void {
			if (textLinkV) {
				const l:uint = textLinkV.length;
				for (var i:uint=0; i<l; i++) {
					const textLink:TextLink = textLinkV[i];
					if (linkFunctionA && linkFunctionA.length > i) textLink.clickFunction = linkFunctionA[i];
					text_AS.addChild(textLink);
				}
				touchable = true;
			} else touchable = false;
			PoolEx.putArray(linkFunctionA);
			linkFunctionA = null;
		}
		public function getTextLinkAt(index:uint):TextLink {
			var textLink:TextLink;
			if (textLinkV && index < textLinkV.length) textLink = textLinkV[index];
			return textLink;
		}
		private function updateShadow():void {
			positionShadow();
			alphaShadow();
			colorShadow();
		}
		private function positionShadow():void {
			if (visibleShadow) {
				initShadow();
				shadow_AS.x = text_AS.x + _format.dropShadowX;
				shadow_AS.y = text_AS.y + _format.dropShadowY;
			}
		}
		private function get visibleShadow():Boolean {
			if (_format.dropShadowX == 0 && _format.dropShadowY == 0) return false;
			else if (_format.dropShadowAlpha == 0) return false;
			else return true;
		}
		private function initShadow():void {
			if (shadow_AS == null) {
				shadow_AS = new ApertureSprite();
				shadow_AS.touchable = false;
				addChildAt(shadow_AS,0);
				Compositor.fillShadow(charLocationV);
				addShadowQuad();
			}
		}
		private function addShadowQuad():void {
			const l:uint = charLocationV.length;
			for (var i:uint=0; i<l; i++) {
				const charLocation:CharLocation = charLocationV[i];
				if (charLocation.shadowQuad) shadow_AS.addChild(charLocation.shadowQuad);
				addShadowLineArray(charLocation.shadowStrikethroughA);
				addShadowLineArray(charLocation.shadowUnderlineA);
				addShadowLineArray(charLocation.shadowLinkA);
			}
		}
		private function addShadowLineArray(shadowLineA:Array):void {
			if (shadowLineA) {
				const l:uint = shadowLineA.length;
				for (var i:uint=0; i<l; i++) {
					const shadowLine_AQ:ApertureQuad = shadowLineA[i];
					shadow_AS.addChild(shadowLine_AQ);
				}
			}
		}
		private function alphaShadow():void {
			if (visibleShadow) {
				initShadow();
				shadow_AS.alpha = _format.dropShadowAlpha;
			}
		}
		private function colorShadow():void {
			if (visibleShadow && shadow_AS) {
				shadow_AS.setHex(_format.dropShadowColor,true);
			}
		}
		private function shadowChange(evt:Event,changeHex:uint):void {
			const positionB:Boolean = Boolean(Color.getRed(changeHex)),
				alphaB:Boolean = Boolean(Color.getGreen(changeHex)),
				colorB:Boolean = Boolean(Color.getBlue(changeHex));
			if (positionB) positionShadow();
			if (alphaB) alphaShadow();
			if (colorB) colorShadow();
		}
		public function get border():Boolean {return _border != null;}
		public function set border(value:Boolean):void {
			if (value && _border == null) {                
				_border = new ApertureSprite();
				addChild(_border);
				for (var i:int=0; i<4; ++i) {
					_border.addChild(new ApertureQuad(1,1));
				}
				updateBorder();
			}
			else if (!value && _border != null) disposeBorder();
		}
		private function updateBorder():void {
			if (_border == null) return;
			const width:Number  = _hitArea.width,
				height:Number = _hitArea.height;
			const topLine:ApertureQuad    = _border.getChildAt(0) as ApertureQuad,
				rightLine:ApertureQuad  = _border.getChildAt(1) as ApertureQuad,
				bottomLine:ApertureQuad = _border.getChildAt(2) as ApertureQuad,
				leftLine:ApertureQuad   = _border.getChildAt(3) as ApertureQuad;
			topLine.width    = width; topLine.height    = 1;
			bottomLine.width = width; bottomLine.height = 1;
			leftLine.width   = 1;     leftLine.height   = height;
			rightLine.width  = 1;     rightLine.height  = height;
			rightLine.x  = width  - 1;
			bottomLine.y = height - 1;
			topLine.color = rightLine.color = bottomLine.color = leftLine.color = _format.topLeftColor;
		}
		private function apertureChange(evt:Event,changeHex:uint):void {
			const baseColorB:Boolean = Boolean(Color.getAlpha(changeHex)),
				outlineColorB:Boolean = Boolean(Color.getRed(changeHex)),
				outlineWidthB:Boolean = Boolean(Color.getGreen(changeHex)),
				outlineSoftnessB:Boolean = Boolean(Color.getBlue(changeHex));
			if (baseColorB) updateFormatColors();
			if (outlineColorB && !outlineWidthB) updateFormatOutlineColors();
			else if (!outlineColorB && outlineWidthB) updateFormatOutlineWidths();
			else if (outlineColorB && outlineWidthB) updateFormatOutline();
			if (outlineSoftnessB) updateAllSoftness();
		}
		private function updateFormatColors():void {
			if (charLocationV) {
				const l:uint = charLocationV.length;
				for (var i:uint=0; i<l; i++) {
					const charLocation:CharLocation = charLocationV[i];
					if (charLocation.getLinkPosition(i)) continue;
					const colorValue:* = getTagValue(i,TextTag.COLOR);
					if (colorValue == null) charLocation.updateColor(_format.topLeftColor,_format.topRightColor,_format.bottomLeftColor,_format.bottomRightColor,true);
				}
			}
		}
		private function updateFormatOutlineColors():void {
			if (charLocationV) {
				const l:uint = charLocationV.length;
				for (var i:uint=0; i<l; i++) {
					const outlineValue:* = getTagValue(i,TextTag.OUTLINE_COLOR);
					if (outlineValue == null) {
						const charLocation:CharLocation = charLocationV[i];
						if (charLocation.getLinkPosition(i)) continue;
						charLocation.updateOutlineColor(_format.outlineColor,true);
					}
				}
			}
		}
		private function updateFormatOutlineWidths():void {
			if (charLocationV) {
				const l:uint = charLocationV.length;
				for (var i:uint=0; i<l; i++) {
					const outlineWidthValue:* = getTagValue(i,TextTag.OUTLINE_WIDTH);
					if (outlineWidthValue == null) {
						const charLocation:CharLocation = charLocationV[i];
						if (charLocation.getLinkPosition(i)) continue;
						charLocation.updateOutlineWidth(_format.outlineWidth);
					}
				}
			}
		}
		private function updateFormatOutline():void {
			if (charLocationV) {
				const l:uint = charLocationV.length;
				for (var i:uint=0; i<l; i++) {
					const charLocation:CharLocation = charLocationV[i];
					if (charLocation.getLinkPosition(i)) continue;
					const customOutlineColor:* = getTagValue(i,TextTag.OUTLINE_COLOR);
					var outlineColor:uint;
					if (customOutlineColor) outlineColor = customOutlineColor;
					else outlineColor = _format.outlineColor;
					var outlineWidth:Number;
					const customWidth:* = getTagValue(i,TextTag.OUTLINE_WIDTH);
					if (customWidth) outlineWidth = customWidth;
					else outlineWidth = _format.outlineWidth;
					charLocation.setupOutline(outlineColor,outlineWidth);
				}
			}
		}
		private function updateAllSoftness():void {
			if (charLocationV) {
				const l:uint = charLocationV.length;
				for (var i:uint=0; i<l; i++) {
					const charLocation:CharLocation = charLocationV[i];
					charLocation.updateSoftness(_format.softness);
				}
			}
		}
		override public function multiplyColor():void {
			super.multiplyColor();
		}
		public function getCharLocationAt(index:uint):CharLocation {
			var charLocation:CharLocation;
			if (charLocationV && index < charLocationV.length) charLocation = charLocationV[index];
			return charLocation;
		}
		public function get text():String {return _text;}
		public function set text(value:String):void {
			setText(value,null);
		}
		public function setText(value:String,linkFunctionA:Array):void {
			_text = value;
			resetHitArea();
			setRequiresRecomposition();
			this.linkFunctionA = linkFunctionA;
		}
		private function get isHorizontalAutoSize():Boolean {
			return _options.autoSize == TextFieldAutoSize.HORIZONTAL || _options.autoSize == TextFieldAutoSize.BOTH_DIRECTIONS;
		}
		private function get isVerticalAutoSize():Boolean {
			return _options.autoSize == TextFieldAutoSize.VERTICAL || _options.autoSize == TextFieldAutoSize.BOTH_DIRECTIONS;
		}
		public function get format():TextFormatEx {return _format;}
		public function set format(textFormat:TextFormatEx):void {
			if (textFormat == null) throw new ArgumentError("format cannot be null");
			_format.copyFrom(textFormat);
		}
		public function get options():TextOptions {return _options;}
		public function get wordWrap():Boolean {return _options.wordWrap;}
		public function set wordWrap(value:Boolean):void {_options.wordWrap = value;}
		private function disposeTextBounds():void {
			Pool.putRectangle(_textBounds);
			_textBounds = null;
		}
		private function disposeTags():void {
			if (textTagA) {
				var l:uint, i:uint;
				l = textTagA.length;
				for (i=0; i<l; i++) {
					const textTag:TextTag = textTagA[i];
					TextTag.putInstance(textTag);
				}
				PoolEx.putArray(textTagA);
				textTagA = null;
			}
			if (tagObjectA) {
				l = tagObjectA.length;
				for (i=0; i<l; i++) {
					const tagObject:TagObject = tagObjectA[i];
					if (tagObject) TagObject.putInstance(tagObject);
				}
				PoolEx.putArray(tagObjectA);
				tagObjectA = null;
			}
		}
		private function disposeTextLinkV():void {
			if (textLinkV) {
				const l:uint = textLinkV.length;
				for (var i:uint=0; i<l; i++) {
					const textLink:TextLink = textLinkV[i];
					text_AS.removeChild(textLink);
					TextLink.putInstance(textLink);
				}
				TextLink.putVector(textLinkV);
				textLinkV = null;
				touchable = false;
			}
		}
		private function disposeBorder():void {
			if (_border) {
				_border.removeFromParent();
				while (_border.numChildren > 0) {
					const apertureQuad:ApertureQuad = _border.getChildAt(0) as ApertureQuad;
					_border.removeChild(apertureQuad);
					apertureQuad.dispose();
				}
				_border.dispose();
				_border = null;
			}
		}
		public override function dispose():void {
			disposeTextLinkV();
			CharLocation.putVector(charLocationV,true)
			charLocationV = null;
			removeChild(text_AS);
			text_AS.dispose();
			text_AS = null;
			if (shadow_AS) {
				removeChild(shadow_AS);
				shadow_AS.dispose();
				shadow_AS = null;
			}
			disposeTags();
			Pool.putRectangle(_hitArea);
			_hitArea = null;
			disposeTextBounds();
			_format.removeEventListener(Event.CHANGE,setRequiresRecomposition);
			_format.removeEventListener(TextFormatEx.APERTURE_CHANGE,apertureChange);
			_format.removeEventListener(TextFormatEx.SHADOW_CHANGE,shadowChange);
			TextFormatEx.putInstance(_format);
			_format = null;
			_options.removeEventListener(Event.CHANGE,setRequiresRecomposition);
			_options = null;
			disposeBorder();
			super.dispose();
		}
	}

}
