// liftright/web/assets/js/charts.js
document.addEventListener("DOMContentLoaded", () => {
  const cfg = window.LR_DASHBOARD || {};
  const el = document.getElementById("lrFormTrendChart");
  if (!el || !cfg.trendUrl || typeof Chart === "undefined") return;

  async function loadTrend() {
    try {
      const res = await fetch(cfg.trendUrl, { cache: "no-store" });
      const data = await res.json();
      if (!data || !data.success || !Array.isArray(data.points)) return;

      const labels = data.points.map((p, i) => {
        const shortLabel = String(p.label || "—");
        const logId = Number(p.log_id || (i + 1));
        return `${shortLabel} #${logId}`;
      });

      const fullLabels = data.points.map(p => String(p.full_label || p.label || "—"));
      const values = data.points.map(p => Number(p.pct || 0));

      const ctx = el.getContext("2d");
      const gradient = ctx.createLinearGradient(0, 0, 0, 220);
      gradient.addColorStop(0, "rgba(79,157,252,0.35)");
      gradient.addColorStop(1, "rgba(79,157,252,0.04)");

      if (window.lrTrendChart) {
        window.lrTrendChart.destroy();
      }

      window.lrTrendChart = new Chart(el, {
        type: "line",
        data: {
          labels,
          datasets: [{
            label: "Form score (%)",
            data: values,
            tension: 0.35,
            fill: true,
            backgroundColor: gradient,
            borderWidth: 2,
            pointRadius: 3,
            pointHoverRadius: 5
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          interaction: {
            intersect: false,
            mode: "index"
          },
          scales: {
            y: {
              min: 0,
              max: 100,
              ticks: {
                callback: (v) => v + "%"
              }
            }
          },
          plugins: {
            legend: { display: true },
            tooltip: {
              callbacks: {
                title: (items) => {
                  const idx = items?.[0]?.dataIndex ?? 0;
                  return fullLabels[idx] || "";
                },
                label: (ctx) => `Form score: ${ctx.parsed.y}%`
              }
            }
          }
        }
      });

    } catch (e) {
      // fail silently; dashboard still usable
      console.error("Failed to load dashboard trend:", e);
    }
  }

  loadTrend();
});