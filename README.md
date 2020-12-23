# migrate-mercurial-to-git

## Usage
```sh
bash hg-to-git.sh <hg-repo-url> <git-repo-url>
```

## Optional: Target Prefix

For batch migration you can optionally specify `GIT_PREFIX` in the environment.
The target repo is constructed from `GIT_PREFIX` plus the name of the HG repo.

```sh
export GIT_PREFIX="https://gitlab.com/user/group/"
bash hg-to-git.sh https://internal.sys/scm-webapp/hg/some_name
```
The target repo will be `https://gitlab.com/user/group/`**`some_name`**

> ⚠️ `<git-repo-url>` overrides `GIT_PREFIX`

---

## Acknowledgements:
* Uses https://github.com/frej/fast-export for the repo conversion

---

*PULL REQUESTS WELCOME*
