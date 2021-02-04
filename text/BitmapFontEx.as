// StarlingEx - https://github.com/BladePoint/StarlingEx
// Copyright Doublehead Games, LLC. All rights reserved.
// This code is open source under the MIT License - https://github.com/BladePoint/StarlingEx/blob/master/docs/LICENSE
// Use in conjunction with Starling - https://gamua.com/starling/

package starlingEx.text {

	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	import starling.display.Mesh;
	import starling.events.Event;
	import starling.text.BitmapFontType;
	import starling.textures.Texture;
	import starling.textures.TextureSmoothing;
	import starling.utils.Align;
	import starling.utils.Pool;
	import starling.utils.StringUtil;
	import starlingEx.display.ApertureQuad;
	import starlingEx.display.QuadDrawable;
	import starlingEx.events.EventEx;
	import starlingEx.styles.ApertureDistanceFieldStyle;
	import starlingEx.text.BitmapCharEx;
	import starlingEx.text.Compositor;
	import starlingEx.text.IFont;
	import starlingEx.text.TextFormatEx;
	import starlingEx.textures.DynamicAtlas;
	import starlingEx.textures.TextureBitmapData;
	import starlingEx.utils.PoolEx;

	/* A BitmapFontEx is a class for bitmap fonts to be used with TextFieldEx. Multiple BitmapFontEx instances can be used with a single DynamicAtlas
	   in order to reduce draw calls. Some of this code is appropriated from starling.text.BitmapFont. */
	public class BitmapFontEx implements IFont {
		static private const instancePool:Vector.<BitmapFontEx> = new <BitmapFontEx>[];
		static public function getInstance(characters:String=""):BitmapFontEx {
			var bitmapFont:BitmapFontEx;
			if (instancePool.length == 0) bitmapFont = new BitmapFontEx(characters);
			else {
				bitmapFont = instancePool.pop();
				bitmapFont.init(characters);
			}
			return bitmapFont;
		}
		static public function putInstance(bitmapFont:BitmapFontEx):void {
			if (bitmapFont) {
				bitmapFont.reset();
				instancePool[instancePool.length] = bitmapFont;
			}
		}

		public var threshold:Number = Compositor.defaultThreshold,
			softness:Number;
		private var _characters:String, _name:String, _smoothing:String, _type:String;
		private var _chars:Dictionary;
		private var _offsetX:Number, _offsetY:Number, _padding:Number, _size:Number, _lineHeight:Number, _baseline:Number, _distanceFieldSpread:Number, _italicRadians:Number, _sinItalicRadians:Number, _lineThicknessProportion:Number, _baselineProportion:Number, _underlineProportion:Number, charQuadFactorySoftness:Number;
		private var whiteX:int = -1, whiteY:int = -1;
		private var charQuadA:Array, lineQuadA:Array;
		private var initCharFunction:Function;
		private var dynamicAtlas:DynamicAtlas;
		private var fontTexture:Texture, whiteTexture:Texture;
		private var fontBitmapData:BitmapData;

		/* Pass a string containing the characters you wish to use, or use the default value if you want to use all the characters. */
		public function BitmapFontEx(characters:String="") {
			init(characters);
		}
		private function init(characters:String=""):void {
			removeDuplicateCharacters(characters);
			_offsetX = _offsetY = _padding = 0.0;
			addMissing();
			addQuadless();
			charQuadA = PoolEx.getArray();
			lineQuadA = PoolEx.getArray();
		}
		private function removeDuplicateCharacters(characters:String):void {
			const array:Array = PoolEx.getArray();
			var l:uint = characters.length;
			for (var i:uint=0; i<l; i++) {
				const character:String = characters.charAt(i);
				if (array.indexOf(character) == -1) array[array.length] = character;
			}
			_characters = array.join();
			PoolEx.putArray(array);
		}
		private function addMissing():void {
			addChar(Compositor.CHAR_MISSING,BitmapCharEx.getInstance(this,Compositor.CHAR_MISSING,0,0,0));
		}
		private function addQuadless():void {
			addChar(Compositor.CHAR_NON,BitmapCharEx.getInstance(this,Compositor.CHAR_NON,0,0,0));
		}
		private function addChar(charID:int,bitmapChar:BitmapCharEx):void {
			if (_chars == null) _chars = new Dictionary();
			_chars[charID] = bitmapChar;
		}
		public function getChar(charID:int):BitmapCharEx {
			return _chars[charID];
		}
		/* Initialize with a Texture and XML. A DynamicAtlas cannot be used if you initialize with a Texture.*/
		public function initTexture(fontAtlasTexture:Texture,fontXML:XML):void {
			parseXmlData(fontXML);
			initCharFunction = initCharTexture;
			fontTexture = fontAtlasTexture;
			parseXmlChar(fontXML);
		}
		/* Initialize with a BitmapData and XML. Pass a dynamicAtlas for the 3rd parameter if you wish for this
		   BitmapFontEx to be included in it. */
		public function initBitmapData(fontAtlas_BMD:BitmapData,fontXML:XML,dynamicAtlas:DynamicAtlas=null):void {
			if (dynamicAtlas) {
				fontBitmapData = fontAtlas_BMD;
				parseXmlData(fontXML);
				dynamicAtlas.addEventListener(EventEx.SUCCESS,packSuccess);
				dynamicAtlas.addEventListener(EventEx.FAILURE,packFailure);
				this.dynamicAtlas = dynamicAtlas;
				initCharFunction = initCharTextureBitmap;
				parseXmlChar(fontXML);
			} else {
				const texture:Texture = Texture.fromBitmapData(fontAtlas_BMD);
				initTexture(texture,fontXML);
			}
		}
		/* Initialize with a Bitmap class and XML. Pass a dynamicAtlas for the 3rd parameter if you wish for this
		BitmapFontEx to be included in it. */
		public function initBitmapClass(fontAtlasBitmapClass:Class,fontXML:XML,dynamicAtlas:DynamicAtlas=null):void {
			if (dynamicAtlas) {
				const bitmap:Bitmap = new fontAtlasBitmapClass();
				const bitmapData:BitmapData = bitmap.bitmapData;
				bitmap.bitmapData = null;
				initBitmapData(bitmapData,fontXML,dynamicAtlas);
			} else {
				const texture:Texture = Texture.fromBitmap(new fontAtlasBitmapClass());
				texture.root.onRestore = function():void {texture.root.uploadBitmapData(new fontAtlasBitmapClass());};
				initTexture(texture,fontXML);
			}
		}
		private function parseXmlData(fontXML:XML):void {
			_name = StringUtil.clean(fontXML.info.@face);
			_size = parseFloat(fontXML.info.@size);
			_lineHeight = parseFloat(fontXML.common.@lineHeight);
			_baseline = parseFloat(fontXML.common.@base);
			if (fontXML.info.@smooth.toString() == "0") _smoothing = TextureSmoothing.NONE;
			if (_size <= 0) throw new Error("Warning: invalid font size in '" + _name + "' font.");
			if (fontXML.distanceField.length()) {
				_distanceFieldSpread = parseFloat(fontXML.distanceField.@distanceRange);
				_type = fontXML.distanceField.@fieldType == "msdf" ? BitmapFontType.MULTI_CHANNEL_DISTANCE_FIELD : BitmapFontType.DISTANCE_FIELD;
			} else {
				_distanceFieldSpread = 0.0;
				_type = BitmapFontType.STANDARD;
			}
		}
		protected function parseXmlChar(fontXML:XML):void {
			if (_characters) {
				const l:uint = _characters.length;
				for (var i:uint=0; i<l; i++) {
					var charCode:Number = _characters.charCodeAt(i);
					var XMLlist:XMLList = fontXML.chars.char.(@id == charCode);
					initChar(XMLlist[0]);
				}
			} else for each (var xml:XML in fontXML.chars.char) initChar(xml);
			for each (var kerningElement:XML in fontXML.kernings.kerning) {
				const first:int = parseInt(kerningElement.@first);
				const second:int = parseInt(kerningElement.@second);
				const amount:Number = parseFloat(kerningElement.@amount);
				if (second in _chars) getChar(second).addKerning(first,amount);
			}
		}
		private function initChar(xml:XML):void {
			if (xml) {
				const id:int = parseInt(xml.@id);
				const x:Number = parseFloat(xml.@x),
					y:Number = parseFloat(xml.@y),
					width:Number = parseFloat(xml.@width),
					height:Number = parseFloat(xml.@height);
				const xOffset:Number = parseFloat(xml.@xoffset);
				const yOffset:Number = parseFloat(xml.@yoffset);
				const xAdvance:Number = parseFloat(xml.@xadvance);
				const bitmapChar:BitmapCharEx = BitmapCharEx.getInstance(this,id,xOffset,yOffset,xAdvance);
				initCharFunction(id,x,y,width,height,bitmapChar);
			}
		}
		private function initCharTexture(id:int,x:Number,y:Number,width:Number,height:Number,bitmapChar:BitmapCharEx):void {
			const region:Rectangle = Pool.getRectangle(x,y,width,height);
			const texture:Texture = Texture.fromTexture(fontTexture,region);
			Pool.putRectangle(region);
			bitmapChar.initTexture(texture);
			addChar(id,bitmapChar);
		}
		private function initCharTextureBitmap(id:int,x:Number,y:Number,width:Number,height:Number,bitmapChar:BitmapCharEx):void {
			const textureBitmapData:TextureBitmapData = TextureBitmapData.getInstance(fontBitmapData);
			textureBitmapData.setSourceArea(x,y,width,height);
			bitmapChar.initTextureBitmap(textureBitmapData);
			dynamicAtlas.addDrawable(textureBitmapData);
			addChar(id,bitmapChar);
		}
		public function initFormat(format:TextFormatEx):void {
			if (format.softness >= 0) charQuadFactorySoftness = format.softness;
			else {
				if (!isNaN(softness)) charQuadFactorySoftness = softness;
				else charQuadFactorySoftness = _size / (format.size * _distanceFieldSpread);
			}
		}
		public function get name():String {return _name;}
		public function get size():Number {return _size;}
		public function get type():String {return _type;}
		public function get distanceFont():Boolean {
			var returnB:Boolean;
			if (_type == BitmapFontType.DISTANCE_FIELD || _type == BitmapFontType.MULTI_CHANNEL_DISTANCE_FIELD) returnB = true;
			return returnB;
		}
		public function get multiChannel():Boolean {
			if (_type == BitmapFontType.MULTI_CHANNEL_DISTANCE_FIELD) return true;
			else return false;
		}
		public function get padding():Number {return _padding;}
		public function get lineHeight():Number {return _lineHeight;}
		public function get offsetX():Number {return _offsetX;}
		public function get offsetY():Number {return _offsetY;}
		public function get italicRadians():Number {
			return _italicRadians;
		}
		public function set italicRadians(radians:Number):void {
			_italicRadians = radians;
			calcSinItalicRadians();
		}
		private function calcSinItalicRadians():void {
			_sinItalicRadians = Math.sin(_italicRadians);
		}
		public function get sinItalicRadians():Number {
			return _sinItalicRadians;
		}
		public function getCharQuad(char:BitmapCharEx):ApertureQuad {
			const textureBitmapData:TextureBitmapData = char.textureBitmapData;
			var charQuad:ApertureQuad;
			if (charQuadA.length == 0) {
				Mesh.defaultStyleFactory = charQuadStyleFactory;
				if (textureBitmapData) charQuad = new QuadDrawable(textureBitmapData) as ApertureQuad;
				else {
					charQuad = new ApertureQuad();
					charQuad.texture = char.texture;
				}
				Mesh.defaultStyleFactory = null;
			}
			else {
				charQuad = charQuadA.pop();
				if (textureBitmapData) {
					const quadDrawable:QuadDrawable = charQuad as QuadDrawable;
					quadDrawable.assignTextureEx(char.textureBitmapData);
				} else charQuad.texture = char.texture;
			}
			return charQuad;
		}
		public function putCharQuad(charQuad:ApertureQuad):void {
			if (charQuad) {
				if (charQuad is QuadDrawable) {
					const quadDrawable:QuadDrawable = charQuad as QuadDrawable;
					quadDrawable.reset();
				} else charQuad.texture = null;
				charQuad.alignPivot(Align.LEFT,Align.TOP);
				charQuad.skewX = 0;
				charQuadA[charQuadA.length] = charQuad;
			}
		}
		private function charQuadStyleFactory():ApertureDistanceFieldStyle {
			const apertureDistanceFieldStyle:ApertureDistanceFieldStyle = new ApertureDistanceFieldStyle(charQuadFactorySoftness);
			apertureDistanceFieldStyle.multiChannel = multiChannel;
			return apertureDistanceFieldStyle;
		}
		public function getLineQuad(w:Number,h:Number):ApertureQuad {
			var lineQuad:ApertureQuad;
			if (lineQuadA.length == 0) {
				Mesh.defaultStyleFactory = lineQuadStyleFactory;
				if (dynamicAtlas) {
					lineQuad = new QuadDrawable(dynamicAtlas.white_TBD);
					lineQuad.readjustSize(w,h);
				} else {
					lineQuad = new ApertureQuad(w,h);
					lineQuad.texture = getWhiteTexture();
				}
				Mesh.defaultStyleFactory = null;
			} else {
				lineQuad = lineQuadA.pop();
				lineQuad.readjustSize(w,h);
			}
			return lineQuad;
		}
		public function putLineQuad(lineQuad:ApertureQuad):void {
			if (lineQuad) lineQuadA[lineQuadA.length] = lineQuad;
		}
		private function lineQuadStyleFactory():ApertureDistanceFieldStyle {
			const apertureDistanceFieldStyle:ApertureDistanceFieldStyle = new ApertureDistanceFieldStyle();
			apertureDistanceFieldStyle.multiChannel = multiChannel;
			apertureDistanceFieldStyle.setupOutline(0,0x000000,1,false);
			return apertureDistanceFieldStyle;
		}
		public function setWhiteTexture(whiteX:uint,whiteY:uint):void {
			this.whiteX = whiteX;
			this.whiteY = whiteY;
		}
		public function getWhiteTexture():Texture {
			var returnTexture:Texture;
			if (dynamicAtlas) returnTexture = dynamicAtlas.white_TBD.texture;
			else if (fontTexture && whiteX >=0 && whiteY >= 0) {
				if (whiteTexture == null) {
					const region:Rectangle = Pool.getRectangle(whiteX,whiteY,1,1);
					whiteTexture = Texture.fromTexture(fontTexture,region);
					Pool.putRectangle(region);
				}
				returnTexture = whiteTexture;
			}
			return returnTexture;
		}
		public function getWhiteTBD():TextureBitmapData {
			if (dynamicAtlas) return dynamicAtlas.white_TBD;
			else return null;
		}
		public function get lineThicknessProportion():Number {
			return _lineThicknessProportion;
		}
		public function set lineThicknessProportion(decimal:Number):void {
			_lineThicknessProportion = decimal;
		}
		public function get baselineProportion():Number {
			return _baselineProportion;
		}
		public function set baselineProportion(decimal:Number):void {
			_baselineProportion = decimal;
		}
		public function get underlineProportion():Number {
			return _underlineProportion;
		}
		public function set underlineProportion(decimal:Number):void {
			_underlineProportion = decimal;
		}
		private function packSuccess(evt:Event):void {
			removePackListeners();
		}
		private function packFailure(evt:Event):void {
			removePackListeners();
			dynamicAtlas = null;
		}
		private function removePackListeners():void {
			dynamicAtlas.removeEventListener(EventEx.SUCCESS,packSuccess);
			dynamicAtlas.removeEventListener(EventEx.FAILURE,packFailure);
		}
		public function reset():void {
			threshold = Compositor.defaultThreshold;
			whiteX = whiteY = -1;
			_characters = _name = _smoothing = _type = "";
			if (_chars) {
				for (var charID:int in _chars) {
					const bitmapChar:BitmapCharEx = _chars[charID];
					if (bitmapChar.textureBitmapData) {
						const textureBitmapData:TextureBitmapData = bitmapChar.textureBitmapData;
						TextureBitmapData.putInstance(textureBitmapData);
					} else if (bitmapChar.texture) {
						const texture:Texture = bitmapChar.texture;
						texture.dispose();
					}
					BitmapCharEx.putInstance(bitmapChar);
					delete _chars[charID];
				}
			}
			_size = _lineHeight = _baseline = _distanceFieldSpread = _italicRadians = _sinItalicRadians = _lineThicknessProportion = _baselineProportion = _underlineProportion = charQuadFactorySoftness = NaN;
			disposeQuadArray(charQuadA);
			PoolEx.putArray(charQuadA);
			disposeQuadArray(lineQuadA);
			PoolEx.putArray(lineQuadA);
			charQuadA = lineQuadA = null;
			initCharFunction = null;
			if (dynamicAtlas) {
				removePackListeners();
				dynamicAtlas = null;
			}
			if (fontTexture) {
				fontTexture.root.onRestore = null;
				fontTexture.dispose();
				fontTexture = null;
			}
			if (whiteTexture) {
				whiteTexture.dispose();
				whiteTexture = null;
			}
			if (fontBitmapData) {
				fontBitmapData.dispose();
				fontBitmapData = null;
			}
		}
		private function disposeQuadArray(array:Array):void {
			const l:uint = array.length;
			for (var i:uint=0; i<l; i++) {
				const apertureQuad:ApertureQuad = array[i];
				apertureQuad.dispose();
			}
			array.length = 0;
		}
		public function dispose():void {
			reset();
			_chars = null;
		}
	}

}
