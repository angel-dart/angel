# Angel Results
5 consecutive trials run on a Windows 10 box with 4GB RAM, and several programs open in the background.

Setup:
* Angel framework `1.0.8`
* Running `wrk` 4.0.2.2
* 2 threads
* 256 connections
* 30 seconds

Average:
* `11070.18` req/sec
* `11.86` ms latency

```
tobe@LAPTOP-VBHCSVRH:/mnt/c/Users/thosa$ wrk -c 256 -d 30 -t 2 http://localhost:3000
Running 30s test @ http://localhost:3000
  2 threads and 256 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency    12.23ms    7.56ms 206.05ms   93.09%
    Req/Sec     5.48k   761.94     7.18k    87.50%
  324822 requests in 30.06s, 62.88MB read
Requests/sec:  10806.24
Transfer/sec:      2.09MB
tobe@LAPTOP-VBHCSVRH:/mnt/c/Users/thosa$ wrk -c 256 -d 30 -t 2 http://localhost:3000
Running 30s test @ http://localhost:3000
  2 threads and 256 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency    11.06ms    4.88ms 134.86ms   78.68%
    Req/Sec     5.98k   539.40     7.50k    91.40%
  356355 requests in 30.11s, 68.99MB read
Requests/sec:  11836.11
Transfer/sec:      2.29MB
tobe@LAPTOP-VBHCSVRH:/mnt/c/Users/thosa$ wrk -c 256 -d 30 -t 2 http://localhost:3000
Running 30s test @ http://localhost:3000
  2 threads and 256 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency    12.03ms    6.18ms 159.93ms   87.89%
    Req/Sec     5.52k     0.88k    7.32k    90.31%
  327749 requests in 30.06s, 63.45MB read
Requests/sec:  10901.35
Transfer/sec:      2.11MB
tobe@LAPTOP-VBHCSVRH:/mnt/c/Users/thosa$ wrk -c 256 -d 30 -t 2 http://localhost:3000
Running 30s test @ http://localhost:3000
  2 threads and 256 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency    12.92ms    7.06ms 189.00ms   82.48%
    Req/Sec     5.12k     1.00k    6.42k    75.59%
  302273 requests in 30.05s, 58.52MB read
Requests/sec:  10059.96
Transfer/sec:      1.95MB
tobe@LAPTOP-VBHCSVRH:/mnt/c/Users/thosa$ wrk -c 256 -d 30 -t 2 http://localhost:3000
Running 30s test @ http://localhost:3000
  2 threads and 256 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency    11.05ms    4.92ms 104.90ms   69.57%
    Req/Sec     5.95k     0.87k    7.65k    76.80%
  352798 requests in 30.03s, 68.30MB read
Requests/sec:  11747.23
Transfer/sec:      2.27MB
tobe@LAPTOP-VBHCSVRH:/mnt/c/Users/thosa$
```