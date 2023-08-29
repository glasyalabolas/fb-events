#ifndef __FB_EVENTS__
#define __FB_EVENTS__

'' Type alias for event IDs
type as long EventID

'' Just a base type to allow covariant types
type EventArgs extends Object : end type

'' Signature for event handling subs
type as sub( as any ptr, as EventArgs ) EventHandler

'' Convenience macro to perform the covariant cast
#define toHandler( fp ) ( cast( EventHandler, @fp ) )

#ifndef FBNULL
  #define FBNULL cast( any ptr, 0 )
#endif

type Events
  public:
    declare constructor()
    declare constructor( as long )
    declare destructor()
    
    declare function registerListener( as EventID, as EventHandler ) as boolean
    declare function unregisterListener( as EventID, as EventHandler ) as boolean
    declare sub raise( as EventID, as EventArgs, as any ptr = 0 )
  
  private:
    type LinkedListNode
      declare constructor()
      declare constructor( as any ptr )
      
      as LinkedListNode ptr forward, backward
      as any ptr item
    end type
    
    '' (Doubly) Linked List
    type LinkedList
      public:
        declare constructor()
        declare destructor()
        
        declare operator [] ( as integer ) as any ptr
        
        declare property count() as integer
        declare property first() as LinkedListNode ptr
        declare property last() as LinkedListNode ptr
        
        declare sub clear()
        declare function addBefore( as LinkedListNode ptr, as any ptr ) as LinkedListNode ptr
        declare function addAfter( as LinkedListNode ptr, as any ptr ) as LinkedListNode ptr
        declare function addFirst( as any ptr ) as LinkedListNode ptr
        declare function addLast( as any ptr ) as LinkedListNode ptr
        declare function remove( as LinkedListNode ptr ) as any ptr
        declare function removeFirst() as any ptr
        declare function removeLast() as any ptr
      
      private:
        declare sub _dispose()
        
        as LinkedListNode ptr _first, _last
        as integer _count
    end type
    
    '' Internal type for entries into the hash table
    type EventTableEntry
      as EventID eID
      as LinkedList listeners
      as long idx
    end type
    
    declare static function hash( as ulong ) as ulong
    
    declare function find( as EventID ) as EventTableEntry ptr
    
    as EventTableEntry _bucket( any )
    as long _entry( any ), _size, _count
end type

constructor Events()
  constructor( 256 )
end constructor

constructor Events( size as long )
  _size = iif( size < 16, 16, size )
  redim _bucket( 0 to _size - 1 )
  redim _entry( 0 to _size - 1 )
  
  for i as integer = 0 to _size - 1
    _entry( i ) = -1
  next
end constructor

destructor Events()
  erase( _bucket )
  erase( _entry )
end destructor

function Events.hash( x as ulong ) as ulong
  x = ( ( x shr 16 ) xor x ) * &h45d9f3b
  x = ( ( x shr 16 ) xor x ) * &h45d9f3b
  return( ( x shr 16 ) xor x )
end function

function Events.find( eID as EventID ) as EventTableEntry ptr
  dim as ulong h = hash( eID ) mod _size
  dim as long current = _entry( h )
  
  do while( current <> -1 )
    if( _bucket( current ).eID = eID ) then
      return( @_bucket( current ) )
    end if
    
    current = _bucket( current ).idx
  loop
  
  return( 0 )
end function

function Events.registerListener( eID as EventID, handler as EventHandler ) as boolean
  var e = find( eID )
  
  if( e = 0 ) then
    '' Event isn't registered yet
    if( _count < _size ) then
      dim as ulong h = hash( eID ) mod _size
      
      _bucket( _count ).idx = _entry( h )
      _bucket( _count ).eID = eID
      _bucket( _count ).listeners.addLast( handler )
      _entry( h ) = _count
      
      _count += 1
      
      return( true )
    end if
  else
    '' Event is already registered, just add the handler
    e->listeners.addLast( handler )
    return( true )
  end if
  
  return( false )
end function

function Events.unregisterListener( eID as EventID, handler as EventHandler ) as boolean
  var e = find( eID )
  
  if( e <> 0 ) then
    var n = e->listeners.first
    
    do while( n <> 0 )
      if( n->item = handler ) then
        e->listeners.remove( n )
        return( true )
      end if
      
      n = n->forward
    loop
  end if
  
  return( false )
end function

sub Events.raise( eID as EventID, p as EventArgs, sender as any ptr = 0 )
  var e = find( eID )
  
  if( e <> 0 ) then
    var n = e->listeners.first
    
    for i as integer = 0 to e->listeners.count - 1
      cast( EventHandler, n->item )( sender, p )
      n = n->forward 
    next
  end if
end sub

private constructor Events.LinkedListNode() : end constructor

private constructor Events.LinkedListNode( anItem as any ptr )
  item = anItem
end constructor

private constructor Events.LinkedList() : end constructor

private destructor Events.LinkedList()
  clear()
end destructor

private operator Events.LinkedList.[]( index as integer ) as any ptr
  var n = _first
  
  for i as integer = 0 to _count - 1
    if( i = index ) then
      return( n->item )
    end if
    
    n = n->forward
  next
  
  return( FBNULL )
end operator

private property Events.LinkedList.count() as integer
  return( _count )
end property

private property Events.LinkedList.first() as LinkedListNode ptr
  return( _first )
end property

private property Events.LinkedList.last() as LinkedListNode ptr
  return( _last )
end property

private sub Events.LinkedList.clear()
  do while( _count > 0 )
    remove( _last )
  loop
  
  _first = FBNULL
  _last = _first
end sub

private function Events.LinkedList.addBefore( _
  node as LinkedListNode ptr, item as any ptr ) as LinkedListNode ptr
  
  var newNode = new LinkedListNode( item )
  
  newNode->backward = node->backward
  newNode->forward = node
  
  if( node->backward = FBNULL ) then
    _first = newNode
  else
    node->backward->forward = newNode
  end if
  
  _count += 1
  node->backward = newNode
  
  return( newNode )
end function

private function Events.LinkedList.addAfter( _
  node as LinkedListNode ptr, item as any ptr ) as LinkedListNode ptr
  
  var newNode = new LinkedListNode( item )
  
  newNode->backward = node
  newNode->forward = node->forward
  
  if( node->forward = FBNULL ) then
    _last = newNode
  else
    node->forward->backward = newNode
  end if
  
  _count += 1
  node->forward = newNode
  
  return( newNode )
end function

private function Events.LinkedList.addFirst( item as any ptr ) as LinkedListNode ptr
  if( _first = FBNULL ) then
    var newNode = new LinkedListNode( item )
    
    _first = newNode
    _last = newNode
    
    newNode->backward = FBNULL
    newNode->forward = FBNULL
    
    _count += 1
    
    return( newNode )
  end if
  
  return( addBefore( _first, item ) )
end function

private function Events.LinkedList.addLast( item as any ptr ) as LinkedListNode ptr
  return( iif( _last = FBNULL, addFirst( item ), addAfter( _last, item ) ) )
end function

private function Events.LinkedList.remove( node as LinkedListNode ptr ) as any ptr
  dim as any ptr item = FBNULL
  
  if( node <> FBNULL andAlso _count > 0 ) then
    if( node->backward = FBNULL ) then
      _first = node->forward
    else
      node->backward->forward = node->forward
    end if
    
    if( node->forward = FBNULL ) then
      _last = node->backward
    else
      node->forward->backward = node->backward
    end if
    
    _count -= 1
    item = node->item
    
    delete( node )
  end if
  
  return( item )
end function

private function Events.LinkedList.removeFirst() as any ptr
  return( remove( _first ) )
end function

private function Events.LinkedList.removeLast() as any ptr
  return( remove( _last ) )
end function

#undef FBNULL

#endif