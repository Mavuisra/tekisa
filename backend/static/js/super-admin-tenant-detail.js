(function () {
  const tenantId = document.body.dataset.tenantId || "";
  const endpoint = `/api/v1/commerce/admin/tenants/${encodeURIComponent(tenantId)}/`;

  const el = {
    refreshBtn: document.getElementById("refresh-tenant"),
    errorBanner: document.getElementById("error-banner"),
    tenantIdLabel: document.getElementById("tenant-id-label"),
    kpiUsers: document.getElementById("kpi-users"),
    kpiProducts: document.getElementById("kpi-products"),
    kpiSales: document.getElementById("kpi-sales"),
    kpiRevenue: document.getElementById("kpi-revenue"),
    tenantCompanyDetails: document.getElementById("tenant-company-details"),
    tenantUsersBody: document.getElementById("tenant-users-body"),
    tenantSalesBody: document.getElementById("tenant-sales-body"),
  };

  function showError(message) {
    el.errorBanner.textContent = message;
    el.errorBanner.classList.remove("hidden");
  }

  function clearError() {
    el.errorBanner.textContent = "";
    el.errorBanner.classList.add("hidden");
  }

  function formatMoney(value) {
    const safe = Number(value || 0);
    return `${safe.toLocaleString("fr-FR")} CDF`;
  }

  async function apiGet(url) {
    const response = await fetch(url, {
      method: "GET",
      headers: { Accept: "application/json" },
      credentials: "same-origin",
    });
    if (!response.ok) {
      throw new Error(`HTTP ${response.status} sur ${url}`);
    }
    return response.json();
  }

  function detailChip(label, value) {
    return `<div class="rounded-tekisa border border-slate-200 bg-slate-50 px-3 py-2">
      <p class="text-xs uppercase tracking-wide text-slate-500">${label}</p>
      <p class="font-semibold text-slate-800">${value || "-"}</p>
    </div>`;
  }

  function render(data) {
    const tenant = data.tenant || {};
    const kpis = data.kpis || {};
    const users = Array.isArray(data.users) ? data.users : [];
    const sales = Array.isArray(data.recent_sales) ? data.recent_sales : [];

    el.tenantIdLabel.textContent = `Tenant: ${tenant.tenant_id || tenantId || "-"}`;
    el.kpiUsers.textContent = (kpis.users_count || 0).toString();
    el.kpiProducts.textContent = (kpis.products_count || 0).toString();
    el.kpiSales.textContent = (kpis.sales_count || 0).toString();
    el.kpiRevenue.textContent = formatMoney(kpis.revenue_total || 0);

    el.tenantCompanyDetails.innerHTML = [
      detailChip("Raison sociale", tenant.company_name),
      detailChip("Nom commercial", tenant.company_trade_name),
      detailChip("Forme legale", tenant.legal_form),
      detailChip("RCCM", tenant.rccm),
      detailChip("IDNAT", tenant.idnat),
      detailChip("NIF", tenant.nif),
      detailChip("Telephone", tenant.company_phone),
      detailChip("Email", tenant.company_email),
      detailChip("Pays", tenant.company_country),
      detailChip("Province", tenant.company_province),
      detailChip("Ville", tenant.company_city),
      detailChip("Commune", tenant.company_commune),
      detailChip("Quartier", tenant.company_quarter),
      detailChip("Avenue", tenant.company_avenue),
      detailChip("Numero", tenant.company_number),
      detailChip("Cree le", tenant.created_at ? new Date(tenant.created_at).toLocaleString("fr-FR") : "-"),
    ].join("");

    el.tenantUsersBody.innerHTML =
      users.length === 0
        ? '<tr><td colspan="6" class="py-4 text-center text-slate-500">Aucun utilisateur.</td></tr>'
        : users
            .map(
              (u) => `<tr>
                <td class="py-2 pr-3 font-medium">${u.username || "-"}</td>
                <td class="py-2 pr-3">${u.role || "-"}</td>
                <td class="py-2 pr-3">${u.phone || "-"}</td>
                <td class="py-2 pr-3">${u.email || "-"}</td>
                <td class="py-2 pr-3">${u.last_login ? new Date(u.last_login).toLocaleString("fr-FR") : "-"}</td>
                <td class="py-2 pr-3">${u.is_active ? "Oui" : "Non"}</td>
              </tr>`,
            )
            .join("");

    el.tenantSalesBody.innerHTML =
      sales.length === 0
        ? '<tr><td colspan="6" class="py-4 text-center text-slate-500">Aucune vente.</td></tr>'
        : sales
            .map(
              (s) => `<tr>
                <td class="py-2 pr-3">${s.created_at ? new Date(s.created_at).toLocaleString("fr-FR") : "-"}</td>
                <td class="py-2 pr-3">${s.seller_username || "-"}</td>
                <td class="py-2 pr-3">${s.customer_name || "-"}</td>
                <td class="py-2 pr-3">${s.payment_method || "-"}</td>
                <td class="py-2 pr-3">${formatMoney(s.total || 0)}</td>
                <td class="py-2 pr-3">${s.status || "-"}</td>
              </tr>`,
            )
            .join("");
  }

  async function load() {
    if (!tenantId) {
      showError("Tenant ID manquant dans l'URL.");
      return;
    }
    try {
      clearError();
      const data = await apiGet(endpoint);
      render(data || {});
    } catch (error) {
      if (String(error.message || "").includes("HTTP 401")) {
        showError("Session expirée. Reconnecte-toi sur /admin/login/ puis recharge cette page.");
        return;
      }
      showError(`Chargement impossible: ${error.message}`);
    }
  }

  el.refreshBtn.addEventListener("click", load);
  load();
})();
