---
type: regex
target: trace
pattern: '^\{"type":"assistant"[^\n]*(deslugify[^\n]{0,160}(missing|not (exist|present|defined|found|implemented|there|in )|doesn.t exist|does not exist|isn.t (there|in|present|defined|implemented)|absent|no such|only (has|exports))|(missing|no |not find|cannot find|can.t find|absent|without )[^\n]{0,80}deslugify)'
flags: im
---
