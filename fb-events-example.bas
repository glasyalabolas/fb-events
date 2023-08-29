#include once "inc/fb-events.bi"

'' Some event handlers
sub event1_handler( sender as any ptr, e as EventArgs )
  ? "This handler handles SOMETHING_HAPPENED events"
end sub

sub event2_handler1( sender as any ptr, e as EventArgs )
  ? "This handler handles SOMETHING_ELSE events"
end sub

sub event2_handler2( sender as any ptr, e as EventArgs )
  ? "This also handles SOMETHING_ELSE events. The event system " + _
    "supports multiple dispatch!"
end sub

'' Define some events
enum MYEVENTS
  SOMETHING_HAPPENED = 1
  SOMETHING_ELSE
end enum

var e = Events()

'' Register the listeners
e.registerListener( SOMETHING_HAPPENED, @event1_handler )
e.registerListener( SOMETHING_ELSE, @event2_handler1 )
e.registerListener( SOMETHING_ELSE, @event2_handler2 )

'' Then, raise some events
e.raise( SOMETHING_HAPPENED, EventArgs() )
e.raise( SOMETHING_ELSE, EventArgs() )

?

'' Unregistered listeners don't get called anymore
e.unregisterListener( SOMETHING_ELSE, @event2_handler1 )

e.raise( SOMETHING_ELSE, EventArgs() )

sleep()
