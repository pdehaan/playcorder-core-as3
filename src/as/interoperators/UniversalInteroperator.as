package interoperators
{
    import flash.external.ExternalInterface;

    import interoperators.Factory;
    import connectors.IConnectable;
    import Playcorder;
    import events.RecorderEvent;
    import events.RecorderErrorEvent;
    import events.RecorderChangeEvent;
    import events.PlayerEvent;
    import tickets.Ticket;
    import tickets.GUIDTicket;

    import com.demonsters.debugger.MonsterDebugger;
    import com.codecatalyst.promise.Deferred;
    import com.codecatalyst.promise.Promise;

    public class UniversalInteroperator extends Interoperator
    {
        private static var instanceCount:Number = 0;
        public static const MEMBER_NAME:Object = {
            RECORDER_ONCONNECTED    : 'recorder_onconnected',
            RECORDER_ONDISCONNECTED : 'recorder_ondisconnected',
            RECORDER_ONSTARTED      : 'recorder_onstarted',
            RECORDER_ONSTOPPED      : 'recorder_onstopped',
            RECORDER_ONERROR        : 'recorder_onerror',
            RECORDER_ONCHANGE       : 'recorder_onchange',
            RECORDER_CONNECT        : 'recorder_connect',
            RECORDER_DISCONNECT     : 'recorder_disconnect',
            RECORDER_START          : 'recorder_start',
            RECORDER_STOP           : 'recorder_stop',
            RECORDER_ACTIVITY       : 'recorder_activity',
            RECORDER_MUTED          : 'recorder_muted',
            RECORDER_INITIALIZE     : 'recorder_initialize',
            PLAYER_ONSTARTED        : 'player_onstarted',
            PLAYER_ONSTOPPED        : 'player_onstopped',
            PLAYER_START            : 'player_start',
            PLAYER_STOP             : 'player_stop',
            PLAYER_INITIALIZE       : 'player_initialize',
            ONREADY                 : 'onready',
            GETID                   : 'getID',
            PREPARE                 : 'prepare'
        };

        private var _inited:Boolean = false;
        private var _findSelf:String;
        protected var _count:Number = 0;

        private function secure(func:Function):Function
        {
            var me:Interoperator = this;
            return function():*
            {
                if ( disabled ) 
                {
                    return;
                }

                return func.apply(me, arguments);
            }
        }

        private function onRecorderConnected(event:RecorderEvent):void
        {
            callSelf(MEMBER_NAME.RECORDER_ONCONNECTED, 
            {
                'guid': event.guid.toString()
            })
        }

        private function onRecorderDisconnected(event:RecorderEvent):void
        {
            callSelf(MEMBER_NAME.RECORDER_ONDISCONNECTED, 
            {
                'guid': event.guid.toString()
            })
        }

        private function onRecorderStarted(event:RecorderEvent):void
        {
            callSelf(MEMBER_NAME.RECORDER_ONSTARTED, 
            {
                'guid': event.guid.toString()
            })
        }

        private function onRecorderStopped(event:RecorderEvent):void
        {
            callSelf(MEMBER_NAME.RECORDER_ONSTOPPED, 
            {
                'guid': event.guid.toString()
            })
        }

        private function onRecorderError(event:RecorderErrorEvent):void
        {
            callSelf(MEMBER_NAME.RECORDER_ONERROR,
            {
                'guid': event.guid ? event.guid.toString():'',
                'code': event.code
            })
        }

        private function onRecorderChange(event:RecorderChangeEvent):void
        {
            callSelf(MEMBER_NAME.RECORDER_ONCHANGE,
            {
                'code': event.code
            })
        }

        private function onPlayerStarted(event:PlayerEvent):void
        {
            callSelf(MEMBER_NAME.PLAYER_ONSTARTED, 
            {
            })
        }

        private function onPlayerStopped(event:PlayerEvent):void
        {
            callSelf(MEMBER_NAME.PLAYER_ONSTOPPED, 
            {
            })
        }

        protected function callSelf(methodName:String, ... args:*):void
        {
            if ( disabled )
            {
                return;
            }
            
            ExternalInterface.call.apply
            (
                ExternalInterface, 
                [ _findSelf , methodName ].concat(args)
            );
        }  

        // override the init method, setup callbacks and expose member methods
        protected override function init():Promise
        {
            var dfd:Deferred = new Deferred();

            if (_inited || !ExternalInterface.available)
            {
                dfd.resolve( null );
                return dfd.promise;
            }

            ExternalInterface.addCallback(MEMBER_NAME.PLAYER_START, function(path:String):void
            {
                MonsterDebugger.trace(this, 'external calls to player.start()');

                playcorder.player.start( path );
            });

            ExternalInterface.addCallback(MEMBER_NAME.PLAYER_STOP, function():void
            {
                MonsterDebugger.trace(this, 'external calls to player.stop()');

                playcorder.player.stop();
            });

            ExternalInterface.addCallback(MEMBER_NAME.RECORDER_START, function():String
            {
                var ret:String = '';

                MonsterDebugger.trace(this, 'external calls to recorder.start()');

                var ticket:Ticket = playcorder.recorder.start();

                if (ticket is GUIDTicket)
                {
                    ret = GUIDTicket(ticket).guid.toString();
                }

                return ret;
            });

            ExternalInterface.addCallback(MEMBER_NAME.RECORDER_STOP, function():void
            {
                
                MonsterDebugger.trace(this, 'external calls to recorder.stop()');

                playcorder.recorder.stop();
            });

            ExternalInterface.addCallback(MEMBER_NAME.RECORDER_ACTIVITY, function():Number
            {

                var ret:Number = 0;

                if (playcorder.recorder && playcorder.recorder.microphone){
                    ret = playcorder.recorder.microphone.activityLevel;
                }

                return ret;
            });

            ExternalInterface.addCallback(MEMBER_NAME.RECORDER_MUTED, function():Boolean
            {
                var ret:Boolean = true;

                MonsterDebugger.trace(this, 'external calls to recorder.muted()');

                if (playcorder.recorder && playcorder.recorder.microphone){
                    ret = playcorder.recorder.microphone.muted;
                }

                return ret;
            });

            ExternalInterface.addCallback(MEMBER_NAME.RECORDER_CONNECT, function():String
            {
                var ret:String = '';

                if (playcorder.recorder is IConnectable)
                {
                    var connectable:IConnectable = IConnectable(playcorder.recorder);

                    MonsterDebugger.trace(this, 'external calls to recorder.connect()');

                    var ticket:Ticket = connectable.connect();

                    if (ticket is GUIDTicket)
                    {
                        ret = GUIDTicket(ticket).guid.toString();
                    }
                }

                return ret;
            });

            ExternalInterface.addCallback(MEMBER_NAME.RECORDER_DISCONNECT, function():void
            {
                if (playcorder.recorder is IConnectable)
                {
                    var connectable:IConnectable = IConnectable(playcorder.recorder);

                    MonsterDebugger.trace(this, 'external calls to recorder.disconnect()');

                    connectable.disconnect();
                }
            });

            ExternalInterface.addCallback(MEMBER_NAME.RECORDER_INITIALIZE, function(config:Object):Boolean
            {

                var ret:Boolean = playcorder.init_recorder(config);

                playcorder.recorder.addEventListener(RecorderEvent.CONNECTED, onRecorderConnected);
                playcorder.recorder.addEventListener(RecorderEvent.DISCONNECTED, onRecorderDisconnected);
                playcorder.recorder.addEventListener(RecorderEvent.STARTED, onRecorderStarted);
                playcorder.recorder.addEventListener(RecorderEvent.STOPPED, onRecorderStopped);
                playcorder.recorder.addEventListener(RecorderEvent.ERROR, onRecorderError);
                playcorder.recorder.addEventListener(RecorderChangeEvent.CHANGE, onRecorderChange);

                return ret;
            });

            ExternalInterface.addCallback(MEMBER_NAME.PLAYER_INITIALIZE, function(config:Object):Boolean
            {
                var ret:Boolean = playcorder.init_player(config);

                playcorder.player.addEventListener(PlayerEvent.STARTED, onPlayerStarted);
                playcorder.player.addEventListener(PlayerEvent.STOPPED, onPlayerStopped);

                return ret;
            });

            ExternalInterface.addCallback(MEMBER_NAME.PREPARE, function():Boolean
            {
                return playcorder.prepare();
            });

            ExternalInterface.addCallback(MEMBER_NAME.GETID, function():Number
            {
                return _count;
            });

            _inited = true;

            // resolve when the super class is inited.
            dfd.resolve(super.init());

            return dfd.promise;
        }

        protected override function onReady():void
        {
            // fire ready event when it is ready
            callSelf( MEMBER_NAME.ONREADY );
        }

        protected function getFuncToInvokeExternalHostMethod(id:Number):String
        {
            return "";
        }

        public function UniversalInteroperator(playcorder:Playcorder)
        {
            _count = instanceCount++;
            _findSelf = getFuncToInvokeExternalHostMethod( _count );

            super(playcorder);

            data['id'] = _count;
        }
    }
}