# Introduction

git-silo is an extension to git for storing large files.  It uses git filters to
intercept operations on large files, similar to git-media.  git-silo's primary
data transport is ssh.

See `git silo -h` for instructions how to use it.

# Alternatives

git-media: The mother of the git-filter-based approaches.  Originally developed
by schacon and now maintained by alebedev.

 - GitHub: <https://github.com/alebedev/git-media>.

git-bigstore: Python implementation that uses git filters and cloud storage.

 - GitHub: <https://github.com/lionheart/git-bigstore>.

git-fat: Anothr git-filter-based approach.  It is implemented in Python and uses
rsync for data transfer.

 - GitHub: <https://github.com/jedbrown/git-fat>.

git-lfs: Announced by GitHub in Apr 2015.  It uses git filters and seems to be
an evolution of git-media.  Implemented in Go, which allows distributing
statically linked binaries for many platforms.

 - Homepage: <https://git-lfs.github.com>.
 - GitHub: <https://github.com/github/git-lfs>.
 - Hacker news discussion: <https://news.ycombinator.com/item?id=9343021>.

git-annex: It uses a different approach based on symlinks instead of git
filters.

 - Homepage: <https://git-annex.branchable.com>.
