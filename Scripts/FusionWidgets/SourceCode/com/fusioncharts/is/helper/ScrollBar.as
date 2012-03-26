/**
* @class ScrollBar
* @author InfoSoft Global (P) Ltd. www.fusioncharts.com / www.InfoSoftGlobal.com
* @version 3.0.1
*
* Copyright (C) InfoSoft Global Pvt. Ltd.

* ScrollBar class lets you add a very low footprint scroll bar
* to any textfield.
*/
import mx.utils.Delegate;
class com.fusioncharts.is.helper.ScrollBar {
	//Private variables
	//Movie clip in which the scroll elements would be drawn
	private var scrollMC:MovieClip;
	//The text field for which this scroll bar is applicable
	private var tf:TextField;
	//Position
	private var x:Number;
	private var y:Number;
	//Width and height
	private var w:Number;
	private var h:Number;
	//Vertical Padding between the scroll bar and the buttons (above and below it)
	private var scrollVPadding:Number = 3;
	//Horizontal and vertical padding between the scroll bar and the scroll bg
	private var scrollBarHPadding:Number = 3;
	private var scrollBarVPadding:Number = 3;
	//Height of button
	private var btnHeight:Number = 10;
	//Cosmetic Properties
	private var scrollBgColor:Number;
	private var scrollBarColor:Number;
	private var btnColor:Number;
	//More co-ordinates
	private var btnCenterX:Number;
	private var upBtnEnd:Number;
	private var downBtnStart:Number;
	//Scroll background properties
	private var scrollBgX:Number;
	private var scrollBgY:Number;
	private var scrollBgW:Number;
	private var scrollBgH:Number;
	//Scroll bar properties
	private var scrollBarX:Number;
	private var scrollBarY:Number;
	private var scrollBarH:Number;
	private var scrollBarW:Number;
	private var scrollBarDragH:Number;
	//Reference to sub movie clips
	private var mcBtnUp:MovieClip;
	private var mcBtnDown:MovieClip;
	private var mcScrollBg:MovieClip;
	private var mcScrollBar:MovieClip;
	//Boolean indicating whether scroll bar would be visible
	private var showScrollBar:Boolean;
	//Text field line properties;
	private var viewLines:Number;
	private var totalLines:Number;
	//Scroll interval
	private var scrollInterval:Number;
	//Scroll speed - in Milliseconds - the lesser the faster
	private var scrollSpeed:Number = 50;
	//Flag to indicate whether it's currently scrolling using.
	private var isBarScrolling:Boolean = false;
	//Flag to indicate whether the events for scroll bar have been renderd
	private var isEventRendered:Boolean = false;
	//Last scroll positions
	private var lastScroll:Number = 1;
	private var lastScrollY:Number = 0;
	//Ratio moved - bar to bg
	private var ratioMoved:Number;
	//Listener Object
	private var scrollListener:Object;
	/**
	* Constructor function.
	* Draws the scroll bar and attaches it to the required textfield.
	* @param	t				Text field to which this scroll bar will be attached.
	* @param	targetMC		Target movie clip in which we'll draw the scroll bar
	* @param	x				Top X Position of the entire scroll bar
	* @param	y				Top Y Position of the entire scroll bar
	* @param	w				Width of the scroll bar
	* @param	h				Height of the scroll bar
	* @param	scrollBgColor	Background color for scroll bar
	* @param	scrollBarColor	Scroll bar color
	* @param	btnColor		Color of scroll button
	*/
	function ScrollBar(t:TextField, targetMC:MovieClip, x:Number, y:Number, w:Number, h:Number, scrollBgColor:String, scrollBarColor:String, btnColor:String) {
		//Store in private properties
		tf = t;
		scrollMC = targetMC;
		this.x = x;
		this.y = y;
		this.w = w;
		this.h = h;
		//Cosmetic parameters
		this.scrollBgColor = parseInt(scrollBgColor, 16);
		this.scrollBarColor = parseInt(scrollBarColor, 16);
		this.btnColor = parseInt(btnColor, 16);
		//Draw the base
		this.drawBase();
		//Draw the scroll bar too
		this.drawScrollBar();
	}
	/**
	* drawBase method draws the scroll bar background and scroll buttons
	* |-scrollMC -|
	*		  |-bg (Scroll Bar background) - Depth 1
	*		  |-bar (Drag-able bar) 	   - Depth 2
	*		  |-btnUp					   - Depth 3
	*		  |-btnDown					   - Depth 4
	*/
	private function drawBase() {
		//Create the sub movie clips
		mcScrollBg = scrollMC.createEmptyMovieClip("bg", 1);
		mcScrollBar = scrollMC.createEmptyMovieClip("bar", 2);
		mcBtnUp = scrollMC.createEmptyMovieClip("btnUp", 3);
		mcBtnDown = scrollMC.createEmptyMovieClip("btnDown", 4);
		//Calculate the co-ordinates and height,width of scroll bg and bar
		//Scroll bg properties
		scrollBgX = x;
		scrollBgY = y+btnHeight+scrollVPadding;
		scrollBgW = w;
		scrollBgH = h-((2*btnHeight)+(2*scrollVPadding));
		//Calculate the position for buttons
		btnCenterX = x+(w/2);
		upBtnEnd = y+btnHeight;
		downBtnStart = upBtnEnd+scrollBgH+(2*scrollVPadding);
		//Draw the buttons
		//Up button
		mcBtnUp.lineStyle();
		mcBtnUp.beginFill(btnColor, 100);
		mcBtnUp.moveTo(btnCenterX, y);
		mcBtnUp.lineTo(btnCenterX-(w/2), upBtnEnd);
		mcBtnUp.lineTo(btnCenterX+(w/2), upBtnEnd);
		mcBtnUp.lineTo(btnCenterX, y);
		mcBtnUp.endFill();
		//Down button
		mcBtnDown.lineStyle();
		mcBtnDown.beginFill(btnColor, 100);
		mcBtnDown.moveTo(btnCenterX-(w/2), downBtnStart);
		mcBtnDown.lineTo(btnCenterX+(w/2), downBtnStart);
		mcBtnDown.lineTo(btnCenterX, downBtnStart+btnHeight);
		mcBtnDown.lineTo(btnCenterX-(w/2), downBtnStart);
		mcBtnDown.endFill();
		//Draw the scroll bg
		mcScrollBg.moveTo(scrollBgX, scrollBgY);
		mcScrollBg.lineStyle();
		mcScrollBg.beginFill(scrollBgColor, 100);
		mcScrollBg.lineTo(scrollBgX+scrollBgW, scrollBgY);
		mcScrollBg.lineTo(scrollBgX+scrollBgW, scrollBgY+scrollBgH);
		mcScrollBg.lineTo(scrollBgX, scrollBgY+scrollBgH);
		mcScrollBg.lineTo(scrollBgX, scrollBgY);
		mcScrollBg.endFill();
		//Event handlers for the up and down buttons
		//When the up button is pressed, we delegate the handler to scrollUp method
		mcBtnUp.onPress = Delegate.create(this, scrollUp);
		mcBtnUp.onRelease = mcBtnUp.onReleaseOutside=Delegate.create(this, clearScrollInterval);
		//When the down button is pressed, we delegate the handler to scrollDown method
		mcBtnDown.onPress = Delegate.create(this, scrollDown);
		mcBtnDown.onRelease = mcBtnDown.onReleaseOutside=Delegate.create(this, clearScrollInterval);
	}
	/**
	* scrollDown function is called as a delegate function when the down button
	* is pressed. In this function, we set an interval of 50 milliseconds to scroll
	* the textbox line by line.
	*/
	private function scrollDown():Void {
		//Set interval for scrolling down
		scrollInterval = setInterval(scrollDownByOne, scrollSpeed, tf);
		//Nested function scrollDownByOne which scrolls the text field by 1 line (if required)
		function scrollDownByOne(tf:TextField) {
			if (tf.scroll<tf.maxscroll) {
				//Scroll Down by 1
				tf.scroll++;
			}
		}
	}
	/**
	* scrollUp function is called as a delegate function when the down button
	* is pressed. In this function, we set an interval of 50 milliseconds to scroll
	* the textbox line by line.
	*/
	private function scrollUp():Void {
		//Set interval for scrolling up
		scrollInterval = setInterval(scrollUpByOne, scrollSpeed, tf);
		//Nested function scrollDownByOne which scrolls the text field by 1 line (if required)
		function scrollUpByOne(tf:TextField) {
			if (tf.scroll>1) {
				//Scroll Up by 1
				tf.scroll--;
			}
		}
	}
	/**
	 * scrollToEnd method scrolls the textfield to end.
	*/
	public function scrollToEnd():Void{
		//Set the scroll to maximum point.
		tf.scroll = tf.maxscroll;
		//Invalidate 
		this.invalidate();
	}
	/**
	* clearScrollInterval is called as a delegate function when either
	* the down or up button is released. Here, we clear the interval, which
	* was invoked for scrolling.
	*/
	private function clearScrollInterval():Void {
		//Clear the interval
		clearInterval(scrollInterval);
	}
	/**
	* drawScrollBar draws the actual scroll bar.
	* We have kept two functions separate so that a user can invalidate
	* the scroll bar once something has been added to a textbox at runtime.
	* For a textfield, the following formulas apply:
	* Viewable Lines : 	(tf.bottomScroll-tf.scroll+1))
	* Total Lines : 	(tf.maxscroll+tf.bottomScroll-tf.scroll)
	*/
	public function drawScrollBar() {
		//The scroll bar would be displayed only if the content of the
		//text field exceeds the current view, and we've text to scroll. So check
		showScrollBar = (tf.maxscroll>1) ? true : false;		
		//Perform other things only if we've to show the scroll bar
		if (showScrollBar) {
			//Get the viewable lines and total lines
			viewLines = (tf.bottomScroll-tf.scroll+1);
			totalLines = (tf.maxscroll+tf.bottomScroll-tf.scroll);
			//Calculate scroll bar co-ordinates and dimensions
			scrollBarX = scrollBgX+scrollBarHPadding;
			scrollBarY = scrollBgY+scrollBarVPadding;
			scrollBarW = scrollBgW-(2*scrollBarHPadding);
			//Scroll bar height = (viewable lines / total lines) * height of scroll bg
			scrollBarH = int((viewLines/totalLines)*(scrollBgH-(2*scrollBarVPadding)));
			//Minimum height of scroll bar can be 5 pixels.
			scrollBarH = (scrollBarH<5) ? 5 : scrollBarH;
			//Drag-able height of scroll bar
			scrollBarDragH = scrollBgH-scrollBarH-(2*scrollBarVPadding);
			//Clear scroll bar first
			mcScrollBar.clear();
			//Flag to update that we've content
			mcScrollBar.content = true;
			//Draw the scroll bar			
			mcScrollBar.moveTo(scrollBarX, scrollBarY);
			mcScrollBar.lineStyle();
			mcScrollBar.beginFill(scrollBarColor, 100);
			mcScrollBar.lineTo(scrollBarX+scrollBarW, scrollBarY);
			mcScrollBar.lineTo(scrollBarX+scrollBarW, scrollBarY+scrollBarH);
			mcScrollBar.lineTo(scrollBarX, scrollBarY+scrollBarH);
			mcScrollBar.lineTo(scrollBarX, scrollBarY);
			mcScrollBar.endFill();			
			//Define events for the scroll bar, if not already defined
			if (!this.isEventRendered){
				//Define the onPress and onRelease handlers
				mcScrollBar.onPress = Delegate.create(this, scrollBarDown);
				mcScrollBar.onRelease = mcScrollBar.onReleaseOutside=Delegate.create(this, scrollBarUp);
				//Create a listener object, whose onScroller property would listen for scroll of tf
				scrollListener = new Object();
				//Delegate the onScroller event to updateScrollBar method of this class.
				scrollListener.onScroller = Delegate.create(this, updateScrollBar);
				//Add the listener to text field
				tf.addListener(scrollListener);
				//Update flag after first rendering
				this.isEventRendered = true;
			}
		}else{
			//If scroll bar is not to be shown, and it was previously rendered
			//This is when the text box gets cleared after showing scroll bar for a while.
			//Optimization: We also check if there's any content in the movie clip to avoid empty clear() calls
			if (this.isEventRendered && mcScrollBar.content==true){
				mcScrollBar.clear();
				//Update flag that we've erased content
				mcScrollBar.content = false;
			}
		}		
	}
	/**
	* invalidate method is called, whenever we want to invalidate our
	* current scroll bar and re-adjust itself to the text field.
	* Specifically, it should be called, when new text is added to the
	* attached text field from code itself.
	*/
	public function invalidate():Void {
		//Re-draw the scroll bar - rest can remain same.
		this.drawScrollBar();
	}
	/**
	* This method is invoked when the user presses the scroll bar.
	* Here, we allow the user to drag the scroll bar down.
	*/
	private function scrollBarDown():Void {
		//Update scrolling flag
		isBarScrolling = true;
		//Store the last scroll positions
		lastScroll = tf.scroll;
		lastScrollY = mcScrollBar._y;
		//Allow dragging
		mcScrollBar.startDrag(false, 0, 0, 0, scrollBgH-scrollBarH-(2*scrollBarVPadding));
		//Create the enterFrame event
		mcScrollBar.onEnterFrame = Delegate.create(this, scrollText);
	}
	/**
	* This method is invoked when the user released the scroll bar.
	* Here, we set the proper flags and stop dragging.
	*/
	private function scrollBarUp():Void {
		//Update scrolling flag
		isBarScrolling = false;
		//Stop dragging
		mcScrollBar.stopDrag();
		//Delete the enterFrame event
		delete mcScrollBar.onEnterFrame;
		//Correct precision errors
		//If the scroll bar is at 0 position, we set scroll to 0
		if (Math.floor(mcScrollBar._y) == 0) {
			tf.scroll = 1;
		}
		//If the scroll bar is at down most position, we scroll to the last line.  
		if (Math.floor(mcScrollBar._y) == scrollBarDragH) {
			tf.scroll = tf.maxscroll;
		}
	}
	/**
	* This method is invoked under onEnterFrame of the scroll bar.
	* Here, we first check if the user is dragging the scroll bar.
	* If yes, we update the scroll position of the textbox.
	*/
	private function scrollText():Void {
		//We perform the routine only if the scroll bar is pressed
		//i.e., the user is scrolling using the scroll bar
		if (isBarScrolling) {
			//Update the scroll position of the textbox
			//Find ratio moved.
			ratioMoved = (mcScrollBar._y-lastScrollY)/scrollBarDragH;
			//Scroll the textbox
			tf.scroll = lastScroll+Math.ceil(ratioMoved*(tf.maxscroll));
		}
	}
	/**
	* updateScrollBar method updates the position of the scroll bar
	* based on the scroll position of the textbox
	* This method is invoked when the onScroller event of the text field
	* is invoked.
	*/
	private function updateScrollBar() {
		//If the user is not scrolling using the bar, we update the scroll bar position
		if (!isBarScrolling) {
			//If we're not scrolling using the bar, re-set the bar position
			mcScrollBar._y = ((tf.scroll-1)/(tf.maxscroll-1))*(scrollBarDragH);
			//Correct precision errors
			//If the scroll bar is at 0 position, we set scroll to 0
			if (tf.scroll == 1) {
				mcScrollBar._y = 0;
			}
			//If the scroll bar is at down most position, we scroll to the last line.  
			if (tf.scroll == tf.maxscroll) {
				mcScrollBar._y == scrollBarDragH;
			}
		}
	}
	/**
	* destroy method MUST be called whenever you wish to delete this class's
	* instance.
	*/
	public function destroy() {
		//Remove listener.
		tf.removeListener(scrollListener);
		//Remove the movie clips
		mcScrollBg.removeMovieClip();
		mcScrollBar.removeMovieClip();
		mcBtnUp.removeMovieClip();
		mcBtnDown.removeMovieClip();
	}
}
