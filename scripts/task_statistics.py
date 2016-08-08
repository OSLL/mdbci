from requests import get
from argparse import ArgumentParser
import sys

def getProjectId(arguments.hostName, arguments.projectName)

def getIssuesList(arguments.hostName, projectId, arguments.issuefilter)

def getIssuesStatistics(issuesList)

def printIssueStatistics(issuesStatistics) 
    

def aggregateIssuesStatistics(issuesStatistics)

def printAggregatedIssuesStatistics(aggregatedIssuesStatistics)
    for user, count in aggregatedIssuesStatistics
        print "{}\t{}".format(user, count)

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
        required=True)
    return parser.parse_args()

if __name__ == '__main__':
    arguments = parseArguments()
    print arguments
    projectId = getProjectId(arguments.hostName, arguments.projectName)
    issuesList = getIssuesList(arguments.hostName, projectId, arguments.issuefilter)
    issuesStatistics = getIssuesStatistics(issuesList)
    printIssueStatistics(issuesStatistics) 
    aggregatedIssuesStatistics = aggregateIssuesStatistics(issuesStatistics)
    printAggregatedIssuesStatistics(aggregatedIssuesStatistics)
