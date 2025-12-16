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

      const labels = data.points.map(p => p.label);
      const values = data.points.map(p => Number(p.pct || 0));

      // optional: if you want to visually mark fatigue sessions later
      // const fatigueFlags = data.points.map(p => Number(p.fatigue || 0));

      new Chart(el, {
        type: "line",
        data: {
          labels,
          datasets: [{
            label: "Form score (%)",
            data: values,
            tension: 0.3,
            fill: false,
            pointRadius: 3,
            pointHoverRadius: 5
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          scales: {
            y: {
              suggestedMin: 0,
              suggestedMax: 100,
              ticks: { callback: (v) => v + "%" }
            }
          },
          plugins: {
            legend: { display: true }
          }
        }
      });

    } catch (e) {
      // fail silently; dashboard still usable
    }
  }

  loadTrend();
});
