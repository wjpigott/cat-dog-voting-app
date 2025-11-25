from flask import Flask, request, jsonify, render_template_string
import redis
import os
import json
from datetime import datetime

app = Flask(__name__)

# Redis connection (for vote storage)
try:
    redis_client = redis.Redis(
        host=os.environ.get('REDIS_HOST', 'localhost'),
        port=int(os.environ.get('REDIS_PORT', 6379)),
        decode_responses=True
    )
    redis_client.ping()
    print("Connected to Redis")
except:
    redis_client = None
    print("Redis not available, using in-memory storage")

# In-memory fallback
votes = {"cat": 0, "dog": 0}

# HTML Template
HTML_TEMPLATE = """
<!DOCTYPE html>
<html>
<head>
    <title>Cat vs Dog Voting App</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; background: #f0f8ff; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .vote-button { 
            font-size: 24px; 
            padding: 20px 40px; 
            margin: 20px; 
            border: none; 
            border-radius: 10px; 
            cursor: pointer; 
            transition: transform 0.2s;
        }
        .vote-button:hover { transform: scale(1.1); }
        .cat-button { background: #ff9999; color: white; }
        .dog-button { background: #9999ff; color: white; }
        .results { margin-top: 40px; }
        .vote-count { font-size: 18px; margin: 10px 0; }
        .environment { background: #333; color: white; padding: 10px; margin: 20px 0; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🐱 Cat vs Dog Voting App 🐶</h1>
        
        <div class="environment">
            Environment: {{ environment }} | Cluster: {{ cluster_type }}
        </div>
        
        <div>
            <button class="vote-button cat-button" onclick="vote('cat')">
                Vote for Cats 🐱
            </button>
            <button class="vote-button dog-button" onclick="vote('dog')">
                Vote for Dogs 🐶
            </button>
        </div>
        
        <div class="results" id="results">
            <h2>Current Results:</h2>
            <div class="vote-count">Cats: <span id="cat-votes">{{ cat_votes }}</span> votes</div>
            <div class="vote-count">Dogs: <span id="dog-votes">{{ dog_votes }}</span> votes</div>
        </div>
    </div>
    
    <script>
        function vote(animal) {
            fetch('/vote', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ vote: animal })
            })
            .then(response => response.json())
            .then(data => {
                document.getElementById('cat-votes').textContent = data.cat;
                document.getElementById('dog-votes').textContent = data.dog;
            })
            .catch(error => console.error('Error:', error));
        }
        
        // Auto-refresh results every 5 seconds
        setInterval(() => {
            fetch('/results')
            .then(response => response.json())
            .then(data => {
                document.getElementById('cat-votes').textContent = data.cat;
                document.getElementById('dog-votes').textContent = data.dog;
            });
        }, 5000);
    </script>
</body>
</html>
"""

@app.route('/')
def index():
    current_votes = get_votes()
    return render_template_string(HTML_TEMPLATE, 
                                cat_votes=current_votes['cat'],
                                dog_votes=current_votes['dog'],
                                environment=os.environ.get('ENVIRONMENT', 'development'),
                                cluster_type=os.environ.get('CLUSTER_TYPE', 'local'))

@app.route('/vote', methods=['POST'])
def vote():
    vote_data = request.get_json()
    animal = vote_data.get('vote', '').lower()
    
    if animal not in ['cat', 'dog']:
        return jsonify({'error': 'Invalid vote. Must be cat or dog'}), 400
    
    # Increment vote count
    if redis_client:
        try:
            redis_client.incr(f'votes:{animal}')
        except:
            votes[animal] += 1
    else:
        votes[animal] += 1
    
    return jsonify(get_votes())

@app.route('/results')
def results():
    return jsonify(get_votes())

@app.route('/health')
def health():
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.utcnow().isoformat(),
        'environment': os.environ.get('ENVIRONMENT', 'development'),
        'cluster_type': os.environ.get('CLUSTER_TYPE', 'local'),
        'redis_connected': redis_client is not None
    })

@app.route('/ready')
def ready():
    # Simple readiness check
    return jsonify({'status': 'ready'})

def get_votes():
    if redis_client:
        try:
            cat_votes = int(redis_client.get('votes:cat') or 0)
            dog_votes = int(redis_client.get('votes:dog') or 0)
            return {'cat': cat_votes, 'dog': dog_votes}
        except:
            pass
    
    return votes

if __name__ == '__main__':
    # Initialize Redis votes if not exists
    if redis_client:
        try:
            if not redis_client.exists('votes:cat'):
                redis_client.set('votes:cat', 0)
            if not redis_client.exists('votes:dog'):
                redis_client.set('votes:dog', 0)
        except:
            pass
    
    app.run(host='0.0.0.0', port=80, debug=False)