#!/usr/bin/python3

import subprocess
import shutil
import argparse
import git   ### pip3 install gitpython
from os import path, makedirs
import json



def Parser():
    parser = argparse.ArgumentParser()
    parser.add_argument('--sa', nargs=1, metavar='SA', help='Service account credentials file')
    parser.add_argument('--project', nargs=1, metavar='PROJECT', help='GCP Project ID')
    parser.add_argument('--database', nargs=1, metavar='DB_HOST', help='GCP Cloud SQL database connection string')
    parser.add_argument('--cmd', nargs=1, metavar='CMD', help='Either: new-deploy or deploy-app-engine')
    return parser


def create_directories():
    if not path.exists(base_dir + "/credentials"):
        makedirs(base_dir + "/credentials")
    if not path.exists(base_dir + "/variables"):
        makedirs(base_dir + "/variables")
    if not path.exists(base_dir + "/deployments"):
        makedirs(base_dir + "/deployments")
    if not path.exists(base_dir + "/logs"):
        makedirs(base_dir + "/logs")



def clone_repos(path):
    shutil.rmtree(path, ignore_errors=True)
    subprocess.call(["mkdir", path])
    git.Git(path).clone('git@bitbucket.org:evenito/platform-auth-gip.git', ['--single-branch','--branch=master'])
    print("Platform-auth-gip cloned....")
    git.Git(path).clone('git@bitbucket.org:evenito/platform-api.git', ['--single-branch','--branch=master'])
    print("Platform-api cloned....")
    git.Git(path).clone('git@bitbucket.org:evenito/platform-space-registry.git', ['--single-branch','--branch=master'])
    print("Platform-space-registry cloned....")



def generate_vars_file(project):
    credentials_path = base_dir + "/credentials/" + project + ".json"
    content = """{
      "credentials_file": "%s",
      "project_id": "%s",
      "app_engine_location": "europe-west6",

      "app_key": "IzET8cvs38llTP6s3HpdEiIqFbAG11toLYKopxFOj4L_2SOP",
      "app_name": "platform",
      "database_version": "POSTGRES_9_6",
      "database_instance_name": "platform-api",
      "database_name": "postgres",
      "database_tier": "db-f1-micro",
      "database_disk_size": "10",
      "database_user": "postgres",
      "database_pass": "CK616j1bAnR3FLcDfHFv",

      "firebase_app_id": "1:801061313259:web:404bd9426588db39f9fcae",
      "firebase_api_key": "AIzaSyAgvMkKEWKnbJLKqAzjcYnzupXy_CIR5AQ",
      "firebase_auth_domain": "firechat-256210.firebaseapp.com",
      "firebase_db": "https://firechat-256210.firebaseio.com",
      "firebase_proj-id": "firechat-256210",
      "firebase_storage_bucket": "firechat-256210.appspot.com",
      "firebase_msg_sender_id": "801061313259",
      "service_auth_url": "https://evenito-deploy.appspot.com"
    }
    """ % (credentials_path, project)

    vars_path = base_dir + "/variables/" + project + ".tfvars.json"
    with open(vars_path, 'w') as f:
        f.write(content)
    with open(credentials_path, 'w') as w:
        w.close()


def app_config(project, db_host):
    with open(base_dir + "/variables/" + project + ".tfvars.json", 'r') as c:
        data = c.read()
    config = json.loads(data)
    content = """
runtime: nodejs
env: flex
service: GCPSERVICE
automatic_scaling:
  min_num_instances: 1
  max_num_instances: 2
  cpu_utilization:
    target_utilization: 0.5
resources:
  cpu: 1
  memory_gb: 2
  disk_size_gb: 10
beta_settings:
  cloud_sql_instances: %s
env_variables:
  HOST: 0.0.0.0
  NODE_ENV: production
  APP_NAME: %s
  APP_URL: http://${HOST}:${PORT}
  CACHE_VIEWS: false
  APP_KEY: %s
  DB_CONNECTION: pg
  DB_HOST: /cloudsql/%s
  DB_PORT: 5432
  DB_USER: %s
  DB_PASSWORD: %s
  DB_DATABASE: %s
  HASH_DRIVER: bcrypt
  SESSION_DRIVER: cookie
  SERVICE_AUTH_URL: %s
  SPACE_URL: https://registry-dot-%s.appspot.com
  FIREBASE_APP_ID: %s
  FIREBASE_API_KEY: %s
  FIREBASE_AUTH_DOMAIN: %s
  FIREBASE_DB: %s
  FIREBASE_PROJECT_ID: %s
  FIREBASE_STORAGE_BUCKET: %s
  FIREBASE_MSG_SENDER_ID: %s
""" % (
        db_host, 
        config['app_name'], 
        config['app_key'], 
        db_host, 
        config['database_user'], 
        config['database_pass'], 
        config['database_name'], 
        config['service_auth_url'], 
        project,
        config['firebase_app_id'],
        config['firebase_api_key'],
        config['firebase_auth_domain'],
        config['firebase_db'],
        config['firebase_proj-id'],
        config['firebase_storage_bucket'],
        config['firebase_msg_sender_id'])
    
    api_config = base_dir + "/build/platform-api/app.yaml"
    auth_config = base_dir + "/build/platform-auth-gip/app.yaml"
    registry_config = base_dir + "/build/platform-space-registry/app.yaml"

    with open(api_config, 'w') as api:
        api.write(content)

    with open(auth_config, 'w') as auth:
        auth.write(content)

    with open(registry_config, 'w') as reg:
        reg.write(content)
    ### Backup app.yaml for the project
    with open(base_dir + "/deployments/" + project + "-deploy-app.yaml", 'w') as backup:
        backup.write(content)

    ### Change the GCP service name for each app   
    subprocess.check_output(["sed", "-i", "s/GCPSERVICE/api/", api_config])
    subprocess.check_output(["sed", "-i", "s/GCPSERVICE/default/", auth_config])
    subprocess.check_output(["sed", "-i", "s/GCPSERVICE/registry/", registry_config])
    



def deploy_to_app_engine(project, sa, db_host):
    clone_repos(base_dir + '/build')
    app_config(project, db_host)
    gcloud = shutil.which('gcloud')


    if gcloud != None:
        subprocess.check_output([gcloud, 'auth', 'activate-service-account', '--key-file', sa])

        print("Starting deployment of platform-auth....")
        subprocess.call([gcloud, 'app', 'deploy', '--project', project, '--quiet'], cwd=base_dir + "/build/platform-auth-gip")

        print("Starting deployment of platform-space-registry....")
        subprocess.call([gcloud, 'app', 'deploy', '--project', project, '--quiet'], cwd=base_dir + "/build/platform-space-registry")

        print("Starting deployment of platform-api....")
        subprocess.call([gcloud, 'app', 'deploy', '--project', project, '--quiet'], cwd=base_dir + "/build/platform-api")
    else:
        print("gcloud cli not found....")






parser = Parser()
args = parser.parse_args()

base_dir = path.dirname(path.realpath(__file__))

create_directories()


if args.cmd and args.project:
    project = args.project[0]
    cmd = args.cmd[0]

    terraform = shutil.which('terraform')
    if terraform == None:
        print("Terraform not found...")

    if cmd == 'new-deploy':
        log_dir = base_dir + "/logs/" + project
        variables = base_dir + "/variables/" + project + ".tfvars.json"
        if not path.exists(log_dir):
            makedirs(log_dir)
        if path.isfile(variables):
            subprocess.check_output([terraform, 'workspace', 'select', project ])
            with open(log_dir + "/terraform-apply.log", 'w') as terra_log:
                subprocess.call([terraform, 'apply', '-auto-approve', '-var-file', variables ], stdout=terra_log)
        else:
            subprocess.check_output([terraform, 'workspace', 'new', project ])
            generate_vars_file(project)
            print("Variables generated in: %s , please check and modify" % variables)
            print("Write your credentials in: credentials/%s.json" % project)

    elif cmd == 'deploy-app-engine':
        if args.sa and args.database and args.project:
            project = args.project[0]
            sa = args.sa[0]
            db_host = args.database[0]
            deploy_to_app_engine(project, sa, db_host)


