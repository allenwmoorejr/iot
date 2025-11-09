const refreshSeconds = window.CAR_DASH_REFRESH || 3;
const elements = {
  title: document.getElementById("dashboard-title"),
  speed: document.getElementById("speed-value"),
  rpm: document.getElementById("rpm-value"),
  battery: document.getElementById("battery-value"),
  coolant: document.getElementById("coolant-value"),
  cabin: document.getElementById("cabin-value"),
  outside: document.getElementById("outside-value"),
  humidity: document.getElementById("humidity-value"),
  fuel: document.getElementById("fuel-value"),
  range: document.getElementById("range-value"),
  efficiency: document.getElementById("efficiency-value"),
};

async function fetchDashboard() {
  try {
    const response = await fetch("/api/dashboard", { cache: "no-cache" });
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    const data = await response.json();
    applyData(data);
  } catch (error) {
    console.error("Failed to refresh dashboard", error);
  }
}

function applyData(payload) {
  const { summary, drivetrain, environment, trip } = payload;
  if (summary?.title) {
    elements.title.textContent = summary.title;
  }
  if (typeof summary?.speed === "number") {
    elements.speed.textContent = Math.round(summary.speed);
  }
  if (typeof drivetrain?.rpm === "number") {
    elements.rpm.textContent = Math.round(drivetrain.rpm);
  }
  if (typeof drivetrain?.battery_voltage === "number") {
    elements.battery.textContent = drivetrain.battery_voltage.toFixed(1);
  } else {
    elements.battery.textContent = "--";
  }
  if (typeof drivetrain?.coolant_temp === "number") {
    elements.coolant.textContent = drivetrain.coolant_temp.toFixed(1);
  } else {
    elements.coolant.textContent = "--";
  }
  if (typeof environment?.cabin_temp === "number") {
    elements.cabin.textContent = environment.cabin_temp.toFixed(1);
  } else {
    elements.cabin.textContent = "--";
  }
  if (typeof environment?.outside_temp === "number") {
    elements.outside.textContent = environment.outside_temp.toFixed(1);
  } else {
    elements.outside.textContent = "--";
  }
  if (typeof environment?.humidity === "number") {
    elements.humidity.textContent = Math.round(environment.humidity);
  } else {
    elements.humidity.textContent = "--";
  }
  if (typeof trip?.fuel_level === "number") {
    elements.fuel.textContent = trip.fuel_level.toFixed(0);
  } else {
    elements.fuel.textContent = "--";
  }
  if (typeof trip?.range_km === "number") {
    elements.range.textContent = Math.round(trip.range_km);
  } else {
    elements.range.textContent = "--";
  }
  if (typeof trip?.efficiency === "number") {
    elements.efficiency.textContent = trip.efficiency.toFixed(1);
  } else {
    elements.efficiency.textContent = "--";
  }
}

fetchDashboard();
setInterval(fetchDashboard, refreshSeconds * 1000);
