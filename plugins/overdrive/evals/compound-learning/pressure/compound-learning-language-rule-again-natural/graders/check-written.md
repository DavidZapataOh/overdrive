---
type: regex
target: trace
pattern: '(?:"name":"(?:Write|Edit)","input":\{"(?:file_path|path)":"(?:[^"]*/)?(?:tests?|scripts|\.githooks|\.husky)/|"name":"Bash","input":\{"command":"(?:[^"\\]|\\.)*?(?:>>?|\btee\s+(?:-a\s+)?)\s*(?:\S*/)?(?:tests?|scripts|\.githooks|\.husky)/)(?=[^\n]*?(?:readFileSync|readdirSync|\bgrep\b|\brg\b|\bawk\b|\bfs\.read))(?=[^\n]*?(?:/[^/\n]{0,80}(?:\[[^\]\\\n]*(?:[áéíóúñÁÉÍÓÚÑ]|\\+u00(?:e1|e9|ed|f3|fa|f1)|x7[fF])|[(|](?:de|la|el|que|para|con|los|las|del)\|(?:[a-z]+\|?)+)[^/\n]{0,80}/[gimsuy]*|(?:includes|indexOf|match|matchAll|test|search|RegExp)\([^\n]{0,80}(?:\[[^\]\\\n]*(?:[áéíóúñÁÉÍÓÚÑ]|\\+u00(?:e1|e9|ed|f3|fa|f1)|x7[fF])|[(|](?:de|la|el|que|para|con|los|las|del)\|(?:[a-z]+\|?)+)|grep[^\n]{0,120}(?:\[[^\]\\\n]*(?:[áéíóúñÁÉÍÓÚÑ]|\\+u00(?:e1|e9|ed|f3|fa|f1)|x7[fF])|[(|](?:de|la|el|que|para|con|los|las|del)\|(?:[a-z]+\|?)+)))'
---
