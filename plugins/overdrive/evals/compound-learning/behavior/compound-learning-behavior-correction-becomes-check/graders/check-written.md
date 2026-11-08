---
type: regex
target: trace
pattern: '(?:"name":"(?:Write|Edit)","input":\{(?:"replace_all":(?:true|false),)?"(?:file_path|path)":"(?:[^"]*/)?(?:tests?|scripts|\.githooks|\.husky)/|"name":"Bash","input":\{"command":"(?:[^"\\]|\\.)*?(?:>>?|(?:\\[nrt]|\b)tee\s+(?:-a\s+)?)\s*(?:\S*/)?(?:tests?|scripts|\.githooks|\.husky)/)(?=[^\n]*?(?:readFileSync|readdirSync|(?:\\[nrt]|\b)grep\b|(?:\\[nrt]|\b)rg\b|(?:\\[nrt]|\b)awk\b|\bfs\.read))(?=[^\n]*?(?:/[^/\n]{0,80}console[^/\n]{0,80}/[gimsuy]*|(?:includes|indexOf|match|matchAll|test|search|RegExp)\([^\n]{0,80}console|grep[^\n]{0,120}console))'
---
