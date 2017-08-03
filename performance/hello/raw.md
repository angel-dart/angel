# `dart:io` Results
5 consecutive trials run on a Windows 10 box with 4GB RAM, and several programs open in the background.

Setup:
* Running `wrk` 4.0.2.2
* 2 threads
* 256 connections
* 30 seconds

Average:
* `14598.16` req/sec
* `8.88` ms latency

```
tobe@LAPTOP-VBHCSVRH:/mnt/c/Users/thosa$ wrk -c 256 -d 30 -t 2 http://localhost:3000
Running 30s test @ http://localhost:3000
  2 threads and 256 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency     9.67ms    8.19ms 202.28ms   96.17%
    Req/Sec     7.15k     1.47k    9.97k    73.76%
  417716 requests in 30.07s, 82.06MB read
Requests/sec:  13892.50
Transfer/sec:      2.73MB
tobe@LAPTOP-VBHCSVRH:/mnt/c/Users/thosa$ wrk -c 256 -d 30 -t 2 http://localhost:3000
Running 30s test @ http://localhost:3000
  2 threads and 256 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency     8.47ms    3.14ms 100.77ms   65.40%
    Req/Sec     7.61k   670.47     8.85k    73.88%
  453301 requests in 30.07s, 89.05MB read
Requests/sec:  15077.15
Transfer/sec:      2.96MB
tobe@LAPTOP-VBHCSVRH:/mnt/c/Users/thosa$ wrk -c 256 -d 30 -t 2 http://localhost:3000
Running 30s test @ http://localhost:3000
  2 threads and 256 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency     8.62ms    3.51ms  73.34ms   63.74%
    Req/Sec     7.52k   650.22     8.91k    79.17%
  448445 requests in 30.07s, 88.10MB read
Requests/sec:  14911.53
Transfer/sec:      2.93MB
tobe@LAPTOP-VBHCSVRH:/mnt/c/Users/thosa$ wrk -c 256 -d 30 -t 2 http://localhost:3000
Running 30s test @ http://localhost:3000
  2 threads and 256 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency     8.75ms    3.51ms  70.50ms   64.53%
    Req/Sec     7.41k   825.50    10.23k    72.24%
  441338 requests in 30.09s, 86.70MB read
Requests/sec:  14665.62
Transfer/sec:      2.88MB
tobe@LAPTOP-VBHCSVRH:/mnt/c/Users/thosa$ wrk -c 256 -d 30 -t 2 http://localhost:3000
Running 30s test @ http://localhost:3000
  2 threads and 256 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency     8.90ms    3.62ms  78.36ms   66.71%
    Req/Sec     7.31k   742.11    10.79k    77.84%
  434674 requests in 30.09s, 85.39MB read
Requests/sec:  14443.98
Transfer/sec:      2.84MB
```