# Introduction

Git Silo is an extension to Git for storing large files.  It uses Git filters
to intercept operations on large files, similar to git-media.  Git Silo's
primary data transport is ssh.

See `git silo -h` for usage instructions.

Unless you already use Git Silo, I'd recommend you consider Git LFS instead.

# Alternatives

The following blog post contains a comparison of some approaches to storing big
files in git:
<http://blog.deveo.com/storing-large-binary-files-in-git-repositories/>.

git-media: The mother of the git-filter-based approaches.  Originally developed
by schacon and now maintained by alebedev.

 - GitHub: <https://github.com/alebedev/git-media>.

git-bigstore: Python implementation that uses git filters and cloud storage.

 - GitHub: <https://github.com/lionheart/git-bigstore>.

git-fat: Another git-filter-based approach.  It is implemented in Python and
uses rsync for data transfer.

 - GitHub: <https://github.com/jedbrown/git-fat>.

git-lfs: Announced by GitHub in Apr 2015.  It uses git filters and seems to be
an evolution of git-media.  Implemented in Go, which allows distributing
statically linked binaries for many platforms.

 - Homepage: <https://git-lfs.github.com>.
 - GitHub: <https://github.com/github/git-lfs>.
 - Hacker news discussion with lots of references to other tools:
   <https://news.ycombinator.com/item?id=9343021>.

git-annex: It uses a slightly different approach that is based on symlinks
instead of text placeholder files.  I'm unsure how it uses git filters.

 - Homepage: <https://git-annex.branchable.com>.

git-fit: It uses an approach that avoids git filters.  Meta data is tracked in
a single json file instead.

 - GitHub: <https://github.com/dailymuse/git-fit>

AWS CodeCommit: AWS announced CodeCommit for early 2015.  The announcement
claims that it will be compatible with git workflows but allow storing large
files.

 - Homepage: <http://aws.amazon.com/codecommit/>
