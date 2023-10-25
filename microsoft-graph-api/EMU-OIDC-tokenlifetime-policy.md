
## Background

This is applicable to GitHub Enterprise Cloud enterprises that are enabled for [enterprise managed users (EMUs) and using Azure AD/Entra OIDC authentication](https://docs.github.com/en/enterprise-cloud@latest/admin/identity-and-access-management/using-enterprise-managed-users-for-iam/configuring-oidc-for-enterprise-managed-users).

[You can adjust the lifetime of a session, and how often a managed user account needs to reauthenticate with your IdP, by changing the lifetime policy property of the ID tokens issued for GitHub from your IdP. The default lifetime is one hour](https://docs.github.com/enterprise-cloud@latest/admin/identity-and-access-management/using-enterprise-managed-users-for-iam/configuring-oidc-for-enterprise-managed-users#about-oidc-for-enterprise-managed-users). Our GitHub public documentation currently links [to this Microsoft article](https://learn.microsoft.com/en-us/entra/identity-platform/configure-token-lifetimes) for configuring this ID token lifetime policy; however, the PowerShell steps in that Microsoft article will not allow you to assign a token lifetime policy to the GitHub Enterprise Managed User (OIDC) app based on `ServicePrincipal Id` rather than application object `Id`. The token lifetime policy needs to be assigned to the `ServicePrincipal Id` of the app because this is the local representation of this multi-tenant app in your Azure AD/Entra tenant. It does not appear that the current PowerShell `cmdlets` will allow you to do this for a multi-tenant app, however the [MS Graph API](https://learn.microsoft.com/en-us/graph/use-the-api) will allow you to do this.

## MS Graph Explorer steps for creating a `tokenLifetimePolicy` and assigning it to the GitHub Enterprise Managed User (OIDC) app in Azure AD/Entra

Here is an example of the steps for creating a `tokenLifetimePolicy` in your tenant and assigning it to the `ServicePrincipal Id` of the GitHub Enterprise Managed User (OIDC) app using [Microsoft Graph Explorer](https://developer.microsoft.com/en-us/graph/graph-explorer).

[You can have multiple `tokenLifetimePolicy` policies in a tenant but can only assign one `tokenLifetimePolicy` per application](https://learn.microsoft.com/en-us/graph/api/application-post-tokenlifetimepolicies?view=graph-rest-1.0&tabs=http). If you need assistance using MS Graph Explorer, these example commands, or configuring/applying a token lifetime policy in Azure AD/Entra using MS Graph, please reach out to Microsoft Support.

1. Sign in to MS Graph Explorer using the admin account for your Azure AD/Entra tenant: https://developer.microsoft.com/en-us/graph/graph-explorer

1. Set the **Request Header** in MS Graph Explorer to a key of `content-type` and a value of `application/json`.

1. Run the query below to get the `id` of the `servicePrincipal` for the GitHub EMU OIDC app:

   - Request Method: `GET`

   - URL:

        ```text
        https://graph.microsoft.com/v1.0/servicePrincipals?$filter=displayName eq 'GitHub+Enterprise+Managed+User+(OIDC)'&$select=id
        ```

   - Example Response:

        ```json
        {
            "@odata.context": "https://graph.microsoft.com/v1.0/$metadata#servicePrincipals(id)",
            "value": [
                {
                    "id": "abcdefgh-ijkl-1234-mnop-qrstuvwxyz56"
                }
            ]
        }
        ```

1. You can verify that you're able to get this `servicePrincipal` object using this `id` with the query below:

   - Request Method: `GET`

   - URL:

        > Replace the `SERVICE_PRICIPAL_ID` with the `id` of the `servicePrincipal` for the GitHub EMU OIDC app (from step 3)

        ```text
        https://graph.microsoft.com/v1.0/servicePrincipals/SERVICE_PRICIPAL_ID?$select=id,appDisplayName,appId,displayName,tags
        ```

1. Run the command below to create a new `tokenlifetimepolicy`. In the following example, the token lifetime policy is being set to 12 hours:

    - Request Method: `POST`

    - URL:

        ```text
        https://graph.microsoft.com/v1.0/policies/tokenLifetimePolicies
        ```

    - Request Body:

        ```json
        { 
          "definition": [
            "{\"TokenLifetimePolicy\":{\"Version\":1,\"AccessTokenLifetime\":\"12:00:00\"}}"
          ],
          "displayName": "12-hour policy",
          "isOrganizationDefault": false 
        }        
        ```

   The policy `id` will be listed in the results.

1. You can run the query below to list this new policy:

    - Request Method: `GET`

    - URL:
        > Replace the `NEW_TOKENLIFETIMEPOLICY_ID` with the `id` of the new token lifetime policy (from step 5).

        ```text
        https://graph.microsoft.com/v1.0/policies/tokenLifetimePolicies/NEW_TOKENLIFETIMEPOLICY_ID
        ```

1. Run the command below to assign this new policy to the `servicePrincipal` of the GitHub EMU OIDC app:

   - Request Method: `POST`

   - URL:

        > Replace the `SERVICE_PRICIPAL_ID` with the `id` of the `servicePrincipal` for the GitHub EMU OIDC app (from step 3)

        ```text
        https://graph.microsoft.com/v1.0/servicePrincipals/SERVICE_PRICIPAL_ID/tokenLifetimePolicies/$ref
        ```

   - Request body:

        > Replace the `NEW_TOKENLIFETIMEPOLICY_ID` with the `id` of the new token lifetime policy from step 5.

        ```json
        {
            "@odata.id": "https://graph.microsoft.com/v1.0/policies/tokenLifetimePolicies/NEW_TOKENLIFETIMEPOLICY_ID"
        }
        ```

1. The query below will show the display name of the `tokenLifetimePolicy` assigned to this app based on the `servicePrincipal` of the app:

    - Request Method: `GET`

    - URL:

        > Replace the `SERVICE_PRICIPAL_ID` with the `servicePrincipal Id` of the GitHub EMU OIDC app (from step 3).

        ```text
        https://graph.microsoft.com/v1.0/servicePrincipals/SERVICE_PRICIPAL_ID/tokenLifetimePolicies?$select=displayName
        ```

    - Example Response:

        ```json
        {
            "@odata.context": "https://graph.microsoft.com/v1.0/$metadata#Collection(microsoft.graph.tokenLifetimePolicy)",
            "value": [
                {
                    "displayName": "12-hour policy"
                }
            ]
        }
        ```
