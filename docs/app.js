let foodData = [];

// Load the JSON data
fetch('../output/chicken_food_impacts.json')
    .then(response => {
        console.log('Response status:', response.status);
        console.log('Response ok:', response.ok);
        return response.text();  // Get as text first to see what we're getting
    })
    .then(text => {
        console.log('Received text length:', text.length);
        console.log('First 100 chars:', text.substring(0, 100));
        console.log('Last 100 chars:', text.substring(text.length - 100));
        
        // Now try to parse
        const data = JSON.parse(text);
        foodData = data;
        console.log('✓ Loaded', foodData.length, 'foods');
    })
    .catch(error => {
        console.error('Error loading data:', error);
        document.getElementById('results').innerHTML = 
            '<div class="empty-state">Error loading data. Check console for details.</div>';
    });

// Search functionality
const searchInput = document.getElementById('search');
const resultsDiv = document.getElementById('results');
const impactDiv = document.getElementById('impact');

searchInput.addEventListener('input', function(e) {
    const searchTerm = e.target.value.toLowerCase().trim();
    
    if (searchTerm.length < 2) {
        resultsDiv.innerHTML = '';
        resultsDiv.style.display = 'none';
        return;
    }

    const matches = foodData.filter(food => 
        food.food_name.toLowerCase().includes(searchTerm)
    ).slice(0, 15);

    if (matches.length === 0) {
        resultsDiv.innerHTML = '<div class="empty-state">No foods found matching "' + searchTerm + '"</div>';
        resultsDiv.style.display = 'block';
        return;
    }

    resultsDiv.style.display = 'block';
    resultsDiv.innerHTML = matches.map(food => `
        <div class="food-item" onclick="showImpact('${food.food_code}')">
            <h3>${food.food_name}</h3>
            <p>${food.chicken_grams}g chicken | ${food.lives_per_serving.toFixed(6)} chickens affected</p>
        </div>
    `).join('');
});

// Display impact for selected food
// Display impact for selected food
function showImpact(foodCode) {
    console.log('showImpact called with:', foodCode);
    
    const food = foodData.find(f => f.food_code === foodCode);
    if (!food) {
        console.error('Food not found:', foodCode);
        return;
    }

    console.log('Found food:', food);

    // Hide search results
    resultsDiv.style.display = 'none';
    searchInput.value = '';

    // Sort welfare harms by hours per serving (highest first)
    const sortedHarms = [...food.welfare_harms].sort((a, b) => 
        b.hours_per_serving - a.hours_per_serving
    );

    impactDiv.innerHTML = `
        <h2>${food.food_name}</h2>
        
        <div class="stats-grid">
            <div class="stat-box">
                <div class="label">Chicken Content</div>
                <div class="value">${food.chicken_grams}g</div>
            </div>
            <div class="stat-box">
                <div class="label">Animals Affected</div>
                <div class="value">${food.lives_per_serving.toFixed(4)} chickens</div>
            </div>
        </div>

        <div class="welfare-section">
            <h3>⚠️ Welfare Impacts per Serving</h3>
            ${sortedHarms.map(harm => `
                <div class="welfare-harm">
                    <h4>${harm.condition}</h4>
                    <div class="harm-stats">
                        <div class="harm-stat">
                            <div class="label">Hours per Life</div>
                            <div class="value">${harm.hours_per_life.toFixed(2)} hours</div>
                        </div>
                        <div class="harm-stat">
                            <div class="label">Hours per Serving</div>
                            <div class="value">${harm.hours_per_serving.toFixed(4)} hours</div>
                        </div>
                    </div>
                    <div class="prevalence-bar">
                        <div class="prevalence-fill" style="width: ${Math.min((harm.hours_per_serving / sortedHarms[0].hours_per_serving) * 100, 100)}%"></div>
                    </div>
                </div>
            `).join('')}
        </div>

        <button class="back-button" onclick="clearImpact()">← Search Another Food</button>
    `;

    impactDiv.scrollIntoView({ behavior: 'smooth', block: 'start' });
}

function clearImpact() {
    impactDiv.innerHTML = '';
    searchInput.focus();
}