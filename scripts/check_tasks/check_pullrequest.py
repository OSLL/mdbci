import json
import requests


GITHUB_API_URL = 'https://api.github.com/repos/{}/{}/pulls'

MDBCI_OWNER = 'OSLL'
MDBCI_REPO = 'mdbci'

TITLE = 'title'

PULLREQUEST_FAILED = 'Pullrequest is missed'
PULLREQUEST_SUCCESS = 'Pullrequest exists'

def get_url_for_check_pullrequest(url, owner, repository):
    return url.format(owner, repository)


def check_pullrequest_in_mdbci(branch):
    response = requests.get(
        get_url_for_check_pullrequest(GITHUB_API_URL,MDBCI_OWNER, MDBCI_REPO))
    responseText = json.loads(response.text)
    for pull in responseText:
        if pull[TITLE][:4] == branch:
            print PULLREQUEST_SUCCESS
            return True
    print PULLREQUEST_FAILED
    return False
