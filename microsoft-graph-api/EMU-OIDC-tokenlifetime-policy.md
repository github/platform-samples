
### Background

This is applicable to GitHub Enterprise Cloud enterprises that are enabled for [enterprise managed users (EMUs) and using Azure AD/Entra OIDC authentication](https://docs.github.com/en/enterprise-cloud@latest/admin/identity-and-access-management/using-enterprise-managed-users-for-iam/configuring-oidc-for-enterprise-managed-users). 

[You can adjust the lifetime of a session, and how often a managed user account needs to reauthenticate with your IdP, by changing the lifetime policy property of the ID tokens issued for GitHub from your IdP. The default lifetime is one hour](https://docs.github.com/en/enterprise-cloud@latest/admin/identity-and-access-management/using-enterprise-managed-users-for-iam/configuring-oidc-for-enterprise-managed-users#about-oidc-for-enterprise-managed-users). GitHub documentation currently links [to this Microsoft article](https://learn.microsoft.com/en-us/entra/identity-platform/configure-token-lifetimes) for configuring this ID token lifetime policy, however the PowerShell steps in that Microsoft article will not allow you to assign a token lifetime policy to the GitHub Enterprise Managed User (OIDC) app based on `ServicePrincipal` `Id` rather than application object `Id`. The token lifetime policy needs to be assigned to the `ServicePrincipal` `Id` of the app because this is the local representation of this multi-tenant app in your Azure AD/Entra tenant. It does not appear that the current PowerShell cmdlets will allow you to do this for a multi-tenant app, however the [MS Graph API](https://learn.microsoft.com/en-us/graph/use-the-api) will allow you to do this. 

### MS Graph Explorer steps for creating a `tokenLifetimePolicy` and assigning it to the GitHub Enterprise Managed User (OIDC) app in Azure AD/Entra

Here is an example of the steps for creating a `tokenLifetimePolicy` in your tenant and assigning it to the `ServicePrincipal` `Id` of the GitHub Enterprise Managed User (OIDC) app using [Microsoft Graph Explorer](https://developer.microsoft.com/en-us/graph/graph-explorer). [You can have multiple tokenLifetimePolicy policies in a tenant but can assign only one `tokenLifetimePolicy` per application](https://learn.microsoft.com/en-us/graph/api/application-post-tokenlifetimepolicies?view=graph-rest-1.0&tabs=http). If you need assistance using MS Graph Explorer, these example commands, or configuring/applying a token lifetime policy in Azure AD/Entra using MS Graph, please reach out to Microsoft Support. 

- **Sign into MS Graph Explorer using the admin account for your Entra tenant: https://developer.microsoft.com/en-us/graph/graph-explorer.**

- **Set the Request Header in MS Graph Explorer to a key of `content-type` and a value of `application/json`.** 

- **Run the query below to get the `servicePrincipal` `Id` of the GitHub OIDC app.**

   Request Method:

   ```
   GET
   ```

   URL:

   ```
   https://graph.microsoft.com/v1.0/servicePrincipals?$filter=displayName+eq+'GitHub+Enterprise+Managed+User+(OIDC)'
   ```

- **You can verify that you're able to get this `servicePrincipal` object using this `Id` with the query below:**

   Request Method:

   ```
   GET
   ```

   URL:

   ```
   GET https://graph.microsoft.com/v1.0/servicePrincipals/{Service Principal ID of app goes here}
   ```

- **Run the command below to create a new `tokenlifetimepolicy`. In this example, the token lifetime policy is being set to 12 hours.**

   Request Method:

   ```
   POST
   ```

   URL:

   ```
   https://graph.microsoft.com/v1.0/policies/tokenLifetimePolicies
   ```

   Request Body:

   ```
   { "definition": [ "{"TokenLifetimePolicy":{"Version":1,"AccessTokenLifetime":"12:00:00"}}" ], "displayName": "12hour policy", "isOrganizationDefault": false }
   ```

   The policy ID will be returned in the results. 

- **You can run the query below to list this new policy:**

   Request Method:

   ```
   GET
   ```

   ```
   https://graph.microsoft.com/v1.0/policies/tokenLifetimePolicies/{Id of new tokeLifeTimePolicy}
   ```

- **Run the command below to assign this new policy to the `servicePrincipal` of the GitHub OIDC app:**

   Request Method:

   ```
   POST
   ```

   ```
   https://graph.microsoft.com/v1.0/servicePrincipals/{servicePrincipal ID of the app}/tokenLifetimePolicies/$ref
   ```

   Request body:

   ```
   { "@odata.id":"https://graph.microsoft.com/v1.0/policies/tokenLifetimePolicies/{Id of the tokeLifetimePolicy" }
   ```

- **The query below will show the display name of the `tokenLifetimePolicy` assigned to this app based on the `servicePrincipal` of the app.**

   ```
   GET https://graph.microsoft.com/v1.0/servicePrincipals/{servicePrincipal ID of the app}/tokenLifetimePolicies?$select=displayName
   ```
