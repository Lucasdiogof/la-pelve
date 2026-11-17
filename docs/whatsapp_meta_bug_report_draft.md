# Rascunho do relatório de bug para a Meta (NÃO enviado)

Enviar em developers.facebook.com/support/bugs. Revisar antes. Sem tokens, cookies ou códigos.

**Title:** Embedded Signup shows "can't onboard customers right now" for a Tech Provider with verified business and approved permissions

**Description (EN):**
Our Embedded Signup flow is blocked by Meta before any step of ours runs. Opening the Embedded Signup dialog (config_id 4693096200923752) shows: "Lucksrei não pode integrar clientes no momento" (the business cannot onboard customers right now) with only a "share my contact information" button. The choice between new number and existing WhatsApp Business app never appears.

IDs: App 2811023262627717 (published) · Business Portfolio 4371966796448884 · Config 4693096200923752 · Domain https://lapelve.lucksrei.com

Contradictory status in Business Settings:
- Business info: Verified, Technology Provider.
- Security Center > Access Verification: "In review" since 04/10/2026.
- Warning "WhatsApp needs more information"; the Tech Provider integration tab returns error 1007.
Already approved: Business Verification, App Review (whatsapp_business_management, whatsapp_business_messaging, public_profile), OAuth domains and webhook configured.

Reproduced (17/11/2026), same result every time, before any callback reaches our code:
1. Minimal static page on our domain: only FB.init + FB.login (config_id, response_type=code, override_default_response_type, extras.setup) , in an automated Chromium.
2. Same page, with extras.version removed.
3. Real desktop Chrome on Windows (Graph v25.0), owner account. Session ID 01a1eb89-06a8-7166-b389-e964ae752d08
4. Real iPhone, Safari, through our production app.
5. Owner account, a Facebook account that does not administer the business, and a third person's account.
Other session IDs: 01a1e474-aa97-70b4-aef2-fde3ebb24b7b, 01a1e492-ca80-73de-9c0c-b32929baec65

Because the same block appears across browsers, devices, SDK parameters and accounts, we believe it is a restriction on the business/app (likely the pending Access Verification) rather than a client issue.

Expected: Embedded Signup opens normally. Request: please tell us what is blocking onboarding and what we must do to lift it.
Previous support cases (closed by automation, no human review): 29569203806031459, 29067602789565652.
