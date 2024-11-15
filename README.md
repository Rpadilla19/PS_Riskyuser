# PS_Riskyuser
The purpose of the script is to use mg-graph to pull any users labeled as 'high-risk', sign in counts and entry logs.

How to use

The script has two versions, one for delegated access and the other has an interactive log-in. In my use case we loaded the script on a raspberry pi [delegated access] to run weekly to audit users.  If you are unsure if the app you are using has proper permissions look in Entra, app registration > go to application > api permission. If you do not see the necessary modules it will not work. For interactive log-in make sure you are signed in to the proper account and have the proper permissions to access the necessary modules.
