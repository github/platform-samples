# Git Repo Analysis Scripts

Git can become slow if a repository exceeds certain thresholds ([read this for details](http://larsxschneider.github.io/2016/09/21/large-git-repos)). Use the scripts explained below to identify possible culprits in a repository. The scripts have been tested on macOS but they should run on Linux as is.

_Hint:_ The scripts can run for a long time and output a lot lines. Pipe their output to a file (`./script > myfile`) for further processing.

## Large by File Size
Use the [git-find-large-files](git-find-large-files) script to identity large files in your Git repository that you could move to [Git LFS](https://git-lfs.github.com/) (e.g. using [git-lfs-migrate](https://github.com/git-lfs/git-lfs/blob/master/docs/man/git-lfs-migrate.1.ronn)).

Use the [git-find-lfs-extensions](git-find-lfs-extensions) script to identify certain file types that you could move to [Git LFS](https://git-lfs.github.com/).

## Large by File Count
Use the [git-find-dirs-many-files](git-find-dirs-many-files) and [git-find-dirs-unwanted](git-find-dirs-unwanted) scripts to identify directories with a large number of files. These might indicate 3rd party components that could be extracted.

Use the [git-find-dirs-deleted-files](git-find-dirs-deleted-files) to identify directories that have been deleted and used to contain a lot of files. If you purge all files under these directories from your history then you might be able significantly reduce the overall size of your repository.


