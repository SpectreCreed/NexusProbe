/**
 * Email OSINT Dashboard — App JS
 * Alpine.js components and Chart.js initialisation.
 */

// ─── Risk Score Gauge (ApexCharts) ──────────────────────────────────────────
function initRiskGauge(score, color) {
  const colorMap = {
    emerald: '#10b981',
    amber:   '#f59e0b',
    orange:  '#f97316',
    red:     '#ef4444',
  };
  const hex = colorMap[color] || '#6366f1';

  if (typeof ApexCharts === 'undefined') return;

  const options = {
    series: [score],
    chart: {
      type: 'radialBar',
      height: 220,
      background: 'transparent',
      sparkline: { enabled: true },
    },
    plotOptions: {
      radialBar: {
        startAngle: -140,
        endAngle: 140,
        hollow: { size: '55%' },
        track: {
          background: 'rgba(255,255,255,0.05)',
          strokeWidth: '100%',
        },
        dataLabels: {
          name: { show: false },
          value: {
            fontSize: '2.5rem',
            fontWeight: 800,
            color: hex,
            fontFamily: 'Inter, sans-serif',
            offsetY: 10,
            formatter: (v) => Math.round(v),
          },
        },
      },
    },
    fill: {
      type: 'gradient',
      gradient: {
        shade: 'dark',
        type: 'horizontal',
        gradientToColors: [hex],
        stops: [0, 100],
      },
    },
    colors: [hex],
    stroke: { lineCap: 'round' },
    theme: { mode: 'dark' },
  };

  const el = document.querySelector('#risk-gauge');
  if (el) {
    const chart = new ApexCharts(el, options);
    chart.render();
  }
}

// ─── Breach Category Chart (Chart.js) ───────────────────────────────────────
function initBreachChart(breachCount, accountCount, hasDomain, hasGravatar) {
  const el = document.getElementById('exposure-chart');
  if (!el || typeof Chart === 'undefined') return;

  Chart.defaults.color = '#94a3b8';

  new Chart(el, {
    type: 'doughnut',
    data: {
      labels: ['Breaches', 'Accounts', 'Domain Intel', 'Public Profile'],
      datasets: [{
        data: [
          breachCount,
          accountCount,
          hasDomain ? 1 : 0,
          hasGravatar ? 1 : 0,
        ],
        backgroundColor: [
          'rgba(239,68,68,0.7)',
          'rgba(99,102,241,0.7)',
          'rgba(6,182,212,0.7)',
          'rgba(16,185,129,0.7)',
        ],
        borderColor: [
          '#ef4444', '#6366f1', '#06b6d4', '#10b981'
        ],
        borderWidth: 1.5,
        hoverOffset: 8,
      }],
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      cutout: '68%',
      plugins: {
        legend: {
          position: 'bottom',
          labels: {
            padding: 16,
            usePointStyle: true,
            pointStyleWidth: 10,
            font: { family: 'Inter', size: 12 },
          },
        },
        tooltip: {
          callbacks: {
            label: (ctx) => ` ${ctx.label}: ${ctx.parsed}`,
          },
        },
      },
    },
  });
}

// ─── Account category bar chart ─────────────────────────────────────────────
function initAccountsChart(categories) {
  const el = document.getElementById('accounts-chart');
  if (!el || typeof Chart === 'undefined' || !categories) return;

  const labels = Object.keys(categories);
  const values = Object.values(categories);
  if (!labels.length) return;

  new Chart(el, {
    type: 'bar',
    data: {
      labels,
      datasets: [{
        label: 'Accounts',
        data: values,
        backgroundColor: 'rgba(99,102,241,0.6)',
        borderColor: '#6366f1',
        borderWidth: 1,
        borderRadius: 6,
      }],
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: { legend: { display: false } },
      scales: {
        x: {
          grid: { color: 'rgba(255,255,255,0.04)' },
          ticks: { color: '#94a3b8', font: { size: 11 } },
        },
        y: {
          grid: { color: 'rgba(255,255,255,0.04)' },
          ticks: { color: '#94a3b8', stepSize: 1 },
          beginAtZero: true,
        },
      },
    },
  });
}

// ─── Copy to clipboard ──────────────────────────────────────────────────────
function copyToClipboard(text) {
  navigator.clipboard.writeText(text).then(() => {
    const toast = document.getElementById('copy-toast');
    if (toast) {
      toast.classList.remove('opacity-0');
      toast.classList.add('opacity-100');
      setTimeout(() => {
        toast.classList.remove('opacity-100');
        toast.classList.add('opacity-0');
      }, 2000);
    }
  });
}

// ─── HTMX events ────────────────────────────────────────────────────────────
document.addEventListener('htmx:afterSwap', (e) => {
  // Re-run chart init after HTMX swap if needed
  const gaugeEl = e.detail.target?.querySelector?.('#risk-gauge');
  if (gaugeEl && window.__riskData) {
    initRiskGauge(window.__riskData.score, window.__riskData.color);
  }
});

// ─── D3 Connection Graph (Phase 2) ──────────────────────────────────────────
function initConnectionGraph(nodes, links) {
  if (typeof d3 === 'undefined') return;
  const container = document.getElementById('connection-graph');
  const svg = d3.select('#graph-svg');
  const tooltip = document.getElementById('graph-tooltip');
  if (!container || svg.empty()) return;

  const W = container.clientWidth || 800;
  const H = container.clientHeight || 340;

  const nodeColors = {
    email:   '#8b5cf6',  // violet
    breach:  '#ef4444',  // red
    account: '#6366f1',  // indigo
    domain:  '#06b6d4',  // cyan
  };
  const nodeRadius = { email: 20, breach: 9, account: 9, domain: 13 };

  // Zoom behaviour
  const zoomG = svg.append('g');
  svg.call(
    d3.zoom()
      .scaleExtent([0.3, 3])
      .on('zoom', (e) => zoomG.attr('transform', e.transform))
  );

  // Arrow marker
  svg.append('defs').append('marker')
    .attr('id', 'arrow')
    .attr('viewBox', '0 -4 8 8')
    .attr('refX', 18).attr('refY', 0)
    .attr('markerWidth', 6).attr('markerHeight', 6)
    .attr('orient', 'auto')
    .append('path')
    .attr('d', 'M0,-4L8,0L0,4')
    .attr('fill', 'rgba(99,102,241,0.4)');

  // Force simulation (responsive force constants)
  const isMobile = W < 500;
  const centralDistance = isMobile ? 65 : 100;
  const leafDistance = isMobile ? 45 : 60;
  const chargeStrength = isMobile ? -80 : -180;
  const collideRadius = isMobile ? 4 : 8;

  const simulation = d3.forceSimulation(nodes)
    .force('link', d3.forceLink(links).id(d => d.id).distance(d => {
      return d.source.type === 'email' ? centralDistance : leafDistance;
    }))
    .force('charge', d3.forceManyBody().strength(chargeStrength))
    .force('center', d3.forceCenter(W / 2, H / 2))
    .force('collision', d3.forceCollide().radius(d => (nodeRadius[d.type] || 10) + collideRadius));

  // Links
  const link = zoomG.append('g')
    .selectAll('line')
    .data(links)
    .join('line')
    .attr('stroke', 'rgba(99,102,241,0.25)')
    .attr('stroke-width', 1.5)
    .attr('marker-end', 'url(#arrow)');

  // Nodes group
  const node = zoomG.append('g')
    .selectAll('g')
    .data(nodes)
    .join('g')
    .attr('cursor', 'grab')
    .call(d3.drag()
      .on('start', (e, d) => { if (!e.active) simulation.alphaTarget(0.3).restart(); d.fx = d.x; d.fy = d.y; })
      .on('drag', (e, d) => { d.fx = e.x; d.fy = e.y; })
      .on('end', (e, d) => { if (!e.active) simulation.alphaTarget(0); d.fx = null; d.fy = null; })
    );

  // Circle
  node.append('circle')
    .attr('r', d => nodeRadius[d.type] || 9)
    .attr('fill', d => nodeColors[d.type] || '#6366f1')
    .attr('fill-opacity', 0.85)
    .attr('stroke', d => nodeColors[d.type] || '#6366f1')
    .attr('stroke-width', 2)
    .attr('stroke-opacity', 0.3);

  // Label
  node.append('text')
    .attr('dy', d => (nodeRadius[d.type] || 9) + 14)
    .attr('text-anchor', 'middle')
    .attr('font-size', d => d.type === 'email' ? '11px' : '9px')
    .attr('fill', '#94a3b8')
    .text(d => d.label.length > 18 ? d.label.slice(0, 16) + '…' : d.label);

  // Tooltip
  node
    .on('mouseover', (e, d) => {
      tooltip.style.display = 'block';
      tooltip.textContent = `${d.label} (${d.type})`;
    })
    .on('mousemove', (e) => {
      const rect = container.getBoundingClientRect();
      tooltip.style.left = (e.clientX - rect.left + 12) + 'px';
      tooltip.style.top  = (e.clientY - rect.top  - 10) + 'px';
    })
    .on('mouseleave', () => { tooltip.style.display = 'none'; });

  // Tick
  simulation.on('tick', () => {
    link
      .attr('x1', d => d.source.x).attr('y1', d => d.source.y)
      .attr('x2', d => d.target.x).attr('y2', d => d.target.y);
    node.attr('transform', d => `translate(${d.x},${d.y})`);
  });
}
