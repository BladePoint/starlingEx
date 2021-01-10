// StarlingEx - https://github.com/BladePoint/StarlingEx
// Copyright Doublehead Games, LLC. All rights reserved.
// This code is open source under the MIT License - https://github.com/BladePoint/StarlingEx/blob/master/docs/LICENSE
// Use in conjunction with Starling - https://gamua.com/starling/

package starlingEx.textures {

	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import starling.utils.Pool;
	import starlingEx.textures.TextureDrawable;

	public class TextureBitmapData extends TextureDrawable {

		private var sourceBMD:BitmapData;
		public function TextureBitmapData(bitmapData:BitmapData) {
			sourceBMD = bitmapData;
			super(sourceBMD);
		}
		override public function getBMD():BitmapData {
			var returnBMD:BitmapData;
			if (bitmapData) return returnBMD = bitmapData;
			else {
				if (sourceBMD && texturePadding == 0 && cropW == 0 && cropH == 0 && sourceOffsetX == 0 && sourceOffsetY == 0 && !whiteFill) returnBMD = sourceBMD;
				else {
					createBMD();
					returnBMD = bitmapData;
				}
			}
			return returnBMD;
		}
		public function createBMD():void {
			const bitmapW:uint = sourceW + texturePadding*2,
				  bitmapH:uint = sourceH + texturePadding*2;
			const sourceRect:Rectangle = Pool.getRectangle(sourceOffsetX,sourceOffsetY,sourceW,sourceH);
			const destPoint:Point = Pool.getPoint(texturePadding,texturePadding);
			bitmapData = TextureDrawable.newBitmapData(bitmapW,bitmapH);
			bitmapData.copyPixels(sourceBMD,sourceRect,destPoint);
			if (whiteFill) {
				sourceRect.x = sourceRect.y = destPoint.x;
				TextureDrawable.applyWhiteTransform(bitmapData,sourceRect);
			}
			Pool.putRectangle(sourceRect);
			Pool.putPoint(destPoint);
			sourceBMD = null;
		}
		override public function copyPixelsTo(targetBMD:BitmapData):void {
			const sourceRect:Rectangle = Pool.getRectangle();
			var copyFromBMD:BitmapData;
			const targetPoint:Point = Pool.getPoint(x,y);
			var offset:uint;
			const texturePaddingX2:uint = texturePadding * 2;
			if (bitmapData) {
				copyFromBMD = bitmapData;
				sourceRect.x = sourceRect.y = texturePadding;
				sourceRect.width = copyFromBMD.width - texturePaddingX2;
				sourceRect.height = copyFromBMD.height - texturePaddingX2;
			} else {
				copyFromBMD = sourceBMD;
				sourceRect.x = sourceOffsetX;
				sourceRect.y = sourceOffsetY;
				sourceRect.width = sourceW;
				sourceRect.height = sourceH;
			}
			if (atlasPadding > 0) offset += atlasPadding;
			if (atlasExtrude) offset += 1;
			targetPoint.x += texturePadding + offset;
			targetPoint.y += texturePadding + offset;
			targetBMD.copyPixels(copyFromBMD,sourceRect,targetPoint);
			x = x + offset;
			y = y + offset;
			width = sourceW + texturePaddingX2;
			height = sourceH + texturePaddingX2;
			Pool.putRectangle(sourceRect);
			Pool.putPoint(targetPoint);
		}
		override public function dispose():void {
			sourceBMD = null;
			super.dispose();
		}

	}
	
}
