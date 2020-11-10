// StarlingEx - https://github.com/BladePoint/StarlingEx
// Copyright Doublehead Games, LLC. All rights reserved.
// This code is open source under the MIT License - https://github.com/BladePoint/StarlingEx/blob/master/docs/LICENSE
// Use in conjunction with Starling - https://gamua.com/starling/

package starlingEx.text {

	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.events.Event;
	import starling.rendering.Painter;
	import starling.text.TextFieldAutoSize;
	import starling.text.TextFormat;
	import starling.text.TextOptions;
	import starling.utils.Align;
	import starling.utils.Color;
	import starling.utils.Pool;
	import starling.utils.RectangleUtil;
	import starlingEx.display.ApertureQuad;
	import starlingEx.display.ApertureSprite;
	import starlingEx.text.ApertureTextFormat;
	import starlingEx.text.CharLocation;
	import starlingEx.text.DistanceFieldFont;
	import starlingEx.text.IDistanceCompositor;
	import starlingEx.text.TagObject;
	import starlingEx.text.TextLink;
	import starlingEx.text.TextTag;
	import starlingEx.utils.PoolEx;
	import starlingEx.utils.Utils;

	/* Much of this code is appropriated from starling.text.Textfield and altered in order to exclusively support DistanceFieldFont. */
	public class ApertureTextField extends ApertureSprite {
		static private const COMPOSITOR_DATA_NAME:String = "starlingEx.text.ApertureTextField.compositors";
		static private function get compositors():Dictionary {
			var compositors:Dictionary = Starling.painter.sharedData[COMPOSITOR_DATA_NAME] as Dictionary;
            if (compositors == null) {
				compositors = new Dictionary();
				Starling.painter.sharedData[COMPOSITOR_DATA_NAME] = compositors;
			}
            return compositors;
		}
		static public function registerCompositor(compositor:IDistanceCompositor,fontName:String):void {
			if (fontName == null) throw new ArgumentError("fontName must not be null");
			compositors[Utils.convertToLowerCase(fontName)] = compositor;
		}
		static public function unregisterCompositor(fontName:String,dispose:Boolean=true):void {
			fontName = Utils.convertToLowerCase(fontName);
			if (dispose && compositors[fontName] != undefined) compositors[fontName].dispose();
			delete compositors[fontName];
		}
		static public function getCompositor(fontName:String):IDistanceCompositor {
			return compositors[Utils.convertToLowerCase(fontName)];
		}
		static private var sMatrix:Matrix = Pool.getMatrix();

		public var container_AS:ApertureSprite, shadow_AS:ApertureSprite;
		public var charLocationV:Vector.<CharLocation>;
		public var tagObjectA:Array;
		public var textLinkV:Vector.<TextLink>;
		private var _hitArea:Rectangle, _textBounds:Rectangle;
		private var _text:String;
		private var _format:ApertureTextFormat;
		private var _options:TextOptions;
		private var _border:ApertureSprite;
		private var linkFunctionA:Array, textTagA:Array;
		private var compositor:IDistanceCompositor;
		private var requiresRecomposition:Boolean, recomposing:Boolean;
		/* If your text string includes link tags, be sure to pass an array of the functions to be called. The first function in the array
		   will be assigned to the first link, the second function will be assigned to the second link, etc... */
		public function ApertureTextField(width:int,height:int,text:String,format:ApertureTextFormat,options:TextOptions=null,linkFunctionA:Array=null) {
			_text = text;
			_format = format.cloneAperture();
			_format.assignTextField(this);
			_format.addEventListener(Event.CHANGE,setRequiresRecomposition);
			_format.addEventListener(ApertureTextFormat.APERTURE_CHANGE,apertureChange);
			_format.addEventListener(ApertureTextFormat.SHADOW_CHANGE,shadowChange);
			_options = options ? options.clone() : new TextOptions();
            _options.addEventListener(Event.CHANGE,setRequiresRecomposition);
			this.linkFunctionA = linkFunctionA;
			compositor = ApertureTextField.getCompositor(_format.font);
			container_AS = new ApertureSprite();
			addChild(container_AS);
			setHitArea(width,height);
			requiresRecomposition = true;
		}
		private function setHitArea(w:int,h:int):void {
			_hitArea = Pool.getRectangle();
			const max:uint = uint.MAX_VALUE;
			if (w>0 && h>0) {
				_options.autoSize = TextFieldAutoSize.NONE;
				_hitArea.width = w;
				_hitArea.height = h;
			} else if (w>0 && h<0) {
				_options.autoSize = TextFieldAutoSize.VERTICAL;
				_hitArea.width = w;
				_hitArea.height = max;
			} else if (w<0 && h>0) {
				_options.autoSize = TextFieldAutoSize.HORIZONTAL;
				_hitArea.width = max;
				_hitArea.height = h;
			} else if (w<0 && h<0) {
				_options.autoSize = TextFieldAutoSize.BOTH_DIRECTIONS;
				_hitArea.width = max;
				_hitArea.height = max;
			}
		}
		private function resetHitArea():void {
			const max:uint = uint.MAX_VALUE;
			if (_options.autoSize == TextFieldAutoSize.VERTICAL) _hitArea.height = max;
			else if (_options.autoSize == TextFieldAutoSize.HORIZONTAL) _hitArea.width = max;
			else if (_options.autoSize == TextFieldAutoSize.BOTH_DIRECTIONS) {
				_hitArea.width = max;
				_hitArea.height = max;
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
			Pool.putRectangle(_textBounds);
			_textBounds = null;
			disposeTags();
			disposeTextLinkV();
			compositor.resetCharLocation(charLocationV);
		}
		private function parseText():void {
			while (stripTag()) stripTag();
			initTagObjects();
			/*if (tagObjectA) {
				var l:uint = tagObjectA.length;
				for (var i:uint=0; i<l; i++) {
					var tagObject:TagObject = tagObjectA[i];
					if (tagObject) {
						var traceString:String = i+": ";
						for (var tagType:String in tagObject) {
							var textTag:TextTag = tagObject[tagType];
							traceString += textTag.tagType;
							if (textTag.value) traceString += "=" + textTag.value;
							traceString += ","
						}
						trace(traceString);
					}
				}
			}*/
		}
		private function stripTag():Boolean {
			var returnB:Boolean;
			var resultO:Object = TextTag.regExp.exec(_text);
			if (resultO == null) returnB = false;
			else {
				/*trace("matched text: " + resultO[0] + " at index " + resultO.index);
				trace("slash capture group: " + resultO[1]);
				trace("tag capture group: " + resultO[2]);
				trace("value capture group: " + resultO[3]);*/
				var tagIndex:uint = resultO.index,
					tagLength:uint = resultO[0].length;
				var endTag:String = resultO[1],
					tagType:String = resultO[2],
					tagValue:String = resultO[3];
				_text = _text.slice(0,tagIndex) + _text.slice(tagIndex+tagLength);
				if (!endTag) newTextTag(tagType,tagIndex,tagValue);
				else endTextTag(tagType,tagIndex);
				returnB = true;
			}
			return returnB;
		}
		public function newTextTag(tagType:String,tagIndex:uint,valueString:String):void {
			if (textTagA == null) textTagA = PoolEx.getArray();
			var textTag:TextTag = TextTag.getInstance(tagType,tagIndex);
			if (tagType == TextTag.COLOR) textTag.setColor(valueString);
			else if (tagType == TextTag.OUTLINE_COLOR) textTag.setOutlineColor(valueString);
			else if (tagType == TextTag.OUTLINE_WIDTH) textTag.setOutlineWidth(valueString);
			textTagA[textTagA.length] = textTag;
		}
		public function endTextTag(tagType:String,tagIndex:uint):void {
			for (var i:int=textTagA.length-1; i>=0; i--) {
				var textTag:TextTag = textTagA[i];
				if (textTag.tagType == tagType) {
					textTag.endIndex = tagIndex - 1;
					break;
				}
			}
		}
		public function initTagObjects():void {
			if (textTagA) {
				tagObjectA = Pool.getArray();
				tagObjectA.length = _text.length;
				var l:uint = textTagA.length;
				for (var i:uint=0; i<l; i++) {
					var textTag:TextTag = textTagA[i];
					var tagType:String = textTag.tagType;
					for (var j:uint=textTag.startIndex; j<=textTag.endIndex; j++) {
						var tagObject:TagObject = tagObjectA[j];
						if (tagObject == null) tagObject = tagObjectA[j] = TagObject.getTagObject();
						tagObject[tagType] = textTag;
					}
				}
			}
		}
		public function applyFormatTags(index:uint,charLocation:CharLocation):void {
			charLocation.italic = testFormatTag(TextTag.ITALIC,index);
			if (charLocation.strikethrough == null) charLocation.strikethrough = testFormatTag(TextTag.STRIKETHROUGH,index); //charLocation.strikethrough will already have a value if the previous strikethrough was split
			if (charLocation.underline == null) charLocation.underline = testFormatTag(TextTag.UNDERLINE,index);
			if (charLocation.link == null) charLocation.link = testFormatTag(TextTag.LINK,index);
		}
		private function testFormatTag(tagType:String,index:uint):String {
			var returnString:String;
			if (tagObjectA) {
				var tagObject:TagObject = tagObjectA[index];
				if (tagObject) returnString = tagObject.testFormatTag(tagType,index);
			}
			return returnString;
		}
		private function testValueTag(index:uint,tagType:String):* {
			var returnValue:*;
			if (tagObjectA) {
				var tagObject:TagObject = tagObjectA[index];
				if (tagObject) returnValue = tagObject.testValueTag(tagType);
			}
			return returnValue;
		}
		public function initCharColorAndOutline(i:uint,charLocation:CharLocation):void {
			var topLeftColor:uint = _format.topLeftColor,
				topRightColor:uint = _format.topRightColor,
				bottomLeftColor:uint = _format.bottomLeftColor,
				bottomRightColor:uint = _format.bottomRightColor,
				outlineColor:uint = _format.outlineColor;
			var outlineWidth:Number = _format.outlineWidth;
			var colorA:Array = testValueTag(i,TextTag.COLOR);
			if (colorA) {
				if (colorA.length == 1) topLeftColor = topRightColor = bottomLeftColor = bottomRightColor = colorA[0];
				else if (colorA.length == 2) {
					topLeftColor = topRightColor = colorA[0];
					bottomLeftColor = bottomRightColor = colorA[1];
				} else if (colorA.length == 4) {
					topLeftColor = colorA[0];
					topRightColor = colorA[1];
					bottomLeftColor = colorA[2];
					bottomRightColor = colorA[3];
				}
			}
			var outlineValue:* = testValueTag(i,TextTag.OUTLINE_COLOR);
			if (outlineValue) outlineColor = outlineValue;
			var outlineWidthResult:* = testValueTag(i,TextTag.OUTLINE_WIDTH);
			if (outlineWidthResult) outlineWidth = outlineWidthResult;
			var charQuad:ApertureQuad = charLocation.quad;
			if (charQuad) {
				charLocation.updateColor(topLeftColor,topRightColor,bottomLeftColor,bottomRightColor,false);
				compositor.setupOutline(charLocation,outlineColor,outlineWidth);
				charLocation.updateSoftness(compositor.getDefaultSoftness(_format));
				container_AS.addChild(charQuad);
			} else {//necessary to begin a textline if there is no charQuad
				charLocation.textLineTopLeftColor = topLeftColor;
				charLocation.textLineTopRightColor = topRightColor;
				charLocation.textLineBottomLeftColor = bottomLeftColor;
				charLocation.textLineBottomRightColor = bottomRightColor;
				charLocation.textLineOutlineColor = outlineColor;
				charLocation.textLineOutlineWidth = outlineWidth;
			}
		}
		private function updateText():void {
			var width:Number  = _hitArea.width,
				height:Number = _hitArea.height;
			container_AS.x = container_AS.y = 0;
			charLocationV = compositor.fillContainer(this,width,height);
			if (_options.autoSize != TextFieldAutoSize.NONE) {
				_textBounds = Pool.getRectangle();
                _textBounds = container_AS.getBounds(container_AS,_textBounds);
				if (isHorizontalAutoSize) {
					container_AS.x = _textBounds.x = -_textBounds.x;
					_hitArea.width = _textBounds.width;
					_textBounds.x = 0;
				}
				if (isVerticalAutoSize) {
                    container_AS.y = _textBounds.y = -_textBounds.y;
					_hitArea.height = _textBounds.height;
					_textBounds.y = 0;
				}
			} else {
				Pool.putRectangle(_textBounds);
				_textBounds = null;
			}
        }
		public function addTextLink(textLink:TextLink):void {
			if (textLinkV == null) textLinkV = TextLink.getVector();
			textLinkV[textLinkV.length] = textLink;
		}
		private function updateTextLink():void {
			if (textLinkV) {
				var l:uint = textLinkV.length;
				for (var i:uint=0; i<l; i++) {
					var textLink:TextLink = textLinkV[i];
					if (linkFunctionA && linkFunctionA.length > i) textLink.clickFunction = linkFunctionA[i];
					container_AS.addChild(textLink);
				}
				touchable = true;
			} else touchable = false;
			PoolEx.putArray(linkFunctionA);
			linkFunctionA = null;
		}
		private function updateShadow():void {
			if (_format.dropShadowX != 0 || _format.dropShadowY != 0 && _format.dropShadowAlpha != 0) {
				if (shadow_AS == null) {
					shadow_AS = new ApertureSprite();
					shadow_AS.touchable = false;
					addChildAt(shadow_AS,0);
				}
				compositor.fillShadow(this);
				positionShadow();
				alphaShadow();
				colorShadow();
			}
		}
		private function colorShadow():void {
			shadow_AS.setHex(_format.dropShadowColor,true);
		}
		private function positionShadow():void {
			shadow_AS.x = container_AS.x + _format.dropShadowX;
			shadow_AS.y = container_AS.y + _format.dropShadowY;
		}
		private function alphaShadow():void {
			shadow_AS.alpha = _format.dropShadowAlpha;
		}
		private function shadowChange(evt:Event,changeHex:uint):void {
			var positionB:Boolean = Boolean(Color.getRed(changeHex)),
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
			var width:Number  = _hitArea.width,
				height:Number = _hitArea.height;
			var topLine:ApertureQuad    = _border.getChildAt(0) as ApertureQuad,
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
		public function get format():TextFormat {return _format;}
		public function set format(textFormat:TextFormat):void {
			if (textFormat == null) throw new ArgumentError("format cannot be null");
			_format.copyFrom(textFormat);
        }
		public function get apertureFormat():ApertureTextFormat {return _format;}
		public function get options():TextOptions {return _options;}
		private function get isHorizontalAutoSize():Boolean {
			return _options.autoSize == TextFieldAutoSize.HORIZONTAL || _options.autoSize == TextFieldAutoSize.BOTH_DIRECTIONS;
		}
		private function get isVerticalAutoSize():Boolean {
			return _options.autoSize == TextFieldAutoSize.VERTICAL || _options.autoSize == TextFieldAutoSize.BOTH_DIRECTIONS;
		}
		public function get autoSize():String {return _options.autoSize;}
		public function set autoSize(value:String):void {_options.autoSize = value;}
		public function get wordWrap():Boolean {return _options.wordWrap;}
        public function set wordWrap(value:Boolean):void {_options.wordWrap = value;}
		public override function getBounds(targetSpace:DisplayObject,out:Rectangle=null):Rectangle {
            if (requiresRecomposition) recompose();
            getTransformationMatrix(targetSpace,sMatrix);
            return RectangleUtil.getBounds(_hitArea,sMatrix,out);
        }
		public function getTextBounds(targetSpace:DisplayObject,out:Rectangle=null):Rectangle {
			if (requiresRecomposition) recompose();
			if (_textBounds == null) {
				_textBounds = Pool.getRectangle();
				container_AS.getBounds(this,_textBounds);
			}
			getTransformationMatrix(targetSpace,sMatrix);
			return RectangleUtil.getBounds(_textBounds,sMatrix,out);
		}
		public function get text():String {return _text;}
		public function set text(value:String):void {
			setText(value,null);
        }
		public function setText(value:String,linkFunctionA:Array):void {
			if (value == null) value = "";
			_text = value;
			resetHitArea();
			setRequiresRecomposition();
			this.linkFunctionA = linkFunctionA;
		}
		private function apertureChange(evt:Event,changeHex:uint):void {
			var baseColorB:Boolean = Boolean(Color.getAlpha(changeHex)),
				outlineColorB:Boolean = Boolean(Color.getRed(changeHex)),
				outlineWidthB:Boolean = Boolean(Color.getGreen(changeHex)),
				outlineSoftnessB:Boolean = Boolean(Color.getBlue(changeHex));
			if (baseColorB) updateFormatColors();
			if (outlineColorB && !outlineWidthB) updateOutlineFormatColors();
			else if (!outlineColorB && outlineWidthB) updateOutlineFormatWidths();
			else if (outlineColorB && outlineWidthB) updateOutlineFormat();
			if (outlineSoftnessB) updateAllSoftness();
		}
		private function updateFormatColors():void {
			if (charLocationV) {
				var l:uint = charLocationV.length;
				for (var i:uint=0; i<l; i++) {
					var charLocation:CharLocation = charLocationV[i];
					if (charLocation.link) break;
					var colorValue:* = testValueTag(i,TextTag.COLOR);
					if (colorValue == null) charLocation.updateColor(_format.topLeftColor,_format.topRightColor,_format.bottomLeftColor,_format.bottomRightColor,true);
				}
			}
		}
		private function updateOutlineFormatColors():void {
			if (charLocationV) {
				var l:uint = charLocationV.length;
				for (var i:uint=0; i<l; i++) {
					var outlineValue:* = testValueTag(i,TextTag.OUTLINE_COLOR);
					if (outlineValue == null) {
						var charLocation:CharLocation = charLocationV[i];
						if (charLocation.link) break;
						charLocation.updateOutlineColor(_format.outlineColor,true);
					}
				}
			}
		}
		private function updateOutlineFormatWidths():void {
			if (charLocationV) {
				var l:uint = charLocationV.length;
				for (var i:uint=0; i<l; i++) {
					var outlineWidthValue:* = testValueTag(i,TextTag.OUTLINE_WIDTH);
					if (outlineWidthValue == null) {
						var charLocation:CharLocation = charLocationV[i];
						if (charLocation.link) break;
						compositor.updateOutlineWidth(charLocation,_format.outlineWidth);
					}
				}
			}
		}
		private function updateOutlineFormat():void {
			if (charLocationV) {
				var l:uint = charLocationV.length;
				for (var i:uint=0; i<l; i++) {
					var charLocation:CharLocation = charLocationV[i];
					if (charLocation.link) break;
					var customOutlineColor:* = testValueTag(i,TextTag.OUTLINE_COLOR);
					var outlineColor:uint;
					if (customOutlineColor) outlineColor = customOutlineColor;
					else outlineColor = _format.outlineColor;
					var outlineWidth:Number;
					var customWidth:* = testValueTag(i,TextTag.OUTLINE_WIDTH);
					if (customWidth) outlineWidth = customWidth;
					else outlineWidth = _format.outlineWidth;
					compositor.setupOutline(charLocation,outlineColor,outlineWidth);
				}
			}
		}
		private function updateAllSoftness():void {
			if (charLocationV) {
				var l:uint = charLocationV.length;
				for (var i:uint=0; i<l; i++) {
					var charLocation:CharLocation = charLocationV[i];
					charLocation.updateSoftness(_format.softness);
				}
			}
		}
		override public function multiplyColor():void {
			super.multiplyColor();
		}
		private function disposeTextLinkV():void {
			if (textLinkV) {
				var l:uint = textLinkV.length;
				for (var i:uint=0; i<l; i++) {
					var textLink:TextLink = textLinkV[i];
					container_AS.removeChild(textLink);
					TextLink.putInstance(textLink);
				}
				TextLink.putVector(textLinkV);
				textLinkV = null;
				touchable = false;
			}
		}
		private function disposeTags():void {
			if (textTagA) {
				var l:uint, i:uint;
				l = textTagA.length;
				for (i=0; i<l; i++) {
					var textTag:TextTag = textTagA[i];
					TextTag.putInstance(textTag);
				}
				PoolEx.putArray(textTagA);
				textTagA = null;
			}
			if (tagObjectA) {
				l = tagObjectA.length;
				for (i=0; i<l; i++) {
					var tagObject:TagObject = tagObjectA[i];
					if (tagObject) TagObject.putTagObject(tagObject);
				}
				PoolEx.putArray(tagObjectA);
				tagObjectA = null;
			}
		}
		private function disposeBorder():void {
			if (_border) {
				_border.removeFromParent();
				while (_border.numChildren > 0) {
					var apertureQuad:ApertureQuad = _border.getChildAt(0) as ApertureQuad;
					_border.removeChild(apertureQuad);
					apertureQuad.dispose();
				}
				_border.dispose();
				_border = null;
			}
		}
		public override function dispose():void {
			disposeTextLinkV();
			compositor.resetCharLocation(charLocationV);
			CharLocation.putVector(charLocationV)
			charLocationV = null;
			removeChild(container_AS);
			container_AS.dispose();
			container_AS = null;
			if (shadow_AS) {
				removeChild(shadow_AS);
				shadow_AS.dispose();
				shadow_AS = null;
			}
			disposeTags();
			Pool.putRectangle(_hitArea);
			Pool.putRectangle(_textBounds);
			_hitArea = _textBounds = null;
			_format.removeEventListener(Event.CHANGE,setRequiresRecomposition);
			_format.removeEventListener(ApertureTextFormat.APERTURE_CHANGE,apertureChange);
			_format.removeEventListener(ApertureTextFormat.SHADOW_CHANGE,shadowChange);
			ApertureTextFormat.putInstance(_format);
			_format = null;
			_options.removeEventListener(Event.CHANGE,setRequiresRecomposition);
			_options = null;
			disposeBorder();
			compositor = null;
			super.dispose();
		}

	}

}
