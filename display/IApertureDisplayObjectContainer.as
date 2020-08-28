package starlingEx.display {

	import starling.display.DisplayObject;

	public interface IApertureDisplayObjectContainer {

		function getMultRGB(index:uint=0):Array;
		function addChild(child:DisplayObject):DisplayObject;

	}

}
