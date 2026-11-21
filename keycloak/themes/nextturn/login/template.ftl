<#macro registrationLayout bodyClass="" displayInfo=false displayMessage=true displayRequiredFields=false showAnotherWayIfPresent=true>
<!DOCTYPE html>
<html lang="${(locale.currentLanguageTag)!'vi'}">
<head>
    <meta charset="utf-8">
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <meta name="robots" content="noindex, nofollow">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>${msg("loginTitle")}</title>
    
    <#if properties.styles?has_content>
        <#list properties.styles?split(' ') as style>
            <link href="${url.resourcesPath}/${style}" rel="stylesheet" />
        </#list>
    </#if>
    <#if properties.scripts?has_content>
        <#list properties.scripts?split(' ') as script>
            <script src="${url.resourcesPath}/${script}" type="text/javascript"></script>
        </#list>
    </#if>
</head>
<body class="login-pf-page ${bodyClass}">
  <div class="login-container card-pf">
    <header class="nextturn-brand-header">
      <div class="brand-logo-container">
        <!-- Default is keycloak-logo.svg. nextturn-branding.js dynamically updates according to Method 2 -->
        <img id="brand-logo" 
             class="brand-logo" 
             src="${url.resourcesPath}/img/keycloak-logo.svg" 
             alt="Authentication Logo" />
      </div>
      <h1 id="brand-title" class="brand-title">${msg("loginTitle")}</h1>
      <p id="brand-subtitle" class="brand-subtitle">${msg("loginSubTitle")}</p>
      <div id="brand-badge" class="brand-badge" style="display: none;">
        <span id="brand-badge-text"></span>
      </div>
    </header>

    <#-- Global alert messages (Error / Success) -->
    <#if displayMessage && message?has_content && (message.type != 'warning' || !isAppInitiatedAction??)>
      <div class="alert alert-${message.type}">
        <span class="kc-feedback-text">${kcSanitize(message.summary)?no_esc}</span>
      </div>
    </#if>

    <#-- Login Form / Body -->
    <#nested "form">

    <#-- Additional Info / Action section -->
    <#if displayInfo>
      <div id="kc-info" class="login-pf-info">
        <#nested "info">
      </div>
    </#if>
  </div>
</body>
</html>
</#macro>
