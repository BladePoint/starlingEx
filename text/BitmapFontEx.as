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
	import starling.styles.MeshStyle;
	import starling.text.BitmapFontType;
	import starling.textures.Texture;
	import starling.textures.TextureSmoothing;
	import starling.utils.Align;
	import starling.utils.Pool;
	import starling.utils.StringUtil;
	import starlingEx.display.ApertureQuad;
	import starlingEx.styles.ApertureDistanceFieldStyle;
	import starlingEx.text.BitmapCharEx;
	import starlingEx.text.Compositor;
	import starlingEx.text.IFont;
	import starlingEx.text.TextFormatEx;
	import starlingEx.textures.DynamicAtlas;
	import starlingEx.textures.TextureBitmapData;
	import starlingEx.utils.RectanglePacker;

	public class BitmapFontEx implements IFont {

		public var threshold:Number = Compositor.defaultThreshold;
		public var whiteX:int = -1, whiteY:int = -1;
		private var _characters:String, _name:String, _smoothing:String, _type:String;
		private var _chars:Dictionary;
		private var _offsetX:Number, _offsetY:Number, _padding:Number, _size:Number, _lineHeight:Number, _baseline:Number, _distanceFieldSpread:Number, _italicRadians:Number, _sinItalicRadians:Number, _lineThicknessProportion:Number, _baselineProportion:Number, _underlineProportion:Number, charQuadFactorySoftness:Number;
		private var charQuadV:Vector.<ApertureQuad>, lineQuadV:Vector.<ApertureQuad>;
		private var initCharFunction:Function;
		private var dynamicAtlas:DynamicAtlas;
		private var fontTexture:Texture, whiteTexture:Texture;
		private var fontBitmapData:BitmapData;
		public function BitmapFontEx(characters:String="") {
			_characters = characters;
			_chars = new Dictionary();
			_offsetX = _offsetY = _padding = 0.0;
			charQuadV = new <ApertureQuad>[];
			lineQuadV = new <ApertureQuad>[];
			addMissing();
			addQuadless();
		}
		public function initTexture(fontAtlasTexture:Texture,fontXML:XML):void {
			parseXmlData(fontXML);
			initCharFunction = initCharTexture;
			fontTexture = fontAtlasTexture;
			parseXmlChar(fontXML);
		}
		public function initBitmapData(fontAtlas_BMD:BitmapData,fontXML:XML,dynamicAtlas:DynamicAtlas=null):void {
			if (dynamicAtlas) {
				fontBitmapData = fontAtlas_BMD;
				parseXmlData(fontXML);
				dynamicAtlas.addEventListener(RectanglePacker.SUCCESS,packSuccess);
				dynamicAtlas.addEventListener(RectanglePacker.FAILURE,packFailure);
				this.dynamicAtlas = dynamicAtlas;
				initCharFunction = initCharTextureBitmap;
				parseXmlChar(fontXML);
			} else {
				const texture:Texture = Texture.fromBitmapData(fontAtlas_BMD);
				initTexture(texture,fontXML);
			}
		}
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
				initCharFunction(id,x,y,width,height,xOffset,yOffset,xAdvance);
			}
		}
		private function initCharTexture(id:int,x:Number,y:Number,width:Number,height:Number,xOffset:Number,yOffset:Number,xAdvance:Number):void {
			const bitmapChar:BitmapCharEx = new BitmapCharEx(this,id,xOffset,yOffset,xAdvance);
			const region:Rectangle = Pool.getRectangle(x,y,width,height);
			const texture:Texture = Texture.fromTexture(fontTexture,region);
			Pool.putRectangle(region);
			bitmapChar.initTexture(texture);
			addChar(id,bitmapChar);
		}
		private function initCharTextureBitmap(id:int,x:Number,y:Number,width:Number,height:Number,xOffset:Number,yOffset:Number,xAdvance:Number):void {
			const bitmapChar:BitmapCharEx = new BitmapCharEx(this,id,xOffset,yOffset,xAdvance);
			const textureBitmapData:TextureBitmapData = new TextureBitmapData(fontBitmapData);
			textureBitmapData.setSourceDimensions(width,height);
			textureBitmapData.setSourceOffset(x,y);
			bitmapChar.initTextureBitmap(textureBitmapData);
			dynamicAtlas.addRectangle(textureBitmapData);
			addChar(id,bitmapChar);
		}
		private function addChar(charID:int,bitmapChar:BitmapCharEx):void {
			_chars[charID] = bitmapChar;
		}
		private function addMissing():void {
			addChar(Compositor.CHAR_MISSING,new BitmapCharEx(this,Compositor.CHAR_MISSING,0,0,0));
		}
		private function addQuadless():void {
			addChar(Compositor.CHAR_NON,new BitmapCharEx(this,Compositor.CHAR_NON,0,0,0));
		}
		public function getChar(charID:int):BitmapCharEx {
			return _chars[charID];
		}
		public function initFormat(format:TextFormatEx):void {
			if (format.softness >= 0) charQuadFactorySoftness = format.softness;
			else charQuadFactorySoftness = _size / (format.size * _distanceFieldSpread);
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
		public function getCharQuad():ApertureQuad {
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
		public function putCharQuad(charQuad:ApertureQuad):void {
			if (charQuad) {
				charQuad.alignPivot(Align.LEFT,Align.TOP);
				charQuad.skewX = 0;
				charQuadV[charQuadV.length] = charQuad;
			}
		}
		private function charQuadStyleFactory():ApertureDistanceFieldStyle {
			const apertureDistanceFieldStyle:ApertureDistanceFieldStyle = new ApertureDistanceFieldStyle(charQuadFactorySoftness);
			apertureDistanceFieldStyle.multiChannel = multiChannel;
			return apertureDistanceFieldStyle;
		}
		public function getLineQuad(w:Number,h:Number):ApertureQuad {
			var lineQuad:ApertureQuad;
			if (lineQuadV.length == 0) {
				Mesh.defaultStyle = ApertureDistanceFieldStyle;
				lineQuad = new ApertureQuad(w,h);
				Mesh.defaultStyle = MeshStyle;
				lineQuad.texture = getWhiteTexture();
				const adfs:ApertureDistanceFieldStyle = lineQuad.style as ApertureDistanceFieldStyle;
				adfs.multiChannel = multiChannel;
				adfs.setupOutline(0,0x000000,1,false);
			} else {
				lineQuad = lineQuadV.pop();
				lineQuad.readjustSize(w,h);
			}
			lineQuad.touchable = false;
			return lineQuad;
		}
		public function putLineQuad(lineQuad:ApertureQuad):void {
			if (lineQuad) lineQuadV[lineQuadV.length] = lineQuad;
		}
		public function setWhiteTexture(whiteX:uint,whiteY:uint):void {
			this.whiteX = whiteX;
			this.whiteY = whiteY;
		}
		public function getWhiteTexture():Texture {
			var returnTexture:Texture;
			if (dynamicAtlas) returnTexture = dynamicAtlas.white_TB.texture;
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
			disposeSourceBitmapData();
		}
		private function packFailure(evt:Event):void {
			removePackListeners();
			dynamicAtlas = null;
			for each (var charID:int in _chars) {
				const bitmapChar:BitmapCharEx = _chars[charID];
				const texture:Texture = bitmapChar.texture;
			}
			disposeSourceBitmapData();
		}
		private function removePackListeners():void {
			dynamicAtlas.removeEventListener(RectanglePacker.SUCCESS,packSuccess);
			dynamicAtlas.removeEventListener(RectanglePacker.SUCCESS,packFailure);
		}
		private function disposeSourceBitmapData():void {
			if (fontBitmapData) {
				fontBitmapData.dispose();
				fontBitmapData = null;
			}
		}
		public function dispose():void {
			
		}
	}

}