/**
 * Created with IntelliJ IDEA.
 * User: William
 * Date: 9/3/13
 * Time: 3:04 PM
 * To change this template use File | Settings | File Templates.
 */
package gameplataform.controller.data {
import flash.display.Stage;
import flash.geom.Rectangle;
import flash.text.StyleSheet;

import gameplataform.model.*;

/**
 * This class contains any kind of data that needs to be accessed from any point in the game
 */
public class GameData {

    private static var _stage           :Stage;

    public static var variables         :Variables;
    public static var styleSheet        :StyleSheet;

    public static function get stage():Stage            { return _stage; }
    public static function set stage(value:Stage):void  { _stage = value; }

    public static function get stageWidth   ():Number { return _stage.stageWidth; }
    public static function get stageHeight  ():Number { return _stage.stageHeight; }
    public static function get stageRect    ():Rectangle { return new Rectangle(0,0,_stage.stageWidth, _stage.stageHeight); }

}
}