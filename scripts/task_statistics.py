from requests import get
from argparse import ArgumentParser
import sys

PROJECTS_URL = '{0}/projects.json'
ISSUES_URL = '{0}/issues.json?project_id={1}&limit=1000000&{2}'
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

def getProjectId(hostName, projectName):
    url = PROJECTS_URL.format(hostName)
    projects = get(url, verify=False).json()[PROJECTS]
    for project in projects:
        if project[NAME] == projectName:
            return project[ID]
    raise ValueError("Project {0} not found!".format(projectName))

def getIssuesList(hostName, projectId, issuefilter):
    url = ISSUES_URL.format(hostName, projectId, issuefilter)
    return get(url, verify=False).json()[ISSUES]

def getIssueJournal(hostName, issueId):
    url = JOURNAL_URL.format(hostName, issueId)
    return get(url, verify=False).json()[ISSUE][JOURNALS]

def getContributorsList(journal):
    contributors = set()
    for entry in journal:
        for detail in entry[DETAILS]:
           # if detail[NAME] == STATUS_ID  and NEW_VALUE in detail:
           #     print detail[NAME] + "=" +detail[NEW_VALUE]
            if detail[NAME] == STATUS_ID and detail[NEW_VALUE] == REVIEW_ID:
                contributors.add(entry[USER][NAME])
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
        readableStatistic = ""
        for issueId, contributorCount in statistic.iteritems():
            readableStatistic += "{0}({1}), ".format(issueId, contributorCount)
        print "{0}:\t{1}".format(user, readableStatistic)

#def aggregateIssuesStatistics(issuesStatistics)

#def printAggregatedIssuesStatistics(aggregatedIssuesStatistics)
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
        default = '')
    return parser.parse_args()

if __name__ == '__main__':
    arguments = parseArguments()
    projectId = getProjectId(arguments.hostName, arguments.projectName)
    issuesList = getIssuesList(arguments.hostName, projectId, arguments.issueFilter)
    issuesStatistics = getIssuesStatistics(arguments.hostName, issuesList)
    printIssueStatistics(issuesStatistics) 
#    aggregatedIssuesStatistics = aggregateIssuesStatistics(issuesStatistics)
#    printAggregatedIssuesStatistics(aggregatedIssuesStatistics)
