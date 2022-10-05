# What is this ?

Repository for logging my zig programming.

# Run

```
% zig build run
```

A feature to run is decided by defined environment variable(s).

## json to yaml converter

```
% JSON=sample.json zig build run
```

## http server

```
% HOST=127.0.0.1 PORT=3000 zig build run
```

# TEST

```
% zig test ./src/test.zig
```

