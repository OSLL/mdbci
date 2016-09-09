from github import Github

GITHUB_USERNAME = 'TestUserGeomongoGithub'
PASSWORD = 'ND3GyNHCpxweSqC2'
REPO = 'pytift_experimental'

# constants
OPEN = 'open'
PULLREQUEST_EXISTS = 'pullrequest exists'
PULLREQUEST_MISSED = 'pullrequest is missed'


def get_github_instance():
    github = Github(GITHUB_USERNAME, PASSWORD)
    return github


def check_pullrequest(branch):
    ghs = get_github_instance()
    list_repo = ghs.get_user().get_repos()
    for repo in list_repo:
        if repo.name == REPO:
            right_repo = repo
            break
    list_pulls = right_repo.get_pulls(OPEN)
    for pullrequest in list_pulls:
        if pullrequest.title == branch:
            print PULLREQUEST_EXISTS
            return True
    print PULLREQUEST_MISSED
    return False
