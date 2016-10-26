from redmine import Redmine

USER = 'pytift.test.bot'
PASSWORD = 'pytift.test.bot'
COMPANY = 'https://dev.osll.ru'

RESOURCES = u'resources'
NAME = u'name'
TEST_SCENARIO = u'Test scenario'
VALUE = u'value'

# keys for status id
ATTRIBUTES = '_attributes'
STATUS = 'status'
ID = 'id'

# values for status id
REVIEW = 22


def get_redmine_server():
    redmine = Redmine(COMPANY, username=USER, password=PASSWORD)
    return redmine


def get_redmine_issue(redmine, branch):
    issue = redmine.issue.get(branch)
    return issue


def add_comment(issue, comment):
    issue.notes = comment
    issue.save()


def is_issue_resolved(issue):  # in review status
    return issue[ATTRIBUTES][STATUS][ID] == REVIEW


def transition_issue(issue, status):
    issue.status_id = status
    issue.save()


def get_test_scenario_value(issue):
    list_resources = issue.custom_fields[RESOURCES]
    for resource in list_resources:
        if resource[NAME] == TEST_SCENARIO:
            return resource[VALUE]
    return None


def assigned_issue_to_user_id(issue_id, user_id):
    redmine = get_redmine_server()   
    redmine.issue.update(issue_id, assigned_to_id=user_id)
