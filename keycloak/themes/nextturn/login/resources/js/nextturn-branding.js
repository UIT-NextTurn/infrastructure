/**
 * NextTurn Keycloak Dynamic Branding Script
 * Handles dynamic logo, facility name, and theme modes for:
 *   1. Superadmin -> NextTurn Platform Logo + Obsidian Dark Style
 *   2. Tenant with custom logo -> Tenant Logo (Method 2 URL/Attribute) with Keycloak fallback on error
 *   3. Tenant without custom logo -> Keycloak Logo (Default)
 */
(function () {
    'use strict';

    function getResourcesPath() {
        const scriptTags = document.getElementsByTagName('script');
        for (let i = 0; i < scriptTags.length; i++) {
            const src = scriptTags[i].src || '';
            const idx = src.indexOf('/js/nextturn-branding.js');
            if (idx !== -1) {
                return src.substring(0, idx);
            }
        }
        return '';
    }

    function initBranding() {
        const resourcesPath = getResourcesPath();
        const keycloakLogo = resourcesPath + '/img/keycloak-logo.svg';
        const nextturnLogo = resourcesPath + '/img/nextturn-logo.svg';

        const searchParams = new URLSearchParams(window.location.search);
        let tenantCode = searchParams.get('tenant_code');
        let tenantName = searchParams.get('tenant_name');
        let logoUrl = searchParams.get('logo_url');
        let portal = searchParams.get('portal');
        let organization = searchParams.get('organization');

        // Persist context in sessionStorage so branding survives wrong password reloads
        if (tenantCode || portal || organization) {
            const ctx = {
                tenantCode: tenantCode,
                tenantName: tenantName,
                logoUrl: logoUrl,
                portal: portal,
                organization: organization
            };
            try {
                sessionStorage.setItem('nt_branding_context', JSON.stringify(ctx));
            } catch (e) {
                // Ignore storage errors in restricted iframe
            }
        } else {
            // Restore from sessionStorage if URL parameters were stripped by Keycloak loginAction
            try {
                const cached = sessionStorage.getItem('nt_branding_context');
                if (cached) {
                    const parsed = JSON.parse(cached);
                    tenantCode = parsed.tenantCode;
                    tenantName = parsed.tenantName;
                    logoUrl = parsed.logoUrl;
                    portal = parsed.portal;
                    organization = parsed.organization;
                }
            } catch (e) {}
        }

        const isSuperAdmin = portal === 'superadmin' || (!tenantCode && !organization);

        const logoEl = document.getElementById('brand-logo');
        const titleEl = document.getElementById('brand-title');
        const subtitleEl = document.getElementById('brand-subtitle');
        const badgeEl = document.getElementById('brand-badge');
        const badgeTextEl = document.getElementById('brand-badge-text');
        const rootContainer = document.querySelector('.login-pf-page') || document.body;

        if (isSuperAdmin) {
            // =========================================================================
            // Mode 1: Super Admin -> NextTurn Brand Logo & Obsidian Console Theme
            // =========================================================================
            if (rootContainer) {
                rootContainer.classList.add('mode-superadmin');
                rootContainer.classList.remove('mode-tenant');
            }
            if (logoEl) {
                logoEl.src = nextturnLogo;
                logoEl.alt = 'NextTurn Global Platform';
            }
            if (titleEl) {
                titleEl.textContent = 'NextTurn Global Platform';
            }
            if (subtitleEl) {
                subtitleEl.textContent = 'Trung tâm Quản trị Nền tảng Toàn cầu (Super Admin)';
            }
            if (badgeEl) {
                badgeEl.style.display = 'inline-flex';
                badgeEl.className = 'brand-badge badge-superadmin';
            }
            if (badgeTextEl) {
                badgeTextEl.textContent = 'SUPER ADMIN CONSOLE';
            }
        } else {
            // =========================================================================
            // Mode 2: Tenant Staff / Admin Login
            // =========================================================================
            if (rootContainer) {
                rootContainer.classList.add('mode-tenant');
                rootContainer.classList.remove('mode-superadmin');
            }

            const displayName = tenantName && tenantName.trim() !== '' ? tenantName : (tenantCode || 'NextTurn Facility');
            if (titleEl) {
                titleEl.textContent = displayName;
            }
            if (subtitleEl) {
                subtitleEl.textContent = 'Cổng Đăng nhập Nhân sự Cơ sở';
            }
            if (badgeEl) {
                badgeEl.style.display = 'inline-flex';
                badgeEl.className = 'brand-badge badge-tenant';
            }
            if (badgeTextEl) {
                badgeTextEl.textContent = 'Cơ sở: ' + (tenantCode || 'Chung');
            }

            // Logo Selection:
            // If tenant has custom logo -> use logoUrl, fallback to Keycloak logo if error/404
            // If tenant does NOT have custom logo -> default directly to Keycloak logo
            if (logoEl) {
                if (logoUrl && logoUrl.trim() !== '') {
                    logoEl.src = logoUrl.trim();
                    logoEl.alt = displayName + ' Logo';
                    logoEl.onerror = function () {
                        // Fallback to Keycloak logo on network error or missing file
                        this.onerror = null;
                        this.src = keycloakLogo;
                        this.alt = 'Keycloak Identity Security';
                    };
                } else {
                    // Default to Keycloak logo
                    logoEl.src = keycloakLogo;
                    logoEl.alt = 'Keycloak Identity Security';
                }
            }
        }
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initBranding);
    } else {
        initBranding();
    }
})();
