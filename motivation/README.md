You are here, because you might have received an patch or pull-request to one of your project.
This was just some typo-fixing in documentation, not the hard-to-catch null-pointer or missing feature.
You wonder .. why ?

What I did:
* walking around at random on lintian.debian.org, looking for ones with spelling-issues.
* looking up the upstream, get the source, run misspell_fixer against ( git, svn, tar, .. ) 
* manually check each and every finding. ( im not an native-speaker )
* when done, generate a pull-request (github) or provide a patch (email)

My rules:
* fixes only for text, man-pages, comments - never in "active" code ( not breaking variables, config-options).
* check for *po files, which could lead to translation issues later

Here my motivation
* once I started investigating an bug in a software.
* it was soo obvious, that anyone working with that will hit that bug within 5 minutes
* looking in vendors "known issues" and "patch" area - no success 
* spent a day in finding, documenting the bug for vendor.
* got reply from vendor within 5 minutes, patch solved issue - was already a year old.
* further investigation (am I stupid ?) .. in the patch-notes was a typo !
* had some more discussion with vendor, so he fixes that .. others will not fall into same trap.

So.. this is open-source, everyone can do his part; So did I.

A great software without documentation is worth nothing
Finding typos might distract people, or let them not find what they are looking for.
