/**
 * Created by William on 4/24/2014.
 */
package game.view.base {
import utils.event.SignalDispatcher;

import utilsDisplay.base.BaseMovieClip;

public class BaseMovieClipDispatcher extends BaseMovieClip {

    protected var dispatcher:SignalDispatcher;

    public function BaseMovieClipDispatcher() {
        super();
        this.dispatcher = new SignalDispatcher(this);
    }

    public function addSignalListener(signal:String, listener:Function):void {
        dispatcher.addSignalListener(signal, listener);
    }

    public function addOnceSignalListener(signal:String, listener:Function):void {
        dispatcher.addSignalListenerOnce(signal, listener);
    }

    public function removeSignalListener(signal:String, listener:Function):void {
        dispatcher.removeSignalListener(signal, listener);
    }

    public function removeAll():void {
        dispatcher.removeAllSignals();
    }

    public function dispatchSignal(signal:String, data:* = null):void {
        dispatcher.dispatchSignalWith(signal, data);
    }

    override public function destroy():void {
        dispatcher.removeAllSignals();
        super.destroy();
    }
}
}
