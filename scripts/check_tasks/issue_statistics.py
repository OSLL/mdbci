from requests import get
from argparse import ArgumentParser
import sys

PROJECTS_URL = '{0}/projects.json'
ISSUES_URL = '{0}/issues.json?project_id={1}&limit=100&offset={2}&{3}'
JOURNAL_URL = '{0}/issues/{1}.json?include=journals'

NAME = 'name'
ID = 'id'
DETAILS = 'details'
NEW_VALUE = 'new_value'
STATUS_ID = 'status_id'
REVIEW_ID = "22"
USER = 'user'
PROJECTS = 'projects'
ISSUES = 'issues'
JOURNALS = 'journals'
ISSUE = 'issue'
LIMIT_MAX = 100
LIMIT = 'limit'
TOTAL_COUNT = 'total_count'


def getProjectId(hostName, projectName):
    url = PROJECTS_URL.format(hostName)
    projects = get(url, verify=False).json()[PROJECTS]
    for project in projects:
        if project[NAME] == projectName:
            return project[ID]
    raise ValueError("Project {0} not found!".format(projectName))


def getIssuesList(hostName, projectId, issuefilter):
    issues = []
    offset = 0
    while True:
        url = ISSUES_URL.format(hostName, projectId, offset, issuefilter)
        print "Requesting issues by url: {0}".format(url)
        result = get(url, verify=False).json()
        issues += result[ISSUES]
        if offset > result[TOTAL_COUNT]:
            break
        offset += LIMIT_MAX

    return issues


def getIssueJournal(hostName, issueId):
    url = JOURNAL_URL.format(hostName, issueId)
    return get(url, verify=False).json()[ISSUE][JOURNALS]


def getContributorsList(journal, return_value=NAME):
    contributors = set()
    for entry in journal:
        for detail in entry[DETAILS]:
           # if detail[NAME] == STATUS_ID  and NEW_VALUE in detail:
           #     print detail[NAME] + "=" +detail[NEW_VALUE]
            if detail[NAME] == STATUS_ID and detail[NEW_VALUE] == REVIEW_ID:
                if return_value == NAME:
                    contributors.add(entry[USER][NAME])
                else:
                    contributors.add(entry[USER][ID])
                break
    return list(contributors)


def getIssuesStatistics(hostName, issues):
    issueStatistics = {}
    for issue in issues:
        issueId = issue[ID]
        journal = getIssueJournal(hostName, issueId)
        contributors = getContributorsList(journal)
        contributorCount = len(contributors)
        for contributor in contributors:
            if contributor not in issueStatistics:
                issueStatistics[contributor] = {}
            issueStatistics[contributor][issueId] = contributorCount
    return issueStatistics


def printIssueStatistics(issuesStatistics):
    for user, statistic in issuesStatistics.iteritems():
        readableIssueList = ""
        taskCount = 0
        for issueId, contributorCount in statistic.iteritems():
            readableIssueList += "{0}({1}), ".format(issueId, contributorCount)
            taskCount += 1.0 / float(contributorCount)
        print "{0}({1}):\t{2}".format(user, taskCount, readableIssueList)

# def aggregateIssuesStatistics(issuesStatistics)

# def printAggregatedIssuesStatistics(aggregatedIssuesStatistics)
#    for user, count in aggregatedIssuesStatistics
#        print "{}\t{}".format(user, count)


def parseArguments():
    parser = ArgumentParser(description='Tool for retriving task statistics ')
    parser.add_argument(
        '--hostName',
        help='base address (e.g. http://site/)',
        type=unicode,
        required=True)
    parser.add_argument(
        '--projectName',
        help='project name to retrieve issues',
        type=unicode,
        required=True)
    parser.add_argument(
        '--issueFilter',
        help='filter for /issues.json REST interface, see more at http://www.redmine.org/projects/redmine/wiki/Rest_Issues#Listing-issues',
        type=unicode,
        default='')
    return parser.parse_args()

if __name__ == '__main__':
    arguments = parseArguments()
    print "Getting project id"
    projectId = getProjectId(arguments.hostName, arguments.projectName)
    print "Project id = {0}".format(projectId)
    print "Recieving issue list using project_id and filter"
    issuesList = getIssuesList(
        arguments.hostName,
        projectId,
        arguments.issueFilter)
    print "Recieved {0} issues".format(len(issuesList))
    print "Calculating task statistics for users"
    issuesStatistics = getIssuesStatistics(arguments.hostName, issuesList)
    printIssueStatistics(issuesStatistics)
