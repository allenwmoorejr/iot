/***** MODULES *****/
{ module: "MMM-Remote-Control" },

// Rotate pages
{ module: "MMM-Carousel",
  position: "bottom_bar",
  config: {
    mode: "slides",
    slides: [
      ["clock","calendar","weather","mqtt-tiles","pihole-box"],
      ["cam-grid"]
    ],
    transitionInterval: 20000
  }
},

{ module: "clock", position: "top_left" },

{ module: "calendar", position: "top_left",
  header: "Calendar",
  config: {
    calendars: [
      // replace with your ICS
      { url: "https://calendar.google.com/calendar/ical/.../basic.ics" }
    ]
  }
},

{ module: "weather", position: "top_right",
  config: {
    weatherProvider: "openweathermap",
    type: "current",
    units: "imperial",
    apiKey: process.env.OPENWEATHER_API_KEY,   // set via K8s Secret (you already have)
    location: "Chicago,US"
  }
},
{ module: "weather", position: "top_right",
  config: {
    weatherProvider: "openweathermap",
    type: "forecast",
    units: "imperial",
    apiKey: process.env.OPENWEATHER_API_KEY,
    location: "Chicago,US"
  }
},

// --- MQTT sensor tiles (uses Mosquitto in your cluster)
{ module: "MMM-MQTT", header: "Home Sensors", position: "bottom_left", classes: "mqtt-tiles",
  config: {
    logging: false,
    mqttServer: "ws://mosquitto.suite.svc.cluster.local:1883", // or "mqtt://..." if module prefers TCP
    subscriptions: [
      { topic: "zigbee2mqtt/livingroom/sensor", label: "Living Room",
        jsonpointer: "/temperature", suffix: "°F", decimals: 1 },
      { topic: "zigbee2mqtt/livingroom/sensor", label: "Humidity",
        jsonpointer: "/humidity", suffix: "%", decimals: 0 },
      { topic: "zigbee2mqtt/door/front", label: "Front Door",
        jsonpointer: "/contact", map: { "true": "Closed", "false": "Open" } }
    ]
  }
},

// --- Pi-hole quick stats (HTTP API)
{ module: "MMM-HTMLBox", position: "bottom_right", classes: "pihole-box",
  config: {
    html: `
      <div style="font-size:18px">
        <div><b>Pi-hole</b></div>
        <div id="pihole-q"   >Queries: …</div>
        <div id="pihole-blk" >Blocked: …</div>
        <div id="pihole-perc">Blocked%: …</div>
      </div>
      <script>
        async function pull(){ 
          try{
            const r = await fetch("http://pihole.suite.home.arpa/admin/api.php");
            const j = await r.json();
            document.getElementById("pihole-q").innerText   = "Queries: " + j.dns_queries_today;
            document.getElementById("pihole-blk").innerText = "Blocked: " + j.ads_blocked_today;
            document.getElementById("pihole-perc").innerText= "Blocked%: " + j.ads_percentage_today + "%";
          }catch(e){}
        }
        pull(); setInterval(pull, 60000);
      </script>
    `
  }
},

// --- Camera page (HLS snapshot or RTSP). Start with snapshots (simpler, no GPU):
{ module: "MMM-HTMLBox", position: "fullscreen_above", classes: "cam-grid",
  config: {
    html: `
      <div style="display:grid;grid-template-columns:1fr 1fr;gap:8px">
        <img

