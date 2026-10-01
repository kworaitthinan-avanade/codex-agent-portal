# RB-016 - SSO application access request

**Agent:** `request-access`
**Match terms:** sso, single sign on, application access, saml, app assignment

## Symptoms

SSO application access request, reported through the portal, email or a monitoring alert.

## Procedure

| # | Step | Tool | write |
|---|---|---|---|
| 1 | Confirm the application is SSO-enabled | `entra_get_user` | false |
| 2 | Confirm the requester is in the owning cost centre | `entra_get_user` | false |
| 3 | Reply with the assignment status | `ticket_comment` | false |

## Notes

Assignment itself is performed by the application owner, not by this agent.
