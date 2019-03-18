#!/bin/bash

# Author: Drikus van der Walt
# Description: Automation of codepipeline for a serverless application
# Date: 08/02/2019

#--- SETUP AND VARIABLES ---

REPONAME=`jq -r '.REPONAME' ./Configurations/config.json`
PROJECTNAME=`jq -r '.PROJECTNAME' ./Configurations/config.json`
SETNAME=`jq -r '.SETNAME' ./Configurations/config.json`
STACKNAME=`jq -r '.STACKNAME' ./Configurations/config.json`
PIPELINENAME=`jq -r '.PIPELINENAME' ./Configurations/config.json`

# --- AUTOMATED DEPLOYMENT OF A CODEPIPELINE FOR A SERVERLESS APPLICATION ---

# --- 1. STEPS BEFORE PIPELINE CAN BE DONE ---

# --- 1.1. CODECOMMIT ---

echo $'Creating Codecommit repository...\n'

aws codecommit create-repository --repository-name "$REPONAME" --repository-description "My demonstration repository" > codecommit.json;

echo $'Created Codecommit repository.\n'

# --- 1.2. CODEBUILD ---

echo $'Creating Codebuild project.\n'

jq '.name = "'"$PROJECTNAME"'"' codebuildTemplate.json|sponge codebuildTemplate.json

# NOTE: The programming language of the project is set in the codebuildTemplate.json

aws codebuild create-project --cli-input-json file://codebuildTemplate.json > deployedBuild.json

echo $'Codebuild project created.\n'

# --- 2. EDIT THE PIPELINE TEMPLATE BEFORE DEPLOYMENT ---

jq '.pipeline.stages[0].actions[0].configuration.RepositoryName = "'"$REPONAME"'"' codepipelineTemplate.json|sponge codepipelineTemplate.json
jq '.pipeline.stages[1].actions[0].configuration.ProjectName = "'"$PROJECTNAME"'"' codepipelineTemplate.json|sponge codepipelineTemplate.json
jq '.pipeline.stages[2].actions[0].configuration.ChangeSetName = "'"$SETNAME"'"' codepipelineTemplate.json|sponge codepipelineTemplate.json
jq '.pipeline.stages[2].actions[0].configuration.StackName = "'"$STACKNAME"'"' codepipelineTemplate.json|sponge codepipelineTemplate.json
jq '.pipeline.stages[2].actions[1].configuration.ChangeSetName = "'"$SETNAME"'"' codepipelineTemplate.json|sponge codepipelineTemplate.json
jq '.pipeline.stages[2].actions[1].configuration.StackName = "'"$STACKNAME"'"' codepipelineTemplate.json|sponge codepipelineTemplate.json
jq '.pipeline.name = "'"$PIPELINENAME"'"' codepipelineTemplate.json|sponge codepipelineTemplate.json

echo $'Variables injected into the codepipeline template file.\n'

# --- 3. DEPLOY THE CODE PIPELINE ---

echo $'Deploying Codepipeline.\n'

aws codepipeline create-pipeline --cli-input-json file://codepipelineTemplate.json > deployedPipeline.json

echo $'Codepipeline deployed.\n'
