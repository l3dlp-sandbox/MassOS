This is a fallback directory containing the license files for packages in the
MassOS system which do not appear to ship license files in their source tree.

Note that this is a HIGHLY undesired workaround. If at all possible, by any
means, you should try to derive the license text from the source tree, or add
it externally via a patch, rather than a file in this directory.

Sometimes the license text may not be a standalone file, but rather included
at the start of one or more of the software's source files. If this is the
case, it may be sufficient to simply extract out that part of the source file
and install it directly as the license file. As an example, for the 'zlib'
package, we do the following (dollar sign indicates the shell prompt, even
though this is ordinarily run from a script):

$ head -n28 zlib.h | tail -n25 | install -Dm644 /dev/stdin /usr/share/licenses/zlib/LICENSE

If there is already nothing in this directory apart from the README.txt file
you are reading right now, then that is a good sign, and is what we want to 
remain as the case. If there are license files still in this directory,
contributions that implement alternative methods would be appreciated, and will
allow us to hopefully (eventually) drop support for this directory outright.
