const plants = [
  {
    id: "lavender",
    name: "Munstead Lavender",
    emoji: "🌿",
    price: 14,
    stock: 4,
    traits: ["drought-wise", "pollinator", "fragrant"],
    climate: "dry",
    care: "low water"
  },
  {
    id: "tomato",
    name: "Black Cherry Tomato",
    emoji: "🍅",
    price: 9,
    stock: 6,
    traits: ["edible", "heirloom", "sun lover"],
    climate: "warm",
    care: "steady water"
  },
  {
    id: "penstemon",
    name: "Rocky Mountain Penstemon",
    emoji: "🌸",
    price: 12,
    stock: 3,
    traits: ["native", "pollinator", "drought-wise"],
    climate: "dry",
    care: "low water"
  },
  {
    id: "basil",
    name: "Thai Basil",
    emoji: "🌱",
    price: 7,
    stock: 5,
    traits: ["edible", "fragrant", "container"],
    climate: "warm",
    care: "steady water"
  },
  {
    id: "hosta",
    name: "Blue Mouse Ears Hosta",
    emoji: "🍃",
    price: 13,
    stock: 2,
    traits: ["shade", "collector", "container"],
    climate: "cool",
    care: "moist soil"
  }
];

const trendPool = [
  {
    headline: "Dry gardens are having a moment",
    detail: "Customers are asking for low-water plants that still bring bees and color.",
    wants: ["drought-wise", "pollinator"]
  },
  {
    headline: "Balcony cooks are shopping early",
    detail: "Container herbs and edible starts are moving fast this week.",
    wants: ["container", "edible"]
  },
  {
    headline: "Native plant club posted a spring list",
    detail: "Locals are looking for regionally adapted flowers with wildlife value.",
    wants: ["native", "pollinator"]
  },
  {
    headline: "Collectors want something unusual",
    detail: "Small rare-looking varieties are fetching better prices.",
    wants: ["collector", "container"]
  }
];

const customerNames = [
  "Balcony gardener",
  "Chef with a patio",
  "Native-plant regular",
  "New homeowner",
  "Shade garden collector",
  "Weekend market grower"
];

const state = {
  week: 1,
  cash: 120,
  reputation: 12,
  trendIndex: 0,
  customers: [],
  log: ["Opened the nursery gates. The benches smell like damp soil and tomato leaves."]
};

const els = {
  week: document.querySelector("#week"),
  cash: document.querySelector("#cash"),
  reputation: document.querySelector("#reputation"),
  trend: document.querySelector("#trend"),
  customers: document.querySelector("#customers"),
  inventory: document.querySelector("#inventory"),
  parentA: document.querySelector("#parent-a"),
  parentB: document.querySelector("#parent-b"),
  hybridResult: document.querySelector("#hybrid-result"),
  log: document.querySelector("#log"),
  nextWeek: document.querySelector("#next-week"),
  restock: document.querySelector("#restock"),
  hybridize: document.querySelector("#hybridize")
};

function currentTrend() {
  return trendPool[state.trendIndex % trendPool.length];
}

function money(value) {
  return `$${value}`;
}

function addLog(message) {
  state.log.unshift(message);
  state.log = state.log.slice(0, 8);
}

function scorePlantForTrend(plant, trend) {
  return plant.traits.filter((trait) => trend.wants.includes(trait)).length;
}

function generateCustomers() {
  const trend = currentTrend();
  state.customers = Array.from({ length: 4 }, (_, index) => {
    const preferredTrait = trend.wants[index % trend.wants.length];
    return {
      name: customerNames[(state.week + index) % customerNames.length],
      preferredTrait,
      patience: 1 + Math.floor(Math.random() * 3)
    };
  });
}

function sellPlant(id) {
  const plant = plants.find((item) => item.id === id);
  if (!plant || plant.stock <= 0) return;

  const trend = currentTrend();
  const score = scorePlantForTrend(plant, trend);
  const bonus = score * 3;
  const reputationGain = score > 0 ? 2 : 1;

  plant.stock -= 1;
  state.cash += plant.price + bonus;
  state.reputation += reputationGain;
  addLog(`${plant.name} sold for ${money(plant.price + bonus)}. ${score > 0 ? "Good read on the market." : "A modest sale, but every garden starts somewhere."}`);
  render();
}

function restockFavorites() {
  const cost = 36;
  if (state.cash < cost) {
    addLog("Not enough cash to place a restock order.");
    render();
    return;
  }

  const trend = currentTrend();
  const ranked = [...plants].sort((a, b) => scorePlantForTrend(b, trend) - scorePlantForTrend(a, trend));
  ranked.slice(0, 3).forEach((plant) => {
    plant.stock += 2;
  });
  state.cash -= cost;
  addLog("Restocked the benches with this week's strongest sellers.");
  render();
}

function hybridize() {
  const first = plants.find((plant) => plant.id === els.parentA.value);
  const second = plants.find((plant) => plant.id === els.parentB.value);
  const cost = 24;

  if (!first || !second || first.id === second.id) {
    els.hybridResult.textContent = "Choose two different parents.";
    return;
  }

  if (state.cash < cost) {
    els.hybridResult.textContent = "The bench needs $24 for soil, tags, and propagation space.";
    return;
  }

  state.cash -= cost;
  const inherited = [...new Set([...first.traits, ...second.traits])];
  const chosenTraits = inherited.sort(() => Math.random() - 0.5).slice(0, 3);
  const hybridName = `${first.name.split(" ")[0]} ${second.name.split(" ").at(-1)}`;
  const newPlant = {
    id: `hybrid-${Date.now()}`,
    name: hybridName,
    emoji: Math.random() > 0.5 ? first.emoji : second.emoji,
    price: Math.round((first.price + second.price) / 2) + 5,
    stock: 1,
    traits: chosenTraits,
    climate: first.climate,
    care: second.care
  };

  plants.push(newPlant);
  els.hybridResult.innerHTML = `<strong>${newPlant.name}</strong><br><span>${chosenTraits.join(", ")}</span>`;
  addLog(`A new bench tag appears: ${newPlant.name}. It might be worth watching.`);
  render();
}

function nextWeek() {
  state.week += 1;
  state.trendIndex += 1 + Math.floor(Math.random() * 2);
  plants.forEach((plant) => {
    if (plant.stock > 0 && Math.random() > 0.35) {
      plant.stock += 1;
    }
  });
  generateCustomers();
  addLog("A new week rolls in. The regulars have different questions now.");
  render();
}

function renderStats() {
  els.week.textContent = state.week;
  els.cash.textContent = money(state.cash);
  els.reputation.textContent = state.reputation;
}

function renderTrend() {
  const trend = currentTrend();
  els.trend.innerHTML = `
    <div>
      <strong>${trend.headline}</strong>
      <span>${trend.detail}</span>
    </div>
    <div>${trend.wants.map((trait) => `<span class="tag">${trait}</span>`).join(" ")}</div>
  `;
}

function renderCustomers() {
  els.customers.innerHTML = state.customers.map((customer) => `
    <article class="customer">
      <strong>${customer.name}<small>${customer.patience} patience</small></strong>
      <small>Looking for: ${customer.preferredTrait}</small>
    </article>
  `).join("");
}

function tagClass(trait) {
  if (trait.includes("water") || trait.includes("shade")) return "water";
  if (trait.includes("heirloom") || trait.includes("edible")) return "clay";
  return "";
}

function renderInventory() {
  els.inventory.innerHTML = plants.map((plant) => `
    <article class="plant-card">
      <div class="plant-emoji" aria-hidden="true">${plant.emoji}</div>
      <div>
        <div class="plant-title">
          <strong>${plant.name}</strong>
          <small>${money(plant.price)}</small>
        </div>
        <small>${plant.care} · ${plant.climate} climate · ${plant.stock} in stock</small>
        <div class="plant-meta">
          ${plant.traits.map((trait) => `<span class="tag ${tagClass(trait)}">${trait}</span>`).join("")}
        </div>
      </div>
      <div class="plant-actions">
        <button data-sell="${plant.id}" ${plant.stock <= 0 ? "disabled" : ""}>Sell</button>
        <button data-grow="${plant.id}">Grow +1</button>
      </div>
    </article>
  `).join("");

  document.querySelectorAll("[data-sell]").forEach((button) => {
    button.addEventListener("click", () => sellPlant(button.dataset.sell));
  });
  document.querySelectorAll("[data-grow]").forEach((button) => {
    button.addEventListener("click", () => {
      const plant = plants.find((item) => item.id === button.dataset.grow);
      plant.stock += 1;
      addLog(`${plant.name} propagated successfully.`);
      render();
    });
  });
}

function renderHybridOptions() {
  const options = plants.map((plant) => `<option value="${plant.id}">${plant.name}</option>`).join("");
  const currentA = els.parentA.value;
  const currentB = els.parentB.value;
  els.parentA.innerHTML = options;
  els.parentB.innerHTML = options;
  els.parentA.value = currentA || plants[0].id;
  els.parentB.value = currentB || plants[1].id;
}

function renderLog() {
  els.log.innerHTML = state.log.map((message) => `<li>${message}</li>`).join("");
}

function render() {
  renderStats();
  renderTrend();
  renderCustomers();
  renderInventory();
  renderHybridOptions();
  renderLog();
}

els.nextWeek.addEventListener("click", nextWeek);
els.restock.addEventListener("click", restockFavorites);
els.hybridize.addEventListener("click", hybridize);

generateCustomers();
render();
