This is a complete mess for now. I found these files online:

http://www.bio.brandeis.edu/marderlab/matlab%20scripts.html

As I am only looking at a few files I probably won't do anything with this library.

Code options
------------

There seem to be three options when working with this data:

# Use the sigTOOL (http://sigtool.sourceforge.net/) by Malcolm Lidierth. This code seems to work with the data file directly. It is unclear if this is being updated. It is also unclear if this supports newer files. It might read newer files and just return junk.
# Use the SON library provided by CED. Some of predecessors of sigTOOL implemented exposure of this library in Matlab. Those files are old but the SON library seems to be receiving updates. Unfortunately it seems as if only 32 Windows might be supported.
# CED also provides a link to a NeuroShare dll which seems to be getting regular updates as well. The NeuroShare dll also comes in a 64 bit version. I'm not sure what is lost by using a generic reader but it seems to work well enough.