import argparse
from check_pullrequest import check_pullrequest_in_mdbci, \
    get_url_for_check_pullrequest
from redmine_api import get_redmine_server, get_redmine_issue, \
    get_test_scenario_value, is_issue_resolved, \
    transition_issue, add_comment, assigned_issue_to_user_id
from issue_statistics import getContributorsList, \
    getIssueJournal


ARG_BRANCH = '--branch'
SUCCESS_PRINT = 'This issue {} is successfully completed'
SUCCESS_COMMENT = 'Test success'
SUCCESS = "SUCCESS"
UNSUCCESS_PRINT = 'The issue {} is unsuccessfully completed'
TEST_SCENARIO_FAILED = 'Test scenario is missed\n'
TEST_SCENARIO_SUCCESS = 'Test scenario exists'
PULLREQUEST_FAILED = 'Pullrequest is missed\n'
PULLREQUEST_SUCCESS = 'Pullrequest exists'
FAIL_REASON = "FAIL_REASON"

# for env variable
PROPSFILE = 'propsfile'
MODE_AW = 'aw'

# values for status id
NEW = 1

GITHUB_URL = 'https://github.com/{}/{}/pull'
MAXSCALE_OWNER = 'mariadb-corporation'
MAXSCALE_REPO = 'maxscale-jenkins-jobs'

REDMINE_OSLL_HOST = 'https://dev.osll.ru'

ID = 'id'

def write_env_var(variable, value):
    f = open(PROPSFILE, MODE_AW)
    f.write(variable + '=' + value + '\n')
    f.close()


def get_comment(test_scenario_field=True, pullrequest=True):
    result = 'Test failed. \n'
    if not test_scenario_field:
        result += TEST_SCENARIO_FAILED
    if not pullrequest:
        result += PULLREQUEST_FAILED
    return result


def get_branch_number():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        ARG_BRANCH,
        required=True)
    args = parser.parse_args()
    return args.branch


def check_test_scenario_field(test_scenario_value):
    if test_scenario_value is None or test_scenario_value == u'':
        print TEST_SCENARIO_FAILED
        return False
    print TEST_SCENARIO_SUCCESS
    return True


def check_text_in_test_scenario_field(test_scenario_value):
    if test_scenario_value.find(
        get_url_for_check_pullrequest(
            GITHUB_URL,
            MAXSCALE_OWNER,
            MAXSCALE_REPO)) != -1:
        print PULLREQUEST_SUCCESS
        return True
    print PULLREQUEST_FAILED
    return False


def check_issue(branch):
    redmine = get_redmine_server()
    issue = get_redmine_issue(redmine, branch)
    if is_issue_resolved(issue):
        test_scenario_value = get_test_scenario_value(issue)
        test_scenario = check_test_scenario_field(test_scenario_value)
        pullrequest = check_pullrequest_in_mdbci(branch)
        if not pullrequest:  # while maxscale repo private
            pullrequest = check_text_in_test_scenario_field(
                test_scenario_value)
        if pullrequest and test_scenario:
            print SUCCESS_PRINT.format(branch)
            write_env_var(FAIL_REASON, SUCCESS)
        else:
            print UNSUCCESS_PRINT.format(branch)
            comment = get_comment(
                test_scenario, pullrequest)
            transition_issue(issue, NEW)
            journal = getIssueJournal(REDMINE_OSLL_HOST, issue[ID])
            last_user_id = getContributorsList(journal, return_value=ID)[-1]
            assigned_issue_to_user_id(issue[ID], last_user_id)
            add_comment(issue, comment)
            write_env_var(FAIL_REASON, comment)
    else:
        write_env_var(FAIL_REASON, SUCCESS)


if __name__ == '__main__':
    check_issue(get_branch_number())
