package starlingEx.utils {

	import flash.geom.Rectangle;
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;
	import starling.events.EventDispatcher;
	import starling.utils.MathUtil;
	import starling.utils.Pool;
	import starlingEx.events.EventEx;
	import starlingEx.utils.PoolEx;
	import starlingEx.utils.Utils;

	public class RectanglePacker extends EventDispatcher {
		static private function nextLength(i:uint,max:uint):uint {
			return MathUtil.min(Utils.nextPowerOfTwo(i),max);
		}

		protected var _maxContainerLength:uint;
		protected var bounds:Rectangle, container:Rectangle;
		protected var notPackedA:Array, packedA:Array, morePackedA:Array;
		protected var dictionary:Dictionary;
		private var outsideContainer:Rectangle;
		private var freeA:Array;
		public function RectanglePacker(maxContainerLength:uint) {
			container = Pool.getRectangle();
			outsideContainer = Pool.getRectangle();
			bounds = Pool.getRectangle();
			notPackedA = PoolEx.getArray();
			packedA = PoolEx.getArray();
			freeA = PoolEx.getArray();
			dictionary = new Dictionary();
			setMaxContainerLength(maxContainerLength);
		}
		protected function setMaxContainerLength(maxContainerLength:uint):void {
			_maxContainerLength = maxContainerLength;
		}
		public function addRectangle(rect:Rectangle):void {
			const length:uint = notPackedA.length;
			dictionary[rect] = length;
			notPackedA[length] = rect;
		}
		public function addRectangles(...args):void {
			addRectangleA(args);
			args.length = 0;
		}
		public function addRectangleA(rectA:Array):void {
			const l:uint = rectA.length;
			for (var i:uint=0; i<l; i++) {
				addRectangle(rectA[i]);
			}
		}
		public function remove(removeObject:Object):Boolean {
			var returnResult:Boolean;
			if (dictionary[removeObject] != null) {
				const index:uint = dictionary[removeObject];
				var testObject:Rectangle;
				if (index < packedA.length) {
					testObject = packedA[index];
					if (testObject == removeObject) {
						returnResult = true;
						freeA[freeA.length] = getRectFromArray(packedA,index);
						filterFreeRectangles(freeA);
						packedA.splice(index,1);
						return returnResult;
					}
				}
				if (morePackedA && index < morePackedA.length) {
					testObject = morePackedA[index];
					if (testObject == removeObject) {
						returnResult = true;
						freeA[freeA.length] = getRectFromArray(morePackedA,index);
						filterFreeRectangles(freeA);
						morePackedA.splice(index,1);
						return returnResult;
					}
				}
				if (index < notPackedA.length) {
					testObject = notPackedA[index];
					if (testObject == removeObject) {
						returnResult = true;
						notPackedA.splice(index,1);
						return returnResult;
					}
				}
			}
			return returnResult;
		}
		public function removeRectangle(rect:Rectangle):Boolean {
			var returnResult:Boolean;
			if (dictionary[rect] != null) {
				const index:uint = dictionary[rect];
				var testRectangle:Rectangle;
				if (index < packedA.length) {
					testRectangle = packedA[index];
					if (rect == testRectangle) {
						packedA.splice(index,1);
						returnResult = true;
						return returnResult;
					}
				}
				if (morePackedA && index < morePackedA.length) {
					testRectangle = morePackedA[index];
					if (rect == testRectangle) {
						morePackedA.splice(index,1);
						returnResult = true;
						return returnResult;
					}
				}
				if (index < notPackedA.length) {
					testRectangle = notPackedA[index];
					if (rect == testRectangle) {
						notPackedA.splice(index,1);
						returnResult = true;
						return returnResult;
					}
				}
			}
			return returnResult;
		}
		public function pack():void {
			estimateContainer();
			var packResult:Boolean = notPackedToPacked();
			while (packResult == false && (container.width < _maxContainerLength || container.height < _maxContainerLength)) {
				estimateContainer();
				packResult = notPackedToPacked();
			}
			dispatchPackResult(packResult);
		}
		private function estimateContainer():void {
			if (container.width == 0 && container.height == 0) {
				const vector3D:Vector3D = Pool.getPoint3D(); //x = largest width, y = largest height, z = total area
				calcNotPacked(vector3D);
				container.width = container.height = nextLength(Math.sqrt(vector3D.z),_maxContainerLength);
				if (vector3D.x > container.width) container.width = nextLength(vector3D.x,_maxContainerLength);
				if (vector3D.y > container.height) container.height = nextLength(vector3D.y,_maxContainerLength);
				Pool.putPoint3D(vector3D);
				outsideContainer.x = container.width;
				outsideContainer.y = container.height;
				sortNotPacked();
				updateDictionary(notPackedA);
			} else if (container.width <= container.height && container.width < _maxContainerLength) {
				container.width = nextLength(container.width+1,_maxContainerLength);
				outsideContainer.x = container.width;
			} else if (container.height < _maxContainerLength) {
				container.height = nextLength(container.height+1,_maxContainerLength);
				outsideContainer.y = container.height;
			}
			freeA[0] = Pool.getRectangle(0,0,container.width,container.height);
		}
		protected function calcNotPacked(vector3D:Vector3D):void {
			const l:uint = notPackedA.length;
			for (var i:uint=0; i<l; i++) {
				const rect:Rectangle = notPackedA[i];
				vector3D.z += rect.width * rect.height;
				vector3D.x = MathUtil.max(vector3D.x,rect.width);
				vector3D.y = MathUtil.max(vector3D.y,rect.height);
			}
		}
		protected function sortNotPacked():void {
			notPackedA.sortOn("height",Array.NUMERIC);
		}
		public function get containerW():uint {return container.width;}
		public function get containerH():uint {return container.height;}
		public function get numberPacked():uint {return packedA.length;}
		protected function updateDictionary(array:Array):void {
			const l:uint = array.length;
			for (var i:uint=0; i<l; i++) {
				const rectangle:Rectangle = array[i];
				dictionary[rectangle] = i;
			}
		}
		protected function notPackedToPacked():Boolean {
			var packRectanglesResult:Boolean;
			bounds.width = bounds.height = 0;
			while (notPackedA.length > 0) {
				const rect:Rectangle = getRectFromArray(notPackedA,notPackedA.length-1);
				if (packRectangle(rect)) {
					packRectanglesResult = true;
					packedA[packedA.length] = notPackedA[notPackedA.length-1];
					notPackedA.length -= 1;
				} else {
					packRectanglesResult = false;
					resetFailedPack(packedA);
					break;
				}
			}
			if (packRectanglesResult) updateDictionary(packedA);
			return packRectanglesResult;
		}
		protected function getRectFromArray(array:Array,index:uint):Rectangle {
			return array[index];
		}
		protected function packRectangle(rect:Rectangle):Boolean {
			const bestIndex:int = getFreeIndex(rect);
			if (bestIndex != -1) {
				const bestFree:Rectangle = freeA[bestIndex];
				rect.x = bestFree.x;
				rect.y = bestFree.y;
				newFreeRect(rect);
				if (rect.right > bounds.right) bounds.width = rect.right;
				if (rect.bottom > bounds.bottom) bounds.height = rect.bottom;
				return true;
			} else return false;
		}
		private function getFreeIndex(test:Rectangle):int {
			var free:Rectangle,
				best:Rectangle = outsideContainer;
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
			const newFreeA:Array = PoolEx.getArray();
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
			filterFreeRectangles(newFreeA);
			while (newFreeA.length > 0) freeA[freeA.length] = newFreeA.pop();
			PoolEx.putArray(newFreeA);
		}
		private function filterFreeRectangles(array:Array):void {
			var inside:Rectangle, outside:Rectangle;
			const l:uint = array.length;
			for (var i:int=l-1; i>=0; i--) {
				inside = array[i];
				for (var j:int=array.length-1; j>=0; j--) {
					if (i != j) {
						outside = array[j];
						if (inside.x >= outside.x && inside.y >= outside.y &&inside.right <= outside.right && inside.bottom <= outside.bottom) {
							Pool.putRectangle(inside);
							array[i] = array[array.length-1];
							if (array.length > 0) array.length--;
							break;
						}
					}
				}
			}
		}
		protected function resetFailedPack(removeFromA:Array):void {
			while (removeFromA.length > 0) notPackedA[notPackedA.length] = removeFromA.pop();
			resetRectangleArray(freeA);
		}
		private function resetRectangleArray(rectangleArray:Array):void {
			const l:uint = rectangleArray.length;
			for (var i:uint=0; i<l; i++) {
				Pool.putRectangle(rectangleArray[i]);
			}
			rectangleArray.length = 0;
		}
		protected function dispatchPackResult(packResult:Boolean):void {
			dispatch(packResult);
		}
		private function dispatch(packResult:Boolean):void {
			var resultString:String;
			if (packResult) resultString = EventEx.SUCCESS;
			else resultString = EventEx.FAILURE;
			dispatchEventWith(resultString,false,this);
		}
		public function packMore():void {
			if (morePackedA == null) morePackedA = PoolEx.getArray();
			var packMoreResult:Boolean = notPackedToMorePacked(),
				resizedContainer:Boolean;
			while (packMoreResult == false && (container.width < _maxContainerLength || container.height < _maxContainerLength)) {
				reestimateContainer();
				packMoreResult = notPackedToMorePacked();
				if (packMoreResult) resizedContainer = true;
			}
			dispatchPackMoreResult(packMoreResult,resizedContainer);
		}
		private function reestimateContainer():void {
			estimateContainer();
			var l:uint = packedA.length;
			for (var i:uint=0; i<l; i++) {
				const rect:Rectangle = getRectFromArray(packedA,i);
				newFreeRect(rect);
			}
		}
		protected function dispatchPackMoreResult(packMoreResult:Boolean,resizedContainer:Boolean):void {
			dispatch(packMoreResult);
		}
		private function notPackedToMorePacked():Boolean {
			var packRectanglesResult:Boolean;
			while (notPackedA.length > 0) {
				const rect:Rectangle = getRectFromArray(notPackedA,notPackedA.length-1);
				if (packRectangle(rect)) {
					packRectanglesResult = true;
					morePackedA[morePackedA.length] = notPackedA[notPackedA.length-1];
					notPackedA.length -= 1;
				} else {
					packRectanglesResult = false;
					resetFailedPack(morePackedA);
					break;
				}
			}
			if (packRectanglesResult) updateDictionary(morePackedA);
			return packRectanglesResult;
		}
		public function morePackedToPacked():void {
			while (morePackedA.length > 0) packedA[packedA.length] = morePackedA.pop();
		}
		public function repack():void {
			
		}
		public function get maxContainerLength():uint {
			return _maxContainerLength;
		}
		public function reset():void {
			bounds.width = bounds.height = container.width = container.height = 0;
			resetPackArrays();
			resetRectangleArray(freeA);
			resetDictionary();
		}
		protected function resetPackArrays():void {
			resetRectangleArray(notPackedA);
			resetRectangleArray(packedA);
			resetRectangleArray(morePackedA);
		}
		public function resetDictionary():void {
			for (var rect:Rectangle in dictionary) {delete dictionary[rect];}
		}
		public function dispose():void {
			reset();
			Pool.putRectangle(bounds);
			Pool.putRectangle(container);
			Pool.putRectangle(outsideContainer);
			bounds = container = outsideContainer = null;
			PoolEx.putArray(notPackedA);
			PoolEx.putArray(packedA);
			PoolEx.putArray(morePackedA);
			PoolEx.putArray(freeA);
			notPackedA = packedA = morePackedA = freeA = null;
			dictionary = null;
		}
	}

}
