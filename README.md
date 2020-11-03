# StarlingEx
This package contains several extensions that expand the functionality of their base Starling classes, and some new original classes as well that I hope you will find useful. The highlights are as follows.

## ApertureSprite
An ApertureSprite is a container, much like its base Sprite class, with the additional functionality of allowing you to assign a color to it. The container itself does not display a color, but its IAperture children will automatically have their colors multiplied by the parent color, unless their apertureLock property is set to true. This is useful if you wish to tint a number of DisplayObjects at the same time to the same color, such as if you are doing a fade-to-black effect. You could also apertureLock one of the children to prevent it from darkening to produce a spotlight effect.

## ApertureQuad
In order to utilize ApertureSprite's color feature, it's children must implement IAperture. ApertureQuad extends Quad and implements IAperture, and thus can have its color changed by its parent ApertureSprite. Changing colors in this manner is very fast and efficient and does not require additional draw calls, although it is limited in that it can only reduce the color in a channel, much like how making the aperture in a camera smaller can only reduce the amount of light coming in. If you wanted to increase the color in a channel, that would require the use of a color offset filter, which would need additional draw calls. The Starling Manual has an excellent [explanation of how this works.](https://manual.starling-framework.org/en/#_the_goal)

## ApertureTextFormat
ApertureTextFormat extends TextFormat and can only be used with ApertureTextField. It adds 3 additional features.
* Set each color of the corners of the letters.
* Set the thickness and color of an outline that goes around each letter.
* Set the position, color, and alpha of a dropshadow that appears behind each letter.

## ApertureTextField
