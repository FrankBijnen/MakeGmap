A few really fast tools to convert, filter and update OpenStreetMap data files<br/>
<br/>
Current Version: 0.9<br/>
<br/>
Programm desrcriptions:<br/>
https://wiki.openstreetmap.org/wiki/osmconvert <br/>
https://wiki.openstreetmap.org/wiki/osmfilter <br/>
https://wiki.openstreetmap.org/wiki/osmupdate <br/>
<br/>
Changelog 0.9<br/>
<br/>
osmconvert:<br/>
new feature: --complete-boundaries<br/>
new syntax: --complete-multipolygons instead of --complex-ways<br/>
bug fixed: tag confusion when applying --modify-tags="... add ..."<br/>
<br/>
osmconvert and osmfilter:<br/>
increased hash size from 1000 MB to 1360 MB (--help will show more information on --hash-memory)<br/>
<br/>
osmupdate:<br/>
changed default repository access to HTTPS,<br/>
allowing new options --complete-multipolygons and --complete-boundaries being relayed to osmconvert<br/>
