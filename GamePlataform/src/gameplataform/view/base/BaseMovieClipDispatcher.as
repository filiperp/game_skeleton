/**
 * Created by William on 4/24/2014.
 */
package gameplataform.view.base {
import utils.events.SignalDispatcher;

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


    override public function destroy():void {
        super.destroy();
        dispatcher.removeAllSignals();
    }
}
}
