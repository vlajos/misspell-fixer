You are here, because you might have received a patch or pull-request to one of your projects.
This was just some typo-fixing in documentation, not the hard-to-catch null-pointer or missing feature.

# You wonder .. why ?

### spelling-errors...
* this happens to everybody.
* I never see my own ones, just the ones from others. (and usually I make a ton of them) 
* the compiler did run successfully - hurray
* I have some shorter and longer fingers... how the hell should typing ever work ?

### What I did:
* walking around at random on lintian.debian.org, looking for ones with spelling-issues.
* looking up the upstream project, get the source, run `misspell_fixer` against ( git, svn, tar, .. ) 
* manually check each and every finding. ( im not a native-speaker )
* when done, generate a pull-request (github) or provide a patch (email)

### My rules:
* fixes only for text, man-pages, comments 
* never in "active" code ( not breaking variables, config-options).
* check for *po files, which could lead to translation issues later
* full respect. You did some fantastic piece of software. 
  I just don't have the time to add that super-feature or bugfix
* fixing in the upstream (and some projcects realy executes the `build on the shoulders of giants`), not do disti-specific patches - everybody profits.
* when on github, and your project has a .travis.yml, I activate and test if your tests still work.
* when you have a easy-to-execute /test environment ( e.g. `make test` ) i run them also.
* for the fancy rails, go, nodejs, ... dont force people to install tons of obscure libs. debian-stable-deb or nothing :)
* if you want me to sign some kind of CLA.. well, if you can afford some lawers.. :-P

### Here my motivation
* once I started investigate a bug in a (commercial) software.
* it was soo obvious, that anyone working with that will hit that bug within 5 minutes
* looking in vendors "known issues" and "patch" area - no success 
* spent hours in documenting, submitting the bug for vendor.
* got reply from vendor within five minutes - patch solved issue - was already a year old.
* more investigation (am I stupid ?) .. in the patch-description was a typo !
* had some more discussion with vendor, so he fixes that too .. others should not fall into same well-known trap.

So.. this is open-source, everyone can do his part; So I just did.
And a "here's the patch" is in general a more successfully way compared to sending an email and complain about.

A great software without documentation is worth nothing
Finding typos might distract people, or let them not find what they are looking for.

### You like it ?
If you decide to apply the patch, accept the pull-request...
* double-read the diff; I'm just a human.
* run your tests to verify things still work. ( having a CI or other tests/ is a good idea.. but that's an different story)
* there is no real need to add me to the changelog. Take it as "public domain", "copyleft" or whatever makes you happy
* If you still want to add a note, just link to ka7@github.com

### don't-like ?
* I'm ok with that, too; maybe I messed up something
* maybe I over-optimized something, or the wording was ok anyway

( You found an error here ?  Patches welcome ;-) )

