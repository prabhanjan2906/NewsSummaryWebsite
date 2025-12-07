# NewsSummaryWebsite

To setup github actions to work with GCP:
1. First create your project in google cloud.
    - goto https://console.cloud.google.com/welcome and create a project.
    - find the project ID and project number on the home page of your project and save them as PROJECT_ID and PROJECT_NUMBER environment variables.
2. Setup google cloud cli on your local machine and perform these Manual steps.
    - 2.1 login first
        ```
        gcloud auth login
        ```
    - 2.2 set the project
        ```
        gcloud config set project $PROJECT_ID
        ```
    - 2.3 create service account with any name and verify the same
        ```
        gcloud iam service-accounts create service-account-name
        gcloud iam service-accounts list
        ```

    - 2.4 command:
        ```
        gcloud iam workload-identity-pools create "identity-pool-name" --project="${PROJECT_ID}"       --location="global" --display-name="GitHub OIDC Pool"
        ```
    - 2.5 command:
        ```
        gcloud iam workload-identity-pools providers create-oidc "github-provider" \
            --project="${PROJECT_ID}" \
            --location="global" \
            --workload-identity-pool="identity-pool-name" \
            --display-name="GitHub OIDC Provider" \
            --issuer-uri="https://token.actions.githubusercontent.com" \
            --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository,attribute.actor=assertion.actor,attribute.aud=assertion.aud" \
            --attribute-condition="attribute.repository=='githubOrganisation/RepositoryName'"
        ```
    - 2.6 
        ```
        gcloud iam service-accounts add-iam-policy-binding $SERVICE_ACCOUNT_EMAIL --project="${PROJECT_ID}" \
            --role="roles/iam.workloadIdentityUser" \
            --member="principalSet://iam.googleapis.com/projects/$PROJECT_NUMBER$/locations/global/workloadIdentityPools/github-pool/*"
        ```
    - 2.7 To verify the auth is working, you need to do a gcloud projects describe. for that, the below permissions will enable access to describe.
        ```
        gcloud projects add-iam-policy-binding "$PROJECT_ID" \
            --member="serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
            --role="roles/viewer"
        ```
    - 2.8 you also need to enable the following API's for github to work with google cloud.
        ```
        https://console.developers.google.com/apis/api/iamcredentials.googleapis.com/overview?project=YOUR_PROJECT_ID
        https://console.developers.google.com/apis/api/cloudresourcemanager.googleapis.com/overview?project=YOUR_PROJECT_ID
        ```
    
    - 2.9 NOW the Gihub actions should be able to communicate with GCP and create resources successfully.