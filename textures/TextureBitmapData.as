// StarlingEx - https://github.com/BladePoint/StarlingEx
// Copyright Doublehead Games, LLC. All rights reserved.
// This code is open source under the MIT License - https://github.com/BladePoint/StarlingEx/blob/master/docs/LICENSE
// Use in conjunction with Starling - https://gamua.com/starling/

package starlingEx.textures {

	import flash.display.BitmapData;
	import flash.display.IBitmapDrawable;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import starling.utils.Pool;
	import starlingEx.textures.TextureDrawable;

	public class TextureBitmapData extends TextureDrawable {
		static private const instancePool:Vector.<TextureBitmapData> = new <TextureBitmapData>[];
		static public function getInstance(bitmapData:BitmapData,textureMultiplier:Number=1):TextureBitmapData {
			var textureBitmapData:TextureBitmapData;
			if (instancePool.length == 0) textureBitmapData = new TextureBitmapData(bitmapData,textureMultiplier);
			else {
				textureBitmapData = instancePool.pop();
				textureBitmapData.init(bitmapData,textureMultiplier);
			}
			return textureBitmapData;
		}
		static public function putInstance(textureBitmapData:TextureBitmapData):void {
			if (textureBitmapData) {
				textureBitmapData.reset();
				instancePool[instancePool.length] = textureBitmapData;
			}
		}

		private var sourceBMD:BitmapData;
		public function TextureBitmapData(bitmapData:BitmapData,textureMultiplier:Number=1) {
			super(bitmapData,textureMultiplier);
		}
		override protected function setOriginalDimensions(iBitmapDrawable:IBitmapDrawable):void {
			sourceBMD = iBitmapDrawable as BitmapData;
			originalW = sourceBMD.width;
			originalH = sourceBMD.height;
			super.setOriginalDimensions(iBitmapDrawable);
		}
		override protected function generateBitmapData():void {
			if (bitmapData == null) {
				if (sourceBMD && texturePadding == 0 && cropW == 0 && cropH == 0 && _sourceX == 0 && _sourceY == 0 && !whiteFill) bitmapData = sourceBMD;
				else copySourceBitmapData();
			}
		}
		private function copySourceBitmapData():void {
			const w:uint = sourceW + texturePadding*2,
				  h:uint = sourceH + texturePadding*2;
			const sourceRect:Rectangle = Pool.getRectangle(_sourceX,_sourceY,sourceW,sourceH);
			const destPoint:Point = Pool.getPoint(texturePadding,texturePadding);
			bitmapData = TextureDrawable.newBitmapData(w,h);
			bitmapData.copyPixels(sourceBMD,sourceRect,destPoint);
			if (whiteFill) {
				sourceRect.x = destPoint.x;
				sourceRect.y = destPoint.y;
				TextureDrawable.applyWhiteTransform(bitmapData,sourceRect);
			}
			Pool.putRectangle(sourceRect);
			Pool.putPoint(destPoint);
		}
		override internal function copyPixelsTo(targetBMD:BitmapData):void {
			const sourceRect:Rectangle = Pool.getRectangle();
			var copyFromBMD:BitmapData;
			const targetPoint:Point = Pool.getPoint(atlasRect.x,atlasRect.y);
			var offset:uint;
			const texturePaddingX2:uint = texturePadding * 2;
			if (bitmapData) {
				copyFromBMD = bitmapData;
				sourceRect.x = sourceRect.y = texturePadding;
				sourceRect.width = copyFromBMD.width - texturePaddingX2;
				sourceRect.height = copyFromBMD.height - texturePaddingX2;
			} else {
				copyFromBMD = sourceBMD;
				sourceRect.x = sourceX;
				sourceRect.y = sourceY;
				sourceRect.width = sourceW;
				sourceRect.height = sourceH;
			}
			if (atlasPadding > 0) offset += atlasPadding;
			if (atlasExtrude) offset += 1;
			targetPoint.x += texturePadding + offset;
			targetPoint.y += texturePadding + offset;
			targetBMD.copyPixels(copyFromBMD,sourceRect,targetPoint);
			atlasRect.x += offset;
			atlasRect.y += offset;
			atlasRect.width = sourceW + texturePaddingX2;
			atlasRect.height = sourceH + texturePaddingX2;
			Pool.putRectangle(sourceRect);
			Pool.putPoint(targetPoint);
		}
		override internal function reset():void {
			sourceBMD = null;
			super.reset();
		}
		override protected function disposeBitmapData():void {
			if (bitmapData && bitmapData != sourceBMD) bitmapData.dispose();
			bitmapData = null;
		}
		override public function dispose():void {
			reset();
			super.dispose();
		}
	}

}
