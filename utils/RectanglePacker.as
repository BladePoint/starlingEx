package starlingEx.utils {

	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	import starling.events.EventDispatcher;
	import starling.utils.Pool;
	import starlingEx.utils.PoolEx;

	public class RectanglePacker extends EventDispatcher {
		static public const SUCCESS:String = "success",
			FAILURE:String = "failure";
		static private function nextLength(i:uint,max:uint):uint {
			return Math.min(Utils.nextPowerOfTwo(i),max);
		}
		static private function resetRectangleArray(rectangleArray:Array):void {
			const l:uint = rectangleArray.length;
			for (var i:uint=0; i<l; i++) {
				Pool.putRectangle(rectangleArray[i]);
			}
			rectangleArray.length = 0;
		}

		public var maxContainerLength:uint;
		protected var bounds:Rectangle;
		protected var packedA:Array, notPackedA:Array;
		private var container:Rectangle, outside:Rectangle;
		private var freeA:Array, newFreeA:Array;
		private var dictionary:Dictionary;
		public function RectanglePacker(maxContainerLengthP:uint) {
			maxContainerLength = maxContainerLengthP;
			container = Pool.getRectangle();
			outside = Pool.getRectangle();
			bounds = Pool.getRectangle();
			notPackedA = PoolEx.getArray();
			packedA = PoolEx.getArray();
			freeA = PoolEx.getArray();
			newFreeA = PoolEx.getArray();
			dictionary = new Dictionary();
		}
		public function addRectangle(rect:Rectangle):void {
			const length:uint = notPackedA.length;
			dictionary[rect] = length;
			notPackedA[length] = rect;
		}
		public function addRectangleA(rectA:Array):void {
			const l:uint = rectA.length;
			for (var i:uint=0; i<l; i++) {
				addRectangle(rectA[i]);
			}
		}
		public function addRectangles(...args):void {
			addRectangleA(args);
			args.length = 0;
		}
		public function removeRectangle(rect:Rectangle):Boolean {
			var returnResult:Boolean;
			if (dictionary[rect] != null) {
				const index:uint = dictionary[rect];
				var testRect:Rectangle;
				if (index < packedA.length) {
					testRect = packedA[index];
					if (rect == testRect) {
						packedA.splice(index,1);
						returnResult = true;
						return returnResult;
					}
				}
				if (index < notPackedA.length) {
					testRect = notPackedA[index];
					if (rect == testRect) {
						notPackedA.splice(index,1);
						returnResult = true;
					}
				}
			}
			return returnResult;
		}
		public function pack():void {
			var packResult:Boolean;
			while (packResult == false && (container.width < maxContainerLength || container.width < maxContainerLength)) {
				estimateContainer();
				packResult = packRectangles();
			}
			dispatchPackResult(packResult);
		}
		protected function dispatchPackResult(packResult:Boolean):void {
			var resultString:String;
			if (packResult) resultString = SUCCESS;
			else resultString = FAILURE;
			dispatchEventWith(resultString);
		}
		private function estimateContainer():void {
			if (container.width == 0 && container.height == 0) {
				const l:uint = notPackedA.length;
				var area:uint,
					maxW:uint,
					maxH:uint;
				var rect:Rectangle;
				for (var i:uint=0; i<l; i++) {
					rect = notPackedA[i];
					area += rect.width * rect.height;
					maxW = Math.max(maxW,rect.width);
					maxH = Math.max(maxH,rect.height);
				}
				container.width = container.height = nextLength(Math.sqrt(area),maxContainerLength);
				if (maxW > container.width) container.width = nextLength(maxW,maxContainerLength);
				if (maxH > container.height) container.height = nextLength(maxH,maxContainerLength);
				notPackedA.sortOn("height",Array.NUMERIC);
				updateDictionary(notPackedA);
			} else if (container.width <= container.height && container.width < maxContainerLength) container.width = nextLength(container.width+1,maxContainerLength);
			else if (container.height < maxContainerLength) container.height = nextLength(container.height+1,maxContainerLength);
			outside.x = container.width;
			outside.y = container.height;
			outside.width = outside.height = 0;
			bounds.width = bounds.height = 0;
		}
		private function updateDictionary(array:Array):void {
			const l:uint = array.length;
			for (var i:uint=0; i<l; i++) {
				const rectangle:Rectangle = array[i];
				dictionary[rectangle] = i;
			}
		}
		private function packRectangles():Boolean {
			var rect:Rectangle;
			var packResult:Boolean;
			while (notPackedA.length > 0) {
				rect = notPackedA[notPackedA.length-1];
				packResult = packRectangle(rect);
				if (packResult) {
					packedA[packedA.length] = rect;
					notPackedA.length -= 1;
				} else {
					reset();
					break;
				}
			}
			if (packResult) updateDictionary(packedA);
			return packResult;
		}
		private function packRectangle(rect:Rectangle):Boolean {
			const bestIndex:int = getFreeIndex(rect);
			if (bestIndex != -1) {
				const bestFree:Rectangle = freeA[bestIndex];
				rect.x = bestFree.x;
				rect.y = bestFree.y;
				newFreeRect(rect);
				while (newFreeA.length > 0) freeA[freeA.length] = newFreeA.pop();
				if (rect.right > bounds.right) bounds.width = rect.right;
				if (rect.bottom > bounds.bottom) bounds.height = rect.bottom;
				return true;
			} else return false;
		}
		private function getFreeIndex(test:Rectangle):int {
			var free:Rectangle,
				best:Rectangle = outside;
			var index:int = -1;
			const l:uint = freeA.length;
			for (var i:int=l-1; i>=0; i--) {
				free = freeA[i];
                if (test.width <= free.width && test.height <= free.height && free.x < best.x) {
					index = i;
					best = free;
				}
			}
			return index;
		}
		private function newFreeRect(rect:Rectangle):void {
			const rectX:int = rect.x,
				rectY:int = rect.y,
				rectRight:int = rectX + rect.width,
				rectRight1:int = rectX + rect.width + 1, //increase dimensions by 1 to include touching free areas
				rectBottom:int = rectY + rect.height,
				rectBottom1:int = rectY + rect.height + 1;
			var rightDelta:int, leftDelta:int, bottomDelta:int, topDelta:int;
			const l:uint = freeA.length;
			var deltaCount:uint;
			var free:Rectangle;
			for (var i:int=l-1; i>=0; i--) {
				free = freeA[i];
				if (!(rectX >= free.right || rectRight1 <= free.x || rectY >= free.bottom || rectBottom1 <= free.y)) { //if rect is not outside free
					deltaCount = 0;
					rightDelta = free.right - rectRight;
					if (rightDelta > 0) {
						newFreeA[newFreeA.length] = Pool.getRectangle(rectRight,free.y,rightDelta,free.height);
						deltaCount++;
					}
					leftDelta = rectX - free.x;
					if (leftDelta > 0) {
						newFreeA[newFreeA.length] = Pool.getRectangle(free.x,free.y,leftDelta,free.height);
						deltaCount++;
					}
					bottomDelta = free.bottom - rectBottom;
					if (bottomDelta > 0) {
						newFreeA[newFreeA.length] = Pool.getRectangle(free.x,rectBottom,free.width,bottomDelta);
						deltaCount++;
					}
					topDelta = rectY - free.y;
					if (topDelta > 0) {
						newFreeA[newFreeA.length] = Pool.getRectangle(free.x,free.y,free.width,topDelta);
						deltaCount++;
					}
					if (deltaCount == 0 && (rect.width < free.width || rect.height < free.height)) newFreeA[newFreeA.length] = free;
					else Pool.putRectangle(free);
					//replace processed element with top;
					freeA[i] = freeA[freeA.length-1];
					if (freeA.length > 0) freeA.length--;
				}
			}
			filterNew();
		}
		private function filterNew():void {
			var inside:Rectangle, outside:Rectangle;
			const l:uint = newFreeA.length;
			for (var i:int=l-1; i>=0; i--) {
				inside = newFreeA[i];
				for (var j:int=newFreeA.length-1; j>=0; j--) {
					if (i != j) {
						outside = newFreeA[j];
						if (inside.x >= outside.x && inside.y >= outside.y &&inside.right <= outside.right && inside.bottom <= outside.bottom) {
							Pool.putRectangle(inside);
							newFreeA[i] = newFreeA[newFreeA.length-1];
							if (newFreeA.length > 0) newFreeA.length--;
							break;
						}
					}
				}
			}
		}
		private function reset():void {
			while (packedA.length > 0) notPackedA[notPackedA.length] = packedA.pop();
			resetRectangleArray(freeA);
			freeA[0] = Pool.getRectangle(0,0,container.width,container.height);
		}
		protected function resetPackArrays():void {
			resetRectangleArray(notPackedA);
			resetRectangleArray(packedA);
		}
		public function dispose():void {
			Pool.putRectangle(container);
			Pool.putRectangle(outside);
			Pool.putRectangle(bounds);
			container = outside = bounds = null;
			resetPackArrays();
			resetRectangleArray(freeA);
			resetRectangleArray(newFreeA);
			PoolEx.putArray(notPackedA);
			PoolEx.putArray(packedA);
			PoolEx.putArray(freeA);
			PoolEx.putArray(newFreeA);
			notPackedA = packedA = freeA = newFreeA = null;
			for (var rect:Rectangle in dictionary) {
				delete dictionary[rect];
			}
			dictionary = null;
		}
	}
	
}
