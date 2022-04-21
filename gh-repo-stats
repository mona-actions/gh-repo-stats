#!/bin/bash
################################################################################
################################################################################
####### Get All Repos from Org List ############################################
################################################################################
################################################################################

# LEGEND:
# This script will use the github API to list all repos
# and sizes for an organization
# It will return an output.csv with the following statistics:
#
# Organization Name
# Repository Name
# If empty
# Last push
# Last commit
# isFork
# Size(mb)
# Total record count
# Collaborator count
# Protected branches
# PR reviews
# Milestones
# Issues
# Pull requests
# PR review comments
# Commit comments
# Issue comments
# Issue events
# Releases
# Projects
# Migration URL
#
# This will work for users on GitHub.com that are trying to figure out
# how many repos they own, and how large they are.
# This can be used by services to help distinguish what repos
# could be an issue, as well as help prepare for a migration
#
# PREREQS:
# You need to have the following to run this script successfully:
# - GitHub Personal Access Token with a scope of "repos" and access to the organization(s) that will be analyzed
# - Either the name of the organization to be analyzed, or a list of organizations with
#   the format provided by the Organization csv report found at [YOUR_GHE_DOMAIN]/stafftools/reports
# - jq installed on the machine running the query
#
# NOTES:
# - Repositories under 1 mb will be shown as 0mb
#

################################################################################
#### Function PrintUsage #######################################################
PrintUsage()
{
  cat <<EOM
Usage: get-repo-statistics [options] ORGANIZATION_NAME

Options:
    -h, --help                    : Show script help
    -d, --Debug                   : Enable Debug logging
    -u, --url                     : Set GHE URL (e.g. https://github.example.com) Looks for GHE_URL environment
                                    variable if omitted
    -i, --input                   : Set path to a file with a list of organizations to scan, with the syntax of
                                    an Org Statistics csv
                                    exported from https://github.example.com/stafftools/reports
    -t, --token                   : Set Personal Access Token with repo scope - Looks for GITHUB_TOKEN environment
                                    variable if omitted
    -r, --analyze-repo-conflicts  : Checks the Repo Name against repos in other organizations and generates a list
                                    of potential naming conflicts if those orgs are to be merged during migration
    -T, --analyze-team-conflicts  : Gathers each org's teams and checks against other orgs to generate a list of
                                    potential naming conflicts if those orgs are to be merged during migration
    -p, --repo-page-size          : Set the pagination size for the initial repository GraphQL query - defaults to 20
                                    If a timeout occurs, reduce this value
    -e, --extra-page-size         : Set the pagination size for subsequent, paginated GraphQL queries - defaults to 20
                                    If a timeout occurs, reduce this value

Description:
get-repo-statistics scans an organization or list of organizations for all repositories and gathers size statistics for each repository

Example:
  ./get-repo-statistics -u https://github.example.com -t ABCDEFG1234567 my-org-name

EOM
  exit 0
}
####################################
# Read in the parameters if passed #
####################################
PARAMS=""
while (( "$#" )); do
  case "$1" in
    -h|--help)
      PrintUsage;
      ;;
    -u|--url)
      GHE_URL=$2
      shift 2
      ;;
    -d|--DEBUG)
      DEBUG=true
      shift
      ;;
    -t|--token)
      GITHUB_TOKEN=$2
      shift 2
      ;;
    -i|--input)
      INPUT_FILE_NAME=$2
      shift 2
      ;;
    -r|--analyze-repo-conflicts)
      ANALYZE_CONFLICTS=1
      shift
      ;;
    -T|--analyze-team-conflicts)
      ANALYZE_TEAMS=1
      shift
      ;;
    -p|--repo-page-size)
      REPO_PAGE_SIZE=$2
      shift 2
      ;;
    -e|--extra-page-size)
      EXTRA_PAGE_SIZE=$2
      shift 2
      ;;
    --) # end argument parsing
      shift
      break
      ;;
    -*) # unsupported flags
      echo "Error: Unsupported flag $1" >&2
      exit 1
      ;;
    *) # preserve positional arguments
  PARAMS="$PARAMS $1"
  shift
  ;;
  esac
done

##################################################
# Set positional arguments in their proper place #
##################################################
eval set -- "$PARAMS"

###########
# GLOBALS #
###########
ORG_NAME=$1            # Name of the GitHub Organization
SLEEP='300'            # Number of seconds to sleep if out of API calls
SLEEP_RETRY_COUNT='15' # Number of times to try to sleep before giving up
SLEEP_COUNTER='0'      # Counter of how many times we have gone to sleep
EXISTING_FILE='0'      # Check if a file already exists

################################################################################
############################ FUNCTIONS #########################################
################################################################################
################################################################################
################################################################################
#### Function DebugJQ ##########################################################
DebugJQ()
{
  # If Debug is on, print it out...
  if [[ ${DEBUG} == true ]]; then
    echo "$1" | jq '.'
  fi
}
################################################################################
#### Function Debug ############################################################
Debug()
{
  # If Debug is on, print it out...
  if [[ ${DEBUG} == true ]]; then
    echo "$1"
  fi
}
################################################################################
#### Function Header ###########################################################
Header()
{
  echo ""
  echo "######################################################"
  echo "######################################################"
  echo "############# GitHub repo list and sizer #############"
  echo "######################################################"
  echo "######################################################"
  echo ""

  ###################
  # Get the GHE URL #
  ###################
  if [[ -z ${GHE_URL} ]]; then
    echo ""
    echo "------------------------------------------------------"
    echo "Please give the URL to the GitHub Enterprise instance you would like to query"
    echo "in the format: https://ghe-url.com"
    echo "followed by [ENTER]:"

    ########################
    # Read input from user #
    ########################
    read -r GHE_URL

    ############################################
    # Clean any whitespace that may be entered #
    ############################################
    GHE_URL_NO_WHITESPACE="$(echo -e "${GHE_URL}" | tr -d '[:space:]')"
    GHE_URL=$GHE_URL_NO_WHITESPACE
  fi

  #################################
  # Get the Personal Access Token #
  #################################
  GetPersonalAccessToken

  ################
  # Set the URLS #
  ################
  if [[ "${GHE_URL}" == "https://github.com" ]]; then
    GITHUB_URL="https://api.github.com"
    GRAPHQL_URL="https://api.github.com/graphql"
  else
    GITHUB_URL+="${GHE_URL}/api/v3"
    GRAPHQL_URL="${GHE_URL}/api/graphql"
  fi

  if [[ -z "${REPO_PAGE_SIZE}" ]]; then
    REPO_PAGE_SIZE=20
  fi

  if [[ -z "${EXTRA_PAGE_SIZE}" ]]; then
    EXTRA_PAGE_SIZE=100
  fi

  ################################################################
  # Validate we can hit the endpoint by getting the current user #
  ################################################################
  Debug "curl -kw '%{http_code}' -s --request GET \
  --url ${GITHUB_URL}/user \
  --header \"authorization: Bearer ************\""

  USER_RESPONSE=$(curl -kw '%{http_code}' -s --request GET \
    --url "${GITHUB_URL}"/user \
    --header "authorization: Bearer ${GITHUB_TOKEN}")

  Debug "USER_RESPONSE: "
  Debug "${USER_RESPONSE}"

  USER_RESPONSE_CODE="${USER_RESPONSE:(-3)}"
  USER_DATA="${USER_RESPONSE::${#USER_RESPONSE}-4}"

  DebugJQ "${USER_DATA}"

  #######################
  # Validate the return #
  #######################
  if [[ "$USER_RESPONSE_CODE" != "200" ]]; then
    echo "Error getting user"
    echo "${USER_DATA}"
  else
    USER_LOGIN=$(echo "${USER_DATA}" | jq -r '.login')
    # Check for success
    if [[ -z ${USER_LOGIN} ]]; then
      # Got bad return
      echo "ERROR! Failed to validate GHE instance:[${GITHUB_URL}]"
      echo "Received error: ${USER_DATA}"
      exit 1
    else
      Debug "Successfully validated access to GHE Instance..."
    fi
  fi

  #####################
  # Check GHE version #
  #####################
  if [[ "${GITHUB_URL}" != "https://api.github.com" ]]; then

    META_RESPONSE=$(curl -kw '%{http_code}' -s --request GET \
    --url "${GITHUB_URL}"/meta \
    --header "authorization: Bearer ${GITHUB_TOKEN}")

    Debug "META_RESPONSE: "
    Debug "${META_RESPONSE}"

    META_RESPONSE_CODE="${META_RESPONSE:(-3)}"
    META_DATA="${META_RESPONSE::${#META_RESPONSE}-4}"

    DebugJQ "${META_DATA}"

    #######################
    # Validate the return #
    #######################
    if [[ "$META_RESPONSE_CODE" != "200" ]]; then
      echo "Error getting GHE version"
      echo "${META_DATA}"
    else
      VERSION=$(echo "${META_DATA}" | jq -r '.installed_version')
    fi
  else
    VERSION="cloud"
  fi
  Debug "Version: ${VERSION}"

  ###########################
  # Check org or input file #
  ###########################
  if [[ -z ${ORG_NAME} ]] && [[ -z ${INPUT_FILE_NAME} ]]; then
    ###########################################
    # Get the name of the GitHub Organization #
    ###########################################
    echo ""
    echo "------------------------------------------------------"
    echo "Please enter name of the GitHub Organization you wish to"
    echo "gather information from, followed by [ENTER]:"
    ########################
    # Read input from user #
    ########################
    read -r ORG_NAME

    # Clean any whitespace that may be enetered
    ORG_NAME_NO_WHITESPACE="$(echo -e "${ORG_NAME}" | tr -d '[:space:]')"
    ORG_NAME="${ORG_NAME_NO_WHITESPACE}"

    #########################
    # Validate the Org Name #
    #########################
    if [ ${#ORG_NAME} -le 1 ]; then
      echo "Error! You must give a valid Organization name!"
      exit 1
    fi
  fi

  #################################
  # Get the personal access token #
  #################################
  GetPersonalAccessToken

  ###########################################
  # Make lower case to prevent weird issues #
  ###########################################
  ORG_NAME=$(echo "${ORG_NAME}" | tr '[:upper:]' '[:lower:]')
}
################################################################################
#### Function Footer ###########################################################
Footer()
{
  #######################################
  # Basic footer information and totals #
  #######################################
  echo ""
  echo "######################################################"
  echo "The script has completed"
  echo "Results file:[${OUTPUT_FILE_NAME}]"
  echo "######################################################"
  echo ""
  echo ""
}
################################################################################
#### Function GetPersonalAccessToken ###########################################
GetPersonalAccessToken()
{
  ############################
  # Check if we have a token #
  ############################
  if [[ -z ${GITHUB_TOKEN} ]]; then
    ########################################
    # Get the GitHub Personal Access Token #
    ########################################
    echo ""
    echo "------------------------------------------------------"
    echo "Please create a GitHub Personal Access Token used to gather"
    echo "information from your Organization, with a scope of 'repo',"
    echo "followed by [ENTER]:"
    echo "(note: your input will NOT be displayed)"
    ########################
    # Read input from user #
    ########################
    read -rs GITHUB_TOKEN
  fi
  # Clean any whitespace that may be enetered
  GITHUB_TOKEN_NO_WHITESPACE="$(echo -e "${GITHUB_TOKEN}" | tr -d '[:space:]')"
  GITHUB_TOKEN="${GITHUB_TOKEN_NO_WHITESPACE}"

  ##########################################
  # Check the length of the PAT for sanity #
  ##########################################
  if [ ${#GITHUB_TOKEN} -ne 40 ]; then
    echo "GitHub PAT's are 40 characters in length! you gave me ${#GITHUB_TOKEN} characters!"
    exit 1
  fi
}
################################################################################
#### Function GenerateFiles #####################################################
GenerateFiles()
{
  ##########################
  # Get current date stamp #
  ##########################
  # Get datestring YYYYMMDDHHMM
  DATE=$(date +%Y%m%d%H%M)

  ####################
  # Create File Name #
  ####################
  # Example: MyOrg-all_repos-201901041059.csv
  OUTPUT_FILE_NAME="$ORG_NAME-all_repos-$DATE.csv"

  ######################################################
  # Need to see if there is a file that already exists #
  ######################################################
  EXISTING_FILE_CMD=$(find . -name "$ORG_NAME-all_repos-*" |grep . 2>&1)

  #######################
  # Load the error code #
  #######################
  ERROR_CODE=$?

  ##############################
  # Check the shell for errors #
  ##############################
  if [ "${ERROR_CODE}" -eq 0 ]; then
    # There is already file
    # Going to use and append
    OUTPUT_FILE_NAME="${EXISTING_FILE_CMD:2}"
    EXISTING_FILE=1
  fi

  if [[ ${ANALYZE_CONFLICTS} -eq 1 ]]; then
    REPO_CONFLICTS_OUTPUT_FILE="$ORG_NAME-repo-conflicts-${DATE}.csv"

    ######################################################
    # Need to see if there is a file that already exists #
    ######################################################
    EXISTING_FILE_CMD=$(find . -name "$ORG_NAME-repo-conflicts-*" |grep . 2>&1)

    #######################
    # Load the error code #
    #######################
    ERROR_CODE=$?

    ##############################
    # Check the shell for errors #
    ##############################
    if [ "${ERROR_CODE}" -eq 0 ]; then
      # There is already file
      # Going to use and append
      REPO_CONFLICTS_OUTPUT_FILE="${EXISTING_FILE_CMD:2}"
    fi

    if ! echo "conflict qty, repo name, org names" > "${REPO_CONFLICTS_OUTPUT_FILE}"
    then
      echo "Failed to generate result file: ${REPO_CONFLICTS_OUTPUT_FILE}!"
      exit 1
    fi
  fi

  if [[ ${ANALYZE_TEAMS} -eq 1 ]]; then
    TEAM_CONFLICTS_OUTPUT_FILE="$ORG_NAME-team-conflicts-${DATE}.csv"

    ######################################################
    # Need to see if there is a file that already exists #
    ######################################################
    EXISTING_FILE_CMD=$(find . -name "$ORG_NAME-team-conflicts-*" |grep . 2>&1)

    #######################
    # Load the error code #
    #######################
    ERROR_CODE=$?

    ##############################
    # Check the shell for errors #
    ##############################
    if [ "${ERROR_CODE}" -eq 0 ]; then
      # There is already file
      # Going to use and append
      TEAM_CONFLICTS_OUTPUT_FILE="${EXISTING_FILE_CMD:2}"
    fi

    if ! echo "conflict qty, team name, org names" > "${TEAM_CONFLICTS_OUTPUT_FILE}"
    then
      echo "Failed to generate result file: ${TEAM_CONFLICTS_OUTPUT_FILE}!"
      exit 1
    fi
  fi

  #########################################
  # Only add header if were not appending #
  #########################################
  if [ "${EXISTING_FILE}" -ne 1 ]; then
    #############################
    # Create Header in the file #
    #############################
    echo "Creating file header..."
    # File format headers: ORG_NAME,REPO_NAME,IS_EMPTY,PUSHED_AT,UPDATED_AT,IS_FORK,REPO_SIZE,RECORD_CT,COLLABORATOR_CT,PROTECTED_BRANCH_CT,PR_REVIEW_CT,MILESTONE_CT,ISSUE_CT,PR_CT,PR_REVIEW_COMMENT_CT,COMMIT_COMMENT_CT,ISSUE_COMMENT_CT,ISSUE_EVENT_CT,RELEASE_CT,PROJECT_CT,GHE_URL/ORG_NAME/REPO_NAME,MIGRATION_ISSUE
    echo "Org_Name,Repo_Name,Is_Empty,Last_Push,Last_Update,isFork,Repo_Size(mb),Record_Count,Collaborator_Count,Protected_Branch_Count,PR_Review_Count,Milestone_Count,Issue_Count,PR_Count,PR_Review_Comment_Count,Commit_Comment_Count,Issue_Comment_Count,Issue_Event_Count,Release_Count,Project_Count,Full_URL,Migration_Issue" >> "${OUTPUT_FILE_NAME}" 2>&1

    #######################
    # Load the error code #
    #######################
    ERROR_CODE=$?

    ##############################
    # Check the shell for errors #
    ##############################
    if [ ${ERROR_CODE} -ne 0 ]; then
      echo "ERROR! Failed to write headers to file:[${OUTPUT_FILE_NAME}]!"
      exit 1
    fi
  fi
}
################################################################################
#### Function CheckAdminRights #################################################
CheckAdminRights()
{
  ################
  # Pull in vars #
  ################
  ORG_NAME="$1"

  # Debug info
  Debug "echo curl -kw '%{http_code}' -s -X GET \
    --url ${GITHUB_URL}/orgs/${ORG_NAME}/memberships/${USER_LOGIN} \
    --header \"authorization: Bearer ${GITHUB_TOKEN}\""

  ##################
  # Get membership #
  ##################
  MEMBERSHIP_RESPONSE=$(curl -kw '%{http_code}' -s -X GET \
  --url "${GITHUB_URL}/orgs/${ORG_NAME}/memberships/${USER_LOGIN}" \
  --header "authorization: Bearer ${GITHUB_TOKEN}")

  MEMBERSHIP_RESPONSE_CODE="${MEMBERSHIP_RESPONSE:(-3)}"
  MEMBERSHIP_DATA="${MEMBERSHIP_RESPONSE::${#MEMBERSHIP_RESPONSE}-4}"

  if [[ "$MEMBERSHIP_RESPONSE_CODE" != "200" ]]; then
    echo "Error getting Membership for Org: ${ORG_NAME}"
    echo "${MEMBERSHIP_DATA}"
    exit 1
  else
    Debug "Org Membership Response:"
    DebugJQ "${MEMBERSHIP_DATA}"

    MEMBERSHIP_STATUS=$(echo "${MEMBERSHIP_DATA}" | jq -r '.role')
    MEMBERSHIP_STATUS="admin"
    if [[ ${MEMBERSHIP_STATUS} = "admin" ]]; then
      Debug "You are an owner. Getting Repo Stats"
    else
      echo "You are not an owner of org: ${ORG_NAME}"
      echo "cannot grab all needed information without access!"
      exit 1
    fi
  fi
}
################################################################################
#### Function GetOrgsFromFile ##################################################
GetOrgsFromFile()
{
  # shellcheck disable=SC2034
  # Unused variables left for readability
  while IFS=, read -r id created_at login email admin_ct member_ct team_ct repo_ct sfa_required
  do
    ORG_NAME=${login}

    echo "Checking access to org: ${ORG_NAME}"

    ######################
    # Check Admin Rights #
    ######################
    CheckAdminRights "${ORG_NAME}"
    #############################################
    # Check the API limit remaining for GraphQL #
    #############################################
    CheckAPILimit
    ######################
    # Get repos from Org #
    ######################
    GetRepos
    ######################
    # Get the teams info #
    ######################
    if [[ ${ANALYZE_TEAMS} -eq 1 ]]; then
      GetTeams
    fi
  done < "${INPUT_FILE_NAME}"
}
################################################################################
#### Function CheckAPILimit ####################################################
CheckAPILimit()
{
  ##############################################################
  # Check what is remaining, and if 0, we need to sleep it off #
  ##############################################################
  API_REMAINING_CMD=$(curl -s -X GET \
    --url "${GITHUB_URL}/rate_limit" \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    |  jq -r '.resources.graphql.remaining' 2>&1)

  #######################
  # Load the error code #
  #######################
  ERROR_CODE=$?

  ##############################
  # Check the shell for errors #
  ##############################
  if [ "${ERROR_CODE}" -ne 0 ]; then
    echo  "ERROR! Failed to get valid response back from GitHub API!"
    echo "ERROR:[${API_REMAINING_CMD}]"
    exit 1
  fi

  ##########################################
  # Check to see if we have API calls left #
  ##########################################
  if [ "${API_REMAINING_CMD}" -eq 0 ]; then
    # Increment the sleep counter
    ((SLEEP_COUNTER++))
    # Warn the user
    echo "WARN! We have run out of GrahpQL calls and need to sleep!"
    echo "Sleeping for ${SLEEP} seconds before next check"
    # Check if we have slept enough
    if [ "${SLEEP_COUNTER}" -gt "${SLEEP_RETRY_COUNT}" ]; then
      # We have been doing this too long
      echo "ERROR! We have tried to wait for:[$SLEEP_RETRY_COUNT] attempts!"
      echo "ERROR! We only sleep for:[${SLEEP_COUNTER}] attempts!"
      echo "Bailing out!"
      exit 1
    else
      # Get some sleep...
      sleep "${SLEEP}"
    fi
  else
    echo "[${API_REMAINING_CMD}] API attempts remaining..."
  fi
}
################################################################################
#### Function GetRepos #########################################################
GetRepos()
{
  ##############################
  # Grab repos from the system #
  ##############################
  function generate_graphql_data()
  {
    if [[ "${VERSION}" == "cloud" || ${VERSION:2:2} -ge 17 ]]; then
      cat <<EOF
  {
  "query":"query { organization(login: \"${ORG_NAME}\") { repositories(first:${REPO_PAGE_SIZE}${REPO_NEXT_PAGE}) { totalDiskUsage pageInfo { hasPreviousPage hasNextPage hasPreviousPage endCursor } nodes { owner { login } name nameWithOwner diskUsage isEmpty pushedAt updatedAt isFork collaborators(first:1) { totalCount } branchProtectionRules(first:1) { totalCount } pullRequests(first:${REPO_PAGE_SIZE}) { totalCount pageInfo { hasNextPage endCursor } nodes { number commits(first:1){ totalCount } timeline(first:1) { totalCount } comments(first:1) { totalCount } reviews(first:${REPO_PAGE_SIZE}) { totalCount pageInfo { hasNextPage endCursor } nodes { comments(first:1) { totalCount } } } } } milestones(first:1) { totalCount } commitComments(first:1) { totalCount } issues(first:${REPO_PAGE_SIZE}) { totalCount pageInfo { hasNextPage endCursor } nodes { timeline(first:1) { totalCount } comments(first:1) { totalCount } } } releases(first:1) { totalCount } projects(first:1) { totalCount } } } } }"
  }
EOF
  else
    cat <<EOF
  {
  "query":"query { organization(login: \"${ORG_NAME}\") { repositories(first:${REPO_PAGE_SIZE}${REPO_NEXT_PAGE}) { totalDiskUsage pageInfo { hasPreviousPage hasNextPage hasPreviousPage endCursor } nodes { owner { login } name nameWithOwner diskUsage isEmpty pushedAt updatedAt isFork collaborators(first:1) { totalCount } protectedBranches(first:1) { totalCount } pullRequests(first:${REPO_PAGE_SIZE}) { totalCount pageInfo { hasNextPage endCursor } nodes { number commits(first:1){ totalCount } timeline(first:1) { totalCount } comments(first:1) { totalCount } reviews(first:${REPO_PAGE_SIZE}) { totalCount pageInfo { hasNextPage endCursor } nodes { comments(first:1) { totalCount } } } } } milestones(first:1) { totalCount } commitComments(first:1) { totalCount } issues(first:${REPO_PAGE_SIZE}) { totalCount pageInfo { hasNextPage endCursor } nodes { timeline(first:1) { totalCount } comments(first:1) { totalCount } } } releases(first:1) { totalCount } projects(first:1) { totalCount } } } } }"
  }
EOF
  fi
  }

  Debug "Getting repos"
  Debug "curl -kw '%{http_code}' -s -X POST -H \"authorization: Bearer ${GITHUB_TOKEN}\" -H \"content-type: application/json\" \
  --data \"$(generate_graphql_data)\" \
  \"${GRAPHQL_URL}\""

  #############
  # Get repos #
  #############
  REPO_RESPONSE=$(curl -kw '%{http_code}' -s -X POST -H "authorization: Bearer ${GITHUB_TOKEN}" -H "content-type: application/json" \
  --data "$(generate_graphql_data)" \
  "${GRAPHQL_URL}")

  REPO_RESPONSE_CODE="${REPO_RESPONSE:(-3)}"
  DATA_BLOCK="${REPO_RESPONSE::${#REPO_RESPONSE}-4}"

  if [[ "$REPO_RESPONSE_CODE" != "200" ]]; then
    echo "Error getting Repos for Org: ${ORG_NAME}"
    echo "${DATA_BLOCK}"
  else
    Debug "DEBUG --- REPO DATA BLOCK:"
    DebugJQ "${DATA_BLOCK}"

    ERROR_MESSAGE=$(echo "${DATA_BLOCK}" | jq -r '.errors[]?')

    if [[ -n "${ERROR_MESSAGE}" ]]; then
      echo "ERROR --- Errors occurred while retrieving repos for org: ${ORG_NAME}"
      echo "${ERROR_MESSAGE}" | jq '.'
      echo "REPOS:"
      echo "${DATA_BLOCK}" | jq '.data.organization.repositories.nodes[].name'
    fi

    ##########################
    # Get the Next Page Flag #
    ##########################
    HAS_NEXT_PAGE=$(echo "${DATA_BLOCK}" | jq -r '.data.organization.repositories.pageInfo.hasNextPage')

    ##############################
    # Get the Current End Cursor #
    ##############################
    REPO_NEXT_PAGE=', after: \"'$(echo "${DATA_BLOCK}" | jq -r '.data.organization.repositories.pageInfo.endCursor')'\"'

    #############################################
    # Parse all the repo data out of data block #
    #############################################
    ParseRepoData "${DATA_BLOCK}"

    ########################################
    # See if we need to loop for more data #
    ########################################
    if [ "${HAS_NEXT_PAGE}" == "false" ]; then
      # We have all the data, we can move on
      echo "Gathered all repositories for org: ${ORG_NAME}"
      REPO_NEXT_PAGE=""
    elif [ "${HAS_NEXT_PAGE}" == "true" ]; then
      # We need to loop through GitHub to get all repos
      Debug "More pages of repos, gathering next batch"
      #############################################
      # Check the API limit remaining for GraphQL #
      #############################################
      CheckAPILimit
      #######################################
      # Call GetRepos again with new cursor #
      #######################################
      GetRepos
    else
      # Failing to get this value means we didnt get a good response back from GitHub
      # And it could be bad input from user, not enough access, or a bad token
      # Fail out and have user validate the info
      echo ""
      echo "######################################################"
      echo "ERROR! Failed response back from GitHub on org: ${ORG_NAME}!"
      echo "Please validate your PAT, Organization, and access levels!"
      echo "######################################################"
    fi
  fi
}
################################################################################
#### Function ParseRepoData ####################################################
ParseRepoData()
{
  ##########################
  # Pull in the data block #
  ##########################
  PARSE_DATA=$1

  REPOS=$(echo "${PARSE_DATA}" | jq -r '.data.organization.repositories.nodes')
  for REPO in $(echo "${REPOS}" | jq -r '.[] | @base64'); do
    _jq() {
    echo "${REPO}" | base64 --decode | jq -r "${1}"
    }

    OWNER=$(_jq '.owner.login' | tr '[:upper:]' '[:lower:]')
    REPO_NAME=$(_jq '.name' | tr '[:upper:]' '[:lower:]')

    #################################################################
    # Need to check if this repo has already been parsed in the doc #
    #################################################################
    grep "${OWNER},${REPO_NAME}," "${OUTPUT_FILE_NAME}" >/dev/null 2>&1

    #######################
    # Load the error code #
    #######################
    ERROR_CODE=$?

    ##############################
    # Check the shell for errors #
    ##############################
    if [ ${ERROR_CODE} -eq 0 ]; then
      # Found this in the csv already
      echo "Repo:[${OWNER}/${REPO_NAME}] has previously been analyzed, moving on..."
    else
      # Need to run analysis
      echo "Analyzing Repo: ${REPO_NAME}"

      REPO_SIZE_KB=$(_jq '.diskUsage')
      REPO_SIZE=$(ConvertKBToMB "${REPO_SIZE_KB}")

      IS_EMPTY=$(_jq '.isEmpty')
      PUSHED_AT=$(_jq '.pushedAt')
      UPDATED_AT=$(_jq '.updatedAt')
      IS_FORK=$(_jq '.isFork')

      MILESTONE_CT=$(_jq '.milestones.totalCount')
      COLLABORATOR_CT=$(_jq '.collaborators.totalCount')
      PR_CT=$(_jq '.pullRequests.totalCount')
      ISSUE_CT=$(_jq '.issues.totalCount')
      RELEASE_CT=$(_jq '.releases.totalCount')
      COMMIT_COMMENT_CT=$(_jq '.commitComments.totalCount')
      PROJECT_CT=$(_jq '.projects.totalCount')

      if [[ "${VERSION}" == "cloud" || ${VERSION:2:2} -ge 17 ]]; then
        PROTECTED_BRANCH_CT=$(_jq '.branchProtectionRules.totalCount')
      else
        PROTECTED_BRANCH_CT=$(_jq '.protectedBranches.totalCount')
      fi

      ISSUE_EVENT_CT=0
      ISSUE_COMMENT_CT=0
      PR_REVIEW_CT=0
      PR_REVIEW_COMMENT_CT=0

      ##################
      # Analyze Issues #
      ##################
      if [[ $ISSUE_CT -ne 0 ]]; then
        AnalyzeIssues "${REPO}"
      fi

      #########################
      # Analyze Pull Requests #
      #########################
      if [[ $PR_CT -ne 0 ]]; then
        AnalyzePullRequests "${REPO}"
      fi

      ###########################
      # Build the output string #
      ###########################
      RECORD_CT=$((COLLABORATOR_CT + PROTECTED_BRANCH_CT + PR_REVIEW_CT + MILESTONE_CT + ISSUE_CT + PR_CT + PR_REVIEW_COMMENT_CT + COMMIT_COMMENT_CT + ISSUE_COMMENT_CT + ISSUE_EVENT_CT + RELEASE_CT + PROJECT_CT))

      ####################################
      # Get if this is a migration issue #
      ####################################
      MIGRATION_ISSUE=$(MarkMigrationIssues "${REPO_SIZE}" "${RECORD_CT}")
      if [ "${MIGRATION_ISSUE}" -eq 0 ]; then
        MIGRATION_ISSUE="TRUE"
      else
        MIGRATION_ISSUE="FALSE"
      fi
      ########################
      # Write it to the file #
      ########################
      echo "${ORG_NAME},${REPO_NAME},${IS_EMPTY},${PUSHED_AT},${UPDATED_AT},${IS_FORK},${REPO_SIZE},${RECORD_CT},${COLLABORATOR_CT},${PROTECTED_BRANCH_CT},${PR_REVIEW_CT},${MILESTONE_CT},${ISSUE_CT},${PR_CT},${PR_REVIEW_COMMENT_CT},${COMMIT_COMMENT_CT},${ISSUE_COMMENT_CT},${ISSUE_EVENT_CT},${RELEASE_CT},${PROJECT_CT},${GHE_URL}/${ORG_NAME}/${REPO_NAME},${MIGRATION_ISSUE}" >> "${OUTPUT_FILE_NAME}"

      #######################
      # Load the error code #
      #######################
      ERROR_CODE=$?

      ##############################
      # Check the shell for errors #
      ##############################
      if [ $ERROR_CODE -ne 0 ]; then
        echo "ERROR! Failed to write output to file:[${OUTPUT_FILE_NAME}]"
        exit 1
      fi

      ##############################
      # Check to anazyle conflicts #
      ##############################
      if [[ ${ANALYZE_CONFLICTS} -eq 1 ]]; then
        ### Check the repository name against array of all previously-processed repositories
        REPO_INDEX=-1

        for ITEM in "${!REPO_LIST[@]}"; do
          if [[ "${REPO_LIST[${ITEM}]}" = "${REPO_NAME}" ]]; then
            REPO_INDEX=${i}
          fi
        done

        ### If this is the first instance of that repository name, add it to the list and add the group name to its array
        if [[ ${REPO_INDEX} -eq -1 ]]; then
          Debug "Repo: ${REPO_NAME} is unique. Adding to the list!"
          REPO_LIST+=( "${REPO_NAME}" )
          GROUP_LIST[(( ${#REPO_LIST[@]} - 1 ))]=${ORG_NAME}
          NUMBER_OF_CONFLICTS[(( ${#REPO_LIST[@]} - 1 ))]=1
        else
          echo "Repo: ${REPO_NAME} already exists. Adding ${ORG_NAME} to the conflict list"
          GROUP_LIST[${REPO_INDEX}]+=" ${ORG_NAME}"
          (( NUMBER_OF_CONFLICTS[REPO_INDEX]++ ))
        fi
      fi
    fi
  done
}
################################################################################
#### Function AnalyzeIssues ####################################################
AnalyzeIssues()
{
  THIS_REPO=$1

  _pr_issue_jq() {
   echo "${THIS_REPO}" | base64 --decode | jq -r "${1}"
  }

  ISSUES=$(_pr_issue_jq '.issues.nodes')

  ##########################
  # Get the Next Page Flag #
  ##########################
  HAS_NEXT_ISSUES_PAGE=$(_pr_issue_jq '.issues.pageInfo.hasNextPage')

  ##############################
  # Get the Current End Cursor #
  ##############################
  ISSUE_NEXT_PAGE=', after: \"'$(_pr_issue_jq  '.issues.pageInfo.endCursor')'\"'

  for ISSUE in $(echo "${ISSUES}" | jq -r '.[] | @base64'); do
    _issue_jq() {
 echo "${ISSUE}" | base64 --decode | jq -r "${1}"
    }

    EVENT_CT=$(_issue_jq '.timeline.totalCount')
    COMMENT_CT=$(_issue_jq '.comments.totalCount')
    ISSUE_EVENT_CT=$((ISSUE_EVENT_CT + EVENT_CT - COMMENT_CT))
    ISSUE_COMMENT_CT=$((ISSUE_COMMENT_CT + COMMENT_CT))
  done

  ########################################
  # See if we need to loop for more data #
  ########################################
  if [ "$HAS_NEXT_ISSUES_PAGE" == "false" ]; then
    # We have all the data, we can move on
    Debug "Gathered all issues from Repo: ${REPO_NAME}"
    ISSUE_NEXT_PAGE=""
  elif [ "$HAS_NEXT_ISSUES_PAGE" == "true" ]; then
    # We need to loop through GitHub to get all repos
    Debug "More pages of issues, gathering next batch"

    ######################################
    # Call GetNextIssues with new cursor #
    ######################################
    GetNextIssues
  else
    # Failing to get this value means we didnt get a good response back from GitHub
    # And it could be bad input from user, not enough access, or a bad token
    # Fail out and have user validate the info
    echo ""
    echo "######################################################"
    echo "ERROR! Failed response back from GitHub!"
    echo "Please validate your PAT, Organization, and access levels!"
    echo "######################################################"
    exit 1
  fi
}
################################################################################
#### Function GetNextIssues ####################################################
GetNextIssues()
{
  #############################
  # Generate the graphql data #
  #############################
  function generate_graphql_data()
  {
  cat <<EOF
    {
  "query":"{  repository(owner:\"${OWNER}\" name:\"${REPO_NAME}\") { owner { login } name issues(first:${EXTRA_PAGE_SIZE}${ISSUE_NEXT_PAGE}) { totalCount pageInfo { hasNextPage endCursor } nodes { timeline(first: 1) { totalCount } comments(first: 1) { totalCount } } } }}"
    }
EOF
  }

  ISSUE_RESPONSE=$(curl -kw '%{http_code}' -s -X POST -H "authorization: Bearer ${GITHUB_TOKEN}" -H "content-type: application/json" \
  --data "$(generate_graphql_data)" \
  "${GRAPHQL_URL}")

  ISSUE_RESPONSE_CODE="${ISSUE_RESPONSE:(-3)}"
  ISSUE_DATA="${ISSUE_RESPONSE::${#ISSUE_RESPONSE}-4}"

  if [[ "${ISSUE_RESPONSE_CODE}" != "200" ]]; then
    echo "Error getting more Issues for Repo: ${OWNER}/${REPO_NAME}"
    echo "${ISSUE_DATA}"
  else

    Debug "ISSUE DATA BLOCK:"
    DebugJQ "${ISSUE_DATA}"

    ERROR_MESSAGE=$(echo "${ISSUE_DATA}" | jq -r '.errors[]?')

    if [[ -n "${ERROR_MESSAGE}" ]]; then
      echo "ERROR --- Errors occurred while retrieving issues for repo: ${REPO_NAME}"
      echo "${ERROR_MESSAGE}" | jq '.'
    fi

    ISSUE_REPO=$(echo "${ISSUE_DATA}" | jq -r '.data.repository | @base64')

    ######################
    # Analyze the issues #
    ######################
    AnalyzeIssues "${ISSUE_REPO}"
  fi
}
################################################################################
#### Function AnalyzePullRequests ##############################################
AnalyzePullRequests()
{
  PR_REPO=$1

  _pr_repo_jq() {
   echo "${PR_REPO}" | base64 --decode | jq -r "${1}"
  }

  Debug "Analyzing Pull Requests for: ${REPO_NAME}"

  PRS=$(_pr_repo_jq '.pullRequests.nodes')

  ##########################
  # Get the Next Page Flag #
  ##########################
  HAS_NEXT_PRS_PAGE=$(_pr_repo_jq '.pullRequests.pageInfo.hasNextPage')

  ##############################
  # Get the Current End Cursor #
  ##############################
  PR_NEXT_PAGE=', after: \"'$(_pr_repo_jq  '.pullRequests.pageInfo.endCursor')'\"'

  for PR in $(echo "${PRS}" | jq -r '.[] | @base64'); do
    _pr_jq() {
 echo "${PR}" | base64 --decode | jq -r "${1}"
    }

    PR_NUMBER=$(_pr_jq '.number')

    EVENT_CT=$(_pr_jq '.timeline.totalCount')
    COMMENT_CT=$(_pr_jq '.comments.totalCount')
    REVIEW_CT=$(_pr_jq '.reviews.totalCount')
    COMMIT_CT=$(_pr_jq '.commits.totalCount')

    if [[ ${REVIEW_CT} -ne 0 ]]; then
      AnalyzeReviews "${PR}"
    fi

    ISSUE_EVENT_CT=$((ISSUE_EVENT_CT + EVENT_CT - COMMENT_CT - COMMIT_CT))
    ISSUE_COMMENT_CT=$((ISSUE_COMMENT_CT + COMMENT_CT))
    PR_REVIEW_CT=$((PR_REVIEW_CT + REVIEW_CT))
  done

  ########################################
  # See if we need to loop for more data #
  ########################################
  if [ "${HAS_NEXT_PRS_PAGE}" == "false" ]; then
    # We have all the data, we can move on
    Debug "Gathered all pull requests from Repo: ${REPO_NAME}"
    PR_NEXT_PAGE=""
  elif [ "$HAS_NEXT_PRS_PAGE" == "true" ]; then
    # We need to loop through GitHub to get all pull requests
    Debug "More pages of pull requests, gathering next batch"

    #########################
    # Get the pull requests #
    #########################
    GetNextPullRequests
  else
    # Failing to get this value means we didnt get a good response back from GitHub
    # And it could be bad input from user, not enough access, or a bad token
    # Fail out and have user validate the info
    echo ""
    echo "######################################################"
    echo "ERROR! Failed response back from GitHub!"
    echo "Please validate your PAT, Organization, and access levels!"
    echo "######################################################"
    exit 1
  fi
}
################################################################################
#### Function GetNextPullRequests ##############################################
GetNextPullRequests()
{
  function generate_graphql_data()
  {
  cat <<EOF
    {
  "query":"{  repository(owner:\"${OWNER}\" name:\"${REPO_NAME}\") {  owner {  login  }  name   pullRequests(first:${EXTRA_PAGE_SIZE}${PR_NEXT_PAGE}) {  totalCount  pageInfo {    hasNextPage  endCursor  }  nodes { number  commits(first:1){  totalCount   }    timeline(first: 1) {  totalCount    }    comments(first: 1) {  totalCount    }    reviews(first: ${EXTRA_PAGE_SIZE}) {  totalCount  pageInfo {    hasNextPage  endCursor  }    nodes {  comments(first: 1) {    totalCount  }  }   }  }  }  }}"
    }
EOF
  }

  Debug "Getting pull requests"
  Debug "curl -kw '%{http_code}' -s -X POST -H \"authorization: Bearer ${GITHUB_TOKEN}\" -H \"content-type: application/json\" \
    --data \"$(generate_graphql_data)\" \
    \"${GRAPHQL_URL}\""

  PR_RESPONSE=$(curl -kw '%{http_code}' -s -X POST -H "authorization: Bearer ${GITHUB_TOKEN}" -H "content-type: application/json" \
  --data "$(generate_graphql_data)" \
  "${GRAPHQL_URL}")

  PR_RESPONSE_CODE="${PR_RESPONSE:(-3)}"
  PR_DATA="${PR_RESPONSE::${#PR_RESPONSE}-4}"

  if [[ "$PR_RESPONSE_CODE" != "200" ]]; then
    echo "Error getting more Pull Requests for Repo: ${OWNER}/${REPO_NAME}"
    echo "${PR_DATA}"
  else

    Debug "PULL_REQUEST DATA BLOCK:"
    DebugJQ "${PR_DATA}"

    ERROR_MESSAGE=$(echo "${PR_DATA}" | jq -r '.errors[]?')

    if [[ -n "${ERROR_MESSAGE}" ]]; then
      echo "ERROR --- Errors occurred while retrieving pull requests for repo: ${REPO_NAME}"
      echo "${ERROR_MESSAGE}" | jq '.'
    fi

    PR_REPO=$(echo "${PR_DATA}" | jq -r '.data.repository | @base64')

    AnalyzePullRequests "${PR_REPO}"
  fi
}
################################################################################
#### Function AnalyzeReviews ###################################################
AnalyzeReviews()
{
  REVIEW_PR=$1

  _review_jq() {
   echo "${REVIEW_PR}" | base64 --decode | jq -r "${1}"
  }

  REVIEWS=$(_review_jq '.reviews.nodes')

  ##########################
  # Get the Next Page Flag #
  ##########################
  HAS_NEXT_REVIEWS_PAGE=$(_review_jq '.reviews.pageInfo.hasNextPage')

  ##############################
  # Get the Current End Cursor #
  ##############################
  REVIEW_NEXT_PAGE=', after: \"'$(_review_jq  '.reviews.pageInfo.endCursor')'\"'
  PR_NUMBER=$(_review_jq '.number')

  Debug "Analyzing Pull Request Reviews for: ${REPO_NAME} PR: ${PR_NUMBER}"

  for REVIEW in $(echo "${REVIEWS}" | jq -r '.[] | @base64'); do
    _pr_jq() {
 echo "${REVIEW}" | base64 --decode | jq -r "${1}"
    }

    REVIEW_COMMENT_CT=$(_pr_jq '.comments.totalCount')

    PR_REVIEW_COMMENT_CT=$((PR_REVIEW_COMMENT_CT + REVIEW_COMMENT_CT))
  done

  ########################################
  # See if we need to loop for more data #
  ########################################
  if [ "${HAS_NEXT_REVIEWS_PAGE}" == "false" ]; then
    # We have all the data, we can move on
    Debug "Gathered all reviews from PR"
    REVIEW_NEXT_PAGE=""
  elif [ "${HAS_NEXT_REVIEWS_PAGE}" == "true" ]; then
    # We need to loop through GitHub to get all pull requests
    Debug "More pages of reviews. Gathering next batch."

    #######################################
    # Call GetNextReviews with new cursor #
    #######################################
    GetNextReviews
  else
    # Failing to get this value means we didnt get a good response back from GitHub
    # And it could be bad input from user, not enough access, or a bad token
    # Fail out and have user validate the info
    echo ""
    echo "######################################################"
    echo "ERROR! Failed response back from GitHub!"
    echo "Please validate your PAT, Organization, and access levels!"
    echo "######################################################"
    exit 1
  fi
}
################################################################################
#### Function GetNextReviews ###################################################
GetNextReviews()
{
  #########################
  # Generate graphql data #
  #########################
  function generate_graphql_data()
  {
  cat <<EOF
    {
  "query":"{ repository(owner:\"${OWNER}\" name:\"${REPO_NAME}\") { owner { login } name pullRequest(number:${PR_NUMBER}) { commits(first:1){  totalCount   }    timeline(first: 1) {  totalCount    }    comments(first: 1) {  totalCount    }    reviews(first: ${EXTRA_PAGE_SIZE}${REVIEW_NEXT_PAGE}) { totalCount pageInfo { hasNextPage endCursor } nodes { comments(first: 1) {    totalCount } } } } }}"
    }
EOF
  }

  ##################
  # Get PR Reviews #
  ##################
  Debug "Getting pull request reviews"
  Debug "curl -kw '%{http_code}' -s -X POST -H \"authorization: Bearer ${GITHUB_TOKEN}\" -H \"content-type: application/json\" \
  --data \"$(generate_graphql_data)\" \
  \"${GRAPHQL_URL}\""

  REVIEW_RESPONSE=$(curl -kw '%{http_code}' -s -X POST -H "authorization: Bearer ${GITHUB_TOKEN}" -H "content-type: application/json" \
  --data "$(generate_graphql_data)" \
  "${GRAPHQL_URL}")

  REVIEW_RESPONSE_CODE="${REVIEW_RESPONSE:(-3)}"
  REVIEW_DATA="${REVIEW_RESPONSE::${#REVIEW_RESPONSE}-4}"

  ######################
  # Look for PR errors #
  ######################
  if [[ "$REVIEW_RESPONSE_CODE" != "200" ]]; then
    echo "Error getting more PR Reviews for Repo: ${OWNER}/${REPO_NAME} and PR: ${PR_NUMBER}"
    echo "${REVIEW_DATA}"
  else

    Debug "REVIEW DATA BLOCK:"
    DebugJQ "${REVIEW_DATA}"

    ##################
    # Get any errors #
    ##################
    ERROR_MESSAGE=$(echo "${REVIEW_DATA}" | jq -r '.errors[]?')

    ####################
    # Check for errors #
    ####################
    if [[ -n "${ERROR_MESSAGE}" ]]; then
      echo "ERROR --- Errors occurred while retrieving pr reviews for repo: ${REPO_NAME} and pr: ${PR_NUMBER}"
      echo "${ERROR_MESSAGE}" | jq '.'
    fi

    #####################
    # Get the Review PR #
    #####################
    REVIEW_PR=$(echo "${REVIEW_DATA}" | jq -r '.data.repository.pullRequest | @base64')

    ######################
    # Analyze the review #
    ######################
    AnalyzeReviews "${REVIEW_PR}"
  fi
}
################################################################################
#### Function GetTeams #########################################################
GetTeams()
{
  function generate_graphql_data()
  {
  cat <<EOF
    {
  "query":"query {   organization(login:\"${OWNER}\") {    teams(first: ${REPO_PAGE_SIZE}${TEAM_NEXT_PAGE}) {  pageInfo{  hasNextPage  endCursor  } nodes { slug } } } }"
    }
EOF
  }

  Debug "curl -kw '%{http_code}' -s -X POST -H \"authorization: Bearer ${GITHUB_TOKEN}\" -H \"content-type: application/json\" \
  --data \"$(generate_graphql_data)\" \
  \"${GRAPHQL_URL}\""

  TEAM_RESPONSE=$(curl -kw '%{http_code}' -s -X POST -H "authorization: Bearer ${GITHUB_TOKEN}" -H "content-type: application/json" \
  --data "$(generate_graphql_data)" \
  "${GRAPHQL_URL}")

  TEAM_RESPONSE_CODE="${TEAM_RESPONSE:(-3)}"
  TEAM_DATA="${TEAM_RESPONSE::${#TEAM_RESPONSE}-4}"

  if [[ "$TEAM_RESPONSE_CODE" != "200" ]]; then
    echo "Error getting Teams for Org: ${OWNER}"
    echo "${TEAM_DATA}"
  else
    Debug "TEAM DATA BLOCK:"
    DebugJQ "${TEAM_DATA}"

    ERROR_MESSAGE=$(echo "$TEAM_DATA" | jq -r '.errors[]?')

    if [[ -n "${ERROR_MESSAGE}" ]]; then
      echo "ERROR --- Errors occurred while retrieving teams for org: ${OWNER}"
      echo "${ERROR_MESSAGE}" | jq '.'
    fi

    TEAMS=$(echo "${TEAM_DATA}" | jq '.data.organization.teams.nodes')


    ##########################
    # Get the Next Page Flag #
    ##########################
    HAS_NEXT_TEAM_PAGE=$(echo "${TEAM_DATA}" | jq -r '.data.organization.teams.pageInfo.hasNextPage')

    ##############################
    # Get the Current End Cursor #
    ##############################
    TEAM_NEXT_PAGE=', after: \"'$(echo "${TEAM_DATA}" | jq -r '.data.organization.teams.pageInfo.endCursor')'\"'

    for TEAM in $(echo "${TEAMS}" | jq -r '.[] | @base64'); do
      _team_jq() {
        echo "${TEAM}" | base64 --decode | jq -r "${1}"
      }

      TEAM_NAME=$(_team_jq '.slug')

      ### Check the team name against array of all previously-processed teams
      TEAM_INDEX=-1

      for i in "${!TEAM_LIST[@]}"; do
      if [[ "${TEAM_LIST[$i]}" = "${TEAM_NAME}" ]]; then
        TEAM_INDEX=${i}
      fi
      done

      ### If this is the first instance of that team name, add it to the list and add the org name to its array
      if [[ ${TEAM_INDEX} -eq -1 ]]; then
        Debug "Team: ${TEAM_NAME} is unique. Adding to the list!"
        TEAM_LIST+=( "${TEAM_NAME}" )
        TEAM_ORG_LIST[(( ${#TEAM_LIST[@]} - 1 ))]=${ORG_NAME}
        NUMBER_OF_TEAM_CONFLICTS[(( ${#TEAM_LIST[@]} - 1 ))]=1
      else
        Debug "Team: $TEAM_NAME already exists. Adding ${ORG_NAME} to the conflict list"
        TEAM_ORG_LIST[${TEAM_INDEX}]+=" ${ORG_NAME}"
        (( NUMBER_OF_TEAM_CONFLICTS[TEAM_INDEX]++ ))
      fi
    done

    ########################################
    # See if we need to loop for more data #
    ########################################
    if [ "${HAS_NEXT_TEAM_PAGE}" == "false" ]; then
      # We have all the data, we can move on
      Debug "Gathered all teams from PR"
      TEAM_NEXT_PAGE=""
    elif [ "${HAS_NEXT_TEAM_PAGE}" == "true" ]; then
      # We need to loop through GitHub to get all teams
      Debug "More pages of teams. Gathering next batch."

      #######################################
      # Call GetTeams with new cursor #
      #######################################
      GetTeams
    else
      # Failing to get this value means we didnt get a good response back from GitHub
      # And it could be bad input from user, not enough access, or a bad token
      # Fail out and have user validate the info
      echo ""
      echo "######################################################"
      echo "ERROR! Failed response back from GitHub!"
      echo "Please validate your PAT, Organization, and access levels!"
      echo "######################################################"
      exit 1
    fi
  fi
}
################################################################################
#### Function MarkMigrationIssues ##############################################
MarkMigrationIssues()
{
  # Need to read the output files, and total the issues and see
  # if over 60k objects or repo is over 2gb

  ##############
  # Read Input #
  ##############
  REPO_SIZE="$1"
  RECORD_COUNT="$2"

  # Check if more than 60k objects
  if [ "${RECORD_COUNT}" -ge 60000 ] || [ "${REPO_SIZE}" -gt 1500 ]; then
    echo "0"
    return 0
  else
    echo "1"
    return 1
  fi
}
################################################################################
#### Function ReportConflicts ##################################################
ReportConflicts()
{
  if [[ ${ANALYZE_CONFLICTS} -eq 1 ]]; then
    for (( i=0; i<${#REPO_LIST[@]}; i++)) do
      if (( ${NUMBER_OF_CONFLICTS[$i]} > 1 )); then
        echo "${NUMBER_OF_CONFLICTS[$i]},${REPO_LIST[$i]},${GROUP_LIST[$i]}" >> "${REPO_CONFLICTS_OUTPUT_FILE}"
      fi
    done
  fi

  ##########################
  # Check to analyze teams #
  ##########################
  if [[ ${ANALYZE_TEAMS} -eq 1 ]]; then
    for (( i=0; i<${#TEAM_LIST[@]}; i++)) do
      if (( ${NUMBER_OF_TEAM_CONFLICTS[$i]} > 1 )); then
        echo "${NUMBER_OF_TEAM_CONFLICTS[$i]},${TEAM_LIST[$i]},${TEAM_ORG_LIST[$i]}" >> "${TEAM_CONFLICTS_OUTPUT_FILE}"
      fi
    done
  fi
}
################################################################################
#### Function ConvertKBToMB ####################################################
ConvertKBToMB()
{
  ####################################
  # Value that needs to be converted #
  ####################################
  VALUE=$1

  ##############################
  # Validate that its a number #
  ##############################
  REGEX='^[0-9]+$'
  if ! [[ ${VALUE} =~ ${REGEX} ]] ; then
    echo "ERROR! Not a number:[${VALUE}]"
    exit 1
  fi

  #################
  # Convert to MB #
  #################
  SIZEINMB=$((VALUE/1024))
  echo "${SIZEINMB}"

  ####################
  # Return the value #
  ####################
  return ${SIZEINMB}
}
################################################################################
#### Function ValidateJQ #######################################################
ValidateJQ()
{
  # Need to validate the machine has jq installed as we use it to do the parsing
  # of all the json returns from GitHub

  if ! jq --version &>/dev/null
  then
    echo "Failed to find jq in the path!"
    echo "If this is a Mac, run command: brew install jq"
    echo "If this is Debian, run command: sudo apt install jq"
    echo "If this is Centos, run command: yum install jq"
    echo "Once installed, please run this script again."
    exit 1
  fi
}
################################################################################
############################## MAIN ############################################
################################################################################

##########
# Header #
##########
Header

#########################
# Validate JQ installed #
#########################
ValidateJQ

#################
# Generate File #
#################
GenerateFiles

########################
# Check the input file #
########################
if [[ -z ${INPUT_FILE_NAME} ]]; then
  ######################
  # Check Admin Rights #
  ######################
  CheckAdminRights "${ORG_NAME}"
  ###################
  # Get GitHub Data #
  ###################
  echo "------------------------------------------------------"
  echo "Getting repositories for org: ${ORG_NAME}"
  #############################################
  # Check the API limit remaining for GraphQL #
  #############################################
  CheckAPILimit
  #############
  # Get Repos #
  #############
  GetRepos
else
  ############
  # Get Orgs #
  ############
  GetOrgsFromFile
fi

########################
# Report all conflicts #
########################
ReportConflicts

##########
# Footer #
##########
Footer
