Description
===========

* A basic recipe which configures ntp client.

Attributes
==========
* ntp[:servers] (applies to NTP Servers and Clients)

  - Array, should be a list of upstream NTP public servers.  The NTP protocol
    works best with at least 3 servers. 

Usage
=====

* Create a role, and specify your ntp servers somthing like the following:
<pre>
    name "base"
    default_attributes(
        "ntp" => {
        "servers" => ["0.pool.ntp.org", "1.pool.ntp.org"]
        }
    )
</pre>
