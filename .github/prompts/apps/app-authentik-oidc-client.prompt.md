# Configuring an OIDC Client in Authentik for {{client_app_name}}

Outline the key information and steps required to configure "{{client_app_name}}" as an OIDC client application in Authentik:

1.  **In Authentik Admin UI (under Applications -> Applications -> Create Application):**
    - Name: `{{client_app_name}}`
    - Slug: (e.g., `{{client_app_name_slug}}`)
    - Provider: Create or select an existing OpenID Connect Provider.

2.  **In Authentik OIDC Provider Settings (associated with the application):**
    - Client type: (e.g., Confidential)
    - Client ID: (Authentik will generate this, e.g., `{{placeholder_client_id}}`)
    - Client Secret: (Authentik will generate this, e.g., `{{placeholder_client_secret}}`) -> Remind me to store this in a K8s Secret for `{{client_app_name}}`.
    - Redirect URIs/Callback URLs (one per line):
        - `https://{{client_app_name_hostname_1}}/path/to/oidc/callback`
        - `https://{{client_app_name_hostname_2}}/another/callback`
    - Scopes: (e.g., `openid email profile`)
    - Signing Key: Select an appropriate key.

3.  **Information to provide to "{{client_app_name}}" configuration:**
    - Authentik Issuer URL / Discovery URL (e.g., `https://authentik.yourdomain.com/application/o/{{provider_slug_or_name}}/`)
    - Client ID (from Authentik).
    - Client Secret (from Authentik, to be loaded from the K8s Secret).

Remind me to ensure the Redirect URIs configured in Authentik exactly match what "{{client_app_name}}" will use and register.
