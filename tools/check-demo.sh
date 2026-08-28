#!/bin/bash
# Drive the two interactive demos and assert they actually produced output.
#
# A static screenshot and a clean console say nothing here: both demos only run
# on pointer input, so their errors fire on interaction and never on load. The
# toolbar and the clipboard panel shipped broken once behind exactly that gap.
set -e
cd "$(dirname "$0")/.."
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
PORT=4178

python3 -m http.server $PORT --directory docs >/dev/null 2>&1 &
SRV=$!
trap 'kill $SRV 2>/dev/null; rm -f docs/_check.html' EXIT
until curl -s -o /dev/null "http://localhost:$PORT/index.html"; do sleep 0.2; done

python3 - <<'PY'
drive = '''
<div id="probe"></div>
<script>
var ERR=[]; addEventListener('error',function(e){ERR.push(e.message+' @'+e.lineno)});
addEventListener('load',function(){
 var shot=document.getElementById('shot');
 function go(){
  var sc=document.getElementById('screen');
  sc.setPointerCapture=function(){}; sc.releasePointerCapture=function(){};
  var r=sc.getBoundingClientRect();
  function ev(t,x,y){sc.dispatchEvent(new PointerEvent(t,{clientX:r.left+x,clientY:r.top+y,
    bubbles:true,cancelable:true,pointerId:1,pointerType:"mouse",button:0,buttons:1,isPrimary:true}));}
  ev("pointerdown",150,110);
  for(var i=1;i<=8;i++) ev("pointermove",150+i*50,110+i*26);
  ev("pointerup",550,318);
  ev("pointerdown",260,200);
  for(var j=1;j<=10;j++) ev("pointermove",260+j*22,200+Math.sin(j/2)*26);
  ev("pointerup",480,205);
  setTimeout(function(){
   var c=document.getElementById("clipCanvas"), b=document.getElementById("bar");
   document.getElementById("probe").textContent=JSON.stringify({
     errors:ERR,
     clipFilled:c.parentElement.classList.contains("filled"),
     clipReadout:document.getElementById("clipDim").textContent,
     toolbarShown:b.classList.contains("on"),
     manifestBars:document.querySelectorAll(".row .mbar i").length,
     ocrVerdict:(document.querySelector("#ocr .verdict")||{}).textContent||""
   });
  },400);
 }
 if(shot.complete&&shot.naturalWidth) setTimeout(go,250);
 else shot.addEventListener("load",function(){setTimeout(go,250)});
});
</script>
'''
s=open('docs/index.html').read()
open('docs/_check.html','w').write(s.replace('</body>', drive+'</body>'))
PY

OUT=$("$CHROME" --headless --disable-gpu --dump-dom --virtual-time-budget=6000 \
  --window-size=1440,3000 "http://localhost:$PORT/_check.html" 2>/dev/null \
  | grep -o '<div id="probe">[^<]*</div>' | sed 's/<[^>]*>//g')

echo "$OUT" | python3 -c '
import json,sys
d=json.loads(sys.stdin.read())
fail=[]
if d["errors"]:                      fail.append("js errors: %s" % d["errors"])
if not d["clipFilled"]:              fail.append("clipboard panel stayed empty after a drag")
if "x" not in d["clipReadout"] and "×" not in d["clipReadout"]:
                                     fail.append("clipboard readout: %r" % d["clipReadout"])
if not d["toolbarShown"]:            fail.append("toolbar never appeared")
if d["manifestBars"] < 5:            fail.append("manifest bars: %d" % d["manifestBars"])
print(json.dumps(d, indent=1))
if fail:
    print("\nFAIL"); [print(" -",f) for f in fail]; sys.exit(1)
print("\nPASS - both demos produced output")
'
