// StarlingEx - https://github.com/BladePoint/StarlingEx
// Copyright Doublehead Games, LLC. All rights reserved.
// This code is open source under the MIT License - https://github.com/BladePoint/StarlingEx/blob/master/docs/LICENSE
// Use in conjunction with Starling - https://gamua.com/starling/

package starlingEx.textures {

	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.geom.Vector3D;
	import starling.core.Starling;
	import starling.events.Event;
	import starling.textures.Texture;
	import starling.utils.MathUtil;
	import starling.utils.Pool;
	import starlingEx.textures.TextureBitmapData;
	import starlingEx.textures.TextureDrawable;
	import starlingEx.utils.RectanglePacker;
	import starlingEx.utils.Utils;

	public class DynamicAtlas extends RectanglePacker {
		static private const instancePool:Vector.<DynamicAtlas> = new <DynamicAtlas>[];
		static public function getInstance(includeWhiteTextureBitmapData:Boolean=true):DynamicAtlas {
			var dynamicAtlas:DynamicAtlas;
			if (instancePool.length == 0) dynamicAtlas = new DynamicAtlas(includeWhiteTextureBitmapData);
			else {
				dynamicAtlas = instancePool.pop();
				dynamicAtlas.setMaxContainerLength(Texture.maxSize);
				dynamicAtlas.init(includeWhiteTextureBitmapData);
			}
			return dynamicAtlas;
		}
		static public function putInstance(dynamicAtlas:DynamicAtlas):void {
			if (dynamicAtlas) {
				dynamicAtlas.reset();
				instancePool[instancePool.length] = dynamicAtlas;
			}
		}
		static private var white_BMD:BitmapData;
		static private function initWhiteBitmapData():void {
			white_BMD = new BitmapData(1,1,false,0xffffff);
		}

		public var texture:Texture;
		/* If true, draws the smallest possible bitmapData. If false, draws a bitmapData that is the same size as the container rectangle. Set to false
		   if you plan on using the packMore method.*/
		public var drawToBounds:Boolean = true,
			mipMapping:Boolean;
		private var _white_TBD:TextureBitmapData;
		private var bitmapData:BitmapData;
		private var uploading:Boolean, requiresUpload:Boolean;
		public function DynamicAtlas(includeWhiteTextureBitmapData:Boolean=true) {
			super(Texture.maxSize);
			init(includeWhiteTextureBitmapData);
		}
		override protected function setMaxContainerLength(maxContainerLength:uint):void {
			_maxContainerLength = Utils.previousPowerOfTwo(maxContainerLength);
		}
		private function init(includeWhiteTextureBitmapData:Boolean):void {
			if (includeWhiteTextureBitmapData) addWhiteTextureBitmapData();
		}
		public function addWhiteTextureBitmapData():void {
			if (white_BMD == null) initWhiteBitmapData();
			if (_white_TBD == null) {
				_white_TBD = TextureBitmapData.getInstance(white_BMD);
				_white_TBD.atlasExtrude = true;
			}
			addDrawable(_white_TBD);
		}
		public function get white_TBD():TextureBitmapData {return _white_TBD;}
		public function addDrawable(textureDrawable:TextureDrawable):void {
			const length:uint = notPackedA.length;
			dictionary[textureDrawable] = length;
			notPackedA[length] = textureDrawable;
			textureDrawable.calcRectangle();
		}
		public function addDrawables(...args):void {
			addRectangleA(args);
			args.length = 0;
		}
		public function addDrawableA(rectA:Array):void {
			const l:uint = rectA.length;
			for (var i:uint=0; i<l; i++) {
				addDrawable(rectA[i]);
			}
		}
		public function removeDrawable(textureDrawable:TextureDrawable):Boolean {
			var returnResult:Boolean;
			if (dictionary[textureDrawable] != null) {
				const index:uint = dictionary[textureDrawable];
				var testElement:*;
				if (index < packedA.length) {
					testElement = packedA[index];
					if (textureDrawable == testElement) {
						packedA.splice(index,1);
						returnResult = true;
						return returnResult;
					}
				}
				if (index < morePackedA.length) {
					testElement = morePackedA[index];
					if (textureDrawable == testElement) {
						morePackedA.splice(index,1);
						returnResult = true;
						return returnResult;
					}
				}
				if (index < notPackedA.length) {
					testElement = notPackedA[index];
					if (textureDrawable == testElement) {
						notPackedA.splice(index,1);
						returnResult = true;
						return returnResult;
					}
				}
			}
			return returnResult;
		}
		override protected function calcNotPacked(vector3D:Vector3D):void {
			const l:uint = notPackedA.length;
			for (var i:uint=0; i<l; i++) {
				const notPackedElement:* = notPackedA[i];
				var rect:Rectangle;
				if (notPackedElement is TextureDrawable) {
					const textureDrawable:TextureDrawable = notPackedElement as TextureDrawable;
					rect = textureDrawable.atlasRect;
				} else if (notPackedElement is Rectangle) rect = notPackedElement as Rectangle;
				vector3D.z += rect.width * rect.height;
				vector3D.x = MathUtil.max(vector3D.x,rect.width);
				vector3D.y = MathUtil.max(vector3D.y,rect.height);
			}
		}
		override protected function sort(array:Array):void {
			array.sort(sortByHeightAscending);
		}
		private function sortByHeightAscending(element1:*,element2:*):int {
			var height1:Number = getElementHeight(element1),
				height2:Number = getElementHeight(element2);
			if (height1 < height2) return -1;
			else if (height1 > height2) return 1;
			else return 0;
		}
		private function getElementHeight(element:*):Number {
			var height:Number;
			if (element is TextureDrawable) {
				const textureDrawable:TextureDrawable = element as TextureDrawable;
				height = textureDrawable.atlasRect.height;
			} else if (element is Rectangle) {
				const rect:Rectangle = element as Rectangle;
				height = rect.height;
			}
			return height;
		}
		override protected function updateDictionary(array:Array):void {
			const l:uint = array.length;
			for (var i:uint=0; i<l; i++) {
				const arrayElement:* = array[i];
				dictionary[arrayElement] = i;
			}
		}
		override protected function getRectFromArray(array:Array,index:uint):Rectangle {
			const arrayElement:* = array[index];
			var rect:Rectangle;
			if (arrayElement is TextureDrawable) {
				const textureDrawable:TextureDrawable = arrayElement as TextureDrawable;
				rect = textureDrawable.atlasRect;
			} else if (arrayElement is Rectangle) rect = arrayElement as Rectangle;
			return rect;
		}
		override protected function dispatchPackResult(packResult:Boolean):void {
			if (packResult) {
				drawRectangles(packedA);
				initTexture();
			}
			super.dispatchPackResult(packResult);
		}
		override protected function dispatchPackMoreResult(packMoreResult:Boolean,resizedContainer:Boolean):void {
			if (packMoreResult) {
				if (resizedContainer) {
					bitmapData.dispose();
					bitmapData = null;
					drawRectangles(packedA);
					drawRectangles(morePackedA);
					morePackedToPacked();
					initTexture();
					dispatchEventWith(Event.CHANGE);
				} else {
					drawRectangles(morePackedA);
					morePackedToPacked();
					setRequiresUpload();
				}
			}
			super.dispatchPackMoreResult(packMoreResult,resizedContainer);
		}
		private function drawRectangles(array:Array):void {
			if (bitmapData == null) initBitmapData();
			const l:uint = array.length;
			for (var i:uint=0; i<l; i++) {
				const arrayElement:* = array[i];
				if (arrayElement is TextureBitmapData) {
					const textureBitmapData:TextureBitmapData = arrayElement as TextureBitmapData;
					copyTextureBitmap(textureBitmapData);
					textureBitmapData.addEventListener(TextureDrawable.DRAWABLE_CHANGED_CONTENTS,redrawTextureBitmapData);
					//textureBitmapData.addEventListener(TextureDrawable.DRAWABLE_CHANGED_SIZE,redrawTextureBitmapData);
					textureBitmapData.assignAtlas(this);
				}
			}
		}
		private function copyTextureBitmap(textureBitmapData:TextureBitmapData,cleanTargetArea:Boolean=false):void {
			if (cleanTargetArea) bitmapData.fillRect(textureBitmapData.atlasRect,TextureDrawable.transparentGreenHex);
			textureBitmapData.copyPixelsTo(bitmapData);
			if (textureBitmapData.whiteFill) TextureDrawable.applyWhiteTransform(bitmapData,textureBitmapData.textureRect);
			if (textureBitmapData.atlasExtrude) extrude(textureBitmapData.textureRect);
		}
		private function extrude(targetRect:Rectangle):void {
			const copyRect:Rectangle = Pool.getRectangle(targetRect.left,targetRect.top,targetRect.width,1);
			const copyPoint:Point = Pool.getPoint(copyRect.left,copyRect.top-1);
			bitmapData.copyPixels(bitmapData,copyRect,copyPoint);
			copyRect.y = targetRect.bottom - 1;
			copyPoint.y = targetRect.bottom;
			bitmapData.copyPixels(bitmapData,copyRect,copyPoint);
			copyRect.y = targetRect.top;
			copyRect.width = 1;
			copyRect.height = targetRect.height;
			copyPoint.x = copyRect.left - 1;
			copyPoint.y = copyRect.top;
			bitmapData.copyPixels(bitmapData,copyRect,copyPoint);
			copyRect.x = targetRect.right - 1;
			copyPoint.x = targetRect.right;
			bitmapData.copyPixels(bitmapData,copyRect,copyPoint);
			bitmapData.setPixel32(targetRect.left-1,targetRect.top-1,bitmapData.getPixel32(targetRect.left,targetRect.top));
			bitmapData.setPixel32(targetRect.right,targetRect.top-1,bitmapData.getPixel32(targetRect.right-1,targetRect.top));
			bitmapData.setPixel32(targetRect.left-1,targetRect.bottom,bitmapData.getPixel32(targetRect.left,targetRect.bottom-1));
			bitmapData.setPixel32(targetRect.right,targetRect.bottom,bitmapData.getPixel32(targetRect.right-1,targetRect.bottom-1));
			Pool.putRectangle(copyRect);
			Pool.putPoint(copyPoint);
		}
		private function redrawTextureBitmapData(evt:Event):void {
			const textureBitmapData:TextureBitmapData = evt.target as TextureBitmapData;
			copyTextureBitmap(textureBitmapData,true);
			setRequiresUpload();
		}
		private function initBitmapData():void {
			if (bitmapData) bitmapData.dispose();
			var w:uint, h:uint;
			if (drawToBounds) {
				w = bounds.width;
				h = bounds.height;
			} else {
				w = container.width;
				h = container.height;
			}
			bitmapData = TextureDrawable.newBitmapData(w,h);
		}
		public function setRequiresUpload(evt:starling.events.Event=null):void {
			requiresUpload = true;
		}
		private function initTexture():void {
			if (texture) texture.dispose();
			texture = Texture.fromBitmapData(bitmapData,mipMapping);
			addEventFrameUpload();
		}
		private function addEventFrameUpload():void {
			Starling.current.stage.addEventListener(Event.ENTER_FRAME,uploadBitmapData);
		}
		private function removeEventFrameUpload():void {
			Starling.current.stage.removeEventListener(Event.ENTER_FRAME,uploadBitmapData);
		}
		private function uploadBitmapData(evt:Event):void {
			if (requiresUpload && !uploading) {
				uploading = true;
				texture.root.uploadBitmapData(bitmapData);
				requiresUpload = uploading = false;
			}
		}
		override public function repack():void {
			requiresUpload = false;
			
		}
		override public function reset():void {
			removeEventFrameUpload();
			if (texture) {
				texture.dispose();
				texture = null;
			}
			mipMapping = false;
			if (bitmapData) {
				bitmapData.dispose();
				bitmapData = null;
			}
			unassignPacked();
			super.reset();
		}
		public function unassignPacked():void {
			const l:uint = packedA.length;
			for (var i:uint=0; i<l; i++) {
				const rect:Rectangle = packedA[i];
				if (rect is TextureBitmapData) {
					const textureBitmapData:TextureBitmapData = rect as TextureBitmapData;
					textureBitmapData.assignAtlas(null);
				}
			}
		}
		override protected function resetPackArrays():void {
			resetPackArray(notPackedA);
			resetPackArray(packedA);
			resetPackArray(morePackedA);
		}
		private function resetPackArray(packA:Array):void {
			packA.length = 0;
		}
		override public function resetDictionary():void {
			for (var textureDrawable:TextureDrawable in dictionary) {delete dictionary[textureDrawable];}
			super.resetDictionary();
		}
		override public function dispose():void {
			reset();
			if (_white_TBD) {
				TextureBitmapData.putInstance(_white_TBD);
				_white_TBD = null;
			}
			super.dispose();
		}
	}
	
}
