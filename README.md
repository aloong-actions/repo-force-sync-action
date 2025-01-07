# Repo Force Sync

A GitHub Action for syncing between two independent repositories using **force push**.
>[!WARNING]
>This action would fully cover the specific branch for the destination repo. Take care!

## Features

- Sync branches between two GitHub repositories
- The sync between repos is controlled by whitelist in `whitelist.json`
- To sync with current repository, please checkout [Github Repo Sync](https://github.com/marketplace/actions/github-repo-sync)

## Usage

> Always make a full backup of your repo (`git clone --mirror`) before using this action.

### GitHub Actions

**args**
```yml
  source_host:
    description: your source github host url, default to 'github.com'
    required: false
    default: github.com
  source_repo:
    description: GitHub repo slug or full url
    required: true
  source_branch:
    description: Branch name to sync from
    required: true
  destination_host:
    description: your destination github host url, default to 'github.com'
    required: false
    default: github.com
  destination_repo:
    description: GitHub repo slug or full url
    required: true
  destination_branch:
    description: Branch name to sync to
    required: true
  source_ssh_private_key:
    description: SSH key used to authenticate with source ssh url provided (optional if public or https url with authentication)
    required: false
  source_access_token:
    source: The personal access token you created for source repo https authentication
  destination_ssh_private_key:
    description: SSH key used to authenticate with destination ssh url provided (optional if public or https url with authentication)
    required: false
  destination_access_token:
    description: The personal access token you created for dest repo https authentication
```

> :warning:**Note**:
> If you use organization level secrets, and your repository is `PUBLIC`, make sure the org level secrets's `Repository access` property is set to `All repositories`, otherwise the action could not read the secrets.

**Sample**
```yml
# .github/workflows/git-sync.yml

on: push
jobs:
  git-sync:
    runs-on: [ebf-pod-ubuntu-2004-slim]
    steps:
      - name: auto sync full repo
        uses: aloong-actions/repo-force-sync-action@v1
        with:
          source_host: "github.enterprise.com"
          source_repo: "your-org/your-repo"
          source_branch: "master"
          # destination_host: 'xxxx'  -- default to github.com
          destination_repo: "your-dest-org/your-dest-repo"
          destination_branch: "main"
          source_access_token: ${{ secrets.your_source_token }}
          destination_access_token: ${{ secrets.your_dest_token }}
```

#### Whitelist

This actions checks the whitelist.json first, if the source host or dest host is
not in the whitelist, or the dest orgs not in the whitelist, the job will fail.

| source host                                                                        | destination host | allowed destination org              |
|------------------------------------------------------------------------------------|------------------|------------------------------|
| github.enterprise.com</br> github.com | github.com       | enterprise, enterprise-azure |
| github.enterprise.com</br> github.com | *enterprise.com  | *                            |

##### Using ssh

> The `ssh_private_key`, or `source_ssh_private_key` and `destination_ssh_private_key` must be supplied if using ssh clone urls.

```yml
source_repo: "git@github.com:username/repository.git"
```
or
```yml
source_repo: "git@gitlab.com:username/repository.git"
```


##### Using https

> The `ssh_private_key`, `source_ssh_private_key` and `destination_ssh_private_key` can be omitted if using authenticated https urls.

```yml
source_repo: "https://${SOURCE_ACCESS_TOKEN}@${SOURCE_HOST}/${SOURCE_REPO}.git"
dest_repo: "https://${DESTINATION_ACCESS_TOKEN}@${DESTINATION_HOST}/${DESTINATION_REPO}.git"
```

#### Set up deploy keys

> You only need to set up deploy keys if repository is private and ssh clone url is used.

- Either generate different ssh keys for both source and destination repositories or use the same one for both, leave passphrase empty (note that GitHub deploy keys must be unique for each repository)

```sh
$ ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
```

- In GitHub, either:

  - add the unique public keys (`key_name.pub`) to _Repo Settings > Deploy keys_ for each repository respectively and allow write access for the destination repository

  or

  - add the single public key (`key_name.pub`) to _Personal Settings > SSH keys_

- Add the private key(s) to _Repo > Settings > Secrets_ for the repository containing the action (`SSH_PRIVATE_KEY`, or `SOURCE_SSH_PRIVATE_KEY` and `DESTINATION_SSH_PRIVATE_KEY`)

#### Advanced: Sync all branches

To Sync all branches from source to destination, use `source_branch: "refs/remotes/source/*"` and `destination_branch: "refs/heads/*"`. But be careful, branches with the same name including `master` will be overwritten.

```yml
source_branch: "refs/remotes/source/*"
destination_branch: "refs/heads/*"
```

#### Advanced: Sync all tags

To Sync all tags from source to destination, use `source_branch: "refs/tags/*"` and `destination_branch: "refs/tags/*"`. But be careful, tags with the same name will be overwritten.

```yml
source_branch: "refs/tags/*"
destination_branch: "refs/tags/*"
```
