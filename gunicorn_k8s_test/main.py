from flask import Flask, jsonify

app = Flask(__name__)

# Global list to store byte strings for memory consumption
memory_hog = []

@app.route('/')
def hello_world():
    return 'Hello, World!'

@app.route('/consume_memory')
def consume_memory():
    try:
        # Each string is approximately 100 MB in size
        # (1 character is 1 byte, so 100 * 1024 * 1024 characters is ~100 MB)
        memory_hog.append(' ' * (100 * 1024 * 1024))
        return jsonify({
            "status": "success",
            "message": "Increased memory consumption by 100 MB",
            "total_consumed": f"{len(memory_hog) * 100} MB"
        })
    except Exception as e:
        return jsonify({
            "status": "error",
            "message": str(e)
        })

@app.route('/release_memory')
def release_memory():
    memory_hog.clear()
    return jsonify({
        "status": "success",
        "message": "Memory released"
    })

if __name__ == '__main__':
    app.run()
