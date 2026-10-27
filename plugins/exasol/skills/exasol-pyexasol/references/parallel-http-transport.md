# Parallel HTTP Transport

Use one of these designs:

1. Start independent processes and open a new PyExasol connection inside each
   process.
2. Run one parent `IMPORT` or `EXPORT` statement and use child processes for
   its HTTP streams.

Never reuse a parent connection in children or share one connection across
threads. Separate connections in threads are not the recommended performance
design because one Python process remains limited by the GIL.

For parallel HTTP transfer:

1. The parent opens the main connection and calls `get_nodes(pool_size)`.
2. Each child calls `pyexasol.http_transport(ipaddr, port, ...)` and sends
   `transport.exa_address` to the parent.
3. The parent calls `export_parallel()` or `import_parallel()` once with all
   addresses while the children call the matching callback methods.
4. On success or failure, the parent joins every child; terminate remaining
   children before raising an error.

The implemented property is `.exa_address`; some upstream docstrings wrongly
say `.address`. Child `compression` and `encryption` values must match the main
connection. Restrict child HTTP listeners to networks reachable by the Exasol
nodes; do not expose them broadly. PyExasol provides transport primitives, not
worker-pool cleanup.

`get_nodes()` repeats nodes when `pool_size` exceeds the active node count.
Measure the workload; more processes do not guarantee better performance.
