/**
 * Created with IntelliJ IDEA.
 * User: William
 * Date: 8/14/13
 * Time: 7:29 PM
 * To change this template use File | Settings | File Templates.
 */
package utilsDisplay.managers {

import flash.events.EventDispatcher;
import flash.events.MouseEvent;
import flash.utils.Dictionary;
import flash.utils.setTimeout;

public class ButtonManager {

    private static const STATUS_DISABLED:uint = 0;
    private static const STATUS_ENABLED :uint = 1;
    private static const STATUS_DELAY   :uint = 2;

    public static var DEFAULT_DELAY_TIME:uint = 0;
    public static var DEFAULT_BUTTON_MODE:Boolean = true;

    private static const MODE_UP    :uint = 0;
    private static const MODE_DOWN  :uint = 1;

    private static const PROPERTY_BUTTON_MODE:String = "buttonMode";

    private static var _buttons:Dictionary = new Dictionary();
    private static var _focus:EventDispatcher = null;

    /**
     * Adds a button to be managed via flash's MouseEvent.
     * @param button The target
     * @param parameters  priority:int(0),
     *     useCapture       :Boolean(false),
     *     useWeakReference :Boolean(false),
     *     delay            :Number(0),
     *     buttonMode       :uint(0000000),
     *     onClick          :Function(null),
     *     onDown           :Function(null),
     *     onUp             :Function(null),
     *     onOver           :Function(null),
     *     onOut            :Function(null),
     *     onEnable         :Function(null),
     *     onDisable        :Function(null),
     *     onRemove         :Function(null),
     *     enable           :Boolean(true)
     */
    public static function add(button:EventDispatcher, parameters:Object):void {
        var p:ButtonProperty = _buttons[button];

        parameters ||= {};

        if(p != null) {
            change(button, parameters);
            return;
        }

        p                   = new ButtonProperty();
        p.reference         = button;
        p.mode              = MODE_UP;

        p.priority          = parameters.priority || 0;
        p.useCapture        = (parameters.useCapture == null)? false : parameters.useCapture;
        p.useWeakReference  = (parameters.useWeakReference == null)? false : parameters.useWeakReference;

        p.delay             = parameters.delay != int.MIN_VALUE? parameters.delay : DEFAULT_DELAY_TIME;
        p.buttonMode        = parameters.buttonMode || DEFAULT_BUTTON_MODE  ;

        p.onClick           = parameters.onClick    ;
        p.onDown            = parameters.onDown     ;
        p.onUp              = parameters.onUp       ;
        p.onOver            = parameters.onOver     ;
        p.onOut             = parameters.onOut      ;
        p.onEnable          = parameters.onEnable   ;
        p.onDisable         = parameters.onDisable  ;
        p.onRemove          = parameters.onRemove   ;

        _buttons[button] = p;

        button.addEventListener(MouseEvent.ROLL_OVER    , onOver, p.useCapture, p.priority, p.useWeakReference);
        button.addEventListener(MouseEvent.ROLL_OUT     , onOut , p.useCapture, p.priority, p.useWeakReference);
        button.addEventListener(MouseEvent.MOUSE_DOWN   , onDown, p.useCapture, p.priority, p.useWeakReference);
        button.addEventListener(MouseEvent.MOUSE_UP     , onUp  , p.useCapture, p.priority, p.useWeakReference);

        if(p.buttonMode && button.hasOwnProperty(PROPERTY_BUTTON_MODE))
            button[PROPERTY_BUTTON_MODE] = true;

        if(parameters.enable == null || parameters.enable == true) {
            p.status = STATUS_DISABLED;
            enable(button);
        } else {
            p.status = STATUS_ENABLED;
            disable(button);
        }
    }

    public static function remove(button:EventDispatcher):void {
        var p:ButtonProperty = _buttons[button];

        if(p == null || button == null) return;
        button.removeEventListener(MouseEvent.MOUSE_DOWN, onDown);
        button.removeEventListener(MouseEvent.MOUSE_UP  , onUp);
        button.removeEventListener(MouseEvent.ROLL_OVER , onOver);
        button.removeEventListener(MouseEvent.ROLL_OUT  , onOut);
        p.callRemove();
        p.destroy();
        delete _buttons[button];
    }

    public static function change(button:EventDispatcher, parameters:Object):void {
        var p:ButtonProperty = _buttons[button];
        if(p == null || parameters == null)
            return;

        p.priority          = parameters.priority || 0;
        p.useCapture        = (parameters.useCapture == null)? false : parameters.useCapture;
        p.useWeakReference  = (parameters.useWeakReference == null)? false : parameters.useWeakReference;

        p.delay         = parameters.delay      || p.delay     ;
        p.overColor     = parameters.overColor  || p.overColor ;
        p.downColor     = parameters.downColor  || p.downColor ;
        p.buttonMode    = parameters.buttonMode || p.buttonMode;

        p.onClick       = parameters.onClick   || p.onClick     ;
        p.onDown        = parameters.onDown    || p.onDown      ;
        p.onUp          = parameters.onUp      || p.onUp        ;
        p.onOver        = parameters.onOver    || p.onOver      ;
        p.onOut         = parameters.onOut     || p.onOut       ;
        p.onEnable      = parameters.onEnable  || p.onEnable    ;
        p.onDisable     = parameters.onDisable || p.onDisable   ;
        p.onRemove      = parameters.onRemove  || p.onRemove    ;

        if(p.buttonMode && button.hasOwnProperty(PROPERTY_BUTTON_MODE))
            button[PROPERTY_BUTTON_MODE] = true;
    }

    public static function enable(button:EventDispatcher):void {
        var p:ButtonProperty = _buttons[button];

        if(p == null || p.status == STATUS_ENABLED || p.status == STATUS_DELAY)
            return;

        p.status = STATUS_ENABLED;

        if(_focus == button) {
            p.callOver();
        } else {
            p.callEnable();
        }
    }

    public static function disable(button:EventDispatcher):void {
        var p:ButtonProperty = _buttons[button];

        if(p == null || p.status == STATUS_DISABLED)
            return;

        p.status = STATUS_DISABLED;
        p.callDisable();
    }

    public static function setStatus(button:EventDispatcher, enable:Boolean):void {
        if(enable)  ButtonManager.enable(button);
        else        ButtonManager.disable(button);
    }

    public static function isRegistered(button:EventDispatcher):Boolean {
        return (button in _buttons);
    }

    public static function isEnabled(button:EventDispatcher):Boolean {
        return isRegistered(button) ? ButtonProperty(_buttons[button]).status == STATUS_ENABLED : false;
    }

    public static function get currentFocus():EventDispatcher { return _focus; }

    //==================================
    //  Events
    //==================================
    private static function onDown(e:MouseEvent):void {
        var button:EventDispatcher = e.currentTarget as EventDispatcher;
        var p:ButtonProperty = _buttons[button];
        if(p == null)
            throw new Error("Un-disposed button: \"" + button.toString() + "\".");
        if(p.status == STATUS_ENABLED) {
            p.mode = MODE_DOWN;
            p.callDown();
        }
    }

    private static function onUp(e:MouseEvent):void {
        var button:EventDispatcher = e.currentTarget as EventDispatcher;
        var p:ButtonProperty = _buttons[button];
        if(p == null)
            throw new Error("Un-disposed button: \"" + button.toString() + "\".");
        if(p.delay > 0) {
            disableOnClick(button);
            setTimeout(enableOnClick, p.delay, button);
        } else {

        }
        if(p.status == STATUS_ENABLED && p.mode == MODE_DOWN) {
            p.mode = MODE_UP;
            p.callUp();
            p.callClick();
        }
    }

    private static function onOver(e:MouseEvent):void {
        var button:EventDispatcher = e.currentTarget as EventDispatcher;
        var p:ButtonProperty = _buttons[button];
        if(p == null)
            throw new Error("Un-disposed button: \"" + button.toString() + "\".");
        _focus = button;
        if(p.status == STATUS_ENABLED) {
            p.callOver();
        }
    }

    private static function onOut(e:MouseEvent):void {
        var button:EventDispatcher = e.currentTarget as EventDispatcher;
        _focus = null;
        var p:ButtonProperty = _buttons[button];
        if(p == null)
            throw new Error("Un-disposed button: \"" + button.toString() + "\".");
        if(p.status == STATUS_ENABLED) {
            if(p.mode == MODE_DOWN)  //still holding mouse down
                p.callUp();
            p.mode = MODE_UP;
            p.callOut();
        }
    }

    private static function enableOnClick(button:EventDispatcher):void {
        var p:ButtonProperty = _buttons[button];
        //if it was disabled while in delay, do not enable
        if(p == null || p.status == STATUS_DISABLED) return;
        p.status = STATUS_ENABLED;
        p.callEnable();
    }

    private static function disableOnClick(button:EventDispatcher):void {
        var p:ButtonProperty = _buttons[button];
        if(p == null) return;
        p.status = STATUS_DELAY;
        p.callDisable();
    }
}
}

class ButtonProperty {

    public var reference:Object = null;

    public var status           :int    = int.MIN_VALUE;
    public var mode             :int    = int.MIN_VALUE;
    public var delay            :Number = int.MIN_VALUE;
    public var buttonMode       :Boolean = true;
    public var overColor        :uint   = 0x000000;
    public var downColor        :uint   = 0x000000;
    public var priority         :uint = 0;
    public var useCapture       :Boolean = false;
    public var useWeakReference :Boolean = false;

    public var onClick    :Function = null;
    public var onDown     :Function = null;
    public var onUp       :Function = null;
    public var onOver     :Function = null;
    public var onOut      :Function = null;
    public var onEnable   :Function = null;
    public var onDisable  :Function = null;
    public var onRemove   :Function = null;

    public function callClick  ():void { if(onClick   != null) onClick  .call(this, reference); }
    public function callDown   ():void { if(onDown    != null) onDown   .call(this, reference); }
    public function callUp     ():void { if(onUp      != null) onUp     .call(this, reference); }
    public function callOver   ():void { if(onOver    != null) onOver   .call(this, reference); }
    public function callOut    ():void { if(onOut     != null) onOut    .call(this, reference); }
    public function callEnable ():void { if(onEnable  != null) onEnable .call(this, reference); }
    public function callDisable():void { if(onDisable != null) onDisable.call(this, reference); }
    public function callRemove ():void { if(onRemove  != null) onRemove .call(this, reference); }

    public function destroy():void {
        this.onClick   = null;
        this.onDown    = null;
        this.onUp      = null;
        this.onOver    = null;
        this.onOut     = null;
        this.onEnable  = null;
        this.onDisable = null;
        this.onRemove  = null;
    }
}
