<#import "template.ftl" as layout>
<@layout.registrationLayout displayMessage=!messagesPerField.existsError('username','password') displayInfo=realm.password && realm.registrationAllowed && !registrationDisabled??; section>
    <#if section = "title">
        ${msg("loginTitle")}
    <#elseif section = "form">
        <div id="kc-form">
            <div id="kc-form-wrapper">
                <#if realm.password>
                    <form id="kc-form-login" onsubmit="login.disabled = true; return true;" action="${url.loginAction}" method="post">
                        <#if !usernameHidden??>
                            <div class="form-group">
                                <label for="username">
                                    <#if !realm.loginWithEmailAllowed>${msg("username")}<#elseif !realm.registrationEmailAsUsername>${msg("usernameOrEmail")}<#else>${msg("email")}</#if>
                                </label>
                                <input tabindex="1" 
                                       id="username" 
                                       class="form-control" 
                                       name="username" 
                                       value="${(login.username!'')}" 
                                       type="text" 
                                       autofocus 
                                       autocomplete="username"
                                       aria-invalid="<#if messagesPerField.existsError('username','password')>true</#if>" />
                                <#if messagesPerField.existsError('username','password')>
                                    <span id="input-error" class="alert alert-error" style="display:block; margin-top:6px;" aria-live="polite">
                                        ${kcSanitize(messagesPerField.getFirstError('username','password'))?no_esc}
                                    </span>
                                </#if>
                            </div>
                        </#if>

                        <div class="form-group">
                            <label for="password">${msg("password")}</label>
                            <input tabindex="2" 
                                   id="password" 
                                   class="form-control" 
                                   name="password" 
                                   type="password" 
                                   autocomplete="current-password"
                                   aria-invalid="<#if messagesPerField.existsError('username','password')>true</#if>" />
                        </div>

                        <#if realm.rememberMe && !usernameHidden??>
                            <div class="form-group" style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 12px;">
                                <label style="display: flex; align-items: center; gap: 8px; font-weight: 400; font-size: 13px; cursor: pointer;">
                                    <#if login.rememberMe??>
                                        <input tabindex="3" id="rememberMe" name="rememberMe" type="checkbox" checked> ${msg("rememberMe")}
                                    <#else>
                                        <input tabindex="3" id="rememberMe" name="rememberMe" type="checkbox"> ${msg("rememberMe")}
                                    </#if>
                                </label>
                                <#if realm.resetPasswordAllowed>
                                    <a tabindex="5" href="${url.loginResetCredentialsUrl}" style="font-size: 12px; color: var(--nt-brand-accent); text-decoration: none;">
                                        ${msg("doForgotPassword")}
                                    </a>
                                </#if>
                            </div>
                        </#if>

                        <div id="kc-form-buttons">
                            <input type="hidden" id="id-hidden-input" name="credentialId" <#if auth.selectedCredential?has_content>value="${auth.selectedCredential}"</#if>/>
                            <input tabindex="4" class="btn btn-primary" name="login" id="kc-login" type="submit" value="${msg("doLogIn")}"/>
                        </div>
                    </form>
                </#if>
            </div>
        </div>

        <#-- Enterprise Identity Providers (SSO) if configured for Organization -->
        <#if realm.password && social.providers??>
            <div id="kc-social-providers" class="social-providers">
                <div class="social-providers-title">${msg("enterpriseSsoLabel")}</div>
                <#list social.providers as p>
                    <a id="social-${p.alias}" class="social-link" href="${p.loginUrl}">
                        <span>${p.displayName}</span>
                    </a>
                </#list>
            </div>
        </#if>
    <#elseif section = "info">
        <#-- Optional signup link if enabled -->
        <#if realm.password && realm.registrationAllowed && !registrationDisabled??>
            <div id="kc-registration" style="text-align: center; margin-top: 16px; font-size: 13px;">
                <span>${msg("noAccount")} <a tabindex="6" href="${url.registrationUrl}" style="color: var(--nt-brand-accent); font-weight: 600;">${msg("doRegister")}</a></span>
            </div>
        </#if>
    </#if>
</@layout.registrationLayout>
