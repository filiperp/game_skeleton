/**
 * Created with IntelliJ IDEA.
 * User: William
 * Date: 8/14/13
 * Time: 7:29 PM
 * To change this template use File | Settings | File Templates.
 */
package utilsDisplay.managers.buttons {

import com.greensock.TweenMax;
import com.greensock.easing.Linear;

import flash.display.DisplayObject;
import flash.display.MovieClip;
import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.utils.Dictionary;
import flash.utils.setTimeout;

public class ButtonManager {
    private static const DISABLED   :int = 0;
    private static const ENABLED    :int = 1;

    private static var _buttons:Dictionary = new Dictionary();

    public static var DEFAULT_OVER_COLOR:uint = 0xffbb00;
    public static var DEFAULT_DOWN_COLOR:uint = 0x000000;
    public static var DEFAULT_DELAY_TIME:int = 0;
    public static var DEFAULT_BUTTON_MODE:Boolean = true;

    private static const MODE_NONE :int = 0;
    private static const MODE_OVER :int = 1;
    private static const MODE_DOWN :int = 2;

    private static var focus:DisplayObject = null;

    public static function add(button:DisplayObject, parameters:Object):void {
        var p:ButtonProperty = _buttons[button];

        if(p != null) throw new Error("Already registered instance : \"" + button.name + "\".");
        if(parameters == null) parameters = {};

        p                   = new ButtonProperty();
        p.reference         = button;
        p.status            = DISABLED;
        p.mode              = MODE_NONE;

        p.priority          = parameters.priority || 0;
        p.useCapture        = (parameters.useCapture == null)? false : parameters.useCapture;
        p.useWeakReference  = (parameters.useWeakReference == null)? false : parameters.useWeakReference;

        p.useDefault    = parameters.useDefault == null ? true : parameters.useDefault;
        p.delay         = parameters.delay      || DEFAULT_DELAY_TIME   ;
        p.overColor     = parameters.overColor  || DEFAULT_OVER_COLOR   ;
        p.downColor     = parameters.downColor  || DEFAULT_DOWN_COLOR   ;
        p.buttonMode    = parameters.buttonMode || DEFAULT_BUTTON_MODE  ;

        p.onClick       = parameters.onClick    || defaultClick     ;
        p.onDown        = parameters.onDown     || defaultDown      ;
        p.onUp          = parameters.onUp       || defaultUp        ;
        p.onOver        = parameters.onOver     || defaultOver      ;
        p.onOut         = parameters.onOut      || defaultOut       ;
        p.onEnable      = parameters.onEnable   || defaultEnable    ;
        p.onDisable     = parameters.onDisable  || defaultDisable   ;

        _buttons[button] = p;

        enable(button);
    }

    public static function remove(button:DisplayObject):void {
        var p:ButtonProperty = _buttons[button];

        if(p == null) return;
        button.removeEventListener(MouseEvent.MOUSE_DOWN, onDown);
        button.removeEventListener(MouseEvent.MOUSE_UP, onUp);
        button.removeEventListener(MouseEvent.ROLL_OVER, onOver);
        button.removeEventListener(MouseEvent.ROLL_OUT, onOut);
        p.destroy();
        delete _buttons[button];
    }

    public static function change(button:DisplayObject, parameters:Object):void {
        var p:ButtonProperty = _buttons[button];
        if(p == null) return;
        if(parameters == null) return;

        p.priority          = parameters.priority || 0;
        p.useCapture        = (parameters.useCapture == null)? false : parameters.useCapture;
        p.useWeakReference  = (parameters.useWeakReference == null)? false : parameters.useWeakReference;

        p.useDefault    = parameters.useDefault == null ? p.useDefault : parameters.useDefault;
        p.delay         = parameters.delay      || p.delay     ;
        p.overColor     = parameters.overColor  || p.overColor ;
        p.downColor     = parameters.downColor  || p.downColor ;
        p.buttonMode    = parameters.buttonMode || p.buttonMode;

        p.onClick       = parameters.onClick   || p.onClick  ;
        p.onDown        = parameters.onDown    || p.onDown   ;
        p.onUp          = parameters.onUp      || p.onUp     ;
        p.onOver        = parameters.onOver    || p.onOver   ;
        p.onOut         = parameters.onOut     || p.onOut    ;
        p.onEnable      = parameters.onEnable  || p.onEnable ;
        p.onDisable     = parameters.onDisable || p.onDisable;
    }

    public static function enable(button:DisplayObject):void {
        var p:ButtonProperty = _buttons[button];

        if(p == null || p.status == ENABLED) return;

        p.status = ENABLED;

        if(p.buttonMode && (button is MovieClip || button is Sprite))
            button["buttonMode"] = true;
        button.addEventListener(MouseEvent.ROLL_OVER, onOver, p.useCapture, p.priority, p.useWeakReference);
        button.addEventListener(MouseEvent.ROLL_OUT , onOut, p.useCapture, p.priority, p.useWeakReference);
        p.callEnable();
    }

    public static function disable(button:DisplayObject):void {
        var p:ButtonProperty = _buttons[button];

        if(p == null || p.status == DISABLED) return;

        p.status = DISABLED;
        if(p.buttonMode && (button is MovieClip || button is Sprite))
            button["buttonMode"] = false;
        button.removeEventListener(MouseEvent.MOUSE_DOWN, onDown);
        button.removeEventListener(MouseEvent.MOUSE_UP  , onUp);
        button.removeEventListener(MouseEvent.ROLL_OVER , onOver);
        button.removeEventListener(MouseEvent.ROLL_OUT  , onOut);
        p.callDisable();
    }

    public static function setStatus(button:DisplayObject, enable:Boolean):void {
        if(enable)  ButtonManager.enable(button);
        else        ButtonManager.disable(button);
    }

    public static function isRegistered(button:DisplayObject):Boolean {
        return (_buttons[button] != null && _buttons[button] != undefined);
    }

    public static function isEnabled(button:DisplayObject):Boolean {
        return (isRegistered(button)) ? ButtonProperty(_buttons[button]).status == ENABLED : false;
    }

    public static function get currentFocus():DisplayObject { return focus; }

    /** Mouse Events **/
    private static function onDown(e:MouseEvent):void {
        var button:DisplayObject = e.currentTarget as DisplayObject;
        button.removeEventListener(MouseEvent.MOUSE_DOWN, onDown);
        var p:ButtonProperty = _buttons[button];
        if(p == null) return;
        button.addEventListener(MouseEvent.MOUSE_UP, onUp, p.useCapture, p.priority, p.useWeakReference);
        p.mode = MODE_DOWN;
        p.callDown();
    }

    private static function onUp(e:MouseEvent):void {
        var button:DisplayObject = e.currentTarget as DisplayObject;
        button.removeEventListener(MouseEvent.MOUSE_UP, onUp);
        var p:ButtonProperty = _buttons[button];
        if(p == null)       return;
        if(p.delay > 0) {
            disableOnClick(button);
            setTimeout(enableOnClick, p.delay, button);
        } else {
            button.addEventListener(MouseEvent.MOUSE_DOWN, onDown, p.useCapture, p.priority, p.useWeakReference);
        }
        p.callUp();
        p.callClick();
    }

    private static function onOver(e:MouseEvent):void {
        var button:DisplayObject = e.currentTarget as DisplayObject;
        var p:ButtonProperty = _buttons[button];
        if(p == null) return;
        button.addEventListener(MouseEvent.MOUSE_DOWN, onDown, p.useCapture, p.priority, p.useWeakReference);
        focus = button;
        p.mode = MODE_OVER;
        p.callOver();
    }

    private static function onOut(e:MouseEvent):void {
        var button:DisplayObject = e.currentTarget as DisplayObject;
        button.removeEventListener(MouseEvent.MOUSE_DOWN, onDown);
        button.removeEventListener(MouseEvent.MOUSE_UP  , onUp);
        focus = null;
        var p:ButtonProperty = _buttons[button];
        if(p == null) return;
        if(p.mode == MODE_DOWN)  //still holding mouse down
            p.callUp();
        p.mode = MODE_NONE;
        p.callOut();
    }

    private static function enableOnClick(button:DisplayObject):void {
        var p:ButtonProperty = _buttons[button];
        if(p == null || p.status != ENABLED) return;
        button.addEventListener(MouseEvent.ROLL_OVER, onOver, p.useCapture, p.priority, p.useWeakReference);
        button.addEventListener(MouseEvent.MOUSE_UP, onUp, p.useCapture, p.priority, p.useWeakReference);
        p.callEnable();
    }

    private static function disableOnClick(button:DisplayObject):void {
        var p:ButtonProperty = _buttons[button];
        if(p == null) return;
        button.removeEventListener(MouseEvent.ROLL_OVER, onOver);
        button.removeEventListener(MouseEvent.MOUSE_UP, onUp);
        p.callDisable();
    }



    /** Default Effects **/
    private static function defaultClick(button:DisplayObject):void {
        //do nothing
    }
    private static function defaultDown(button:DisplayObject):void {
        var p:ButtonProperty = _buttons[button];
        if(p.useDefault)
            TweenMax.to(p.reference, 0.3, {colorMatrixFilter: {colorize: p.downColor, amount: 0.3, saturation: 1}});
    }
    private static function defaultUp(button:DisplayObject):void {
        var p:ButtonProperty = _buttons[button];
        if(p.useDefault)
            TweenMax.to(p.reference, 0.3, {colorMatrixFilter: {remove: true}});
    }
    private static function defaultOver(button:DisplayObject):void {
        var p:ButtonProperty = _buttons[button];
        if(p.useDefault)
            TweenMax.to(p.reference, 0.3, {glowFilter: {color: p.overColor, alpha: 1, blurX: 5, blurY: 5, strength: 3, ease: Linear.easeInOut}});
    }
    private static function defaultOut(button:DisplayObject):void {
        var p:ButtonProperty = _buttons[button];
        if(p.useDefault)
            TweenMax.to(p.reference, 0.1, {glowFilter: {remove: true}});
    }
    private static function defaultEnable(button:DisplayObject):void {
        var p:ButtonProperty = _buttons[button];
        if(p.useDefault)
            TweenMax.to(p.reference, 0.3, {colorMatrixFilter: {colorize: 0x000000, amount: 0, saturation: 1, remove: true}});
    }
    private static function defaultDisable(button:DisplayObject):void {
        var p:ButtonProperty = _buttons[button];
        if(p.useDefault)
            TweenMax.to(p.reference, 0.3, {colorMatrixFilter: {colorize: 0x000000, amount: 0.5, saturation: 0}});
    }
}
}