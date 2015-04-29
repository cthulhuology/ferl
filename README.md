ferl
----

ferl is an experimental distributed stack machine language in Erlang.


Concept
-------

So the idea behind ferl comes from a project I wrote ca. 1990 
which was a language somewhere between Forth and TCL.  At the 
time I thougth it would be cool if you had objects that had 
their own little state machines that communicated over a network
of computers.  

The problem back in 1990's was I had UARTs and a 2400 baud modem.
Eventually I got 2 computers to talk to eachother, passing code
from one to the other.  I'd get to program in the Internet for 
the next 20 years, but then I didn't have enough computers to do it.

The concept behind ferl is that code is data, data is code, and
you can move either to either (what ever is more convienent).  
By having a distributed stack machine, we can move state from
physical machine to physical machine, where that state is either
data or code, and expect it to just resume wherever it is.

In ferl, an actor is represented as a structure:

	[ Instructions, Data, Return, Dictionary ]

Where:

* Instructions - current instruction list
* Data - a data stack for storing transient data
* Return - a return stack for storing continuations
* Dictionary - a property list for term definition

Each ferl vm has a set of core definitions which define the base
language, and then each actor can contain it's own list of definitions.
Some of those definitions may refer to local resources or capabilities,
allowing the actor to access local behavior by name.

At each node, the ferl vm interprets the instruction stream within the
context of the actor's Dictionary and the local extensions.  In addition
to the typical programming language operations, some of those instructions 
can cause the actor to transfer to another node.  Think of these flow
control operations that transfer the process from one machine to another.


Examples
--------

Let's say we have an application we want to query a set of 
databases in sequence to build up a result.  First it will go
visit an order database and lookup a set of orders for the past
hour.  We'll store the order data in our dict and move on to the 
inventory node:

	orders where date 1 hour within define -> inventory

Which will result in our actor moving from the Orders node to the
inventory node:

	+--------+      +-----------+
        | Orders | ---> | Inventory |
	+--------+      +-----------+

In the Inventory node, we'll check each order to see if they 
are in the inventory, and if there are we'll spawn a new 
actor to ship the order, otherwise we'll spawn a new actor
to backorder the parts, then we'll wait an hour and go grab
the last hour of orders:

	: ship inventory withdraw spawn -> shipping ups send ;
	: backorder spawn -> backorders customer alert ;

	orders where quantity inventory quantity <= ? ship backorder
	1 hour wait -> orders

Here we've got another flow control concept where the original actor
spawns new actors that go off perform some other flows based on their
order data, on some other nodes, while our original actor then goes
off and returns to the original node and effectively loops:

			    +----------+
                       +--->| Shipping |
	+-----------+  |    +----------+       +--------+
        | Inventory | -+---------------------> | Orders |
	+-----------+  |    +------------+     +--------+
                       +--->| Backorders |
 			    +------------+

We can actually write a single linear program, with code being evaluated
on multiple machines, and multiple tasks being run in parallel on multiple
machines as operations on array elements, similar to the techniques 
described in: http://www.fscript.org/documentation/OOPAL.pdf

