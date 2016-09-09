import argparse
from check_pullrequest import check_pullrequest
from redmine_api import get_redmine_server, get_redmine_issue, \
    get_test_scenario_field, is_issue_resolved, \
    transition_issue, add_comment

ARG_BRANCH = '--branch'
SUCCESS_PRINT = 'This issue {} is successfully completed'
SUCCESS_COMMENT = 'Test success'
SUCCESS = "SUCCESS"
UNSUCCESS_PRINT = 'This issue {} is unsuccessfully completed'
TEST_SCENARIO_FAILED = 'Test scenario is missed\n'
TEST_SCENARIO_SUCCESS = 'Test scenario exists'
PULLREQUEST_FAILED = 'Pullrequest is missed\n'
FAIL_REASON = "FAIL_REASON"

#for env variable
PROPSFILE = 'propsfile'
MODE_AW = 'aw'

#values for status id
NEW = 1


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


def check_test_scenario_field(test_scenario_field):
    if test_scenario_field is None or test_scenario_field == u'':
        print TEST_SCENARIO_FAILED
        return False
    print TEST_SCENARIO_SUCCESS
    return True


def check_issue(branch):
    redmine = get_redmine_server()
    issue = get_redmine_issue(redmine, branch)
    if is_issue_resolved(issue):
        test_scenario_field = get_test_scenario_field(issue)
        test_scenario = check_test_scenario_field(test_scenario_field)
        pullrequest = check_pullrequest(branch)
        if pullrequest and test_scenario:
            print SUCCESS_PRINT.format(branch)
            add_comment(issue, SUCCESS_COMMENT)
            write_env_var(FAIL_REASON, SUCCESS)
        else:
            print UNSUCCESS_PRINT.format(branch)
            comment = get_comment(
                test_scenario_field, pullrequest)
            transition_issue(issue, NEW)
            add_comment(issue, comment)
            write_env_var(FAIL_REASON, comment)
    else:
        write_env_var(FAIL_REASON, SUCCESS)


if __name__ == '__main__':
    check_issue(get_branch_number())

