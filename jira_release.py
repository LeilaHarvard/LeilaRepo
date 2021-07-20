from atlassian import Jira
import sys
import logging
from datetime import datetime
import time
import os

jira = Jira(
    url='https://kvprodman.atlassian.net',
    username='jenkins@knowledgevision.com',
    password='U8dA3NrmQQIAtqHrCa7PA2E5')

JIRA_PROJECTS = ('PH', 'QU', 'THUN', 'OEC')
JIRA_RELEASE_NAME = 'release_{date}'.format(date=datetime.now().strftime('%Y%m%d'))

logging.root.setLevel(logging.INFO)

if os.path.exists("story_list_prepared.txt"):
    os.remove("story_list_prepared.txt")
if os.path.exists("story_list_tocheck.txt"):
    os.remove("story_list_tocheck.txt")

f_tocheck = open("story_list_tocheck.txt", "a")
f = open("story_list_prepared.txt", "a")

logging.info('Verification status of stories')
with open("story_list.txt", "r") as input_file:
    for story_name in input_file:
        stripped_story_name = story_name.strip()

        ISSUE_STATUS = jira.get_issue_status(stripped_story_name)

        if "Done" == ISSUE_STATUS:
            logging.info('Jira story {story} has status {status}'.format(story=stripped_story_name, status=ISSUE_STATUS))
            f.write('{story}\n'.format(story=stripped_story_name))
        else:
            logging.info('Jira story {story} has status {status}'.format(story=stripped_story_name, status=ISSUE_STATUS))   # need to add flow for processing not existing stories (it is failing currently)
            logging.error('The story must be in status "Done" to proceed')
            f_tocheck.write('{story}\n'.format(story=stripped_story_name))
            
f.close()
f_tocheck.close()

if jira is not None:
    for PROJECT in JIRA_PROJECTS:
        PROJECT_ID = jira.project(PROJECT)["id"]
        logging.info('Jira {project} project {version} fixed version creating...'.format(version=JIRA_RELEASE_NAME, project=PROJECT))
        now_data = datetime.now().isoformat()
        try:
            versions = jira.get_project_versions_paginated(PROJECT, start=None, limit=500, order_by=None, expand=None, query=None, status=None)

            # skip version creation in case this version already exists
            if versions and len(versions["values"]) > 1:
                break_flag = 0
                for value in versions["values"]:
                    logging.info("Release name: {release_name}\nRelease ID: {release_id}".format(release_name=value["name"], release_id=value["id"]))
                    # if JIRA_RELEASE_NAME == value["name"]:
                    #     logging.info('Removing release {release} with id {id} and project {project}'.format(release=JIRA_RELEASE_NAME, id=value["id"], project=PROJECT))
                    #     jira.delete_version(str(value["id"]))
                    #     break_flag = 1
                    #     time.sleep(5)
                    if JIRA_RELEASE_NAME == str(value["name"]):
                        logging.info('Version {} already exists, skipping creation'.format(str(value["name"])))
                        break_flag = 1
                        break
            if break_flag == 0:
              #  jira.add_version(PROJECT, PROJECT_ID, JIRA_RELEASE_NAME, is_archived=False, is_released=True)
                logging.info('Jira {name} fixed version created'.format(name=JIRA_RELEASE_NAME))
            else:
                break_flag = 0
        except Exception as e:
            logging.error('Jira {name} fixed version create failed'.format(name=JIRA_RELEASE_NAME))
            logging.error(e)
            sys.exit(1)

#with open("story_list_prepared.txt", "r") as input_file:
 #   for story_name in input_file:
 #       stripped_story_name = story_name.strip()
        
        # added current fixVersion to the stories
 #       fields = {
    #        'fixVersions': [{'name': JIRA_RELEASE_NAME}]
 #       }

  #      jira.update_issue_field(stripped_story_name, fields)
 #       logging.info("Jira fixVersion added to story {story}".format(story=stripped_story_name))
 #       time.sleep(1)